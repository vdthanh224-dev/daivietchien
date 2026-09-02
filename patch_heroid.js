const fs = require('fs');
let code = fs.readFileSync('Assets/Scripts/Battle2v2UI.cs', 'utf8');

const t1 = `                        if (playerCard != null && playerCard.HeroId == "HERO_1") {`;
const rep1 = `                        if (playerCard != null && playerCard.HeroId == "1") {`;

const t2 = `        if (playerCard.HeroId == "HERO_1") { // Cao Lỗ`;
const rep2 = `        if (playerCard.HeroId == "1") { // Cao Lỗ`;

const t3 = `        if (string.IsNullOrEmpty(currentRoomId) || playerCard == null || playerCard.HeroId != "HERO_1") return;`;
const rep3 = `        if (string.IsNullOrEmpty(currentRoomId) || playerCard == null || playerCard.HeroId != "1") return;`;

const t4 = `        } else if (playerCard.HeroId == "HERO_4") { // Lê Chân`;
const rep4 = `        } else if (playerCard.HeroId == "4") { // Lê Chân`;

const t5 = `        if (string.IsNullOrEmpty(currentRoomId) || playerCard == null || playerCard.HeroId != "HERO_4") return;`;
const rep5 = `        if (string.IsNullOrEmpty(currentRoomId) || playerCard == null || playerCard.HeroId != "4") return;`;

const t6 = `        if (g != null && g.HeroId == "HERO_1" && g.IsSkillActive("Chế Nỏ") && c.suit == CardSuit.Spade) return true;`;
const rep6 = `        if (g != null && g.HeroId == "1" && g.IsSkillActive("Chế Nỏ") && c.suit == CardSuit.Spade) return true;`;

const t7 = `        if (victim.heroId === "HERO_3") {`;
const rep7 = `        if (victim.heroId === "3" || victim.heroId === 3) {`;

code = code.replace(t1, rep1).replace(t2, rep2).replace(t3, rep3).replace(t4, rep4).replace(t5, rep5).replace(t6, rep6);

fs.writeFileSync('Assets/Scripts/Battle2v2UI.cs', code, 'utf8');
console.log('SUCCESS: UI Hero ID FIX');
