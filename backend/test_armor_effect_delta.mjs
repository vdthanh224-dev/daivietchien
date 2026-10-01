import assert from "node:assert/strict";
import { initGame, applyDamageToPlayer, sanitizeGameStateForClient } from "./functions/game-engine/src/gameEngine.js";
import { CARD_SUBTYPES } from "./functions/game-engine/src/deck.js";

const state = initGame("armor-vfx", [
  { seat: 1, userId: "one", generalName: "One", maxHp: 4 },
  { seat: 2, userId: "two", generalName: "Two", maxHp: 4 },
  { seat: 3, userId: "three", generalName: "Three", maxHp: 4 },
  { seat: 4, userId: "four", generalName: "Four", maxHp: 4 }
]);
const target = state.players[1];
target.aoBaoCharges = 2;
target.equipments = [{ id: "ao-bao", name: "Áo Bào Hoàng Tộc", subType: CARD_SUBTYPES.ARMOR }];
state.activeCard = { casterSeat: 1 };

const wineSlash = applyDamageToPlayer(state, 2, 2, "Hủ Rượu Trảm", "NORMAL", true);

assert.equal(wineSlash.finalDamage, 0);
assert.equal(target.hp, 4);
assert.equal(state.lastAction.armorEffect, "AO_BAO_HOANG_TOC");
assert.equal(state.lastAction.armorChargesRemaining, 0);
assert.equal(state.lastDelta.armorExpired, true);

target.hp = 4;
target.aoBaoCharges = 1;
target.equipments = [{ id: "ao-bao", name: "Áo Bào Hoàng Tộc", subType: CARD_SUBTYPES.ARMOR }];
const finalBlock = applyDamageToPlayer(state, 2, 2, "Hủ Rượu Trảm", "NORMAL", true);
assert.equal(finalBlock.finalDamage, 1);
assert.equal(target.hp, 3);
assert.equal(state.lastAction.armorChargesRemaining, 0);
assert.equal(state.lastDelta.armorExpired, true);
assert.equal(sanitizeGameStateForClient(state, 1).delta.armorEffect, "AO_BAO_HOANG_TOC");
console.log("Armor VFX delta: PASS");
