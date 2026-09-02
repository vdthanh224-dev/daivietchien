const fs = require('fs');
let code = fs.readFileSync('deno-server/gameEngine.js', 'utf8');

const t7 = `if (victim.heroId === "HERO_3") {`;
const rep7 = `if (String(victim.heroId) === "3") {`;

const t8 = `if (playerCard.HeroId == "HERO_2") dist -= 2;`;

code = code.replace(t7, rep7).replace(t7, rep7);
fs.writeFileSync('deno-server/gameEngine.js', code, 'utf8');
console.log('SUCCESS: Deno Hero ID FIX');
