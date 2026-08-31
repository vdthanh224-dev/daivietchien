const fs = require('fs');
let code = fs.readFileSync('Assets/Scripts/Battle2v2UI.cs', 'utf8');

const regex = /if \(playerCard\.Data\.id == "HERO_1"\) \{ \/\/ Cao Lỗ[\s\S]*?\} else \{\s*playerCard\.SkillButtonGo\.SetActive\(false\);\s*\}/;

const replaceStr = `if (playerCard.Data.id == "HERO_1") { // Cao Lỗ
            bool isSkillActive = playerCard.IsSkillActive("Chế Nỏ");
            playerCard.SkillButtonGo.SetActive(hasSpade || isSkillActive);
            var btnText = playerCard.SkillButtonGo.GetComponentInChildren<UnityEngine.UI.Text>();
            if (btnText != null) btnText.text = isSkillActive ? "HỦY CHẾ NỎ" : "CHẾ NỎ";
            
            var btnImg = playerCard.SkillButtonGo.GetComponent<UnityEngine.UI.Image>();
            if (btnImg != null) btnImg.color = isSkillActive ? new UnityEngine.Color(1f, 0.4f, 0.4f, 1f) : new UnityEngine.Color(1f, 0.8f, 0.2f, 1f);
            
            playerCard.SkillButton.onClick.AddListener(OnPlayerSkillCheNoClicked);
        } else if (playerCard.Data.id == "HERO_4") { // Lê Chân
            bool hasUsed = playerCard.HasUsedSkill("Triều Dâng");
            bool isMyTurn = currentAuthoritativePhase == "PLAY" && currentAuthoritativeTurnSeat == playerCard.SeatNumber;
            playerCard.SkillButtonGo.SetActive(isMyTurn && !hasUsed);
            
            var btnText = playerCard.SkillButtonGo.GetComponentInChildren<UnityEngine.UI.Text>();
            if (btnText != null) btnText.text = "TRIỀU DÂNG";
            
            var btnImg = playerCard.SkillButtonGo.GetComponent<UnityEngine.UI.Image>();
            if (btnImg != null) btnImg.color = new UnityEngine.Color(0.2f, 0.6f, 1f, 1f); // Blue
            
            playerCard.SkillButton.onClick.AddListener(OnPlayerSkillTrieuDangClicked);
        } else {
            playerCard.SkillButtonGo.SetActive(false);
        }`;

if (regex.test(code)) {
    code = code.replace(regex, replaceStr);
    fs.writeFileSync('Assets/Scripts/Battle2v2UI.cs', code);
    console.log("Patched UpdatePlayerSkillButtonState");
} else {
    console.log("Target not found");
}
