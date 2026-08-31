const fs = require('fs');
let code = fs.readFileSync('Assets/Scripts/AppwriteMatchmaking.cs', 'utf8');

const match = code.match(/public class GameActionPayload\s*\{[\s\S]*?\}/);
console.log(match ? match[0] : 'not found');
