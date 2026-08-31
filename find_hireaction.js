const fs = require('fs');
const lines = fs.readFileSync('deno-server/gameEngine.js', 'utf8').split('\n');
const match = lines.findIndex(l => l.includes('function handleAIReaction'));
console.log(lines.slice(match, match + 70).join('\n'));
