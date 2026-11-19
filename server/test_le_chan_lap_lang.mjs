import assert from "node:assert/strict";
import {
  initGame,
  handlePlayCard,
  handleRespondAction,
  handleEndTurn,
  handleDiscardCards,
  applyDamageToPlayer
} from "./functions/game-engine/src/gameEngine.js";
import { HEROES, SKILLS } from "./functions/game-engine/src/heroes.js";
import { CARD_SUBTYPES, CARD_CATEGORIES } from "./functions/game-engine/src/deck.js";

function card(id, name, subType, suit = "Heart", number = 7, category = CARD_CATEGORIES.BASIC) {
  return { id, name, subType, suit, number, category };
}

function put(state, seat, c) {
  const p = state.players.find((player) => player.seat === seat);
  p.hand = p.hand || [];
  p.hand.push(c);
  return c;
}

function freshState() {
  const players = [
    { seat: 1, heroId: "HERO_4", userId: "u1", userName: "Lê Chân" },
    { seat: 2, heroId: "HERO_1", userId: "u2", userName: "Cao Lỗ" },
    { seat: 3, heroId: "HERO_2", userId: "u3", userName: "Đào Hãn" },
    { seat: 4, heroId: "HERO_10", userId: "u4", userName: "Lý Bí" }
  ];
  const state = initGame("test-lap-lang", players, "2v2");
  for (const p of state.players) {
    p.hand = [];
    p.equipments = [];
    p.judgements = [];
  }
  return state;
}

console.log("=== Testing Lê Chân: Lập Làng Remake ===");

// 1. Description check
{
  assert.equal(
    SKILLS.LAP_LANG.description,
    "Cuối lượt, nếu bạn không gây sát thương, bạn rút 2 lá bài, nếu bạn gây sát thương, rút số lượng lá bài bằng số sát thương đã gây trong lượt."
  );
  assert.ok(HEROES.HERO_4.skills.includes("LAP_LANG"));
  console.log("✓ TEST 1 PASSED: Skill description and registration verified");
}

// 2. 0 damage dealt without excess cards -> draws 2 cards at end of turn
{
  const state = freshState();
  const p1 = state.players[0];
  p1.hp = 3;
  put(state, 1, card("C1", "Bánh Chưng", CARD_SUBTYPES.PEACH));
  put(state, 1, card("C2", "Đỡ", CARD_SUBTYPES.DODGE));
  assert.equal(p1.hand.length, 2);

  const res = handleEndTurn(state, 1);
  assert.equal(res.success, true);
  // Drew 2 cards from Lap Lang
  assert.equal(p1.hand.length, 4, "Must draw 2 cards when 0 damage dealt");
  const lapLangAction = state.actionHistory.find((a) => a.type === "LAP_LANG_DRAW");
  assert.ok(lapLangAction, "LAP_LANG_DRAW action must be recorded");
  assert.equal(lapLangAction.drawCount, 2);
  assert.ok(lapLangAction.description.includes("không gây sát thương"));
  console.log("✓ TEST 2 PASSED: 0 damage dealt without excess cards draws 2 cards");
}

// 3. 0 damage dealt with excess cards -> draws 2 cards after discard phase
{
  const state = freshState();
  const p1 = state.players[0];
  p1.hp = 3;
  put(state, 1, card("D1", "Lá 1", CARD_SUBTYPES.DODGE));
  put(state, 1, card("D2", "Lá 2", CARD_SUBTYPES.DODGE));
  put(state, 1, card("D3", "Lá 3", CARD_SUBTYPES.DODGE));
  put(state, 1, card("D4", "Lá 4", CARD_SUBTYPES.DODGE));
  assert.equal(p1.hand.length, 4);

  assert.equal(handleEndTurn(state, 1).success, true);
  assert.equal(state.phase, "DISCARD");
  assert.equal(p1.hand.length, 4, "Must not draw before discarding");

  assert.equal(handleDiscardCards(state, 1, ["D1"]).success, true);
  // After discarding 1 card (hand = 3), Lap Lang draws 2 cards (hand = 5)
  assert.equal(p1.hand.length, 5, "Must draw 2 cards after discarding excess cards");
  console.log("✓ TEST 3 PASSED: 0 damage dealt with excess cards draws 2 cards after discard");
}

