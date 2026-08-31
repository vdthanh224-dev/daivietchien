const fs = require('fs');
let code = fs.readFileSync('Assets/Scripts/Battle2v2UI.cs', 'utf8');

const regex1 = /void ApplyServerGameState\(AppwriteMatchmaking\.ServerGameState state\)\s*\{[\s\S]*?pendingDealMyCards = new List<List<CardModel>>\(\);/;

const replace1 = `void ApplyServerGameState(AppwriteMatchmaking.ServerGameState state)
    {`;

const regex2 = /private void ApplyServerStateDelta\(AppwriteMatchmaking\.GameStateDelta delta\)\s*\{[\s\S]*?pendingDealMyCards = new List<List<CardModel>>\(\);/;

const replace2 = `private void ApplyServerStateDelta(AppwriteMatchmaking.GameStateDelta delta)
    {`;

code = code.replace(regex1, replace1);
code = code.replace(regex2, replace2);

const insertListsStr = `
    private List<GeneralCardUI> pendingDealTargets = new List<GeneralCardUI>();
    private List<int> pendingDealCounts = new List<int>();
    private List<List<CardModel>> pendingDealMyCards = new List<List<CardModel>>();
`;

const classRegex = /public class Battle2v2UI : MonoBehaviour\s*\{/;
code = code.replace(classRegex, "public class Battle2v2UI : MonoBehaviour\n    {" + insertListsStr);

fs.writeFileSync('Assets/Scripts/Battle2v2UI.cs', code);
console.log("Patched list variables out of method scope");
