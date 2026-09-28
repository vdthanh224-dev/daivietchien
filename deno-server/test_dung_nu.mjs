import assert from "node:assert/strict";
import { CARD_CATEGORIES, CARD_SUBTYPES } from "./deck.js";
import { handlePlayCard, handleRespondAction, initGame } from "./gameEngine.js";

const state = initGame("dung-nu-test", [
  { seat: 1, heroId: "HERO_5" },
  { seat: 2, heroId: "HERO_2" },
  { seat: 3, heroId: "HERO_1" },
  { seat: 4, heroId: "HERO_3" }
]);
const caster = state.players[0];
const target = state.players[1];
caster.hp = 3;
target.hp = 4;
caster.hand.push({ id: "test-slash", name: "Trảm", category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.ATTACK_NORMAL, suit: "Spade" });
target.hand = [
  { id: "test-dodge-1", name: "Đỡ", category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.DODGE, suit: "Heart" },
  { id: "test-dodge-2", name: "Đỡ", category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.DODGE, suit: "Diamond" }
];

assert.equal(handlePlayCard(state, 1, "test-slash", 2).success, true);
assert.equal(state.activeCard.requiredDodgeCount, 2);
assert.equal(handleRespondAction(state, 2, true, "test-dodge-1").success, true);
assert.equal(state.phase, "AWAIT_SLASH_DEFENSE");
assert.equal(state.activeCard.dodgesUsed, 1);
assert.equal(target.hp, 4);
assert.equal(handleRespondAction(state, 2, true, "test-dodge-2").success, true);
assert.equal(state.phase, "PLAY");
assert.equal(target.hp, 4);

state.slashesUsedThisTurn = 0;
caster.hand.push({ id: "test-slash-2", name: "Trảm", category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.ATTACK_NORMAL, suit: "Club" });
target.hand = [{ id: "test-dodge-3", name: "Đỡ", category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.DODGE, suit: "Heart" }];
assert.equal(handlePlayCard(state, 1, "test-slash-2", 2).success, true);
assert.equal(handleRespondAction(state, 2, true, "test-dodge-3").success, true);
assert.equal(state.phase, "AWAIT_SLASH_DEFENSE");
assert.equal(handleRespondAction(state, 2, false, null).success, true);
assert.equal(target.hp, 3);

console.log("Dũng Nữ OK");
