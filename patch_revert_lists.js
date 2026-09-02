const fs = require('fs');
let code = fs.readFileSync('Assets/Scripts/Battle2v2UI.cs', 'utf8');

const regex = /private List<GeneralCardUI> pendingDealTargets = new List<GeneralCardUI>\(\);\s*private List<int> pendingDealCounts = new List<int>\(\);\s*private List<List<CardModel>> pendingDealMyCards = new List<List<CardModel>>\(\);/;
code = code.replace(regex, "");

const regexGDR = /private IEnumerator GlobalDealRoutine\(List<GeneralCardUI> targets, List<int> counts, List<List<CardModel>> newCardsList\)\s*\{[\s\S]*?targets\.Clear\(\);\s*counts\.Clear\(\);\s*newCardsList\.Clear\(\);\s*\}/;

const replaceGDR = `private IEnumerator GlobalDealRoutine(List<GeneralCardUI> targets, List<int> counts, List<List<CardModel>> newCardsList) {
        int maxCount = 0;
        foreach (var c in counts) if (c > maxCount) maxCount = c;
        
        for (int i = 0; i < maxCount; i++) {
            for (int t = 0; t < targets.Count; t++) {
                if (i < counts[t]) {
                    var target = targets[t];
                    yield return AnimateDealtCard(target);
                    if (target == playerCard && newCardsList[t] != null && i < newCardsList[t].Count) {
                        playerHandUI.AddCard(newCardsList[t][i]);
                        UpdateHandCountsVisual();
                    }
                }
            }
            yield return new WaitForSeconds(0.05f);
        }
    }`;

code = code.replace(regexGDR, replaceGDR);

const regexASGS = /void ApplyServerGameState\(AppwriteMatchmaking\.ServerGameState state\)\s*\{/;
const replaceASGS = `void ApplyServerGameState(AppwriteMatchmaking.ServerGameState state)
    {
        var pendingDealTargets = new List<GeneralCardUI>();
        var pendingDealCounts = new List<int>();
        var pendingDealMyCards = new List<List<CardModel>>();`;

code = code.replace(regexASGS, replaceASGS);

const regexASSD = /private void ApplyServerStateDelta\(AppwriteMatchmaking\.GameStateDelta delta\)\s*\{[\s\S]*?List<List<CardModel>> pendingDealMyCards = new List<List<CardModel>>\(\);/;
const replaceASSD = `private void ApplyServerStateDelta(AppwriteMatchmaking.GameStateDelta delta)
    {
        var pendingDealTargets = new List<GeneralCardUI>();
        var pendingDealCounts = new List<int>();
        var pendingDealMyCards = new List<List<CardModel>>();`;

code = code.replace(regexASSD, replaceASSD);

fs.writeFileSync('Assets/Scripts/Battle2v2UI.cs', code);
console.log("Reverted lists to local");
