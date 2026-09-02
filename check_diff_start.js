const fs = require('fs');
const lines1 = fs.readFileSync('head1_b2v2.cs', 'utf8').split('\n');
const lines2 = fs.readFileSync('Assets/Scripts/Battle2v2UI.cs', 'utf8').split('\n');
let diffStart = -1;
for (let i = 0; i < Math.min(lines1.length, lines2.length); i++) {
    if (lines1[i] !== lines2[i]) {
        diffStart = i;
        break;
    }
}
console.log("Diff starts at line: " + diffStart);
console.log("HEAD~1: " + lines1[diffStart]);
console.log("Current: " + lines2[diffStart]);
