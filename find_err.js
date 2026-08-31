const fs = require('fs');
const lines = fs.readFileSync('deno-server/gameEngine.js', 'utf8').split('\n');
const match = lines.findIndex(l => l.includes('Không tìm thấy lá bài trên tay'));
console.log(lines.slice(Math.max(0, match - 20), match + 20).join('\n'));
