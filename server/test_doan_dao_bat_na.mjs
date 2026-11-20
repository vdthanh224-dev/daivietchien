import assert from "node:assert/strict";
import { CARD_CATEGORIES, CARD_SUBTYPES } from "./functions/game-engine/src/deck.js";
import {
  handlePlayCard,
  handleRespondAction,
  handleUseSkill,
  initGame
} from "./functions/game-engine/src/gameEngine.js";

const players = [1, 2, 3, 4].map((seat) => ({ seat, heroId: seat === 1 ? "HERO_6" : `HERO_${seat}` }));
const basic = (id, name = "Bài Cơ Bản", subType = CARD_SUBTYPES.PEACH) => ({
  id,
  name,
  suit: "Heart",
  rank: 1,
  category: CARD_CATEGORIES.BASIC,
  subType
});

const scroll = (id, name = "Qua Cầu Rút Ván", subType = CARD_SUBTYPES.DISMANTLE) => ({
  id,
  name,
  suit: "Spade",
  rank: 3,
  category: CARD_CATEGORIES.INSTANT_SCROLL,
  subType
});

const weapon = (id, name = "Hỏa Mai Tây Sơn", subType = CARD_SUBTYPES.WEAPON, range = 4) => ({
  id,
  name,
  suit: "Diamond",
  rank: 5,
  category: CARD_CATEGORIES.EQUIPMENT,
  subType,
  range
});

const armor = (id, name = "Áo Bào Hoàng Tộc", subType = CARD_SUBTYPES.ARMOR) => ({
  id,
  name,
  suit: "Club",
  rank: 2,
  category: CARD_CATEGORIES.EQUIPMENT,
  subType
});

// Test 1: Bát Nạ with Basic card (draws 1 card + slash limit not consumed)
{
  const state = initGame("bat-na-basic-draw", players);
  const initialHandCount = state.players[0].hand.length;
  state.players[0].hand.push(basic("bat-na-source"));
  state.players[0].hand.push(basic("normal-slash", "Trảm", CARD_SUBTYPES.ATTACK_NORMAL));

  const result = handleUseSkill(state, 1, "Bát Nạ", 2, "bat-na-source");
  assert.equal(result.success, true);
  // Pushed 2 cards, cost card was consumed (-1), drew 1 card (+1), so count is initialHandCount + 2
  assert.equal(state.players[0].hand.length, initialHandCount + 2);
  assert.equal(state.slashesUsedThisTurn, 0);
  assert.equal(state.phase, "AWAIT_SLASH_DEFENSE");

  handleRespondAction(state, 2, false, null);
  assert.equal(handlePlayCard(state, 1, "normal-slash", 2).success, true);
  assert.equal(state.slashesUsedThisTurn, 1);
}

// Test 2: Slash first, then Bát Nạ
{
  const state = initGame("slash-before-bat-na", players);
  state.players[0].hand.push(basic("normal-slash-first", "Trảm", CARD_SUBTYPES.ATTACK_NORMAL));
  state.players[0].hand.push(basic("bat-na-after-slash"));
  assert.equal(handlePlayCard(state, 1, "normal-slash-first", 2).success, true);
  assert.equal(handleRespondAction(state, 2, false, null).success, true);
  assert.equal(state.slashesUsedThisTurn, 1);
  assert.equal(handleUseSkill(state, 1, "Bát Nạ", 2, "bat-na-after-slash").success, true);
  assert.equal(state.slashesUsedThisTurn, 1);
  assert.equal(state.phase, "AWAIT_SLASH_DEFENSE");
}

// Test 3: Bát Nạ with Scroll card (destroys target card before Trảm)
{
  const state = initGame("bat-na-scroll-destroy", players);
  state.players[0].hand.push(scroll("bat-na-scroll"));
  state.players[1].hand = [basic("target-held-card")];
  state.players[1].equipments = [];

  const res = handleUseSkill(state, 1, "Bát Nạ", 2, "bat-na-scroll");
  assert.equal(res.success, true);
  // Must enter AWAIT_TARGET_CARD with effectType BAT_NA
  assert.equal(state.phase, "AWAIT_TARGET_CARD");
  assert.equal(state.waitingTargetSeat, 1);
  assert.equal(state.targetCardSelection.effectType, "BAT_NA");
  assert.equal(state.targetCardSelection.chooserSeat, 1);
  assert.equal(state.targetCardSelection.targetSeat, 2);

  // Seat 1 selects the target card to destroy
  const token = state.targetCardSelection.options[0].token;
  const destroyRes = handleRespondAction(state, 1, true, null, token);
  assert.equal(destroyRes.success, true);

  // Target card is destroyed
  assert.equal(state.players[1].hand.length, 0);

  // Trảm immediately takes effect -> target must defend against slash!
  assert.equal(state.phase, "AWAIT_SLASH_DEFENSE");
  assert.equal(state.waitingTargetSeat, 2);
  assert.equal(state.activeCard.countsTowardTurnSlashLimit, false);
}

// Test 4: Bát Nạ with Scroll card when target has no cards
{
  const state = initGame("bat-na-scroll-no-cards", players);
  state.players[0].hand.push(scroll("bat-na-scroll-empty"));
  state.players[1].hand = [];
  state.players[1].equipments = [];
  state.players[1].judgements = [];

  const res = handleUseSkill(state, 1, "Bát Nạ", 2, "bat-na-scroll-empty");
  assert.equal(res.success, true);
  // Directly resolves to slash defense without entering AWAIT_TARGET_CARD
  assert.equal(state.phase, "AWAIT_SLASH_DEFENSE");
  assert.equal(state.waitingTargetSeat, 2);
}

