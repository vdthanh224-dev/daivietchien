const fs = require('fs');
let code = fs.readFileSync('deno-server/gameEngine.js', 'utf8');

const targetStr = `      state.harvestPool = pool;
      state.harvestPickers = living.slice(0, pool.length).map(p => p.seat);
      if (state.harvestPool.length === 0 || state.harvestPickers.length === 0) {
        state.harvestPool = [];
        state.harvestPickers = [];
        resetWaitingState(state);
        return { success: true, state };
      }

      state.phase = "AWAIT_HARVEST";
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

const replacement = `      state.harvestPool = pool;
      state.harvestPickers = living.slice(0, pool.length).map(p => p.seat);
      
      state.activeCard = { cardId: card.id, cardName: card.name, casterSeat };
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

const normalizedCode = code.replace(/\r\n/g, '\n');
const normalizedTarget = targetStr.replace(/\r\n/g, '\n');

if (normalizedCode.includes(normalizedTarget)) {
    const newCode = normalizedCode.replace(normalizedTarget, replacement);
    fs.writeFileSync('deno-server/gameEngine.js', newCode, 'utf8');
    console.log('SUCCESS: HARVEST FIX');
} else {
    console.log('FAILED TO FIND HARVEST FIX STRING');
}
