import assert from "node:assert/strict";
import {
  initGame,
  handlePlayCard,
  handleRespondAction,
  handleUseSkill,
  handleAIReaction
} from "./functions/game-engine/src/gameEngine.js";
import { CARD_CATEGORIES, CARD_SUBTYPES } from "./functions/game-engine/src/deck.js";

function makeCard(id, name, subType, category = CARD_CATEGORIES.INSTANT_SCROLL, suit = "Heart", rank = 7) {
  return { id, name, subType, category, suit, rank };
}

function makeDeck(count = 30) {
  return Array.from({ length: count }, (_, i) =>
    makeCard(`deck-${i + 1}`, `Bài ${i + 1}`, CARD_SUBTYPES.DODGE, CARD_CATEGORIES.BASIC)
  );
}

function createTestState() {
  const state = initGame("TEST_VAN_SACH", [
    { id: "u1", name: "Tinh Thiều", heroId: "HERO_12", seat: 1, isAI: false },
    { id: "u2", name: "Đào Hãn", heroId: "HERO_2", seat: 2, isAI: true },
    { id: "u3", name: "Thi Sách", heroId: "HERO_3", seat: 3, isAI: true },
    { id: "u4", name: "Lê Chân", heroId: "HERO_4", seat: 4, isAI: true }
  ]);
  state.currentTurnSeat = 1;
  state.turnSeat = 1;
  state.phase = "PLAY";
  for (const p of state.players) {
    p.hand = [];
    p.equipments = [];
    p.judgements = [];
  }
  state._deck = makeDeck(30);
  state._discard = [];
  return state;
}

console.log("=== Testing Tinh Thiều: Văn Sách Skill ===");

// TEST 1: Văn Sách does not trigger on 1st scroll, triggers on 2nd scroll
{
  const state = createTestState();

  const scroll1 = makeCard("scroll-1", "Dụng Binh Như Thần", CARD_SUBTYPES.EX_NIHILO);
  const scroll2 = makeCard("scroll-2", "Dụng Binh Như Thần", CARD_SUBTYPES.EX_NIHILO);
  const discardFodder = makeCard("fodder-1", "Trảm", CARD_SUBTYPES.ATTACK_NORMAL, CARD_CATEGORIES.BASIC);

  state.players[0].hand = [scroll1, scroll2, discardFodder];

  // 1st scroll
  handlePlayCard(state, 1, scroll1.id);
  if (state.phase === "AWAIT_HAN_LAM") {
    handleRespondAction(state, 1, true, null);
  }
  assert.equal(state.phase, "PLAY", "Sau lá Cẩm Nang thứ nhất, Văn Sách chưa kích hoạt");
  assert.equal(state.players[0].usedSkills.CamNangUsedThisTurn, 1);

  // 2nd scroll
  handlePlayCard(state, 1, scroll2.id);
  if (state.phase === "AWAIT_HAN_LAM") {
    handleRespondAction(state, 1, true, null);
  }
  assert.equal(state.phase, "AWAIT_VAN_SACH", "Sau lá Cẩm Nang thứ hai, Văn Sách phải kích hoạt");
  assert.equal(state.waitingTargetSeat, 1);
  assert.equal(state.pendingVanSach.seat, 1);
  assert.equal(state.pendingVanSach.lastScroll.card.name, "Dụng Binh Như Thần");

  console.log("✅ TEST 1 Passed: Văn Sách triggers on 2nd scroll only");
}

