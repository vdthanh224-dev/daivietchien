import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import {
  initGame, handleEndTurn, handleRespondAction, handleAIReaction,
  handleDiscardCards, handlePlayCard, handleUseSkill, tickGameState,
  executeFallbackReactionForSeat, hydrateGameState,
} from "./functions/game-engine/src/gameEngine.js";
import { CARD_CATEGORIES, CARD_SUBTYPES } from "./functions/game-engine/src/deck.js";

function card(id, subType = CARD_SUBTYPES.ATTACK_NORMAL) {
  return { id, name: id, subType, category: CARD_CATEGORIES.BASIC, suit: "Spade", rank: 7 };
}

function fresh(heroId = "HERO_24", isAI = false) {
  const state = initGame("waiting-progress", [1, 2, 3, 4].map((seat) => ({
    seat, heroId: seat === 1 ? heroId : "HERO_1", isAI: seat === 1 && isAI,
  })));
  for (const player of state.players) {
    player.hand = [];
    player.equipments = [];
    player.judgements = [];
    player.usedSkills = {};
  }
  Object.assign(state, { phase: "PLAY", turnSeat: 1, waitingTargetSeat: 0, activeCard: null, turnStart: null });
  return state;
}

function promptAnTich(state, count = 2) {
  state.players[0].hand = Array.from({ length: count }, (_, i) => card(`hide-${i}`));
  assert.equal(handleEndTurn(state, 1).success, true);
  assert.equal(state.phase, "AWAIT_AN_TICH");
}

const tests = [];
function test(name, run) { tests.push({ name, run }); }

test("live dynasty_5 scenario: AI Ngô Xương Ngập completes Ẩn Tích", () => {
  const state = initGame("live-an-tich", [18, 42, 13, 39, 24].map((hero, i) => ({
    seat: i + 1, heroId: `HERO_${hero}`, isAI: i !== 1,
  })), "dynasty_5");
  Object.assign(state, { phase: "PLAY", turnSeat: 5, waitingTargetSeat: 0, turnStart: null, turnDamageDealt: false });
  const player = state.players[4];
  player.hand = Array.from({ length: 4 }, (_, i) => card(`live-${i}`));
  assert.equal(handleEndTurn(state, 5).success, true);
  assert.equal(state.phase, "AWAIT_AN_TICH");
  state.timerStartAt = Date.now() - 2600;
  tickGameState(state, [2]);
  assert.notEqual(state.phase, "AWAIT_AN_TICH");
  assert.equal(player.anTichCards.length, 1);
  assert.equal(player.hand.length, 3);
  assert.equal(state.turnSeat, 1);
});

test("declining Ẩn Tích continues the end of turn", () => {
  const state = fresh();
  promptAnTich(state);
  assert.equal(handleRespondAction(state, 1, false, null).success, true);
  assert.equal(state.turnSeat, 2);
  assert.equal(state.players[0].anTichCards.length, 0);
});

test("declining Ẩn Tích still enforces discard and does not prompt again", () => {
  const state = fresh();
  promptAnTich(state, 4);
  assert.equal(handleRespondAction(state, 1, false, null).success, true);
  assert.equal(state.phase, "DISCARD");
  assert.equal(handleDiscardCards(state, 1, [state.players[0].hand[0].id]).success, true);
  assert.equal(state.turnSeat, 2);
});

test("accepting Ẩn Tích continues discarding excess cards", () => {
  const state = fresh();
  promptAnTich(state, 5);
  assert.equal(handleRespondAction(state, 1, true, "hide-0").success, true);
  assert.equal(state.phase, "DISCARD");
  assert.deepEqual(state.players[0].anTichCards.map(c => c.id), ["hide-0"]);
  assert.equal(handleDiscardCards(state, 1, ["hide-1"]).success, true);
  assert.equal(state.turnSeat, 2);
});