// Test 5: Bát Nạ with Weapon card (infinite distance)
{
  const state = initGame("bat-na-weapon-infinite-range", players);
  // In a 4-player game (seats 1, 2, 3, 4), distance between seat 1 and seat 3 is 2.
  // Seat 1 has no equipped weapon (range = 1).
  state.players[0].hand.push(weapon("bat-na-weapon"));
  state.players[0].hand.push(basic("normal-slash", "Trảm", CARD_SUBTYPES.ATTACK_NORMAL));

  // Normal slash against seat 3 fails due to distance
  const slashFail = handlePlayCard(state, 1, "normal-slash", 3);
  assert.equal(slashFail.success, undefined);
  assert.ok(slashFail.error);

  // Bát Nạ with Weapon card succeeds against seat 3 (infinite range)
  const batNaRes = handleUseSkill(state, 1, "Bát Nạ", 3, "bat-na-weapon");
  assert.equal(batNaRes.success, true);
  assert.equal(state.phase, "AWAIT_SLASH_DEFENSE");
  assert.equal(state.waitingTargetSeat, 3);
}

// Test 6: Bát Nạ with Armor card (ignores target armor)
{
  const state = initGame("bat-na-armor-ignore", players);
  // Seat 2 equips Áo Bào Hoàng Tộc (charges = 2)
  state.players[1].equipments.push({
    id: "ao-bao",
    name: "Áo Bào Hoàng Tộc",
    category: CARD_CATEGORIES.EQUIPMENT,
    subType: CARD_SUBTYPES.ARMOR
  });
  state.players[1].aoBaoCharges = 2;
  const initialHp = state.players[1].hp;

  // Seat 1 activates Bát Nạ using an Armor card
  state.players[0].hand.push(armor("bat-na-armor"));
  const res = handleUseSkill(state, 1, "Bát Nạ", 2, "bat-na-armor");
  assert.equal(res.success, true);
  assert.equal(state.activeCard.ignoreArmor, true);

  // Seat 2 fails to dodge (takes hit)
  handleRespondAction(state, 2, false, null);

  // Áo Bào Hoàng Tộc must NOT absorb damage, HP is deducted directly
  assert.equal(state.players[1].hp, initialHp - 1);
  assert.equal(state.players[1].aoBaoCharges, 2);
}

// Test 7: Bát Nạ with Armor card against Khiên Mây Bện
{
  const state = initGame("bat-na-armor-khien-may", players);
  state.players[1].equipments.push({
    id: "khien-may",
    name: "Khiên Mây Bện",
    category: CARD_CATEGORIES.EQUIPMENT,
    subType: CARD_SUBTYPES.ARMOR
  });

  state.players[0].hand.push(armor("bat-na-armor-2"));
  const res = handleUseSkill(state, 1, "Bát Nạ", 2, "bat-na-armor-2");
  assert.equal(res.success, true);
  assert.equal(state.phase, "AWAIT_SLASH_DEFENSE");

  // Attempting to use Khiên Mây Bện must be rejected because armor is ignored
  const kmAttempt = handleRespondAction(state, 2, true, "KHIEN_MAY");
  assert.equal(kmAttempt.success, undefined);
  assert.ok(kmAttempt.error.includes("Trang bị Giáp"));
}

function doanDaoState(roomId) {
  const state = initGame(roomId, players);
  state.players[0].equipments.push({
    id: "doan-dao",
    name: "Đoản Đao Lam Sơn",
    category: CARD_CATEGORIES.EQUIPMENT,
    subType: CARD_SUBTYPES.WEAPON,
    range: 2
  });
  state.players[0].hand.push(basic("doan-slash", "Trảm", CARD_SUBTYPES.ATTACK_NORMAL));
  state.players[1].hand = [basic("target-card-1"), basic("target-card-2")];
  handlePlayCard(state, 1, "doan-slash", 2);
  handleRespondAction(state, 2, false, null);
  assert.equal(state.phase, "AWAIT_DOAN_DAO_CHOICE");
  assert.equal(state.waitingTargetSeat, 1);
  return state;
}

{
  const state = doanDaoState("doan-dao-damage");
  handleRespondAction(state, 1, false, null);
  assert.equal(state.players[1].hp, state.players[1].maxHp - 1);
}

{
  const state = doanDaoState("doan-dao-destroy");
  const attackerHand = state.players[0].hand.length;
  handleRespondAction(state, 1, true, null);
  assert.equal(state.targetCardSelection.chooserSeat, 1);
  assert.equal(state.targetCardSelection.targetSeat, 2);
  handleRespondAction(state, 1, true, null, state.targetCardSelection.options[0].token);
  assert.equal(state.phase, "AWAIT_TARGET_CARD");
  handleRespondAction(state, 1, true, null, state.targetCardSelection.options[0].token);
  assert.equal(state.players[1].hand.length, 0);
  assert.equal(state.players[0].hand.length, attackerHand);
  assert.equal(state.players[1].hp, state.players[1].maxHp);
}

console.log("Đoản Đao và Bát Nạ ALL TESTS PASSED!");
