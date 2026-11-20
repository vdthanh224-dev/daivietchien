import assert from "node:assert/strict";
import { CARD_CATEGORIES, CARD_SUBTYPES } from "./functions/game-engine/src/deck.js";
import {
  handlePlayCard,
  handleRespondAction,
  initGame
} from "./functions/game-engine/src/gameEngine.js";

// HERO_7 is Nàng Nội (skills: TIEN_PHONG, TRAN_TIEN, maxHp: 4)
const players = [1, 2, 3, 4].map((seat) => ({ seat, heroId: seat === 1 ? "HERO_7" : `HERO_${seat}` }));

const slash = (id, name = "Trảm", subType = CARD_SUBTYPES.ATTACK_NORMAL) => ({
  id,
  name,
  suit: "Spade",
  rank: 5,
  category: CARD_CATEGORIES.BASIC,
  subType
});

const dodge = (id) => ({
  id,
  name: "Đỡ",
  suit: "Heart",
  rank: 2,
  category: CARD_CATEGORIES.BASIC,
  subType: CARD_SUBTYPES.DODGE
});

function passNearDeath(state) {
  while (state.phase === "AWAIT_NEAR_DEATH") {
    handleRespondAction(state, state.waitingTargetSeat, false, null);
  }
}

// Test 1: Tiên Phong turn 1 extra draw (first player draws 5 base cards + 2 Tiên Phong = 7 cards)
{
  const state = initGame("tien-phong-turn-1-draw", players);
  assert.equal(state.players[0].hand.length, 7);
  assert.equal(state.players[0].turnsTaken, 1);
}

// Test 2: Tiên Phong turn 1 with >= 3 Trảm in hand draws 1 card
{
  const state = initGame("tien-phong-gte-3-slashes", players);
  // Give Seat 1 exactly 3 slashes in hand
  state.players[0].hand = [slash("s1"), slash("s2"), slash("s3")];
  state.players[1].hand = [dodge("d1")];

  // Play s1 against seat 2 (had 3 slashes in hand -> >= 3)
  const res = handlePlayCard(state, 1, "s1", 2);
  assert.equal(res.success, true);

  // Hand had 3, s1 played (-1), drew 1 (+1) -> hand.length is 3
  assert.equal(state.players[0].hand.length, 3);

  // Target CAN dodge because it's not unavoidable
  assert.equal(state.phase, "AWAIT_SLASH_DEFENSE");
  assert.equal(state.waitingTargetSeat, 2);

  // Seat 2 dodges successfully
  const dodgeRes = handleRespondAction(state, 2, true, "d1");
  assert.equal(dodgeRes.success, true);
  assert.equal(state.players[1].hp, state.players[1].maxHp);
}

// Test 3: Tiên Phong turn 1 with < 3 Trảm in hand is UNAVOIDABLE (cannot be dodged)
{
  const state = initGame("tien-phong-lt-3-slashes", players);
  // Give Seat 1 exactly 2 slashes in hand
  state.players[0].hand = [slash("s1"), slash("s2")];
  state.players[1].hand = [dodge("d1"), dodge("d2")];
  const targetInitialHp = state.players[1].hp;

  // Play s1 against seat 2 (had 2 slashes in hand -> < 3)
  const res = handlePlayCard(state, 1, "s1", 2);
  assert.equal(res.success, true);

  // Slash is UNAVOIDABLE: directly damages seat 2 without AWAIT_SLASH_DEFENSE!
  assert.equal(state.players[1].hp, targetInitialHp - 1);

  // Tiên Phong also allows unlimited slashes in turn 1!
  // Now play s2 against seat 2 (had 1 slash in hand -> < 3)
  const res2 = handlePlayCard(state, 1, "s2", 2);
  assert.equal(res2.success, true);
  assert.equal(state.players[1].hp, targetInitialHp - 2);
}

// Test 4: Tiên Phong in turn 2 does NOT trigger unlimited slashes or bonus effects
{
  const state = initGame("tien-phong-turn-2", players);
  // Simulate turn 2
  state.players[0].turnsTaken = 2;
  state.players[0].hand = [slash("s1"), slash("s2")];
  state.players[1].hand = [dodge("d1")];

  // Play s1
  const res = handlePlayCard(state, 1, "s1", 2);
  assert.equal(res.success, true);
  assert.equal(state.phase, "AWAIT_SLASH_DEFENSE");

  // Dodge s1
  handleRespondAction(state, 2, true, "d1");

  // Try to play s2 in turn 2: must be BLOCKED by slash limit!
  const res2 = handlePlayCard(state, 1, "s2", 2);
  assert.equal(res2.success, undefined);
  assert.ok(res2.error.includes("hết lượt Trảm"));
}

// Test 5: Trận Tiền - Full HP kill automatically draws 2 cards
{
  const state = initGame("tran-tien-full-hp", players);
  state.players[0].hp = 4;
  state.players.forEach(p => p.hand = []);
  state.players[0].hand = [slash("kill-slash")];
  state.players[1].hp = 1;

  // Seat 1 slashes Seat 2 -> unavoidable (< 3 slashes) -> near death
  handlePlayCard(state, 1, "kill-slash", 2);
  passNearDeath(state);

  // Since seat 1 was full HP, Trận Tiền automatically draws 2 cards
  assert.equal(state.players[0].hand.length, 2);
  assert.equal(state.players[0].hp, 4);
  assert.equal(state.phase, "PLAY");
}

// Test 6: Trận Tiền - Wounded kill, choose HEAL 1 HP
{
  const state = initGame("tran-tien-wounded-heal", players);
  state.players[0].hp = 3; // Wounded: 3/4
  state.players.forEach(p => p.hand = []);
  state.players[0].hand = [slash("kill-slash")];
  state.players[1].hp = 1;

  handlePlayCard(state, 1, "kill-slash", 2);
  passNearDeath(state);

  assert.equal(state.phase, "AWAIT_TRAN_TIEN");
  assert.equal(state.waitingTargetSeat, 1);

  // Seat 1 chooses to heal 1 HP
  const choiceRes = handleRespondAction(state, 1, true, "HEAL_1");
  assert.equal(choiceRes.success, true);

  // HP increases by 1!
  assert.equal(state.players[0].hp, 4);
  assert.equal(state.players[0].hand.length, 0);
  assert.equal(state.phase, "PLAY");
}

// Test 7: Trận Tiền - Wounded kill, choose DRAW 2 cards
{
  const state = initGame("tran-tien-wounded-draw", players);
  state.players[0].hp = 3;
  state.players.forEach(p => p.hand = []);
  state.players[0].hand = [slash("kill-slash")];
  state.players[1].hp = 1;

  handlePlayCard(state, 1, "kill-slash", 2);
  passNearDeath(state);

  assert.equal(state.phase, "AWAIT_TRAN_TIEN");

  // Seat 1 chooses to draw 2 cards
  const choiceRes = handleRespondAction(state, 1, false, "DRAW_2");
  assert.equal(choiceRes.success, true);

  // HP remains 3, hand increased by 2
  assert.equal(state.players[0].hp, 3);
  assert.equal(state.players[0].hand.length, 2);
  assert.equal(state.phase, "PLAY");
}

console.log("Nàng Nội (Tiên Phong & Trận Tiền) ALL TESTS PASSED!");
