const fs = require('fs');
const lines = fs.readFileSync('Assets/Scripts/Battle2v2UI.cs', 'utf8').split('\n');
const match = lines.findIndex(l => l.includes('switch (state.phase)'));
console.log(lines.slice(match - 30, match + 5).join('\n'));
