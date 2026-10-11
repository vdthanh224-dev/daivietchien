import assert from 'node:assert/strict';
import { CARD_CATEGORIES, CARD_SUBTYPES } from './functions/game-engine/src/deck.js';
import {
  initGame,
  handlePlayCard,
  handleUseSkill,
  handleRespondAction,
  handleEndTurn,
  applyDamageToPlayer
} from './functions/game-engine/src/gameEngine.js';
import {
  getHeroById,
  normalizeHeroId,
  heroHasSkill
} from './functions/game-engine/src/heroes.js';

console.log("=== Testing Heroes 51-60 Skills ===");

function createTestState(heroIds = ["HERO_51", "HERO_52", "HERO_53", "HERO_54"]) {
  const state = initGame("TEST_ROOM_51_60", [
    { seat: 1, team: 1, heroId: heroIds[0] },
    { seat: 2, team: 2, heroId: heroIds[1] },
    { seat: 3, team: 1, heroId: heroIds[2] },
    { seat: 4, team: 2, heroId: heroIds[3] }
  ]);
  for (const p of state.players) p.hand = [];
  return state;
}

// -------------------------------------------------------------
// Test Hero 51: Trần Hoảng (Hội Nghị & Diên Hồng)
// -------------------------------------------------------------
{
  const state = createTestState(["HERO_51", "HERO_2", "HERO_3", "HERO_4"]);
  const p1 = state.players[0];
  const p2 = state.players[1];
  assert.equal(heroHasSkill(p1, "HOI_NGHI"), true);
  assert.equal(heroHasSkill(p1, "DIEN_HONG"), true);

  // Test Hội Nghị: Harvest played -> P1 and ally draw 1
  state._deck = [
    { id: "D1", name: "Lá 1", suit: "Heart", rank: 2, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.ATTACK_NORMAL },
    { id: "D2", name: "Lá 2", suit: "Heart", rank: 3, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.ATTACK_NORMAL },
    { id: "D3", name: "Lá 3", suit: "Heart", rank: 4, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.ATTACK_NORMAL },
    { id: "D4", name: "Lá 4", suit: "Heart", rank: 5, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.ATTACK_NORMAL },
    { id: "D5", name: "Lá 5", suit: "Heart", rank: 6, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.ATTACK_NORMAL },
    { id: "D6", name: "Lá 6", suit: "Heart", rank: 7, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.ATTACK_NORMAL },
    { id: "D7", name: "Lá 7", suit: "Heart", rank: 8, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.ATTACK_NORMAL },
    { id: "D8", name: "Lá 8", suit: "Heart", rank: 9, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.ATTACK_NORMAL }
  ];
  p2.hand = [{ id: "HARVEST_1", name: "Mở Kho Cứu Tế", suit: "Heart", rank: 4, category: CARD_CATEGORIES.INSTANT_SCROLL, subType: CARD_SUBTYPES.HARVEST }];
  state.phase = "PLAY";
  state.turnSeat = 2;
  const harvestRes = handlePlayCard(state, 2, "HARVEST_1");
  assert.equal(harvestRes.success, true);
  // P1 should have drawn 1 card from Hội Nghị!
  assert.equal(p1.hand.length >= 1, true);

  // Test Diên Hồng: P1 discards scroll, buffs P3's next Slash damage
  state.phase = "PLAY";
  state.turnSeat = 1;
  p1.hand = [{ id: "SCROLL_1", name: "Vườn Không Nhà Trống", suit: "Spade", rank: 3, category: CARD_CATEGORIES.INSTANT_SCROLL, subType: CARD_SUBTYPES.SNATCH }];
  const useRes = handleUseSkill(state, 1, "Diên Hồng", 3, "SCROLL_1");
  assert.equal(useRes.success, true);
  assert.equal(state.players[2].dienHongBuff, 1);

  // P3 uses Slash on P2 -> deals 1 base + 1 buff = 2 damage!
  state.turnSeat = 3;
  state.players[2].hand = [{ id: "P3_SLASH", name: "Trảm", suit: "Heart", rank: 5, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.ATTACK_NORMAL }];
  p2.hp = 4;
  const slashRes = handlePlayCard(state, 3, "P3_SLASH", 2);
  assert.equal(slashRes.success, true);
  // P2 declines to dodge
  const dodgeRes = handleRespondAction(state, 2, false, null);
  assert.equal(dodgeRes.success, true);
  assert.equal(p2.hp, 2); // Took 2 damage!
  assert.equal(state.players[2].dienHongBuff, 0); // Consumed
  console.log("✅ Hero 51: Trần Hoảng (Hội Nghị & Diên Hồng) OK");
}

