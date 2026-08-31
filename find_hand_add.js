const fs = require('fs');
let code = fs.readFileSync('Assets/Scripts/Battle2v2UI.cs', 'utf8');

const regex = /int newCards = p\.handCount - hand\.Count;\s*if \(newCards > 0\) \{\s*StartCoroutine\(AnimateMultipleDealtCards\(g, newCards\)\);\s*for \(int i = 0; i < newCards; i\+\+\) \{\s*hand\.Add\(new CardModel \{ id = "HIDDEN", cardName = "Ẩn" \}\);\s*\}\s*\}/g;

if (regex.test(code)) {
    console.log("Found match for hidden cards dealing");
} else {
    console.log("No match");
}
