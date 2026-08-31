const fs = require('fs');
let code = fs.readFileSync('deno-server/server.js', 'utf8');
code = code.replace(
  'handleRespondAction,',
  'handleRespondAction,\n  handleToggleSkill,'
);
code = code.replace(
  'if (payload.action === "PLAY_CARD") {',
  'if (payload.action === "TOGGLE_SKILL") {\n      return handleToggleSkill(state, seat, payload.skillId);\n    }\n    if (payload.action === "PLAY_CARD") {'
);
fs.writeFileSync('deno-server/server.js', code);
