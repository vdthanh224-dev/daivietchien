const fs = require('fs');
const lines1 = fs.readFileSync('head1_b2v2.cs', 'utf8').replace(/\r/g, '').split('\n');
const lines2 = fs.readFileSync('Assets/Scripts/Battle2v2UI.cs', 'utf8').replace(/\r/g, '').split('\n');

for (let i = 430; i < lines1.length; i++) {
    if (lines2.indexOf(lines1[i]) === -1) {
        if (lines1[i].trim().length > 5) {
            console.log("Missing line in current: " + i + " -> " + lines1[i].trim());
            break;
        }
    }
}
