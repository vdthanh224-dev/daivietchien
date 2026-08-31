const fs = require('fs');
let code = fs.readFileSync('deno-server/gameEngine.js', 'utf8');

const regex = /else if \(state\.phase === "PLAY" && state\.turnSeat > 0\) \{/;
const replaceStr = `else if (state.phase === "PLAY" && state.turnSeat > 0) {
    if (state.turnTimer !== newTimer) {
       state.turnTimer = newTimer;
       changed = true;
       if (newTimer % 5 === 0) important = true; // Sync UI every 5s
    }`;

if (regex.test(code)) {
    code = code.replace(regex, replaceStr);
    fs.writeFileSync('deno-server/gameEngine.js', code);
    console.log("Patched turnTimer logic");
} else {
    console.log("Target not found");
}
