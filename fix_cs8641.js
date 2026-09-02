const fs = require('fs');
let code = fs.readFileSync('Assets/Scripts/Battle2v2UI.cs', 'utf8');

code = code.replace(/\/\/\s*if\s*\(serverControlled\)\s*promptTimer\s*=\s*turnTimer;/g, "");
code = code.replace(/else\s+promptTimer\s*-=\s*Time\.unscaledDeltaTime;/g, "promptTimer -= Time.unscaledDeltaTime;");
code = code.replace(/else\s*\/\/\s*if\s*\(serverControlled\)\s*promptTimer\s*=\s*turnTimer;/g, "");

fs.writeFileSync('Assets/Scripts/Battle2v2UI.cs', code, 'utf8');
console.log('Fixed CS8641');
