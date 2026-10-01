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

{
  const state = initGame("bat-na-slash-limit", players);
  state.players[0].hand.push(basic("bat-na-source"));
  state.players[0].hand.push(basic("normal-slash", "Trảm", CARD_SUBTYPES.ATTACK_NORMAL));
  assert.equal(handleUseSkill(state, 1, "Bát Nạ", 2, "bat-na-source").success, true);
  assert.equal(state.slashesUsedThisTurn, 0);
  handleRespondAction(state, 2, false, null);
  assert.equal(handlePlayCard(state, 1, "normal-slash", 2).success, true);
  assert.equal(state.slashesUsedThisTurn, 1);
}

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

console.log("Đoản Đao và Bát Nạ OK");