// -------------------------------------------------------------
// Test Hero 52: Trần Khâm (Thiền Tâm & Trúc Lâm)
// -------------------------------------------------------------
{
  const state = createTestState(["HERO_1", "HERO_52", "HERO_3", "HERO_4"]);
  const p2 = state.players[1];
  assert.equal(heroHasSkill(p2, "THIEN_TAM"), true);
  assert.equal(heroHasSkill(p2, "TRUC_LAM"), true);

  // Test Thiền Tâm: Near death, P2 discards 2 cards to self-rescue
  p2.hp = 1;
  p2.hand = [
    { id: "CARD_A", name: "Đỡ", suit: "Diamond", rank: 2, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.DODGE },
    { id: "CARD_B", name: "Chiến Mã", suit: "Heart", rank: 5, category: CARD_CATEGORIES.EQUIPMENT, subType: CARD_SUBTYPES.DEFENSIVE_HORSE }
  ];
  // Apply 1 lethal damage
  state.turnSeat = 2;
  applyDamageToPlayer(state, 2, 1, "Đòn đánh", "NORMAL");
  assert.equal(state.phase, "AWAIT_NEAR_DEATH");
  assert.equal(state.waitingTargetSeat, 2);

  // P2 responds with Thiền Tâm
  const respRes = handleRespondAction(state, 2, true, "CARD_A,CARD_B", 2, { skill: "THIEN_TAM" });
  assert.equal(respRes.success, true);
  assert.equal(p2.hp, 1); // Healed to 1 HP!
  assert.equal(p2.hand.length, 0); // Discarded 2 cards

  // Test Trúc Lâm: End of turn with no damage cards in hand -> draws 1
  state.phase = "PLAY";
  state.turnSeat = 2;
  p2.hand = [{ id: "NON_DMG", name: "Đỡ", suit: "Diamond", rank: 7, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.DODGE }];
  state._deck = [{ id: "TL_DRAW", name: "Bánh Chưng", suit: "Heart", rank: 10, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.PEACH }];
  const endRes = handleEndTurn(state, 2);
  assert.equal(endRes.success, true);
  assert.equal(p2.hand.some(c => c.id === "TL_DRAW"), true);
  console.log("✅ Hero 52: Trần Khâm (Thiền Tâm & Trúc Lâm) OK");
}

