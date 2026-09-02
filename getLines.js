const fs = require('fs');
let code = fs.readFileSync('Assets/Scripts/Battle2v2UI.cs', 'utf8');
const lines = code.split('\n');
let start = -1;
let end = -1;
for (let i = 0; i < lines.length; i++) {
    if (lines[i].includes('private void ShowServerHarvestModal')) start = i;
    if (start !== -1 && lines[i].includes('private IEnumerator') && i > start) {
        end = i;
        break;
    }
}
if (end === -1) end = start + 100;
console.log(lines.slice(start, end).join('\n'));
