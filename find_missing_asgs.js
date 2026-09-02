const fs = require('fs');
const lines = fs.readFileSync('old_b2v2.cs', 'utf8').split('\n');
const match = lines.findIndex(l => l.includes('void ApplyServerGameState('));
if (match !== -1) {
    let endMatch = -1;
    for (let i = match; i < lines.length; i++) {
        if (lines[i].includes('private void ApplyServerStateDelta(')) {
            endMatch = i - 1;
            break;
        }
    }
    console.log("Lines " + match + " to " + endMatch);
    fs.writeFileSync('missing_asgs.cs', lines.slice(match, endMatch + 1).join('\n'));
} else {
    console.log("not found in old_b2v2");
}
