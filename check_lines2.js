const fs = require('fs');
const lines = fs.readFileSync('old_b2v2.cs', 'utf8').split('\n');
console.log("Total lines:", lines.length);
