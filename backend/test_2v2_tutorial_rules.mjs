import assert from "node:assert/strict";
import {
  applyDamageToPlayer,
  handleDiscardCards,
  handleEndTurn,
  handleAIStep,
  handlePlayCard,
  handleRespondAction,
  initGame,
  sanitizeGameStateForClient,
} from "./functions/game-engine/src/gameEngine.js";
import { createFullDeck104 } from "./functions/game-engine/src/deck.js";

const catalog = new Map(createFullDeck104().map((card) => [card.id, card]));
const card = (id) => ({ ...catalog.get(id) });
const players = [
  { seat: 1, userId: "u1", generalName: "P1", maxHp: 4 },
  { seat: 2, userId: "u2", generalName: "P2", maxHp: 4 },
  { seat: 3, userId: "u3", generalName: "P3", maxHp: 4 },
  { seat: 4, userId: "u4", generalName: "P4", maxHp: 4 },
];

function freshState() {
  const state = initGame("tutorial-rules", players);
  state.players.forEach((player) => {
    player.hand = [];
    player.equipments = [];
    player.judgements = [];
    player.hp = player.maxHp;
  });
  state.turnSeat = 1;
  state.phase = "PLAY";
  state.waitingTargetSeat = 0;
  state.waitingTimer = 0;
  state.activeCard = null;
  state.nullifyChain = null;
  state.targetCardSelection = null;
  state.harvestPool = [];
  state.harvestPickers = [];
  state.aoeVictimsQueue = [];
  state._discard = [];
  state.discardTop = null;
  return state;
}

function passNullify(state) {
  while (state.phase === "AWAIT_NULLIFY") {
    const result = handleRespondAction(state, state.waitingTargetSeat, false, null);
    assert.equal(result.success, true);
  }
}

function playAndOpenTargetSelection(state, cardId, targetSeat) {
  const result = handlePlayCard(state, 1, cardId, targetSeat);
  assert.equal(result.success, true);
  passNullify(state);
  assert.equal(state.phase, "AWAIT_TARGET_CARD");
}

assert.equal(initGame("initial", players).players[0].hand.length, 5);
assert.equal(initGame("initial", players).players[1].hand.length, 4);
assert.equal(initGame("initial", players).deckCount, 35);

const hiddenState = initGame("privacy", players);
const anonymous = sanitizeGameStateForClient(hiddenState);
assert.ok(anonymous.players.every((player) => player.hand.every((hidden) => hidden.id === "HIDDEN")));
const seatOneView = sanitizeGameStateForClient(hiddenState, 1);
assert.equal(seatOneView.players.find((player) => player.seat === 1).hand[0].id, hiddenState.players[0].hand[0].id);
assert.ok(seatOneView.players.find((player) => player.seat === 2).hand.every((hidden) => hidden.id === "HIDDEN"));

const drawState = initGame("draw", players);
const firstDiscardId = drawState.players[0].hand[0].id;
assert.equal(handleEndTurn(drawState, 1).success, true);
assert.equal(drawState.phase, "DISCARD");
assert.equal(handleDiscardCards(drawState, 1, [firstDiscardId]).success, true);
assert.equal(drawState.turnSeat, 2);
assert.equal(drawState.players[1].hand.length, 6);

const targetState = freshState();
const target = targetState.players[1];
target.hand = [card("D1_C_8")];
target.equipments = [card("D1_C_5")];
target.judgements = [card("D1_S_6")];
targetState.players[0].hand = [card("D1_S_3")];
playAndOpenTargetSelection(targetState, "D1_S_3", 2);
assert.deepEqual(targetState.targetCardSelection.options.map((option) => option.zone), ["HAND", "EQUIPMENT", "JUDGEMENT"]);
const hiddenHandOption = targetState.targetCardSelection.options.find((option) => option.zone === "HAND");
assert.equal(hiddenHandOption.card, null);
assert.equal(handleRespondAction(targetState, 1, true, null, hiddenHandOption.token).success, true);
assert.equal(target.hand.length, 0);
assert.equal(targetState.lastAction.targetCardId, null);
assert.equal(targetState.lastAction.targetCardName, "lá úp trên tay");
assert.equal(targetState.discardTop.id, "HIDDEN");

targetState.players[0].hand = [card("D1_S_A")];
playAndOpenTargetSelection(targetState, "D1_S_A", 2);
assert.ok(targetState.targetCardSelection.options.some((option) => option.zone === "JUDGEMENT"));
const equipmentOption = targetState.targetCardSelection.options.find((option) => option.zone === "EQUIPMENT");
assert.equal(handleRespondAction(targetState, 1, true, null, equipmentOption.token).success, true);
assert.equal(target.equipments.length, 0);
assert.equal(targetState.lastAction.targetCardZone, "EQUIPMENT");
assert.equal(targetState.lastAction.targetCardId, "D1_C_5");

