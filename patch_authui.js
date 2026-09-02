const fs = require('fs');
let code = fs.readFileSync('Assets/Scripts/AuthUI.cs', 'utf8');

const regex = /if \(UnityEngine\.Input\.GetKeyDown[\s\S]*?QuickLogin\(9\);/;
const replaceStr = `var kb = UnityEngine.InputSystem.Keyboard.current;
        if (kb != null) {
            if (kb.digit1Key.wasPressedThisFrame) QuickLogin(1);
            else if (kb.digit2Key.wasPressedThisFrame) QuickLogin(2);
            else if (kb.digit3Key.wasPressedThisFrame) QuickLogin(3);
            else if (kb.digit4Key.wasPressedThisFrame) QuickLogin(4);
            else if (kb.digit5Key.wasPressedThisFrame) QuickLogin(5);
            else if (kb.digit6Key.wasPressedThisFrame) QuickLogin(6);
            else if (kb.digit7Key.wasPressedThisFrame) QuickLogin(7);
            else if (kb.digit8Key.wasPressedThisFrame) QuickLogin(8);
            else if (kb.digit9Key.wasPressedThisFrame) QuickLogin(9);
        }`;

if (regex.test(code)) {
    code = code.replace(regex, replaceStr);
    fs.writeFileSync('Assets/Scripts/AuthUI.cs', code);
    console.log("Patched AuthUI.cs to use InputSystem");
} else {
    console.log("Target not found");
}
