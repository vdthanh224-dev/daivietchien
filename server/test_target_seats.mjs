import assert from "node:assert/strict";
import { initGame, handlePlayCard, handleRespondAction } from "./functions/game-engine/src/gameEngine.js";
import { CARD_CATEGORIES, CARD_SUBTYPES } from "./functions/game-engine/src/deck.js";
import { getModeRules } from "./functions/game-engine/src/modeRegistry.js";

const names = {
  [CARD_SUBTYPES.ACEDIA]: "Trầm Ảo Sa Bẫy",
  [CARD_SUBTYPES.SUPPLY_SHORTAGE]: "Cắt Đường Lương",
  [CARD_SUBTYPES.BAI_COC_BACH_DANG]: "Bãi Cọc Bạch Đằng",
};

function card(subType, id = `test-${subType}`, category = CARD_CATEGORIES.DELAYED_SCROLL) {
  return { id, name: names[subType] || id, subType, category, suit: "Heart", rank: 13 };
}

function fresh(modeId, targetSeat, heroId = "HERO_24", casterSeat = targetSeat - 1) {
  const state = initGame("target-seat-regression", Array.from({ length: getModeRules(modeId).maxPlayers }, (_, i) => ({
    seat: i + 1, heroId: i + 1 === targetSeat ? heroId : "HERO_1",
  })), modeId);
  for (const player of state.players) {
    player.hand = [];
    player.equipments = [];
    player.judgements = [];
    player.usedSkills = {};
  }
  Object.assign(state, { phase: "PLAY", turnSeat: casterSeat, waitingTargetSeat: 0, activeCard: null, turnStart: null });
  return state;
}

let passed = 0;
const failures = [];
function test(name, run) {
  try { run(); passed++; }
  catch (error) { failures.push(name); console.error(`FAIL ${name}: ${error.message}`); }
}

// Reproduce the live match: Lý Đạo Thành (seat 2) targets full-health
// Ngô Xương Ngập (seat 5), beyond the original four-seat table.
test("live five-player Trầm Ảo on full-health Ngô Xương Ngập", () => {
  const state = fresh("dynasty_5", 5, "HERO_24", 2);
  state.players[1].heroId = "HERO_42";
  const scroll = card(CARD_SUBTYPES.ACEDIA);
  state.players[1].hand = [scroll, card(CARD_SUBTYPES.PEACH, "can-gian-cost", CARD_CATEGORIES.BASIC)];
  const result = handlePlayCard(state, 2, scroll.id, 5);
  assert.equal(result.success, true, result.error);
  assert.equal(state.phase, "AWAIT_CAN_GIAN");
  assert.equal(handleRespondAction(state, 2, false, null).success, true);
  assert.equal(state.players[4].hp, 3);
  assert.deepEqual(state.players[4].judgements.map(c => c.id), [scroll.id]);
});

for (const modeId of ["2v2", "dynasty_5", "dynasty_8", "ffa_8", "4v4"]) {
  const maxSeat = getModeRules(modeId).maxPlayers;
  const targetSeats = maxSeat <= 4 ? [2] : Array.from({ length: maxSeat - 4 }, (_, i) => i + 5);
  for (const targetSeat of targetSeats) {
    for (const hp of [3, 2, 1]) {
      for (const subType of Object.keys(names).map(Number)) {
        test(`${modeId}: ${names[subType]} on Ngô Xương Ngập seat ${targetSeat}, ${hp} HP`, () => {
          const state = fresh(modeId, targetSeat);
          const caster = state.players.find(p => p.seat === state.turnSeat);
          const target = state.players.find(p => p.seat === targetSeat);
          target.hp = hp;
          const scroll = card(subType);
          caster.hand = [scroll];
          const result = handlePlayCard(state, caster.seat, scroll.id, String(targetSeat));
          assert.equal(result.success, true, result.error);
          if (hp === 1) {
            assert.equal(state.lastAction.type, "THIEN_CAM_BLOCKED");
            assert.equal(target.judgements.length, 0);
            assert.deepEqual(caster.hand.map(c => c.id), [scroll.id]);
          } else {
            assert.deepEqual(target.judgements.map(c => c.id), [scroll.id]);
            assert.equal(caster.hand.length, 0);
          }
          assert.equal(target.hp, hp);
        });
      }
    }

    test(`${modeId}: non-immune hero at seat ${targetSeat} can receive Trầm Ảo at 1 HP`, () => {
      const state = fresh(modeId, targetSeat, "HERO_1");
      const caster = state.players.find(p => p.seat === state.turnSeat);
      const target = state.players.find(p => p.seat === targetSeat);
      target.hp = 1;
      caster.hand = [card(CARD_SUBTYPES.ACEDIA)];
      assert.equal(handlePlayCard(state, caster.seat, caster.hand[0].id, targetSeat).success, true);
      assert.equal(target.judgements.length, 1);
    });

    test(`${modeId}: existing delayed scroll still blocks a duplicate at seat ${targetSeat}`, () => {
      const state = fresh(modeId, targetSeat);
      const caster = state.players.find(p => p.seat === state.turnSeat);
      const target = state.players.find(p => p.seat === targetSeat);
      target.judgements = [card(CARD_SUBTYPES.ACEDIA, "existing")];
      caster.hand = [card(CARD_SUBTYPES.ACEDIA, "duplicate")];
      assert.match(handlePlayCard(state, caster.seat, "duplicate", targetSeat).error, /cùng loại/);
      assert.equal(target.judgements.length, 1);
      assert.equal(caster.hand.length, 1);
    });
  }
}

