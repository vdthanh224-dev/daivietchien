const fs = require('fs');
let code = fs.readFileSync('Assets/Scripts/Battle2v2UI.cs', 'utf8');
code = code.replace(
  'SetLog("⚠️ <color=#FF5555><b>BẠN BỊ TẤN CÔNG BẰNG ĐÒN TRẢM!</b></color> Hãy chọn lá [ĐỠ] hoặc bấm [KHÔNG NÉ]. (Thời gian: 40s)");',
  'SetLog("⚠️ <color=#FF5555><b>BẠN BỊ TẤN CÔNG BẰNG ĐÒN TRẢM!</b></color> " + (hasHolyCannon ? Phải dùng lá ĐỠ khác chất  : "Hãy chọn lá [ĐỠ] hoặc bấm [KHÔNG NÉ].") + " (Thời gian: 40s)");'
);
fs.writeFileSync('Assets/Scripts/Battle2v2UI.cs', code);
