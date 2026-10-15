import { CARD_CATEGORIES as C, CARD_SUBTYPES as S, isSlash, isDodge, isPeach } from './deck.js';
import { heroHasSkill } from './heroes.js';

// Policy uses only the AI's cards and public board information. Legality and
// effects still go through the same engine handlers used by human players.
export function aiEquipmentValue(player, card) {
  if (!card) return 0;
  let value = 28;
  if (card.subType === S.WEAPON) {
    value += (Number(card.range) || 1) * 5;
    if (card.name?.includes('Nỏ Thần')) value += (player.hand || []).filter(isSlash).length * 14;
    if (card.name?.includes('Thuận Thiên')) value += 12;
  }
  if (card.subType === S.ARMOR) value += player.hp <= 2 ? 36 : 20;
  if (card.subType === S.DEFENSIVE_HORSE) value += player.hp <= 2 ? 18 : 8;
  if (heroHasSkill(player, 'DONG_PHUC') || heroHasSkill(player, 'PHO_VUONG')) value += 12;
  if (heroHasSkill(player, 'CUONG_KY') && [S.WEAPON, S.ARMOR].includes(card.subType)) value += 18;
  return value;
}

export function aiCardKeepValue(player, card, state = null) {
  if (!card) return 0;
  if (isPeach(card)) return player.hp <= 2 ? 110 : 70;
  if (isDodge(card) || (heroHasSkill(player, 'TIEN_THOAI') && isSlash(card))) {
    const count = (player.hand || []).filter((c) => isDodge(c) || (heroHasSkill(player, 'TIEN_THOAI') && isSlash(c))).length;
    return (player.hp <= 2 ? 85 : 60) - Math.max(0, count - 1) * 12;
  }
  if (card.subType === S.FLAWLESS_DEFENSE) return 58;
  if (card.subType === S.EX_NIHILO) return 65;
  if (card.category === C.EQUIPMENT) {
    const existing = (player.equipments || []).find((e) => e.subType === card.subType);
    return existing ? Math.max(10, aiEquipmentValue(player, card) - aiEquipmentValue(player, existing)) : aiEquipmentValue(player, card);
  }
  if (isSlash(card)) {
    const count = (player.hand || []).filter(isSlash).length;
    const spent = state?.turnSeat === player.seat && state.slashesUsedThisTurn >= 1 + (player.extraSlashLimit || 0)
      && !(player.equipments || []).some((e) => e.name?.includes('Nỏ Thần'));
    return spent ? 16 : Math.max(18, 48 - Math.max(0, count - 1) * 10);
  }
  if (card.subType === S.DAI_HONG_THUY) return 6;
  if (card.subType === S.WINE) return player.hp <= 1 ? 70 : 25;
  return 28;
}

