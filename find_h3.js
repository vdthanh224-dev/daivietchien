const fs = require('fs');
const lines = fs.readFileSync('deno-server/gameEngine.js', 'utf8').split('\n');
const match = lines.findIndex(l => l.includes('function beginNextHarvestPicker(state) {'));
console.log(lines.slice(match, match + 40).join('\n'));
