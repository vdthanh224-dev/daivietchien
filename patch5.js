const fs = require('fs');
let code = fs.readFileSync('deno-server/gameEngine.js', 'utf8');

const t = code.substring(code.indexOf("state.harvestPickers = living.slice(0, pool.length).map(p => p.seat);"), code.indexOf("if (card.subType === CARD_SUBTYPES.ARROW_RAIN || card.subType === CARD_SUBTYPES.BARBARIAN_INVASION) {"));

const replacement = `state.harvestPickers = living.slice(0, pool.length).map(p => p.seat);
      
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
      return { success: true, state };
    }

    // 3. DIỆN RỘNG (Mưa Tên / Bãi Cọc Ngầm)
    `;

if (t.length > 5) {
    code = code.replace(t, replacement);
    fs.writeFileSync('deno-server/gameEngine.js', code, 'utf8');
    console.log('SUCCESS: HARVEST FIX');
} else {
    console.log('FAILED TO FIND HARVEST FIX STRING');
}
