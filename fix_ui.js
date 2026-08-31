const fs = require('fs');
let code = fs.readFileSync('Assets/Scripts/Battle2v2UI.cs', 'utf8');
code = code.replace(
  "string qText = !isCurrentlyCanceled\r\n                        ? $\"Có dùng Diệu Kế Phá Mưu để ngăn chặn {casterDesc}{GetFormattedCardName(rootCard)}{targetDesc} không?\"\r\n                        : $\"Có dùng Diệu Kế Phá Mưu để phá giải Diệu Kế của người khác lên {GetFormattedCardName(rootCard)}{targetDesc} không?\";",
  "string qText = !isCurrentlyCanceled\r\n                        ? $\"Có dùng Diệu Kế Phá Mưu để ngăn chặn\\n{casterDesc}{GetFormattedCardName(rootCard)}{targetDesc} không?\"\r\n                        : $\"Có dùng Diệu Kế Phá Mưu để phá giải Diệu Kế của đối phương\\nnhằm vào {GetFormattedCardName(rootCard)}{targetDesc} không?\";"
);
fs.writeFileSync('Assets/Scripts/Battle2v2UI.cs', code);
