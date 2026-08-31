const fs = require('fs');
const code = fs.readFileSync('Assets/Scripts/Battle2v2UI.cs', 'utf8');
const match = code.match(/IEnumerator ShowNullifyPrompt[\s\S]*?var panelGo = new GameObject\("CounterPromptModal"/m);
console.log(match ? match[0] : 'not found');
