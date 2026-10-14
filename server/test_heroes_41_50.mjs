import assert from 'node:assert/strict';
import { CARD_CATEGORIES, CARD_SUBTYPES } from './functions/game-engine/src/deck.js';
import {
  initGame,
  handlePlayCard,
  handleUseSkill,
  handleRespondAction,
  handleEndTurn,
  handleDiscardCards,
  applyDamageToPlayer,
  sanitizeGameStateForClient,
  handleAIReaction,
  executeFallbackReactionForSeat,
  tickGameState
} from './functions/game-engine/src/gameEngine.js';
import {
  getHeroById,
  normalizeHeroId,
  heroHasSkill
} from './functions/game-engine/src/heroes.js';

console.log("=== Testing Heroes 41-50 Skills ===");

function createTestState(heroIds = ["HERO_41", "HERO_42", "HERO_43", "HERO_44"]) {
  return initGame("TEST_ROOM_41_50", [
    { seat: 1, team: 1, heroId: heroIds[0] },
    { seat: 2, team: 2, heroId: heroIds[1] },
    { seat: 3, team: 1, heroId: heroIds[2] },
    { seat: 4, team: 2, heroId: heroIds[3] }
  ]);
}

// -------------------------------------------------------------
// Test Hero 41: Lý Nhật Tôn (Đại Việt & Thủ Pháp)
// -------------------------------------------------------------
{
  const state = createTestState(["HERO_41", "HERO_2", "HERO_3", "HERO_4"]);
  const p1 = state.players[0];
  assert.equal(p1.heroId, "HERO_41");
  assert.equal(heroHasSkill(p1, "DAI_VIET"), true);
  assert.equal(heroHasSkill(p1, "THU_PHAP"), true);

  // Turn start prompt for Đại Việt
  state.phase = "PLAY";
  state.turnSeat = 1;
  p1.daiVietColor = "RED";
  p1.turnPlayedColors = new Set();
  p1.hand = [
    { id: "CARD_RED_1", name: "Trảm", suit: "Heart", rank: 8, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.ATTACK_NORMAL },
    { id: "CARD_BLACK_1", name: "Trảm", suit: "Spade", rank: 9, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.ATTACK_NORMAL },
    { id: "CARD_YELLOW_1", name: "Trảm", suit: "Club", rank: 10, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.ATTACK_NORMAL }
  ];
  state.players[1].hand = [];
  state._deck = [
    { id: "DRAW_1", name: "Đỡ", suit: "Diamond", rank: 2, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.DODGE },
    { id: "DRAW_2", name: "Đỡ", suit: "Diamond", rank: 3, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.DODGE },
    { id: "DRAW_3", name: "Đỡ", suit: "Diamond", rank: 4, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.DODGE },
    { id: "DRAW_4", name: "Đỡ", suit: "Diamond", rank: 5, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.DODGE }
  ];

  // Play RED card -> triggers Đại Việt draw!
  const playRes1 = handlePlayCard(state, 1, "CARD_RED_1", 2);
  assert.equal(playRes1.success, true);
  // P1 played 1 card, but drew 1 card from Đại Việt
  assert.equal(p1.hand.some(c => c.id === "DRAW_4"), true);

  // Clean attack phase
  state.phase = "PLAY";
  state.activeCard = null;
  state.slashesUsedThisTurn = 0;

  // Play Black card
  const playRes2 = handlePlayCard(state, 1, "CARD_BLACK_1", 2);
  assert.equal(playRes2.success, true);

  state.phase = "PLAY";
  state.activeCard = null;
  state.slashesUsedThisTurn = 0;

  // Play Yellow card
  const playRes3 = handlePlayCard(state, 1, "CARD_YELLOW_1", 2);
  assert.equal(playRes3.success, true);

  // Now p1 has played 3 colors (RED, BLACK, YELLOW)
  assert.equal(p1.turnPlayedColors.size >= 3, true);

  // End turn -> triggers Thủ Pháp (draws 3, discard 1)
  state.phase = "PLAY";
  const endRes = handleEndTurn(state, 1);
  assert.equal(endRes.success, true);
  assert.equal(state.phase, "AWAIT_THU_PHAP_DISCARD");
  assert.equal(state.waitingTargetSeat, 1);

  // Respond discard 1 card
  const discCardId = p1.hand[0].id;
  const respRes = handleRespondAction(state, 1, true, discCardId);
  assert.equal(respRes.success, true);
  console.log("✅ Hero 41: Lý Nhật Tôn (Đại Việt & Thủ Pháp) OK");
}

