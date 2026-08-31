const fs = require('fs');
let code = fs.readFileSync('Assets/Scripts/Battle2v2UI.cs', 'utf8');

const regex = /private void ApplyServerStateDelta\(AppwriteMatchmaking\.GameStateDelta delta\)\s*\{/;
const replaceStr = `private void ApplyServerStateDelta(AppwriteMatchmaking.GameStateDelta delta)
    {
        List<GeneralCardUI> pendingDealTargets = new List<GeneralCardUI>();
        List<int> pendingDealCounts = new List<int>();
        List<List<CardModel>> pendingDealMyCards = new List<List<CardModel>>();`;

if (regex.test(code)) {
    code = code.replace(regex, replaceStr);
    fs.writeFileSync('Assets/Scripts/Battle2v2UI.cs', code);
    console.log("Patched ApplyServerStateDelta");
} else {
    console.log("Target not found");
}
