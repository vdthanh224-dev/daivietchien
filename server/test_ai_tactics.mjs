import assert from 'node:assert/strict';
import { initGame, handleAIStep, handleAIReaction, handlePlayCard, handleRespondAction,
  applyDamageToPlayer, tickGameState } from './functions/game-engine/src/gameEngine.js';
import { CARD_CATEGORIES as C, CARD_SUBTYPES as S } from './functions/game-engine/src/deck.js';

const card = (id, subType, category = C.BASIC, suit = 'Heart') => ({ id, name: id, subType, category, suit, rank: 9 });
function board(hero = 2, mode = '2v2') {
  const size = mode === 'dynasty_8' ? 8 : 4;
  const state = initGame('ai-tactics', Array.from({ length: size }, (_, i) => ({
    seat: i + 1, heroId: `HERO_${i === 0 ? hero : 2}`, isAI: i === 0,
  })), mode);
  for (const p of state.players) {
    p.hand = []; p.equipments = []; p.judgements = []; p.usedSkills = {};
    p.hp = p.maxHp; p.isAlive = true;
  }
  state.turnSeat = 1; state.turnStart = null; state.phase = 'PLAY'; state.waitingTargetSeat = 0;
  state.activeCard = null; state.slashesUsedThisTurn = 0;
  state.actionHistory = []; state._discard = [];
  state._deck = Array.from({ length: 40 }, (_, i) => card(`draw-${i}`, S.DODGE));
  return state;
}
const ok = (result) => assert.equal(result?.success, true, result?.error);

// Skills that turn multiple cards into an effect must use real engine payloads.
for (const hero of [17, 28]) {
  const state = board(hero);
  state.players[0].hand = [card('cost-a', S.WINE), card('cost-b', S.WINE), card('slash', S.ATTACK_NORMAL)];
  state.slashesUsedThisTurn = 1;
  ok(handleAIStep(state, 1));
  if (hero === 17) {
    assert(state.players.some((p) => p.judgements.some((c) => c.subType === S.BAI_COC_BACH_DANG)), 'Vạn An should actually place a trap');
    assert.equal(state.players[0].usedSkills.VanAnCount, 1);
  } else {
    assert.equal(state.phase, 'AWAIT_DUEL', 'Tây Phu should start its duel despite a spent normal slash');
    assert(state.players[0].hand.some((c) => c.id === 'slash'), 'Keep a slash to answer the duel');
  }
}

for (const [hero, expected] of [[4, 'TRIEU_DANG'], [6, 'BAT_NA'], [16, 'HUNG_SUC'], [21, 'DAN_CAU'], [22, 'THUY_CHIEN'], [24, 'THIEN_CAM'],
  [25, 'BINH_SAN'], [33, 'DINH_QUOC'], [36, 'TRAO_BAO'], [38, 'MUU_DINH'], [39, 'DOI_DO'],
  [42, 'DINH_TRIEU'], [43, 'NHIEP_CHINH'], [49, 'CHUYEN_CHE']]) {
  const state = board(hero);
  const armor = card('enemy-armor', S.ARMOR, C.EQUIPMENT);
  state.players[1].equipments = [armor];
  state.players[0].hand = [card('cost', S.WINE, C.BASIC, hero === 22 ? 'Club' : 'Spade')];
  if (hero === 16) { state.players[0].hand = [card('cost-weapon', S.WEAPON, C.EQUIPMENT)]; state.players[1].hp = 1; }
  if (hero === 21) state.players[1].equipments = [{ ...card('long-weapon', S.WEAPON, C.EQUIPMENT), range: 3 }];
  if (hero === 24) state.players[0].hand = [card('delay', S.DAI_HONG_THUY, C.DELAYED_SCROLL)];
  if (hero === 25) {
    state.players[0].equipments = [card('old-armor', S.ARMOR, C.EQUIPMENT)];
    state.players[0].hand = [card('spare-armor', S.ARMOR, C.EQUIPMENT)];
  }
  if (hero === 33) { state.players[0].hand.push(card('slash', S.ATTACK_NORMAL)); state.slashesUsedThisTurn = 1; }
  if (hero === 36) { state.players[0].hand = [card('gift', S.ARMOR, C.EQUIPMENT)]; state.players[2].hp = 1; }
  if (hero === 39) state.players[0].hand = [];
  if (hero === 42) state.players[0].hand = [card('gift', S.ARROW_RAIN, C.INSTANT_SCROLL)];
  if (hero === 43) { state.players[0].hand.push(card('gift-heal', S.PEACH)); state.players[2].hp = 1; }
  ok(handleAIStep(state, 1));
  const actions = state.actionHistory.filter((a) => a.type.includes(expected));
  assert(actions.length > 0 || state.targetCardSelection?.effectType === expected,
    `HERO_${hero} must use ${expected}, got ${state.lastAction?.type}`);
}

