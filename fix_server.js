const fs = require('fs');
let code = fs.readFileSync('deno-server/server.js', 'utf8');

code = code.replace(
  'if (payload.action === "TOGGLE_SKILL") {\n      return handleToggleSkill(state, seat, payload.skillId);\n    }',
  'if (payload.action === "USE_SKILL") {\n      return handleUseSkill(state, seat, payload.skillId, payload.targetSeat);\n    }\n    if (payload.action === "TOGGLE_SKILL") {\n      return handleToggleSkill(state, seat, payload.skillId);\n    }'
);
code = code.replace(
  'handleToggleSkill,',
  'handleUseSkill,\n  handleToggleSkill,'
);

fs.writeFileSync('deno-server/server.js', code);
