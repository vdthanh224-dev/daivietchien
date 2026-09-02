const fs = require('fs');
const lines = fs.readFileSync('old_b2v2.cs', 'utf8').split('\n');
const match = lines.findIndex(l => l.includes('void ApplyServerGameState('));
let endMatch = lines.findIndex(l => l.includes('private void ApplyServerLoadout('));
console.log("Match: " + match + ", endMatch: " + endMatch);
