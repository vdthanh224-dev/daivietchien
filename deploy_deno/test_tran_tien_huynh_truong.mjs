import assert from "node:assert/strict";
import { CARD_CATEGORIES, CARD_SUBTYPES } from "./functions/game-engine/src/deck.js";
import { handlePlayCard, handleRespondAction, handleUseSkill, initGame } from "./functions/game-engine/src/gameEngine.js";

const card = (id, name, subType) => ({
  id,
  name,
  suit: "Heart",
  rank: 7,
  category: CARD_CATEGORIES.BASIC,
  subType
});

{
  const state = initGame("tran-tien", [
    { seat: 1, heroId: "HERO_7" },
    { seat: 2, heroId: "HERO_2" },
    { seat: 3, heroId: "HERO_1" },
    { seat: 4, heroId: "HERO_3" }
  ]);
  state.players[0].hand = [card("lethal-slash", "Trảm", CARD_SUBTYPES.ATTACK_NORMAL)];
  state.players[1].hand = [];
  state.players[1].hp = 1;
  assert.equal(handlePlayCard(state, 1, "lethal-slash", 2).success, true);
  assert.equal(handleRespondAction(state, 2, false, null).success, true);
  while (state.phase === "AWAIT_NEAR_DEATH") {
    assert.equal(handleRespondAction(state, state.waitingTargetSeat, false, null).success, true);
  }
  assert.equal(state.players[1].isAlive, false);
  assert.equal(state.players[0].hand.length, 2);
  assert.equal(state.actionHistory.some((action) => action.type === "TRAN_TIEN_DRAW" && action.casterSeat === 1), true);
}

{
  const state = initGame("huynh-truong-near-death", [
    { seat: 1, heroId: "HERO_1" },
    { seat: 2, heroId: "HERO_8" },
    { seat: 3, heroId: "HERO_2" },
    { seat: 4, heroId: "HERO_3" }
  ]);
  state.players[0].hand = [
    card("slash", "Trảm", CARD_SUBTYPES.ATTACK_NORMAL),
    card("rescue", "Bánh Chưng", CARD_SUBTYPES.PEACH)
  ];
  state.players[1].hand = [card("gift", "Bài đưa", CARD_SUBTYPES.PEACH)];
  state.players[1].hp = 1;
  assert.equal(handlePlayCard(state, 1, "slash", 2).success, true);
  assert.equal(handleRespondAction(state, 2, false, null).success, true);
  assert.equal(handleRespondAction(state, 1, true, "rescue").success, true);
  assert.equal(state.phase, "AWAIT_KHOI_BINH");
  assert.equal(handleRespondAction(state, 2, false, null).success, true);
  assert.equal(state.phase, "AWAIT_HUYNH_TRUONG");
  assert.equal(handleUseSkill(state, 2, "Huynh Trưởng", 3, "gift").success, true);
  assert.equal(state.players[2].hand.some((candidate) => candidate.id === "gift"), true);
  assert.equal(state.phase, "PLAY");
}

console.log("Trận Tiền và Huynh Trưởng OK");
