import assert from 'node:assert/strict';
import { CARD_CATEGORIES, CARD_SUBTYPES } from './functions/game-engine/src/deck.js';
import {
  initGame,
  handlePlayCard,
  handleUseSkill,
  handleAIStep
} from './functions/game-engine/src/gameEngine.js';
import {
  getHeroById,
  heroHasSkill,
  SKILLS
} from './functions/game-engine/src/heroes.js';

console.log("=== Testing Đào Hãn: Phù Trấn Remake ===");

// 1. Definition check
const daoHan = getHeroById("HERO_2");
assert.equal(daoHan.name, "Đào Hãn");
assert.deepEqual(daoHan.skills, ["XA_THUAN", "PHU_TRAN"]);
assert.match(SKILLS.PHU_TRAN.description, /rút 3 lá bài/);
assert.match(SKILLS.PHU_TRAN.description, /đổi vũ khí lấy lá mới/);

function createTestState() {
  return initGame("TEST_DAO_HAN", [
    { id: "u1", name: "Đào Hãn", heroId: "HERO_2", seat: 1, isAI: false },
    { id: "u2", name: "Cao Lỗ", heroId: "HERO_1", seat: 2, isAI: true },
    { id: "u3", name: "Thi Sách", heroId: "HERO_3", seat: 3, isAI: true },
    { id: "u4", name: "Lê Chân", heroId: "HERO_4", seat: 4, isAI: true }
  ]);
}

// 2. Trảm không đeo vũ khí -> Rút 3 lá bài (thay vì 1)
{
  const state = createTestState();
  const p1 = state.players[0];
  state.phase = "PLAY";
  state.turnSeat = 1;

  p1.equipments = []; // Không đeo vũ khí
  p1.hand = [
    { id: "SLASH_1", name: "Trảm Thường", suit: "Spade", rank: 7, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.ATTACK_NORMAL }
  ];
  state._deck = [
    { id: "D1", name: "Lá 1", suit: "Club", rank: 2, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.DODGE },
    { id: "D2", name: "Lá 2", suit: "Heart", rank: 3, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.PEACH },
    { id: "D3", name: "Lá 3", suit: "Diamond", rank: 4, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.DODGE }
  ];

  const playRes = handlePlayCard(state, 1, "SLASH_1", 2);
  assert.equal(playRes.success, true);
  // P1 đánh 1 lá Trảm, rút 3 lá -> tay có 3 lá
  assert.equal(p1.hand.length, 3, "Đào Hãn phải rút đủ 3 lá bài");
  assert.equal(p1.hand.some(c => c.id === "D1"), true);
  assert.equal(p1.hand.some(c => c.id === "D2"), true);
  assert.equal(p1.hand.some(c => c.id === "D3"), true);
  console.log("✅ Phù Trấn: Trảm khi không có vũ khí rút đúng 3 lá bài");
}

// 3. Trảm khi CÓ vũ khí -> Không kích hoạt Phù Trấn
{
  const state = createTestState();
  const p1 = state.players[0];
  state.phase = "PLAY";
  state.turnSeat = 1;

  p1.equipments = [
    { id: "WP_1", name: "Kiếm Thuận Thiên", category: CARD_CATEGORIES.EQUIPMENT, subType: CARD_SUBTYPES.WEAPON }
  ];
  p1.hand = [
    { id: "SLASH_2", name: "Trảm Thường", suit: "Spade", rank: 7, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.ATTACK_NORMAL }
  ];
  state._deck = [
    { id: "D_FAIL", name: "Lá Không Được Rút", suit: "Club", rank: 2, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.DODGE }
  ];

  const playRes = handlePlayCard(state, 1, "SLASH_2", 2);
  assert.equal(playRes.success, true);
  assert.equal(p1.hand.length, 0, "Khi có vũ khí thì không được rút bài");
  console.log("✅ Phù Trấn: Trảm khi có vũ khí không rút bài");
}

