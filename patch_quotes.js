const fs = require('fs');
let code = fs.readFileSync('Assets/Scripts/Battle2v2UI.cs', 'utf8');

const regex = /\+ \(hasHolyCannon \? Phải dùng lá ĐỠ khác chất  : "Hãy chọn lá \[ĐỠ\] hoặc bấm \[KHÔNG NÉ\]\."\) \+/;
const replaceStr = `+ (hasHolyCannon ? "Phải dùng lá ĐỠ khác chất" : "Hãy chọn lá [ĐỠ] hoặc bấm [KHÔNG NÉ].") +`;

if (regex.test(code)) {
    code = code.replace(regex, replaceStr);
    fs.writeFileSync('Assets/Scripts/Battle2v2UI.cs', code);
    console.log("Patched missing quotes at 5661");
} else {
    console.log("Target not found");
}
