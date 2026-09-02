const fs = require('fs');
const lines = fs.readFileSync('Assets/Scripts/Battle2v2UI.cs', 'utf8').split('\n');
const match = lines.findIndex(l => l.includes('private void ApplyServerLoadout('));
console.log(lines.slice(match - 50, match).join('\n'));
