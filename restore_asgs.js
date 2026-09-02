const fs = require('fs');
const lines = fs.readFileSync('old_b2v2.cs', 'utf8').split('\n');
const match = lines.findIndex(l => l.includes('void ApplyServerGameState('));
let endMatch = lines.findIndex(l => l.includes('private void ApplyServerLoadout('));
const missingCode = lines.slice(match, endMatch).join('\n');

let code = fs.readFileSync('Assets/Scripts/Battle2v2UI.cs', 'utf8');
code = code.replace(/private void ApplyServerLoadout\(/, missingCode + '\n    private void ApplyServerLoadout(');
fs.writeFileSync('Assets/Scripts/Battle2v2UI.cs', code);
console.log("Restored ApplyServerGameState");