// TEST 2: Văn Sách - Choice DRAW (Bỏ 1 lá để rút 1 lá)
{
  const state = createTestState();

  const scroll1 = makeCard("s1", "Dụng Binh Như Thần", CARD_SUBTYPES.EX_NIHILO);
  const scroll2 = makeCard("s2", "Dụng Binh Như Thần", CARD_SUBTYPES.EX_NIHILO);
  const fodder = makeCard("fodder", "Trảm", CARD_SUBTYPES.ATTACK_NORMAL, CARD_CATEGORIES.BASIC);

  state.players[0].hand = [scroll1, scroll2, fodder];

  handlePlayCard(state, 1, scroll1.id);
  if (state.phase === "AWAIT_HAN_LAM") handleRespondAction(state, 1, true, null);
  handlePlayCard(state, 1, scroll2.id);
  if (state.phase === "AWAIT_HAN_LAM") handleRespondAction(state, 1, true, null);

  assert.equal(state.phase, "AWAIT_VAN_SACH");
  const handCountBefore = state.players[0].hand.length;

  // Discard fodder to DRAW 1 card
  const res = handleRespondAction(state, 1, true, fodder.id, "DRAW", [], 0, { choice: "DRAW" });
  assert.equal(res.success, true);
  assert.equal(state.phase, "PLAY");
  // Fodder removed (-1) + drawn 1 (+1) => hand count unchanged
  assert.equal(state.players[0].hand.length, handCountBefore);
  assert.equal(state.players[0].hand.some(c => c.id === fodder.id), false, "Lá bỏ không còn trên tay");
  const lastAction = state.actionHistory.at(-1);
  assert.equal(lastAction.type, "VAN_SACH_TRIGGERED");
  assert.equal(lastAction.choice, "DRAW");

  console.log("✅ TEST 2 Passed: Văn Sách Choice DRAW functions properly");
}

// TEST 3: Văn Sách - Choice RECAST with Ex Nihilo (Dụng Binh Như Thần)
{
  const state = createTestState();

  const scroll1 = makeCard("s1", "Xích Tâm Tỏa", CARD_SUBTYPES.IRON_CHAIN);
  const scroll2 = makeCard("s2", "Dụng Binh Như Thần", CARD_SUBTYPES.EX_NIHILO);
  const fodder = makeCard("fodder", "Trảm", CARD_SUBTYPES.ATTACK_NORMAL, CARD_CATEGORIES.BASIC);

  state.players[0].hand = [scroll1, scroll2, fodder];

  // 1st scroll: Iron chain
  handlePlayCard(state, 1, scroll1.id, 2);
  if (state.phase === "AWAIT_HAN_LAM") handleRespondAction(state, 1, true, null);

  // 2nd scroll: Ex Nihilo (draws 2)
  handlePlayCard(state, 1, scroll2.id);
  if (state.phase === "AWAIT_HAN_LAM") handleRespondAction(state, 1, true, null);

  assert.equal(state.phase, "AWAIT_VAN_SACH");
  const handCountBeforeRecast = state.players[0].hand.length;

  // Recast Ex Nihilo: Discards 1 fodder, replays Ex Nihilo (draws 2 cards)
  const res = handleRespondAction(state, 1, true, fodder.id, "RECAST", [], 0, { choice: "RECAST", recast: true });
  assert.equal(res.success, true);
  assert.equal(state.phase, "PLAY", "Sau khi tái thi triển Cẩm Nang, game trở về phase PLAY");
  // -1 fodder + 2 drawn = net +1 card
  assert.equal(state.players[0].hand.length, handCountBeforeRecast - 1 + 2);
  assert.equal(state.players[0].usedSkills.CamNangUsedThisTurn, 2, "Recast không làm tăng CamNangUsedThisTurn");
  assert.equal(state.players[0].usedSkills.VanSachPending, false, "Không bị loop vô tận Văn Sách");

  console.log("✅ TEST 3 Passed: Văn Sách Choice RECAST Ex Nihilo works without infinite loop");
}

