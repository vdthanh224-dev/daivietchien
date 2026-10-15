import assert from "node:assert/strict";
import { writeFile } from "node:fs/promises";
import {
  initGame, tickGameState, getMatchResult, sanitizeGameStateForClient,
  handlePlayCard, handleRespondAction,
} from "./functions/game-engine/src/gameEngine.js";
import { getModeRules } from "./functions/game-engine/src/modeRegistry.js";
import { CARD_CATEGORIES, CARD_SUBTYPES } from "./functions/game-engine/src/deck.js";

const fixtures = [];
let cases = 0;
for (const modeId of ["dynasty_5", "dynasty_8"]) {
  const rules = getModeRules(modeId);
  assert.equal(rules.roleDistribution.filter(r => r === "KING").length, 1);
  assert.equal(rules.roleDistribution.filter(r => r === "LOYALIST").length, modeId === "dynasty_5" ? 1 : 2);
  assert.equal(rules.roleDistribution.filter(r => r === "REBEL").length, modeId === "dynasty_5" ? 2 : 4);
  assert.equal(rules.roleDistribution.filter(r => r === "SPY").length, 1);
  for (let mask = 0; mask < 2 ** rules.maxPlayers; mask++) {
    const state = initGame(`${modeId}-${mask}`, rules.roleDistribution.map((role, i) => ({seat:i+1,heroId:"HERO_1",role})), modeId);
    for (const p of state.players) {
      p.isAlive = Boolean(mask & (1 << (p.seat - 1)));
      p.hp = p.isAlive ? 4 : 0;
      p.hand = []; p.equipments = []; p.judgements = [];
    }
    state.timerStartAt = Date.now();
    const alive = state.players.filter(p => p.isAlive);
    const kingAlive = alive.some(p => p.role === "KING");
    const expected = !kingAlive
      ? (alive.length === 1 && alive[0].role === "SPY" ? "SPY" : "REBELS")
      : (!alive.some(p => ["REBEL", "SPY"].includes(p.role)) ? "KING" : "");
    tickGameState(state);
    assert.equal(state.status === "FINISHED", Boolean(expected), `${modeId}: living mask ${mask}`);
    if (expected) {
      assert.equal(state.winningRole, expected);
      const winningRoles = expected === "KING" ? ["KING", "LOYALIST"] : [expected === "REBELS" ? "REBEL" : "SPY"];
      for (const p of state.players) {
        const result = getMatchResult(state, p.seat);
        assert.equal(result.isWinner, winningRoles.includes(p.role), "Dead teammates share their faction's victory");
        assert.equal(result.silver, result.isWinner ? 150 : 75);
        const snapshot = sanitizeGameStateForClient(state, p.seat);
        assert.deepEqual(snapshot.result, result);
        assert.equal(snapshot.modeId, modeId);
        assert.equal(snapshot.winningRole, expected);
        if ((expected === "KING" && mask === 1) || expected === "SPY" || mask === 0) fixtures.push({modeId,seat:p.seat,state:snapshot});
      }
      const gameOverCount = state.actionHistory.filter(a => a.type === "GAME_OVER").length;
      assert.equal(gameOverCount, 1);
      tickGameState(state);
      assert.equal(state.actionHistory.filter(a => a.type === "GAME_OVER").length, 1);
    } else assert.equal(getMatchResult(state, 1), null);
    cases++;
  }
  // A dying king still has a rescue opportunity before being declared dead.
  const state = initGame(`dying-${modeId}`, rules.roleDistribution.map((role, i)=>({seat:i+1,heroId:"HERO_1",role})),modeId);
  state.players[0].hp = 0;
  state.phase = "AWAIT_NEAR_DEATH";
  state.waitingTargetSeat = 2;
  state.timerStartAt = Date.now();
  tickGameState(state);
  assert.equal(state.status, "PLAYING");
}

for (const winningTeamId of ["dragon", "phoenix"]) {
  const state = initGame(`2v2-${winningTeamId}`, [1,2,3,4].map(seat=>({seat,heroId:"HERO_1"})));
  for (const p of state.players) {
    // Leave only one team member alive; its dead teammate must still win.
    p.isAlive = p.teamId === winningTeamId && p.seat <= 2;
    p.hp = p.isAlive ? 4 : 0;
  }
  tickGameState(state);
  assert.equal(state.status,"FINISHED");
  for (const p of state.players) {
    const snapshot = sanitizeGameStateForClient(state,p.seat);
    assert.equal(snapshot.result.isWinner,p.teamId===winningTeamId);
    assert.equal(snapshot.result.silver,p.teamId===winningTeamId?150:75);
    fixtures.push({modeId:"2v2",seat:p.seat,state:snapshot});
  }
}

// Finish through the actual slash/death path, without waiting for the next tick.
for (const modeId of ["dynasty_5", "dynasty_8"]) {
  const state = initGame(`king-death-${modeId}`, getModeRules(modeId).roleDistribution.map((role,i)=>({seat:i+1,heroId:"HERO_1",role})),modeId);
  for (const p of state.players) {p.hand=[];p.equipments=[];p.judgements=[];}
  state.players[0].hp=1;
  state.turnSeat=2;
  state.phase="PLAY";
  state.players[1].hand=[{id:"kill-king",name:"Trảm",category:CARD_CATEGORIES.BASIC,subType:CARD_SUBTYPES.ATTACK_NORMAL,suit:"Spade",rank:7}];
  assert.equal(handlePlayCard(state,2,"kill-king",1).success,true);
  handleRespondAction(state,1,false,null);
  for (let response = 0; response < state.players.length && state.phase === "AWAIT_NEAR_DEATH"; response++) {
    handleRespondAction(state,state.waitingTargetSeat,false,null);
  }
  assert.equal(state.players[0].isAlive,false);
  assert.equal(state.status,"FINISHED");
  assert.equal(state.winningRole,"REBELS");
}

if (process.env.RESULT_FIXTURE_PATH) await writeFile(process.env.RESULT_FIXTURE_PATH,JSON.stringify(fixtures,null,2));
console.log(`Match results, immediate king death, team rewards, and all ${cases} dynasty survivor combinations: PASS`);
