const fs = require('fs');
let code = fs.readFileSync('deno-server/gameEngine.js', 'utf8');

const useSkillCode = 
export function handleUseSkill(state, seat, skillId, targetSeat = 0) {
  if (state.status === "FINISHED") return { error: "Trận đấu đã kết thúc" };
  seat = Number(seat);
  const player = state.players.find(p => p.seat === seat);
  if (!player || player.hp <= 0) return { error: "Người chơi không hợp lệ" };

  if (state.phase !== "PLAY" || state.turnSeat !== seat) return { error: "Chỉ được dùng kỹ năng trong lượt của bạn" };

  if (skillId === "Triều Dâng") {
      if (player.usedSkills && player.usedSkills["Triều Dâng"]) return { error: "Kỹ năng Triều Dâng chỉ được dùng 1 lần mỗi lượt" };
      
      const target = state.players.find(p => p.seat === targetSeat);
      if (!target) return { error: "Mục tiêu không hợp lệ" };
      if (target.seat === seat) return { error: "Không thể chọn bản thân" };
      
      const options = [];
      (target.equipments || []).forEach(c => {
          options.push({ token: "equip_" + c.id, zone: "EQUIP", label: "Trang bị", card: c });
      });
      if (options.length === 0) return { error: "Mục tiêu không có trang bị để hủy" };
      
      if (!player.usedSkills) player.usedSkills = {};
      player.usedSkills["Triều Dâng"] = true;

      state.phase = "AWAIT_TARGET_CARD";
      state.targetCardSelection = {
        chooserSeat: seat,
        targetSeat: targetSeat,
        operation: "DESTROY",
        effectType: "TRIEU_DANG",
        options: options
      };
      state.waitingTargetSeat = seat;
      state.waitingReactionType = "TARGET_CARD";
      state.waitingTimer = 40;

      recordAction(state, {
        type: "USE_SKILL",
        casterSeat: seat,
        targetSeat: targetSeat,
        description: "🌊 <b>" + player.generalName + "</b> phát động [Triều Dâng] nhằm vào <b>" + target.generalName + "</b>!"
      });
      refreshLastDelta(state);
      return { success: true, state };
  }

  return { error: "Kỹ năng không hợp lệ hoặc chưa được hỗ trợ" };
}
;

code = code.replace('export function handleToggleSkill', useSkillCode + '\nexport function handleToggleSkill');
fs.writeFileSync('deno-server/gameEngine.js', code);
