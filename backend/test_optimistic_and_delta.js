import { initGame, handlePlayCard, handleRespondAction, handleEndTurn, checkVersion, sanitizeGameStateForClient } from './functions/game-engine/src/gameEngine.js';

console.log('=== TEST 1: OPTIMISTIC LOCKING ===');
const players = [
  { userId: 'u1', generalName: 'Lê Lợi', maxHp: 4 },
  { userId: 'u2', generalName: 'Trần Hưng Đạo', maxHp: 4 },
  { userId: 'u3', generalName: 'Nguyễn Huệ', maxHp: 4 },
  { userId: 'u4', generalName: 'Quang Trung', maxHp: 4 }
];

const state = initGame('room_opt_1', players);
console.log('Initial state version:', state.version);

// 1. Client A sends valid action with expectedVersion = 1
const vCheck1 = checkVersion(state, 1);
console.log('Client A checkVersion (exp=1):', vCheck1 === null ? 'VALID ✅' : 'FAILED ❌');

// Client A plays a card, incrementing version to 2
const card1 = state.players[0].hand[0];
handlePlayCard(state, 1, card1.id, 2);
console.log('State version after Card Play:', state.version);

// 2. Client B sends stale action with expectedVersion = 1 (Old version)
const vCheck2 = checkVersion(state, 1);
console.log('Client B checkVersion (stale exp=1):', vCheck2 !== null && vCheck2.conflict ? 'REJECTED CONFLICT AS EXPECTED ✅' : 'FAILED ❌');
console.log('Conflict details:', vCheck2);

// 3. Client B syncs and sends with expectedVersion = 2 (New version)
const vCheck3 = checkVersion(state, 2);
console.log('Client B checkVersion (updated exp=2):', vCheck3 === null ? 'VALID ✅' : 'FAILED ❌');

console.log('\n=== TEST 2: DELTA UPDATE GENERATION ===');
console.log('Delta generated in lastAction:');
console.log(JSON.stringify(state.lastDelta, null, 2));

if (state.lastDelta && state.lastDelta.version === 2 && state.lastDelta.playerDeltas.length === 4) {
  console.log('✅ DELTA UPDATE STRUCTURE IS 100% VALID!');
} else {
  console.log('❌ DELTA UPDATE FAILED');
}
