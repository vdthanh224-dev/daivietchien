import assert from 'node:assert/strict';
import { CARD_CATEGORIES, CARD_SUBTYPES } from './functions/game-engine/src/deck.js';
import {
  initGame,
  handlePlayCard,
  handleToggleSkill,
  handleUseSkill,
  handleEndTurn
} from './functions/game-engine/src/gameEngine.js';
import {
  getHeroById,
  heroHasSkill,
  SKILLS
} from './functions/game-engine/src/heroes.js';

console.log("=== Testing Cao Lỗ: Chế Nỏ Skill & Mechanics (4 Colors: Đỏ, Trắng, Vàng, Đen) ===");

// 1. Check Hero definition and skills
const caoLo = getHeroById("HERO_1");
assert.equal(caoLo.name, "Cao Lỗ");
assert.deepEqual(caoLo.skills, ["CHE_NO"], "Cao Lỗ chỉ có skill 1 Chế Nỏ, skill 2 Cơ Biến đã được loại bỏ");
assert.equal(caoLo.maxHp, 4);
assert.match(SKILLS.CHE_NO.description, /Khi sử dụng Nỏ Thần Kim Quy, bốc 1 lá bài/, "Mô tả Chế Nỏ có hiệu ứng bốc 1 lá bài");

function createTestState() {
  return initGame("TEST_CAO_LO_CHE_NO", [
    { id: "u1", name: "Cao Lỗ", heroId: "HERO_1", seat: 1, isAI: false },
    { id: "u2", name: "Đào Hãn", heroId: "HERO_2", seat: 2, isAI: true },
    { id: "u3", name: "Thi Sách", heroId: "HERO_3", seat: 3, isAI: true },
    { id: "u4", name: "Lê Chân", heroId: "HERO_4", seat: 4, isAI: true }
  ]);
}

// 2. Chế Nỏ toggling: CHỈ lá bài ĐEN (Black) biến thành Nỏ Thần Kim Quy; Vàng (Club), Đỏ (Heart), Trắng (Diamond) giữ nguyên
{
  const state = createTestState();
  const p1 = state.players[0];
  assert.equal(heroHasSkill(p1, "CHE_NO"), true);
  assert.equal(heroHasSkill(p1, "CO_BIEN"), false, "Không còn Cơ Biến");

  state.phase = "PLAY";
  state.turnSeat = 1;
  p1.hand = [
    { id: "CARD_BLACK", name: "Trảm Đen", suit: "Spade", rank: 7, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.ATTACK_NORMAL },
    { id: "CARD_YELLOW", name: "Đỡ Vàng", suit: "Club", rank: 3, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.DODGE },
    { id: "CARD_RED", name: "Bánh Chưng Đỏ", suit: "Heart", rank: 9, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.PEACH },
    { id: "CARD_WHITE", name: "Trảm Trắng", suit: "Diamond", rank: 5, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.ATTACK_NORMAL }
  ];

  // Bật Chế Nỏ
  const toggleOn = handleToggleSkill(state, 1, "Chế Nỏ");
  assert.equal(toggleOn.success, true);
  assert.equal(p1.activeSkills["Chế Nỏ"], true);

  // CHỈ lá ĐEN biến thành Nỏ Thần Kim Quy (Trang bị / Vũ khí)
  assert.equal(p1.hand[0].name, "Nỏ Thần Kim Quy");
  assert.equal(p1.hand[0].category, CARD_CATEGORIES.EQUIPMENT);
  assert.equal(p1.hand[0].subType, CARD_SUBTYPES.WEAPON);

  // Lá VÀNG (Club) KHÔNG ĐƯỢC biến đổi, giữ nguyên là Đỡ Vàng
  assert.equal(p1.hand[1].name, "Đỡ Vàng");
  assert.equal(p1.hand[1].category, CARD_CATEGORIES.BASIC);

  // Lá ĐỎ (Heart) giữ nguyên
  assert.equal(p1.hand[2].name, "Bánh Chưng Đỏ");
  assert.equal(p1.hand[2].category, CARD_CATEGORIES.BASIC);

  // Lá TRẮNG (Diamond) giữ nguyên
  assert.equal(p1.hand[3].name, "Trảm Trắng");
  assert.equal(p1.hand[3].category, CARD_CATEGORIES.BASIC);

  // Tắt Chế Nỏ -> Phục hồi lá Đen cũ
  const toggleOff = handleToggleSkill(state, 1, "Chế Nỏ");
  assert.equal(toggleOff.success, true);
  assert.equal(p1.activeSkills["Chế Nỏ"], false);
  assert.equal(p1.hand[0].name, "Trảm Đen");
  assert.equal(p1.hand[1].name, "Đỡ Vàng");
  assert.equal(p1.hand[2].name, "Bánh Chưng Đỏ");
  assert.equal(p1.hand[3].name, "Trảm Trắng");
  console.log("✅ Chế Nỏ: Chỉ chuyển đổi duy nhất màu Đen (Đỏ, Trắng, Vàng giữ nguyên) và hoàn tác thành công");
}

