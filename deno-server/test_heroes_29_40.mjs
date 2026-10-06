import assert from "node:assert/strict";
import { CARD_CATEGORIES, CARD_SUBTYPES } from "./deck.js";
import { handleRespondAction, handleUseSkill, handlePlayCard, initGame, applyDamageToPlayer } from "./gameEngine.js";

console.log("=== Testing Heroes 29-40 Skills ===");

// 1. Test Định Quốc (Nguyễn Bặc - HERO_33)
{
  const state = initGame("test-dq", [
    { seat: 1, heroId: "HERO_33" },
    { seat: 2, heroId: "HERO_1" },
    { seat: 3, heroId: "HERO_2" },
    { seat: 4, heroId: "HERO_3" }
  ]);
  state.phase = "PLAY";
  state.turnSeat = 1;
  const p1 = state.players[0];
  p1.hand = [{ id: "c_black", name: "Trảm", suit: "Spade", rank: 7, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.SLASH }];
  const res = handleUseSkill(state, 1, "Định Quốc", 2, "c_black");
  assert.ok(res.success || res.state, "Định Quốc should succeed");
  console.log("✅ Định Quốc OK");
}

// 2. Test Trao Bào (Dương Vân Nga - HERO_36)
{
  const state = initGame("test-tb", [
    { seat: 1, heroId: "HERO_36" },
    { seat: 2, heroId: "HERO_1" },
    { seat: 3, heroId: "HERO_2" },
    { seat: 4, heroId: "HERO_3" }
  ]);
  state.phase = "PLAY";
  state.turnSeat = 1;
  const p1 = state.players[0];
  const p2 = state.players[1];
  p2.hp = 2; // injured
  p1.hand = [{ id: "eq_weapon", name: "Song Cung", suit: "Heart", rank: 5, category: CARD_CATEGORIES.EQUIPMENT, subType: CARD_SUBTYPES.WEAPON }];

  // Step 1: Offer equip
  const resOffer = handleUseSkill(state, 1, "Trao Bào", 2, "eq_weapon");
  assert.ok(resOffer.success, "Trao Bào offer should succeed");
  assert.equal(state.phase, "AWAIT_TRAO_BAO_EQUIP", "Phase should be AWAIT_TRAO_BAO_EQUIP");
  assert.equal(state.waitingTargetSeat, 2, "Waiting target seat should be 2");

  // Step 2: Receiver accepts (equips immediately)
  const resEquip = handleRespondAction(state, 2, true, null);
  assert.ok(resEquip.success, "Receiver equip should succeed");
  assert.equal(state.phase, "PLAY", "Phase should return to PLAY");
  assert.equal(p2.hp, 3, "Trao Bào should heal target");
  assert.ok(p2.equipments.some(e => e.id === "eq_weapon"), "Target should have equipped weapon");
  assert.equal(p1.hand.length, 1, "Trao Bào should draw 1 card for caster");

  // Test Decline path (goes to hand instead of equip)
  p2.hp = 2; // injured again
  p1.hand = [{ id: "eq_armor", name: "Áo Giáp", suit: "Club", rank: 6, category: CARD_CATEGORIES.EQUIPMENT, subType: CARD_SUBTYPES.ARMOR }];
  handleUseSkill(state, 1, "Trao Bào", 2, "eq_armor");
  assert.equal(state.phase, "AWAIT_TRAO_BAO_EQUIP");
  handleRespondAction(state, 2, false, null);
  assert.equal(p2.hp, 3, "Target should heal even when declining to equip");
  assert.ok(p2.hand.some(c => c.id === "eq_armor"), "Target should have card in hand when declining to equip");
  assert.ok(!p2.equipments.some(e => e.id === "eq_armor"), "Target should NOT have armor equipped");
  console.log("✅ Trao Bào OK");
}

// 3. Test Nhiếp Chính (Dương Vân Nga - HERO_36)
{
  const state = initGame("test-nc", [
    { seat: 1, heroId: "HERO_1" },
    { seat: 2, heroId: "HERO_36" }, // DVN
    { seat: 3, heroId: "HERO_2" },
    { seat: 4, heroId: "HERO_3" }
  ]);
  const p1 = state.players[0];
  const p2 = state.players[1]; // DVN
  const p3 = state.players[2];
  const p4 = state.players[3];

  p2.hand = [{ id: "dvn_card", name: "Sách", suit: "Spade", rank: 9, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.SLASH }];
  p3.hand = [{ id: "opp_card", name: "Đao", suit: "Heart", rank: 8, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.SLASH }];
  p1.hp = 2; // p1 injured (2/4)
  p4.hp = 2; // p4 injured (2/4)

  // Player 1 takes damage -> triggers Nhiếp Chính prompt for DVN (seat 2)
  applyDamageToPlayer(state, 1, 1, "Test", "NORMAL", false);
  assert.equal(state.phase, "AWAIT_NHIEP_CHINH", "Should enter AWAIT_NHIEP_CHINH");
  assert.equal(state.waitingTargetSeat, 2, "DVN should be prompted");

  // DVN responds: picks her card (rank 9) and challenges seat 3
  const resDvn = handleRespondAction(state, 2, true, "dvn_card", null, null, 3);
  assert.ok(resDvn.success, "DVN challenge should succeed");
  assert.equal(state.phase, "AWAIT_NHIEP_CHINH_DUEL_OPPONENT", "Should enter AWAIT_NHIEP_CHINH_DUEL_OPPONENT");
  assert.equal(state.waitingTargetSeat, 3, "Seat 3 should be prompted for duel card");

  // Seat 3 reveals card (rank 8)
  const resOpp = handleRespondAction(state, 3, true, "opp_card");
  assert.ok(resOpp.success, "Opponent response should succeed");
  // Since both P1 and P4 are injured, DVN gets to choose who to heal!
  assert.equal(state.phase, "AWAIT_NHIEP_CHINH_HEAL", "Should enter AWAIT_NHIEP_CHINH_HEAL because >1 players injured");
  assert.equal(state.waitingTargetSeat, 2, "DVN should choose heal target");

  // DVN chooses P1 to heal
  const resHeal = handleRespondAction(state, 2, true, null, null, null, 1);
  assert.ok(resHeal.success, "Heal selection should succeed");
  assert.equal(p1.hp, 2, "P1 took 1 dmg (from 3 to 2) and healed 1 dmg back (was 1, now 2)");
  console.log("✅ Nhiếp Chính OK");
}

