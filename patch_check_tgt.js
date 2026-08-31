const fs = require('fs');
let code = fs.readFileSync('deno-server/gameEngine.js', 'utf8');

const regex = /if \(card\.category === CARD_CATEGORIES\.DELAYED_SCROLL \|\| card\.subType === CARD_SUBTYPES\.LIGHTNING \|\| card\.subType === CARD_SUBTYPES\.SUPPLY_SHORTAGE \|\| card\.subType === CARD_SUBTYPES\.ACEDIA\)/;

const replaceStr = `if (card.subType === CARD_SUBTYPES.SNATCH || card.subType === CARD_SUBTYPES.DISMANTLE || card.subType === CARD_SUBTYPES.FLAWLESS_DEFENSE) {
    const t = state.players.find(x => x.seat === targetSeat);
    if (t && t.hand.length === 0 && (t.equipments || []).length === 0 && (t.judgements || []).length === 0) {
       return { error: "Mục tiêu không có bài (trên tay/trang bị/phán xét) để chọn!" };
    }
  }

  if (card.category === CARD_CATEGORIES.DELAYED_SCROLL || card.subType === CARD_SUBTYPES.LIGHTNING || card.subType === CARD_SUBTYPES.SUPPLY_SHORTAGE || card.subType === CARD_SUBTYPES.ACEDIA)`;

if (regex.test(code)) {
    code = code.replace(regex, replaceStr);
    fs.writeFileSync('deno-server/gameEngine.js', code);
    console.log("Patched target check for SCROLL in handlePlayCard");
} else {
    console.log("Target not found");
}
