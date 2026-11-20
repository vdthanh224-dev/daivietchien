import assert from "node:assert/strict";
import {
  initGame,
  handlePlayCard,
  handleRespondAction,
  applyDamageToPlayer,
  getHandLimit,
  tickGameState,
} from "./functions/game-engine/src/gameEngine.js";
import { heroHasSkill } from "./functions/game-engine/src/heroes.js";
import { CARD_SUBTYPES } from "./functions/game-engine/src/deck.js";

function makeCard(id, name, subType = CARD_SUBTYPES.ATTACK_NORMAL, suit = "Spade", rank = 7) {
  return { id, name, subType, suit, rank, category: 0 };
}

console.log("Starting Thi Sách Hịch Nghĩa & Starting HP Tests...");

// TEST 1: Starting HP of Thi Sách is 2/4
{
  const state = initGame("test-starting-hp", [
    { seat: 1, heroId: "HERO_3", isAI: false }, // Thi Sách
    { seat: 2, heroId: "HERO_1", isAI: true },
    { seat: 3, heroId: "HERO_2", isAI: false },
    { seat: 4, heroId: "HERO_4", isAI: true },
  ]);

  const thiSach = state.players[0];
  assert.equal(thiSach.hp, 2, "Thi Sách initial HP must be 2");
  assert.equal(thiSach.maxHp, 4, "Thi Sách max HP must be 4");
  assert.equal(heroHasSkill(thiSach, "HICH_NGHIA"), true, "Thi Sách must have Hịch Nghĩa initially");
  console.log("✓ TEST 1 PASSED: Thi Sách starts with 2/4 HP");
}

// TEST 2: Someone loses HP -> Thi Sách loses 1 HP and draws 3 cards (no infinite loop)
{
  const state = initGame("test-hp-loss-trigger", [
    { seat: 1, heroId: "HERO_3", isAI: true }, // Thi Sách (Team 1, AI)
    { seat: 2, heroId: "HERO_1", isAI: false }, // Cao Lỗ (Team 2)
    { seat: 3, heroId: "HERO_2", isAI: true },
    { seat: 4, heroId: "HERO_4", isAI: false },
  ]);

  const thiSach = state.players[0];
  const caoLo = state.players[1];
  const handBefore = thiSach.hand.length;

  assert.equal(thiSach.hp, 2);

  // Cao Lỗ takes 1 damage
  applyDamageToPlayer(state, caoLo.seat, 1, "đòn Trảm", "NORMAL", true);

  // Cao Lỗ lost 1 HP (from 4 down to 3)
  assert.equal(caoLo.hp, 3);

  // Thi Sách triggered Hịch Nghĩa: lost 1 HP (from 2 to 1) and drew 3 cards
  assert.equal(thiSach.hp, 1, "Thi Sách must lose 1 HP on external HP loss");
  assert.equal(thiSach.hand.length, handBefore + 3, "Thi Sách must draw 3 cards");
  assert.equal(heroHasSkill(thiSach, "HICH_NGHIA"), true, "Thi Sách still has Hịch Nghĩa at 1 HP");

  const action = state.actionHistory.find((a) => a.type === "HICH_NGHIA_TRIGGERED");
  assert.ok(action, "Must record HICH_NGHIA_TRIGGERED action");
  console.log("✓ TEST 2 PASSED: External HP loss triggered Thi Sách HP loss and card draw without loop");
}

// TEST 3: Thi Sách HP reaches 0 -> AI revives to 4 HP, loses Hịch Nghĩa, permanent hand limit = 4
{
  const state = initGame("test-revive-ai", [
    { seat: 1, heroId: "HERO_3", isAI: true }, // Thi Sách (Team 1, AI)
    { seat: 2, heroId: "HERO_1", isAI: false },
    { seat: 3, heroId: "HERO_2", isAI: true },
    { seat: 4, heroId: "HERO_4", isAI: false },
  ]);

  const thiSach = state.players[0];
  const caoLo = state.players[1];

  // 1st external damage: Thi Sách HP goes from 2 to 1, draws 3
  applyDamageToPlayer(state, caoLo.seat, 1, "đòn Trảm");
  assert.equal(thiSach.hp, 1);

  const handCountAfterFirst = thiSach.hand.length;

  // 2nd external damage: Thi Sách HP drops to 0, draws 3 cards, then revives to 4 HP!
  applyDamageToPlayer(state, caoLo.seat, 1, "đòn Trảm");

  assert.equal(thiSach.hp, 4, "Thi Sách must revive to 4 HP");
  assert.equal(thiSach.hand.length, handCountAfterFirst + 3, "Thi Sách must draw 3 cards before revive");
  assert.equal(thiSach.permanentHandLimit, 4, "Thi Sách permanentHandLimit must be 4");
  assert.equal(getHandLimit(thiSach), 4, "getHandLimit must return 4");
  assert.equal(heroHasSkill(thiSach, "HICH_NGHIA"), false, "Thi Sách must lose Hịch Nghĩa after revive");

  const reviveAction = state.actionHistory.find((a) => a.type === "HICH_NGHIA_REVIVE");
  assert.ok(reviveAction, "Must record HICH_NGHIA_REVIVE action");
  console.log("✓ TEST 3 PASSED: Dropping to 0 HP revives AI Thi Sách to 4 HP, loses skill, hand limit permanently 4");
}

