import assert from 'node:assert/strict';
import { CARD_CATEGORIES, CARD_SUBTYPES } from './functions/game-engine/src/deck.js';
import {
  initGame,
  handlePlayCard,
  handleRespondAction,
  handleEndTurn,
  tickGameState,
  sanitizeGameStateForClient,
  recordAction
} from './functions/game-engine/src/gameEngine.js';

console.log("=== Testing Bot AI Takeover & Disconnect / Reconnect ===");

// 1. Khởi tạo trận đấu 4 người chơi (Seat 1, 2, 3, 4)
const state = initGame("ROOM_DISCONNECT_TEST", [
  { seat: 1, team: 1, heroId: "HERO_1", generalName: "Cao Lỗ" },
  { seat: 2, team: 2, heroId: "HERO_2", generalName: "Đào Hãn" },
  { seat: 3, team: 1, heroId: "HERO_3", generalName: "Thi Sách" },
  { seat: 4, team: 2, heroId: "HERO_4", generalName: "Lê Chân" }
]);

for (const p of state.players) {
  p.hand = [];
  assert.equal(p.isAI, false);
  assert.equal(p.isDisconnected, undefined);
  assert.equal(p.isAiTakeover, undefined);
}

const p1 = state.players[0];
const p2 = state.players[1];

// 2. Giả lập Seat 2 ngắt kết nối
console.log("--> Test: Seat 2 disconnects");
p2.isDisconnected = true;
p2.isAiTakeover = true;
recordAction(state, {
  type: "PLAYER_DISCONNECTED",
  casterSeat: 2,
  description: `🔌 <b>${p2.generalName}</b> (Ghế 2) đã ngắt kết nối! Bot AI tự động đánh thay.`
});

assert.equal(p2.isDisconnected, true);
assert.equal(p2.isAiTakeover, true);
assert.equal(state.lastAction?.type, "PLAYER_DISCONNECTED");

// Kiểm tra sanitizeGameStateForClient xuất cờ disconnect cho client
const sanitizedP1View = sanitizeGameStateForClient(state, 1);
const sanitizedP2 = sanitizedP1View.players.find(p => p.seat === 2);
assert.equal(sanitizedP2.isDisconnected, true);
assert.equal(sanitizedP2.isAiTakeover, true);
console.log("✅ Sanitize state contains isDisconnected & isAiTakeover");

// 3. Test Bot AI phản ứng thay khi bị Trảm trong lúc mất mạng
console.log("--> Test: Bot AI takes over reaction when targeted by Slash");
p1.hand = [{ id: "S1", name: "Trảm", suit: "Spade", rank: 8, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.ATTACK_NORMAL }];
p2.hand = [{ id: "D1", name: "Đỡ", suit: "Heart", rank: 2, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.DODGE }];
p2.hp = 4;
state.phase = "PLAY";
state.turnSeat = 1;

// P1 chém P2
const playRes = handlePlayCard(state, 1, "S1", 2);
assert.equal(playRes.success, true);
assert.equal(state.phase, "AWAIT_SLASH_DEFENSE");
assert.equal(state.waitingTargetSeat, 2);

// Giả lập thời gian trôi qua hơn thời gian suy nghĩ 2.5s với connectedSeats chỉ gồm [1, 3, 4]
state.timerStartAt = Date.now() - 2600;
const tickRes = tickGameState(state, [1, 3, 4]);
assert.equal(tickRes.changed, true);
// Bot AI của P2 phải tự động phản ứng (dùng Đỡ để tránh mất máu)
assert.equal(p2.hp, 4); // Không mất máu vì AI đã Đỡ
assert.equal(p2.hand.length, 0); // Đã dùng lá Đỡ
console.log("✅ Bot AI successfully reacted for disconnected player (Dodge used)");

// 4. Test Bot AI đánh bài thay khi đến lượt của người mất mạng
console.log("--> Test: Bot AI takes over PLAY phase when disconnected player turn comes");
state.phase = "PLAY";
state.turnSeat = 2;
p2.hand = [{ id: "PEACH_1", name: "Bánh Chưng", suit: "Heart", rank: 5, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.PEACH }];
p2.hp = 2; // Đang bị thương
state.timerStartAt = Date.now() - 2600;

// Tick chạy với connectedSeats = [1, 3, 4] (Seat 2 vắng mặt)
const turnTickRes = tickGameState(state, [1, 3, 4]);
assert.equal(turnTickRes.changed, true);
// AI tự động ăn Bánh Chưng để hồi máu
assert.equal(p2.hp, 3);
console.log("✅ Bot AI successfully took action in PLAY phase (Healed with Peach)");

// 5. Test Người chơi kết nối lại (Reconnect)
console.log("--> Test: Seat 2 reconnects");
// Giả lập xử lý khi socket Seat 2 kết nối lại
const wasDisconnected = Boolean(p2.isDisconnected || p2.isAiTakeover);
assert.equal(wasDisconnected, true);
p2.isDisconnected = false;
p2.isAiTakeover = false;
p2.isAI = false;
state.timerStartAt = Date.now(); // Làm mới đồng hồ khi người chơi vào lại
recordAction(state, {
  type: "PLAYER_RECONNECTED",
  casterSeat: 2,
  description: `⚡ <b>${p2.generalName}</b> (Ghế 2) đã kết nối lại phòng đấu!`
});

assert.equal(p2.isDisconnected, false);
assert.equal(p2.isAiTakeover, false);
assert.equal(p2.isAI, false);
assert.equal(state.lastAction?.type, "PLAYER_RECONNECTED");

const reconnectedSanitize = sanitizeGameStateForClient(state, 2);
const reconnectedP2 = reconnectedSanitize.players.find(p => p.seat === 2);
assert.equal(reconnectedP2.isDisconnected, false);
assert.equal(reconnectedP2.isAiTakeover, false);
assert.equal(reconnectedP2.isAI, false);
console.log("✅ Player successfully reconnected and AI relinquishes control");

// 6. Test Bot AI KHÔNG ĐƯỢC tự đánh khi người chơi đã kết nối lại
console.log("--> Test: Bot AI must NOT take action when reconnected human is thinking");
state.phase = "PLAY";
state.turnSeat = 2;
p2.hand = [{ id: "SLASH_2", name: "Trảm", suit: "Spade", rank: 7, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.ATTACK_NORMAL }];
// Giả lập 3 giây trôi qua (< 40 giây)
state.timerStartAt = Date.now() - 3000;
const reconnectedTick = tickGameState(state, [1, 2, 3, 4]);
// AI không được ra bài hay kết thúc lượt vì người chơi thật đang kết nối!
assert.equal(p2.hand.length, 1);
assert.equal(state.phase, "PLAY");
assert.equal(state.turnSeat, 2);
console.log("✅ AI correctly did NOT auto-play for reconnected human player");

console.log("🎉 All Disconnect & Reconnect / AI Takeover tests PASSED!");
