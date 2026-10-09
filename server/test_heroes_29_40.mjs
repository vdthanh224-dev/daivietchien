import assert from "node:assert/strict";
import { CARD_CATEGORIES, CARD_SUBTYPES } from "./functions/game-engine/src/deck.js";
import { handleRespondAction, handleUseSkill, handlePlayCard, initGame, applyDamageToPlayer } from "./functions/game-engine/src/gameEngine.js";

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

  // Test Trao Bào with equipped item (equipped on caster)
  p2.hp = 2;
  p1.equipments = [{ id: "eq_shield", name: "Bạch Ngân Giáp", suit: "Spade", rank: 2, category: CARD_CATEGORIES.EQUIPMENT, subType: CARD_SUBTYPES.ARMOR }];
  const resEquippedOffer = handleUseSkill(state, 1, "Trao Bào", 2, "eq_shield");
  assert.ok(resEquippedOffer.success, "Trao Bào should offer equipped item successfully");
  assert.equal(p1.equipments.length, 0, "Caster equipments should no longer contain offered item");
  handleRespondAction(state, 2, true, null);
  assert.ok(p2.equipments.some(e => e.id === "eq_shield"), "Target should receive and equip the equipped armor");
  assert.equal(p2.hp, 3, "Target should heal from receiving equipped armor");

  // Test Trao Bào with LOCAL_EQUIP_ fallback
  p2.hp = 2;
  p1.equipments = [{ id: "weapon_bow", name: "Cung", suit: "Heart", rank: 9, category: CARD_CATEGORIES.EQUIPMENT, subType: CARD_SUBTYPES.WEAPON }];
  const resFallbackOffer = handleUseSkill(state, 1, "Trao Bào", 2, "LOCAL_EQUIP_equipped_weapon");
  assert.ok(resFallbackOffer.success, "Trao Bào should offer equipped item by LOCAL_EQUIP_ fallback");
  assert.equal(p1.equipments.length, 0, "Caster equipments should be removed via fallback");
  handleRespondAction(state, 2, true, null);
  assert.ok(p2.equipments.some(e => e.id === "weapon_bow"), "Target should receive the fallback equipped weapon");

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