targetState.players[0].hand = [card("D1_H_Q")];
playAndOpenTargetSelection(targetState, "D1_H_Q", 2);
const judgementOption = targetState.targetCardSelection.options.find((option) => option.zone === "JUDGEMENT");
assert.ok(judgementOption);
assert.equal(handleRespondAction(targetState, "1", true, null, judgementOption.token).success, true);
assert.equal(target.judgements.length, 0);
assert.equal(targetState.lastAction.targetCardZone, "JUDGEMENT");

targetState.players[0].hand = [card("D1_S_7")];
target.hand = [card("D1_C_9")];
playAndOpenTargetSelection(targetState, "D1_S_7", 2);
const stealHandOption = targetState.targetCardSelection.options.find((option) => option.zone === "HAND");
assert.equal(handleRespondAction(targetState, 1, true, null, stealHandOption.token).success, true);
assert.equal(target.hand.length, 0);
assert.equal(targetState.players[0].hand.length, 1);
assert.equal(targetState.lastAction.targetCardId, null);
assert.equal(targetState.lastAction.targetCardName, "lá úp trên tay");

targetState.players[0].hand = [card("D1_S_7")];
target.hand = [];
target.equipments = [card("D1_C_5")];
target.judgements = [card("D1_S_6")];
playAndOpenTargetSelection(targetState, "D1_S_7", 2);
assert.deepEqual(targetState.targetCardSelection.options.map((option) => option.zone), ["EQUIPMENT", "JUDGEMENT"]);
const stealJudgementOption = targetState.targetCardSelection.options.find((option) => option.zone === "JUDGEMENT");
assert.equal(handleRespondAction(targetState, 1, true, null, stealJudgementOption.token).success, true);
assert.equal(target.judgements.length, 0);
assert.equal(targetState.players[0].hand.at(-1).id, "D1_S_6");

const reverseState = freshState();
reverseState.players[0].hand = [card("D1_H_3")];
reverseState.players[1].hand = [card("D1_C_4")];
reverseState.players[2].hand = [card("D1_H_Q")];
assert.equal(handlePlayCard(reverseState, 1, "D1_H_3", 0).success, true);
assert.equal(handleRespondAction(reverseState, 1, false, null).success, true);
assert.equal(handleRespondAction(reverseState, 2, true, "D1_C_4").success, true);
assert.equal(reverseState.phase, "AWAIT_NULLIFY");
assert.equal(reverseState.nullifyChain.isCanceled, true);
assert.equal(handleRespondAction(reverseState, 3, true, "D1_H_Q").success, true);
assert.equal(reverseState.nullifyChain.isCanceled, false);
while (reverseState.phase === "AWAIT_NULLIFY") {
  assert.equal(handleRespondAction(reverseState, reverseState.waitingTargetSeat, false, null).success, true);
}
assert.equal(reverseState.phase, "PLAY");
assert.equal(reverseState.players[0].hand.length, 2);

const activeFlawlessState = freshState();
activeFlawlessState.players[0].hand = [card("D1_S_A")];
activeFlawlessState.players[1].hand = [card("D1_C_8"), card("D1_C_4")];
activeFlawlessState.players[1].equipments = [card("D1_C_5")];
activeFlawlessState.players[2].hand = [card("D1_H_Q")];
assert.equal(handlePlayCard(activeFlawlessState, 1, "D1_S_A", 2).success, true);
assert.equal(activeFlawlessState.phase, "AWAIT_NULLIFY");
assert.equal(activeFlawlessState.players[0].hand.length, 0);
assert.equal(activeFlawlessState._discard.length, 0);
assert.equal(handleRespondAction(activeFlawlessState, 1, false, null).success, true);
assert.equal(handleRespondAction(activeFlawlessState, 2, true, "D1_C_4").success, true);
assert.equal(activeFlawlessState.nullifyChain.isCanceled, true);
assert.equal(handleRespondAction(activeFlawlessState, 3, true, "D1_H_Q").success, true);
while (activeFlawlessState.phase === "AWAIT_NULLIFY") {
  assert.equal(handleRespondAction(activeFlawlessState, activeFlawlessState.waitingTargetSeat, false, null).success, true);
}
assert.equal(activeFlawlessState.phase, "AWAIT_TARGET_CARD");
assert.equal(activeFlawlessState._discard.filter((discarded) => discarded.id === "D1_S_A").length, 1);
assert.equal(activeFlawlessState.targetCardSelection.options.length, 2);

