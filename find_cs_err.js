const fs = require('fs');
const lines = fs.readFileSync('Assets/Scripts/Battle2v2UI.cs', 'utf8').split('\n');
console.log("--- 1220-1230 ---");
console.log(lines.slice(1220, 1230).join('\n'));
console.log("--- 6630-6640 ---");
console.log(lines.slice(6630, 6640).join('\n'));
console.log("--- 6860-6870 ---");
console.log(lines.slice(6860, 6870).join('\n'));
