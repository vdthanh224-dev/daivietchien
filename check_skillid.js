const fs = require('fs');
let code = fs.readFileSync('Assets/Scripts/AppwriteMatchmaking.cs', 'utf8');

const regex = /public string skillId;/g;
if (regex.test(code)) {
    console.log("skillId exists in AppwriteMatchmaking.cs");
}
