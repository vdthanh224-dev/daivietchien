const fs = require('fs');
const lines = fs.readFileSync('Assets/Scripts/Battle2v2UI.cs', 'utf8').split('\n');
const match = lines.findIndex(l => l.includes('var warningText = AddText('));
console.log(lines.slice(Math.max(0, match - 20), match + 20).join('\n'));