// -------------------------------------------------------------
// Test Hero 53: Trần Quốc Tuấn (Hịch Tướng & Vạn Kiếp)
// -------------------------------------------------------------
{
  const state = createTestState(["HERO_53", "HERO_2", "HERO_3", "HERO_4"]);
  const p1 = state.players[0];
  assert.equal(heroHasSkill(p1, "HICH_TUONG"), true);
  assert.equal(heroHasSkill(p1, "VAN_KIEP"), true);

  // Test Hịch Tướng: P1 discards 2 Slashes, draws 2 cards
  p1.hand = [
    { id: "S1", name: "Trảm", suit: "Spade", rank: 5, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.ATTACK_NORMAL },
    { id: "S2", name: "Trảm", suit: "Club", rank: 6, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.ATTACK_NORMAL }
  ];
  state._deck = [
    { id: "HD1", name: "Đỡ", suit: "Heart", rank: 2, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.DODGE },
    { id: "HD2", name: "Đỡ", suit: "Heart", rank: 3, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.DODGE }
  ];
  state.phase = "PLAY";
  state.turnSeat = 1;
  const useRes = handleUseSkill(state, 1, "Hịch Tướng", 0, "S1,S2");
  assert.equal(useRes.success, true);
  assert.equal(p1.hand.length, 2);
  assert.equal(p1.hand.some(c => c.id === "HD1"), true);

  // Test Vạn Kiếp: Equipped with Weapon -> Slash targets 2 players
  p1.equipments = [{ id: "WEAPON_1", name: "Trường Thương", subType: CARD_SUBTYPES.WEAPON, range: 3 }];
  p1.hand = [{ id: "SLASH_VK", name: "Trảm", suit: "Spade", rank: 8, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.ATTACK_NORMAL }];
  state.phase = "PLAY";
  state.turnSeat = 1;
  const playRes = handlePlayCard(state, 1, "SLASH_VK", 2, { vanKiepTargetSeat: 4 });
  assert.equal(playRes.success, true);
  assert.equal(playRes.state.activeCard?.lienChauTargets?.[0], 4);
  console.log("✅ Hero 53: Trần Quốc Tuấn (Hịch Tướng & Vạn Kiếp) OK");
}

// -------------------------------------------------------------
// Test Hero 54: Trần Quang Khải (Thái Bình & Thượng Tướng)
// -------------------------------------------------------------
{
  const state = createTestState(["HERO_54", "HERO_2", "HERO_3", "HERO_4"]);
  const p1 = state.players[0];
  assert.equal(heroHasSkill(p1, "THAI_BINH_TRAN_QUANG_KHAI"), true);
  assert.equal(heroHasSkill(p1, "THUONG_TUONG"), true);

  // Test Thái Bình: End of turn without using Slash -> equips Armor from discard
  state._discard = [
    { id: "DISCARD_ARMOR", name: "Bát Quái Trận", suit: "Club", rank: 2, category: CARD_CATEGORIES.EQUIPMENT, subType: CARD_SUBTYPES.ARMOR }
  ];
  state.phase = "PLAY";
  state.turnSeat = 1;
  const endRes = handleEndTurn(state, 1);
  assert.equal(endRes.success, true);
  assert.equal((p1.equipments || []).some(e => e.id === "DISCARD_ARMOR"), true);

  // Test Thượng Tướng: Equipped with both Offensive & Defensive Horse -> infinite range
  p1.equipments = [
    { id: "H_OFF", name: "Ngựa Công", subType: CARD_SUBTYPES.OFFENSIVE_HORSE, distMod: -1 },
    { id: "H_DEF", name: "Ngựa Thủ", subType: CARD_SUBTYPES.DEFENSIVE_HORSE, distMod: 1 }
  ];
  p1.hand = [{ id: "SLASH_INF", name: "Trảm", suit: "Heart", rank: 7, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.ATTACK_NORMAL }];
  state.phase = "PLAY";
  state.turnSeat = 1;
  // Attack P3 (distance normally 2, without weapon normally range 1, but Thượng Tướng gives infinite range!)
  const slashRes = handlePlayCard(state, 1, "SLASH_INF", 3);
  assert.equal(slashRes.success, true);
  console.log("✅ Hero 54: Trần Quang Khải (Thái Bình & Thượng Tướng) OK");
}

