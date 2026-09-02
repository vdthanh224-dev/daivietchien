const fs = require('fs');
let text = fs.readFileSync('deno-server/gameEngine.js', 'utf8');

const sIdx = text.indexOf('function resolveJudgementCard');
const eIdx = text.indexOf('function continueTurnStart');

const newRes = 'function resolveJudgementCard(state, judgementCard, targetSeat) {\n' +
'  const target = state.players.find((player) => player.seat === targetSeat);\n' +
'  if (!target || !judgementCard) return;\n' +
'  const judgeCard = drawJudgementCard(state) || { suit: "Heart", rank: 10, name: "Bài Phán Xét", id: "JUDGECARD" };\n' +
'\n' +
'  let isHit = false;\n' +
'  let triggered = false;\n' +
'  let actionType = "";\n' +
'  let description = "";\n' +
'  let nextRecipient = 0;\n' +
'\n' +
'  if (judgementCard.subType === CARD_SUBTYPES.LIGHTNING) {\n' +
'    isHit = judgeCard.suit === "Spade" && judgeCard.rank >= 2 && judgeCard.rank <= 9;\n' +
'    actionType = isHit ? "LIGHTNING_HIT" : "LIGHTNING_PASSED";\n' +
'    const recipient = !isHit ? findNextJudgementRecipient(state, targetSeat, CARD_SUBTYPES.LIGHTNING) : null;\n' +
'    nextRecipient = recipient ? recipient.seat : 0;\n' +
'    description = isHit\n' +
'      ? "⚡⚡⚡ [Thần Sấm Báo Ứng] phán xét " + judgeCard.suit + " " + judgeCard.rank + ": <b>" + target.generalName + "</b> chuẩn bị chịu 3 sát thương Lôi!"\n' +
'      : (recipient ? "⚡ [Thần Sấm Báo Ứng] phán xét " + judgeCard.suit + " " + judgeCard.rank + " không trúng, chuẩn bị chuyển sang <b>" + recipient.generalName + "</b>." : "⚡ [Thần Sấm Báo Ứng] không trúng và không còn vùng phán xét hợp lệ, lá bài bị bỏ.");\n' +
'  } else if (judgementCard.subType === CARD_SUBTYPES.SUPPLY_SHORTAGE) {\n' +
'    triggered = judgeCard.suit !== "Club";\n' +
'    actionType = triggered ? "SUPPLY_SHORTAGE_TRIGGERED" : "SUPPLY_SHORTAGE_PASSED";\n' +
'    description = triggered ? "🌾❌ <b>" + target.generalName + "</b> phán xét " + judgeCard.suit + " " + judgeCard.rank + ", chuẩn bị bỏ qua Giai đoạn Rút bài." : "🌾✅ <b>" + target.generalName + "</b> phán xét ra Chuồn, hóa giải Cắt Đường Lương.";\n' +
'  } else if (judgementCard.subType === CARD_SUBTYPES.ACEDIA) {\n' +
'    triggered = judgeCard.suit !== "Heart";\n' +
'    actionType = triggered ? "ACEDIA_TRIGGERED" : "ACEDIA_PASSED";\n' +
'    description = triggered ? "🕸️❌ <b>" + target.generalName + "</b> phán xét " + judgeCard.suit + " " + judgeCard.rank + ", chuẩn bị bỏ qua Giai đoạn Ra bài." : "🕸️✅ <b>" + target.generalName + "</b> phán xét ra Cơ, thoát khỏi Sa Bẫy.";\n' +
'  }\n' +
'\n' +
'  state.phase = "AWAIT_JUDGEMENT";\n' +
'  state.waitingTimer = 3;\n' +
'  state.timerStartAt = Date.now();\n' +
'  state.pendingJudgement = {\n' +
'    actionType,\n' +
'    targetSeat,\n' +
'    judgeCardId: judgeCard.id,\n' +
'    judgementCardId: judgementCard.id,\n' +
'    judgementCardType: judgementCard.subType,\n' +
'    isHit,\n' +
'    triggered,\n' +
'    nextRecipient\n' +
'  };\n' +
'\n' +
'  recordAction(state, {\n' +
'    type: actionType,\n' +
'    targetSeat,\n' +
'    cardId: judgeCard.id,\n' +
'    description\n' +
'  });\n' +
'}\n' +
'\n' +
'function applyPendingJudgement(state) {\n' +
'  const pending = state.pendingJudgement;\n' +
'  if (!pending) {\n' +
'     return continueTurnStart(state);\n' +
'  }\n' +
'  const { actionType, targetSeat, judgementCardId, judgementCardType, isHit, triggered, nextRecipient } = pending;\n' +
'  const target = state.players.find(p => p.seat === targetSeat);\n' +
'  state.pendingJudgement = null;\n' +
'  state.phase = "PLAY";\n' +
'  state.waitingTimer = 0;\n' +
'  \n' +
'  if (!target) return continueTurnStart(state);\n' +
'\n' +
'  const judgementCard = target.judgements?.find(c => c.id === judgementCardId);\n' +
'  if (judgementCard) {\n' +
'      target.judgements = target.judgements.filter(c => c.id !== judgementCardId);\n' +
'  }\n' +
'  \n' +
'  const cardObj = judgementCard || { id: judgementCardId, subType: judgementCardType };\n' +
'\n' +
'  if (judgementCardType === CARD_SUBTYPES.LIGHTNING) {\n' +
'    if (isHit) {\n' +
'      discardCard(state, cardObj);\n' +
'      applyDamageToPlayer(state, targetSeat, 3, "Thần Sấm Báo Ứng");\n' +
'      if (state.phase === "AWAIT_NEAR_DEATH") return;\n' +
'    } else {\n' +
'      if (nextRecipient > 0) {\n' +
'        const recipient = state.players.find(p => p.seat === nextRecipient);\n' +
'        if (recipient) {\n' +
'           recipient.judgements = recipient.judgements || [];\n' +
'           recipient.judgements.push(cardObj);\n' +
'        } else {\n' +
'           discardCard(state, cardObj);\n' +
'        }\n' +
'      } else {\n' +
'        discardCard(state, cardObj);\n' +
'      }\n' +
'    }\n' +
'  } else {\n' +
'    discardCard(state, cardObj);\n' +
'    if (judgementCardType === CARD_SUBTYPES.SUPPLY_SHORTAGE && triggered) {\n' +
'      if (state.turnStart) state.turnStart.skipDraw = true;\n' +
'    } else if (judgementCardType === CARD_SUBTYPES.ACEDIA && triggered) {\n' +
'      if (state.turnStart) state.turnStart.skipPlay = true;\n' +
'    }\n' +
'  }\n' +
'\n' +
'  return continueTurnStart(state);\n' +
'}\n\n';

text = text.substring(0, sIdx) + newRes + text.substring(eIdx);
fs.writeFileSync('deno-server/gameEngine.js', text);
