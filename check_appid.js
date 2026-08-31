const fs = require('fs');
let code = fs.readFileSync('Assets/Scripts/AppwriteMatchmaking.cs', 'utf8');

const regex = /public string skillId;/;
if (regex.test(code)) {
    console.log("skillId present");
} else {
    console.log("skillId NOT present");
}
