import assert from "node:assert/strict";
import {
  applyDamageToPlayer,
  handleRespondAction,
  initGame,
  tickGameState
} from "./gameEngine.js";

function newGame() {
  const state = initGame("khoi-binh-test", [
    { seat: 1, heroId: "HERO_1" },
    { seat: 2, heroId: "HERO_2" },
    { seat: 3, heroId: "HERO_8" },
    { seat: 4, heroId: "HERO_3" }
  ]);
  state.activeCard = { casterSeat: 1, targetSeat: 2, name: "Trảm" };
  return state;
}

{
  const state = newGame();
  const sourceCards = state.players[0].hand.length;
  const ownerCards = state.players[2].hand.length;
  applyDamageToPlayer(state, 2, 1, "đòn Trảm", "NORMAL", true);
  assert.equal(state.phase, "AWAIT_KHOI_BINH");
  assert.equal(state.waitingTargetSeat, 3);
  handleRespondAction(state, 3, true, null);
  assert.equal(state.players[0].hand.length, sourceCards + 1);
  assert.equal(state.players[2].hand.length, ownerCards + 1);
  assert.equal(state.phase, "PLAY");
}

{
  const state = newGame();
  applyDamageToPlayer(state, 2, 1, "đòn Trảm", "NORMAL", true);
  state.timerStartAt = Date.now() - 40_000;
  tickGameState(state);
  assert.equal(state.phase, "PLAY");
  assert.equal(state.lastAction.type, "KHOI_BINH_DECLINED");
}

console.log("Khởi Binh OK");
