const fs = require('fs');
let code = fs.readFileSync('Assets/Scripts/Battle2v2UI.cs', 'utf8');

if (!code.includes('private int lastProcessedActionSeq = 0;')) {
    const classRegex = /public class Battle2v2UI : MonoBehaviour\s*\{/;
    code = code.replace(classRegex, "public class Battle2v2UI : MonoBehaviour\n    {\n    private int lastProcessedActionSeq = 0;");
    fs.writeFileSync('Assets/Scripts/Battle2v2UI.cs', code);
    console.log("Added lastProcessedActionSeq to class");
} else {
    console.log("lastProcessedActionSeq already defined");
}
