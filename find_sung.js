const fs = require('fs');
const lines = fs.readFileSync('deno-server/gameEngine.js', 'utf8').split('\n');
const match = lines.findIndex(l => l.includes('Súng Thần Công'));
console.log(lines.slice(Math.max(0, match - 5), match + 5).join('\n'));