// -------------------------------------------------------------
// Test Hero 42: Lý Đạo Thành (Can Gián & Định Triều)
// -------------------------------------------------------------
{
  const state = createTestState(["HERO_1", "HERO_42", "HERO_3", "HERO_4"]);
  const p1 = state.players[0]; // seat 1, team 1
  const p2 = state.players[1]; // seat 2, team 2 (Lý Đạo Thành)
  const p3 = state.players[2]; // seat 3, team 1
  const p4 = state.players[3]; // seat 4, team 2
  assert.equal(heroHasSkill(p2, "CAN_GIAN"), true);
  assert.equal(heroHasSkill(p2, "DINH_TRIEU"), true);

  // 1. Prompting & Client State
  p1.hand = [{ id: "DELAY_1", name: "Trầm Ảo Sa Bẫy", suit: "Heart", rank: 13, category: CARD_CATEGORIES.DELAYED_SCROLL, subType: CARD_SUBTYPES.ACEDIA }];
  p2.hand = [
    { id: "RED_CARD_P2", name: "Đỡ", suit: "Heart", rank: 7, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.DODGE },
    { id: "BLACK_CARD_P2", name: "Trảm", suit: "Spade", rank: 8, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.ATTACK_NORMAL }
  ];
  state.phase = "PLAY";
  state.turnSeat = 1;

  const playRes1 = handlePlayCard(state, 1, "DELAY_1", 3);
  assert.equal(playRes1.success, true);
  assert.equal(state.phase, "AWAIT_CAN_GIAN");
  assert.equal(state.waitingTargetSeat, 2);

  // Check client sanitation preserves AWAIT_CAN_GIAN and provides pendingCanGian
  const clientView = sanitizeGameStateForClient(state, 2);
  assert.equal(clientView.phase, "AWAIT_CAN_GIAN");
  assert.equal(clientView.pendingCanGian?.targetSeat, 3);
  assert.equal(clientView.pendingCanGian?.card?.id, "DELAY_1");

  // 2. Error cases: Accepting without card or with non-red card
  const errNoCard = handleRespondAction(state, 2, true, null);
  assert.equal(!!errNoCard.error, true);
  assert.equal(state.phase, "AWAIT_CAN_GIAN"); // Phase must not be cleared on error
  assert.equal(!!state.pendingCanGian, true);

  const errBlackCard = handleRespondAction(state, 2, true, "BLACK_CARD_P2");
  assert.equal(!!errBlackCard.error, true);
  assert.equal(state.phase, "AWAIT_CAN_GIAN");
  assert.equal(!!state.pendingCanGian, true);

  // 3. Declining Can Gián attaches the delayed scroll
  const declineRes = handleRespondAction(state, 2, false, null);
  assert.equal(declineRes.success, true);
  assert.equal(p3.judgements.length, 1);
  assert.equal(p3.judgements[0].id, "DELAY_1");
  assert.equal(p2.hand.length, 2); // Hand untouched

  // 4. Accepting Can Gián with RED card cancels the delayed scroll
  p3.judgements = [];
  p1.hand = [{ id: "DELAY_2", name: "Trầm Ảo Sa Bẫy", suit: "Heart", rank: 6, category: CARD_CATEGORIES.DELAYED_SCROLL, subType: CARD_SUBTYPES.ACEDIA }];
  state.phase = "PLAY";
  state.turnSeat = 1;

  const playRes2 = handlePlayCard(state, 1, "DELAY_2", 3);
  assert.equal(playRes2.success, true);
  assert.equal(state.phase, "AWAIT_CAN_GIAN");
  const acceptRes = handleRespondAction(state, 2, true, "RED_CARD_P2");
  assert.equal(acceptRes.success, true);
  assert.equal(p3.judgements.length, 0); // Cancelled!
  assert.equal(p2.hand.some(c => c.id === "RED_CARD_P2"), false); // Discarded!

  // 5. Using Can Gián via handleUseSkill
  p2.hand.push({ id: "RED_CARD_P2_2", name: "Đỡ", suit: "Heart", rank: 9, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.DODGE });
  p1.hand = [{ id: "DELAY_3", name: "Trầm Ảo Sa Bẫy", suit: "Diamond", rank: 1, category: CARD_CATEGORIES.DELAYED_SCROLL, subType: CARD_SUBTYPES.ACEDIA }];
  state.phase = "PLAY";
  state.turnSeat = 1;

  const playRes3 = handlePlayCard(state, 1, "DELAY_3", 3);
  assert.equal(playRes3.success, true);
  assert.equal(state.phase, "AWAIT_CAN_GIAN");
  const skillRes = handleUseSkill(state, 2, "Can Gián", 0, "RED_CARD_P2_2");
  assert.equal(skillRes.success, true);
  assert.equal(p3.judgements.length, 0); // Cancelled!

  // 6. AI Bot logic: AI does NOT save enemies, only allies/self
  p2.isAI = true;
  p2.hand.push({ id: "RED_AI_CARD", name: "Đỡ", suit: "Heart", rank: 3, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.DODGE });
  p1.hand = [{ id: "DELAY_ENEMY", name: "Trầm Ảo Sa Bẫy", suit: "Heart", rank: 13, category: CARD_CATEGORIES.DELAYED_SCROLL, subType: CARD_SUBTYPES.ACEDIA }];
  state.phase = "PLAY";
  state.turnSeat = 1;

  // Targeting P3 (enemy of P2)
  handlePlayCard(state, 1, "DELAY_ENEMY", 3);
  assert.equal(state.phase, "AWAIT_CAN_GIAN");
  const aiEnemyReaction = handleAIReaction(state, 2);
  assert.equal(aiEnemyReaction.success, true);
  assert.equal(p3.judgements.length, 1); // Not saved! Enemy gets delayed scroll!
  assert.equal(p2.hand.some(c => c.id === "RED_AI_CARD"), true); // Card kept!

  // Targeting P4 (ally of P2)
  p1.hand = [{ id: "DELAY_ALLY", name: "Cắt Đường Lương", suit: "Club", rank: 4, category: CARD_CATEGORIES.DELAYED_SCROLL, subType: CARD_SUBTYPES.SUPPLY_SHORTAGE }];
  state.phase = "PLAY";
  state.turnSeat = 1;
  handlePlayCard(state, 1, "DELAY_ALLY", 4);
  assert.equal(state.phase, "AWAIT_CAN_GIAN");
  const aiAllyReaction = handleAIReaction(state, 2);
  assert.equal(aiAllyReaction.success, true);
  assert.equal(p4.judgements.length, 0); // Saved! Cancelled!
  assert.equal(p2.hand.some(c => c.id === "RED_AI_CARD"), false); // Discarded to save ally!

  // 7. Human timeout fallback declines instead of auto-discarding
  p2.isAI = false;
  p3.judgements = [];
  p2.hand.push({ id: "RED_HUMAN_CARD", name: "Đỡ", suit: "Heart", rank: 5, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.DODGE });
  p1.hand = [{ id: "DELAY_TIMEOUT", name: "Trầm Ảo Sa Bẫy", suit: "Heart", rank: 13, category: CARD_CATEGORIES.DELAYED_SCROLL, subType: CARD_SUBTYPES.ACEDIA }];
  state.phase = "PLAY";
  state.turnSeat = 1;
  const playResTimeout = handlePlayCard(state, 1, "DELAY_TIMEOUT", 3);
  assert.equal(playResTimeout.success, true);
  assert.equal(state.phase, "AWAIT_CAN_GIAN");

  // Fallback reaction on timeout
  const fallbackRes = executeFallbackReactionForSeat(state, 2, p2);
  assert.equal(fallbackRes.success, true);
  assert.equal(p2.hand.some(c => c.id === "RED_HUMAN_CARD"), true); // Human red card NOT discarded!
  assert.equal(p3.judgements.length, 1); // Scroll attached to target

  // Test Định Triều: P2 gives scroll to P3, draws 1
  state.phase = "PLAY";
  state.turnSeat = 2;
  p2.hand = [{ id: "SCROLL_P2", name: "Vườn Không Nhà Trống", suit: "Spade", rank: 3, category: CARD_CATEGORIES.INSTANT_SCROLL, subType: CARD_SUBTYPES.SNATCH }];
  state._deck = [{ id: "DRAW_P2", name: "Trảm", suit: "Heart", rank: 5, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.ATTACK_NORMAL }];
  state.players[2].hand = [];

  const useRes = handleUseSkill(state, 2, "Định Triều", 3, "SCROLL_P2");
  assert.equal(useRes.success, true);
  assert.equal(p2.hand.some(c => c.id === "DRAW_P2"), true);
  assert.equal(state.players[2].hand.some(c => c.id === "SCROLL_P2"), true);
  console.log("✅ Hero 42: Lý Đạo Thành (Can Gián & Định Triều) OK");
}

