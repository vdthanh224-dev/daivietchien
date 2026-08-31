const fs = require('fs');
let code = fs.readFileSync('deno-server/gameEngine.js', 'utf8');

const regex = /const actionType = selection\.effectType === "THUONG_NGAU"[\s\S]*?description:\s*`\$\{selection\.operation === "STEAL" \? "🌾" : "🏚️"\}\s*<b>\$\{caster \? caster\.generalName : 'Người chơi'\}<\/b>\s*dùng\s*\[\$\{selection\.cardName\}\]\s*\$\{actionVerb\}\s*\[\$\{publicTargetName\}\]\s*của\s*<b>\$\{target\.generalName\}<\/b>!`\s*\}\);/g;

const replaceStr = `const actionType = selection.effectType === "TRIEU_DANG" ? "TRIEU_DANG_DESTROY"
    : selection.effectType === "THUONG_NGAU" ? "THUONG_NGAU_DESTROY"
    : selection.effectType === "FLAWLESS_DEFENSE" ? "PLAY_FLAWLESS_DEFENSE"
    : selection.operation === "STEAL" ? "PLAY_SNATCH" : "PLAY_DISMANTLE";
  const actionVerb = selection.operation === "STEAL" ? "cướp" : "phá hủy";
  const publicTargetName = option.zone === "HAND" ? "lá úp trên tay" : card.name;
  let desc = \`\${selection.operation === "STEAL" ? "🌾" : "🏚️"} <b>\${caster ? caster.generalName : 'Người chơi'}</b> dùng [\${selection.cardName}] \${actionVerb} [\${publicTargetName}] của <b>\${target.generalName}</b>!\`;
  if (selection.effectType === "TRIEU_DANG") {
    desc = \`🌊 <b>\${caster ? caster.generalName : 'Người chơi'}</b> dùng kỹ năng <b>Triều Dâng</b> phá hủy trang bị [\${publicTargetName}] của <b>\${target.generalName}</b>!\`;
  }
  resetTargetCardSelection(state);
  recordAction(state, {
    type: actionType,
    casterSeat: chooserSeat,
    targetSeat: target.seat,
    cardId: selection.cardId,
    cardName: selection.cardName,
    targetCardId: option.zone === "HAND" ? null : card.id,
    targetCardName: publicTargetName,
    targetCardZone: option.zone,
    description: desc
  });`;

if (regex.test(code)) {
  code = code.replace(regex, replaceStr);
  fs.writeFileSync('deno-server/gameEngine.js', code);
  console.log('Patched completeTargetCardSelection');
} else {
  console.log('Target string not found');
}
