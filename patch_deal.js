const fs = require('fs');
let code = fs.readFileSync('Assets/Scripts/Battle2v2UI.cs', 'utf8');

const regex1 = /int newCards = p\.handCount - hand\.Count;\s*if \(newCards > 0\) \{\s*StartCoroutine\(AnimateMultipleDealtCards\(g, newCards\)\);\s*for \(int i = 0; i < newCards; i\+\+\) \{\s*hand\.Add\(new CardModel \{ id = "HIDDEN", cardName = "Ẩn" \}\);\s*\}\s*\}/;

const replace1 = `int newCards = p.handCount - hand.Count;
                        if (newCards > 0) {
                            pendingDealTargets.Add(g);
                            pendingDealCounts.Add(newCards);
                            pendingDealMyCards.Add(null);
                            for (int i = 0; i < newCards; i++) {
                                hand.Add(new CardModel { id = "HIDDEN", cardName = "Ẩn" });
                            }
                        }`;

const regex2 = /StartCoroutine\(AnimateMultipleDealtCards\(playerCard, diff, newDealtCards\)\);/;

const replace2 = `pendingDealTargets.Add(playerCard);
                            pendingDealCounts.Add(diff);
                            pendingDealMyCards.Add(newDealtCards);`;

if (regex1.test(code) && regex2.test(code)) {
    code = code.replace(regex1, replace1);
    code = code.replace(regex2, replace2);
    
    // insert list definitions
    code = code.replace(/void ApplyServerGameState\(AppwriteMatchmaking\.ServerGameState state\)\s*\{/, 
        `void ApplyServerGameState(AppwriteMatchmaking.ServerGameState state)
    {
        List<GeneralCardUI> pendingDealTargets = new List<GeneralCardUI>();
        List<int> pendingDealCounts = new List<int>();
        List<List<CardModel>> pendingDealMyCards = new List<List<CardModel>>();`);
        
    // insert coroutine trigger at end of ApplyServerGameState
    // find end of ApplyServerGameState: it ends right before `private void ApplyServerStateDelta`
    const endMatch = code.match(/\s*\}\s*private void ApplyServerStateDelta/);
    if (endMatch) {
        code = code.replace(/\s*\}\s*private void ApplyServerStateDelta/, 
        `
        if (pendingDealTargets.Count > 0) {
            StartCoroutine(GlobalDealRoutine(pendingDealTargets, pendingDealCounts, pendingDealMyCards));
        }
    }
    
    private IEnumerator GlobalDealRoutine(List<GeneralCardUI> targets, List<int> counts, List<List<CardModel>> newCardsList) {
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
        }
    }

    private void ApplyServerStateDelta`);
        fs.writeFileSync('Assets/Scripts/Battle2v2UI.cs', code);
        console.log("Patched round-robin deal");
    } else {
        console.log("End of method not found");
    }
} else {
    console.log("Target not found");
}