// TEST 4: Văn Sách - Choice RECAST with Dismantle (Phá Hủy)
{
  const state = createTestState();

  const scroll1 = makeCard("s1", "Dụng Binh Như Thần", CARD_SUBTYPES.EX_NIHILO);
  const scroll2 = makeCard("s2", "Phá Hủy", CARD_SUBTYPES.DISMANTLE);
  const fodder = makeCard("fodder", "Trảm", CARD_SUBTYPES.ATTACK_NORMAL, CARD_CATEGORIES.BASIC);
  const enemyCard = makeCard("enemy-card", "Kiếm", CARD_SUBTYPES.WEAPON, CARD_CATEGORIES.EQUIPMENT);

  state.players[0].hand = [scroll1, scroll2, fodder];
  state.players[1].hand = [enemyCard];
  state.players[2].hand = [makeCard("p3-card", "Giáp", CARD_SUBTYPES.ARMOR, CARD_CATEGORIES.EQUIPMENT)];

  handlePlayCard(state, 1, scroll1.id);
  if (state.phase === "AWAIT_HAN_LAM") handleRespondAction(state, 1, true, null);

  // Play Dismantle on Seat 2
  handlePlayCard(state, 1, scroll2.id, 2);
  if (state.phase === "AWAIT_HAN_LAM") handleRespondAction(state, 1, true, null);
  // Target card selection for Dismantle
  if (state.phase === "AWAIT_TARGET_CARD") {
    const token = state.targetCardSelection.options[0].token;
    handleRespondAction(state, 1, true, token);
  }

  assert.equal(state.phase, "AWAIT_VAN_SACH");
  assert.equal(state.pendingVanSach.lastScroll.card.name, "Phá Hủy");

  // Recast Dismantle targeting Seat 3
  const res = handleRespondAction(state, 1, true, fodder.id, "RECAST", [], 3, { choice: "RECAST", recast: true });
  assert.equal(res.success, true);
  // Dismantle on Seat 3 opens AWAIT_TARGET_CARD for Seat 3's card
  assert.equal(state.phase, "AWAIT_TARGET_CARD");
  assert.equal(state.targetCardSelection.targetSeat, 3, "Recast nhắm đúng mục tiêu chỉ định");

  // Complete target card selection
  const token3 = state.targetCardSelection.options[0].token;
  handleRespondAction(state, 1, true, token3);
  assert.equal(state.phase, "PLAY");
  assert.equal(state.players[2].hand.length, 0, "Lá của Ghế 3 đã bị phá hủy thành công");

  console.log("✅ TEST 4 Passed: Văn Sách Choice RECAST Dismantle targets and destroys correctly");
}

// TEST 5: Văn Sách - Decline (Từ chối)
{
  const state = createTestState();

  const scroll1 = makeCard("s1", "Dụng Binh Như Thần", CARD_SUBTYPES.EX_NIHILO);
  const scroll2 = makeCard("s2", "Dụng Binh Như Thần", CARD_SUBTYPES.EX_NIHILO);
  const fodder = makeCard("fodder", "Trảm", CARD_SUBTYPES.ATTACK_NORMAL, CARD_CATEGORIES.BASIC);

  state.players[0].hand = [scroll1, scroll2, fodder];

  handlePlayCard(state, 1, scroll1.id);
  if (state.phase === "AWAIT_HAN_LAM") handleRespondAction(state, 1, true, null);
  handlePlayCard(state, 1, scroll2.id);
  if (state.phase === "AWAIT_HAN_LAM") handleRespondAction(state, 1, true, null);

  assert.equal(state.phase, "AWAIT_VAN_SACH");
  handleRespondAction(state, 1, false, null);
  assert.equal(state.phase, "PLAY");
  assert.equal(state.players[0].hand.some(c => c.id === fodder.id), true, "Từ chối không bị mất bài");

  console.log("✅ TEST 5 Passed: Văn Sách Decline works properly");
}

