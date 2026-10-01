import assert from "node:assert/strict";
import { CARD_CATEGORIES, CARD_SUBTYPES } from "./functions/game-engine/src/deck.js";
import { handlePlayCard, handleRespondAction, initGame } from "./functions/game-engine/src/gameEngine.js";

const state = initGame("water-chain", [1, 2, 3, 4].map((seat) => ({ seat, heroId: `HERO_${seat}` })));
for (const player of state.players) {
  player.hand = [];
  player.equipments = [];
  player.hp = 4;
  player.isChained = false;
}

state.players[1].isChained = true;
state.players[3].isChained = true;
state.players[0].hand = [{
  id: "water-slash",
  name: "Trảm - Thủy",
  suit: "Spade",
  rank: 8,
  category: CARD_CATEGORIES.BASIC,
  subType: CARD_SUBTYPES.ATTACK_WATER
}];

assert.equal(handlePlayCard(state, 1, "water-slash", 2).success, true);
assert.equal(handleRespondAction(state, 2, false, null).success, true);
assert.deepEqual(state.players.map((player) => player.hp), [4, 3, 4, 3]);
assert.equal(state.players.some((player) => player.isChained), false);
assert.equal(state.actionHistory.some((action) => action.type === "CHAIN_DAMAGE_SPREAD" && action.targetSeat === 4), true);

console.log("Trảm Thủy lan xích OK");
