const fs = require('fs');
const lines = fs.readFileSync('Assets/Scripts/Battle2v2UI.cs', 'utf8').split('\n');
const match = lines.findIndex(l => l.includes('StartCoroutine(AnimateMultipleDealtCards(g, diff));'));
if (match !== -1) {
    console.log(lines.slice(match - 5, match + 5).join('\n'));
} else {
    console.log("AnimateMultipleDealtCards not found in ASGS");
}
