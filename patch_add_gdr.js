const fs = require('fs');
let code = fs.readFileSync('Assets/Scripts/Battle2v2UI.cs', 'utf8');

const insertStr = `
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
            yield return new WaitForSeconds(0.05f);
        }
    }
`;

const regex = /private void ApplyServerStateDelta/;
code = code.replace(regex, insertStr + "\n    private void ApplyServerStateDelta");
fs.writeFileSync('Assets/Scripts/Battle2v2UI.cs', code);
console.log("Added GlobalDealRoutine");