// 4. 1 damage dealt -> draws 1 card at end of turn
{
  const state = freshState();
  const p1 = state.players[0];
  const p2 = state.players[1];
  p1.hp = 3;
  p2.hp = 3;
  put(state, 1, card("S1", "Trảm Thường", CARD_SUBTYPES.ATTACK_NORMAL));
  
  // Player 1 slashes Player 2
  const playRes = handlePlayCard(state, 1, "S1", [2]);
  assert.equal(playRes.success, true);
  assert.equal(state.phase, "AWAIT_SLASH_DEFENSE");

  // Player 2 passes dodge -> takes 1 damage
  const dodgeRes = handleRespondAction(state, 2, false);
  assert.equal(dodgeRes.success, true);
  assert.equal(p2.hp, 2);
  assert.equal(state.turnDamageDealt, true);
  assert.equal(state.turnDamageDealtAmount, 1);

  // Player 1 ends turn (hand is empty, HP is 3, no excess)
  const endRes = handleEndTurn(state, 1);
  assert.equal(endRes.success, true);
  // Drew 1 card because dealt 1 damage
  assert.equal(p1.hand.length, 1, "Must draw 1 card when 1 damage dealt");
  const lapLangAction = state.actionHistory.find((a) => a.type === "LAP_LANG_DRAW");
  assert.ok(lapLangAction, "LAP_LANG_DRAW action must be recorded");
  assert.equal(lapLangAction.drawCount, 1);
  assert.ok(lapLangAction.description.includes("đã gây 1 sát thương"));
  console.log("✓ TEST 4 PASSED: 1 damage dealt draws 1 card at end of turn");
}

// 5. 3 damage dealt -> draws 3 cards at end of turn
{
  const state = freshState();
  const p1 = state.players[0];
  const p2 = state.players[1];
  p1.hp = 3;
  p2.hp = 4;

  // Apply 3 damage from p1 to p2
  applyDamageToPlayer(state, 2, 3, "đòn Trảm", "NORMAL", true, { attackerSeat: 1 });
  assert.equal(state.turnDamageDealt, true);
  assert.equal(state.turnDamageDealtAmount, 3);
  assert.equal(p1.hand.length, 0);

  const endRes = handleEndTurn(state, 1);
  assert.equal(endRes.success, true);
  // Drew 3 cards because dealt 3 damage
  assert.equal(p1.hand.length, 3, "Must draw 3 cards when 3 damage dealt");
  const lapLangAction = state.actionHistory.find((a) => a.type === "LAP_LANG_DRAW");
  assert.ok(lapLangAction, "LAP_LANG_DRAW action must be recorded");
  assert.equal(lapLangAction.drawCount, 3);
  assert.ok(lapLangAction.description.includes("đã gây 3 sát thương"));
  console.log("✓ TEST 5 PASSED: 3 damage dealt draws 3 cards at end of turn");
}

// 6. External damage to Lê Chân or self-damage does not count as damage dealt
{
  const state = freshState();
  const p1 = state.players[0];
  p1.hp = 3;

  // External enemy damages p1
  applyDamageToPlayer(state, 1, 1, "đòn Trảm", "NORMAL", true, { attackerSeat: 2 });
  assert.equal(p1.hp, 2);
  assert.equal(state.turnDamageDealt, false, "Damage from seat 2 during seat 1 turn should not credit seat 1");
  assert.equal(state.turnDamageDealtAmount, 0);

  // Self damage
  applyDamageToPlayer(state, 1, 1, "Tự mất máu", "NORMAL", false, { attackerSeat: 1 });
  assert.equal(p1.hp, 1);
  assert.equal(state.turnDamageDealt, false, "Self damage should not count as damage dealt to others");
  assert.equal(state.turnDamageDealtAmount, 0);

  // Since turnDamageDealtAmount is 0, Lap Lang should draw 2 cards
  assert.equal(p1.hand.length, 0);
  const endRes = handleEndTurn(state, 1);
  assert.equal(endRes.success, true);
  assert.equal(p1.hand.length, 2, "Must draw 2 cards since 0 damage was dealt to enemies");
  console.log("✓ TEST 6 PASSED: External damage and self damage do not count as damage dealt");
}

console.log("\n🎉 ALL LÊ CHÂN LẬP LÀNG TESTS PASSED 100%!");