// TEST 4: After revive, permanent hand limit is 4 even when HP decreases, and no further Hịch Nghĩa triggers
{
  const state = initGame("test-after-revive", [
    { seat: 1, heroId: "HERO_3", isAI: true }, // Thi Sách
    { seat: 2, heroId: "HERO_1", isAI: false },
    { seat: 3, heroId: "HERO_2", isAI: true },
    { seat: 4, heroId: "HERO_4", isAI: false },
  ]);

  const thiSach = state.players[0];
  const caoLo = state.players[1];

  // Trigger 2 damages to revive Thi Sách
  applyDamageToPlayer(state, caoLo.seat, 1, "đòn Trảm");
  applyDamageToPlayer(state, caoLo.seat, 1, "đòn Trảm");
  assert.equal(thiSach.hp, 4);
  assert.equal(heroHasSkill(thiSach, "HICH_NGHIA"), false);

  const handCountAfterRevive = thiSach.hand.length;

  // Someone takes damage now: Thi Sách should NOT lose HP or draw cards
  applyDamageToPlayer(state, caoLo.seat, 1, "đòn Trảm");
  assert.equal(thiSach.hp, 4, "Thi Sách HP unchanged because Hịch Nghĩa was lost");
  assert.equal(thiSach.hand.length, handCountAfterRevive, "Thi Sách does not draw cards anymore");

  // Thi Sách takes damage down to 1 HP
  applyDamageToPlayer(state, thiSach.seat, 3, "đòn Trảm");
  assert.equal(thiSach.hp, 1, "Thi Sách takes damage normally");
  assert.equal(getHandLimit(thiSach), 4, "Permanent hand limit remains 4 even when HP is 1");
  console.log("✓ TEST 4 PASSED: Permanent hand limit persists at 1 HP and skill no longer triggers");
}

// TEST 5: Human Thi Sách prompt on direct lethal damage
{
  const state = initGame("test-human-prompt", [
    { seat: 1, heroId: "HERO_3", isAI: false }, // Thi Sách (Human)
    { seat: 2, heroId: "HERO_1", isAI: true },
    { seat: 3, heroId: "HERO_2", isAI: true },
    { seat: 4, heroId: "HERO_4", isAI: true },
  ]);

  const thiSach = state.players[0];
  assert.equal(thiSach.hp, 2);

  // Directly deal 2 damage to human Thi Sách -> drops to 0 HP
  applyDamageToPlayer(state, thiSach.seat, 2, "đòn Trảm", "NORMAL", true);

  assert.equal(state.phase, "AWAIT_HICH_NGHIA_REVIVE", "Human Thi Sách must be prompted to revive");
  assert.equal(state.waitingTargetSeat, 1);
  assert.equal(state.waitingReactionType, "HICH_NGHIA_REVIVE");

  // Human player accepts revive
  const res = handleRespondAction(state, 1, true, null);
  assert.equal(res.success, true);
  assert.equal(thiSach.hp, 4, "Human Thi Sách recovers to 4 HP");
  assert.equal(thiSach.permanentHandLimit, 4, "Hand limit permanently 4");
  assert.equal(heroHasSkill(thiSach, "HICH_NGHIA"), false, "Skill is removed");
  assert.equal(state.phase, "PLAY", "Game returns to PLAY after revive");
  console.log("✓ TEST 5 PASSED: Human Thi Sách prompt acceptance revives to 4 HP and sets limit to 4");
}

// TEST 6: External damage causes Human Thi Sách to drop to 0 HP via Hịch Nghĩa self-damage -> Phase remains AWAIT_HICH_NGHIA_REVIVE
{
  const state = initGame("test-external-hich-nghia-0hp", [
    { seat: 1, heroId: "HERO_1", isAI: true }, // Cao Lỗ
    { seat: 2, heroId: "HERO_3", isAI: false }, // Thi Sách (Human, starts 2 HP)
    { seat: 3, heroId: "HERO_2", isAI: true },
    { seat: 4, heroId: "HERO_4", isAI: true },
  ]);

  const thiSach = state.players[1];
  const caoLo = state.players[0];
  thiSach.hp = 1; // set to 1 HP

  // Cao Lỗ takes 1 damage -> Thi Sách triggers Hịch Nghĩa, drops to 0 HP
  const res = applyDamageToPlayer(state, caoLo.seat, 1, "đòn Trảm");
  assert.equal(thiSach.hp, 0, "Thi Sách must reach 0 HP");
  assert.equal(state.phase, "AWAIT_HICH_NGHIA_REVIVE", "State phase must remain AWAIT_HICH_NGHIA_REVIVE (not overwritten to PLAY)");
  assert.equal(state.waitingTargetSeat, 2, "Waiting target must be Thi Sách (seat 2)");
  assert.equal(state.waitingReactionType, "HICH_NGHIA_REVIVE");
  assert.equal(res.enteredNearDeath, true, "enteredNearDeath must be true");
  console.log("✓ TEST 6 PASSED: External damage preserves AWAIT_HICH_NGHIA_REVIVE prompt for human Thi Sách");
}