// -------------------------------------------------------------
// Test Hero 43: Ỷ Lan (Nhiếp Chính & Khuyến Nông)
// -------------------------------------------------------------
{
  const state = createTestState(["HERO_43", "HERO_2", "HERO_3", "HERO_4"]);
  const p1 = state.players[0];
  assert.equal(heroHasSkill(p1, "NHIEP_CHINH_Y_LAN"), true);
  assert.equal(heroHasSkill(p1, "KHUYEN_NONG"), true);

  // Nhiếp Chính gift card
  state.phase = "PLAY";
  state.turnSeat = 1;
  p1.hand = [{ id: "GIFT_CARD", name: "Đỡ", suit: "Diamond", rank: 5, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.DODGE }];
  state.players[2].hand = [];

  const giftRes = handleUseSkill(state, 1, "Nhiếp Chính", 3, "GIFT_CARD");
  assert.equal(giftRes.success, true);
  assert.equal(p1.hand.length, 0);
  assert.equal(state.players[2].hand.length, 1);

  // Khuyến Nông heal trigger: someone heals -> Ỷ Lan & healed each draw 1
  state.players[1].hp = 2;
  state.players[1].maxHp = 4;
  p1.hand = [];
  state.players[1].hand = [{ id: "PEACH_1", name: "Bánh Chưng", suit: "Heart", rank: 8, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.PEACH }];
  state._deck = [
    { id: "HEAL_DRAW_1", name: "Trảm", suit: "Spade", rank: 2, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.ATTACK_NORMAL },
    { id: "HEAL_DRAW_2", name: "Trảm", suit: "Spade", rank: 3, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.ATTACK_NORMAL }
  ];
  state.phase = "PLAY";
  state.turnSeat = 2;
  const peachRes = handlePlayCard(state, 2, "PEACH_1", 2);
  assert.equal(peachRes.success, true);
  assert.equal(state.players[1].hp, 3);
  // Khuyến Nông now asks Ỷ Lan before drawing for both players.
  assert.equal(state.phase, "AWAIT_KHUYEN_NONG");
  assert.equal(state.waitingTargetSeat, 1);
  const khuyenNongRes = handleRespondAction(state, 1, true, null);
  assert.equal(khuyenNongRes.success, true);
  assert.equal(p1.hand.length, 1);
  console.log("✅ Hero 43: Ỷ Lan (Nhiếp Chính & Khuyến Nông) OK");
}

