const fs = require('fs');
const lines = fs.readFileSync('Assets/Scripts/Battle2v2UI.cs', 'utf8').split('\n');
const match = lines.findIndex(l => l.includes('CardDatabase.GetCardById'));
console.log(lines.slice(Math.max(0, match - 5), match + 5).join('\n'));