// TEST 7: Thi Sách declines Hịch Nghĩa revive -> Transitions to AWAIT_NEAR_DEATH (Rescue phase) & can be saved with Peach
{
  const state = initGame("test-decline-rescue", [
    { seat: 1, heroId: "HERO_1", isAI: false }, // Teammate/Ally
    { seat: 2, heroId: "HERO_3", isAI: false }, // Thi Sách (Human)
    { seat: 3, heroId: "HERO_2", isAI: false },
    { seat: 4, heroId: "HERO_4", isAI: false },
  ]);

  const thiSach = state.players[1];
  thiSach.hp = 1;

  // Thi Sách takes 1 damage -> 0 HP
  applyDamageToPlayer(state, thiSach.seat, 1, "đòn Trảm");
  assert.equal(state.phase, "AWAIT_HICH_NGHIA_REVIVE");

  // Thi Sách declines revive (e.g. wants to save revive or be rescued by teammate)
  const declineRes = handleRespondAction(state, 2, false, null);
  assert.equal(declineRes.success, true);
  assert.equal(state.phase, "AWAIT_NEAR_DEATH", "Declining revive must enter Near Death rescue phase, NOT instant death");
  assert.equal(state.waitingReactionType, "PEACH");
  assert.equal(state.nearDeathVictimSeat, 2, "Near death victim must be Thi Sách");

  // Give waiting player a Bánh Chưng to rescue
  const waitingPlayer = state.players.find(p => p.seat === state.waitingTargetSeat);
  const peach = { id: "peach_test", name: "Bánh Chưng", subType: CARD_SUBTYPES.PEACH, category: 0 };
  waitingPlayer.hand.push(peach);

  // Rescue Thi Sách
  const rescueRes = handleRespondAction(state, waitingPlayer.seat, true, peach.id);
  assert.equal(rescueRes.success, true);
  assert.equal(thiSach.hp, 1, "Thi Sách must recover to 1 HP upon rescue");
  assert.equal(state.phase, "PLAY", "Game phase returns to PLAY after rescue");
  console.log("✓ TEST 7 PASSED: Declining revive enters Near Death rescue phase and Thi Sách can be saved with Peach");
}

// TEST 8: Thi Sách declines revive and NO ONE rescues -> Dies properly with PLAYER_DIED
{
  const state = initGame("test-decline-no-rescue", [
    { seat: 1, heroId: "HERO_1", isAI: false },
    { seat: 2, heroId: "HERO_3", isAI: false }, // Thi Sách
    { seat: 3, heroId: "HERO_2", isAI: false },
    { seat: 4, heroId: "HERO_4", isAI: false },
  ]);

  const thiSach = state.players[1];
  thiSach.hp = 1;
  applyDamageToPlayer(state, thiSach.seat, 1, "đòn Trảm");
  handleRespondAction(state, 2, false, null); // Decline revive
  assert.equal(state.phase, "AWAIT_NEAR_DEATH");

  // All askers pass rescue
  while (state.phase === "AWAIT_NEAR_DEATH") {
    handleRespondAction(state, state.waitingTargetSeat, false, null);
  }

  assert.equal(thiSach.hp, 0);
  assert.equal(thiSach.isAlive, false, "Thi Sách must die only after everyone passes rescue");
  const deathAction = state.actionHistory.find(a => a.type === "PLAYER_DIED" && a.targetSeat === 2);
  assert.ok(deathAction, "Must record PLAYER_DIED action for Thi Sách");
  console.log("✓ TEST 8 PASSED: Thi Sách dies properly only when all players pass rescue");
}

// TEST 9: Lethal damage after Hịch Nghĩa is already lost -> Enters AWAIT_NEAR_DEATH directly without revive prompt
{
  const state = initGame("test-lethal-after-lost-skill", [
    { seat: 1, heroId: "HERO_1", isAI: true },
    { seat: 2, heroId: "HERO_3", isAI: false }, // Thi Sách
    { seat: 3, heroId: "HERO_2", isAI: true },
    { seat: 4, heroId: "HERO_4", isAI: true },
  ]);

  const thiSach = state.players[1];
  thiSach.hp = 1;
  thiSach.hichNghiaLost = true;
  thiSach.skills = thiSach.skills.filter(s => s !== "HICH_NGHIA");
  thiSach.lostSkills = ["HICH_NGHIA"];

  applyDamageToPlayer(state, thiSach.seat, 1, "đòn Trảm");
  assert.equal(state.phase, "AWAIT_NEAR_DEATH", "Must enter AWAIT_NEAR_DEATH directly when Hịch Nghĩa was already lost");
  assert.equal(state.nearDeathVictimSeat, 2);
  console.log("✓ TEST 9 PASSED: Dropping to 0 HP after Hịch Nghĩa is lost directly enters Near Death rescue");
}

console.log("\nALL THI SÁCH HỊCH NGHĨA TESTS PASSED 100%!");
