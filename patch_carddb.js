const fs = require('fs');
let code = fs.readFileSync('Assets/Scripts/CardDatabase.cs', 'utf8');

const targetStr = `list.Add(CreateCard("D1_S_Q", "Súng Thần Công Hồ Triều", CardSuit.Spade, CardRank.Queen, 1, CardCategory.Equipment, CardSubType.Weapon, "Tầm 5. Mục tiêu không được dùng Đỡ có cùng chất với Trảm của bạn.", "UI/icon_weapon", 5));`;
const replacement = `list.Add(CreateCard("D1_S_Q", "Súng Thần Công Hồ Triều", CardSuit.Spade, CardRank.Queen, 1, CardCategory.Equipment, CardSubType.Weapon, "Tầm 5. Mục tiêu phải dùng Đỡ có cùng chất với Trảm của bạn.", "UI/icon_weapon", 5));`;

let nCode = code.replace(/\r\n/g, '\n');
let nTarget = targetStr.replace(/\r\n/g, '\n');

if (nCode.includes(nTarget)) {
    nCode = nCode.replace(nTarget, replacement);
    fs.writeFileSync('Assets/Scripts/CardDatabase.cs', nCode, 'utf8');
    console.log('SUCCESS: CardDatabase FIX');
} else {
    console.log('FAILED TO FIND CardDatabase STRING');
}
