import assert from 'node:assert/strict';
import { CARD_CATEGORIES, CARD_SUBTYPES } from './functions/game-engine/src/deck.js';
import {
  initGame,
  handlePlayCard,
  handleUseSkill,
  handleEndTurn,
  handleAIStep
} from './functions/game-engine/src/gameEngine.js';
import {
  getHeroById,
  heroHasSkill
} from './functions/game-engine/src/heroes.js';

console.log("=== Testing Cao Lỗ: Cơ Biến Skill ===");

// 1. Check Hero definition and skills
const caoLo = getHeroById("HERO_1");
assert.equal(caoLo.name, "Cao Lỗ");
assert.deepEqual(caoLo.skills, ["CHE_NO", "CO_BIEN"]);
assert.equal(caoLo.maxHp, 4);

function createTestState() {
  return initGame("TEST_CAO_LO_CO_BIEN", [
    { id: "u1", name: "Cao Lỗ", heroId: "HERO_1", seat: 1, isAI: false },
    { id: "u2", name: "Đào Hãn", heroId: "HERO_2", seat: 2, isAI: true },
    { id: "u3", name: "Thi Sách", heroId: "HERO_3", seat: 3, isAI: true },
    { id: "u4", name: "Lê Chân", heroId: "HERO_4", seat: 4, isAI: true }
  ]);
}

// 2. Mechanics: Exchange Black card from hand
{
  const state = createTestState();
  const p1 = state.players[0];
  assert.equal(heroHasSkill(p1, "CO_BIEN"), true);
  assert.equal(heroHasSkill(p1, "CHE_NO"), true);
  assert.equal(heroHasSkill(p1, "LIEN_CHAU"), false);

  state.phase = "PLAY";
  state.turnSeat = 1;
  p1.hand = [
    { id: "CARD_SPADE", name: "Trảm Đen", suit: "Spade", rank: 7, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.ATTACK_NORMAL },
    { id: "CARD_HEART", name: "Bánh Chưng", suit: "Heart", rank: 9, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.PEACH },
    { id: "CARD_CLUB", name: "Đỡ Đen", suit: "Club", rank: 3, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.DODGE }
  ];
  state._deck = [
    { id: "DRAWN_1", name: "Cẩm Nang 1", suit: "Diamond", rank: 5, category: CARD_CATEGORIES.INSTANT_SCROLL, subType: CARD_SUBTYPES.DISMANTLE },
    { id: "DRAWN_2", name: "Cẩm Nang 2", suit: "Heart", rank: 6, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.PEACH }
  ];
  state._discard = [];

  // A. Red card cannot be exchanged
  const redRes = handleUseSkill(state, 1, "Cơ Biến", 0, "CARD_HEART");
  assert.ok(redRes.error);
  assert.match(redRes.error, /Cơ Biến cần chọn 1 lá bài Đen/);

  // B. Black card (Spade) exchanged successfully
  const spadeRes = handleUseSkill(state, 1, "Cơ Biến", 0, "CARD_SPADE");
  assert.equal(spadeRes.success, true);
  assert.equal(p1.hand.some(c => c.id === "CARD_SPADE"), false);
  assert.equal(p1.hand.some(c => c.id === "DRAWN_2"), true);
  assert.equal(state._discard.some(c => c.id === "CARD_SPADE"), true);
  assert.equal(state.lastAction.type, "CO_BIEN_TRIGGERED");

  // C. Second Black card (Club) can also be exchanged in same turn (unlimited active recast)
  const clubRes = handleUseSkill(state, 1, "Cơ Biến", 0, "CARD_CLUB");
  assert.equal(clubRes.success, true);
  assert.equal(p1.hand.some(c => c.id === "CARD_CLUB"), false);
  assert.equal(p1.hand.some(c => c.id === "DRAWN_1"), true);
  assert.equal(state._discard.some(c => c.id === "CARD_CLUB"), true);
  console.log("✅ Cao Lỗ: Cơ Biến đổi bài Đen trên tay thành công");
}

// 3. Mechanics: Exchange Black card from Equipment
{
  const state = createTestState();
  const p1 = state.players[0];
  state.phase = "PLAY";
  state.turnSeat = 1;
  p1.hand = [
    { id: "HAND_RED", name: "Bánh Chưng", suit: "Heart", rank: 9, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.PEACH }
  ];
  p1.equipments = [
    { id: "BLACK_ARMOR", name: "Giáp Hắc Thiết", suit: "Spade", rank: 2, category: CARD_CATEGORIES.EQUIPMENT, subType: CARD_SUBTYPES.ARMOR }
  ];
  state._deck = [
    { id: "DRAWN_EQ", name: "Trảm Rút", suit: "Club", rank: 10, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.ATTACK_NORMAL }
  ];

  const eqRes = handleUseSkill(state, 1, "Cơ Biến", 0, "BLACK_ARMOR");
  assert.equal(eqRes.success, true);
  assert.equal(p1.equipments.length, 0);
  assert.equal(p1.hand.some(c => c.id === "DRAWN_EQ"), true);
  assert.equal(state._discard.some(c => c.id === "BLACK_ARMOR"), true);
  console.log("✅ Cao Lỗ: Cơ Biến đổi trang bị Đen thành công");
}

// 4. Phase and Turn constraints
{
  const state = createTestState();
  state.phase = "AWAIT_SLASH_DEFENSE";
  state.turnSeat = 1;
  const p1 = state.players[0];
  p1.hand = [{ id: "C1", name: "T", suit: "Spade", rank: 1, category: 0, subType: 0 }];
  const wrongPhaseRes = handleUseSkill(state, 1, "Cơ Biến", 0, "C1");
  assert.ok(wrongPhaseRes.error);
  assert.match(wrongPhaseRes.error, /Giai đoạn Ra bài/);

  state.phase = "PLAY";
  state.turnSeat = 2; // Not Cao Lỗ's turn
  const wrongTurnRes = handleUseSkill(state, 1, "Cơ Biến", 0, "C1");
  assert.ok(wrongTurnRes.error);
  console.log("✅ Cao Lỗ: Ràng buộc phase và turn hoạt động chính xác");
}

// 5. AI Cao Lỗ uses Cơ Biến in handleAIStep
{
  const state = createTestState();
  const p1 = state.players[0];
  p1.isAI = true;
  state.phase = "PLAY";
  state.turnSeat = 1;
  state.slashesUsedThisTurn = 1; // Already slashed, so extra slash or non-essential black card will be cycled
  p1.hand = [
    { id: "AI_BLACK_DODGE", name: "Đỡ", suit: "Spade", rank: 2, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.DODGE }
  ];
  state._deck = [
    { id: "AI_NEW_CARD", name: "Lá Mới", suit: "Heart", rank: 9, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.PEACH }
  ];

  const aiStep = handleAIStep(state, 1);
  assert.equal(aiStep.success, true);
  assert.equal(state.lastAction.type, "CO_BIEN_TRIGGERED");
  assert.equal(p1.hand.some(c => c.id === "AI_NEW_CARD"), true);
  console.log("✅ AI Cao Lỗ: Tự động dùng Cơ Biến chu chuyển bài Đen thành công");
}

console.log("🎉 ALL CAO LỖ CƠ BIẾN TESTS PASSED!");
