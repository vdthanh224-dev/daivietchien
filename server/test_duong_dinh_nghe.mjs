import assert from 'assert/strict';
import {
  initGame,
  applyDamageToPlayer,
  handleRespondAction,
  handleEndTurn,
  triggerDuongBinh
} from './functions/game-engine/src/gameEngine.js';
import { CARD_SUBTYPES, CARD_CATEGORIES } from './functions/game-engine/src/deck.js';

function createMockCard(id, name, subType = CARD_SUBTYPES.SLASH, category = CARD_CATEGORIES.BASIC, suit = 'Heart', rank = 7) {
  return { id, name, subType, category, suit, rank };
}

function createFreshState() {
  const players = [
    { seat: 1, userId: 'user_1', heroId: 20, generalId: 'HERO_20', generalName: 'Dương Đình Nghệ', maxHp: 4 },
    { seat: 2, userId: 'user_2', heroId: 1, generalId: 'HERO_1', generalName: 'An Dương Vương', maxHp: 4 },
    { seat: 3, userId: 'user_3', heroId: 2, generalId: 'HERO_2', generalName: 'Trọng Thủy', maxHp: 4 },
    { seat: 4, userId: 'user_4', heroId: 3, generalId: 'HERO_3', generalName: 'Mỵ Châu', maxHp: 4 }
  ];

  const state = initGame('test_duong_dinh_nghe', players, '2v2');
  for (const p of state.players) {
    p.hand = [];
    p.equipments = [];
    p.judgements = [];
    p.hp = 4;
  }
  state.status = 'PLAYING';
  state.phase = 'PLAY';
  state.turnSeat = 2; // Player 2's turn
  return state;
}

console.log('--- Testing Dương Đình Nghệ: Nghĩa Tử & Dưỡng Binh ---');

// Test 1: Nghĩa Tử - Chịu thay 1 sát thương và rút 2 lá
{
  const state = createFreshState();
  const ddn = state.players[0]; // seat 1
  const target = state.players[1]; // seat 2

  // Give Dương Đình Nghệ 1 card to discard
  ddn.hand = [createMockCard('c1', 'Trảm')];
  assert.equal(ddn.hand.length, 1);
  assert.equal(ddn.hp, 4);
  assert.equal(target.hp, 4);

  // Player 2 takes 1 damage
  applyDamageToPlayer(state, 2, 1, 'Trảm', 'NORMAL', true, { attackerSeat: 3 });
  assert.equal(state.phase, 'AWAIT_NGHIA_TU');
  assert.equal(state.waitingTargetSeat, 1);

  // Dương Đình Nghệ accepts Nghĩa Tử, discarding 'c1'
  const res = handleRespondAction(state, 1, true, 'c1');
  assert.equal(res.success, true);

  // Target took 0 damage
  assert.equal(target.hp, 4, 'Target should not have lost HP');
  // Dương Đình Nghệ took 1 damage
  assert.equal(ddn.hp, 3, 'Dương Đình Nghệ should have lost 1 HP');
  // Dương Đình Nghệ discarded 1 card and drew 2 cards -> hand has 2 cards
  assert.equal(ddn.hand.length, 2, 'Dương Đình Nghệ should have drawn 2 cards from Nghĩa Tử');

  // Verify action history recorded NGHIA_TU_TRIGGERED
  const lastAction = state.actionHistory[state.actionHistory.length - 1];
  assert.equal(lastAction.type, 'NGHIA_TU_TRIGGERED');
  assert.equal(lastAction.casterSeat, 1);
  assert.equal(lastAction.skillActivations[0].name, 'Nghĩa Tử');
  assert(lastAction.description.includes('rút 2 lá bài'), 'Description should mention drawing 2 cards');

  console.log('✅ Case 1: Nghĩa Tử (discard 1 card, take 1 damage, draw 2 cards) passed');
}

// Test 2: Nghĩa Tử - Từ chối
{
  const state = createFreshState();
  const ddn = state.players[0];
  const target = state.players[1];

  ddn.hand = [createMockCard('c1', 'Trảm')];
  applyDamageToPlayer(state, 2, 1, 'Trảm', 'NORMAL', true, { attackerSeat: 3 });
  assert.equal(state.phase, 'AWAIT_NGHIA_TU');

  // Dương Đình Nghệ declines Nghĩa Tử
  const res = handleRespondAction(state, 1, false);
  assert.equal(res.success, true);

  // Target took the 1 damage
  assert.equal(target.hp, 3, 'Target should have taken 1 damage');
  // Dương Đình Nghệ took no damage and drew no cards
  assert.equal(ddn.hp, 4, 'Dương Đình Nghệ should remain at 4 HP');
  assert.equal(ddn.hand.length, 1, 'Dương Đình Nghệ hand count should remain 1');

  console.log('✅ Case 2: Nghĩa Tử declined (original victim takes damage, helper unaffected) passed');
}

