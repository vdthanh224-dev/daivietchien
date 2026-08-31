const fs = require('fs');
let code = fs.readFileSync('deno-server/gameEngine.js', 'utf8');

const regex = /const publicTargetName = option\.zone === "HAND" \? "lá úp trên tay" : card\.name;/;
const replaceStr = `const publicTargetName = option.zone === "HAND" ? "lá úp trên tay" : formatCardText(card);`;

if (regex.test(code)) {
    code = code.replace(regex, replaceStr);
    fs.writeFileSync('deno-server/gameEngine.js', code);
    console.log("Patched publicTargetName in completeTargetCardSelection");
} else {
    console.log("Target not found");
}