// -------------------------------------------------------------
// Test Hero 44: Tông Đản (Thổ Binh & Sơn Chiến)
// -------------------------------------------------------------
{
  const state = createTestState(["HERO_44", "HERO_2", "HERO_3", "HERO_4"]);
  const p1 = state.players[0];
  assert.equal(heroHasSkill(p1, "THO_BINH"), true);
  assert.equal(heroHasSkill(p1, "SON_CHIEN"), true);

  // Sơn Chiến: horse card as Fire Slash
  p1.hand = [{ id: "HORSE_1", name: "Chiến Mã Xích Thố", suit: "Heart", rank: 5, category: CARD_CATEGORIES.EQUIPMENT, subType: CARD_SUBTYPES.OFFENSIVE_HORSE, distMod: -1 }];
  state.players[1].hand = [
    { id: "DODGE_LOW", name: "Đỡ", suit: "Diamond", rank: 3, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.DODGE },
    { id: "DODGE_HIGH", name: "Đỡ", suit: "Diamond", rank: 9, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.DODGE }
  ];
  state.phase = "PLAY";
  state.turnSeat = 1;

  const playRes = handlePlayCard(state, 1, "HORSE_1", 2);
  assert.equal(playRes.success, true);
  assert.equal(state.phase, "AWAIT_SLASH_DEFENSE");

  // Thổ Binh: Distance <= 2, Dodge rank 2..7 is rejected
  const dodgeLowRes = handleRespondAction(state, 2, true, "DODGE_LOW");
  assert.equal(dodgeLowRes.error !== undefined, true);

  // Dodge rank 9 is accepted
  const dodgeHighRes = handleRespondAction(state, 2, true, "DODGE_HIGH");
  assert.equal(dodgeHighRes.success, true);
  console.log("✅ Hero 44: Tông Đản (Thổ Binh & Sơn Chiến) OK");
}

