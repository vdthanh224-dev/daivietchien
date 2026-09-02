const fs = require('fs');
let code = fs.readFileSync('Assets/Scripts/Battle2v2UI.cs', 'utf8');

const regex = /if \(pendingDealTargets\.Count > 0\) \{\s*StartCoroutine\(GlobalDealRoutine\(pendingDealTargets, pendingDealCounts, pendingDealMyCards\)\);\s*\}\s*\}\s*private IEnumerator GlobalDealRoutine[\s\S]*?yield return new WaitForSeconds\(0\.05f\);\s*\}\s*\}/;

code = code.replace(regex, "}");
fs.writeFileSync('Assets/Scripts/Battle2v2UI.cs', code);
console.log("Removed GlobalDealRoutine from DispatchGameEngineAction");
