import {
  initGame,
  handlePlayCard,
  handleRespondAction,
  handleEndTurn,
  handleDiscardCards,
  handleAIStep,
  handleAIReaction
} from './functions/game-engine/src/gameEngine.js';

const roomId = 'debug_game_1';
const players = [
  { seat: 1, userId: 'u1', generalName: 'Trần Hưng Đạo', maxHp: 4, hp: 4, isAlly: true, isAI: true, handCount: 4 },
  { seat: 2, userId: 'u2', generalName: 'Ô Mã Nhi', maxHp: 4, hp: 4, isAlly: false, isAI: true, handCount: 4 },
  { seat: 3, userId: 'u3', generalName: 'Lý Thường Kiệt', maxHp: 4, hp: 4, isAlly: true, isAI: true, handCount: 4 },
  { seat: 4, userId: 'u4', generalName: 'Toa Đô', maxHp: 4, hp: 4, isAlly: false, isAI: true, handCount: 4 }
];

let state = initGame(roomId, players);
for (let i = 1; i <= 100; i++) {
  if (state.status === "FINISHED") {
    console.log("GAME FINISHED at step", i);
    break;
  }
  console.log(`Step ${i}: TurnSeat: ${state.turnSeat}, Phase: ${state.phase}, Waiting: ${state.waitingTargetSeat}, LastAction: ${state.lastAction ? state.lastAction.type : 'none'}`);
  if (state.phase !== 'PLAY' && state.phase !== 'DISCARD') {
    const waitingSeat = state.waitingTargetSeat;
    if (state.phase === 'AWAIT_NULLIFY') {
      const res = handleRespondAction(state, waitingSeat, false, null);
      console.log('  -> Responded nullify pass:', res);
    } else if (state.phase === 'AWAIT_HARVEST') {
      const poolCard = (state.harvestPool && state.harvestPool.length > 0) ? state.harvestPool[0].id : null;
      const res = handleRespondAction(state, waitingSeat, true, poolCard);
      console.log('  -> Responded harvest pick:', res);
    } else {
      const res = handleAIReaction(state, waitingSeat);
      console.log('  -> Responded AI reaction:', res);
    }
  } else if (state.phase === 'DISCARD') {
    const p = state.players.find(x => x.seat === state.waitingTargetSeat);
    const excess = p.hand.length - p.hp;
    if (excess > 0) {
      const toDiscard = p.hand.slice(0, excess).map(c => c.id);
      const res = handleDiscardCards(state, state.waitingTargetSeat, toDiscard);
      console.log('  -> Discarded:', res);
    } else {
      const res = handleEndTurn(state, state.waitingTargetSeat);
      console.log('  -> End turn:', res);
    }
  } else {
    const currentSeat = state.turnSeat;
    const res = handleAIStep(state, currentSeat);
    console.log('  -> AI Step result:', res ? res.lastAction || res.type || res.error || 'ok' : 'none');
  }
}
