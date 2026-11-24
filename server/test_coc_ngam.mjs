import assert from 'assert/strict';
import {
  initGame,
  handlePlayCard,
  handleUseSkill,
  handleRespondAction,
  applyDamageToPlayer
} from './functions/game-engine/src/gameEngine.js';
import { CARD_SUBTYPES, CARD_CATEGORIES } from './functions/game-engine/src/deck.js';
import { HEROES, SKILLS } from './functions/game-engine/src/heroes.js';

function createMockCard(id, name, subType = CARD_SUBTYPES.ATTACK_NORMAL, category = CARD_CATEGORIES.BASIC, suit = 'Spade', rank = 7) {
  return { id, name, subType, category, suit, rank };
}

function createFreshState() {
  const players = [
    { seat: 1, userId: 'user_1', heroId: 22, generalId: 'HERO_22', generalName: 'Ngô Quyền', maxHp: 3 },
    { seat: 2, userId: 'user_2', heroId: 1, generalId: 'HERO_1', generalName: 'An Dương Vương', maxHp: 4 },
    { seat: 3, userId: 'user_3', heroId: 2, generalId: 'HERO_2', generalName: 'Trọng Thủy', maxHp: 4 },
    { seat: 4, userId: 'user_4', heroId: 3, generalId: 'HERO_3', generalName: 'Mỵ Châu', maxHp: 4 }
  ];

  const state = initGame('test_coc_ngam', players, '2v2');
  for (const p of state.players) {
    p.hand = [];
    p.equipments = [];
    p.judgements = [];
    p.hp = p.maxHp;
  }
  state.status = 'PLAYING';
  state.phase = 'PLAY';
  state.turnSeat = 1; // Ngô Quyền's turn
  return state;
}

console.log('--- Testing Ngô Quyền: Cọc Ngầm ---');

// Test 1: Check hero skill description and definition
{
  assert.equal(HEROES.HERO_22.skills.includes('COC_NGAM'), true);
  assert.equal(SKILLS.COC_NGAM.name, 'Cọc Ngầm');
  assert.equal(SKILLS.COC_NGAM.description.includes('Bạn có thể dùng lá bài Đen bất kỳ như Trảm Thủy'), true);
  console.log('Test 1: Hero & Skill definition PASSED');
}

// Test 2: Ngô Quyền uses black card (e.g. Spade Dodge) as Trảm Thủy via handlePlayCard
{
  const state = createFreshState();
  const ngoQuyen = state.players.find(p => p.seat === 1);
  const target = state.players.find(p => p.seat === 2);

  // Black Dodge
  const blackDodge = createMockCard('c_dodge_spade', 'Đỡ', CARD_SUBTYPES.DODGE, CARD_CATEGORIES.BASIC, 'Spade', 5);
  ngoQuyen.hand.push(blackDodge);

  const res = handlePlayCard(state, 1, blackDodge.id, target.seat, { cocNgamConvert: true });
  assert.equal(res.success, true, 'Play black dodge as Trảm Thủy should succeed: ' + res.error);
  assert.equal(state.phase, 'AWAIT_SLASH_DEFENSE', 'Target should be prompted to defend slash');
  assert.equal(state.activeCard.damageElement, 'WATER', 'Element should be WATER');

  const lastAction = state.lastAction;
  assert.equal(lastAction.type, 'PLAY_SLASH');
  assert.equal(lastAction.element, 'WATER');
  assert.equal(lastAction.damage, 1);
  assert.equal(lastAction.skillActivations.some(s => s.name === 'Cọc Ngầm'), true, 'Cọc Ngầm activation should be recorded');
  console.log('Test 2: Convert Black Dodge into Trảm Thủy PASSED');
}

// Test 3: Ngô Quyền uses active skill "Cọc Ngầm" with a Black Equipment card
{
  const state = createFreshState();
  const ngoQuyen = state.players.find(p => p.seat === 1);
  const target = state.players.find(p => p.seat === 2);

  // Black Weapon (e.g. Spade weapon)
  const blackWeapon = createMockCard('c_weapon_spade', 'Súng Thần Công', CARD_SUBTYPES.WEAPON, CARD_CATEGORIES.EQUIPMENT, 'Spade', 8);
  ngoQuyen.hand.push(blackWeapon);

  const res = handleUseSkill(state, 1, 'Cọc Ngầm', target.seat, blackWeapon.id);
  assert.equal(res.success, true, 'Use skill Cọc Ngầm should succeed: ' + res.error);
  assert.equal(state.phase, 'AWAIT_SLASH_DEFENSE');
  assert.equal(state.activeCard.damageElement, 'WATER');

  const lastAction = state.lastAction;
  assert.equal(lastAction.type, 'PLAY_SLASH');
  assert.equal(lastAction.element, 'WATER');
  assert.equal(lastAction.damage, 1);
  assert.equal(lastAction.skillActivations.some(s => s.name === 'Cọc Ngầm'), true);
  console.log('Test 3: Active skill Cọc Ngầm with Black Weapon PASSED');
}

