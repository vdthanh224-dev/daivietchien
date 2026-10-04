// Mode rules contain table-level configuration only. Card behavior stays in
// the card registry and game engine so it can be reused by every mode.
const MODE_RULES = Object.freeze({
  "2v2": Object.freeze({
    id: "2v2",
    minPlayers: 4,
    maxPlayers: 4,
    deckSize: 80,
    victory: "LAST_TEAM_STANDING",
    teamForSeat: (seat) => Number(seat) % 2 === 1 ? "dragon" : "phoenix",
    isAllyForSeat: (seat) => Number(seat) % 2 === 1,
    teamLabel: (teamId) => teamId === "dragon" ? "Phe Rồng (Đội 1)" : "Phe Phượng (Đội 2)"
  }),
  "ffa_4": Object.freeze({
    id: "ffa_4",
    minPlayers: 4,
    maxPlayers: 4,
    deckSize: 80,
    victory: "LAST_PLAYER_STANDING",
    teamForSeat: (seat) => `seat:${Number(seat)}`,
    isAllyForSeat: () => false,
    teamLabel: () => ""
  }),
  "ffa_8": Object.freeze({
    id: "ffa_8",
    minPlayers: 8,
    maxPlayers: 8,
    deckSize: 150,
    victory: "LAST_PLAYER_STANDING",
    teamForSeat: (seat) => `seat:${Number(seat)}`,
    isAllyForSeat: () => false,
    teamLabel: () => ""
  }),
  "4v4": Object.freeze({
    id: "4v4",
    minPlayers: 8,
    maxPlayers: 8,
    deckSize: 150,
    victory: "LAST_TEAM_STANDING",
    teamForSeat: (seat) => Number(seat) % 2 === 1 ? "dragon" : "phoenix",
    isAllyForSeat: (seat) => Number(seat) % 2 === 1,
    teamLabel: (teamId) => teamId === "dragon" ? "Phe Rồng (Đội 1)" : "Phe Phượng (Đội 2)"
  }),
  "dynasty_5": Object.freeze({
    id: "dynasty_5", minPlayers: 5, maxPlayers: 5, deckSize: 100,
    victory: "DYNASTY_ROLES",
    roleDistribution: ["KING", "LOYALIST", "REBEL", "REBEL", "SPY"],
    teamForSeat: () => "dynasty",
    isAllyForSeat: (seat) => Number(seat) === 1,
    teamLabel: () => "Vương Triều"
  }),
  "dynasty_8": Object.freeze({
    id: "dynasty_8", minPlayers: 8, maxPlayers: 8, deckSize: 150,
    victory: "DYNASTY_ROLES",
    roleDistribution: ["KING", "LOYALIST", "REBEL", "REBEL", "SPY", "LOYALIST", "REBEL", "REBEL"],
    teamForSeat: () => "dynasty",
    isAllyForSeat: (seat) => Number(seat) === 1,
    teamLabel: () => "Vương Triều"
  })
});

export function getModeRules(modeId = "2v2") {
  return MODE_RULES[String(modeId)] || null;
}

export function requireModeRules(modeId = "2v2") {
  const rules = getModeRules(modeId);
  if (!rules) throw new Error(`Chế độ chơi không hợp lệ: ${modeId}`);
  return rules;
}

export function getModeSeatOrder(state) {
  return (state?.players || [])
    .map((player) => Number(player?.seat))
    .filter(Number.isInteger)
    .sort((left, right) => left - right);
}
