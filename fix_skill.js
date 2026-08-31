const fs = require('fs');
let code = fs.readFileSync('Assets/Scripts/Battle2v2UI.cs', 'utf8');

code = code.replace(
  /private void OnPlayerSkillCheNoClicked\(\)\s*\{\s*return;\s*\}/,
  private void OnPlayerSkillCheNoClicked()
    {
        if (string.IsNullOrEmpty(currentRoomId) || playerCard == null || playerCard.Data == null || playerCard.Data.id != "HERO_1") return;

        DispatchGameEngineAction(new AppwriteMatchmaking.GameActionPayload
        {
            action = "TOGGLE_SKILL",
            roomId = currentRoomId,
            seat = playerCard.SeatNumber,
            skillId = "Chế Nỏ"
        }, (s) => { if (s != null) ApplyServerGameState(s); });
    }
);

fs.writeFileSync('Assets/Scripts/Battle2v2UI.cs', code);
