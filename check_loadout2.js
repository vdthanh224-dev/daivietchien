const fs = require('fs');
const lines2 = fs.readFileSync('Assets/Scripts/Battle2v2UI.cs', 'utf8').split('\n');
lines2.forEach((l, i) => { if (l.includes('ApplyServerLoadout(')) console.log((i+1) + ': ' + l.trim()); });
