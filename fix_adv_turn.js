const fs = require('fs');
let code = fs.readFileSync('deno-server/gameEngine.js', 'utf8');

code = code.replace(
  'if (previousPlayer) previousPlayer.isWineBuffActive = false;',
  'if (previousPlayer) { previousPlayer.isWineBuffActive = false; previousPlayer.usedSkills = {}; }'
);

code = code.replace(
  'activeSkillsValues: p.activeSkills ? Object.values(p.activeSkills) : [],',
  'activeSkillsValues: p.activeSkills ? Object.values(p.activeSkills) : [],\n        usedSkillsKeys: p.usedSkills ? Object.keys(p.usedSkills) : [],\n        usedSkillsValues: p.usedSkills ? Object.values(p.usedSkills) : [],'
);

fs.writeFileSync('deno-server/gameEngine.js', code);