// 3. Sử dụng Nỏ Thần Kim Quy bốc 1 lá bài
{
  const state = createTestState();
  const p1 = state.players[0];
  state.phase = "PLAY";
  state.turnSeat = 1;

  p1.hand = [
    { id: "BLACK_CARD_1", name: "Trảm Đen", suit: "Spade", rank: 8, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.ATTACK_NORMAL },
    { id: "RED_CARD_1", name: "Bánh Chưng Đỏ", suit: "Heart", rank: 5, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.PEACH }
  ];
  state._deck = [
    { id: "DECK_CARD_1", name: "Lá Bài Rút", suit: "Diamond", rank: 9, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.DODGE }
  ];
  state._discard = [];

  // Bật Chế Nỏ
  handleToggleSkill(state, 1, "Chế Nỏ");
  assert.equal(p1.hand[0].name, "Nỏ Thần Kim Quy");

  // Đánh (trang bị) Nỏ Thần Kim Quy
  const playRes = handlePlayCard(state, 1, "BLACK_CARD_1");
  assert.equal(playRes.success, true);

  // Kiểm tra: Nỏ Thần Kim Quy đã vào trang bị
  assert.equal(p1.equipments.length, 1);
  assert.equal(p1.equipments[0].name, "Nỏ Thần Kim Quy");

  // Kiểm tra hiệu ứng: Cao Lỗ bốc 1 lá bài từ deck
  assert.equal(p1.hand.some(c => c.id === "DECK_CARD_1"), true, "Cao Lỗ đã bốc 1 lá bài mới khi dùng Nỏ Thần Kim Quy");
  assert.equal(p1.hand.length, 2, "1 lá bỏ đi trang bị, 1 lá rút mới, 1 lá cũ -> còn 2 lá");
  assert.equal(state.lastAction.type, "EQUIP");
  console.log("✅ Chế Nỏ: Khi sử dụng Nỏ Thần Kim Quy, bốc 1 lá bài thành công");
}

// 4. Sử dụng Nỏ Thần Kim Quy thật (không qua Chế Nỏ) cũng kích hoạt bốc 1 lá bài
{
  const state = createTestState();
  const p1 = state.players[0];
  state.phase = "PLAY";
  state.turnSeat = 1;

  p1.hand = [
    { id: "D80_VK_CQ_NoThan", name: "Nỏ Thần Kim Quy", suit: "Spade", rank: 8, category: CARD_CATEGORIES.EQUIPMENT, subType: CARD_SUBTYPES.WEAPON }
  ];
  state._deck = [
    { id: "DECK_CARD_2", name: "Lá Bài Rút 2", suit: "Heart", rank: 2, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.PEACH }
  ];

  const playRes = handlePlayCard(state, 1, "D80_VK_CQ_NoThan");
  assert.equal(playRes.success, true);
  assert.equal(p1.equipments.some(e => e.name === "Nỏ Thần Kim Quy"), true);
  assert.equal(p1.hand.some(c => c.id === "DECK_CARD_2"), true, "Kể cả lá Nỏ Thần thật cũng kích hoạt bốc 1 lá");
  console.log("✅ Chế Nỏ: Trang bị Nỏ Thần Kim Quy gốc cũng bốc 1 lá bài");
}

console.log("🎉 ALL CAO LỖ TESTS PASSED!");
