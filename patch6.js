const fs = require('fs');
let code = fs.readFileSync('deno-server/gameEngine.js', 'utf8');

const targetStr = `        if (chain.continuation?.type === "CONTINUE_HARVEST") {
          state.harvestPickers.shift();
          beginNextHarvestPicker(state);
          refreshLastDelta(state);
          return { success: true, state };
        }`;
const replacement = `        if (chain.continuation?.type === "CONTINUE_HARVEST") {
          beginNextHarvestPicker(state);
          refreshLastDelta(state);
          return { success: true, state };
        }`;

let nCode = code.replace(/\r\n/g, '\n');
let nTarget = targetStr.replace(/\r\n/g, '\n');

if (nCode.includes(nTarget)) {
    nCode = nCode.replace(nTarget, replacement);
    fs.writeFileSync('deno-server/gameEngine.js', nCode, 'utf8');
    console.log('SUCCESS: NULLIFY SHIFT FIX');
} else {
    console.log('FAILED TO FIND NULLIFY SHIFT STRING');
}
