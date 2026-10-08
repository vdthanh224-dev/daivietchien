import { CARD_SUBTYPES } from './deck.js';

// Card rules are pure hooks. The engine owns zones, prompts, timers, and state mutation.
const EQUIPMENT_RULES = Object.freeze([
  {
    id: 'hoa_mai_tay_son',
    name: 'Hỏa Mai Tây Sơn',
    match: (card) => card?.subType === CARD_SUBTYPES.WEAPON && card?.name === 'Hỏa Mai Tây Sơn',
    hooks: {
      slashElement: ({ slash }) => slash?.subType === CARD_SUBTYPES.ATTACK_NORMAL ? 'FIRE' : null
    }
  },
  {
    id: 'liem_dao_dong_da',
    name: 'Liêm Đao Đống Đa',
    match: (card) => card?.subType === CARD_SUBTYPES.WEAPON && card?.name === 'Liêm Đao Đống Đa',
    hooks: { slashHitDrawOnce: () => 1 }
  },
  {
    id: 'doan_dao_lam_son',
    name: 'Đoản Đao Lam Sơn',
    match: (card) => card?.subType === CARD_SUBTYPES.WEAPON && card?.name === 'Đoản Đao Lam Sơn',
    hooks: { slashHitReplacement: () => 'DESTROY_TWO_TARGET_CARDS' }
  },
  {
    id: 'truong_dao_nam_son',
    name: 'Trường Đao Nam Sơn',
    match: (card) => card?.subType === CARD_SUBTYPES.WEAPON && card?.name === 'Trường Đao Nam Sơn',
    hooks: { slashDodged: () => ({ refundSlashUse: true }) }
  },
  {
    id: 'thuyen_bach_dang',
    name: 'Thuyền Bạch Đằng',
    match: (card) => card?.subType === CARD_SUBTYPES.OFFENSIVE_HORSE && card?.name === 'Thuyền Bạch Đằng',
    hooks: { ignoreSlashDistance: ({ slash }) => slash?.subType === CARD_SUBTYPES.ATTACK_WATER }
  },
  {
    id: 'giap_tay_son',
    name: 'Giáp Tây Sơn',
    match: (card) => card?.subType === CARD_SUBTYPES.ARMOR && card?.name === 'Giáp Tây Sơn',
    hooks: { blockSlash: ({ slash }) => ['Spade', 'Club'].includes(slash?.suit) }
  }
]);

