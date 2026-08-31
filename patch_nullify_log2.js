const fs = require('fs');
let code = fs.readFileSync('deno-server/gameEngine.js', 'utf8');

const regex = /Đang hỏi Ghế \$\{newQuerySeats\[0\]\} \(40s\)\.\.\./;
const replaceStr = `Đang chờ người chơi phản hồi tiếp theo (40s)...`;

if (regex.test(code)) {
    code = code.replace(regex, replaceStr);
    fs.writeFileSync('deno-server/gameEngine.js', code);
    console.log("Patched NULLIFY_PLAYED log message");
} else {
    console.log("Target not found");
}