export function buildAiTurnPlans(state, ai, rules) {
  const { friends, enemies, distance, inRange, slashAllowed, targetScore, canSlashWith, validTarget } = rules;
  const plans = [];
  const hand = ai.hand || [];
  const used = ai.usedSkills || {};
  const keep = (card) => aiCardKeepValue(ai, card, state);
  const cheap = [...hand].sort((a, b) => keep(a) - keep(b) || String(a.id).localeCompare(String(b.id)));
  // Keep one defensive card even when duplicate dodges make the others cheap.
  const reserveDodge = [...hand].reverse().find((c) => isDodge(c) || (heroHasSkill(ai, 'TIEN_THOAI') && isSlash(c)));
  const spare = cheap.filter((c) => c !== reserveDodge && keep(c) < 55);
  const allies = friends.filter((p) => p.seat !== ai.seat)
    .sort((a, b) => (a.hand.length + a.hp * 2) - (b.hand.length + b.hp * 2));
  const attackScore = (target, damage = 1) => 58 + targetScore(target) / 15
    + (target.hp <= damage ? 800 : 0)
    + (String(state.modeId).startsWith('dynasty_') && ai.role === 'REBEL' && target.role === 'KING' ? 1000 : 0)
    - Math.min(target.hand?.length || 0, 5) * 3;
  const add = (kind, score, cardId, targetSeat = 0, extra = {}) => {
    if (Number.isFinite(score) && score > 0) plans.push({ kind, score, cardId, targetSeat, extra });
  };
  const play = (card, target, score, extra = {}) => add('card', score, card.id, target?.seat || 0, extra);
  const skill = (name, target, cost, score, extra = {}) => add(name, score, cost?.id ?? cost ?? null, target?.seat || 0, extra);

  const slashes = hand.filter(canSlashWith);
  const slashTargets = (card) => enemies.filter((p) => validTarget(card, p));
  const offensiveSlash = slashAllowed && slashes.some((c) => slashTargets(c).length);
  for (const card of hand) {
    if (isPeach(card) && ai.hp < ai.maxHp) play(card, ai, ai.hp <= 1 ? 1500 : ai.hp <= 2 ? 220 : 100);
    if (card.subType === S.EX_NIHILO) play(card, ai, 90);
    if (card.subType === S.KHO_NHUC_KE && ai.hp >= 3) play(card, ai, 50 + (heroHasSkill(ai, 'HICH_NGHIA') ? 20 : 0));
    if (card.category === C.EQUIPMENT) {
      const equipped = (ai.equipments || []).filter((e) => e.subType === card.subType);
      const secondWeapon = card.subType === S.WEAPON && heroHasSkill(ai, 'LUC_DICH') && equipped.length < 2;
      const oldValue = equipped.length && !secondWeapon ? Math.min(...equipped.map((e) => aiEquipmentValue(ai, e))) : 0;
      const upgrade = aiEquipmentValue(ai, card) - oldValue;
      if (upgrade > 0 || (heroHasSkill(ai, 'KHAI_SANG') && ai.hp < ai.maxHp && [S.WEAPON, S.ARMOR].includes(card.subType))) {
        play(card, ai, 48 + upgrade + (heroHasSkill(ai, 'KHAI_SANG') && ai.hp < ai.maxHp ? 35 : 0));
      }
    }
    if (canSlashWith(card) && slashAllowed) {
      for (const target of slashTargets(card)) {
        const fire = card.subType === S.ATTACK_FIRE;
        const elemental = fire || card.subType === S.ATTACK_WATER;
        const normalBlocked = (target.equipments || []).some((e) => e.name === 'Giáp Tây Sơn') && ['Spade', 'Club'].includes(card.suit)
          && !(ai.equipments || []).some((e) => e.name?.includes('Thuận Thiên'));
        if (normalBlocked) continue;
        const damage = 1 + (ai.isWineBuffActive ? 1 : 0) + (Number(ai.dienHongBuff) || 0);
        let score = attackScore(target, damage);
        if (elemental && target.isChained) {
          score += state.players.filter((p) => p.hp > 0 && p.isChained && p.seat !== target.seat)
            .reduce((total, p) => total + (friends.includes(p) ? -(p.hp <= damage ? 1000 : 90) : 60), 0);
        }
        if (heroHasSkill(ai, 'DUNG_NU') && target.hp > ai.hp) score += 18;
        if (heroHasSkill(ai, 'CHIEN_TUONG') && card.suit === 'Spade') score += 15;
        play(card, target, score);
        if (heroHasSkill(ai, 'PHA_TONG')) {
          const cost = spare.find((c) => c.id !== card.id && Number(c.rank) < Number(card.rank));
          if (cost && (target.hp <= damage || target.hand.length >= 2)) {
            play(card, target, score + 32 - keep(cost) / 2, { phaTongCardId: cost.id });
          }
        }
      }
    }
    if (card.subType === S.WINE && offensiveSlash && !ai.isWineBuffActive && (!ai.wineUsedThisTurn || heroHasSkill(ai, 'BAO_NO'))) {
      play(card, ai, enemies.some((p) => p.hp === 2 && slashes.some((c) => validTarget(c, p))) ? 160 : 72);
    }
    if (card.subType === S.IRON_CHAIN) {
      const chainedFriend = friends.find((p) => p.isChained);
      if (chainedFriend) play(card, chainedFriend, 75, { targetSeats: friends.filter((p) => p.isChained).slice(0, 2).map((p) => p.seat) });
      else play(card, null, 38, { recast: true });
    }
    if (card.subType === S.HICH_TUONG_SI) {
      const ally = allies.find((p) => p.hand.length > 1);
      if (ally && offensiveSlash && slashes.length >= 2 && spare.some((c) => c.id !== card.id)) play(card, ally, 80);
      else play(card, null, 36, { recast: true });
    }
    if (card.subType === S.MO_YEN_TIEC) {
      const balance = state.players.filter((p) => p.hp > 0 && p.hp < p.maxHp)
        .reduce((total, p) => total + (friends.includes(p) ? (p.hp <= 1 ? 8 : 3) : -2), 0);
      if (balance > 0) play(card, null, 65 + balance * 10);
    }
    if ([S.ARROW_RAIN, S.BARBARIAN_INVASION].includes(card.subType)) {
      const benefit = enemies.reduce((v, p) => v + (p.hp <= 1 ? 150 : 35), 0)
        - allies.reduce((v, p) => v + (p.hp <= 1 ? 500 : p.hp <= 2 ? 85 : 28), 0);
      if (benefit > 0) play(card, null, benefit);
    }
    if (card.subType === S.HARVEST && (hand.length <= 2 || friends.length >= enemies.length)) play(card, null, 30);
    if (card.subType === S.TAU_VI_THUONG_SACH && ai.equipments?.length) {
      const eq = [...ai.equipments].sort((a, b) => aiEquipmentValue(ai, a) - aiEquipmentValue(ai, b))[0];
      if (aiEquipmentValue(ai, eq) < 40) play(card, ai, 42, { targetCardId: eq.id });
    }
    if ([S.SNATCH, S.DISMANTLE].includes(card.subType)) {
      for (const ally of allies) {
        if (ally.judgements?.length && validTarget(card, ally)) play(card, ally, 145);
      }
    }
    for (const enemy of enemies) {
      if ([S.SNATCH, S.DISMANTLE, S.PHU_DE_TRUU_TAN, S.THUY_TRIEU_RUT].includes(card.subType) && validTarget(card, enemy)) {
        const couldHitSelf = card.subType === S.THUY_TRIEU_RUT && hand.length < enemy.hand.length - 1;
        if (!couldHitSelf || ai.hp >= 3) play(card, enemy, 55 + targetScore(enemy, 'disrupt') / 40 - (couldHitSelf ? 30 : 0));
      }
      if ([S.SUPPLY_SHORTAGE, S.ACEDIA, S.BAI_COC_BACH_DANG].includes(card.subType)
        && !enemy.judgements?.some((j) => j.subType === card.subType) && validTarget(card, enemy)) {
        play(card, enemy, 62 + targetScore(enemy) / 35);
      }
      if (card.subType === S.DUEL && validTarget(card, enemy)) {
        const reserve = slashes.length - Math.ceil(enemy.hand.length / 3);
        if (reserve >= 0 || enemy.hp <= 1 || ai.hp >= 3) play(card, enemy, attackScore(enemy) - Math.max(0, -reserve) * 28);
      }
      if (card.subType === S.MUON_GUOM_DIET_DICH) {
        for (const owner of state.players.filter((p) => p.hp > 0 && p.seat !== ai.seat && p.seat !== enemy.seat && p.equipments?.some((e) => e.subType === S.WEAPON))) {
          if (inRange(owner, enemy)) play(card, owner, 65 + targetScore(enemy) / 40, { targetSeat2: enemy.seat });
        }
      }
    }
  }

  const foe = enemies[0];
  for (const enemy of enemies) {
    const attack = attackScore(enemy);
    if (heroHasSkill(ai, 'TRIEU_DANG') && !used['Triều Dâng'] && !used.trieu_dang && enemy.equipments?.length) {
      const eq = [...enemy.equipments].sort((a, b) => aiEquipmentValue(enemy, b) - aiEquipmentValue(enemy, a))[0];
      skill('Triều Dâng', enemy, eq, 100 + aiEquipmentValue(enemy, eq));
    }
    if (heroHasSkill(ai, 'BAT_NA') && !used.BatNa && inRange(ai, enemy)) {
      const cost = cheap.find((c) => c.category === C.BASIC && keep(c) < 60);
      if (cost) skill('Bát Nạ', enemy, cost, attack - keep(cost) / 3);
    }
    if (heroHasSkill(ai, 'HUNG_SUC') && distance(ai, enemy) <= 1) {
      const cost = [...hand, ...(ai.equipments || [])].filter((c) => c.subType === S.WEAPON).sort((a, b) => aiEquipmentValue(ai, a) - aiEquipmentValue(ai, b))[0];
      if (cost) skill('Hùng Sức', enemy, cost, attack + 15);
    }
    if (heroHasSkill(ai, 'THUY_CHIEN') && !enemy.judgements?.some((c) => c.subType === S.BAI_COC_BACH_DANG)) {
      const cost = spare.find((c) => ['Diamond', 'Club'].includes(c.suit));
      if (cost) skill('Thủy Chiến', enemy, cost, 70 + targetScore(enemy) / 40 - keep(cost) / 2);
    }
    if (heroHasSkill(ai, 'VAN_AN') && (used.VanAnCount || 0) < 2 && spare.length >= 2 && !enemy.judgements?.some((c) => c.subType === S.BAI_COC_BACH_DANG)) {
      skill('Vạn An', enemy, spare.slice(0, 2).map((c) => c.id).join('|'), 55 + targetScore(enemy) / 50);
    }
    if (heroHasSkill(ai, 'BINH_SAN') && (enemy.hand.length || enemy.equipments?.length)) {
      const cost = spare.find((c) => c.category === C.EQUIPMENT);
      if (cost) skill('Bình Sạn', enemy, cost, 58 + targetScore(enemy, 'disrupt') / 40);
    }
    if (heroHasSkill(ai, 'TAY_PHU') && spare.length >= 2 && slashes.length > 0) {
      const costs = spare.filter((c) => !canSlashWith(c)).slice(0, 2);
      if (costs.length === 2) skill('Tây Phu', enemy, costs.map((c) => c.id).join('|'), attack - 12);
    }
    if (heroHasSkill(ai, 'DINH_QUOC') && (slashes.length > 0 || enemy.hand.length <= 1 || enemy.hp <= 1)) {
      const cost = spare.find((c) => c.suit === 'Spade');
      if (cost) skill('Định Quốc', enemy, cost, attack - keep(cost) / 2);
    }
    if (heroHasSkill(ai, 'CHUYEN_CHE') && enemy.equipments?.length && spare.length) {
      skill('Chuyên Chế', enemy, spare[0], attack + 35 - keep(spare[0]));
    }
    if (heroHasSkill(ai, 'DAN_CAU') && !used.DanCau && spare.length) {
      const forced = enemies.find((p) => p.seat !== enemy.seat && inRange(p, enemy));
      if (forced) skill('Dẫn Cầu', forced, `${spare[0].id}|${enemy.seat}`, 66 + targetScore(enemy) / 40);
    }
  }
  if (heroHasSkill(ai, 'CO_BIEN') && (used.coBienCount || 0) < 2) {
    const cost = spare.find((c) => c.suit === 'Spade' && (!offensiveSlash || !canSlashWith(c)));
    if (cost) skill('Cơ Biến', null, cost, 32);
  }
  if (heroHasSkill(ai, 'THIEN_CAM')) {
    const cost = hand.find((c) => c.category === C.DELAYED_SCROLL);
    if (cost) skill('Thiên Cảm', null, cost, 95);
  }
  if (heroHasSkill(ai, 'CAI_CACH') && !used.CaiCach && spare.length >= 2) skill('Cải Cách', null, spare.slice(0, 2).map((c) => c.id).join('|'), 42);
  if (heroHasSkill(ai, 'TRAC_LAC') && ai.hp <= 2 && !ai.isWineBuffActive && !ai.wineUsedThisTurn && offensiveSlash) {
    const cost = spare.find((c) => c.suit === 'Spade' && !canSlashWith(c));
    if (cost) skill('Trác Lạc', null, cost, 72);
  }
  if (heroHasSkill(ai, 'MUU_DINH') && !used.muuDinhUsed) skill('Mưu Định', null, null, 92);
  if (heroHasSkill(ai, 'DOI_DO') && !used.doiDoUsed && (hand.length <= 2 || (spare.length >= 3 && spare.length === hand.length))) {
    const seats = friends.slice(0, 4).map((p) => p.seat);
    skill('Dời Đô', null, seats.join(','), 78, { targetSeats: seats });
  }
  for (const ally of allies) {
    if (heroHasSkill(ai, 'TRAO_BAO') && ally.hp < ally.maxHp) {
      const cost = hand.find((c) => c.category === C.EQUIPMENT) || (ai.equipments || []).find((c) => aiEquipmentValue(ai, c) < 50);
      if (cost) skill('Trao Bào', ally, cost, ally.hp <= 1 ? 300 : 115);
    }
    if (heroHasSkill(ai, 'DINH_TRIEU') && !used.DinhTrieu) {
      const cost = cheap.find((c) => c.category === C.INSTANT_SCROLL || c.category === C.DELAYED_SCROLL);
      if (cost) skill('Định Triều', ally, cost, 55 + (ally.hand.length <= 1 ? 35 : 0) - keep(cost) / 4);
    }
    if (heroHasSkill(ai, 'NHIEP_CHINH_Y_LAN') && !used.NhiepChinhGift && hand.length > 1) {
      const cost = hand.find((c) => isPeach(c) && ally.hp < ally.maxHp && ai.hp >= ai.maxHp) || spare[0];
      if (cost) skill('Nhiếp Chính', ally, cost, isPeach(cost) && ally.hp <= 1 ? 200 : 34);
    }
  }
  if (foe && ai.equipments?.some((c) => c.subType === S.BRONZE_DRUM) && !used.DiemTrong && foe.hand.length) skill('Điểm Trống', foe, null, 25);
  return plans.sort((a, b) => b.score - a.score);
}
