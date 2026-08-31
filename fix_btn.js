const fs = require('fs');
let code = fs.readFileSync('Assets/Scripts/Battle2v2UI.cs', 'utf8');

code = code.replace(
  /public void UpdatePlayerSkillButtonState\(\)\s*\{\s*if \(playerCard == null \|\| playerCard\.SkillButtonGo == null\) return;\s*playerCard\.SkillButton\.onClick\.RemoveAllListeners\(\);\s*playerCard\.SkillButtonGo\.SetActive\(false\);\s*\}/,
  public void UpdatePlayerSkillButtonState()
    {
        if (playerCard == null || playerCard.SkillButtonGo == null || playerCard.Data == null) return;
        playerCard.SkillButton.onClick.RemoveAllListeners();
        
        bool hasSpade = false;
        if (playerHandCards != null) {
            foreach(var c in playerHandCards) {
                if (c != null && c.suit == CardSuit.Spade && c.subType != CardSubType.Weapon) {
                    hasSpade = true;
                    break;
                }
            }
        }
        
        if (playerCard.Data.id == "HERO_1") { // Cao Lỗ
            bool isSkillActive = playerCard.IsSkillActive("Chế Nỏ");
            playerCard.SkillButtonGo.SetActive(hasSpade || isSkillActive);
            var btnText = playerCard.SkillButtonGo.GetComponentInChildren<UnityEngine.UI.Text>();
            if (btnText != null) btnText.text = isSkillActive ? "HỦY CHẾ NỎ" : "CHẾ NỎ";
            
            var btnImg = playerCard.SkillButtonGo.GetComponent<UnityEngine.UI.Image>();
            if (btnImg != null) btnImg.color = isSkillActive ? new UnityEngine.Color(1f, 0.4f, 0.4f, 1f) : new UnityEngine.Color(1f, 0.8f, 0.2f, 1f);
            
            playerCard.SkillButton.onClick.AddListener(OnPlayerSkillCheNoClicked);
        } else {
            playerCard.SkillButtonGo.SetActive(false);
        }
    }
);

fs.writeFileSync('Assets/Scripts/Battle2v2UI.cs', code);
