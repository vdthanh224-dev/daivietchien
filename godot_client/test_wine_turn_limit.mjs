import assert from "node:assert/strict";
import {
  handleEndTurn,
  handlePlayCard,
  handleRespondAction,
  initGame,
} from "../server/functions/game-engine/src/gameEngine.js";
import { CARD_CATEGORIES, CARD_SUBTYPES } from "../server/functions/game-engine/src/deck.js";

const wine = (id) => ({
  id,
  name: "Hủ Rượu",
  suit: "Diamond",
  rank: 9,
  category: CARD_CATEGORIES.BASIC,
  subType: CARD_SUBTYPES.WINE,
});
const slash = (id) => ({
  id,
  name: "Trảm",
  suit: "Spade",
  rank: 7,
  category: CARD_CATEGORIES.BASIC,
  subType: CARD_SUBTYPES.ATTACK_NORMAL,
});

function game() {
  const state = initGame("wine-turn-limit", [1, 2, 3, 4].map((seat) => ({
    seat,
    heroId: `HERO_${seat}`,
    generalName: `P${seat}`,
  })));
  for (const player of state.players) {
    player.hand = [];
    player.equipments = [];
    player.judgements = [];
    player.usedSkills = {};
  }
  state._deck = [];
  state._discard = [];
  state.phase = "PLAY";
  state.turnSeat = 1;
  return state;
}

{
  const state = game();
  state.players[0].hand = [wine("wine-1"), slash("slash-1"), wine("wine-2")];
  assert.equal(handlePlayCard(state, 1, "wine-1", 1).success, true);
  assert.equal(state.players[0].isWineBuffActive, true);
  assert.equal(state.players[0].wineUsedThisTurn, true);
  assert.equal(handlePlayCard(state, 1, "slash-1", 2).success, true);
  assert.equal(state.lastDelta.damage, 2, "Delta Trảm kèm Rượu phải ghi 2 sát thương");
  assert.equal(state.lastDelta.isWineBuff, true, "Delta phải giữ cờ Hủ Rượu");
  assert.equal(state.players[0].isWineBuffActive, false, "Trảm phải tiêu buff Rượu");
  handleRespondAction(state, 2, false, null);
  assert.match(handlePlayCard(state, 1, "wine-2", 1).error, /chỉ được dùng 1 Hủ Rượu/);
  assert.equal(state.players[0].hand.some((card) => card.id === "wine-2"), true, "Rượu lần hai không được mất");
}

{
  const state = game();
  state.players[0].hand = [wine("wine-expire")];
  handlePlayCard(state, 1, "wine-expire", 1);
  handleEndTurn(state, 1);
  assert.equal(state.players[0].isWineBuffActive, false, "Buff Rượu phải hết khi kết thúc lượt");
  assert.equal(state.players[0].wineUsedThisTurn, false, "Lượt sau phải được uống Rượu lại");
}

{
  const state = game();
  const victim = state.players[0];
  victim.hp = 0;
  victim.wineUsedThisTurn = true;
  victim.hand = [wine("wine-rescue")];
  state.phase = "AWAIT_NEAR_DEATH";
  state.nearDeathVictimSeat = 1;
  state.nearDeathAttackerSeat = 2;
  state.nearDeathAskerQueue = [];
  state.waitingTargetSeat = 1;
  assert.equal(handleRespondAction(state, 1, true, "wine-rescue").success, true);
  assert.equal(victim.hp, 1, "Rượu vẫn phải tự cứu được dù đã uống tăng sát thương trong lượt");
  assert.equal(victim.wineUsedThisTurn, true, "Rượu cứu cận tử không được sửa giới hạn Rượu tăng sát thương");
}

{
  const state = game();
  const victim = state.players[0];
  victim.hp = 0;
  victim.hand = [wine("wine-rescue-free")];
  state.phase = "AWAIT_NEAR_DEATH";
  state.nearDeathVictimSeat = 1;
  state.nearDeathAttackerSeat = 2;
  state.nearDeathAskerQueue = [];
  state.waitingTargetSeat = 1;
  handleRespondAction(state, 1, true, "wine-rescue-free");
  assert.equal(victim.wineUsedThisTurn, false, "Rượu cứu cận tử không được tính là Rượu tăng sát thương");
}

console.log("PASS wine turn limit");