// TEST 6: AI Tinh Thiều Reaction (AI tự động chọn RECAST)
{
  const state = createTestState();

  const scroll1 = makeCard("s1", "Dụng Binh Như Thần", CARD_SUBTYPES.EX_NIHILO);
  const scroll2 = makeCard("s2", "Dụng Binh Như Thần", CARD_SUBTYPES.EX_NIHILO);
  const fodder = makeCard("fodder", "Trảm", CARD_SUBTYPES.ATTACK_NORMAL, CARD_CATEGORIES.BASIC);

  state.players[0].hand = [scroll1, scroll2, fodder];

  handlePlayCard(state, 1, scroll1.id);
  if (state.phase === "AWAIT_HAN_LAM") handleRespondAction(state, 1, true, null);
  handlePlayCard(state, 1, scroll2.id);
  if (state.phase === "AWAIT_HAN_LAM") handleRespondAction(state, 1, true, null);

  assert.equal(state.phase, "AWAIT_VAN_SACH");
  const aiRes = handleAIReaction(state, 1);
  assert.equal(aiRes.success, true);
  assert.equal(state.phase, "PLAY");
  const actions = state.actionHistory.filter(a => a.type === "VAN_SACH_TRIGGERED");
  assert.equal(actions.length, 1);
  assert.equal(actions[0].choice, "RECAST", "AI Tinh Thiều chọn RECAST");

  console.log("✅ TEST 6 Passed: AI Tinh Thiều handles RECAST automatically");
}

// TEST 7: Backward compatibility - handleRespondAction with default draw
{
  const state = createTestState();

  const scroll1 = makeCard("s1", "Dụng Binh Như Thần", CARD_SUBTYPES.EX_NIHILO);
  const scroll2 = makeCard("s2", "Dụng Binh Như Thần", CARD_SUBTYPES.EX_NIHILO);
  const fodder = makeCard("fodder", "Trảm", CARD_SUBTYPES.ATTACK_NORMAL, CARD_CATEGORIES.BASIC);

  state.players[0].hand = [scroll1, scroll2, fodder];

  handlePlayCard(state, 1, scroll1.id);
  if (state.phase === "AWAIT_HAN_LAM") handleRespondAction(state, 1, true, null);
  handlePlayCard(state, 1, scroll2.id);
  if (state.phase === "AWAIT_HAN_LAM") handleRespondAction(state, 1, true, null);

  assert.equal(state.phase, "AWAIT_VAN_SACH");
  // Old style call without choice or payload
  const res = handleRespondAction(state, 1, true, fodder.id);
  assert.equal(res.success, true);
  assert.equal(state.phase, "PLAY");
  const lastAction = state.actionHistory.at(-1);
  assert.equal(lastAction.type, "VAN_SACH_TRIGGERED");
  assert.equal(lastAction.choice, "DRAW", "Mặc định là DRAW khi không truyền choice");

  console.log("✅ TEST 7 Passed: Backward compatibility with default draw");
}

// TEST 8: handleUseSkill during AWAIT_VAN_SACH
{
  const state = createTestState();

  const scroll1 = makeCard("s1", "Dụng Binh Như Thần", CARD_SUBTYPES.EX_NIHILO);
  const scroll2 = makeCard("s2", "Dụng Binh Như Thần", CARD_SUBTYPES.EX_NIHILO);
  const fodder = makeCard("fodder", "Trảm", CARD_SUBTYPES.ATTACK_NORMAL, CARD_CATEGORIES.BASIC);

  state.players[0].hand = [scroll1, scroll2, fodder];

  handlePlayCard(state, 1, scroll1.id);
  if (state.phase === "AWAIT_HAN_LAM") handleRespondAction(state, 1, true, null);
  handlePlayCard(state, 1, scroll2.id);
  if (state.phase === "AWAIT_HAN_LAM") handleRespondAction(state, 1, true, null);

  assert.equal(state.phase, "AWAIT_VAN_SACH");
  const res = handleUseSkill(state, 1, "Văn Sách", 0, fodder.id);
  assert.equal(res?.success, true);
  assert.equal(state.phase, "PLAY");

  console.log("✅ TEST 8 Passed: handleUseSkill routes properly during AWAIT_VAN_SACH");
}

console.log("\n🎉 ALL TINH THIỀU VĂN SÁCH TESTS PASSED!");
