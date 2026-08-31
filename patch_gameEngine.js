const fs = require('fs');
let code = fs.readFileSync('deno-server/gameEngine.js', 'utf8');
code = code.replace(
  'let cardIndex = caster.hand.findIndex(c => c.id === cardId);',
  'let cardIndex = caster.hand.findIndex(c => c.id === cardId);\n  let card = null;\n  if (cardIndex >= 0) {\n      card = caster.hand[cardIndex];\n      if (caster.activeSkills && caster.activeSkills["Chế Nỏ"] && card.suit === "Spade" && card.subType !== CARD_SUBTYPES.WEAPON) {\n          card = { ...card, name: "Nỏ Thần Kim Quy", subType: CARD_SUBTYPES.WEAPON, category: CARD_CATEGORIES.EQUIPMENT, range: 1, distMod: 0, desc: "Tầm 1. Không giới hạn số Trảm trong lượt" };\n      }\n  }'
);
code = code.replace(
  'const selectedCard = caster.hand[cardIndex];',
  'const selectedCard = card;'
);
fs.writeFileSync('deno-server/gameEngine.js', code);
