const fs = require('fs');
const lines = fs.readFileSync('Assets/Scripts/Battle2v2UI.cs', 'utf8').split('\n');
lines.forEach((l, i) => { if (l.includes('isPlayerTurnActive')) console.log(`${i}: ${l}`); });
