const fs = require('fs');
let code = fs.readFileSync('deno-server/gameEngine.js', 'utf8');

code = code.replace(/\[Bánh Chưng\]/g, '${formatCardText(card)}');
code = code.replace(/\[Hủ Rượu\]/g, '${formatCardText(card)}');
code = code.replace(/\[Dụng Binh Như Thần\]/g, '${formatCardText(card)}');
code = code.replace(/\[Mở Kho Cứu Tế\]/g, '${formatCardText(card)}');
code = code.replace(/\[Thách Đấu\]/g, '${formatCardText(card)}');

fs.writeFileSync('deno-server/gameEngine.js', code);
console.log("Patched formatCardText usages in gameEngine.js");