// -------------------------------------------------------------
// Test Hero 55: Trần Nhật Duật (Đồng Hóa & Bổn Tộc)
// -------------------------------------------------------------
{
  const state = createTestState(["HERO_1", "HERO_55", "HERO_3", "HERO_4"]);
  const p1 = state.players[0];
  const p2 = state.players[1];
  assert.equal(heroHasSkill(p2, "DONG_HOA"), true);
  assert.equal(heroHasSkill(p2, "BON_TOC"), true);

  // Test Đồng Hóa: Targeted by Duel -> swaps hand card with P1, draws 1
  p1.hand = [
    { id: "DUEL_CARD", name: "Huyết Chiến", suit: "Spade", rank: 1, category: CARD_CATEGORIES.INSTANT_SCROLL, subType: CARD_SUBTYPES.BLOOD_BATTLE },
    { id: "P1_EXTRA", name: "Trảm", suit: "Heart", rank: 8, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.ATTACK_NORMAL }
  ];
  p2.hand = [{ id: "P2_SECRET", name: "Lá Bí Mật", suit: "Heart", rank: 9, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.ATTACK_NORMAL }];
  state._deck = [{ id: "DH_DRAW", name: "Đỡ", suit: "Heart", rank: 5, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.DODGE }];
  state.phase = "PLAY";
  state.turnSeat = 1;
  const playRes = handlePlayCard(state, 1, "DUEL_CARD", 2);
  assert.equal(playRes.success, true);
  // P2 swapped card and drew 1!
  assert.equal(p2.hand.some(c => c.id === "DH_DRAW"), true);
  assert.equal(p2.hand.some(c => c.id === "P1_EXTRA"), true);
  assert.equal(p1.hand.some(c => c.id === "P2_SECRET"), true);

  // Test Bổn Tộc: In Play phase, view target's hand within distance 1
  state.phase = "PLAY";
  state.turnSeat = 2;
  p1.hand = [{ id: "P1_CARD", name: "Trảm", suit: "Spade", rank: 10, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.ATTACK_NORMAL }];
  const useRes = handleUseSkill(state, 2, "Bổn Tộc", 1);
  assert.equal(useRes.success, true);
  assert.equal(state.drumReveal?.targetSeat, 1);
  console.log("✅ Hero 55: Trần Nhật Duật (Đồng Hóa & Bổn Tộc) OK");
}

// -------------------------------------------------------------
// Test Hero 56: Trần Quốc Toản (Phá Cường Địch & Cam Lạc)
// -------------------------------------------------------------
{
  const state = createTestState(["HERO_56", "HERO_2", "HERO_3", "HERO_4"]);
  const p1 = state.players[0];
  const p2 = state.players[1];
  assert.equal(heroHasSkill(p1, "PHA_CUONG_DICH"), true);
  assert.equal(heroHasSkill(p1, "CAM_LAC"), true);

  // Test Phá Cường Địch: Without weapon, first Slash hits for +1 damage
  p1.equipments = [];
  p1.hand = [{ id: "P1_SLASH", name: "Trảm", suit: "Spade", rank: 5, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.ATTACK_NORMAL }];
  p2.hp = 4;
  state.phase = "PLAY";
  state.turnSeat = 1;
  const slashRes = handlePlayCard(state, 1, "P1_SLASH", 2);
  assert.equal(slashRes.success, true);
  const dodgeRes = handleRespondAction(state, 2, false, null);
  assert.equal(dodgeRes.success, true);
  assert.equal(p2.hp, 2); // 1 base + 1 Phá Cường Địch = 2 damage!

  // Test Cam Lạc: P1's hand card is destroyed by P2's Dismantle -> P1 draws 1
  p1.hand = [{ id: "P1_TARGET_CARD", name: "Đỡ", suit: "Heart", rank: 3, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.DODGE }];
  p2.hand = [{ id: "DISMANTLE_1", name: "Đột Kích Trộm Lương", suit: "Spade", rank: 3, category: CARD_CATEGORIES.INSTANT_SCROLL, subType: CARD_SUBTYPES.DISMANTLE }];
  state._deck = [{ id: "CL_DRAW", name: "Trảm", suit: "Heart", rank: 7, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.ATTACK_NORMAL }];
  state.phase = "PLAY";
  state.turnSeat = 2;
  const disRes = handlePlayCard(state, 2, "DISMANTLE_1", 1);
  assert.equal(disRes.success, true);
  // P2 selects P1's hand card to destroy
  const selRes = handleRespondAction(state, 2, true, null, 1, { targetCardId: "HAND:0" });
  assert.equal(selRes.success, true);
  // P1 should have drawn 1 card from Cam Lạc!
  assert.equal(p1.hand.some(c => c.id === "CL_DRAW"), true);
  console.log("✅ Hero 56: Trần Quốc Toản (Phá Cường Địch & Cam Lạc) OK");
}

