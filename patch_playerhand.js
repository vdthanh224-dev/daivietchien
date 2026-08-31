const fs = require('fs');
let code = fs.readFileSync('Assets/Scripts/PlayerHandUI.cs', 'utf8');

const regex = /public event Action<CardUI> OnCardPlayed;/;
code = code.replace(regex, '// public event Action<CardUI> OnCardPlayed;');
fs.writeFileSync('Assets/Scripts/PlayerHandUI.cs', code);
console.log("Patched PlayerHandUI.cs event warning");
