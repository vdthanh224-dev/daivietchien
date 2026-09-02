const fs = require('fs');
let code = fs.readFileSync('Assets/Scripts/Battle2v2UI.cs', 'utf8');

const targetStr = `    private bool CanActAsSlash(GeneralCardUI g, CardModel c)
    {
        if (c == null) return false;
        if (g != null && g.HeroId == "HERO_1" && g.IsSkillActive("Chế Nỏ") && c.suit == CardSuit.Spade) return true;
        return IsSlashCard(c);
    }`;
const replacement = `    private bool CanActAsSlash(GeneralCardUI g, CardModel c)
    {
        if (c == null) return false;
        return IsSlashCard(c);
    }`;

let nCode = code.replace(/\r\n/g, '\n');
let nTarget = targetStr.replace(/\r\n/g, '\n');

if (nCode.includes(nTarget)) {
    nCode = nCode.replace(nTarget, replacement);
    fs.writeFileSync('Assets/Scripts/Battle2v2UI.cs', nCode, 'utf8');
    console.log('SUCCESS: CanActAsSlash FIX');
} else {
    console.log('FAILED TO FIND CanActAsSlash STRING');
}