// -------------------------------------------------------------
// Test Hero 57: Trần Bình Trọng (Bảo Quốc & Quỷ Nam)
// -------------------------------------------------------------
{
  const state = createTestState(["HERO_1", "HERO_57", "HERO_3", "HERO_4"]);
  const p1 = state.players[0];
  const p2 = state.players[1];
  assert.equal(heroHasSkill(p2, "BAO_QUOC"), true);
  assert.equal(heroHasSkill(p2, "QUY_NAM"), true);

  // Test Bảo Quốc: When P2 dies, killer P1 loses all equipments and 2 hand cards
  p1.equipments = [{ id: "P1_ARMOR", name: "Áo Giáp", subType: CARD_SUBTYPES.ARMOR }];
  p1.hand = [
    { id: "H1", name: "Lá 1", suit: "Heart", rank: 1, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.ATTACK_NORMAL },
    { id: "H2", name: "Lá 2", suit: "Heart", rank: 2, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.ATTACK_NORMAL }
  ];
  p2.hp = 1;
  p2.hand = [];
  // P1 deals lethal damage to P2
  state.turnSeat = 1;
  applyDamageToPlayer(state, 2, 1, "Đòn đánh", "NORMAL");
  // Near death declined by all players
  while (state.phase === "AWAIT_NEAR_DEATH") {
    handleRespondAction(state, state.waitingTargetSeat, false, null);
  }
  // P2 died -> killer P1 lost equipments and 2 hand cards!
  assert.equal(p1.equipments.length, 0);
  assert.equal(p1.hand.length, 0);

  // Test Quỷ Nam: Slash damage ignores armor
  const state2 = createTestState(["HERO_57", "HERO_2", "HERO_3", "HERO_4"]);
  const pTrọng = state2.players[0];
  const pTarget = state2.players[1];
  pTarget.hp = 4;
  pTarget.equipments = [{ id: "AO_BAO", name: "Áo Bào Hoàng Tộc", subType: CARD_SUBTYPES.ARMOR }];
  pTarget.aoBaoCharges = 2;
  // PTrọng slashes pTarget
  pTrọng.hand = [{ id: "QN_SLASH", name: "Trảm", suit: "Spade", rank: 9, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.ATTACK_NORMAL }];
  state2.phase = "PLAY";
  state2.turnSeat = 1;
  const playRes = handlePlayCard(state2, 1, "QN_SLASH", 2);
  assert.equal(playRes.success, true);
  handleRespondAction(state2, 2, false, null);
  assert.equal(pTarget.hp, 3); // Armor was ignored!
  console.log("✅ Hero 57: Trần Bình Trọng (Bảo Quốc & Quỷ Nam) OK");
}

// -------------------------------------------------------------
// Test Hero 58: Trần Khánh Dư (Đoạt Lương & Vân Đồn)
// -------------------------------------------------------------
{
  const state = createTestState(["HERO_58", "HERO_2", "HERO_3", "HERO_4"]);
  const p1 = state.players[0];
  assert.equal(heroHasSkill(p1, "DOAT_LUONG"), true);
  assert.equal(heroHasSkill(p1, "VAN_DON"), true);

  // Test Vân Đồn & Đoạt Lương: Uses Equipment as Supply Shortage, draws 2 on attach
  p1.hand = [{ id: "HORSE_EQ", name: "Chiến Mã", suit: "Club", rank: 5, category: CARD_CATEGORIES.EQUIPMENT, subType: CARD_SUBTYPES.DEFENSIVE_HORSE }];
  state._deck = [
    { id: "DL1", name: "Lá 1", suit: "Heart", rank: 2, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.ATTACK_NORMAL },
    { id: "DL2", name: "Lá 2", suit: "Heart", rank: 3, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.ATTACK_NORMAL }
  ];
  state.phase = "PLAY";
  state.turnSeat = 1;
  const playRes = handlePlayCard(state, 1, "HORSE_EQ", 2);
  assert.equal(playRes.success, true);
  assert.equal((state.players[1].judgements || []).some(j => j.subType === CARD_SUBTYPES.SUPPLY_SHORTAGE), true);
  // P1 drew 2 cards from Đoạt Lương!
  assert.equal(p1.hand.length, 2);
  console.log("✅ Hero 58: Trần Khánh Dư (Đoạt Lương & Vân Đồn) OK");
}

