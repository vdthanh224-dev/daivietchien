const fs = require('fs');
let code = fs.readFileSync('deno-server/gameEngine.js', 'utf8');

code = code.replace(
  'function discardCard(state, card, reveal = true) {\r\n    if (!card) return;\r\n    state._discard.push(card);',
  'function discardCard(state, card, reveal = true) {\r\n    if (!card) return;\r\n    if (card.originalCard) card = card.originalCard;\r\n    state._discard.push(card);'
);

fs.writeFileSync('deno-server/gameEngine.js', code);
