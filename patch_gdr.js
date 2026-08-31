const fs = require('fs');
let code = fs.readFileSync('Assets/Scripts/Battle2v2UI.cs', 'utf8');

// There are three places where we had:
// if (pendingDealTargets.Count > 0) { StartCoroutine(GlobalDealRoutine(pendingDealTargets, pendingDealCounts, pendingDealMyCards)); }
// Since they are now class-level, we should clear them before adding and after running.
const regexGDR = /private IEnumerator GlobalDealRoutine[\s\S]*?private void ApplyServerStateDelta/m;
const matchGDR = code.match(regexGDR);
if (matchGDR) {
    let gdrStr = matchGDR[0];
    gdrStr = gdrStr.replace(/}\s*$/, `        targets.Clear();\n        counts.Clear();\n        newCardsList.Clear();\n    }\n\n    private void ApplyServerStateDelta`);
    code = code.replace(regexGDR, gdrStr);
    fs.writeFileSync('Assets/Scripts/Battle2v2UI.cs', code);
    console.log("Patched GlobalDealRoutine to clear lists");
}
