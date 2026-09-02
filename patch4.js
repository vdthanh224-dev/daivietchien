const fs = require('fs');
let code = fs.readFileSync('deno-server/gameEngine.js', 'utf8');

const t1 = `      if (state.harvestPool.length === 0 || state.harvestPickers.length === 0) {
        state.harvestPool = [];
        state.harvestPickers = [];
        resetWaitingState(state);
        recordAction(state, {
          type: "HARVEST_EMPTY",
          casterSeat,
          cardId: card.id,
          cardName: card.name,
          description: \`🍚 \${formatCardText(card)} không còn lá bài để chia.\`
        });
        return { success: true, state };
      }`;
const t2 = `      state.phase = "AWAIT_HARVEST";
      state.waitingTargetSeat = state.harvestPickers[0];
      state.waitingTimer = 40;
      state.timerStartAt = Date.now();
      state.activeCard = { cardId: card.id, cardName: card.name, casterSeat };

      const firstPicker = state.players.find(x => x.seat === state.harvestPickers[0]);
      recordAction(state, {
        type: "HARVEST_START",
        casterSeat,
        cardId: card.id,
        cardName: card.name,
        harvestPool: pool,
        description: \`🌾 <b>\${caster ? caster.generalName : 'Người chơi'}</b> \${formatCardText(card)} lật \${pool.length} lá bài công khai! Đang tới lượt <b>\${firstPicker ? firstPicker.generalName : 'Ghế 1'}</b> chọn bài (40s)...\`
      });
      return { success: true, state };`;

const replacement = `      state.activeCard = { cardId: card.id, cardName: card.name, casterSeat };
      recordAction(state, {
        type: "HARVEST_START",
        casterSeat,
        cardId: card.id,
        cardName: card.name,
        harvestPool: pool,
        description: \`🌾 <b>\${caster ? caster.generalName : 'Người chơi'}</b> \${formatCardText(card)} lật \${pool.length} lá bài công khai!\`
      });

      if (state.harvestPool.length === 0 || state.harvestPickers.length === 0) {
        state.harvestPool = [];
        state.harvestPickers = [];
        resetWaitingState(state);
        return { success: true, state };
      }

      beginNextHarvestPicker(state);
      refreshLastDelta(state);
      return { success: true, state };`;

let nCode = code.replace(/\r\n/g, '\n');
let nT1 = t1.replace(/\r\n/g, '\n');
let nT2 = t2.replace(/\r\n/g, '\n');

if (nCode.includes(nT1) && nCode.includes(nT2)) {
    nCode = nCode.replace(nT1, "");
    nCode = nCode.replace(nT2, replacement);
    fs.writeFileSync('deno-server/gameEngine.js', nCode, 'utf8');
    console.log('SUCCESS: HARVEST FIX');
} else {
    console.log('FAILED TO FIND HARVEST FIX STRING');
}
