const fs = require('fs');
let code = fs.readFileSync('Assets/Scripts/Battle2v2UI.cs', 'utf8');

code = code.replace(/playerCard\.Data == null/g, 'string.IsNullOrEmpty(playerCard.HeroId)');
fs.writeFileSync('Assets/Scripts/Battle2v2UI.cs', code);
console.log("Patched playerCard.Data checks");
