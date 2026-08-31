const fs = require('fs');
const code = fs.readFileSync('deno-server/gameEngine.js', 'utf8');
const match = code.match(/function handleUseSkill[\s\S]*?^}/m);
console.log(match ? match[0] : 'not found');
