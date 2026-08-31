const fs = require('fs');
const lines = fs.readFileSync('Assets/Scripts/PlayerHandUI.cs', 'utf8').split('\n');
const match = lines.findIndex(l => l.includes('CardClicked'));
console.log(lines.slice(Math.max(0, match - 5), match + 20).join('\n'));
