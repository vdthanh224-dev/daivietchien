const fs = require('fs');
const lines = fs.readFileSync('deno-server/server.js', 'utf8').split('\n');
console.log(lines.slice(400, 480).join('\n'));
