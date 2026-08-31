const fs = require('fs');
const lines = fs.readFileSync('Assets/Scripts/GeneralCardUI.cs', 'utf8').split('\n');
console.log(lines.slice(20, 35).join('\n'));