for (const modeId of ["dynasty_5", "dynasty_8", "ffa_8", "4v4"]) {
  for (let targetSeat = 5; targetSeat <= getModeRules(modeId).maxPlayers; targetSeat++) {
  for (const subType of [CARD_SUBTYPES.ATTACK_NORMAL, CARD_SUBTYPES.DUEL, CARD_SUBTYPES.DISMANTLE]) {
    test(`${modeId}: other targeted card subtype ${subType} reaches seat ${targetSeat}`, () => {
      const state = fresh(modeId, targetSeat);
      const caster = state.players.find(p => p.seat === state.turnSeat);
      const target = state.players.find(p => p.seat === targetSeat);
      const category = subType === CARD_SUBTYPES.ATTACK_NORMAL ? CARD_CATEGORIES.BASIC : CARD_CATEGORIES.INSTANT_SCROLL;
      const played = card(subType, `targeted-${subType}`, category);
      caster.hand = [played];
      target.hand = [card(CARD_SUBTYPES.DODGE, "target-hand", CARD_CATEGORIES.BASIC)];
      const result = handlePlayCard(state, caster.seat, played.id, targetSeat);
      assert.equal(result.success, true, result.error);
      assert.equal(caster.hand.length, 0);
      if (subType === CARD_SUBTYPES.ATTACK_NORMAL) assert.equal(state.activeCard.targetSeat, targetSeat);
      if (subType === CARD_SUBTYPES.DUEL) assert.equal(state.waitingTargetSeat, targetSeat);
      if (subType === CARD_SUBTYPES.DISMANTLE) assert.equal(state.targetCardSelection.targetSeat, targetSeat);
    });
  }
  }
}

for (const invalidSeat of [0, -1, 2.5, 6, 9, "invalid", null]) {
  test(`five-player match rejects invalid target ${invalidSeat} without consuming the card`, () => {
    const state = fresh("dynasty_5", 5);
    const caster = state.players[3];
    caster.hand = [card(CARD_SUBTYPES.ACEDIA)];
    assert.ok(handlePlayCard(state, 4, caster.hand[0].id, invalidSeat).error);
    assert.equal(caster.hand.length, 1);
    assert.equal(state.players[4].judgements.length, 0);
  });
}

for (const targetSeat of [5, 6, 7, 8]) {
  for (let hero = 1; hero <= 100; hero++) {
    test(`all heroes: HERO_${hero} at seat ${targetSeat} receives Trầm Ảo at full HP`, () => {
      const state = fresh("dynasty_8", targetSeat, `HERO_${hero}`);
      const caster = state.players.find(p => p.seat === state.turnSeat);
      const target = state.players.find(p => p.seat === targetSeat);
      caster.hand = [card(CARD_SUBTYPES.ACEDIA)];
      const result = handlePlayCard(state, caster.seat, caster.hand[0].id, targetSeat);
      assert.equal(result.success, true, result.error);
      assert.equal(target.judgements.length, 1);
    });
  }
}

for (const selection of ["5,6,7,8", [5,6,7,8,8]]) {
  test(`Lý Thường Kiệt can buff all selected seats 5–8 (${typeof selection})`, () => {
    const state = fresh("dynasty_8", 5);
    state.players[3].heroId = "HERO_47";
    state.players[3].hand = [card(CARD_SUBTYPES.ATTACK_NORMAL,"slash",CARD_CATEGORIES.BASIC)];
    handlePlayCard(state,4,"slash",5);
    handleRespondAction(state,5,false,null);
    assert.equal(state.phase,"AWAIT_NAM_QUOC_SON_HA");
    const result = Array.isArray(selection)
      ? handleRespondAction(state,4,true,null,null,selection)
      : handleRespondAction(state,4,true,selection);
    assert.equal(result.success,true);
    assert.deepEqual(state.players.map(p=>p.namQuocSonHaRangeBuff),[0,0,0,0,1,1,1,1]);
  });
}

test("dead seat 5 remains an invalid delayed-scroll target", () => {
  const state = fresh("dynasty_5", 5);
  state.players[4].hp = 0;
  state.players[4].isAlive = false;
  state.players[3].hand = [card(CARD_SUBTYPES.ACEDIA)];
  assert.ok(handlePlayCard(state, 4, state.players[3].hand[0].id, 5).error);
  assert.equal(state.players[3].hand.length, 1);
});

assert.equal(failures.length, 0, `${failures.length} targeting regressions failed; ${passed} passed`);
console.log(`All ${passed} targeting and Thiên Cảm regressions passed.`);
