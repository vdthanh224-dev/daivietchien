const fs = require('fs');
const lines1 = fs.readFileSync('head1_b2v2.cs', 'utf8').replace(/\r/g, '').split('\n');
console.log(lines1.slice(410, 430).join('\n'));