// Test 4: Trảm Thủy deals +1 damage when target is affected by Bãi Cọc Bạch Đằng
{
  const state = createFreshState();
  const ngoQuyen = state.players.find(p => p.seat === 1);
  const target = state.players.find(p => p.seat === 2);

  // Put Bãi Cọc Bạch Đằng in target judgements
  target.judgements.push({
    id: 'bai_coc_1',
    name: 'Bãi Cọc Bạch Đằng',
    subType: CARD_SUBTYPES.BAI_COC_BACH_DANG,
    category: CARD_CATEGORIES.DELAYED_SCROLL
  });

  const blackCard = createMockCard('c_black_1', 'Đột Kích', CARD_SUBTYPES.DISMANTLE, CARD_CATEGORIES.INSTANT_SCROLL, 'Spade', 3);
  ngoQuyen.hand.push(blackCard);

  const res = handleUseSkill(state, 1, 'Cọc Ngầm', target.seat, blackCard.id);
  assert.equal(res.success, true);

  const lastAction = state.lastAction;
  assert.equal(lastAction.damage, 2, 'Damage should be 2 (1 base + 1 Cọc Ngầm bonus)');
  assert.equal(lastAction.skillActivations.some(s => s.name === 'Cọc Ngầm'), true);
  console.log('Test 4: +1 damage on target with Bãi Cọc Bạch Đằng PASSED');
}

// Test 5: Responding in Duel (Huyết Chiến) with a Black Card
{
  const state = createFreshState();
  const ngoQuyen = state.players.find(p => p.seat === 1);
  const attacker = state.players.find(p => p.seat === 2);

  // Setup Duel where Ngô Quyền is respondent
  state.phase = 'AWAIT_DUEL';
  state.duelCasterSeat = 2;
  state.duelTargetSeat = 1;
  state.waitingTargetSeat = 1;
  state.waitingReactionType = 'SLASH';
  state.activeCard = { cardId: 'duel_1', name: 'Huyết Chiến' };

  // Ngô Quyền has a black card (Spade Dodge)
  const blackCard = createMockCard('c_dodge_spade_duel', 'Đỡ', CARD_SUBTYPES.DODGE, CARD_CATEGORIES.BASIC, 'Spade', 2);
  ngoQuyen.hand.push(blackCard);

  const res = handleRespondAction(state, 1, true, blackCard.id);
  assert.equal(res.success, true, 'Duel response should succeed with black card: ' + res.error);
  assert.equal(state.waitingTargetSeat, 2, 'Turn in duel should swap to attacker');

  const lastAction = state.lastAction;
  assert.equal(lastAction.type, 'DUEL_RESPOND');
  assert.equal(lastAction.cardName, 'Trảm Thủy');
  assert.equal(lastAction.skillActivations.some(s => s.name === 'Cọc Ngầm'), true);
  console.log('Test 5: Duel response with Black Card PASSED');
}

// Test 6: Responding to Barbarian Invasion (Giặc Tới) with a Black Card
{
  const state = createFreshState();
  const ngoQuyen = state.players.find(p => p.seat === 1);

  // Setup Barbarian where Ngô Quyền is respondent
  state.phase = 'AWAIT_AOE';
  state.waitingTargetSeat = 1;
  state.waitingReactionType = 'SLASH';
  state.activeCard = {
    cardId: 'barb_1',
    name: 'Giặc Tới',
    subType: CARD_SUBTYPES.GIAC_TOI,
    victims: [1]
  };

  // Ngô Quyền has a black card (Spade Dismantle)
  const blackCard = createMockCard('c_dismantle_spade', 'Đột Kích Trộm Lương', CARD_SUBTYPES.DISMANTLE, CARD_CATEGORIES.INSTANT_SCROLL, 'Spade', 4);
  ngoQuyen.hand.push(blackCard);

  const res = handleRespondAction(state, 1, true, blackCard.id);
  assert.equal(res.success, true, 'Barbarian response should succeed with black card: ' + res.error);

  const lastAction = state.lastAction;
  assert.equal(lastAction.type, 'AOE_DEFENDED');
  assert.equal(lastAction.cardName, 'Trảm Thủy');
  assert.equal(lastAction.skillActivations.some(s => s.name === 'Cọc Ngầm'), true);
  console.log('Test 6: Barbarian response with Black Card PASSED');
}

// Test 7: Red card cannot be used as Trảm Thủy via Cọc Ngầm
{
  const state = createFreshState();
  const ngoQuyen = state.players.find(p => p.seat === 1);
  const target = state.players.find(p => p.seat === 2);

  const redCard = createMockCard('c_red_dodge', 'Đỡ', CARD_SUBTYPES.DODGE, CARD_CATEGORIES.BASIC, 'Heart', 2);
  ngoQuyen.hand.push(redCard);

  const res = handleUseSkill(state, 1, 'Cọc Ngầm', target.seat, redCard.id);
  assert.ok(res.error, 'Red card should return error for Cọc Ngầm');
  console.log('Test 7: Red card rejection PASSED');
}

console.log('--- ALL CỌC NGẦM TESTS PASSED! ---');
