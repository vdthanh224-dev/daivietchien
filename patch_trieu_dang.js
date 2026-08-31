const fs = require('fs');
let code = fs.readFileSync('Assets/Scripts/Battle2v2UI.cs', 'utf8');

const regex = /void OnPlayerSkillCheNoClicked\(\)[\s\S]*?^    }/m;
const match = code.match(regex);
if (match) {
    const appendStr = `
    void OnPlayerSkillTrieuDangClicked()
    {
        if (string.IsNullOrEmpty(currentRoomId) || playerCard == null || playerCard.Data == null || playerCard.Data.id != "HERO_4") return;

        if (currentSelectedTarget == null) {
            SetLog("⚠️ Hãy chọn một mục tiêu đối phương (có trang bị) trước khi dùng Triều Dâng.");
            return;
        }

        if (IsSameTeamSeat(playerCard.SeatNumber, currentSelectedTarget.SeatNumber)) {
            SetLog("⚠️ Kỹ năng Triều Dâng phải chỉ định kẻ địch.");
            return;
        }

        DispatchGameEngineAction(new AppwriteMatchmaking.GameActionPayload
        {
            action = "USE_SKILL",
            roomId = currentRoomId,
            seat = playerCard.SeatNumber,
            skillId = "Triều Dâng",
            targetSeat = currentSelectedTarget.SeatNumber
        }, (s) => { if (s != null) ApplyServerGameState(s); });
    }`;
    code = code.replace(regex, match[0] + '\n' + appendStr);
    fs.writeFileSync('Assets/Scripts/Battle2v2UI.cs', code);
    console.log("Patched OnPlayerSkillTrieuDangClicked");
} else {
    console.log("Target not found");
}
