const fs = require('fs');
const lines = fs.readFileSync('Assets/Scripts/AppwriteMatchmaking.cs', 'utf8').split('\n');
const match = lines.findIndex(l => l.includes('public class GameActionPayload'));
console.log(lines.slice(match, match + 20).join('\n'));