// 6.1. Test Mưu Định (Đào Cam Mộc - HERO_38) interactive flow
{
  const state = initGame("test-md", [
    { seat: 1, heroId: "HERO_38" },
    { seat: 2, heroId: "HERO_1" },
    { seat: 3, heroId: "HERO_2" },
    { seat: 4, heroId: "HERO_3" }
  ]);
  state.phase = "PLAY";
  state.turnSeat = 1;
  const card1 = { id: "test_c1", name: "Đào", suit: "Heart", rank: 12, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.PEACH };
  const card2 = { id: "test_c2", name: "Trảm", suit: "Spade", rank: 7, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.ATTACK_NORMAL };
  state._deck = [card2, card1];

  const resPrompt = handleUseSkill(state, 1, "Mưu Định", 0);
  assert.ok(resPrompt.success, "Mưu Định trigger should succeed");
  assert.equal(state.phase, "AWAIT_MUU_DINH_CHOICE", "Phase should be AWAIT_MUU_DINH_CHOICE");
  assert.equal(state.waitingTargetSeat, 1, "Waiting target seat should be 1");
  assert.equal(state.pendingMuuDinh.cards.length, 2, "Should peek 2 cards");

  const p2HandBefore = state.players[1].hand.length;
  const resRespond = handleRespondAction(state, 1, true, "test_c1", null, null, 2);
  assert.ok(resRespond.success, "Mưu Định respond should succeed");
  assert.equal(state.phase, "PLAY", "Phase should return to PLAY");
  assert.equal(state.players[1].hand.length, p2HandBefore + 1, "Seat 2 should receive chosen card");
  assert.ok(state.players[1].hand.some(c => c.id === "test_c1"), "Seat 2 should receive Đào");
  assert.equal(state._deck[state._deck.length - 1].id, "test_c2", "Remaining card should be put back on top of deck");
  console.log("✅ Mưu Định OK");
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

// 8. Test Thân Chinh (Lý Phật Mã - HERO_40): Trảm gây sát thương -> được Trảm lần 2
{
  const state = initGame("test-tc-lpm", [
    { seat: 1, heroId: "HERO_40" },
    { seat: 2, heroId: "HERO_1" },
    { seat: 3, heroId: "HERO_2" },
    { seat: 4, heroId: "HERO_3" }
  ]);
  state.phase = "PLAY";
  state.turnSeat = 1;
  const p1 = state.players[0];
  const p2 = state.players[1];
  p1.hand = [
    { id: "slash_1", name: "Trảm", suit: "Spade", rank: 5, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.ATTACK_NORMAL },
    { id: "slash_2", name: "Trảm", suit: "Heart", rank: 6, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.ATTACK_NORMAL }
  ];
  p2.hp = 3;
  p2.hand = []; // no dodge

  // First Slash
  const play1 = handlePlayCard(state, 1, "slash_1", 2);
  assert.ok(play1.success, "First slash should succeed");
  assert.equal(state.phase, "AWAIT_SLASH_DEFENSE", "Waiting for dodge");
  
  // Target cannot dodge -> pass
  const pass1 = handleRespondAction(state, 2, false);
  assert.ok(pass1.success, "Dodge pass should succeed");
  assert.equal(p2.hp, 2, "Target took 1 damage");
  assert.equal(p1.extraSlashLimit, 1, "Lý Phật Mã should gain 1 extra slash limit from Thân Chinh");
  assert.equal(state.slashesUsedThisTurn, 1, "1 slash used this turn");

  // Second Slash (allowed because extraSlashLimit == 1)
  const play2 = handlePlayCard(state, 1, "slash_2", 2);
  assert.ok(play2.success, "Second slash must be allowed via Thân Chinh!");
  assert.equal(state.phase, "AWAIT_SLASH_DEFENSE", "Second slash waiting for dodge");
  console.log("✅ Thân Chinh (Lý Phật Mã - Trảm lần 2) OK");
}

// 9. Test Trác Lạc (Lê Long Đĩnh - HERO_37)
{
  const state = initGame("test-tl-lld", [
    { seat: 1, heroId: "HERO_37" },
    { seat: 2, heroId: "HERO_1" },
    { seat: 3, heroId: "HERO_2" },
    { seat: 4, heroId: "HERO_3" }
  ]);
  state.phase = "PLAY";
  state.turnSeat = 1;
  const p1 = state.players[0];
  p1.hp = 2; // <= 2 Máu qualifies for Trác Lạc
  p1.hand = [
    { id: "black_c1", name: "Trảm Thường", suit: "Spade", rank: 8, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.ATTACK_NORMAL },
    { id: "black_c2", name: "Huyết Chiến", suit: "Club", rank: 1, category: CARD_CATEGORIES.INSTANT_SCROLL, subType: CARD_SUBTYPES.BLOOD_BATTLE }
  ];

  // Test 9a: Dùng lá Đen làm Rượu khi HP <= 2
  const resWine = handleUseSkill(state, 1, "Trác Lạc", 0, "black_c1");
  assert.ok(resWine.success, "Trác Lạc wine use should succeed");
  assert.equal(p1.isWineBuffActive, true, "Wine buff should be active");
  assert.equal(p1.wineBonusDamage, 1, "Bạo Nộ bonus damage should be 1");

  // Test 9b: Cận tử dùng lá Đen làm Rượu tự cứu
  p1.hp = 0;
  state.phase = "AWAIT_NEAR_DEATH";
  state.nearDeathVictimSeat = 1;
  state.waitingTargetSeat = 1;
  const resRescue = handleRespondAction(state, 1, true, "black_c2");
  assert.ok(resRescue.success, "Trác Lạc self rescue with black card should succeed");
  assert.equal(p1.hp, 1, "Should be saved to 1 HP");
  console.log("✅ Trác Lạc (Lê Long Đĩnh) OK");
}

console.log("🎉 All heroes 29-40 skill unit tests passed!");