const aiDiscardState = freshState();
aiDiscardState.players[0].hp = 2;
aiDiscardState.players[0].hand = [card("D1_C_8"), card("D1_C_9"), card("D1_C_10")];
aiDiscardState.phase = "DISCARD";
aiDiscardState.waitingTargetSeat = 1;
assert.equal(handleAIStep(aiDiscardState, "1").success, true);
assert.equal(aiDiscardState.phase, "PLAY");
assert.equal(aiDiscardState.turnSeat, 2);
assert.equal(aiDiscardState.discardTop.id, "HIDDEN");

const deathPrivacyState = freshState();
deathPrivacyState.players[2].hp = 1;
deathPrivacyState.players[2].hand = [card("D1_C_8")];
assert.equal(applyDamageToPlayer(deathPrivacyState, 3, 1).enteredNearDeath, true);
while (deathPrivacyState.phase === "AWAIT_NEAR_DEATH") {
  assert.equal(handleRespondAction(deathPrivacyState, deathPrivacyState.waitingTargetSeat, false, null).success, true);
}
assert.equal(deathPrivacyState.players[2].hp, 0);
assert.equal(deathPrivacyState.discardTop.id, "HIDDEN");

const rescueState = freshState();
rescueState.players[2].hp = 1;
rescueState.players[1].hand = [card("D1_H_6")];
assert.equal(applyDamageToPlayer(rescueState, 3, 1).enteredNearDeath, true);
assert.deepEqual([rescueState.waitingTargetSeat, ...rescueState.nearDeathAskerQueue], [1, 2, 3, 4]);
assert.equal(handleRespondAction(rescueState, 1, false, null).success, true);
assert.equal(handleRespondAction(rescueState, 2, true, "D1_H_6").success, true);
assert.equal(rescueState.players[2].hp, 1);
assert.equal(rescueState.phase, "PLAY");

const harvestState = freshState();
harvestState.players[0].hand = [card("D1_H_A")];
assert.equal(handlePlayCard(harvestState, 1, "D1_H_A", 0).success, true);
passNullify(harvestState);
assert.equal(harvestState.phase, "AWAIT_HARVEST");
assert.deepEqual(harvestState.harvestPickers, [1, 2, 3, 4]);
const harvestHandCounts = harvestState.players.map((player) => player.hand.length);
while (harvestState.phase === "AWAIT_HARVEST") {
  const picker = harvestState.waitingTargetSeat;
  const poolCard = harvestState.harvestPool[0];
  assert.equal(handleRespondAction(harvestState, picker, true, poolCard?.id || null).success, true);
}
assert.equal(harvestState.phase, "PLAY");
assert.equal(harvestState.harvestPool.length, 0);
harvestState.players.forEach((player, index) => assert.equal(player.hand.length, harvestHandCounts[index] + 1));

const aoeState = freshState();
aoeState.players[0].hand = [card("D1_C_2")];
assert.equal(handlePlayCard(aoeState, 1, "D1_C_2", 0).success, true);
passNullify(aoeState);
assert.equal(aoeState.phase, "AWAIT_AOE");
assert.deepEqual([aoeState.waitingTargetSeat, ...aoeState.aoeVictimsQueue], [2, 3, 4]);
while (aoeState.phase === "AWAIT_AOE") {
  assert.equal(handleRespondAction(aoeState, aoeState.waitingTargetSeat, false, null).success, true);
}
assert.deepEqual(aoeState.players.map((player) => player.hp), [4, 3, 3, 3]);
assert.equal(aoeState.phase, "PLAY");

const restrictionState = freshState();
restrictionState.players[0].hand = [card("D1_C_7"), card("D1_D_2")];
assert.match(handlePlayCard(restrictionState, 1, "D1_C_7", 0).error, /Máu đã đầy/);
assert.match(handlePlayCard(restrictionState, 1, "D1_D_2", 0).error, /Đỡ chỉ được dùng/);
restrictionState.players[0].hand = [card("D1_S_8")];
assert.match(handlePlayCard(restrictionState, 1, "D1_S_8", 1).error, /chính mình/);
restrictionState.players[0].hand = [card("D1_S_3")];
assert.match(handlePlayCard(restrictionState, 1, "D1_S_3", 3).error, /đối phương/);
assert.equal(restrictionState.phase, "PLAY");

console.log("2v2 tutorial rules: PASS");
