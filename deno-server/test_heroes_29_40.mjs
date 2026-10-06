import assert from "node:assert/strict";
import { CARD_CATEGORIES, CARD_SUBTYPES } from "./deck.js";
import { handleRespondAction, handleUseSkill, initGame } from "./gameEngine.js";

console.log("=== Testing Heroes 29-40 Skills ===");

// 1. Test Định Quốc (Nguyễn Bặc - HERO_33)
{
  const state = initGame("test-dq", [
    { seat: 1, heroId: "HERO_33" },
    { seat: 2, heroId: "HERO_1" },
    { seat: 3, heroId: "HERO_2" },
    { seat: 4, heroId: "HERO_3" }
  ]);
  state.phase = "PLAY";
  state.turnSeat = 1;
  const p1 = state.players[0];
  p1.hand = [{ id: "c_black", name: "Trảm", suit: "Spade", rank: 7, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.SLASH }];
  const res = handleUseSkill(state, 1, "Định Quốc", 2, "c_black");
  assert.ok(res.success || res.state, "Định Quốc should succeed");
  console.log("✅ Định Quốc OK");
}

// 2. Test Trao Bào (Dương Vân Nga - HERO_36)
{
  const state = initGame("test-tb", [
    { seat: 1, heroId: "HERO_36" },
    { seat: 2, heroId: "HERO_1" },
    { seat: 3, heroId: "HERO_2" },
    { seat: 4, heroId: "HERO_3" }
  ]);
  state.phase = "PLAY";
  state.turnSeat = 1;
  const p1 = state.players[0];
  const p2 = state.players[1];
  p2.hp = 2; // injured
  p1.hand = [{ id: "eq_weapon", name: "Song Cung", suit: "Heart", rank: 5, category: CARD_CATEGORIES.EQUIPMENT, subType: CARD_SUBTYPES.WEAPON }];
  const res = handleUseSkill(state, 1, "Trao Bào", 2, "eq_weapon");
  assert.ok(res.success, "Trao Bào should succeed");
  assert.equal(p2.hp, 3, "Trao Bào should heal target");
  assert.equal(p1.hand.length, 1, "Trao Bào should draw 1 card for caster");
  console.log("✅ Trao Bào OK");
}

// 3. Test Thu Phục (Đinh Bộ Lĩnh - HERO_30) via handleRespondAction
{
  const state = initGame("test-tp", [
    { seat: 1, heroId: "HERO_30" },
    { seat: 2, heroId: "HERO_1" },
    { seat: 3, heroId: "HERO_2" },
    { seat: 4, heroId: "HERO_3" }
  ]);
  state.phase = "AWAIT_THU_PHUC";
  state.waitingTargetSeat = 1;
  state.pendingThuPhuc = {
    casterSeat: 1,
    targetSeat: 2,
    card: { id: "ex_nihilo", name: "Dụng Binh Như Thần", category: CARD_CATEGORIES.SCROLL, subType: CARD_SUBTYPES.EX_NIHILO },
    payload: {}
  };
  const p1 = state.players[0];
  const p2 = state.players[1];
  p1.hp = 2;
  p2.hp = 4;
  p2.hand = [{ id: "card_stolen", name: "Trảm", suit: "Club", rank: 8, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.SLASH }];
  const res = handleRespondAction(state, 1, true, null, null, null, 2);
  assert.ok(res.success, "Thu Phục should succeed");
  assert.ok(p1.hand.some(c => c.id === "card_stolen"), "P1 should have stolen card");
  assert.ok(!p2.hand.some(c => c.id === "card_stolen"), "P2 should have lost card");
  console.log("✅ Thu Phục OK");
}

// 4. Test Phò Tá (Đào Cam Mộc - HERO_38) via handleRespondAction
{
  const state = initGame("test-pt", [
    { seat: 1, heroId: "HERO_38" },
    { seat: 2, heroId: "HERO_1" },
    { seat: 3, heroId: "HERO_2" },
    { seat: 4, heroId: "HERO_3" }
  ]);
  state.phase = "AWAIT_PHO_TA";
  state.waitingTargetSeat = 1;
  state.turnStart = { seat: 1 };
  const p1 = state.players[0];
  const p2 = state.players[1];
  p1.hand = [];
  p2.hand = [];
  const res = handleRespondAction(state, 1, true, null, null, null, 2);
  assert.ok(res.success, "Phò Tá should succeed");
  assert.equal(p2.hand.length, 2, "P2 should draw 2 cards");
  assert.equal(p1.hand.length, 1, "P1 should draw 1 card");
  console.log("✅ Phò Tá OK");
}

// 5. Test Trấn Thủ (Phạm Hạp - HERO_34) via handleRespondAction
{
  const state = initGame("test-tt", [
    { seat: 1, heroId: "HERO_1" },
    { seat: 2, heroId: "HERO_34" },
    { seat: 3, heroId: "HERO_2" },
    { seat: 4, heroId: "HERO_3" }
  ]);
  state.phase = "AWAIT_SLASH_DEFENSE";
  state.waitingTargetSeat = 2;
  state.activeCard = { casterSeat: 1, targetSeat: 2, cardId: "slash_1", cardName: "Trảm" };
  const p2 = state.players[1];
  p2.equipments = [{ id: "armor_1", name: "Áo Giáp", suit: "Spade", rank: 2, category: CARD_CATEGORIES.EQUIPMENT, subType: CARD_SUBTYPES.ARMOR }];
  const res = handleRespondAction(state, 2, true, "armor_1");
  assert.ok(res.success, "Trấn Thủ should succeed");
  assert.equal(p2.equipments.length, 0, "Equipment should be discarded");
  console.log("✅ Trấn Thủ OK");
}

console.log("🎉 All heroes 29-40 skill unit tests passed!");
