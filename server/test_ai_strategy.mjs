import assert from "node:assert/strict";
import { initGame, handleAIStep } from "./functions/game-engine/src/gameEngine.js";
import { CARD_CATEGORIES, CARD_SUBTYPES } from "./functions/game-engine/src/deck.js";

function slash(id = "ai-slash") {
  return { id, name: "Trảm", suit: "Spade", rank: 7, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.ATTACK_NORMAL };
}

function resetTurn(state, seat) {
  state.turnSeat = seat;
  state.phase = "PLAY";
  state.slashesUsedThisTurn = 0;
  state.turnDamageDealt = false;
  state.activeCard = null;
}

// The AI should finish a vulnerable enemy instead of attacking the first seat.
{
  const state = initGame("ai-target-finisher", [
    { seat: 1, heroId: "HERO_1", isAI: true },
    { seat: 2, heroId: "HERO_2", isAI: false },
    { seat: 3, heroId: "HERO_3", isAI: false },
    { seat: 4, heroId: "HERO_4", isAI: false },
  ]);
  resetTurn(state, 1);
  state.players[0].hand = [slash()];
  state.players[1].hp = 4;
  state.players[3].hp = 1;

  assert.equal(handleAIStep(state, 1).success, true);
  assert.equal(state.activeCard?.targetSeat, 4, "AI should prioritize the enemy it can finish");
}

// A rebel should pressure the king even when another enemy has less HP.
{
  const state = initGame("ai-dynasty-priority", [
    { seat: 1, heroId: "HERO_1", role: "KING", isAI: false },
    { seat: 2, heroId: "HERO_2", role: "LOYALIST", isAI: false },
    { seat: 3, heroId: "HERO_3", role: "REBEL", isAI: true },
    { seat: 4, heroId: "HERO_4", role: "REBEL", isAI: false },
    { seat: 5, heroId: "HERO_5", role: "SPY", isAI: false },
  ], "dynasty_5");
  resetTurn(state, 3);
  state.players[2].hand = [slash("rebel-slash")];
  state.players[1].hp = 1;
  state.players[0].hp = 3;
  state.players[2].equipments = [{ id: "long-range", subType: CARD_SUBTYPES.WEAPON, range: 2, name: "Trường Đao" }];

  assert.equal(handleAIStep(state, 3).success, true);
  assert.equal(state.activeCard?.targetSeat, 1, "Rebel AI should prioritize the king");
}

console.log("AI strategy target selection: PASS");

// A lethal slash should happen before draw/setup cards are spent.
{
  const state = initGame("ai-lethal-priority", [
    { seat: 1, heroId: "HERO_1", isAI: true },
    { seat: 2, heroId: "HERO_2", isAI: false },
    { seat: 3, heroId: "HERO_3", isAI: false },
    { seat: 4, heroId: "HERO_4", isAI: false },
  ]);
  resetTurn(state, 1);
  state.players[0].hand = [
    slash("priority-slash"),
    { id: "priority-draw", name: "Dụng Binh", suit: "Heart", rank: 1, category: CARD_CATEGORIES.INSTANT_SCROLL, subType: CARD_SUBTYPES.EX_NIHILO },
  ];
  state.players[1].hp = 1;
  assert.equal(handleAIStep(state, 1).success, true);
  assert.equal(state.activeCard?.targetSeat, 2, "AI should secure a lethal attack before drawing");
}

console.log("AI lethal priority: PASS");
