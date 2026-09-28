import assert from "node:assert/strict";
import { CARD_CATEGORIES, CARD_SUBTYPES } from "./deck.js";
import { handleRespondAction, handleUseSkill, initGame } from "./gameEngine.js";

const state = initGame("bat-na-test", [
  { seat: 1, heroId: "HERO_6" },
  { seat: 2, heroId: "HERO_2" },
  { seat: 3, heroId: "HERO_1" },
  { seat: 4, heroId: "HERO_3" }
]);
const caster = state.players[0];
const target = state.players[1];
caster.hand.push({ id: "bat-na-source", name: "Bánh Chưng", category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.PEACH, suit: "Heart" });
state.slashesUsedThisTurn = 1;

const result = handleUseSkill(state, 1, "Bát Nạ", 2, "bat-na-source");
assert.equal(result.success, true);
assert.equal(state.phase, "AWAIT_SLASH_DEFENSE");
assert.equal(state.activeCard.subType, CARD_SUBTYPES.ATTACK_NORMAL);
assert.equal(state.activeCard.countsTowardTurnSlashLimit, false);
assert.equal(state.slashesUsedThisTurn, 1);
assert.equal(caster.usedSkills.BatNa, true);
assert.equal(caster.hand.some((card) => card.id === "bat-na-source"), false);

handleRespondAction(state, 2, false, null);
assert.equal(target.hp, target.maxHp - 1);
caster.hand.push({ id: "bat-na-source-2", name: "Đỡ", category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.DODGE, suit: "Diamond" });
assert.match(handleUseSkill(state, 1, "Bát Nạ", 2, "bat-na-source-2").error, /1 lần mỗi lượt/);

console.log("Bát Nạ OK");
