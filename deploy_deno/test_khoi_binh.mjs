import assert from "node:assert/strict";
import { CARD_CATEGORIES, CARD_SUBTYPES } from "./functions/game-engine/src/deck.js";
import { handlePlayCard, handleRespondAction, handleUseSkill, initGame } from "./functions/game-engine/src/gameEngine.js";

const players = [
  { seat: 1, heroId: "HERO_1" },
  { seat: 2, heroId: "HERO_2" },
  { seat: 3, heroId: "HERO_8" },
  { seat: 4, heroId: "HERO_3" }
];

function card(id, name, subType) {
  return { id, name, suit: "Heart", rank: 7, category: CARD_CATEGORIES.BASIC, subType };
}

function playSuccessfulSlash(state, slashId) {
  assert.equal(handlePlayCard(state, 1, slashId, 2).success, true);
  assert.equal(handleRespondAction(state, 2, false, null).success, true);
}

{
  const state = initGame("khoi-binh-normal", players);
  state.players[0].hand = [card("slash", "Trảm", CARD_SUBTYPES.ATTACK_NORMAL)];
  state.players[1].hand = [];
  playSuccessfulSlash(state, "slash");

  assert.equal(state.phase, "AWAIT_KHOI_BINH");
  assert.equal(state.waitingTargetSeat, 3);
  const sourceCards = state.players[0].hand.length;
  const ownerCards = state.players[2].hand.length;
  assert.equal(handleRespondAction(state, 3, true, null).success, true);
  assert.equal(state.players[0].hand.length, sourceCards + 1);
  assert.equal(state.players[2].hand.length, ownerCards + 1);
  assert.equal(state.phase, "PLAY");
}

{
  const state = initGame("khoi-binh-near-death", players);
  state.players[0].hand = [
    card("slash-lethal", "Trảm", CARD_SUBTYPES.ATTACK_NORMAL),
    card("rescue", "Bánh Chưng", CARD_SUBTYPES.PEACH)
  ];
  state.players[1].hand = [];
  state.players[1].hp = 1;
  playSuccessfulSlash(state, "slash-lethal");

  assert.equal(state.phase, "AWAIT_NEAR_DEATH");
  assert.equal(state.waitingTargetSeat, 1);
  assert.equal(handleRespondAction(state, 1, true, "rescue").success, true);
  assert.equal(state.phase, "AWAIT_KHOI_BINH");
  assert.equal(state.waitingTargetSeat, 3);
  assert.equal(handleRespondAction(state, 3, false, null).success, true);
  assert.equal(state.phase, "PLAY");
}

{
  const state = initGame("khoi-binh-before-huynh-truong", [
    { seat: 1, heroId: "HERO_1" },
    { seat: 2, heroId: "HERO_8" },
    { seat: 3, heroId: "HERO_2" },
    { seat: 4, heroId: "HERO_3" }
  ]);
  state.players[0].hand = [card("slash-chain", "Trảm", CARD_SUBTYPES.ATTACK_NORMAL)];
  state.players[1].hand.push(card("huynh-gift", "Bài đưa", CARD_SUBTYPES.PEACH));
  state.players[2].hand = [];
  playSuccessfulSlash(state, "slash-chain");

  assert.equal(state.phase, "AWAIT_KHOI_BINH");
  assert.equal(handleRespondAction(state, 2, false, null).success, true);
  assert.equal(state.phase, "AWAIT_HUYNH_TRUONG");
  assert.equal(state.waitingTargetSeat, 2);
  const ownerCards = state.players[1].hand.length;
  const recipientCards = state.players[2].hand.length;
  assert.equal(handleUseSkill(state, 2, "Huynh Trưởng", 3, "huynh-gift").success, true);
  assert.equal(state.players[1].hand.length, ownerCards);
  assert.equal(state.players[2].hand.length, recipientCards + 1);
  assert.equal(state.phase, "PLAY");
}

console.log("Khởi Binh OK");
