const fs = require('fs');
let code = fs.readFileSync('Assets/Scripts/Battle2v2UI.cs', 'utf8');

const regex = /pendingDealTargets\.Add\(g\);/g;
console.log("Matches:", (code.match(regex) || []).length);
