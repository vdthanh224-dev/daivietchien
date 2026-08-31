const fs = require('fs');
let code = fs.readFileSync('Assets/Scripts/Battle2v2UI.cs', 'utf8');

code = code.replace(
  /activeSkillsKeys = p\.activeSkillsKeys,/g,
  'activeSkillsKeys = p.activeSkillsKeys,\n                        usedSkillsKeys = p.usedSkillsKeys,\n                        usedSkillsValues = p.usedSkillsValues,'
);

code = code.replace(
  /g\.ActiveSkillsKeys = p\.activeSkillsKeys;/g,
  'g.ActiveSkillsKeys = p.activeSkillsKeys;\n                    g.UsedSkillsKeys = p.usedSkillsKeys;\n                    g.UsedSkillsValues = p.usedSkillsValues;'
);

fs.writeFileSync('Assets/Scripts/Battle2v2UI.cs', code);
console.log('Patched Battle2v2UI.cs for usedSkillsKeys');
