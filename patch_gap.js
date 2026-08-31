const fs = require('fs');
let code = fs.readFileSync('Assets/Scripts/AppwriteMatchmaking.cs', 'utf8');

const regex = /public class GameActionPayload\s*\{[\s\S]*?public string action;/;
const replaceStr = `public class GameActionPayload
    {
        public string action;
        public string skillId;`;

if (regex.test(code)) {
    code = code.replace(regex, replaceStr);
    fs.writeFileSync('Assets/Scripts/AppwriteMatchmaking.cs', code);
    console.log("Patched GameActionPayload");
} else {
    console.log("Target not found");
}
