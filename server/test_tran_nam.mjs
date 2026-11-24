import assert from "node:assert/strict";
import {
  handlePlayCard,
  handleRespondAction,
  initGame
} from "./functions/game-engine/src/gameEngine.js";
import { CARD_CATEGORIES, CARD_SUBTYPES } from "./functions/game-engine/src/deck.js";

function createTestState(casterHeroId = "HERO_13", targetHeroId = "HERO_1") {
  const state = initGame("test-tran-nam", [
    { seat: 1, heroId: casterHeroId, generalName: "P1" },
    { seat: 2, heroId: targetHeroId, generalName: "P2" },
    { seat: 3, heroId: "HERO_2", generalName: "P3" },
    { seat: 4, heroId: "HERO_3", generalName: "P4" }
  ]);
  state.phase = "PLAY";
  state.turnSeat = 1;
  for (const p of state.players) {
    p.hand = [];
    p.equipments = [];
    p.judgements = [];
    p.hp = p.maxHp;
    p.usedSkills = {};
  }
  state.players[1].hand = [
    { id: "DODGE_1", name: "Đỡ", suit: "Diamond", rank: 2, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.DODGE }
  ];
  return state;
}

// 1. Black Normal Slash (Spade) -> Target cannot dodge (unavoidable)
{
  const state = createTestState("HERO_13", "HERO_1");
  state.players[0].hand.push({
    id: "SLASH_BLACK",
    name: "Trảm",
    suit: "Spade",
    rank: 8,
    category: CARD_CATEGORIES.BASIC,
    subType: CARD_SUBTYPES.ATTACK_NORMAL
  });
  const res = handlePlayCard(state, 1, "SLASH_BLACK", 2);
  assert.equal(res.success, true);
  assert.equal(state.players[1].hp, state.players[1].maxHp - 1, "Target should take 1 damage immediately");
  assert.equal(state.phase, "PLAY", "Phase should remain PLAY without waiting for defense");
  const unavoidableAction = state.actionHistory.find((a) => a.type === "SLASH_ATTACK_UNAVOIDABLE");
  assert.ok(unavoidableAction, "Should record SLASH_ATTACK_UNAVOIDABLE");
  assert.equal(unavoidableAction.skillActivations[0].name, "Trấn Nam");
  console.log("✅ Case 1: Black normal slash cannot be dodged");
}

// 2. Yellow Normal Slash (Club) -> Target cannot dodge (unavoidable)
{
  const state = createTestState("HERO_13", "HERO_1");
  state.players[0].hand.push({
    id: "SLASH_YELLOW",
    name: "Trảm",
    suit: "Club",
    rank: 5,
    category: CARD_CATEGORIES.BASIC,
    subType: CARD_SUBTYPES.ATTACK_NORMAL
  });
  const res = handlePlayCard(state, 1, "SLASH_YELLOW", 2);
  assert.equal(res.success, true);
  assert.equal(state.players[1].hp, state.players[1].maxHp - 1, "Target should take 1 damage immediately");
  assert.equal(state.phase, "PLAY");
  const unavoidableAction = state.actionHistory.find((a) => a.type === "SLASH_ATTACK_UNAVOIDABLE");
  assert.ok(unavoidableAction, "Should record SLASH_ATTACK_UNAVOIDABLE");
  assert.equal(unavoidableAction.skillActivations[0].name, "Trấn Nam");
  console.log("✅ Case 2: Yellow normal slash cannot be dodged");
}

// 3. Red Normal Slash (Heart) -> Target CAN dodge
{
  const state = createTestState("HERO_13", "HERO_1");
  state.players[0].hand.push({
    id: "SLASH_RED",
    name: "Trảm",
    suit: "Heart",
    rank: 7,
    category: CARD_CATEGORIES.BASIC,
    subType: CARD_SUBTYPES.ATTACK_NORMAL
  });
  const res = handlePlayCard(state, 1, "SLASH_RED", 2);
  assert.equal(res.success, true);
  assert.equal(state.phase, "AWAIT_SLASH_DEFENSE", "Red normal slash requires defense");
  assert.equal(state.waitingTargetSeat, 2);
  assert.equal(state.players[1].hp, state.players[1].maxHp, "Target has not taken damage yet");
  console.log("✅ Case 3: Red normal slash can be dodged");
}

