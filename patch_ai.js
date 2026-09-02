const fs = require('fs');
let code = fs.readFileSync('deno-server/gameEngine.js', 'utf8');

const t = code.substring(code.indexOf("  // J. Cẩm nang phá bài (Vườn Không / Đột Kích)"), code.indexOf("  // H. Không còn bài muốn đánh -> Kết thúc lượt"));

const replacement = `  // J. Cẩm nang phá bài (Vườn Không / Đột Kích)
  // Ưu tiên cứu đồng đội khỏi các lá Phán Xét (Trì hoãn)
  const allies = state.players.filter(x => areTeammates(x.seat, aiSeat) && x.hp > 0);
  const allyNeedHelp = allies.find((ally) => (ally.judgements && ally.judgements.length > 0));
  
  const snatch = ai.hand.find((card) => card.subType === CARD_SUBTYPES.SNATCH);
  const dismantle = ai.hand.find((card) => card.subType === CARD_SUBTYPES.DISMANTLE);

  if (allyNeedHelp) {
    if (dismantle) {
      return handlePlayCard(state, aiSeat, dismantle.id, allyNeedHelp.seat);
    }
    if (snatch && getDistance(state, aiSeat, allyNeedHelp.seat) <= 1) {
      return handlePlayCard(state, aiSeat, snatch.id, allyNeedHelp.seat);
    }
  }

  // Nếu không có đồng đội cần cứu, dùng để phá bài kẻ địch (Chỉ Hand và Equipment)
  const snatchTarget = enemies.find((enemy) =>
    getDistance(state, aiSeat, enemy.seat) <= 1 && buildTargetCardOptions(state, enemy.seat, false).length > 0
  ) || null;
  if (snatch && snatchTarget) {
    return handlePlayCard(state, aiSeat, snatch.id, snatchTarget.seat);
  }

  const dismantleTarget = enemies.find((enemy) => buildTargetCardOptions(state, enemy.seat, false).length > 0) || null;
  if (dismantle && dismantleTarget) {
    return handlePlayCard(state, aiSeat, dismantle.id, dismantleTarget.seat);
  }

`;

if (t.length > 5) {
    code = code.replace(t, replacement);
    fs.writeFileSync('deno-server/gameEngine.js', code, 'utf8');
    console.log('SUCCESS: AI Snatch/Dismantle FIX');
} else {
    console.log('FAILED TO FIND AI Snatch/Dismantle STRING');
}
