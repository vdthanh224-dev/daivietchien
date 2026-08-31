const fs = require('fs');
let code = fs.readFileSync('deno-server/gameEngine.js', 'utf8');

const regex = /victim\.hp = Math\.min\(victim\.maxHp, Math\.max\(1, victim\.hp \+ 1\)\);[\s\S]*?const resume = resolveNearDeathResume\(state\);/;
const replaceStr = `victim.hp = Math.min(victim.maxHp, Math.max(1, victim.hp + 1));
      state.phase = "PLAY";
      state.waitingTargetSeat = 0;
      state.waitingTimer = 0;
      recordAction(state, {
        type: "RESCUE_SUCCESS",
        casterSeat: respondentSeat,
        targetSeat: victim.seat,
        description: \`💮 <b>\${respondent.generalName}</b> đã dùng \${formatCardText(rescueCard)} cứu sống <b>\${victim.generalName}</b> (\${victim.hp}/\${victim.maxHp})!\`
      });

      if (victim.heroId === "HERO_3") {
          drawCards(state, victim.seat, 2);
          recordAction(state, {
              type: "USE_SKILL",
              casterSeat: victim.seat,
              description: \`✨ <b>\${victim.generalName}</b> kích hoạt <color=#FFD700><b>Hịch Nghĩa</b></color>: Rút 2 lá bài khi thoát khỏi Cận Tử!\`
          });
      }

      const resume = resolveNearDeathResume(state);`;

if (regex.test(code)) {
    code = code.replace(regex, replaceStr);
    fs.writeFileSync('deno-server/gameEngine.js', code);
    console.log("Patched HERO_3 (Hịch Nghĩa) in gameEngine.js");
} else {
    console.log("Target not found for HERO_3");
}
