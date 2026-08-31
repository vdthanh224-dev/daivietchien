const fs = require('fs');
const lines = fs.readFileSync('deno-server/server.js', 'utf8').split('\n');
const match = lines.findIndex(l => l.includes('function applyActionToState('));
console.log(lines.slice(match, match + 20).join('\n'));
