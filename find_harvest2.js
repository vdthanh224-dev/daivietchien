const fs = require('fs');
const lines = fs.readFileSync('deno-server/gameEngine.js', 'utf8').split('\n');
const match = lines.findIndex(l => l.includes('AWAIT_HARVEST') && l.includes('phase ==='));
console.log(lines.slice(match + 20, match + 50).join('\n'));
