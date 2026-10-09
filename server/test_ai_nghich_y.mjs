import assert from "node:assert/strict";
import {
  initGame,
  handlePlayCard,
  handleAIReaction,
  tickGameState,
} from "./functions/game-engine/src/gameEngine.js";

function makeCard(id, name, subType = 1, suit = "Spade", rank = 7) {
  return { id, name, subType, suit, rank, category: 0 };
}

console.log("=== Testing AI Kiều Công Tiễn (Nghịch Ý) ===");

// Test 1: AI Kiều Công Tiễn tự động kích hoạt Nghịch Ý và chuyển Trảm sang kẻ địch trong tầm
{
  const state = initGame("test-kct-redirect-enemy", [
    { seat: 1, heroId: "HERO_1", isAI: false }, // Team 1
    { seat: 2, heroId: "HERO_21", isAI: true },  // Kiều Công Tiễn (Team 2, AI)
    { seat: 3, heroId: "HERO_2", isAI: false }, // Team 1 (Enemy of Seat 2)
    { seat: 4, heroId: "HERO_4", isAI: false }, // Team 2 (Ally of Seat 2)
  ]);
  state.phase = "PLAY";
  state.turnSeat = 1;

  const slash = makeCard("slash-1", "Trảm", 1);
  state.players[0].hand = [slash];
  state.players[1].hand = [makeCard("hand-kct-1", "Sát", 1), makeCard("hand-kct-2", "Đỡ", 2)];

  const playRes = handlePlayCard(state, 1, slash.id, 2);
  assert.equal(playRes?.success, true);
  assert.equal(state.phase, "AWAIT_NGHICH_Y");
  assert.equal(state.waitingTargetSeat, 2);

  // AI reacts
  const aiRes = handleAIReaction(state, 2);
  assert.equal(aiRes?.success, true, "AI Nghịch Ý phản ứng thành công");
  assert.equal(state.phase, "AWAIT_SLASH_DEFENSE", "Sau Nghịch Ý phải chuyển sang AWAIT_SLASH_DEFENSE");
  assert.equal(state.waitingTargetSeat, 3, "Mục tiêu bị chuyển Trảm phải là Seat 3 (kẻ địch trong tầm)");
  assert.equal(state.activeCard.targetSeat, 3, "activeCard.targetSeat phải cập nhật thành Seat 3");
  console.log("✅ Test 1: AI Nghịch Ý chuyển Trảm sang kẻ địch trong tầm thành công");
}

// Test 2: AI Kiều Công Tiễn từ chối Nghịch Ý khi không có kẻ địch trong tầm (chỉ có đồng đội)
{
  const state = initGame("test-kct-no-enemy-in-range", [
    { seat: 1, heroId: "HERO_1", isAI: false }, // Team 1
    { seat: 2, heroId: "HERO_21", isAI: true },  // Kiều Công Tiễn (Team 2, AI)
    { seat: 3, heroId: "HERO_2", isAI: false }, // Team 1 (Đã chết)
    { seat: 4, heroId: "HERO_4", isAI: false }, // Team 2 (Đồng đội)
  ]);
  state.phase = "PLAY";
  state.turnSeat = 1;
  state.players[2].hp = 0; // Seat 3 dead

  const slash = makeCard("slash-1", "Trảm", 1);
  state.players[0].hand = [slash];
  state.players[1].hand = [makeCard("hand-kct-1", "Sát", 1)];

  const playRes = handlePlayCard(state, 1, slash.id, 2);
  assert.equal(playRes?.success, true);
  assert.equal(state.phase, "AWAIT_NGHICH_Y");

  // AI reacts: không chuyển sang đồng đội seat 4, phải từ chối
  const aiRes = handleAIReaction(state, 2);
  assert.equal(aiRes?.success, true);
  assert.equal(state.phase, "AWAIT_SLASH_DEFENSE");
  assert.equal(state.waitingTargetSeat, 2, "Từ chối Nghịch Ý thì mục tiêu vẫn là Kiều Công Tiễn");
  console.log("✅ Test 2: AI Nghịch Ý từ chối chuyển sang đồng đội và nhận đòn Trảm thành công");
}

// Test 3: AI Kiều Công Tiễn phản ứng real-time trong tickGameState (sau 1.5s) không bị kẹt game
{
  const state = initGame("test-kct-tick-realtime", [
    { seat: 1, heroId: "HERO_1", isAI: false },
    { seat: 2, heroId: "HERO_21", isAI: true }, // Kiều Công Tiễn (AI)
    { seat: 3, heroId: "HERO_2", isAI: false },
    { seat: 4, heroId: "HERO_4", isAI: false },
  ]);
  state.phase = "PLAY";
  state.turnSeat = 1;

  const slash = makeCard("slash-1", "Trảm", 1);
  state.players[0].hand = [slash];
  state.players[1].hand = [makeCard("hand-kct-1", "Sát", 1)];
  handlePlayCard(state, 1, slash.id, 2);
  assert.equal(state.phase, "AWAIT_NGHICH_Y");

  // Giả lập trôi qua 2s
  state.timerStartAt = Date.now() - 2000;
  const tickRes = tickGameState(state);
  assert.equal(tickRes?.changed, true);
  assert.equal(state.phase, "AWAIT_SLASH_DEFENSE", "Game loop không bị treo, đã chuyển phase");
  assert.equal(state.waitingTargetSeat, 3);
  console.log("✅ Test 3: tickGameState tự động phản ứng cho AI sau 1.5s không bị đơ kẹt");
}

// Test 4: Người chơi điều khiển Kiều Công Tiễn bị timeout (40s) được tickGameState xử lý trơn tru
{
  const state = initGame("test-kct-human-timeout", [
    { seat: 1, heroId: "HERO_1", isAI: false },
    { seat: 2, heroId: "HERO_21", isAI: false }, // Kiều Công Tiễn (Người chơi)
    { seat: 3, heroId: "HERO_2", isAI: false },  // Seat 3 chết
    { seat: 4, heroId: "HERO_4", isAI: false },
  ]);
  state.phase = "PLAY";
  state.turnSeat = 1;
  state.players[2].hp = 0; // Kẻ địch duy nhất còn lại là caster Seat 1

  const slash = makeCard("slash-1", "Trảm", 1);
  state.players[0].hand = [slash];
  state.players[1].hand = [makeCard("hand-kct-1", "Sát", 1)];
  handlePlayCard(state, 1, slash.id, 2);
  assert.equal(state.phase, "AWAIT_NGHICH_Y");

  // Giả lập timeout 41s
  state.timerStartAt = Date.now() - 41000;
  const tickRes = tickGameState(state);
  assert.equal(tickRes?.changed, true);
  assert.equal(state.phase, "AWAIT_SLASH_DEFENSE", "Hết 40s phải tự động từ chối và sang AWAIT_SLASH_DEFENSE");
  assert.equal(state.waitingTargetSeat, 2);
  console.log("✅ Test 4: Timeout 40s của người chơi tự động xử lý Nghịch Ý, không bao giờ kẹt game");
}

console.log("🎉 Tất cả các test Kiều Công Tiễn Nghịch Ý đều vượt qua!");