// Avoid a water trick that can make the low-HP caster the damage victim.
{
  const state = board();
  state.players[0].hp = 1;
  state.players[0].hand = [card('risky-water', S.THUY_TRIEU_RUT, C.INSTANT_SCROLL)];
  for (const p of [state.players[1], state.players[3]]) p.hand = Array.from({ length: 4 }, (_, i) => card(`trick-${p.seat}-${i}`, S.ACEDIA, C.DELAYED_SCROLL));
  ok(handleAIStep(state, 1));
  assert(state.players[0].hand.some((c) => c.id === 'risky-water'));
}

// Every hero must prioritize survival and protect a dying teammate from AOE.
for (let hero = 1; hero <= 50; hero++) {
  const state = board(hero);
  state.players[0].hp = 1;
  state.players[0].hand = [card('heal', S.PEACH), card('slash', S.ATTACK_NORMAL)];
  state.players[1].hp = 1;
  ok(handleAIStep(state, 1));
  assert.equal(state.players[0].hp, 2, `HERO_${hero} should heal before attacking`);
  const aoe = board(hero);
  aoe.players[2].hp = 1;
  aoe.players[0].hand = [card('aoe', S.ARROW_RAIN, C.INSTANT_SCROLL)];
  ok(handleAIStep(aoe, 1));
  assert(!aoe.aoeVictimsQueue?.length && aoe.phase !== 'AWAIT_AOE', `HERO_${hero} should spare a dying ally`);
  assert.equal(aoe.players[2].hp, 1);
}

// Multi-card costs keep the final dodge and healing card.
{
  const state = board(19);
  state.players[0].hand = [card('heal', S.PEACH), card('dodge-a', S.DODGE), card('dodge-b', S.DODGE),
    card('cost-a', S.WINE), card('cost-b', S.WINE)];
  ok(handleAIStep(state, 1));
  assert.equal(state.lastAction.type, 'CAI_CACH_TRIGGERED');
  assert(state.players[0].hand.some((c) => c.id === 'heal'));
  assert(state.players[0].hand.some((c) => c.id.startsWith('dodge-')));
}

// Clear an ally's delayed card instead of stealing their hand/equipment.
{
  const state = board();
  state.phase = 'AWAIT_TARGET_CARD'; state.waitingTargetSeat = 1;
  state.players[2].hand = [card('ally-heal', S.PEACH)];
  const delay = card('ally-delay', S.ACEDIA, C.DELAYED_SCROLL);
  state.players[2].judgements = [delay];
  state.targetCardSelection = { chooserSeat: 1, targetSeat: 3, effectType: 'TARGET_CARD', operation: 'DESTROY',
    options: [{ token: 'HAND:0', zone: 'HAND', card: null }, { token: 'JUDGEMENT:ally-delay', zone: 'JUDGEMENT', card: delay }] };
  ok(handleAIReaction(state, 1));
  assert.equal(state.players[2].judgements.length, 0);
  assert.equal(state.players[2].hand[0].id, 'ally-heal');
}

// Nullification follows the affected team, including beneficial enemy cards.
for (const [targetSeat, subType, expectedUse] of [[3, S.ACEDIA, true], [2, S.EX_NIHILO, true], [3, S.EX_NIHILO, false]]) {
  const state = board();
  state.players[0].hand = [card('nullify', S.FLAWLESS_DEFENSE, C.INSTANT_SCROLL)];
  state.phase = 'AWAIT_NULLIFY'; state.waitingTargetSeat = 1;
  state.nullifyChain = { rootCard: card('root', subType, C.INSTANT_SCROLL), casterSeat: 2,
    targetSeat, isCanceled: false, querySeats: [1], currentIdx: 0 };
  ok(handleAIReaction(state, 1));
  assert.equal(!state.players[0].hand.some((c) => c.id === 'nullify'), expectedUse);
}

// Forced attacks must not harm a teammate merely to keep a weapon.
{
  const state = board();
  const weapon = { ...card('weapon', S.WEAPON, C.EQUIPMENT), range: 3 };
  state.players[1].isAI = true;
  state.players[1].equipments = [weapon];
  state.players[1].hand = [card('forced-slash', S.ATTACK_NORMAL)];
  state.players[0].hand = [card('borrow', S.MUON_GUOM_DIET_DICH, C.INSTANT_SCROLL)];
  ok(handlePlayCard(state, 1, 'borrow', 2, { targetSeat2: 4 }));
  ok(handleAIReaction(state, 2));
  assert.equal(state.players[3].hp, state.players[3].maxHp);
  assert(state.players[1].hand.some((c) => c.id === 'forced-slash'));
  assert.equal(state.phase, 'PLAY');
}

