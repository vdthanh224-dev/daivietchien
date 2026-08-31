const fs = require('fs');
const lines = fs.readFileSync('Assets/Scripts/PlayerHandUI.cs', 'utf8').split('\n');
const match = lines.findIndex(l => l.includes('void SelectCard('));
console.log(lines.slice(match, match + 20).join('\n'));
