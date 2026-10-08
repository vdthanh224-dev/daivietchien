import assert from "node:assert/strict";
import {
  initGame,
  handlePlayCard,
  handleAIStep,
  handleAIReaction,
} from "./functions/game-engine/src/gameEngine.js";
import { CARD_SUBTYPES } from "./functions/game-engine/src/deck.js";

function makeCard(id, name, subType = CARD_SUBTYPES.ATTACK_NORMAL, suit = "Spade", rank = 7) {
  return { id, name, subType, suit, rank, category: 0 };
}

// Test 1: AI ưu tiên đánh Trảm vào kẻ địch khác khi Triệu Quang Phục không có bài (Dạ Trạch)
{
  const state = initGame("test-ai-skip-da-trach", [
    { seat: 1, heroId: "HERO_1", isAI: true },  // AI (Team 1)
    { seat: 2, heroId: "HERO_14", isAI: false }, // Triệu Quang Phục (Team 2)
    { seat: 3, heroId: "HERO_2", isAI: false },  // Team 1
    { seat: 4, heroId: "HERO_4", isAI: false }   // Lê Chân (Team 2)
  ]);

  state.phase = "PLAY";
  state.turnSeat = 1;
  state.slashesUsedThisTurn = 0;

  // AI có 1 lá Trảm
  state.players[0].hand = [makeCard("slash-1", "Trảm", CARD_SUBTYPES.SLASH)];

  // Seat 2 (Triệu Quang Phục) không có bài trên tay (Dạ Trạch kích hoạt)
  state.players[1].hand = [];

  // Seat 4 (Lê Chân) có bài trên tay
  state.players[3].hand = [makeCard("dodge-4", "Đỡ", CARD_SUBTYPES.DODGE)];

  // AI thực hiện lượt
  const res = handleAIStep(state, 1);
  assert.equal(res?.success, true, "AI đánh bài phải thành công");

  // Kiểm tra mục tiêu bị Trảm: Phải là Seat 4 (Lê Chân), tuyệt đối không được là Seat 2 (Triệu Quang Phục)
  const slashAction = state.actionHistory.find((a) => (a.type === "PLAY_SLASH" || a.type === "PLAY_CARD") && a.cardName?.includes("Trảm"));
  assert.ok(slashAction, "AI phải đánh lá Trảm");
  assert.equal(slashAction.targetSeat, 4, "Mục tiêu của Trảm phải là Seat 4, không được đánh Triệu Quang Phục");
  console.log("[PASS] Test 1: AI chọn Seat 4 thay vì Triệu Quang Phục 0 bài");
}

// Test 2: AI không đánh Trảm khi kẻ địch duy nhất là Triệu Quang Phục đang không có bài
{
  const state = initGame("test-ai-solo-da-trach", [
    { seat: 1, heroId: "HERO_1", isAI: true },  // AI (Team 1)
    { seat: 2, heroId: "HERO_14", isAI: false }, // Triệu Quang Phục (Team 2)
    { seat: 3, heroId: "HERO_2", isAI: false },  // Team 1
    { seat: 4, heroId: "HERO_4", isAI: false }   // Dead (Team 2)
  ]);

  // Seat 4 đã chết
  state.players[3].hp = 0;

  state.phase = "PLAY";
  state.turnSeat = 1;
  state.slashesUsedThisTurn = 0;

  // AI có 1 lá Trảm
  state.players[0].hand = [makeCard("slash-1", "Trảm", CARD_SUBTYPES.SLASH)];

  // Triệu Quang Phục không có bài trên tay
  state.players[1].hand = [];

  // AI thực hiện lượt: Không có mục tiêu hợp lệ -> Kết thúc lượt, không được ra Trảm
  const res = handleAIStep(state, 1);
  assert.equal(res?.success, true, "AI kết thúc lượt thành công");

  const slashAction = state.actionHistory.find((a) => (a.type === "PLAY_SLASH" || a.type === "PLAY_CARD") && a.cardName?.includes("Trảm"));
  assert.equal(slashAction, undefined, "AI tuyệt đối không được đánh Trảm vào Triệu Quang Phục không có bài");
  assert.equal(state.slashesUsedThisTurn, 0, "Không có đòn Trảm nào được tung ra");
  console.log("[PASS] Test 2: AI không đánh Trảm khi Triệu Quang Phục 0 bài là đối thủ duy nhất");
}

