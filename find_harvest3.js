const fs = require('fs');
const lines = fs.readFileSync('deno-server/gameEngine.js', 'utf8').split('\n');
const match = lines.findIndex(l => l.includes('AWAIT_HARVEST') && l.includes('phase ===') && !l.includes('tickGameState'));
console.log(lines.slice(match, match + 20).join('\n'));
