const fs = require('fs');
let code = fs.readFileSync('deno-server/gameEngine.js', 'utf8');

const regex = /if \(canAIReact && elapsed >= 2 && elapsed < 40\) \{[\s\S]*?return \{ changed: true, important \};\s*\}/;
if (regex.test(code)) {
    console.log(code.match(regex)[0]);
} else {
    console.log("Target not found");
}