// 4. Kích hoạt đổi Vũ Khí trên tay lấy 1 lá mới
{
  const state = createTestState();
  const p1 = state.players[0];
  state.phase = "PLAY";
  state.turnSeat = 1;

  p1.hand = [
    { id: "HAND_WP", name: "Nỏ Thần Kim Quy", category: CARD_CATEGORIES.EQUIPMENT, subType: CARD_SUBTYPES.WEAPON },
    { id: "NON_WP", name: "Bánh Chưng", category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.PEACH }
  ];
  state._deck = [
    { id: "NEW_CARD_1", name: "Lá Mới 1", category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.DODGE }
  ];
  state._discard = [];

  // Thử đổi lá không phải vũ khí -> Báo lỗi
  const errRes = handleUseSkill(state, 1, "Phù Trấn", 0, "NON_WP");
  assert.ok(errRes.error);

  // Đổi lá vũ khí trên tay -> Thành công
  const okRes = handleUseSkill(state, 1, "Phù Trấn", 0, "HAND_WP");
  assert.equal(okRes.success, true);
  assert.equal(p1.hand.some(c => c.id === "HAND_WP"), false);
  assert.equal(p1.hand.some(c => c.id === "NEW_CARD_1"), true);
  assert.equal(state._discard.some(c => c.id === "HAND_WP"), true);
  assert.equal(state.lastAction.type, "PHU_TRAN_EXCHANGE");
  console.log("✅ Phù Trấn: Đổi vũ khí trên tay lấy lá mới thành công");
}

// 5. Kích hoạt đổi Vũ Khí ĐANG ĐEO lấy 1 lá mới, sau đó Trảm rút 3 lá
{
  const state = createTestState();
  const p1 = state.players[0];
  state.phase = "PLAY";
  state.turnSeat = 1;

  p1.equipments = [
    { id: "EQUIPPED_WP", name: "Song Cung Mường Nhạ", category: CARD_CATEGORIES.EQUIPMENT, subType: CARD_SUBTYPES.WEAPON }
  ];
  p1.hand = [
    { id: "SLASH_AFTER", name: "Trảm Thường", suit: "Heart", rank: 9, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.ATTACK_NORMAL }
  ];
  state._deck = [
    { id: "CARD_EXCHANGE", name: "Lá Đổi", suit: "Spade", rank: 1, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.DODGE },
    { id: "T1", name: "T1", suit: "Spade", rank: 2, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.DODGE },
    { id: "T2", name: "T2", suit: "Spade", rank: 3, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.DODGE },
    { id: "T3", name: "T3", suit: "Spade", rank: 4, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.DODGE }
  ];
  state._discard = [];

  // Đổi vũ khí đang đeo
  const initialHandSize = p1.hand.length;
  const eqRes = handleUseSkill(state, 1, "Phù Trấn", 0, "EQUIPPED_WP");
  assert.equal(eqRes.success, true);
  assert.equal(p1.equipments.length, 0, "Vũ khí đã được gỡ bỏ khỏi người");
  assert.equal(p1.hand.length, initialHandSize + 1, "Đã nhận lá bài mới");
  assert.equal(state._discard.some(c => c.id === "EQUIPPED_WP"), true);

  // Sau khi gỡ vũ khí, dùng Trảm -> Đào Hãn lập tức rút 3 lá bài!
  const slashRes = handlePlayCard(state, 1, "SLASH_AFTER", 2);
  assert.equal(slashRes.success, true);
  assert.equal(p1.hand.length, 4, "1 lá đổi trước đó + 3 lá rút từ Trảm = 4 lá");
  console.log("✅ Phù Trấn: Đổi vũ khí đang đeo giúp gỡ vũ khí và Trảm rút 3 lá mượt mà");
}

console.log("🎉 ALL ĐÀO HÃN PHÙ TRẤN TESTS PASSED!");
