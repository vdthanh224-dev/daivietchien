const fs = require('fs');
let code = fs.readFileSync('Assets/Scripts/Battle2v2UI.cs', 'utf8');

const regex = /playerHandUI\.ClearHand\(\);\s*if \(diff <= 0\) playerHandUI\.AddCards\(playerHandCards\);/;
const replaceStr = `playerHandUI.ClearHand();
                        if (diff <= 0) {
                            playerHandUI.AddCards(playerHandCards);
                        } else {
                            int oldLimit = playerHandCards.Count - diff;
                            for (int i = 0; i < oldLimit; i++) {
                                playerHandUI.AddCard(playerHandCards[i]);
                            }
                        }`;

if (regex.test(code)) {
    code = code.replace(regex, replaceStr);
    fs.writeFileSync('Assets/Scripts/Battle2v2UI.cs', code);
    console.log("Patched playerHandUI old cards preservation in ASGS");
} else {
    console.log("Target not found");
}
