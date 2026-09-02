const fs = require('fs');
let code = fs.readFileSync('Assets/Scripts/Battle2v2UI.cs', 'utf8');

const regexASGS = /private void ApplyServerGameState\(AppwriteMatchmaking\.ServerGameState state\)\s*\{/;
const replaceASGS = `private void ApplyServerGameState(AppwriteMatchmaking.ServerGameState state)
    {
        var pendingDealTargets = new List<GeneralCardUI>();
        var pendingDealCounts = new List<int>();
        var pendingDealMyCards = new List<List<CardModel>>();`;
code = code.replace(regexASGS, replaceASGS);

// Also apply the deal logic for opponents
const regexOpp = /int diff = p\.handCount - hand\.Count;\s*if \(diff > 0\)\s*\{\s*StartCoroutine\(AnimateMultipleDealtCards\(g, diff\)\);\s*for \(int i = 0; i < diff; i\+\+\) hand\.Add\(new CardModel \{ id = "HIDDEN", cardName = "Ẩn" \}\);\s*\}/;
const replaceOpp = `int diff = p.handCount - hand.Count;
                    if (diff > 0)
                    {
                        pendingDealTargets.Add(g);
                        pendingDealCounts.Add(diff);
                        pendingDealMyCards.Add(null);
                        for (int i = 0; i < diff; i++) hand.Add(new CardModel { id = "HIDDEN", cardName = "Ẩn" });
                    }`;
code = code.replace(regexOpp, replaceOpp);

// Also apply the deal logic for playerCard
const regexPlayer = /int diff = myServerData\.hand\.Count - playerHandCards\.Count;\s*if \(diff > 0\)\s*\{\s*StartCoroutine\(AnimateMultipleDealtCards\(playerCard, diff, newDealtCards\)\);/;
const replacePlayer = `int diff = myServerData.hand.Count - playerHandCards.Count;
                        if (diff > 0)
                        {
                            pendingDealTargets.Add(playerCard);
                            pendingDealCounts.Add(diff);
                            pendingDealMyCards.Add(newDealtCards);`;
code = code.replace(regexPlayer, replacePlayer);

// Add the call to GlobalDealRoutine at the end of ApplyServerGameState
const regexEnd = /if \(string\.Equals\(state\.status, "FINISHED", StringComparison\.Ordinal\)\)\s*\{\s*ApplyAuthoritativeGameFinished\(\);\s*\}\s*\}/;
const replaceEnd = `if (string.Equals(state.status, "FINISHED", StringComparison.Ordinal))
            {
                ApplyAuthoritativeGameFinished();
            }
        }
        
        if (pendingDealTargets.Count > 0) {
            StartCoroutine(GlobalDealRoutine(pendingDealTargets, pendingDealCounts, pendingDealMyCards));
        }`;
code = code.replace(regexEnd, replaceEnd);

fs.writeFileSync('Assets/Scripts/Battle2v2UI.cs', code);
console.log("Patched ApplyServerGameState");
