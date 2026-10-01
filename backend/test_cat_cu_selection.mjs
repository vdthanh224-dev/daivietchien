import assert from "node:assert/strict";
import { initGame, handlePlayCard, handleRespondAction } from "./functions/game-engine/src/gameEngine.js";
import { CARD_CATEGORIES, CARD_SUBTYPES } from "./functions/game-engine/src/deck.js";

const players = [1, 2, 3, 4].map((seat) => ({
  seat,
  userId: `cat-cu-${seat}`,
  generalName: `P${seat}`,
  maxHp: 4,
  heroId: seat === 2 ? "HERO_26" : "HERO_1"
}));
const state = initGame("cat-cu-selection", players);
for (const player of state.players) {
  player.hand = [];
  player.equipments = [];
  player.judgements = [];
}
const card = (id, name, subType, category = 0) => ({
  id,
  name,
  subType,
  category,
  suit: "Spade",
  rank: 1,
  desc: ""
});

state.players[1].hand = [card("CAT_CU_OLD", "Bài cũ", CARD_SUBTYPES.ATTACK_NORMAL)];
state.players[0].hand = [card("CAT_CU_SNATCH", "Đột Kích Trộm Lương", CARD_SUBTYPES.SNATCH, CARD_CATEGORIES.INSTANT_SCROLL)];
state._deck = [card("CAT_CU_DRAWN", "Bài mới", CARD_SUBTYPES.ATTACK_NORMAL)];

assert.equal(handlePlayCard(state, 1, "CAT_CU_SNATCH", 2).success, true);
while (state.phase === "AWAIT_NULLIFY") {
  assert.equal(handleRespondAction(state, state.waitingTargetSeat, false, null).success, true);
}
assert.equal(state.phase, "AWAIT_TARGET_CARD");
assert.equal(state.players[1].hand.length, 2);
assert.equal(state.targetCardSelection.options.filter((option) => option.zone === "HAND").length, 2);
console.log("Cát Cứ target options: PASS");
