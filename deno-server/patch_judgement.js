const fs = require('fs');
let content = fs.readFileSync('deno-server/gameEngine.js', 'utf8');

const newResolve = 
function resolveJudgementCard(state, judgementCard, targetSeat) {
  const target = state.players.find((player) => player.seat === targetSeat);
  if (!target || !judgementCard) return;
  const judgeCard = drawJudgementCard(state) || { suit: "Heart", rank: 10, name: "Bài Phán Xét", id: "JUDGECARD" };

  let isHit = false;
  let triggered = false;
  let actionType = "";
  let description = "";
  let nextRecipient = 0;

  if (judgementCard.subType === CARD_SUBTYPES.LIGHTNING) {
    isHit = judgeCard.suit === "Spade" && judgeCard.rank >= 2 && judgeCard.rank <= 9;
    actionType = isHit ? "LIGHTNING_HIT" : "LIGHTNING_PASSED";
    const recipient = !isHit ? findNextJudgementRecipient(state, targetSeat, CARD_SUBTYPES.LIGHTNING) : null;
    nextRecipient = recipient ? recipient.seat : 0;
    description = isHit
      ? \⚡⚡⚡ [Thần Sấm Báo Ứng] phán xét \ \: <b>\</b> chuẩn bị chịu 3 sát thương Lôi!\
      : (recipient ? \⚡ [Thần Sấm Báo Ứng] phán xét \ \ không trúng, chuẩn bị chuyển sang <b>\</b>.\ : \⚡ [Thần Sấm Báo Ứng] không trúng và không còn vùng phán xét hợp lệ, lá bài bị bỏ.\);
  } else if (judgementCard.subType === CARD_SUBTYPES.SUPPLY_SHORTAGE) {
    triggered = judgeCard.suit !== "Club";
    actionType = triggered ? "SUPPLY_SHORTAGE_TRIGGERED" : "SUPPLY_SHORTAGE_PASSED";
    description = triggered ? \🌾❌ <b>\</b> phán xét \ \, chuẩn bị bỏ qua Giai đoạn Rút bài.\ : \🌾✅ <b>\</b> phán xét ra Chuồn, hóa giải Cắt Đường Lương.\;
  } else if (judgementCard.subType === CARD_SUBTYPES.ACEDIA) {
    triggered = judgeCard.suit !== "Heart";
    actionType = triggered ? "ACEDIA_TRIGGERED" : "ACEDIA_PASSED";
    description = triggered ? \🕸️❌ <b>\</b> phán xét \ \, chuẩn bị bỏ qua Giai đoạn Ra bài.\ : \🕸️✅ <b>\</b> phán xét ra Cơ, thoát khỏi Sa Bẫy.\;
  }

  state.phase = "AWAIT_JUDGEMENT";
  state.waitingTimer = 3;
  state.timerStartAt = Date.now();
  state.pendingJudgement = {
    actionType,
    targetSeat,
    judgeCardId: judgeCard.id,
    judgementCardId: judgementCard.id,
    judgementCardType: judgementCard.subType,
    isHit,
    triggered,
    nextRecipient
  };

  recordAction(state, {
    type: actionType,
    targetSeat,
    cardId: judgeCard.id,
    description
  });
}

