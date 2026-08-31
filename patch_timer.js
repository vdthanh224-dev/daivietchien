const fs = require('fs');
let code = fs.readFileSync('deno-server/gameEngine.js', 'utf8');

const regex = /const elapsed = Math\.floor\(\(Date\.now\(\) - state\.timerStartAt\) \/ 1000\);[\s\S]*?if \(state\.waitingTargetSeat > 0\)/;
const replaceStr = `const elapsed = Math.floor((Date.now() - state.timerStartAt) / 1000);
  const newTimer = Math.max(0, 40 - elapsed);
  
  if (state.waitingTargetSeat > 0) {
    if (state.waitingTimer !== newTimer) {
       state.waitingTimer = newTimer;
       changed = true;
       if (newTimer % 5 === 0) important = true; // Sync UI every 5s
    }`;

if (regex.test(code)) {
    code = code.replace(regex, replaceStr);
    fs.writeFileSync('deno-server/gameEngine.js', code);
    console.log("Patched timer logic in gameEngine.js");
} else {
    console.log("Target not found");
}
