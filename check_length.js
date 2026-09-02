const fs = require('fs');
let code = fs.readFileSync('Assets/Scripts/Battle2v2UI.cs', 'utf8');

const match = code.match(/ApplyServerGameState[\s\S]*?var myServerData = state.players.Find\(p => p.seat == playerCard.SeatNumber\);/);
if (match) console.log(match[0].length);
