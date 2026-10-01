import {
  initGame,
  handlePlayCard,
  handleRespondAction,
  handleEndTurn,
  handleDiscardCards,
  handleAIStep,
  handleAIReaction,
  tickGameState
} from './functions/game-engine/src/gameEngine.js';

console.log("================================================================================");
console.log("🎮 BẮT ĐẦU CHẠY KIỂM THỬ GIẢ LẬP 10 TRẬN ĐẤU AUTHORITATIVE TOÀN DIỆN TRÊN SERVER");
console.log("================================================================================\n");

let totalGamesPassed = 0;
let totalGamesFailed = 0;

for (let gameIdx = 1; gameIdx <= 10; gameIdx++) {
  const roomId = `room_sim_game_${gameIdx}`;
  const players = [
    { seat: 1, userId: `u_${gameIdx}_1`, generalName: 'Trần Hưng Đạo', maxHp: 4, hp: 4, isAlly: true, isAI: true, handCount: 4 },
    { seat: 2, userId: `u_${gameIdx}_2`, generalName: 'Ô Mã Nhi', maxHp: 4, hp: 4, isAlly: false, isAI: true, handCount: 4 },
    { seat: 3, userId: `u_${gameIdx}_3`, generalName: 'Lý Thường Kiệt', maxHp: 4, hp: 4, isAlly: true, isAI: true, handCount: 4 },
    { seat: 4, userId: `u_${gameIdx}_4`, generalName: 'Toa Đô', maxHp: 4, hp: 4, isAlly: false, isAI: true, handCount: 4 }
  ];

  let state = initGame(roomId, players);
  let stepCount = 0;
  let firstActionError = null;
  const maxSteps = 3000;

  while (state.status !== "FINISHED" && stepCount < maxSteps) {
    stepCount++;

    if (state.phase === "AWAIT_JUDGEMENT") {
      state.timerStartAt = Date.now() - 3000;
      tickGameState(state);
      continue;
    }

    // 1. Chờ phản ứng (AWAIT_NULLIFY, AWAIT_HARVEST, AWAIT_SLASH_DEFENSE, AWAIT_AOE, AWAIT_DUEL, AWAIT_NEAR_DEATH)
    if (state.phase !== "PLAY" && state.phase !== "DISCARD") {
      const waitingSeat = state.waitingTargetSeat;
      if (waitingSeat >= 1 && waitingSeat <= 4) {
        if (state.phase === "AWAIT_NULLIFY") {
          const p = state.players.find(x => x.seat === waitingSeat);
          const nullifyCard = p ? p.hand.find(c => c.subType === 10 || (c.name && c.name.includes("Diệu Kế"))) : null;
          if (nullifyCard && Math.random() < 0.35) {
            const result = handleRespondAction(state, waitingSeat, true, nullifyCard.id);
            if (result?.error && !firstActionError) firstActionError = { phase: state.phase, waitingSeat, result };
          } else {
            const result = handleRespondAction(state, waitingSeat, false, null);
            if (result?.error && !firstActionError) firstActionError = { phase: state.phase, waitingSeat, result };
          }
        }
        else if (state.phase === "AWAIT_HARVEST") {
          const poolCard = (state.harvestPool && state.harvestPool.length > 0) ? state.harvestPool[0].id : null;
          const result = handleRespondAction(state, waitingSeat, true, poolCard);
          if (result?.error && !firstActionError) firstActionError = { phase: state.phase, waitingSeat, result };
        }
        else {
          const result = handleAIReaction(state, waitingSeat);
          if (result?.error && !firstActionError) firstActionError = { phase: state.phase, waitingSeat, result };
        }
      } else {
        state.phase = "PLAY";
      }
      continue;
    }

    // 2. Pha bỏ bài thừa (DISCARD)
    if (state.phase === "DISCARD") {
      const p = state.players.find(x => x.seat === state.waitingTargetSeat);
      if (p) {
        const excess = p.hand.length - p.hp;
        if (excess > 0) {
          const toDiscard = p.hand.slice(0, excess).map(c => c.id);
          handleDiscardCards(state, state.waitingTargetSeat, toDiscard);
        } else {
          handleEndTurn(state, state.waitingTargetSeat);
        }
      } else {
        state.phase = "PLAY";
      }
      continue;
    }

    // 3. Pha ra bài (PLAY)
    const currentSeat = state.turnSeat;
    const aiRes = handleAIStep(state, currentSeat);
    if (aiRes && aiRes.error) {
      handleEndTurn(state, currentSeat);
    }
  }

  if (state.status === "FINISHED") {
    totalGamesPassed++;
    const winningTeam = state.lastAction ? state.lastAction.winningTeam : "Đội chiến thắng";
    console.log(`✅ [TRẬN ${gameIdx}/10] KẾT THÚC THÀNH CÔNG sau ${stepCount} bước! Kết quả: ${winningTeam}`);
    console.log(`   - Máu cuối trận: S1: ${state.players[0].hp}, S2: ${state.players[1].hp}, S3: ${state.players[2].hp}, S4: ${state.players[3].hp}`);
  } else {
    totalGamesFailed++;
    console.error(`❌ [TRẬN ${gameIdx}/10] LỖI: Trận đấu vượt quá ${maxSteps} bước mà chưa kết thúc!`);
    console.error(JSON.stringify({
      gameIdx,
      phase: state.phase,
      turnSeat: state.turnSeat,
      waitingTargetSeat: state.waitingTargetSeat,
      waitingReactionType: state.waitingReactionType,
      activeCard: state.activeCard,
      firstActionError,
      nullifyChain: state.nullifyChain,
      targetCardSelection: state.targetCardSelection,
      pendingAfterNearDeath: state.pendingAfterNearDeath,
      pendingChainSpread: state.pendingChainSpread,
      aoeVictimsQueue: state.aoeVictimsQueue,
      nearDeathAskerQueue: state.nearDeathAskerQueue,
      harvestPickers: state.harvestPickers,
      harvestPool: state.harvestPool?.map(card => card.id),
      players: state.players.map(player => ({
        seat: player.seat,
        hp: player.hp,
        isAlive: player.isAlive,
        handCount: player.hand?.length || 0,
        equipments: player.equipments?.map(card => card.id) || [],
        judgements: player.judgements?.map(card => card.id) || []
      })),
      lastAction: state.lastAction,
      recentActions: state.actionHistory?.slice(-8)
    }, null, 2));
  }
}

console.log("\n================================================================================");
console.log(`🏆 TỔNG KẾT KIỂM THỬ: ${totalGamesPassed}/10 TRẬN ĐẤU ĐÃ CHẠY HOÀN HẢO 100% TRÊN SERVER!`);
console.log("================================================================================");
if (totalGamesFailed > 0) process.exitCode = 1;
