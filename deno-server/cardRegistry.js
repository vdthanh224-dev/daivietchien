import { CARD_SUBTYPES } from './deck.js';

const EQUIPMENT_RULES = Object.freeze([
  { id: 'hoa_mai_tay_son', name: 'Hỏa Mai Tây Sơn', match: (card) => card?.subType === CARD_SUBTYPES.WEAPON && card?.name === 'Hỏa Mai Tây Sơn', hooks: { slashElement: ({ slash }) => slash?.subType === CARD_SUBTYPES.ATTACK_NORMAL ? 'FIRE' : null } },
  { id: 'liem_dao_dong_da', name: 'Liêm Đao Đống Đa', match: (card) => card?.subType === CARD_SUBTYPES.WEAPON && card?.name === 'Liêm Đao Đống Đa', hooks: { slashHitDrawOnce: () => 1 } },
  { id: 'doan_dao_lam_son', name: 'Đoản Đao Lam Sơn', match: (card) => card?.subType === CARD_SUBTYPES.WEAPON && card?.name === 'Đoản Đao Lam Sơn', hooks: { slashHitReplacement: () => 'DESTROY_TWO_TARGET_CARDS' } },
  { id: 'truong_dao_nam_son', name: 'Trường Đao Nam Sơn', match: (card) => card?.subType === CARD_SUBTYPES.WEAPON && card?.name === 'Trường Đao Nam Sơn', hooks: { slashDodged: () => ({ refundSlashUse: true }) } },
  { id: 'thuyen_bach_dang', name: 'Thuyền Bạch Đằng', match: (card) => card?.subType === CARD_SUBTYPES.OFFENSIVE_HORSE && card?.name === 'Thuyền Bạch Đằng', hooks: { ignoreSlashDistance: ({ slash }) => slash?.subType === CARD_SUBTYPES.ATTACK_WATER } },
  { id: 'giap_tay_son', name: 'Giáp Tây Sơn', match: (card) => card?.subType === CARD_SUBTYPES.ARMOR && card?.name === 'Giáp Tây Sơn', hooks: { blockSlash: ({ slash }) => ['Spade', 'Club'].includes(slash?.suit) } }
]);

const rule = (id, family, resolver, requiresTarget = false) => ({ id, family, resolver, requiresTarget });
const SUBTYPE_RULES = new Map([
  [CARD_SUBTYPES.ATTACK_NORMAL, rule('slash_normal', 'BASIC', 'SLASH', true)], [CARD_SUBTYPES.ATTACK_FIRE, rule('slash_fire', 'BASIC', 'SLASH', true)], [CARD_SUBTYPES.ATTACK_WATER, rule('slash_water', 'BASIC', 'SLASH', true)],
  [CARD_SUBTYPES.DODGE, rule('dodge', 'BASIC', 'REACTION')], [CARD_SUBTYPES.PEACH, rule('peach', 'BASIC', 'HEAL_SELF')], [CARD_SUBTYPES.WINE, rule('wine', 'BASIC', 'WINE_SELF')],
  [CARD_SUBTYPES.WEAPON, rule('weapon', 'EQUIPMENT', 'EQUIP')], [CARD_SUBTYPES.ARMOR, rule('armor', 'EQUIPMENT', 'EQUIP')], [CARD_SUBTYPES.OFFENSIVE_HORSE, rule('offensive_horse', 'EQUIPMENT', 'EQUIP')], [CARD_SUBTYPES.DEFENSIVE_HORSE, rule('defensive_horse', 'EQUIPMENT', 'EQUIP')], [CARD_SUBTYPES.BRONZE_DRUM, rule('treasure', 'EQUIPMENT', 'EQUIP')],
  [CARD_SUBTYPES.FLAWLESS_DEFENSE, rule('flawless_defense', 'INSTANT', 'NULLIFY', true)], [CARD_SUBTYPES.DISMANTLE, rule('dismantle', 'INSTANT', 'DESTROY_TARGET_CARD', true)], [CARD_SUBTYPES.SNATCH, rule('snatch', 'INSTANT', 'STEAL_TARGET_CARD', true)], [CARD_SUBTYPES.EX_NIHILO, rule('ex_nihilo', 'INSTANT', 'DRAW_SELF')], [CARD_SUBTYPES.DUEL, rule('duel', 'INSTANT', 'DUEL', true)], [CARD_SUBTYPES.IRON_CHAIN, rule('iron_chain', 'INSTANT', 'IRON_CHAIN')], [CARD_SUBTYPES.HARVEST, rule('harvest', 'INSTANT', 'HARVEST')], [CARD_SUBTYPES.BARBARIAN_INVASION, rule('barbarian_invasion', 'INSTANT', 'AOE')], [CARD_SUBTYPES.ARROW_RAIN, rule('arrow_rain', 'INSTANT', 'AOE')], [CARD_SUBTYPES.THUY_TRIEU_RUT, rule('thuy_trieu_rut', 'INSTANT', 'TIDE_TRANSFER', true)], [CARD_SUBTYPES.MUON_GUOM_DIET_DICH, rule('muon_guom_diet_dich', 'INSTANT', 'BORROW_SWORD', true)], [CARD_SUBTYPES.MO_YEN_TIEC, rule('mo_yen_tiec', 'INSTANT', 'HEAL_ALL')], [CARD_SUBTYPES.HICH_TUONG_SI, rule('hich_tuong_si', 'INSTANT', 'HICH_SELECTION')], [CARD_SUBTYPES.KHO_NHUC_KE, rule('kho_nhuc_ke', 'INSTANT', 'SELF_DAMAGE_DRAW')], [CARD_SUBTYPES.TAU_VI_THUONG_SACH, rule('tau_vi_thuong_sach', 'INSTANT', 'DISCARD_OWN_EQUIPMENT_DRAW')], [CARD_SUBTYPES.PHU_DE_TRUU_TAN, rule('phu_de_truu_tan', 'INSTANT', 'RETURN_TARGET_EQUIPMENT', true)],
  [CARD_SUBTYPES.DAI_HONG_THUY, rule('dai_hong_thuy', 'DELAYED', 'ATTACH_SELF')], [CARD_SUBTYPES.SUPPLY_SHORTAGE, rule('supply_shortage', 'DELAYED', 'ATTACH_TARGET', true)], [CARD_SUBTYPES.ACEDIA, rule('acedia', 'DELAYED', 'ATTACH_TARGET', true)], [CARD_SUBTYPES.BAI_COC_BACH_DANG, rule('bai_coc_bach_dang', 'DELAYED', 'ATTACH_TARGET', true)]
]);
export function getCardRule(card) { return SUBTYPE_RULES.get(card?.subType) || rule('unknown', 'UNKNOWN', 'NONE'); }
export function cardRequiresTarget(card) { return getCardRule(card).requiresTarget === true; }

export function getEquipmentRule(card) { return EQUIPMENT_RULES.find((rule) => rule.match(card)) || null; }
export function findEquipmentByRule(player, ruleId) { return (player?.equipments || []).find((card) => getEquipmentRule(card)?.id === ruleId) || null; }
export function runEquipmentHook(player, hookName, context = {}) {
  return (player?.equipments || []).flatMap((card) => {
    const hook = getEquipmentRule(card)?.hooks?.[hookName];
    return hook ? [{ card, value: hook({ ...context, equipment: card }) }] : [];
  });
}
export function firstEquipmentHook(player, hookName, context = {}) { return runEquipmentHook(player, hookName, context).find((result) => result.value) || null; }