// 4. White Normal Slash (Diamond) -> Target CAN dodge
{
  const state = createTestState("HERO_13", "HERO_1");
  state.players[0].hand.push({
    id: "SLASH_WHITE",
    name: "Trảm",
    suit: "Diamond",
    rank: 9,
    category: CARD_CATEGORIES.BASIC,
    subType: CARD_SUBTYPES.ATTACK_NORMAL
  });
  const res = handlePlayCard(state, 1, "SLASH_WHITE", 2);
  assert.equal(res.success, true);
  assert.equal(state.phase, "AWAIT_SLASH_DEFENSE", "White normal slash requires defense");
  assert.equal(state.waitingTargetSeat, 2);
  assert.equal(state.players[1].hp, state.players[1].maxHp);
  console.log("✅ Case 4: White normal slash can be dodged");
}

// 5. Black Elemental Slash (Fire, Spade) -> Target CAN dodge (not a normal slash)
{
  const state = createTestState("HERO_13", "HERO_1");
  state.players[0].hand.push({
    id: "SLASH_FIRE_BLACK",
    name: "Trảm - Hỏa",
    suit: "Spade",
    rank: 4,
    category: CARD_CATEGORIES.BASIC,
    subType: CARD_SUBTYPES.ATTACK_FIRE
  });
  const res = handlePlayCard(state, 1, "SLASH_FIRE_BLACK", 2);
  assert.equal(res.success, true);
  assert.equal(state.phase, "AWAIT_SLASH_DEFENSE", "Black fire slash requires defense");
  assert.equal(state.waitingTargetSeat, 2);
  assert.equal(state.players[1].hp, state.players[1].maxHp);
  console.log("✅ Case 5: Black fire slash can be dodged");
}

// 6. Non-Phạm-Tu hero playing Black Normal Slash -> Target CAN dodge
{
  const state = createTestState("HERO_1", "HERO_2"); // Hero 1 (An Dương Vương)
  state.players[0].hand.push({
    id: "SLASH_BLACK_OTHER",
    name: "Trảm",
    suit: "Spade",
    rank: 8,
    category: CARD_CATEGORIES.BASIC,
    subType: CARD_SUBTYPES.ATTACK_NORMAL
  });
  const res = handlePlayCard(state, 1, "SLASH_BLACK_OTHER", 2);
  assert.equal(res.success, true);
  assert.equal(state.phase, "AWAIT_SLASH_DEFENSE", "Other hero's slash can be dodged");
  console.log("✅ Case 6: Non-Phạm-Tu slash can be dodged");
}

// 7. Giặc Tới on Phạm Tu -> Not immune, enters AWAIT_AOE
{
  const state = createTestState("HERO_1", "HERO_13"); // Hero 1 casts Giặc Tới, target is Phạm Tu (seat 2)
  state.players[0].hand.push({
    id: "GIAC_TOI",
    name: "Giặc Tới",
    suit: "Club",
    rank: 7,
    category: CARD_CATEGORIES.INSTANT_SCROLL,
    subType: CARD_SUBTYPES.BARBARIAN_INVASION
  });
  const res = handlePlayCard(state, 1, "GIAC_TOI");
  assert.equal(res.success, true);
  assert.equal(state.phase, "AWAIT_AOE", "Phạm Tu should be asked to react to Giặc Tới");
  assert.equal(state.waitingTargetSeat, 2);
  console.log("✅ Case 7: Phạm Tu is no longer immune to Giặc Tới");
}

console.log("🎉 All Trấn Nam (Phạm Tu) unit tests passed!");
