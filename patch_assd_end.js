const fs = require('fs');
let code = fs.readFileSync('Assets/Scripts/Battle2v2UI.cs', 'utf8');

const regex = /if \(string\.Equals\(delta\.status, "FINISHED", StringComparison\.Ordinal\)\)\s*\{\s*ApplyAuthoritativeGameFinished\(\);\s*\}\s*\}/;
const replaceStr = `if (string.Equals(delta.status, "FINISHED", StringComparison.Ordinal))
            {
                ApplyAuthoritativeGameFinished();
            }
        }
        
        if (pendingDealTargets.Count > 0) {
            StartCoroutine(GlobalDealRoutine(pendingDealTargets, pendingDealCounts, pendingDealMyCards));
        }`;

if (regex.test(code)) {
    code = code.replace(regex, replaceStr);
    fs.writeFileSync('Assets/Scripts/Battle2v2UI.cs', code);
    console.log("Patched ApplyServerStateDelta end");
} else {
    console.log("Target not found");
}
