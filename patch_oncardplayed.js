const fs = require('fs');
let code = fs.readFileSync('Assets/Scripts/PlayerHandUI.cs', 'utf8');
code = code.replace(/\/\/ public event Action<CardUI> OnCardPlayed;/, 'public event Action<CardUI> OnCardPlayed;');
fs.writeFileSync('Assets/Scripts/PlayerHandUI.cs', code);
console.log("Restored OnCardPlayed in PlayerHandUI");
