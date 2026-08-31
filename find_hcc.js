const fs = require('fs');
const lines = fs.readFileSync('Assets/Scripts/PlayerHandUI.cs', 'utf8').split('\n');
const match = lines.findIndex(l => l.includes('HandleCardClicked('));
console.log(lines.slice(match, match + 30).join('\n'));
