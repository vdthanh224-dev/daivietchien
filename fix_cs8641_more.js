const fs = require('fs');
let code = fs.readFileSync('Assets/Scripts/Battle2v2UI.cs', 'utf8');

code = code.replace(/else\s+(\w+)\s*-=\s*Time\.unscaledDeltaTime;/g, "$1 -= Time.unscaledDeltaTime;");

fs.writeFileSync('Assets/Scripts/Battle2v2UI.cs', code, 'utf8');
console.log('Fixed more CS8641');
