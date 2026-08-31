const fs = require('fs');
const lines = fs.readFileSync('Assets/Scripts/Battle2v2UI.cs', 'utf8').split('\n');
const match = lines.findIndex(l => l.includes('void OnDiscardSelectionChanged('));
console.log(lines.slice(match, match + 20).join('\n'));
