import assert from "node:assert/strict";
import { initGame, tickGameState } from "./functions/game-engine/src/gameEngine.js";
import { HEROES } from "./functions/game-engine/src/heroes.js";
import { getModeRules } from "./functions/game-engine/src/modeRegistry.js";

// Drive the same timer loop used by Render, including a disconnected human
// taken over by AI. A single tick cannot hide a hang in the all-bot fast path.
const originalNow = Date.now;
const originalRandom = Math.random;
const originalLog = console.log;
let now = 1800000000000;
let randomSeed = 1;
Date.now = () => now;
Math.random = () => {
  randomSeed = (Math.imul(randomSeed, 1664525) + 1013904223) >>> 0;
  return randomSeed / 0x100000000;
};
const engineErrors = [];
console.log = (...args) => { if (args[0] === "[AI STEP ERROR]") engineErrors.push(args.slice(1).join(" ")); };
const ignored = new Set(["version", "actionSeq", "actionHistory", "lastAction", "lastDelta", "delta", "timerStartAt", "waitingTimer", "turnTimer"]);
const fingerprint = (state) => JSON.stringify(state, (key, value) => ignored.has(key) ? undefined : value);
const onlyHero = Number(process.env.AI_AUDIT_HERO || 0);
const seeds = Number(process.env.AI_AUDIT_SEEDS || 2);
const maxSteps = Number(process.env.AI_AUDIT_MAX_STEPS || 6000);
const allBots = process.env.AI_AUDIT_ALL_BOTS === "1";
const modes = (process.env.AI_AUDIT_MODES || "2v2,dynasty_5,dynasty_8").split(",");
const failures = [];
const coverage = new Set();
const phases = new Set();
let matches = 0;
let decisions = 0;
try {
  for (let hero = 1; hero <= 50; hero++) {
    if (onlyHero && onlyHero !== hero) continue;
    for (let seed = 1; seed <= seeds; seed++) {
      for (const modeId of modes) {
        randomSeed = hero * 100003 + seed * 997 + modes.indexOf(modeId);
        const size = getModeRules(modeId).maxPlayers;
        const players = Array.from({ length: size }, (_, index) => ({
          seat: index + 1, heroId: `HERO_${index === 0 ? hero : 1 + ((hero + index * 13 + seed * 7) % 50)}`,
          userId: `audit_${index + 1}`, userName: `Audit ${index + 1}`, isAI: allBots || index !== 0,
        }));
        const state = initGame(`ai-audit-${hero}-${seed}-${modeId}`, players, modeId);
        state.players[0].isAiTakeover = true;
        let stagnant = 0;
        let sameTurn = 0;
        const turnKey = () => `${state.turnSeat}:${state.players.map((p) => p.turnsTaken).join(',')}`;
        let previousTurn = turnKey();
        let previous = fingerprint(state);
        let steps = 0;
        const trace = [];
        try {
          for (; steps < maxSteps && state.status !== "FINISHED"; steps++) {
            phases.add(state.phase);
            const actor = state.players.find((p) => p.seat === (state.waitingTargetSeat || state.turnSeat));
            if (actor) coverage.add(actor.heroId);
            now += 3000;
            state.timerStartAt = now - 2600;
            tickGameState(state, []);
            decisions++;
            const current = fingerprint(state);
            stagnant = current === previous ? stagnant + 1 : 0;
            sameTurn = previousTurn === turnKey() ? sameTurn + 1 : 0;
            previousTurn = turnKey();
            previous = current;
            trace.push(`${state.phase}:${state.waitingTargetSeat || state.turnSeat}:${state.lastAction?.type || "-"}`);
            if (trace.length > 12) trace.shift();
            assert(stagnant < 3, `No progress at ${state.phase}, actor ${actor?.heroId}, trace ${trace.join(" > ")}`);
            assert(sameTurn < 400, `Turn repeated 400 decisions: ${trace.join(" > ")}`);
            assert(state.players.every((p) => Number.isFinite(p.hp) && Array.isArray(p.hand)), "Corrupted player state");
            if (["PLAY", "DISCARD"].includes(state.phase)) {
              const orphan = state.players.find((p) => p.isAlive !== false && p.hp <= 0);
              assert(!orphan, `Unresolved dying player ${orphan?.heroId} seat ${orphan?.seat}: ${trace.join(" > ")}; pending ${JSON.stringify({near:state.pendingNearDeath,after:state.pendingAfterNearDeath,uat:state.pendingAfterUatKhi,chain:state.pendingChainSpread,active:state.activeCard})}`);
            }
          }
          assert.equal(state.status, "FINISHED", `Match exceeded ${maxSteps} decisions: ${trace.join(" > ")}`);
          matches++;
        } catch (error) {
          failures.push({ hero, name: HEROES[`HERO_${hero}`].name, seed, modeId, steps, error: error.message,
            players: state.players.map((p) => ({ seat: p.seat, hero: p.heroId, hp: p.hp, alive: p.isAlive, role: p.role, team: p.teamId })) });
        }
      }
    }
    if (hero % 10 === 0) originalLog(`Audited heroes 1-${hero}: ${matches} completed, ${failures.length} failures`);
  }
} finally {
  Date.now = originalNow;
  Math.random = originalRandom;
  console.log = originalLog;
}
console.log(JSON.stringify({ matches, decisions, heroesExercised: coverage.size, waitingPhases: phases.size, rejectedActions: engineErrors.length, failedMatches: failures.length }));
for (const failure of failures.slice(0, 25)) console.error(JSON.stringify(failure));
for (const error of [...new Set(engineErrors)].slice(0, 15)) console.error(`REJECTED: ${error}`);
assert.equal(failures.length, 0, "Every audited hero must complete all simulated matches without stalls");
assert.equal(engineErrors.length, 0, "AI must not submit rejected actions");
console.log("PASS: AI heroes 1-50, full matches, reactions and disconnected-player takeover");
