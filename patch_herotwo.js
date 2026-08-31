const fs = require('fs');
let code = fs.readFileSync('deno-server/gameEngine.js', 'utf8');

const regex = /function hasWeaponRange\(\w+,\s*\w+,\s*\w+\)[\s\S]*?^}/m;
const replaceStr = `function hasWeaponRange(state, fromSeat, toSeat) {
  const from = state.players.find((player) => player.seat === fromSeat);
  if (!from) return false;
  const weapon = (from.equipments || []).find((equipment) => equipment.subType === CARD_SUBTYPES.WEAPON);
  const range = weapon && Number.isFinite(Number(weapon.range)) ? Number(weapon.range) : 1;
  let distance = getDistance(state, fromSeat, toSeat);
  if (from.heroId === "HERO_2") { // Đào Hãn
    distance -= 2;
  }
  return distance <= range;
}`;

if (regex.test(code)) {
    code = code.replace(regex, replaceStr);
    fs.writeFileSync('deno-server/gameEngine.js', code);
    console.log("Patched hasWeaponRange for HERO_2");
} else {
    console.log("Target not found");
}
