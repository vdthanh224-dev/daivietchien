import assert from "node:assert/strict";
import { applyDamageToPlayer, handleEndTurn, handlePlayCard, handleRespondAction, handleToggleSkill, handleUseSkill, initGame, sanitizeGameStateForClient } from "./functions/game-engine/src/gameEngine.js";
import { CARD_CATEGORIES, CARD_SUBTYPES } from "./functions/game-engine/src/deck.js";

const state = initGame("che-no", [
  { seat: 1, userId: "cao-lo", heroId: "1", generalName: "Cao Lỗ", maxHp: 4 },
  { seat: 2, userId: "two", generalName: "Two", maxHp: 4 },
  { seat: 3, userId: "three", generalName: "Three", maxHp: 4 },
  { seat: 4, userId: "four", generalName: "Four", maxHp: 4 }
]);
const caoLo = state.players[0];
caoLo.hand = [{ id: "spade-card", name: "Đỡ", suit: "Spade", rank: 2, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.DODGE, desc: "Hóa giải Trảm" }];

assert.equal(handleToggleSkill(state, 1, "Chế Nỏ").success, true);
assert.equal(caoLo.hand[0].name, "Nỏ Thần Kim Quy");
assert.equal(caoLo.hand[0].subType, CARD_SUBTYPES.WEAPON);
assert.equal(handleToggleSkill(state, 1, "Chế Nỏ").success, true);
assert.equal(caoLo.hand[0].name, "Đỡ");
assert.equal(caoLo.hand[0].subType, CARD_SUBTYPES.DODGE);
assert.equal(handleToggleSkill(state, 2, "Chế Nỏ").error, "Chỉ Cao Lỗ mới có thể dùng Chế Nỏ");

const nameOnlyCaoLoState = initGame("cao-lo-name", [
  { seat: 1, userId: "cao-lo-name", generalName: "Cao Lỗ", maxHp: 4 },
  { seat: 2, userId: "two", generalName: "Two", maxHp: 4 },
  { seat: 3, userId: "three", generalName: "Three", maxHp: 4 },
  { seat: 4, userId: "four", generalName: "Four", maxHp: 4 }
]);
assert.equal(handleToggleSkill(nameOnlyCaoLoState, 1, "Chế Nỏ").success, true);

caoLo.equipments = [{ id: "no-than", name: "Nỏ Thần Kim Quy", subType: CARD_SUBTYPES.WEAPON }];
caoLo.hand = [
  { id: "slash", name: "Trảm Thường", suit: "Heart", rank: 7, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.ATTACK_NORMAL, desc: "Trảm" },
  { id: "cost", name: "Đỡ", suit: "Club", rank: 2, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.DODGE, desc: "Đỡ" }
];
assert.equal(handlePlayCard(state, 1, "slash", 2, { targetSeats: [2, 4], lienChauCardId: "cost" }).success, true);
assert.deepEqual(state.activeCard.lienChauTargets, [4]);
assert.equal(caoLo.hand.length, 0);
assert.equal(handleRespondAction(state, 2, false).success, true);
assert.equal(state.waitingTargetSeat, 4);

const nearDeathState = initGame("lien-chau-near-death", [
  { seat: 1, userId: "cao-lo", heroId: "1", generalName: "Cao Lỗ", maxHp: 4 },
  { seat: 2, userId: "two", generalName: "Two", maxHp: 4 },
  { seat: 3, userId: "three", generalName: "Three", maxHp: 4 },
  { seat: 4, userId: "four", generalName: "Four", maxHp: 4 }
]);
const nearDeathCaoLo = nearDeathState.players[0];
nearDeathCaoLo.equipments = [{ id: "no-than", name: "Nỏ Thần Kim Quy", subType: CARD_SUBTYPES.WEAPON }];
nearDeathCaoLo.hand = [
  { id: "near-death-slash", name: "Trảm Thường", suit: "Heart", rank: 7, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.ATTACK_NORMAL, desc: "Trảm" },
  { id: "near-death-cost", name: "Đỡ", suit: "Club", rank: 2, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.DODGE, desc: "Đỡ" }
];
nearDeathState.players[1].hp = 1;
for (const player of nearDeathState.players.slice(1)) player.hand = [];
assert.equal(handlePlayCard(nearDeathState, 1, "near-death-slash", 2, { targetSeats: [2, 4], lienChauCardId: "near-death-cost" }).success, true);
assert.equal(handleRespondAction(nearDeathState, 2, false).success, true);
while (nearDeathState.phase === "AWAIT_NEAR_DEATH") {
  assert.equal(handleRespondAction(nearDeathState, nearDeathState.waitingTargetSeat, false).success, true);
}
assert.equal(nearDeathState.waitingTargetSeat, 4);