// -------------------------------------------------------------
// Test Hero 45: Thân Cảnh Phúc (Động Phục & Phò Vương)
// -------------------------------------------------------------
{
  const state = createTestState(["HERO_1", "HERO_45", "HERO_3", "HERO_4"]);
  const p2 = state.players[1];
  assert.equal(heroHasSkill(p2, "DONG_PHUC"), true);
  assert.equal(heroHasSkill(p2, "PHO_VUONG"), true);

  // Động Phục: taking damage from scroll card -> draw 2
  for (const p of state.players) p.hand = [];
  p2.hp = 4;
  p2.hand = [];
  state._deck = [
    { id: "DP_DRAW_1", name: "Trảm", suit: "Spade", rank: 2, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.ATTACK_NORMAL },
    { id: "DP_DRAW_2", name: "Trảm", suit: "Spade", rank: 3, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.ATTACK_NORMAL }
  ];
  // P1 plays Huyết Chiến / Duel on P2
  state.players[0].hand = [{ id: "DUEL_1", name: "Huyết Chiến", suit: "Spade", rank: 1, category: CARD_CATEGORIES.INSTANT_SCROLL, subType: CARD_SUBTYPES.BLOOD_BATTLE }];
  state.phase = "PLAY";
  state.turnSeat = 1;
  const duelRes = handlePlayCard(state, 1, "DUEL_1", 2);
  assert.equal(duelRes.success, true);
  assert.equal(state.phase, "AWAIT_DUEL");

  // P2 declines duel slash -> takes 1 damage from scroll
  const respRes = handleRespondAction(state, 2, false, null);
  assert.equal(respRes.success, true);
  assert.equal(p2.hp, 3);
  assert.equal(p2.hand.length, 2); // Drew 2 from Động Phục!

  // Phò Vương: when equip count is highest
  p2.equipments = [
    { id: "EQ1", name: "Vũ khí", subType: CARD_SUBTYPES.WEAPON },
    { id: "EQ2", name: "Áo giáp", subType: CARD_SUBTYPES.ARMOR }
  ];
  // Distance from P1 to P2 with Phò Vương defensive horse (+1)
  // Distance from P2 to P1 with Phò Vương offensive horse (-1)
  assert.equal(heroHasSkill(p2, "PHO_VUONG"), true);
  console.log("✅ Hero 45: Thân Cảnh Phúc (Động Phục & Phò Vương) OK");
}

