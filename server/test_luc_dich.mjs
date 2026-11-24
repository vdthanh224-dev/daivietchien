import assert from "node:assert/strict";
import {
  continueTurnStart,
  initGame
} from "./functions/game-engine/src/gameEngine.js";
import { CARD_CATEGORIES, CARD_SUBTYPES } from "./functions/game-engine/src/deck.js";

function createTestState(casterHeroId = "HERO_16") {
  const state = initGame("test-luc-dich", [
    { seat: 1, heroId: casterHeroId, generalName: "P1" },
    { seat: 2, heroId: "HERO_1", generalName: "P2" },
    { seat: 3, heroId: "HERO_2", generalName: "P3" },
    { seat: 4, heroId: "HERO_3", generalName: "P4" }
  ]);
  state.phase = "START_TURN";
  state.turnSeat = 1;
  state.turnStart = { seat: 1, drawCount: 2 };
  for (const p of state.players) {
    p.hand = [];
    p.equipments = [];
    p.judgements = [];
    p.hp = p.maxHp;
    p.usedSkills = {};
  }
  // Fill deck with generic cards
  state._deck = Array.from({ length: 50 }, (_, i) => ({
    id: `card_${i}`,
    name: "Trảm",
    suit: "Spade",
    rank: 7,
    category: CARD_CATEGORIES.BASIC,
    subType: CARD_SUBTYPES.ATTACK_NORMAL
  }));
  state._discard = [];
  return state;
}

// 1. Phùng Hải with 0 equipments -> draws 2 base + 4 extra = 6 cards
{
  const state = createTestState("HERO_16");
  continueTurnStart(state);
  assert.equal(state.players[0].hand.length, 6, "Phùng Hải 0 trang bị phải rút 6 lá (2 cơ bản + 4 Lực Địch)");
  const lucDichAction = state.actionHistory.find((a) => a.type === "LUC_DICH_DRAW");
  assert.ok(lucDichAction, "Phải ghi nhận action LUC_DICH_DRAW");
  assert.equal(lucDichAction.skillActivations[0].name, "Lực Địch");
  assert.ok(lucDichAction.description.includes("4 lá bài"));
  console.log("✅ Case 1: 0 equipments -> +4 extra cards (total 6)");
}

// 2. Phùng Hải with 1 equipment -> draws 2 base + 3 extra = 5 cards
{
  const state = createTestState("HERO_16");
  state.players[0].equipments.push({
    id: "WEAPON_1",
    name: "Kiếm Thuận Thiên",
    subType: CARD_SUBTYPES.WEAPON,
    category: CARD_CATEGORIES.EQUIPMENT
  });
  continueTurnStart(state);
  assert.equal(state.players[0].hand.length, 5, "Phùng Hải 1 trang bị phải rút 5 lá (2 cơ bản + 3 Lực Địch)");
  const lucDichAction = state.actionHistory.find((a) => a.type === "LUC_DICH_DRAW");
  assert.ok(lucDichAction && lucDichAction.description.includes("3 lá bài"));
  console.log("✅ Case 2: 1 equipment -> +3 extra cards (total 5)");
}

// 3. Phùng Hải with 2 equipments -> draws 2 base + 2 extra = 4 cards
{
  const state = createTestState("HERO_16");
  state.players[0].equipments.push(
    { id: "WEAPON_1", name: "Vũ khí 1", subType: CARD_SUBTYPES.WEAPON, category: CARD_CATEGORIES.EQUIPMENT },
    { id: "WEAPON_2", name: "Vũ khí 2", subType: CARD_SUBTYPES.WEAPON, category: CARD_CATEGORIES.EQUIPMENT }
  );
  continueTurnStart(state);
  assert.equal(state.players[0].hand.length, 4, "Phùng Hải 2 trang bị phải rút 4 lá (2 cơ bản + 2 Lực Địch)");
  const lucDichAction = state.actionHistory.find((a) => a.type === "LUC_DICH_DRAW");
  assert.ok(lucDichAction && lucDichAction.description.includes("2 lá bài"));
  console.log("✅ Case 3: 2 equipments -> +2 extra cards (total 4)");
}