// 4. Test Phá Tống (Lê Hoàn - HERO_35)
{
  const state = initGame("test-pt-slash", [
    { seat: 1, heroId: "HERO_35" }, // Lê Hoàn
    { seat: 2, heroId: "HERO_1" },
    { seat: 3, heroId: "HERO_2" },
    { seat: 4, heroId: "HERO_3" }
  ]);
  state.phase = "PLAY";
  state.turnSeat = 1;
  const p1 = state.players[0];
  const p2 = state.players[1];
  p2.hp = 4;
  p1.hand = [
    { id: "slash_card", name: "Trảm", suit: "Spade", rank: 10, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.ATTACK_NORMAL },
    { id: "cost_card", name: "Bánh Chưng", suit: "Heart", rank: 5, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.PEACH }
  ];

  const res = handlePlayCard(state, 1, "slash_card", 2, { phaTongCardId: "cost_card" });
  assert.ok(res.success, "Phá Tống slash should succeed");
  assert.equal(p1.hand.length, 0, "Both slash card and cost card should be consumed");
  // Target takes unavoidable damage directly, bypassing dodge phase
  assert.equal(p2.hp, 3, "P2 should take 1 damage directly");
  assert.notEqual(state.phase, "AWAIT_SLASH_DEFENSE", "Should NOT enter AWAIT_SLASH_DEFENSE");
  console.log("✅ Phá Tống OK");
}

// 5. Test Thu Phục (Đinh Bộ Lĩnh - HERO_30) via handleRespondAction
{
  const state = initGame("test-tp", [
    { seat: 1, heroId: "HERO_30" },
    { seat: 2, heroId: "HERO_1" },
    { seat: 3, heroId: "HERO_2" },
    { seat: 4, heroId: "HERO_3" }
  ]);
  state.phase = "AWAIT_THU_PHUC";
  state.waitingTargetSeat = 1;
  state.pendingThuPhuc = {
    casterSeat: 1,
    targetSeat: 2,
    card: { id: "ex_nihilo", name: "Dụng Binh Như Thần", category: CARD_CATEGORIES.SCROLL, subType: CARD_SUBTYPES.EX_NIHILO },
    payload: {}
  };
  const p1 = state.players[0];
  const p2 = state.players[1];
  p1.hp = 2;
  p2.hp = 4;
  p2.hand = [{ id: "card_stolen", name: "Trảm", suit: "Club", rank: 8, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.SLASH }];
  const res = handleRespondAction(state, 1, true, null, null, null, 2);
  assert.ok(res.success, "Thu Phục should succeed");
  assert.ok(p1.hand.some(c => c.id === "card_stolen"), "P1 should have stolen card");
  assert.ok(!p2.hand.some(c => c.id === "card_stolen"), "P2 should have lost card");
  console.log("✅ Thu Phục OK");
}

// 6. Test Phò Tá (Đào Cam Mộc - HERO_38) via handleRespondAction
{
  const state = initGame("test-pt", [
    { seat: 1, heroId: "HERO_38" },
    { seat: 2, heroId: "HERO_1" },
    { seat: 3, heroId: "HERO_2" },
    { seat: 4, heroId: "HERO_3" }
  ]);
  state.phase = "AWAIT_PHO_TA";
  state.waitingTargetSeat = 1;
  state.turnStart = { seat: 1 };
  const p1 = state.players[0];
  const p2 = state.players[1];
  p1.hand = [];
  p2.hand = [];
  const res = handleRespondAction(state, 1, true, null, null, null, 2);
  assert.ok(res.success, "Phò Tá should succeed");
  assert.equal(p2.hand.length, 2, "P2 should draw 2 cards");
  assert.equal(p1.hand.length, 1, "P1 should draw 1 card");
  console.log("✅ Phò Tá OK");
}

// 7. Test Trấn Thủ (Phạm Hạp - HERO_34) via handleRespondAction
{
  const state = initGame("test-tt", [
    { seat: 1, heroId: "HERO_1" },
    { seat: 2, heroId: "HERO_34" },
    { seat: 3, heroId: "HERO_2" },
    { seat: 4, heroId: "HERO_3" }
  ]);
  state.phase = "AWAIT_SLASH_DEFENSE";
  state.waitingTargetSeat = 2;
  state.activeCard = { casterSeat: 1, targetSeat: 2, cardId: "slash_1", cardName: "Trảm" };
  const p2 = state.players[1];
  p2.equipments = [{ id: "armor_1", name: "Áo Giáp", suit: "Spade", rank: 2, category: CARD_CATEGORIES.EQUIPMENT, subType: CARD_SUBTYPES.ARMOR }];
  const res = handleRespondAction(state, 2, true, "armor_1");
  assert.ok(res.success, "Trấn Thủ should succeed");
  assert.equal(p2.equipments.length, 0, "Equipment should be discarded");
  console.log("✅ Trấn Thủ OK");
}

console.log("🎉 All heroes 29-40 skill unit tests passed!");
