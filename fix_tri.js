const fs = require('fs');
let code = fs.readFileSync('deno-server/gameEngine.js', 'utf8');

code = code.replace(
  /const actionType = selection.effectType === "THUONG_NGAU"\r\n      \? "THUONG_NGAU_DESTROY"\r\n      : selection.effectType === "FLAWLESS_DEFENSE"\r\n        \? "PLAY_FLAWLESS_DEFENSE"\r\n      : selection.operation === "STEAL" \? "PLAY_SNATCH" : "PLAY_DISMANTLE";/,
  'const actionType = selection.effectType === "THUONG_NGAU"\n      ? "THUONG_NGAU_DESTROY"\n      : selection.effectType === "TRIEU_DANG"\n        ? "USE_SKILL"\n      : selection.effectType === "FLAWLESS_DEFENSE"\n        ? "PLAY_FLAWLESS_DEFENSE"\n      : selection.operation === "STEAL" ? "PLAY_SNATCH" : "PLAY_DISMANTLE";'
);

code = code.replace(
  /description: \\$\{selection\.operation === "STEAL" \? "🌾" : "🏚️"\} <b>\$\{caster \? caster.generalName : 'Người\\s+chơi'\}<\/b> dùng \[\$\{selection\.cardName\}\] \$\{actionVerb\} \[\$\{publicTargetName\}\] của <b>\$\{target.generalName\}<\/b>!\/,
  'description: ${selection.effectType === "TRIEU_DANG" ? "🌊" : (selection.operation === "STEAL" ? "🌾" : "🏚️")} <b></b> dùng []  [] của <b></b>!'
);
fs.writeFileSync('deno-server/gameEngine.js', code);
