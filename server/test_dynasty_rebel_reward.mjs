import assert from "node:assert/strict";
import {
  applyDamageToPlayer,
  handleRespondAction,
  initGame,
} from "./functions/game-engine/src/gameEngine.js";

const roles = ["KING", "LOYALIST", "REBEL", "REBEL", "SPY"];

function makeState(suffix, aiKiller = false) {
  const state = initGame(`dynasty-rebel-reward-${suffix}`, roles.map((role, index) => ({
    seat: index + 1,
    userId: `reward-${suffix}-${index + 1}`,
    generalName: `Tướng ${index + 1}`,
    role,
    maxHp: 4,
    isAI: aiKiller && index === 0,
  })), "dynasty_5");
  for (const player of state.players) {
    player.hand = [];
    player.equipments = [];
    player.judgements = [];
    player.hp = 4;
    player.isAlive = true;
    player.isChained = false;
  }
  state.phase = "PLAY";
  state.status = "PLAYING";
  state.turnSeat = 1;
  state.activeCard = null;
  state._deck = Array.from({ length: 20 }, (_, index) => ({
    id: `reward-card-${suffix}-${index}`,
    name: `Lá thưởng ${index}`,
    suit: "Heart",
    rank: 1,
    category: 0,
    subType: 0,
    desc: "test",
  }));
  state._discard = [];
  state.deckCount = state._deck.length;
  return state;
}

function passNearDeath(state) {
  let guard = 0;
  while (state.phase === "AWAIT_NEAR_DEATH" && guard++ < 16) {
    const result = handleRespondAction(state, state.waitingTargetSeat, false, null);
    assert.equal(result?.error, undefined, result?.error || "near-death pass failed");
  }
  assert.ok(guard < 16, "near-death resolution did not finish");
}

function killRebel(state, options = {}) {
  const killer = state.players.find((player) => player.role === "KING");
  const rebel = state.players.find((player) => player.role === "REBEL");
  rebel.hp = 1;
  state.turnSeat = killer.seat;
  state.activeCard = { casterSeat: options.activeCardSeat ?? killer.seat };
  applyDamageToPlayer(state, rebel.seat, 1, options.source || "test damage", "NORMAL", false, options.damageOptions || {});
  passNearDeath(state);
  return { killer, rebel };
}

// A human King receives exactly three cards.
{
  const state = makeState("human");
  const { killer, rebel } = killRebel(state);
  assert.equal(rebel.isAlive, false);
  assert.equal(killer.hand.length, 3);
  assert.equal(state.actionHistory.filter((action) => action.type === "DYNASTY_REBEL_KILL_DRAW").length, 1);
}

// AI and human killers use the same authoritative reward path.
{
  const state = makeState("ai", true);
  const { killer } = killRebel(state);
  assert.equal(killer.isAI, true);
  assert.equal(killer.hand.length, 3);
}

// The reward is still due when the killer is already at 0 HP during a
// chained/indirect resolution.  The fatal attacker seat, rather than a live
// HP check, is authoritative for this reward.
{
  const state = makeState("dead-killer");
  const killer = state.players.find((player) => player.role === "KING");
  const rebel = state.players.find((player) => player.role === "REBEL");
  killer.hp = 0;
  killer.isAlive = true;
  rebel.hp = 1;
  state.turnSeat = killer.seat;
  state.activeCard = { casterSeat: killer.seat };
  applyDamageToPlayer(state, rebel.seat, 1, "test damage", "NORMAL", false, { attackerSeat: killer.seat });
  passNearDeath(state);
  assert.equal(rebel.isAlive, false);
  assert.equal(killer.hand.length, 3);
}

// A Rebel who kills another Rebel is also rewarded.
{
  const state = makeState("rebel-killer");
  const killer = state.players.find((player) => player.role === "REBEL");
  const victim = state.players.find((player) => player.role === "REBEL" && player.seat !== killer.seat);
  victim.hp = 1;
  state.turnSeat = killer.seat;
  state.activeCard = { casterSeat: killer.seat };
  applyDamageToPlayer(state, victim.seat, 1, "test damage", "NORMAL", false, { attackerSeat: killer.seat });
  passNearDeath(state);
  assert.equal(victim.isAlive, false);
  assert.equal(killer.hand.length, 3);
}

// Delayed/indirect damage keeps the scroll owner as the killer even when the
// active card belongs to the victim.
{
  const state = makeState("delayed");
  const { killer } = killRebel(state, {
    activeCardSeat: 3,
    source: "Đại Hồng Thủy",
    damageOptions: { singleTargetScrollCasterSeat: 1 },
  });
  assert.equal(killer.hand.length, 3);
}

// A chained victim keeps the original attacker through the spread.
{
  const state = makeState("chain");
  const killer = state.players.find((player) => player.role === "KING");
  const firstVictim = state.players.find((player) => player.role === "LOYALIST");
  const rebel = state.players.find((player) => player.role === "REBEL");
  firstVictim.hp = 1;
  rebel.hp = 1;
  firstVictim.isChained = true;
  rebel.isChained = true;
  state.turnSeat = killer.seat;
  state.activeCard = { casterSeat: killer.seat };
  applyDamageToPlayer(state, firstVictim.seat, 1, "test chain", "FIRE", false);
  passNearDeath(state);
  assert.equal(rebel.isAlive, false);
  assert.equal(killer.hand.length, 3);
}

// Rescue prevents the death reward.
{
  const state = makeState("rescued");
  const killer = state.players.find((player) => player.role === "KING");
  const rebel = state.players.find((player) => player.role === "REBEL");
  rebel.hp = 1;
  rebel.hand.push({ id: "banh-chung", name: "Bánh Chưng", suit: "Heart", rank: 1, category: 0, subType: 4 });
  state.turnSeat = killer.seat;
  state.activeCard = { casterSeat: killer.seat };
  applyDamageToPlayer(state, rebel.seat, 1, "test damage");
  while (state.phase === "AWAIT_NEAR_DEATH" && state.waitingTargetSeat !== rebel.seat) {
    handleRespondAction(state, state.waitingTargetSeat, false, null);
  }
  assert.equal(state.phase, "AWAIT_NEAR_DEATH");
  const rescue = handleRespondAction(state, rebel.seat, true, "banh-chung");
  assert.equal(rescue?.error, undefined, rescue?.error || "rescue failed");
  assert.equal(rebel.isAlive, true);
  assert.equal(killer.hand.length, 0);
  assert.equal(state.actionHistory.filter((action) => action.type === "DYNASTY_REBEL_KILL_DRAW").length, 0);
}

console.log("Dynasty Rebel kill reward: PASS");
