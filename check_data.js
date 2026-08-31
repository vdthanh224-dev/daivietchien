const fs = require('fs');
let code = fs.readFileSync('Assets/Scripts/Battle2v2UI.cs', 'utf8');

const m = code.match(/playerCard\.Data/g);
console.log("Remaining playerCard.Data:", m ? m.length : 0);

const m2 = code.match(/\.Data/g);
console.log("Total .Data:", m2 ? m2.length : 0);
