const fs = require('fs');
let code = fs.readFileSync('deno-server/gameEngine.js', 'utf8');
code = code.replace(
  'type: "TOGGLE_SKILL",\n    casterSeat: seat,\n    description: "⚔️ <b>" + player.generalName + "</b> " + (player.activeSkills[skillId] ? "bật" : "tắt") + " tuyệt kỹ <b>[" + skillId + "]</b>."\n  });\n\n  return { success: true, state };',
  'type: "TOGGLE_SKILL",\n    casterSeat: seat,\n    description: "⚔️ <b>" + player.generalName + "</b> " + (player.activeSkills[skillId] ? "bật" : "tắt") + " tuyệt kỹ <b>[" + skillId + "]</b>."\n  });\n\n  refreshLastDelta(state);\n  return { success: true, state };'
);
fs.writeFileSync('deno-server/gameEngine.js', code);
