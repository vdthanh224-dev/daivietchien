const fs = require('fs');
let content = fs.readFileSync('deno-server/gameEngine.js', 'utf8');

const strStart = content.indexOf('function resolveJudgementCard');
const strEnd = content.indexOf('function continueTurnStart');

const newResolve = unction resolveJudgementCard(state, judgementCard, targetSeat) {
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
      ? "⚡⚡⚡ [Thần Sấm Báo Ứng] phán xét " + judgeCard.suit + " " + judgeCard.rank + ": <b>" + target.generalName + "</b> chuẩn bị chịu 3 sát thương Lôi!"
      : (recipient ? "⚡ [Thần Sấm Báo Ứng] phán xét " + judgeCard.suit + " " + judgeCard.rank + " không trúng, chuẩn bị chuyển sang <b>" + recipient.generalName + "</b>." : "⚡ [Thần Sấm Báo Ứng] không trúng và không còn vùng phán xét hợp lệ, lá bài bị bỏ.");
  } else if (judgementCard.subType === CARD_SUBTYPES.SUPPLY_SHORTAGE) {
    triggered = judgeCard.suit !== "Club";
    actionType = triggered ? "SUPPLY_SHORTAGE_TRIGGERED" : "SUPPLY_SHORTAGE_PASSED";
    description = triggered ? "🌾❌ <b>" + target.generalName + "</b> phán xét " + judgeCard.suit + " " + judgeCard.rank + ", chuẩn bị bỏ qua Giai đoạn Rút bài." : "🌾✅ <b>" + target.generalName + "</b> phán xét ra Chuồn, hóa giải Cắt Đường Lương.";
  } else if (judgementCard.subType === CARD_SUBTYPES.ACEDIA) {
    triggered = judgeCard.suit !== "Heart";
    actionType = triggered ? "ACEDIA_TRIGGERED" : "ACEDIA_PASSED";
    description = triggered ? "🕸️❌ <b>" + target.generalName + "</b> phán xét " + judgeCard.suit + " " + judgeCard.rank + ", chuẩn bị bỏ qua Giai đoạn Ra bài." : "🕸️✅ <b>" + target.generalName + "</b> phán xét ra Cơ, thoát khỏi Sa Bẫy.";
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

content = content.substring(0, strStart) + newResolve + content.substring(strEnd);
fs.writeFileSync('deno-server/gameEngine.js', content);
