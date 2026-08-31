const fs = require('fs');
let code = fs.readFileSync('Assets/Scripts/Battle2v2UI.cs', 'utf8');

const regex = /isAwaitingServerNamSon = false; serverTargetCardSelectionInFlight = false; isDiscardPhaseActive = false; if \(playerHandUI != null\) \{ playerHandUI\.IsMultiSelectMode = false; playerHandUI\.ClearSelection\(\); \} \}/;
const replaceStr = `isAwaitingServerNamSon = false; serverTargetCardSelectionInFlight = false; 
            if (state.phase != "DISCARD") {
                isDiscardPhaseActive = false; 
                if (playerHandUI != null) { 
                    playerHandUI.IsMultiSelectMode = false; 
                    playerHandUI.ClearSelection(); 
                    playerHandUI.OnSelectionChanged -= OnDiscardSelectionChanged;
                } 
            }
        }`;

if (regex.test(code)) {
    code = code.replace(regex, replaceStr);
    fs.writeFileSync('Assets/Scripts/Battle2v2UI.cs', code);
    console.log("Patched discard phase reset bug");
} else {
    console.log("Target not found");
}