// 4. Phùng Hải with 3 equipments -> draws 2 base + 1 extra = 3 cards
{
  const state = createTestState("HERO_16");
  state.players[0].equipments.push(
    { id: "WEAPON_1", name: "Vũ khí 1", subType: CARD_SUBTYPES.WEAPON, category: CARD_CATEGORIES.EQUIPMENT },
    { id: "ARMOR_1", name: "Giáp", subType: CARD_SUBTYPES.ARMOR, category: CARD_CATEGORIES.EQUIPMENT },
    { id: "HORSE_1", name: "Ngựa +", subType: CARD_SUBTYPES.DEFENSIVE_HORSE, category: CARD_CATEGORIES.EQUIPMENT }
  );
  continueTurnStart(state);
  assert.equal(state.players[0].hand.length, 3, "Phùng Hải 3 trang bị phải rút 3 lá (2 cơ bản + 1 Lực Địch)");
  const lucDichAction = state.actionHistory.find((a) => a.type === "LUC_DICH_DRAW");
  assert.ok(lucDichAction && lucDichAction.description.includes("1 lá bài"));
  console.log("✅ Case 4: 3 equipments -> +1 extra card (total 3)");
}

// 5. Phùng Hải with 4 equipments -> draws 2 base + 0 extra = 2 cards (no action)
{
  const state = createTestState("HERO_16");
  state.players[0].equipments.push(
    { id: "WEAPON_1", name: "Vũ khí 1", subType: CARD_SUBTYPES.WEAPON, category: CARD_CATEGORIES.EQUIPMENT },
    { id: "WEAPON_2", name: "Vũ khí 2", subType: CARD_SUBTYPES.WEAPON, category: CARD_CATEGORIES.EQUIPMENT },
    { id: "ARMOR_1", name: "Giáp", subType: CARD_SUBTYPES.ARMOR, category: CARD_CATEGORIES.EQUIPMENT },
    { id: "HORSE_1", name: "Ngựa +", subType: CARD_SUBTYPES.DEFENSIVE_HORSE, category: CARD_CATEGORIES.EQUIPMENT }
  );
  continueTurnStart(state);
  assert.equal(state.players[0].hand.length, 2, "Phùng Hải 4 trang bị chỉ rút 2 lá cơ bản");
  const lucDichAction = state.actionHistory.find((a) => a.type === "LUC_DICH_DRAW");
  assert.equal(lucDichAction, undefined, "Không kích hoạt action khi không rút thêm");
  console.log("✅ Case 5: 4 equipments -> +0 extra cards (total 2)");
}

// 6. Phùng Hải with 5 equipments -> draws 2 base + 0 extra = 2 cards
{
  const state = createTestState("HERO_16");
  state.players[0].equipments.push(
    { id: "WEAPON_1", name: "Vũ khí 1", subType: CARD_SUBTYPES.WEAPON, category: CARD_CATEGORIES.EQUIPMENT },
    { id: "WEAPON_2", name: "Vũ khí 2", subType: CARD_SUBTYPES.WEAPON, category: CARD_CATEGORIES.EQUIPMENT },
    { id: "ARMOR_1", name: "Giáp", subType: CARD_SUBTYPES.ARMOR, category: CARD_CATEGORIES.EQUIPMENT },
    { id: "HORSE_1", name: "Ngựa +", subType: CARD_SUBTYPES.DEFENSIVE_HORSE, category: CARD_CATEGORIES.EQUIPMENT },
    { id: "HORSE_2", name: "Ngựa -", subType: CARD_SUBTYPES.OFFENSIVE_HORSE, category: CARD_CATEGORIES.EQUIPMENT }
  );
  continueTurnStart(state);
  assert.equal(state.players[0].hand.length, 2, "Phùng Hải 5 trang bị chỉ rút 2 lá cơ bản");
  console.log("✅ Case 6: 5 equipments -> +0 extra cards (total 2)");
}

// 7. Non-Phùng-Hải hero with 0 equipments -> draws 2 base cards only
{
  const state = createTestState("HERO_1"); // Cao Lỗ
  continueTurnStart(state);
  assert.equal(state.players[0].hand.length, 2, "Tướng khác không có Lực Địch chỉ rút 2 lá");
  const lucDichAction = state.actionHistory.find((a) => a.type === "LUC_DICH_DRAW");
  assert.equal(lucDichAction, undefined);
  console.log("✅ Case 7: Non-Phùng-Hải hero draws standard 2 cards");
}

console.log("🎉 All Lực Địch (Phùng Hải) unit tests passed!");
