const fs = require('fs');
let code = fs.readFileSync('Assets/Scripts/Battle2v2UI.cs', 'utf8');
code = code.replace(
  "titleTxt.resizeTextMaxSize = 24;",
  "titleTxt.resizeTextMaxSize = 30;"
);
code = code.replace(
  "qTxt.resizeTextMaxSize = 20;",
  "qTxt.resizeTextMaxSize = 26;"
);
fs.writeFileSync('Assets/Scripts/Battle2v2UI.cs', code);