// Every subtype has one canonical rule. A mode chooses a deck and may disable
// rules, but never needs to duplicate target validation or card classification.
const SUBTYPE_RULES = new Map([
  [CARD_SUBTYPES.ATTACK_NORMAL, { id: 'slash_normal', family: 'BASIC', resolver: 'SLASH', requiresTarget: true }],
  [CARD_SUBTYPES.ATTACK_FIRE, { id: 'slash_fire', family: 'BASIC', resolver: 'SLASH', requiresTarget: true }],
  [CARD_SUBTYPES.ATTACK_WATER, { id: 'slash_water', family: 'BASIC', resolver: 'SLASH', requiresTarget: true }],
  [CARD_SUBTYPES.DODGE, { id: 'dodge', family: 'BASIC', resolver: 'REACTION' }],
  [CARD_SUBTYPES.PEACH, { id: 'peach', family: 'BASIC', resolver: 'HEAL_SELF' }],
  [CARD_SUBTYPES.WINE, { id: 'wine', family: 'BASIC', resolver: 'WINE_SELF' }],
  [CARD_SUBTYPES.WEAPON, { id: 'weapon', family: 'EQUIPMENT', resolver: 'EQUIP' }],
  [CARD_SUBTYPES.ARMOR, { id: 'armor', family: 'EQUIPMENT', resolver: 'EQUIP' }],
  [CARD_SUBTYPES.OFFENSIVE_HORSE, { id: 'offensive_horse', family: 'EQUIPMENT', resolver: 'EQUIP' }],
  [CARD_SUBTYPES.DEFENSIVE_HORSE, { id: 'defensive_horse', family: 'EQUIPMENT', resolver: 'EQUIP' }],
  [CARD_SUBTYPES.FLAWLESS_DEFENSE, { id: 'flawless_defense', family: 'INSTANT', resolver: 'NULLIFY', requiresTarget: true }],
  [CARD_SUBTYPES.DISMANTLE, { id: 'dismantle', family: 'INSTANT', resolver: 'DESTROY_TARGET_CARD', requiresTarget: true }],
  [CARD_SUBTYPES.SNATCH, { id: 'snatch', family: 'INSTANT', resolver: 'STEAL_TARGET_CARD', requiresTarget: true }],
  [CARD_SUBTYPES.EX_NIHILO, { id: 'ex_nihilo', family: 'INSTANT', resolver: 'DRAW_SELF' }],
  [CARD_SUBTYPES.DUEL, { id: 'duel', family: 'INSTANT', resolver: 'DUEL', requiresTarget: true }],
  [CARD_SUBTYPES.IRON_CHAIN, { id: 'iron_chain', family: 'INSTANT', resolver: 'IRON_CHAIN' }],
  [CARD_SUBTYPES.HARVEST, { id: 'harvest', family: 'INSTANT', resolver: 'HARVEST' }],
  [CARD_SUBTYPES.BARBARIAN_INVASION, { id: 'barbarian_invasion', family: 'INSTANT', resolver: 'AOE' }],
  [CARD_SUBTYPES.ARROW_RAIN, { id: 'arrow_rain', family: 'INSTANT', resolver: 'AOE' }],
  [CARD_SUBTYPES.DAI_HONG_THUY, { id: 'dai_hong_thuy', family: 'DELAYED', resolver: 'ATTACH_SELF' }],
  [CARD_SUBTYPES.SUPPLY_SHORTAGE, { id: 'supply_shortage', family: 'DELAYED', resolver: 'ATTACH_TARGET', requiresTarget: true }],
  [CARD_SUBTYPES.ACEDIA, { id: 'acedia', family: 'DELAYED', resolver: 'ATTACH_TARGET', requiresTarget: true }],
  [CARD_SUBTYPES.BAI_COC_BACH_DANG, { id: 'bai_coc_bach_dang', family: 'DELAYED', resolver: 'ATTACH_TARGET', requiresTarget: true }],
  [CARD_SUBTYPES.THUY_TRIEU_RUT, { id: 'thuy_trieu_rut', family: 'INSTANT', resolver: 'TIDE_TRANSFER', requiresTarget: true }],
  [CARD_SUBTYPES.MUON_GUOM_DIET_DICH, { id: 'muon_guom_diet_dich', family: 'INSTANT', resolver: 'BORROW_SWORD', requiresTarget: true }],
  [CARD_SUBTYPES.MO_YEN_TIEC, { id: 'mo_yen_tiec', family: 'INSTANT', resolver: 'HEAL_ALL' }],
  [CARD_SUBTYPES.HICH_TUONG_SI, { id: 'hich_tuong_si', family: 'INSTANT', resolver: 'HICH_SELECTION' }],
  [CARD_SUBTYPES.BRONZE_DRUM, { id: 'treasure', family: 'EQUIPMENT', resolver: 'EQUIP' }],
  [CARD_SUBTYPES.KHO_NHUC_KE, { id: 'kho_nhuc_ke', family: 'INSTANT', resolver: 'SELF_DAMAGE_DRAW' }],
  [CARD_SUBTYPES.TAU_VI_THUONG_SACH, { id: 'tau_vi_thuong_sach', family: 'INSTANT', resolver: 'DISCARD_OWN_EQUIPMENT_DRAW' }],
  [CARD_SUBTYPES.PHU_DE_TRUU_TAN, { id: 'phu_de_truu_tan', family: 'INSTANT', resolver: 'RETURN_TARGET_EQUIPMENT', requiresTarget: true }]
]);

export function getCardRule(card) {
  return SUBTYPE_RULES.get(card?.subType) || { id: 'unknown', family: 'UNKNOWN', resolver: 'NONE' };
}

export function cardRequiresTarget(card) {
  return getCardRule(card).requiresTarget === true;
}

export function getEquipmentRule(card) {
  return EQUIPMENT_RULES.find((rule) => rule.match(card)) || null;
}

export function findEquipmentByRule(player, ruleId) {
  return (player?.equipments || []).find((card) => getEquipmentRule(card)?.id === ruleId) || null;
}

export function runEquipmentHook(player, hookName, context = {}) {
  const results = [];
  for (const card of player?.equipments || []) {
    const hook = getEquipmentRule(card)?.hooks?.[hookName];
    if (hook) results.push({ card, value: hook({ ...context, equipment: card }) });
  }
  return results;
}

export function firstEquipmentHook(player, hookName, context = {}) {
  return runEquipmentHook(player, hookName, context).find((result) => result.value) || null;
}
