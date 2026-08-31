const fs = require('fs');
let code = fs.readFileSync('Assets/Scripts/Battle2v2UI.cs', 'utf8');

const regex = /void ApplyServerGameState\(AppwriteMatchmaking\.ServerGameState state\)\s*\{/;
const match = code.match(regex);
if (match) {
    console.log(code.substring(match.index, match.index + 500));
}
