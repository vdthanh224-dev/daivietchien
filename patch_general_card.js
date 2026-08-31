const fs = require('fs');
let code = fs.readFileSync('Assets/Scripts/GeneralCardUI.cs', 'utf8');

const regex = /public string\[\] ActiveSkillsKeys;[\s\S]*?public bool\[\] ActiveSkillsValues;/;
const replaceStr = `public string[] ActiveSkillsKeys;
    public bool[] ActiveSkillsValues;
    public string[] UsedSkillsKeys;
    public bool[] UsedSkillsValues;
    
    public bool HasUsedSkill(string skillId)
    {
        if (UsedSkillsKeys == null || UsedSkillsValues == null) return false;
        for (int i = 0; i < UsedSkillsKeys.Length; i++)
        {
            if (UsedSkillsKeys[i] == skillId) return i < UsedSkillsValues.Length && UsedSkillsValues[i];
        }
        return false;
    }`;

code = code.replace(regex, replaceStr);
fs.writeFileSync('Assets/Scripts/GeneralCardUI.cs', code);
console.log('Patched GeneralCardUI.cs');
