const fs = require('fs');
let code = fs.readFileSync('Assets/Scripts/Battle2v2UI.cs', 'utf8');

const regex = /void ApplyServerGameState\(AppwriteMatchmaking\.ServerGameState state\)[\s\S]*?private void ApplyServerStateDelta/;
if (regex.test(code)) {
    console.log("Found ApplyServerGameState");
}
