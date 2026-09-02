const fs = require('fs');
let code = fs.readFileSync('Assets/Scripts/Battle2v2UI.cs', 'utf8');

const t1 = `SetLog("⚠️ <color=#FF5555><b>BẠN BỊ TẤN CÔNG BẰNG ĐÒN TRẢM!</b></color> " + (hasHolyCannon ? "Phải dùng lá ĐỠ khác chất" : "Hãy chọn lá [ĐỠ] hoặc bấm [KHÔNG NÉ].") + " (Thời gian: 40s)");`;
const rep1 = `SetLog("⚠️ <color=#FF5555><b>BẠN BỊ TẤN CÔNG BẰNG ĐÒN TRẢM!</b></color> " + (hasHolyCannon ? "Phải dùng lá ĐỠ cùng chất" : "Hãy chọn lá [ĐỠ] hoặc bấm [KHÔNG NÉ].") + " (Thời gian: 40s)");`;

const t2 = `var legalDodge = hand.Find(c => c.subType == CardSubType.Dodge && (!hasHolyCannon || c.suit != card.suit));`;
const rep2 = `var legalDodge = hand.Find(c => c.subType == CardSubType.Dodge && (!hasHolyCannon || c.suit == card.suit));`;

const t3 = `var legalDodge = hand.Find(c => c.subType == CardSubType.Dodge && (!hasHolyCannon || c.suit != chosenSlashCard.suit));`;
const rep3 = `var legalDodge = hand.Find(c => c.subType == CardSubType.Dodge && (!hasHolyCannon || c.suit == chosenSlashCard.suit));`;

const t4 = `playerHandUI.HighlightOnlyMatching(c => c != null && CanActAsDodge(playerCard, c) && (!hasHolyCannon || c.suit != slashCard.suit));`;
const rep4 = `playerHandUI.HighlightOnlyMatching(c => c != null && CanActAsDodge(playerCard, c) && (!hasHolyCannon || c.suit == slashCard.suit));`;

code = code.replace(t1, rep1).replace(t2, rep2).replace(t3, rep3).replace(t4, rep4);
fs.writeFileSync('Assets/Scripts/Battle2v2UI.cs', code, 'utf8');
console.log('SUCCESS: Súng Thần Công UI FIX');
