const fs = require('fs');
let code = fs.readFileSync('deno-server/gameEngine.js', 'utf8');

code = code.replace(/\[<b\>\$\{card\.name\}<\/b>\]/g, '${formatCardText(card)}');

fs.writeFileSync('deno-server/gameEngine.js', code);
console.log("Patched card name in DELAYED_SCROLL_ATTACHED");