test("invalid Ẩn Tích choice keeps the hand and prompt intact", () => {
  const state = fresh();
  promptAnTich(state);
  assert.ok(handleRespondAction(state, 1, true, "missing").error);
  assert.equal(state.phase, "AWAIT_AN_TICH");
  assert.equal(state.players[0].hand.length, 2);
  assert.equal(handleRespondAction(state, 1, true, "hide-0").success, true);
  assert.equal(state.turnSeat, 2);
});

test("human Ẩn Tích timeout resolves without another 40-second loop", () => {
  const state = fresh();
  promptAnTich(state);
  state.timerStartAt = Date.now() - 41000;
  tickGameState(state, [1, 2, 3, 4]);
  assert.equal(state.turnSeat, 2);
  assert.notEqual(state.phase, "AWAIT_AN_TICH");
});

test("connected human keeps the full response window", () => {
  const state = fresh();
  promptAnTich(state);
  state.timerStartAt = Date.now() - 2000;
  tickGameState(state, [1, 2, 3, 4]);
  assert.equal(state.phase, "AWAIT_AN_TICH");
  assert.equal(state.players[0].anTichCards.length, 0);
});

test("disconnected human Ẩn Tích progresses immediately under AI takeover", () => {
  const state = fresh();
  promptAnTich(state);
  state.players[0].isAiTakeover = true;
  state.timerStartAt = Date.now() - 2600;
  tickGameState(state, [2, 3, 4]);
  assert.equal(state.turnSeat, 2);
});

test("already waiting persisted match recovers without a new prompt marker", () => {
  const original = fresh("HERO_24", true);
  promptAnTich(original);
  delete original.players[0].usedSkills.AnTichResolved;
  const state = hydrateGameState(JSON.parse(JSON.stringify(original)));
  state.timerStartAt = Date.now() - 41000;
  tickGameState(state, [2, 3, 4]);
  assert.equal(state.turnSeat, 2);
});

test("AI uses its hidden Ẩn Tích card to dodge a slash", () => {
  const state = fresh("HERO_24", true);
  const player = state.players[0];
  player.anTichCards = [card("hidden")];
  state.turnSeat = 2;
  state.players[1].hand = [card("slash")];
  assert.equal(handlePlayCard(state, 2, "slash", 1).success, true);
  assert.equal(state.phase, "AWAIT_SLASH_DEFENSE");
  assert.equal(handleAIReaction(state, 1).success, true);
  assert.equal(player.hp, 3);
  assert.equal(player.anTichCards.length, 0);
  assert.ok(state._discard.some(c => c.id === "hidden"));
});

test("Ẩn Tích becomes available on the next own turn", () => {
  const state = fresh();
  promptAnTich(state);
  handleRespondAction(state, 1, false, null);
  for (const seat of [2, 3, 4]) {
    state.players[seat - 1].hand = [];
    assert.equal(handleEndTurn(state, seat).success, true);
  }
  assert.equal(state.turnSeat, 1);
  promptAnTich(state);
});

test("fallback handles Thủ Pháp for a human who timed out", () => {
  const state = fresh("HERO_41");
  state.phase = "AWAIT_THU_PHAP_DISCARD";
  state.waitingTargetSeat = 1;
  state.players[0].hand = [card("discard-me")];
  assert.equal(executeFallbackReactionForSeat(state, 1, state.players[0]).success, true);
  assert.notEqual(state.phase, "AWAIT_THU_PHAP_DISCARD");
  assert.equal(state.players[0].hand.length, 0);
});

for (const disconnected of [false, true]) {
  test(`server loop resolves Thủ Pháp for ${disconnected ? "AI takeover" : "a connected human timeout"}`, () => {
    const state = fresh("HERO_41");
    state.phase = "AWAIT_THU_PHAP_DISCARD";
    state.waitingTargetSeat = 1;
    state.players[0].hand = [card("discard-me")];
    state.players[0].isAiTakeover = disconnected;
    state.timerStartAt = Date.now() - (disconnected ? 2600 : 41000);
    tickGameState(state, disconnected ? [2, 3, 4] : [1, 2, 3, 4]);
    assert.equal(state.turnSeat, 2);
    assert.equal(state.players[0].hand.length, 0);
  });
}

