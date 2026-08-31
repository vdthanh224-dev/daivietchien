const fs = require('fs');
let code = fs.readFileSync('Assets/Scripts/Battle2v2UI.cs', 'utf8');

const regex = /private int lastHandledPhaseVersion = -1;/;
code = code.replace(regex, '// private int lastHandledPhaseVersion = -1;');
fs.writeFileSync('Assets/Scripts/Battle2v2UI.cs', code);
console.log("Patched lastHandledPhaseVersion warning");
