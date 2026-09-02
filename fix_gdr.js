const fs = require('fs');
const lines = fs.readFileSync('Assets/Scripts/Battle2v2UI.cs', 'utf8').split('\n');
const newRoutine =     private IEnumerator GlobalDealRoutine(List<GeneralCardUI> tList, List<int> cList, List<List<CardModel>> mcList) {
        var targets = new List<GeneralCardUI>(tList);
        var counts = new List<int>(cList);
        var newCardsList = new List<List<CardModel>>(mcList);
        pendingDealTargets.Clear();
        pendingDealCounts.Clear();
        pendingDealMyCards.Clear();
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
    };
let start = -1, end = -1;
for(let i=0; i<lines.length; i++) {
  if (lines[i].includes('private IEnumerator GlobalDealRoutine')) start = i;
  if (start !== -1 && lines[i].includes('private void ApplyServerStateDelta')) { end = i - 1; break; }
}
if (start !== -1 && end !== -1) {
  lines.splice(start, end - start, newRoutine);
  fs.writeFileSync('Assets/Scripts/Battle2v2UI.cs', lines.join('\n'));
} else { console.log('not found'); }
