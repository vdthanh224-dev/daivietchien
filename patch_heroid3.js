const fs = require('fs');
let code = fs.readFileSync('Assets/Scripts/Battle2v2UI.cs', 'utf8');

code = code.replace(/HERO_2/g, "2");
fs.writeFileSync('Assets/Scripts/Battle2v2UI.cs', code, 'utf8');
console.log('SUCCESS: HERO_2 UI FIX');
