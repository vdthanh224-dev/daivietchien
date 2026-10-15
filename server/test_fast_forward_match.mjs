import assert from "node:assert/strict";
import { initGame, fastForwardMatchForDeadPlayer } from "./functions/game-engine/src/gameEngine.js";

console.log("=== Testing FAST_FORWARD_MATCH ===");

// 1. Requester is alive
const state = initGame("2v2", [
  { seat: 1, userId: "u1", userName: "Player 1", heroId: "HERO_1", isAI: false },
  { seat: 2, userId: "u2", userName: "Player 2", heroId: "HERO_2", isAI: false },
  { seat: 3, userId: "bot_3", userName: "Bot 3", heroId: "HERO_3", isAI: true },
  { seat: 4, userId: "bot_4", userName: "Bot 4", heroId: "HERO_4", isAI: true },
]);

let res = fastForwardMatchForDeadPlayer(state, 1);
assert.equal(res.error, "Chỉ người đã tử trận mới được tua nhanh", "Alive player cannot fast-forward");
console.log("✅ TEST 1 Passed: Alive player cannot request fast forward");

// 2. Requester is dead, but Player 2 (human) is still alive
state.players[0].hp = 0;
state.players[0].isAlive = false;

res = fastForwardMatchForDeadPlayer(state, 1);
assert.equal(res.error, "Chỉ tua nhanh khi những người còn sống đều là AI", "Cannot fast-forward if human player is still alive");
console.log("✅ TEST 2 Passed: Cannot fast forward if another human player is still alive");

// 3. Player 2 also dies, now only Bot 3 and Bot 4 are alive
state.players[1].hp = 0;
state.players[1].isAlive = false;

res = fastForwardMatchForDeadPlayer(state, 1);
assert.equal(res.success, true, "Fast forward succeeds when all living are AI");
assert.equal(res.fastForwarded, true);
assert.equal(state.fastForwardAiRequested, true);
console.log("✅ TEST 3 Passed: Fast forward succeeds when all living players are AI, final status:", state.status);

// 4. Test when living player is taken over by AI (isAiTakeover = true)
const state2 = initGame("2v2", [
  { seat: 1, userId: "u1", userName: "Player 1", heroId: "HERO_1", isAI: false },
  { seat: 2, userId: "u2", userName: "Player 2", heroId: "HERO_2", isAI: false },
  { seat: 3, userId: "bot_3", userName: "Bot 3", heroId: "HERO_3", isAI: true },
  { seat: 4, userId: "bot_4", userName: "Bot 4", heroId: "HERO_4", isAI: true },
]);
state2.players[0].hp = 0;
state2.players[0].isAlive = false;
state2.players[1].isAiTakeover = true; // Player 2 disconnected/taken over

let res2 = fastForwardMatchForDeadPlayer(state2, 1);
assert.equal(res2.success, true, "Fast forward succeeds when living human is AI-takeover");
console.log("✅ TEST 4 Passed: Fast forward succeeds when living player is AI takeover");

console.log("🎉 ALL FAST FORWARD TESTS PASSED!");