test("fallback declines Ẩn Tích and continues discarding", () => {
  const state = fresh();
  promptAnTich(state, 4);
  assert.equal(executeFallbackReactionForSeat(state, 1, state.players[0]).success, true);
  assert.equal(state.phase, "DISCARD");
  assert.equal(state.players[0].anTichCards.length, 0);
});

test("AI can finish Ẩn Tích if its hand became empty while waiting", () => {
  const state = fresh("HERO_24", true);
  promptAnTich(state);
  state.players[0].hand = [];
  assert.equal(handleAIReaction(state, 1).success, true);
  assert.equal(state.turnSeat, 2);
});

test("fallback declines Oai Nhược and resolves slash damage", () => {
  const state = fresh("HERO_9");
  state.players[0].hand = [card("water-slash", CARD_SUBTYPES.ATTACK_WATER)];
  assert.equal(handlePlayCard(state, 1, "water-slash", 2).success, true);
  assert.equal(state.phase, "AWAIT_OAI_NHUOC");
  const target = state.players[1];
  assert.equal(executeFallbackReactionForSeat(state, 2, target).success, true);
  assert.notEqual(state.phase, "AWAIT_OAI_NHUOC");
  assert.equal(target.hp, 3);
});

test("fallback resolves Chuyên Chế with no slash", () => {
  const state = fresh("HERO_49");
  state.players[0].hand = [card("cost")];
  state.players[1].equipments = [{ ...card("weapon", CARD_SUBTYPES.WEAPON), category: CARD_CATEGORIES.EQUIPMENT }];
  assert.equal(handleUseSkill(state, 1, "Chuyên Chế", 2, "cost").success, true);
  assert.equal(state.phase, "AWAIT_CHUYEN_CHE_RESPOND");
  assert.equal(executeFallbackReactionForSeat(state, 2, state.players[1]).success, true);
  assert.notEqual(state.phase, "AWAIT_CHUYEN_CHE_RESPOND");
  assert.equal(state.players[1].hp, 3);
});

test("fallback declines Bổn Phận and continues turn", () => {
  const state = fresh("HERO_50");
  state.players[0].hand = [card("gift")];
  handleEndTurn(state, 1);
  assert.equal(state.phase, "AWAIT_BON_PHAN");
  assert.equal(executeFallbackReactionForSeat(state, 1, state.players[0]).success, true);
  assert.equal(state.turnSeat, 2);
});

test("fallback declines Nam Quốc Sơn Hà and resumes play", () => {
  const state = fresh("HERO_47");
  state.players[0].hand = [card("slash")];
  handlePlayCard(state, 1, "slash", 2);
  handleRespondAction(state, 2, false, null);
  assert.equal(state.phase, "AWAIT_NAM_QUOC_SON_HA");
  assert.equal(executeFallbackReactionForSeat(state, 1, state.players[0]).success, true);
  assert.notEqual(state.phase, "AWAIT_NAM_QUOC_SON_HA");
});

test("every player response phase has a timeout fallback", () => {
  const source = readFileSync(new URL("./functions/game-engine/src/gameEngine.js", import.meta.url), "utf8");
  const phases = text => new Set([...text.matchAll(/"(AWAIT_[A-Z_]+)"/g)].map(match => match[1]));
  const fallback = phases(source.slice(source.indexOf("export function executeFallbackReactionForSeat"), source.indexOf("export function tickGameState")));
  assert.deepEqual([...phases(source)].filter(phase => phase !== "AWAIT_JUDGEMENT" && !fallback.has(phase)), []);
});

let failures = 0;
for (const { name, run } of tests) {
  try { run(); console.log(`PASS ${name}`); }
  catch (error) { failures++; console.error(`FAIL ${name}: ${error.message}`); }
}
assert.equal(failures, 0, `${failures}/${tests.length} waiting progress regressions failed`);
console.log(`All ${tests.length} waiting progress regressions passed.`);