// -------------------------------------------------------------
// Test Hero 59: Phạm Ngũ Lão (Phục Kích & Đan Phụ)
// -------------------------------------------------------------
{
  const state = createTestState(["HERO_59", "HERO_2", "HERO_3", "HERO_4"]);
  const p1 = state.players[0];
  const p2 = state.players[1];
  assert.equal(heroHasSkill(p1, "PHUC_KICH"), true);
  assert.equal(heroHasSkill(p1, "DAN_PHU"), true);

  // Test Phục Kích: Uses black card as Dismantle (1/turn)
  p1.hand = [
    { id: "BLACK_CARD", name: "Đỡ", suit: "Spade", rank: 7, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.DODGE },
    { id: "SLASH_DP", name: "Trảm", suit: "Heart", rank: 8, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.ATTACK_NORMAL }
  ];
  p2.equipments = [{ id: "P2_EQ", name: "Áo Giáp", subType: CARD_SUBTYPES.ARMOR }];
  p2.hp = 4;
  state.phase = "PLAY";
  state.turnSeat = 1;
  const disRes = handlePlayCard(state, 1, "BLACK_CARD", 2);
  assert.equal(disRes.success, true);
  // Complete dismantle selection
  handleRespondAction(state, 1, true, null, 2, { targetCardId: "EQUIPMENT:P2_EQ" });
  assert.equal(p2.equipments.length, 0);

  // Test Đan Phụ: Slash in same turn deals +1 damage
  const slashRes = handlePlayCard(state, 1, "SLASH_DP", 2);
  assert.equal(slashRes.success, true);
  handleRespondAction(state, 2, false, null);
  assert.equal(p2.hp, 2); // 1 base + 1 Đan Phụ = 2 damage!
  console.log("✅ Hero 59: Phạm Ngũ Lão (Phục Kích & Đan Phụ) OK");
}

// -------------------------------------------------------------
// Test Hero 60: Yết Kiêu (Thấu Thủy & Trực Thuyền)
// -------------------------------------------------------------
{
  const state = createTestState(["HERO_60", "HERO_2", "HERO_3", "HERO_4"]);
  const p1 = state.players[0];
  const p2 = state.players[1];
  assert.equal(heroHasSkill(p1, "THAU_THUY"), true);
  assert.equal(heroHasSkill(p1, "TRUC_THUYEN"), true);

  // Test Thấu Thủy: Immune to Bãi Cọc Bạch Đằng damage
  p1.hp = 4;
  applyDamageToPlayer(state, 1, 1, "Bãi Cọc Bạch Đằng", "NORMAL");
  assert.equal(p1.hp, 4); // No damage taken!

  // Test Trực Thuyền: Slash converted to Water Slash, hits -> destroys P2 equipment
  p1.hand = [{ id: "YK_SLASH", name: "Trảm", suit: "Spade", rank: 6, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.ATTACK_NORMAL }];
  p2.equipments = [{ id: "P2_ARMOR", name: "Áo Giáp", subType: CARD_SUBTYPES.ARMOR }];
  p2.hp = 4;
  state.phase = "PLAY";
  state.turnSeat = 1;
  const slashRes = handlePlayCard(state, 1, "YK_SLASH", 2);
  assert.equal(slashRes.success, true);
  assert.equal(state.activeCard?.damageElement, "WATER");

  handleRespondAction(state, 2, false, null);
  assert.equal(p2.hp, 3);
  assert.equal(p2.equipments.length, 0); // Destroyed by Trực Thuyền!
  console.log("✅ Hero 60: Yết Kiêu (Thấu Thủy & Trực Thuyền) OK");
}

console.log("🎉 All heroes 51-60 skill unit tests passed!");
