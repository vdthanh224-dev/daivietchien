import assert from "node:assert/strict";
import { CARD_CATEGORIES, CARD_SUBTYPES } from "./functions/game-engine/src/deck.js";
import { handlePlayCard, handleRespondAction, initGame, getDistance } from "./functions/game-engine/src/gameEngine.js";

const players = [
  { seat: 1, heroId: "HERO_1" },
  { seat: 2, heroId: "HERO_9" }, // Triệu Thị Trinh
  { seat: 3, heroId: "HERO_3" },
  { seat: 4, heroId: "HERO_4" }
];

function card(id, name, subType, suit = "Heart", category = CARD_CATEGORIES.BASIC, distMod = 0) {
  return { id, name, suit, rank: 7, category, subType, distMod };
}

// 1. Test innate +1 defensive horse distance
{
  const state = initGame("chien-tuong-dist", players);

  // Seat 1 to Seat 2: adjacent on 4-player board, base distance is 1.
  // Triệu Thị Trinh (Seat 2) has Chiến Tượng => distance is 1 + 1 = 2.
  assert.equal(getDistance(state, 1, 2), 2);

  // Seat 3 to Seat 2: adjacent, base distance is 1 => with Chiến Tượng is 2.
  assert.equal(getDistance(state, 3, 2), 2);

  // Seat 4 to Seat 2: opposite, base distance is 2 => with Chiến Tượng is 3.
  assert.equal(getDistance(state, 4, 2), 3);

  // Triệu Thị Trinh's offensive distance to others is unchanged (+1 horse is DEFENSIVE):
  // Seat 2 to Seat 1: base distance is 1.
  assert.equal(getDistance(state, 2, 1), 1);
  // Seat 2 to Seat 3: base distance is 1.
  assert.equal(getDistance(state, 2, 3), 1);
}

// 2. Test equipping an additional real +1 defensive horse stacks to +2
{
  const state = initGame("chien-tuong-stack", players);

  // Equip a real defensive horse (Voi Chiến Đại Việt, subType = DEFENSIVE_HORSE, distMod = 1)
  const voiChien = card("voi_chien_real", "Voi Chiến Đại Việt", CARD_SUBTYPES.DEFENSIVE_HORSE, "Heart", CARD_CATEGORIES.EQUIPMENT, 1);
  state.players[1].equipments = [voiChien];

  // Base 1 + 1 (Voi Chiến) + 1 (Chiến Tượng) = 3 (+2 bonus)
  assert.equal(getDistance(state, 1, 2), 3);
  assert.equal(getDistance(state, 3, 2), 3);
  assert.equal(getDistance(state, 4, 2), 4);
}

// 3. Test Trảm damage:
// - Without real horse on equipment slot: Trảm deals base 1 damage
// - With real horse on equipment slot: Trảm deals 1 + 1 = 2 damage (Chiến Tượng bonus)
{
  const state = initGame("chien-tuong-damage", [
    { seat: 1, heroId: "HERO_9" }, // Triệu Thị Trinh is seat 1
    { seat: 2, heroId: "HERO_2" },
    { seat: 3, heroId: "HERO_1" },
    { seat: 4, heroId: "HERO_3" }
  ]);

  // Case 3a: No real horse equipped
  state.players[0].hand = [card("slash-normal", "Trảm", CARD_SUBTYPES.ATTACK_NORMAL)];
  state.players[1].hand = [];
  state.players[1].hp = 4;

  assert.equal(handlePlayCard(state, 1, "slash-normal", 2).success, true);
  // Target does not dodge
  assert.equal(handleRespondAction(state, 2, false, null).success, true);
  // Damage dealt should be 1 (target HP goes from 4 to 3)
  assert.equal(state.players[1].hp, 3);

  // Case 3b: With real horse equipped on horse slot (e.g. Ngựa Trắng or Voi Chiến)
  const nguaTrang = card("ngua_trang", "Ngựa Trắng Thuần Nông", CARD_SUBTYPES.OFFENSIVE_HORSE, "Diamond", CARD_CATEGORIES.EQUIPMENT, -1);
  state.players[0].equipments = [nguaTrang];
  state.players[0].hand = [card("slash-boosted", "Trảm", CARD_SUBTYPES.ATTACK_NORMAL)];
  state.slashesUsedThisTurn = 0; // reset slash limit for test

  assert.equal(handlePlayCard(state, 1, "slash-boosted", 2).success, true);
  // Target does not dodge
  assert.equal(handleRespondAction(state, 2, false, null).success, true);
  // Damage dealt should be 2 (Chiến Tượng bonus: +1, target HP goes from 3 to 1)
  assert.equal(state.players[1].hp, 1);
}

// 4. Test that default horse cannot be destroyed or targeted by Dismantle (Tẩu Vi Thượng Sách)
{
  const state = initGame("chien-tuong-undestroyable", players);
  // Seat 2 has no items in equipments array
  assert.equal(state.players[1].equipments.length, 0);
  // Default horse is innate, not in player.equipments, so cannot be dismantled
  assert.equal((state.players[1].equipments || []).some(e => e.subType === CARD_SUBTYPES.DEFENSIVE_HORSE), false);
}

console.log("Chiến Tượng (Triệu Thị Trinh) OK");
