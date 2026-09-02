const fs = require('fs');
let code = fs.readFileSync('deno-server/gameEngine.js', 'utf8');

const targetStr = `      victim.hp = Math.min(victim.maxHp, Math.max(1, victim.hp + 1));
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

      const resume = resolveNearDeathResume(state);
      refreshLastDelta(state);
      return resume;`;

const replacement = `      victim.hp = Math.min(victim.maxHp, victim.hp + 1);
      
      if (victim.hp > 0) {
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

        const resume = resolveNearDeathResume(state);
        refreshLastDelta(state);
        return resume;
      } else {
        state.waitingTimer = 40;
        state.timerStartAt = Date.now();
        recordAction(state, {
          type: "RESCUE_ATTEMPT",
          casterSeat: respondentSeat,
          targetSeat: victim.seat,
          description: \`💮 <b>\${respondent.generalName}</b> đã dùng \${formatCardText(rescueCard)} cứu <b>\${victim.generalName}</b> nhưng vẫn còn (\${victim.hp}/\${victim.maxHp}) Máu!\`
        });
        refreshLastDelta(state);
        return { success: true, state };
      }`;

const normalizedCode = code.replace(/\r\n/g, '\n');
const normalizedTarget = targetStr.replace(/\r\n/g, '\n');

if (normalizedCode.includes(normalizedTarget)) {
    const newCode = normalizedCode.replace(normalizedTarget, replacement);
    fs.writeFileSync('deno-server/gameEngine.js', newCode, 'utf8');
    console.log('SUCCESS');
} else {
    console.log('FAILED TO FIND STRING');
}
