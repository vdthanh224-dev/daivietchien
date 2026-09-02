const fs = require('fs');
let code = fs.readFileSync('Assets/Scripts/Battle2v2UI.cs', 'utf8');

// 1. Chế Nỏ target
const cheNoTarget = 'return cm;\r\n        }\r\n\r\n        CardSuit suit = CardSuit.Spade;';
const cheNoTarget2 = 'return cm;\n        }\n\n        CardSuit suit = CardSuit.Spade;';
const cheNoRep = `            if (playerCard != null && playerCard.HeroId == "HERO_1") {\n                bool isCheNo = playerCard.IsSkillActive("Chế Nỏ");\n                if (isCheNo && cm.suit == CardSuit.Spade && cm.subType != CardSubType.Weapon) {\n                    return new CardModel { \n                        id = cm.id, \n                        cardName = "Nỏ Thần Kim Quy", \n                        suit = cm.suit, \n                        rank = cm.rank, \n                        subType = CardSubType.Weapon, \n                        category = CardCategory.Equipment, \n                        iconPath = "UI/icon_weapon", \n                        description = "Tầm 1. Không giới hạn số Trảm trong lượt" \n                    };\n                }\n            }\n            return cm;\n        }\n\n        CardSuit suit = CardSuit.Spade;`;

if (code.includes(cheNoTarget)) code = code.replace(cheNoTarget, cheNoRep);
else if (code.includes(cheNoTarget2)) code = code.replace(cheNoTarget2, cheNoRep);

// 2. Triều dâng target
const trieuDangTarget = 'currentSelectedTarget = clicked;\r\n        AudioManager.Instance.PlayCardSelect();\r\n\r\n        if (targetHighlightGo == null)';
const trieuDangTarget2 = 'currentSelectedTarget = clicked;\n        AudioManager.Instance.PlayCardSelect();\n\n        if (targetHighlightGo == null)';
const trieuDangRep = `currentSelectedTarget = clicked;\n        AudioManager.Instance.PlayCardSelect();\n\n        // Kích hoạt Triều Dâng luôn nếu đang bật mode\n        if (isWaitingForTrieuDangTarget) {\n            isWaitingForTrieuDangTarget = false;\n            OnPlayerSkillTrieuDangClicked();\n            return;\n        }\n\n        if (targetHighlightGo == null)`;

if (code.includes(trieuDangTarget)) code = code.replace(trieuDangTarget, trieuDangRep);
else if (code.includes(trieuDangTarget2)) code = code.replace(trieuDangTarget2, trieuDangRep);

const tdAlertTarget = 'SetLog("⚠️ Hãy chọn một mục tiêu đối phương (có trang bị) trŰ÷c khi dùng Triều Dâng.");\r\n            return;\r\n        }\r\n\r\n        if (IsSameTeamSeat(playerCard.SeatNumber, currentSelectedTarget.SeatNumber)) {\r\n            SetLog("⚠️ Kỹ năng Triều Dâng phải chộ định kẻ đôch.");\r\n            return;\r\n        }';
const tdAlertTarget2 = 'SetLog("⚠️ Hãy chọn một mục tiêu đối phương (có trang bị) trước khi dùng Triều Dâng.");\n            return;\n        }\n\n        if (IsSameTeamSeat(playerCard.SeatNumber, currentSelectedTarget.SeatNumber)) {\n            SetLog("⚠️ Kỹ năng Triều Dâng phải chỉ định kẻ địch.");\n            return;\n        }';
let tdAlertRep = `isWaitingForTrieuDangTarget = true;\n            SetLog("🌊 Đã chọn [Trieu Dâng]. Hãy chạm chọn 1 mục tiêu có trang bị trên bàn để hủy!");\n            return;\n        }\n\n        if (IsSameTeamSeat(playerCard.SeatNumber, currentSelectedTarget.SeatNumber)) {\n            SetLog("⚠️ Kỹ năng Triều Dâng có thể chỉ định kẻ địch (khuyên dùng) nhưng có thể chỉ định đồng minh.");\n        }`;

if (code.includes(tdAlertTarget)) code = code.replace(tdAlertTarget, tdAlertRep);
else if (code.includes(tdAlertTarget2)) code = code.replace(tdAlertTarget2, tdAlertRep);

// 3. UI Counter Waiting / Prompt text fixes
code = code.replace(/qTxt\\.horizontalOverflow = HorizontalWrapMode\\.Wrap; \\r?\\nqTxt\\.verticalOverflow = VerticalWrapMode\\.Overflow;\\r?\\nqTxt\\.resizeTextForBestFit = false;/g, `aTxt.horizontalOverflow = HorizontalWrapMode.Wrap; \n        qTxt.verticalOverflow = VerticalWrapMode.Overflow;\n        qTxt.resizeTextForBestFit = true;\n        qTxt.resizeTextMinSize = 16;\n        qTxt.resizeTextMaxSize = 36; `);

const regexText = /string qText = !isCurrentlyCanceled\\r?\\n\\s*\\? \\$"Có dùng Diệu Kế Phá M�u để ngăn chặn\\\\n{casterDesc}{GetFormattedCardName\(rootCard\)}{targetDesc} không?"\\r?\\n\\s*: \\$"Có dùng Diệu Kế Phá M�u đễ phá giải Diệu Kế của đối phương\\\\nn���m vào {GetFormattedCardName\(rootCard\)}{targetDesc} không?";/g;
const newQText = `var nullifierGen = state.activeCard.nullifyBySeat > 0 ? GetGeneralBySeat(state.activeCard.nullifyBySeat) : null;\n                    string nullifierDesc = nullifierGen != null ? $"#{nullifierGen.SeatNumber} ({nullifierGen.GeneralName})" : "đối phương";\n                    string qText = !isCurrentlyCanceled ? $"Có dùng Diệu Kế Phá Mưu để ngăn chặn\\n{casterDesc}{GetFormattedCardName(rootCard)}{targetDesc} không?" : $"Có dùng Diệu Kế Phá Mưu đễ phá giải Diệu Kế của " + nullifierDesc + "\\nđang bảo vệ cho {GetFormattedCardName(rootCard)}{targetDesc} không?";`;
code = code.replace(regexText, newQText);

// 4. Diệu kế condition for Targetable
const reqTarget = 'return CanActAsSlash(playerCard, c) || c.subType == CardSubType.Duel || c.subType == CardSubType.Snatch || c.subType == CardSubType.Dismantle || c.subType == CardSubType.SupplyShortage || c.subType == CardSubType.Acedia || c.subType == CardSubType.FlawlessDefense;';
const reqTargetRep = 'return CanActAsSlash(playerCard, c) || c.subType == CardSubType.Duel || c.subType == CardSubType.Snatch || c.subType == CardSubType.Dismantle || c.subType == CardSubType.SupplyShortage || c.subType == CardSubType.Acedia || c.subType == CardSubType.FlawlessDefense || (!string.IsNullOrEmpty(c.cardName) && c.cardName.Contains("Diệu Kế"));';
if (code.includes(reqTarget)) code = code.replace(reqTarget, reqTargetRep);

fs.writeFileSync('Assets/Scripts/Battle2v2UI.cs', code);
console.log('Restored all fixes.');