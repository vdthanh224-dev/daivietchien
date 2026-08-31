const fs = require('fs');
const lines = fs.readFileSync('Assets/Scripts/DenoGameClient.cs', 'utf8').split('\n');
const match = lines.findIndex(l => l.includes('STATE_SNAPSHOT'));
console.log(lines.slice(match - 5, match + 20).join('\n'));