// -------------------------------------------------------------
// Test Hero 46: Tô Hiến Thành (Thiết Diện, Thang Mộc, Giải Ách)
// -------------------------------------------------------------
{
  const state = createTestState(["HERO_1", "HERO_46", "HERO_3", "HERO_4"]);
  const p2 = state.players[1];
  assert.equal(heroHasSkill(p2, "THIET_DIEN"), true);
  assert.equal(heroHasSkill(p2, "THANG_MOC"), true);
  assert.equal(heroHasSkill(p2, "GIAI_ACH"), true);

  // Thiết Diện: P1 cannot target P2 with Vườn Không or Đột Kích
  state.players[0].hand = [{ id: "SNATCH_1", name: "Vườn Không Nhà Trống", suit: "Spade", rank: 3, category: CARD_CATEGORIES.INSTANT_SCROLL, subType: CARD_SUBTYPES.SNATCH }];
  p2.hand = [{ id: "P2_H1", name: "Trảm", suit: "Spade", rank: 5, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.ATTACK_NORMAL }];
  state.phase = "PLAY";
  state.turnSeat = 1;
  const snatchRes = handlePlayCard(state, 1, "SNATCH_1", 2);
  assert.equal(snatchRes.error !== undefined, true);
  assert.match(snatchRes.error, /Thiết Diện/);

  // Thang Mộc: at end of P1's turn, P2 draws 2 and self-attaches delayed scroll
  p2.hand = [];
  state._deck = [
    { id: "TM_DRAW_1", name: "Trảm", suit: "Spade", rank: 2, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.ATTACK_NORMAL },
    { id: "TM_DRAW_2", name: "Trảm", suit: "Spade", rank: 3, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.ATTACK_NORMAL }
  ];
  const endRes = handleEndTurn(state, 1);
  assert.equal(endRes.success, true);
  assert.equal(state.phase, "AWAIT_THANG_MOC");
  assert.equal(state.waitingTargetSeat, 2);

  const tmResp = handleRespondAction(state, 2, true, CARD_SUBTYPES.SUPPLY_SHORTAGE);
  assert.equal(tmResp.success, true);
  assert.equal(p2.hand.length, 2);
  assert.equal((p2.judgements || []).length, 1);

  // Giải Ách: when escaping delayed scroll
  assert.equal(heroHasSkill(p2, "GIAI_ACH"), true);
  console.log("✅ Hero 46: Tô Hiến Thành (Thiết Diện, Thang Mộc, Giải Ách) OK");
}

// -------------------------------------------------------------
// Test Hero 47: Lý Thường Kiệt (Tiến Thoái & Nam Quốc Sơn Hà)
// -------------------------------------------------------------
{
  const state = createTestState(["HERO_47", "HERO_2", "HERO_3", "HERO_4"]);
  const p1 = state.players[0];
  assert.equal(heroHasSkill(p1, "TIEN_THOAI"), true);
  assert.equal(heroHasSkill(p1, "NAM_QUOC_SON_HA"), true);

  // Tiến Thoái: Play Dodge as Slash!
  p1.hand = [{ id: "DODGE_AS_SLASH", name: "Đỡ", suit: "Heart", rank: 2, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.DODGE }];
  state.players[1].hand = [];
  state.players[1].hp = 4;
  state.phase = "PLAY";
  state.turnSeat = 1;

  const playRes = handlePlayCard(state, 1, "DODGE_AS_SLASH", 2);
  assert.equal(playRes.success, true);
  assert.equal(state.phase, "AWAIT_SLASH_DEFENSE");

  // P2 cannot dodge -> takes damage from Slash
  const respRes = handleRespondAction(state, 2, false, null);
  assert.equal(respRes.success, true);
  assert.equal(state.players[1].hp, 3);
  // Nam Quốc Sơn Hà triggered! P1 and ally gain +1 attack range
  assert.equal(p1.namQuocSonHaRangeBuff >= 1, true);
  console.log("✅ Hero 47: Lý Thường Kiệt (Tiến Thoái & Nam Quốc Sơn Hà) OK");
}

// -------------------------------------------------------------
// Test Hero 48: Trần Cảnh (Khai Sáng & Cương Kỷ)
// -------------------------------------------------------------
{
  const state = createTestState(["HERO_48", "HERO_2", "HERO_3", "HERO_4"]);
  const p1 = state.players[0];
  assert.equal(heroHasSkill(p1, "KHAI_SANG"), true);
  assert.equal(heroHasSkill(p1, "CUONG_KY"), true);

  // Khai Sáng: equip weapon heals 1 HP (1/turn)
  p1.hp = 3;
  p1.maxHp = 4;
  p1.hand = [{ id: "WEAPON_1", name: "Trường Đao", suit: "Spade", rank: 5, category: CARD_CATEGORIES.EQUIPMENT, subType: CARD_SUBTYPES.WEAPON, range: 3 }];
  state.phase = "PLAY";
  state.turnSeat = 1;

  const equipRes = handlePlayCard(state, 1, "WEAPON_1", 1);
  assert.equal(equipRes.success, true);
  assert.equal(p1.hp, 4); // Healed 1 HP!
  assert.equal(p1.equipments.length, 1);
  console.log("✅ Hero 48: Trần Cảnh (Khai Sáng & Cương Kỷ) OK");
}

