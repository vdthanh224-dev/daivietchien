const fs = require('fs');
const lines = fs.readFileSync('Assets/Scripts/Battle2v2UI.cs', 'utf8').split('\n');
const idx = lines.findIndex(l => l.includes('var panelGo = new GameObject("CounterPromptModal"'));
console.log(lines.slice(idx - 30, idx).join('\n'));
