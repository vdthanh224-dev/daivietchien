const fs = require('fs');
let code = fs.readFileSync('Assets/Scripts/Battle2v2UI.cs', 'utf8');

code = code.replace(/new Vector2\(270f, 42f\), new Vector2\(-140f, 24f\)/, 'new Vector2(300f, 50f), new Vector2(-170f, 35f)');
code = code.replace(/new Vector2\(230f, 42f\), new Vector2\(150f, 16f\)/, 'new Vector2(250f, 50f), new Vector2(170f, 35f)');

fs.writeFileSync('Assets/Scripts/Battle2v2UI.cs', code, 'utf8');
console.log('SUCCESS: Nullify Buttons Regex');