// Chuyên Chế must finish rescue/death before returning to normal play.
{
  const state = board(49);
  state.players[1].hp = 1;
  state.phase = 'AWAIT_CHUYEN_CHE_RESPOND'; state.waitingTargetSeat = 2;
  state.activeCard = { casterSeat: 1, targetSeat: 2 };
  ok(handleRespondAction(state, 2, false, null));
  assert.equal(state.phase, 'AWAIT_NEAR_DEATH');
  for (let i = 0; i < 10 && state.phase === 'AWAIT_NEAR_DEATH'; i++) {
    ok(handleRespondAction(state, state.waitingTargetSeat, false, null));
  }
  assert.equal(state.players[1].isAlive, false);
}

// Lê Hoàn's additional hit must preserve the pending Trung Kiên prompt.
{
  const state = board(35);
  state.players[3].heroId = 'HERO_11';
  state.players[1].hp = 2;
  state.players[0].hand = [card('slash', S.ATTACK_NORMAL)];
  ok(handlePlayCard(state, 1, 'slash', 2));
  ok(handleRespondAction(state, 2, false, null));
  assert.equal(state.phase, 'AWAIT_TRUNG_KIEN');
  assert.equal(state.pendingNearDeath.targetSeat, 2);
  ok(handleAIReaction(state, 4));
  assert.equal(state.players[1].hp, 1);
}

// Chain damage pauses for Huynh Trưởng before hitting later seats.
{
  const state = board();
  state.players[2].heroId = 'HERO_8';
  state.players[2].hand = [card('gift-after-damage', S.WINE)];
  for (const p of state.players.slice(1)) { p.isChained = true; p.hp = 2; }
  state.activeCard = { casterSeat: 1, targetSeat: 2, subType: S.ATTACK_WATER };
  applyDamageToPlayer(state, 2, 1, 'test water', 'WATER');
  assert.equal(state.phase, 'AWAIT_HUYNH_TRUONG');
  assert.equal(state.waitingTargetSeat, 3);
  assert.equal(state.players[3].hp, 2, 'Do not overwrite a reaction by dealing the next chain hit');
  for (let i = 0; i < 10 && state.waitingTargetSeat; i++) ok(handleAIReaction(state, state.waitingTargetSeat));
  assert.equal(state.players[3].hp, 1);
  assert.equal(state.pendingChainSpread, null);
}

// Thổ Binh restricts dodges by rank; AI must use the legal high-rank dodge.
{
  const state = board(44);
  state.players[0].hand = [card('slash', S.ATTACK_NORMAL)];
  state.players[1].hand = [{ ...card('low-dodge', S.DODGE), rank: 4 }, card('high-dodge', S.DODGE)];
  ok(handlePlayCard(state, 1, 'slash', 2));
  ok(handleAIReaction(state, 2));
  assert(state.players[1].hand.some((c) => c.id === 'low-dodge'));
  assert(!state.players[1].hand.some((c) => c.id === 'high-dodge'));
  assert.equal(state.players[1].hp, state.players[1].maxHp);
}

// Thi Sách's death can still act; buffs living allies only and then resumes.
{
  const state = board(2, 'dynasty_8');
  state.players[1].heroId = 'HERO_3';
  state.players[1].isAI = true;
  state.players[1].hp = 1;
  state.turnSeat = 3;
  applyDamageToPlayer(state, 2, 1, 'test');
  assert.equal(state.phase, 'AWAIT_NEAR_DEATH');
  for (let i = 0; i < 12 && state.phase === 'AWAIT_NEAR_DEATH'; i++) ok(handleRespondAction(state, state.waitingTargetSeat, false, null));
  assert.equal(state.phase, 'AWAIT_UAT_KHI_TARGET');
  state.players[0].hp = 2; state.players[5].hp = 2;
  const before = state.players.map((p) => p.hand.length);
  ok(handleAIReaction(state, 2));
  for (const seat of [1, 6]) {
    assert.equal(state.players[seat - 1].hp, 3);
    assert.equal(state.players[seat - 1].hand.length, before[seat - 1] + 2);
  }
  assert.equal(state.players[2].hand.length, before[2]);
  assert.notEqual(state.phase, 'AWAIT_UAT_KHI_TARGET');
}

// An all-bot room progresses through the bounded server batch and finishes.
{
  const state = initGame('all-ai-progress', [1, 2, 3, 4].map((seat) => ({ seat, heroId: `HERO_${seat}`, isAI: true })));
  for (let i = 0; i < 100 && state.status !== 'FINISHED'; i++) assert.equal(tickGameState(state, []).changed, true);
  assert.equal(state.status, 'FINISHED');
}
console.log('PASS: 50-hero survival, friendly fire, costs, nullification, rescue and all-bot progress');