function applyPendingJudgement(state) {
  const pending = state.pendingJudgement;
  if (!pending) {
     return continueTurnStart(state);
  }
  const { actionType, targetSeat, judgementCardId, judgementCardType, isHit, triggered, nextRecipient } = pending;
  const target = state.players.find(p => p.seat === targetSeat);
  state.pendingJudgement = null;
  state.phase = "PLAY";
  state.waitingTimer = 0;
  
  if (!target) return continueTurnStart(state);

  const judgementCard = target.judgements?.find(c => c.id === judgementCardId);
  if (judgementCard) {
      target.judgements = target.judgements.filter(c => c.id !== judgementCardId);
  }
  
  // The actual scroll card needs to be moved
  const cardObj = judgementCard || { id: judgementCardId, subType: judgementCardType };

  if (judgementCardType === CARD_SUBTYPES.LIGHTNING) {
    if (isHit) {
      discardCard(state, cardObj);
      applyDamageToPlayer(state, targetSeat, 3, "Thần Sấm Báo Ứng");
      if (state.phase === "AWAIT_NEAR_DEATH") return;
    } else {
      if (nextRecipient > 0) {
        const recipient = state.players.find(p => p.seat === nextRecipient);
        if (recipient) {
           recipient.judgements = recipient.judgements || [];
           recipient.judgements.push(cardObj);
        } else {
           discardCard(state, cardObj);
        }
      } else {
        discardCard(state, cardObj);
      }
    }
  } else {
    discardCard(state, cardObj);
    if (judgementCardType === CARD_SUBTYPES.SUPPLY_SHORTAGE && triggered) {
      if (state.turnStart) state.turnStart.skipDraw = true;
    } else if (judgementCardType === CARD_SUBTYPES.ACEDIA && triggered) {
      if (state.turnStart) state.turnStart.skipPlay = true;
    }
  }

  return continueTurnStart(state);
}
;

if (content.includes("applyPendingJudgement")) {
  console.log("Already applied applyPendingJudgement");
} else {
  // Use generic replacement logic just replacing the whole function block
  const oldStr = content.substring(content.indexOf("function resolveJudgementCard"), content.indexOf("function continueTurnStart"));
  content = content.replace(oldStr, newResolve + "\n\n");

  const oldTick = xport function tickGameState(state) {
  if (!state || state.status === "FINISHED") return { changed: false, important: false };
  let changed = false;
  let important = false;
  const startingVersion = state.version || 0;

  if (!state.timerStartAt) {
      state.timerStartAt = Date.now();
      changed = true;
  }
  const elapsed = Math.floor((Date.now() - state.timerStartAt) / 1000);
  const newTimer = Math.max(0, 40 - elapsed);
  
  if (state.waitingTargetSeat > 0) {;
    
  const newTick = xport function tickGameState(state) {
  if (!state || state.status === "FINISHED") return { changed: false, important: false };
  let changed = false;
  let important = false;
  const startingVersion = state.version || 0;

  if (!state.timerStartAt) {
      state.timerStartAt = Date.now();
      changed = true;
  }
  
  let timeLimit = 40;
  if (state.phase === "AWAIT_JUDGEMENT") timeLimit = 3;

  const elapsed = Math.floor((Date.now() - state.timerStartAt) / 1000);
  const newTimer = Math.max(0, timeLimit - elapsed);
  
  if (state.phase === "AWAIT_JUDGEMENT") {
     if (state.waitingTimer !== newTimer) {
       state.waitingTimer = newTimer;
       changed = true;
     }
     if (elapsed >= timeLimit) {
       applyPendingJudgement(state);
       important = true;
       state.timerStartAt = Date.now();
       return { changed: true, important };
     }
     return { changed, important };
  }

  if (state.waitingTargetSeat > 0) {;
  
  content = content.replace(oldTick, newTick);

  // hydrate pendingJudgement
  const hydrateOld =   if (state.targetCardSelection && typeof state.targetCardSelection === "object") {;
  const hydrateNew =   if (state.pendingJudgement && typeof state.pendingJudgement === "object") {
    state.pendingJudgement = { ...state.pendingJudgement };
  } else {
    state.pendingJudgement = null;
  }
  if (state.targetCardSelection && typeof state.targetCardSelection === "object") {;
  content = content.replace(hydrateOld, hydrateNew);
  
  const sanitizeOld =       targetCardSelection: sanitizeTargetCardSelection(state.targetCardSelection, requestingSeat),;
  const sanitizeNew =       pendingJudgement: state.pendingJudgement || null,
      targetCardSelection: sanitizeTargetCardSelection(state.targetCardSelection, requestingSeat),;
  content = content.replace(sanitizeOld, sanitizeNew);

  fs.writeFileSync('deno-server/gameEngine.js', content, 'utf8');
  console.log("Success");
}
