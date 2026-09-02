const fs = require('fs');
let code = fs.readFileSync('deno-server/gameEngine.js', 'utf8');

const t1 = `  if (state.phase === "AWAIT_NEAR_DEATH" && state.waitingTargetSeat === aiSeat) {
    const isSelf = (aiSeat === state.nearDeathVictimSeat);
    const peach = ai.hand.find(c => isPeach(c));
    const wine = isSelf ? ai.hand.find(c => isWine(c)) : null;
    const saveCard = peach || wine;

    if (saveCard) {
      return handleRespondAction(state, aiSeat, true, saveCard.id);
    }
    return handleRespondAction(state, aiSeat, false, null);
  }`;

const replacement = `  if (state.phase === "AWAIT_NEAR_DEATH" && state.waitingTargetSeat === aiSeat) {
    const isSelf = (aiSeat === state.nearDeathVictimSeat);
    const peach = ai.hand.find(c => isPeach(c));
    const wine = isSelf ? ai.hand.find(c => isWine(c)) : null;
    const saveCard = peach || wine;

    if (saveCard) {
      return handleRespondAction(state, aiSeat, true, saveCard.id);
    }
    return handleRespondAction(state, aiSeat, false, null);
  }

  if (state.phase === "AWAIT_NULLIFY" && state.waitingTargetSeat === aiSeat) {
    const chain = state.nullifyChain;
    const flawless = ai.hand.find(c => c.subType === 3 || (c.name && c.name.includes("Diệu Kế")));
    if (flawless && chain) {
      const caster = state.players.find(x => x.seat === chain.casterSeat);
      const isCasterAlly = caster && ((aiSeat === 1 || aiSeat === 3) === (caster.seat === 1 || caster.seat === 3));
      const shouldNullify = (!chain.isCanceled && !isCasterAlly) || (chain.isCanceled && isCasterAlly);
      if (shouldNullify) {
        return handleRespondAction(state, aiSeat, true, flawless.id);
      }
    }
    return handleRespondAction(state, aiSeat, false, null);
  }`;

let nCode = code.replace(/\r\n/g, '\n');
let nT1 = t1.replace(/\r\n/g, '\n');

if (nCode.includes(nT1)) {
    nCode = nCode.replace(nT1, replacement);
    fs.writeFileSync('deno-server/gameEngine.js', nCode, 'utf8');
    console.log('SUCCESS: AI NULLIFY FIX');
} else {
    console.log('FAILED TO FIND AI NULLIFY STRING');
}
