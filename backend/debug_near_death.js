import { initGame, handlePlayCard, handleRespondAction, handleAIStep } from './functions/game-engine/src/gameEngine.js';
import { CARD_SUBTYPES } from './functions/game-engine/src/deck.js';

const state = initGame('t', [
  {userId:'u1',generalName:'P1',maxHp:4},
  {userId:'u2',generalName:'P2',maxHp:4},
  {userId:'u3',generalName:'P3',maxHp:4},
  {userId:'ai',generalName:'P4',maxHp:4,isAI:true}
]);
const [p1,p2,p3,p4] = state.players;
// Giả lập tình huống: G4 lượt, G1 và G2 đã chết, G3 còn 1 máu
state.turnSeat = 4;
p1.hp = 0; p2.hp = 0; p3.hp = 1;
p4.hand = [{id:'s',name:'Trảm',suit:'C',rank:8,category:0,subType:CARD_SUBTYPES.ATTACK_NORMAL}];

console.log("AI đánh G3:");
handleAIStep(state, 4);
console.log("phase=", state.phase, "waitSeat=", state.waitingTargetSeat);

if (state.phase === "AWAIT_SLASH_DEFENSE") {
  console.log("G3 không Đỡ:");
  handleRespondAction(state, 3, false, null);
  console.log("phase=", state.phase, "waitSeat=", state.waitingTargetSeat, "p3hp=", p3.hp);
}

let n = 0;
while (state.phase === "AWAIT_NEAR_DEATH" && n < 8) {
  n++;
  console.log(`Hấp Hối bước ${n}: hỏi G${state.waitingTargetSeat}, queue=[${state.nearDeathAskerQueue}], victim=G${state.nearDeathVictimSeat}`);
  const res = handleRespondAction(state, state.waitingTargetSeat, false, null);
  console.log(`  result:`, res?.error || 'ok', `| phase=`, state.phase, `waitSeat=`, state.waitingTargetSeat);
}
console.log("Kết thúc: phase=", state.phase, "status=", state.status, "p3hp=", p3.hp);