// -------------------------------------------------------------
// Test Hero 49: Trần Thủ Độ (Chuyên Chế & Đoạt Quyền)
// -------------------------------------------------------------
{
  const state = createTestState(["HERO_49", "HERO_2", "HERO_3", "HERO_4"]);
  const p1 = state.players[0];
  const p2 = state.players[1];
  assert.equal(p1.maxHp, 3); // 3 HP!
  assert.equal(heroHasSkill(p1, "CHUYEN_CHE"), true);
  assert.equal(heroHasSkill(p1, "DOAT_QUYEN"), true);

  // Chuyên Chế: P1 discards 1 card to destroy P2's equipment, P2 must play Slash or lose 1 HP
  p1.hand = [{ id: "COST_1", name: "Trảm", suit: "Spade", rank: 2, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.ATTACK_NORMAL }];
  p2.equipments = [{ id: "P2_ARMOR", name: "Áo Giáp", category: CARD_CATEGORIES.EQUIPMENT, subType: CARD_SUBTYPES.ARMOR }];
  p2.hand = [{ id: "P2_SLASH", name: "Trảm", suit: "Spade", rank: 8, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.ATTACK_NORMAL }];
  state.phase = "PLAY";
  state.turnSeat = 1;

  const useRes = handleUseSkill(state, 1, "Chuyên Chế", 2, "COST_1");
  assert.equal(useRes.success, true);
  assert.equal(state.phase, "AWAIT_CHUYEN_CHE_RESPOND");
  assert.equal(state.waitingTargetSeat, 2);
  assert.equal(p2.equipments.length, 0); // Destroyed!

  // P2 responds with Slash
  const respRes = handleRespondAction(state, 2, true, "P2_SLASH");
  assert.equal(respRes.success, true);
  assert.equal(state.phase, "PLAY");
  console.log("✅ Hero 49: Trần Thủ Độ (Chuyên Chế & Đoạt Quyền) OK");
}

// -------------------------------------------------------------
// Test Hero 50: Trần Liễu (Ấp Phụ & Bổn Phận)
// -------------------------------------------------------------
{
  const state = createTestState(["HERO_1", "HERO_50", "HERO_3", "HERO_4"]);
  const p1 = state.players[0];
  const p2 = state.players[1];
  assert.equal(heroHasSkill(p2, "AP_PHU"), true);
  assert.equal(heroHasSkill(p2, "BON_PHAN"), true);

  // Ấp Phụ: P2 loses HP from P1 -> draws 1 and retrieves 1 Slash from discard
  state._discard = [{ id: "DISCARD_SLASH", name: "Trảm", suit: "Spade", rank: 7, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.ATTACK_NORMAL }];
  state._deck = [{ id: "AP_DRAW", name: "Đỡ", suit: "Heart", rank: 3, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.DODGE }];
  p2.hand = [];
  p2.hp = 4;
  p1.hand = [{ id: "P1_SLASH", name: "Trảm", suit: "Spade", rank: 9, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.ATTACK_NORMAL }];
  state.phase = "PLAY";
  state.turnSeat = 1;

  const playRes = handlePlayCard(state, 1, "P1_SLASH", 2);
  assert.equal(playRes.success, true);
  // P2 declines to dodge -> takes damage
  const respRes = handleRespondAction(state, 2, false, null);
  assert.equal(respRes.success, true);
  assert.equal(p2.hp, 3);
  // P2 drew 1 from deck and retrieved 1 Slash from discard -> hand has 2 cards!
  assert.equal(p2.hand.length, 2);
  assert.equal(p2.hand.some(c => c.id === "DISCARD_SLASH"), true);

  // Bổn Phận: At end of P2's turn, give 1 Slash to P1
  state.phase = "PLAY";
  state.turnSeat = 2;
  p1.hand = [];
  const endRes = handleEndTurn(state, 2);
  assert.equal(endRes.success, true);
  assert.equal(state.phase, "AWAIT_BON_PHAN");
  assert.equal(state.waitingTargetSeat, 2);

  const bpResp = handleRespondAction(state, 2, true, "DISCARD_SLASH", 1);
  assert.equal(bpResp.success, true);
  assert.equal(p1.hand.some(c => c.id === "DISCARD_SLASH"), true);
  console.log("✅ Hero 50: Trần Liễu (Ấp Phụ & Bổn Phận) OK");
}

console.log("🎉 All heroes 41-50 skill unit tests passed!");
