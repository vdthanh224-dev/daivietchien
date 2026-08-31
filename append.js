export function handleToggleSkill(state, seat, skillId) {
  seat = Number(seat);
  const player = state.players.find(p => p.seat === seat);
  if (!player || player.hp <= 0) return { error: "Người chơi không hợp lệ" };

  if (!player.activeSkills) player.activeSkills = {};
  player.activeSkills[skillId] = !player.activeSkills[skillId];

  recordAction(state, {
    type: "TOGGLE_SKILL",
    casterSeat: seat,
    description: "⚔️ <b>" + player.generalName + "</b> " + (player.activeSkills[skillId] ? "bật" : "tắt") + " tuyệt kỹ <b>[" + skillId + "]</b>."
  });

  return { success: true, state };
}
