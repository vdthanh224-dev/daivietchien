const fs = require('fs');
let code = fs.readFileSync('deno-server/gameEngine.js', 'utf8');
code = code.replace(
  'const card = caster.hand.splice(cardIndex, 1)[0];',
  'const realCard = caster.hand.splice(cardIndex, 1)[0];\n  const card = selectedCard; // Use the properly modified copy with Nỏ Thần'
);
fs.writeFileSync('deno-server/gameEngine.js', code);
