const fs = require('fs');
let code = fs.readFileSync('deno-server/gameEngine.js', 'utf8');

const t1 = `      const cannon = getEquippedWeapon(caster, "Súng Thần Công");
      const requiredDodgeText = cannon ? \` (yêu cầu lá Đỡ khác chất <b>\${card.suit === "Heart" ? "<color=#FF5555>♥</color>" : card.suit === "Diamond" ? "<color=#FF5555>♦</color>" : card.suit === "Club" ? "♣" : "♠"}</b>)\` : "";`;

const t2 = `      const holyCannon = getEquippedWeapon(caster, "Súng Thần Công");
      const idx = respondent.hand.findIndex(c => c.id === cardId && isDodge(c)
        && (!holyCannon || c.suit !== state.activeCard?.suit));`;

const t3 = `    const cannon = getEquippedWeapon(caster, "Súng Thần Công");
    const dodge = ai.hand.find(c => isDodge(c)
      && (!cannon || c.suit !== state.activeCard?.suit));`;

const rep1 = `      const cannon = getEquippedWeapon(caster, "Súng Thần Công");
      const requiredDodgeText = cannon ? \` (yêu cầu lá Đỡ cùng chất <b>\${card.suit === "Heart" ? "<color=#FF5555>♥</color>" : card.suit === "Diamond" ? "<color=#FF5555>♦</color>" : card.suit === "Club" ? "♣" : "♠"}</b>)\` : "";`;

const rep2 = `      const holyCannon = getEquippedWeapon(caster, "Súng Thần Công");
      const idx = respondent.hand.findIndex(c => c.id === cardId && isDodge(c)
        && (!holyCannon || c.suit === state.activeCard?.suit));`;

const rep3 = `    const cannon = getEquippedWeapon(caster, "Súng Thần Công");
    const dodge = ai.hand.find(c => isDodge(c)
      && (!cannon || c.suit === state.activeCard?.suit));`;

code = code.replace(t1, rep1).replace(t2, rep2).replace(t3, rep3);
fs.writeFileSync('deno-server/gameEngine.js', code, 'utf8');
console.log('SUCCESS: Súng Thần Công Engine FIX');
