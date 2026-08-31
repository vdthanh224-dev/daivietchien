const fs = require('fs');
let code = fs.readFileSync('deno-server/gameEngine.js', 'utf8');

const regex = /Đang hỏi <b\>\$\{firstQueriedGen \? firstQueriedGen\.generalName : 'Ghế ' \+ querySeats\[0\]\}<\/b> có dùng Diệu Kế Phá Mưu không/;
const replaceStr = `Đang chờ người chơi phản hồi có dùng Diệu Kế Phá Mưu không`;

if (regex.test(code)) {
    code = code.replace(regex, replaceStr);
    fs.writeFileSync('deno-server/gameEngine.js', code);
    console.log("Patched NULLIFY_START log message");
} else {
    console.log("Target not found");
}
