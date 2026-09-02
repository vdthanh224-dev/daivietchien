const fs = require('fs');
const lines1 = fs.readFileSync('head1_b2v2.cs', 'utf8').split('\n');
const lines2 = fs.readFileSync('Assets/Scripts/Battle2v2UI.cs', 'utf8').split('\n');
console.log("HEAD~1:", lines1.length);
console.log("Current:", lines2.length);