const blockedState = initGame("lien-chau-blocked", [
  { seat: 1, userId: "cao-lo", heroId: "1", generalName: "Cao Lỗ", maxHp: 4 },
  { seat: 2, userId: "two", generalName: "Two", maxHp: 4 },
  { seat: 3, userId: "three", generalName: "Three", maxHp: 4 },
  { seat: 4, userId: "four", generalName: "Four", maxHp: 4 }
]);
const blockedCaoLo = blockedState.players[0];
blockedCaoLo.equipments = [{ id: "no-than", name: "Nỏ Thần Kim Quy", subType: CARD_SUBTYPES.WEAPON }];
blockedCaoLo.hand = [
  { id: "blocked-slash", name: "Trảm Thường", suit: "Heart", rank: 7, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.ATTACK_NORMAL, desc: "Trảm" },
  { id: "blocked-cost", name: "Đỡ", suit: "Club", rank: 2, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.DODGE, desc: "Đỡ" }
];
blockedState.players[1].equipments = [{ id: "giap-dong", name: "Giáp Đồng Sơn Vi", subType: CARD_SUBTYPES.ARMOR }];
assert.equal(handlePlayCard(blockedState, 1, "blocked-slash", 2, { targetSeats: [2, 4], lienChauCardId: "blocked-cost" }).success, true);
assert.equal(blockedState.waitingTargetSeat, 4);

const daoHanState = initGame("dao-han", [
  { seat: 1, userId: "dao-han", generalName: "Đào Hãn", maxHp: 4 },
  { seat: 2, userId: "two", generalName: "Two", maxHp: 4 },
  { seat: 3, userId: "three", generalName: "Three", maxHp: 4 },
  { seat: 4, userId: "four", generalName: "Four", maxHp: 4 }
]);
const daoHan = daoHanState.players[0];
daoHan.hand = [{ id: "dao-han-slash", name: "Trảm Thường", suit: "Heart", rank: 7, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.ATTACK_NORMAL, desc: "Trảm" }];
assert.equal(handlePlayCard(daoHanState, 1, "dao-han-slash", 3).success, true);
assert.equal(daoHan.hand.length, 1);

const uatKhiState = initGame("uat-khi", [
  { seat: 1, userId: "thi-sach", heroId: "3", generalName: "Thi Sách", maxHp: 4 },
  { seat: 2, userId: "two", generalName: "Two", maxHp: 4 },
  { seat: 3, userId: "three", generalName: "Three", maxHp: 4 },
  { seat: 4, userId: "four", generalName: "Four", maxHp: 4 }
]);
uatKhiState.players[0].hp = 2;
const uatTargetHandBefore = uatKhiState.players[1].hand.length;
assert.equal(applyDamageToPlayer(uatKhiState, 1, 1).enteredNearDeath, false);
assert.deepEqual(uatKhiState.uatKhiQueue, [{ seat: 1 }]);
assert.deepEqual(sanitizeGameStateForClient(uatKhiState, 1).uatKhiQueue, [{ seat: 1 }]);
assert.equal(handleUseSkill(uatKhiState, 1, "Uất Khí", 2).success, true);
assert.equal(uatKhiState.players[1].hand.length, uatTargetHandBefore + 1);
assert.deepEqual(uatKhiState.uatKhiQueue, []);

const hichNghiaState = initGame("hich-nghia", [
  { seat: 1, userId: "thi-sach", heroId: "HERO_3", generalName: "Thi Sách", maxHp: 4 },
  { seat: 2, userId: "two", generalName: "Two", maxHp: 4 },
  { seat: 3, userId: "three", generalName: "Three", maxHp: 4 },
  { seat: 4, userId: "four", generalName: "Four", maxHp: 4 }
]);
hichNghiaState.players[0].hp = 1;
hichNghiaState.players[0].hand = [];
assert.equal(applyDamageToPlayer(hichNghiaState, 1, 1).enteredNearDeath, true);
assert.equal(hichNghiaState.players[0].hand.length, 3);

const leChanState = initGame("le-chan", [
  { seat: 1, userId: "le-chan", heroId: "4", generalName: "Lê Chân", maxHp: 3 },
  { seat: 2, userId: "two", generalName: "Two", maxHp: 4 },
  { seat: 3, userId: "three", generalName: "Three", maxHp: 4 },
  { seat: 4, userId: "four", generalName: "Four", maxHp: 4 }
]);
leChanState.players[1].equipments = [{ id: "target-armor", name: "Giáp Đồng Sơn Vi", subType: CARD_SUBTYPES.ARMOR }];
assert.equal(handleUseSkill(leChanState, 1, "Triều Dâng", 2).success, true);
assert.equal(leChanState.phase, "AWAIT_TARGET_CARD");
assert.equal(handleRespondAction(leChanState, 1, true, null, "EQUIPMENT:target-armor").success, true);
assert.equal(leChanState.players[1].equipments.length, 0);
leChanState.players[0].hand = leChanState.players[0].hand.slice(0, 3);
const lapLangHandBefore = leChanState.players[0].hand.length;
assert.equal(handleEndTurn(leChanState, 1).success, true);
assert.equal(leChanState.players[0].hand.length, lapLangHandBefore + 2);

const leChanDamagedState = initGame("le-chan-damaged", [
  { seat: 1, userId: "le-chan", heroId: "HERO_4", generalName: "Lê Chân", maxHp: 3 },
  { seat: 2, userId: "two", generalName: "Two", maxHp: 4 },
  { seat: 3, userId: "three", generalName: "Three", maxHp: 4 },
  { seat: 4, userId: "four", generalName: "Four", maxHp: 4 }
]);
leChanDamagedState.activeCard = { casterSeat: 1 };
applyDamageToPlayer(leChanDamagedState, 2, 1);
const damagedLapLangHandBefore = leChanDamagedState.players[0].hand.length;
assert.equal(handleEndTurn(leChanDamagedState, 1).success, true);
assert.equal(leChanDamagedState.players[0].hand.length, damagedLapLangHandBefore);
console.log("Chế Nỏ toggle: PASS");