// Test 3: Dưỡng Binh - Cuối lượt nhân vật khác, KHÔNG AI nhận sát thương -> rút 2 lá
{
  const state = createFreshState();
  state.turnSeat = 2; // Player 2's turn
  const ddn = state.players[0]; // seat 1
  ddn.hand = [];

  // Player 2 ends turn without anyone taking damage
  const res = handleEndTurn(state, 2);
  assert.equal(res.success, true);

  // Dương Đình Nghệ should have drawn 2 cards
  assert.equal(ddn.hand.length, 2, 'Dương Đình Nghệ should draw 2 cards from Dưỡng Binh');

  // Verify action history
  const duongBinhAction = state.actionHistory.find((a) => a.type === 'DUONG_BINH_DRAW');
  assert(duongBinhAction, 'DUONG_BINH_DRAW action must be recorded');
  assert.equal(duongBinhAction.casterSeat, 1);
  assert.equal(duongBinhAction.skillActivations[0].name, 'Dưỡng Binh');

  console.log('✅ Case 3: Dưỡng Binh triggers when other player ends turn with no damage passed');
}

// Test 4: Dưỡng Binh - Cuối lượt nhân vật khác, CÓ NGƯỜI nhận sát thương -> KHÔNG rút lá
{
  const state = createFreshState();
  state.turnSeat = 2; // Player 2's turn
  const ddn = state.players[0]; // seat 1
  ddn.hand = [];

  // Player 3 takes 1 damage during Player 2's turn
  applyDamageToPlayer(state, 3, 1, 'Trảm', 'NORMAL', true, { attackerSeat: 2, skipNghiaTu: true });
  assert.equal(state.anyDamageReceivedThisTurn, true);

  // Player 2 ends turn
  const res = handleEndTurn(state, 2);
  assert.equal(res.success, true);

  // Dương Đình Nghệ should NOT draw cards
  assert.equal(ddn.hand.length, 0, 'Dương Đình Nghệ should NOT draw cards because damage was dealt');
  const duongBinhAction = state.actionHistory.find((a) => a.type === 'DUONG_BINH_DRAW');
  assert(!duongBinhAction, 'DUONG_BINH_DRAW should not be recorded');

  console.log('✅ Case 4: Dưỡng Binh does NOT trigger when damage was dealt passed');
}

// Test 5: Dưỡng Binh - Cuối lượt của CHÍNH DƯƠNG ĐÌNH NGHỆ -> KHÔNG rút lá
{
  const state = createFreshState();
  state.turnSeat = 1; // Dương Đình Nghệ's own turn
  const ddn = state.players[0]; // seat 1
  ddn.hand = [];

  // Dương Đình Nghệ ends turn without anyone taking damage
  const res = handleEndTurn(state, 1);
  assert.equal(res.success, true);

  // Dương Đình Nghệ should NOT draw cards from Dưỡng Binh on his own turn
  assert.equal(ddn.hand.length, 0, 'Dương Đình Nghệ should NOT draw from Dưỡng Binh on his own turn');
  const duongBinhAction = state.actionHistory.find((a) => a.type === 'DUONG_BINH_DRAW');
  assert(!duongBinhAction, 'DUONG_BINH_DRAW should not trigger on own turn');

  console.log('✅ Case 5: Dưỡng Binh does NOT trigger on own turn passed');
}

// Test 6: Dưỡng Binh - Dương Đình Nghệ đã chết (hp <= 0) -> KHÔNG rút lá
{
  const state = createFreshState();
  state.turnSeat = 2; // Player 2's turn
  const ddn = state.players[0]; // seat 1
  ddn.hp = 0;
  ddn.isAlive = false;
  ddn.hand = [];

  state.anyDamageReceivedThisTurn = false;
  for (const p of state.players) p.damageReceivedThisTurn = false;

  const triggered = triggerDuongBinh(state, 2);
  assert.equal(triggered, false, 'Dead player cannot trigger Dưỡng Binh');
  assert.equal(ddn.hand.length, 0);

  console.log('✅ Case 6: Dead player does NOT trigger Dưỡng Binh passed');
}

// Test 7: Dưỡng Binh - Reset sạch sẽ giữa các lượt liên tiếp
{
  const state = createFreshState();
  const ddn = state.players[0];
  ddn.hand = [];

  // Turn of Player 2: takes damage -> Dưỡng Binh does not trigger
  state.turnSeat = 2;
  applyDamageToPlayer(state, 4, 1, 'Trảm', 'NORMAL', true, { attackerSeat: 2, skipNghiaTu: true });
  handleEndTurn(state, 2);
  assert.equal(ddn.hand.length, 0);

  // Turn advances to Player 3: no damage happens!
  // At the end of Player 3's turn, Dưỡng Binh SHOULD trigger!
  state.turnSeat = 3;
  state.phase = 'PLAY';
  handleEndTurn(state, 3);
  assert.equal(ddn.hand.length, 2, 'Dương Đình Nghệ should draw 2 cards at the end of Player 3 turn');

  console.log('✅ Case 7: Flag resets cleanly between consecutive turns passed');
}

console.log('🎉 All Dương Đình Nghệ (Nghĩa Tử & Dưỡng Binh) unit tests passed successfully!');
