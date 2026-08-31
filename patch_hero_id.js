const fs = require('fs');
let code = fs.readFileSync('Assets/Scripts/Battle2v2UI.cs', 'utf8');

code = code.replace(/playerCard\.Data\.id/g, 'playerCard.HeroId');
fs.writeFileSync('Assets/Scripts/Battle2v2UI.cs', code);
console.log("Patched playerCard.Data.id to playerCard.HeroId");
