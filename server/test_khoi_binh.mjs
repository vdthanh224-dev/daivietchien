import assert from "node:assert/strict";
import { CARD_CATEGORIES, CARD_SUBTYPES } from "./functions/game-engine/src/deck.js";
import { handlePlayCard, handleRespondAction, handleUseSkill, initGame } from "./functions/game-engine/src/gameEngine.js";

const players = [
  { seat: 1, heroId: "HERO_1" },
  { seat: 2, heroId: "HERO_2" },
  { seat: 3, heroId: "HERO_8" },
  { seat: 4, heroId: "HERO_3" }
];

function card(id, name, subType, suit = "Heart") {
  return { id, name, suit, rank: 7, category: CARD_CATEGORIES.BASIC, subType };
}

function playSuccessfulSlash(state, slashId, attackerSeat = 1, targetSeat = 2) {
  assert.equal(handlePlayCard(state, attackerSeat, slashId, targetSeat).success, true);
  if (state.phase === "AWAIT_SLASH_DEFENSE") {
    assert.equal(handleRespondAction(state, targetSeat, false, null).success, true);
  }
  if (state.phase === "AWAIT_DODGE") {
    assert.equal(handleRespondAction(state, targetSeat, false, null).success, true);
  }
}

// 1. Khởi Binh when an ally/other character uses Trảm: Red chaining test
{
  const state = initGame("khoi-binh-chain", players);
  state.players[0].hand = [card("slash", "Trảm", CARD_SUBTYPES.ATTACK_NORMAL)];
  state.players[1].hand = [];

  playSuccessfulSlash(state, "slash", 1, 2);

  assert.equal(state.phase, "AWAIT_KHOI_BINH");
  assert.equal(state.waitingTargetSeat, 3);

  // Set up deck at AWAIT_KHOI_BINH so:
  // First card drawn (for attacker): Black (Club)
  // For Triệu Quốc Đạt:
  // Card 1: Heart (Red) -> triggers chain
  // Card 2: Diamond (Red) -> triggers chain
  // Card 3: Spade (Black) -> stops chain!
  state._deck = [
    card("c-stop", "Đỡ", CARD_SUBTYPES.DODGE, "Spade"),
    card("c-red2", "Bánh Chưng", CARD_SUBTYPES.PEACH, "Diamond"),
    card("c-red1", "Trảm", CARD_SUBTYPES.ATTACK_NORMAL, "Heart"),
    card("c-atk", "Đỡ", CARD_SUBTYPES.DODGE, "Club")
  ];

  const sourceCards = state.players[0].hand.length;
  const ownerCards = state.players[2].hand.length;

  assert.equal(handleRespondAction(state, 3, true, null).success, true);
  // Attacker drew 1 card (Club)
  assert.equal(state.players[0].hand.length, sourceCards + 1);
  // Triệu Quốc Đạt drew 3 cards (Heart, Diamond, Spade)
  assert.equal(state.players[2].hand.length, ownerCards + 3);
  assert.equal(state.players[2].hand.some(c => c.id === "c-red1"), true);
  assert.equal(state.players[2].hand.some(c => c.id === "c-red2"), true);
  assert.equal(state.players[2].hand.some(c => c.id === "c-stop"), true);
  assert.equal(state.phase, "PLAY");
}

// 2. Khởi Binh when Triệu Quốc Đạt HIMSELF uses Trảm and deals damage
{
  const state = initGame("khoi-binh-self", [
    { seat: 1, heroId: "HERO_8" }, // Triệu Quốc Đạt is seat 1
    { seat: 2, heroId: "HERO_2" },
    { seat: 3, heroId: "HERO_1" },
    { seat: 4, heroId: "HERO_3" }
  ]);
  state.players[0].hand = [card("self-slash", "Trảm", CARD_SUBTYPES.ATTACK_NORMAL)];
  state.players[1].hand = [];

  playSuccessfulSlash(state, "self-slash", 1, 2);

  assert.equal(state.phase, "AWAIT_KHOI_BINH");
  assert.equal(state.waitingTargetSeat, 1);

  // Deck: Card 1 is Black (Club), stops immediately after 1 draw
  state._deck = [
    card("c-black", "Đỡ", CARD_SUBTYPES.DODGE, "Club")
  ];

  const ownerCards = state.players[0].hand.length;

  assert.equal(handleRespondAction(state, 1, true, null).success, true);
  // Triệu Quốc Đạt drew 1 card (Club is Black, so stops)
  assert.equal(state.players[0].hand.length, ownerCards + 1);
  assert.equal(state.players[0].hand.some(c => c.id === "c-black"), true);
  assert.equal(state.phase, "PLAY");
}

// 3. Khởi Binh near death
{
  const state = initGame("khoi-binh-near-death", players);
  state.players[0].hand = [
    card("slash-lethal", "Trảm", CARD_SUBTYPES.ATTACK_NORMAL),
    card("rescue", "Bánh Chưng", CARD_SUBTYPES.PEACH)
  ];
  state.players[1].hand = [];
  state.players[1].hp = 1;
  playSuccessfulSlash(state, "slash-lethal", 1, 2);

  assert.equal(state.phase, "AWAIT_NEAR_DEATH");
  assert.equal(state.waitingTargetSeat, 1);
  assert.equal(handleRespondAction(state, 1, true, "rescue").success, true);
  assert.equal(state.phase, "AWAIT_KHOI_BINH");
  assert.equal(state.waitingTargetSeat, 3);
  assert.equal(handleRespondAction(state, 3, false, null).success, true);
  assert.equal(state.phase, "PLAY");
}

// 4. Huynh Trưởng: gives 1 card, draws 2 cards
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
  playSuccessfulSlash(state, "slash-chain", 1, 2);

  assert.equal(state.phase, "AWAIT_KHOI_BINH");
  assert.equal(handleRespondAction(state, 2, false, null).success, true);
  assert.equal(state.phase, "AWAIT_HUYNH_TRUONG");
  assert.equal(state.waitingTargetSeat, 2);
  const ownerCards = state.players[1].hand.length;
  const recipientCards = state.players[2].hand.length;

  // Gives 1 card (-1) and draws 2 cards (+2) => net +1 card
  assert.equal(handleUseSkill(state, 2, "Huynh Trưởng", 3, "huynh-gift").success, true);
  assert.equal(state.players[1].hand.length, ownerCards + 1);
  assert.equal(state.players[2].hand.length, recipientCards + 1);
  assert.equal(state.players[2].hand.some(c => c.id === "huynh-gift"), true);
  assert.equal(state.phase, "PLAY");
}

console.log("Khởi Binh & Huynh Trưởng OK");
