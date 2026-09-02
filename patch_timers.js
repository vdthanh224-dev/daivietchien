const fs = require('fs');
let code = fs.readFileSync('Assets/Scripts/Battle2v2UI.cs', 'utf8');

const regex = /if \(serverControlled\)\s+promptTimer = turnTimer;/g;
const replacement = `// if (serverControlled) promptTimer = turnTimer;`;

const newCode = code.replace(regex, replacement);
if (code !== newCode) {
    fs.writeFileSync('Assets/Scripts/Battle2v2UI.cs', newCode, 'utf8');
    console.log('SUCCESS: FIXED LOCAL TIMERS IN PROMPTS');
} else {
    console.log('FAILED TO FIND PROMPT TIMER UPDATES');
}
