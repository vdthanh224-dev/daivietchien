const fs = require('fs');
let code = fs.readFileSync('Assets/Scripts/AppwriteMatchmaking.cs', 'utf8');
console.log(code.indexOf('public string skillId;'));
