const fs = require('fs');
const lines = fs.readFileSync('old_b2v2.cs', 'utf8').split('\n');
const match = lines.findIndex(l => l.includes('void ApplyServerGameState('));
for (let i = match; i < match + 200; i++) {
    if (lines[i].includes('private') || lines[i].includes('public')) {
        console.log("Found end candidate at " + i + ": " + lines[i]);
    }
}
