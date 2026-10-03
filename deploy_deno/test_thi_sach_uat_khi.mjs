import assert from "node:assert/strict";
import {
  initGame,
  handlePlayCard,
  handleRespondAction,
  handleAIReaction,
  tickGameState,
} from "./functions/game-engine/src/gameEngine.js";
import { CARD_SUBTYPES } from "./functions/game-engine/src/deck.js";

function makeCard(id, name, subType = CARD_SUBTYPES.ATTACK_NORMAL, suit = "Spade", rank = 7) {
  return { id, name, subType, suit, rank, category: 0 };
}

// Test 1: AI Thi Sách tự chọn đồng đội khi đồng đội có ít bài hơn
{
  const state = initGame("test-uat-khi-teammate", [
    { seat: 1, heroId: "HERO_1", isAI: false },
    { seat: 2, heroId: "HERO_3", isAI: true }, // Thi Sách (Team 2)
    { seat: 3, heroId: "HERO_2", isAI: false },
    { seat: 4, heroId: "HERO_4", isAI: true }  // Lê Chân (Team 2, đồng đội của Thi Sách)
  ]);

  // Seat 2 (Thi Sách) có 3 lá, Seat 4 (đồng đội) có 1 lá
  state.players[1].hand = [makeCard("c1", "Đỡ", CARD_SUBTYPES.DODGE), makeCard("c2", "Đỡ", CARD_SUBTYPES.DODGE), makeCard("c3", "Đỡ", CARD_SUBTYPES.DODGE)];
  state.players[3].hand = [makeCard("c4", "Trảm", CARD_SUBTYPES.ATTACK_NORMAL)];
  state.players[0].hand = [makeCard("slash-1", "Trảm", CARD_SUBTYPES.ATTACK_NORMAL)];

  // Seat 1 Trảm Seat 2
  handlePlayCard(state, 1, "slash-1", 2);
  // Seat 2 không Đỡ -> Mất 1 Máu (từ 4 xuống 3, chưa cận tử)
  handleRespondAction(state, 2, false, null);

  assert.equal(state.phase, "AWAIT_UAT_KHI", "Pha phải chuyển sang AWAIT_UAT_KHI khi mất máu chưa cận tử");
  assert.equal(state.waitingTargetSeat, 2, "Thi Sách phải là người chờ phản ứng Uất Khí");
  assert.equal(state.uatKhiQueue.length, 1);

  const teammateHandBefore = state.players[3].hand.length;

  // AI Thi Sách phản ứng Uất Khí
  const res = handleAIReaction(state, 2);
  assert.equal(res?.success, true, "AI phản ứng Uất Khí phải thành công");
  assert.equal(state.players[3].hand.length, teammateHandBefore + 1, "Đồng đội ít bài hơn phải được rút 1 lá bài");

  const uatKhiAction = state.actionHistory.find((a) => a.type === "UAT_KHI_DRAW");
  assert.ok(uatKhiAction, "Phải ghi nhận action UAT_KHI_DRAW");
  assert.equal(uatKhiAction.casterSeat, 2, "Người phát động là Thi Sách (Seat 2)");
  assert.equal(uatKhiAction.targetSeat, 4, "Mục tiêu được chọn là đồng đội (Seat 4)");
  assert.equal(state.phase, "PLAY", "Sau khi giải quyết Uất Khí, game phải tiếp tục pha PLAY");
}