// Test 3: AI không uống Rượu khi không có mục tiêu Trảm hợp lệ (Triệu Quang Phục 0 bài)
{
  const state = initGame("test-ai-wine-da-trach", [
    { seat: 1, heroId: "HERO_1", isAI: true },  // AI (Team 1)
    { seat: 2, heroId: "HERO_14", isAI: false }, // Triệu Quang Phục (Team 2)
    { seat: 3, heroId: "HERO_2", isAI: false },  // Team 1
    { seat: 4, heroId: "HERO_4", isAI: false }   // Dead (Team 2)
  ]);

  state.players[3].hp = 0;
  state.phase = "PLAY";
  state.turnSeat = 1;

  // AI có cả Rượu và Trảm
  state.players[0].hand = [
    makeCard("wine-1", "Hủ Rượu", CARD_SUBTYPES.WINE),
    makeCard("slash-1", "Trảm", CARD_SUBTYPES.SLASH)
  ];
  state.players[1].hand = []; // Triệu Quang Phục 0 bài

  handleAIStep(state, 1);

  const wineAction = state.actionHistory.find((a) => a.type === "PLAY_CARD" && a.cardName?.includes("Rượu"));
  assert.equal(wineAction, undefined, "AI không được uống Rượu vô ích khi không có mục tiêu Trảm hợp lệ");
  console.log("[PASS] Test 3: AI không uống Rượu khi đối thủ là Triệu Quang Phục 0 bài");
}

// Test 4: Khi Triệu Quang Phục CÓ bài trên tay, AI vẫn đánh Trảm bình thường
{
  const state = initGame("test-ai-slash-tqp-with-cards", [
    { seat: 1, heroId: "HERO_1", isAI: true },  // AI (Team 1)
    { seat: 2, heroId: "HERO_14", isAI: false }, // Triệu Quang Phục (Team 2)
    { seat: 3, heroId: "HERO_2", isAI: false },  // Team 1
    { seat: 4, heroId: "HERO_4", isAI: false }   // Dead (Team 2)
  ]);

  state.players[3].hp = 0;
  state.phase = "PLAY";
  state.turnSeat = 1;
  state.slashesUsedThisTurn = 0;

  // AI có Trảm
  state.players[0].hand = [makeCard("slash-1", "Trảm", CARD_SUBTYPES.SLASH)];

  // Triệu Quang Phục CÓ bài trên tay (Dạ Trạch KHÔNG kích hoạt)
  state.players[1].hand = [makeCard("dodge-2", "Đỡ", CARD_SUBTYPES.DODGE)];

  handleAIStep(state, 1);

  const slashAction = state.actionHistory.find((a) => (a.type === "PLAY_SLASH" || a.type === "PLAY_CARD") && a.cardName?.includes("Trảm"));
  assert.ok(slashAction, "AI được phép đánh Trảm khi Triệu Quang Phục có bài trên tay");
  assert.equal(slashAction.targetSeat, 2, "Mục tiêu là Seat 2");
  console.log("[PASS] Test 4: AI đánh Trảm vào Triệu Quang Phục khi có bài thành công");
}

// Test 5: Mượn Gươm Diệt Địch không thể ép chém vào Triệu Quang Phục 0 bài
{
  const state = initGame("test-borrow-sword-da-trach", [
    { seat: 1, heroId: "HERO_1", isAI: false }, // Player
    { seat: 2, heroId: "HERO_4", isAI: false }, // Có vũ khí
    { seat: 3, heroId: "HERO_14", isAI: false }, // Triệu Quang Phục (0 bài)
    { seat: 4, heroId: "HERO_2", isAI: false }
  ]);

  state.players[1].equipments = [{ id: "wp-1", name: "Song Cung Mường Nhạ", subType: CARD_SUBTYPES.WEAPON, range: 2 }];
  state.players[2].hand = []; // Triệu Quang Phục 0 bài

  state.players[0].hand = [makeCard("borrow-1", "Mượn Gươm Diệt Địch", CARD_SUBTYPES.MUON_GUOM_DIET_DICH)];
  state.phase = "PLAY";
  state.turnSeat = 1;

  // Cố gắng ép Seat 2 chém Seat 3 (Triệu Quang Phục 0 bài)
  const res = handlePlayCard(state, 1, "borrow-1", 2, { targetSeat2: 3 });
  assert.ok(res?.error, "Mượn Gươm nhắm vào Triệu Quang Phục 0 bài phải bị từ chối");
  assert.equal(res?.code, "DA_TRACH_BLOCKED");
  console.log("[PASS] Test 5: Mượn Gươm Diệt Địch bị chặn bởi Dạ Trạch khi Triệu Quang Phục 0 bài");
}

console.log("\n==========================================");
console.log("TẤT CẢ 5 TESTS AI DẠ TRẠCH ĐỀU THÀNH CÔNG!");
console.log("==========================================");
