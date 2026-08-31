const fs = require('fs');
let code = fs.readFileSync('Assets/Scripts/Battle2v2UI.cs', 'utf8');

const regex = /playerCard\.Data/g;
console.log("Remaining playerCard.Data count:", (code.match(regex) || []).length);
