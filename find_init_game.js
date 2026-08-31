const fs = require('fs');
const lines = fs.readFileSync('deno-server/server.js', 'utf8').split('\n');
const match = lines.findIndex(l => l.includes('if (payload.action === "INIT_GAME") {'));
console.log(lines.slice(Math.max(0, match - 5), match + 10).join('\n'));
