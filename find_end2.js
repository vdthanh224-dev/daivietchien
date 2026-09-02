const fs = require('fs');
const lines = fs.readFileSync('old_b2v2.cs', 'utf8').split('\n');
const match = lines.findIndex(l => l.includes('void ApplyServerGameState('));
for (let i = match + 1; i < lines.length; i++) {
    if (lines[i].trim().startsWith('private ') || lines[i].trim().startsWith('public ')) {
        console.log("End candidate at " + i + ": " + lines[i]);
        break;
    }
}
