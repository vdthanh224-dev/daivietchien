const fs = require('fs');
const lines = fs.readFileSync('Assets/Scripts/AuthUI.cs', 'utf8').split('\n');
console.log(lines.slice(70, 100).join('\n'));
