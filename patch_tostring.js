const fs = require('fs');
let code = fs.readFileSync('Assets/Scripts/GeneralCardUI.cs', 'utf8');

const regex = /return heroData != null \? heroData\.id : "";/;
const replaceStr = `return heroData != null ? heroData.id.ToString() : "";`;

if (regex.test(code)) {
    code = code.replace(regex, replaceStr);
    fs.writeFileSync('Assets/Scripts/GeneralCardUI.cs', code);
    console.log("Patched heroData.id.ToString()");
} else {
    console.log("Not found");
}