// Test 2: AI Thi Sách tự chọn bản thân khi bản thân có ít bài hơn đồng đội
{
  const state = initGame("test-uat-khi-self", [
    { seat: 1, heroId: "HERO_1", isAI: false },
    { seat: 2, heroId: "HERO_3", isAI: true }, // Thi Sách (Team 2)
    { seat: 3, heroId: "HERO_2", isAI: false },
    { seat: 4, heroId: "HERO_4", isAI: true }  // Lê Chân (Team 2)
  ]);

  // Seat 2 (Thi Sách) có 0 lá, Seat 4 (đồng đội) có 3 lá
  state.players[1].hand = [];
  state.players[3].hand = [makeCard("c1", "Trảm"), makeCard("c2", "Trảm"), makeCard("c3", "Trảm")];
  state.players[0].hand = [makeCard("slash-2", "Trảm", CARD_SUBTYPES.ATTACK_NORMAL)];

  // Seat 1 Trảm Seat 2 -> mất 1 máu
  handlePlayCard(state, 1, "slash-2", 2);
  handleRespondAction(state, 2, false, null);

  assert.equal(state.phase, "AWAIT_UAT_KHI");
  assert.equal(state.waitingTargetSeat, 2);

  // AI Thi Sách phản ứng
  const res = handleAIReaction(state, 2);
  assert.equal(res?.success, true);
  assert.equal(state.players[1].hand.length, 1, "Thi Sách ít bài hơn phải tự chọn bản thân rút 1 lá bài");

  const uatKhiAction = state.actionHistory.filter((a) => a.type === "UAT_KHI_DRAW").pop();
  assert.ok(uatKhiAction);
  assert.equal(uatKhiAction.targetSeat, 2, "Mục tiêu được chọn phải là chính Thi Sách (Seat 2)");
}

// Test 3: tickGameState tự động phản ứng cho AI Thi Sách sau 1.5s
{
  const state = initGame("test-uat-khi-tick", [
    { seat: 1, heroId: "HERO_1", isAI: false },
    { seat: 2, heroId: "HERO_3", isAI: true }, // Thi Sách (AI)
    { seat: 3, heroId: "HERO_2", isAI: false },
    { seat: 4, heroId: "HERO_4", isAI: true }
  ]);

  state.players[1].hand = [];
  state.players[0].hand = [makeCard("slash-3", "Trảm", CARD_SUBTYPES.ATTACK_NORMAL)];

  handlePlayCard(state, 1, "slash-3", 2);
  handleRespondAction(state, 2, false, null);

  assert.equal(state.phase, "AWAIT_UAT_KHI");

  // Giả lập trôi qua 1600ms
  state.timerStartAt = Date.now() - 1600;
  const tickRes = tickGameState(state);
  assert.equal(tickRes.changed, true, "tickGameState phải xử lý hành động AI khi elapsedMs >= 1500");
  assert.equal(state.phase, "PLAY", "tickGameState phải giải quyết xong AWAIT_UAT_KHI");
  assert.equal(state.players[1].hand.length, 1, "Thi Sách phải nhận được lá bài");
}

// Test 4: Khi đồng đội của Thi Sách ĐÃ CHẾT (không còn đồng đội) -> Phải tự buff lên chính mình
{
  const state = initGame("test-uat-khi-no-teammate", [
    { seat: 1, heroId: "HERO_1", isAI: false },
    { seat: 2, heroId: "HERO_3", isAI: true }, // Thi Sách (Team 2)
    { seat: 3, heroId: "HERO_2", isAI: false },
    { seat: 4, heroId: "HERO_4", isAI: true }  // Lê Chân (Team 2, đã chết)
  ]);

  // Đồng đội (Seat 4) đã chết
  state.players[3].hp = 0;
  state.players[3].isAlive = false;

  state.players[1].hand = [makeCard("c1", "Trảm")];
  state.players[0].hand = [makeCard("slash-4", "Trảm", CARD_SUBTYPES.ATTACK_NORMAL)];

  // Seat 1 Trảm Thi Sách
  handlePlayCard(state, 1, "slash-4", 2);
  handleRespondAction(state, 2, false, null);

  assert.equal(state.phase, "AWAIT_UAT_KHI", "Pha phải là AWAIT_UAT_KHI");
  assert.equal(state.waitingTargetSeat, 2);

  const myHandBefore = state.players[1].hand.length;

  // AI Thi Sách phản ứng
  const res = handleAIReaction(state, 2);
  assert.equal(res?.success, true, "AI phản ứng phải thành công");
  assert.equal(state.players[1].hand.length, myHandBefore + 1, "Thi Sách không còn đồng đội phải tự buff rút bài cho chính mình");

  const uatKhiAction = state.actionHistory.filter((a) => a.type === "UAT_KHI_DRAW").pop();
  assert.ok(uatKhiAction, "Phải có action UAT_KHI_DRAW");
  assert.equal(uatKhiAction.targetSeat, 2, "Mục tiêu Uất Khí phải là chính Thi Sách (Seat 2)");
}

console.log("[TEST PASS] Thi Sách Uất Khí AI test passed successfully!");
