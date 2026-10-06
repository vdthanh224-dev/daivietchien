import assert from "node:assert/strict";
import {
  applyDamageToPlayer,
  handleDiscardCards,
  handleEndTurn,
  handleAIReaction,
  handlePlayCard,
  handleRespondAction,
  handleUseSkill,
  handleToggleSkill,
  getHandLimit,
  hydrateGameState,
  initGame,
  getNextAliveSeat,
  sanitizeGameStateForClient,
  tickGameState,
} from "./functions/game-engine/src/gameEngine.js";
import { CARD_CATEGORIES, CARD_SUBTYPES, createDeck, createDeck80, createDeck150 } from "./functions/game-engine/src/deck.js";
import { getCardRule } from "./functions/game-engine/src/cardRegistry.js";
import { HEROES, HERO_MAX_HP } from "./functions/game-engine/src/heroes.js";
import { getModeRules } from "./functions/game-engine/src/modeRegistry.js";

const players = [1, 2, 3, 4].map((seat) => ({
  seat,
  userId: `test_${seat}`,
  generalName: `Test ${seat}`,
  maxHp: 4,
}));

function freshState() {
  const state = initGame("room_2v2_regressions", players);
  for (const player of state.players) {
    player.hand = [];
    player.equipments = [];
    player.judgements = [];
    player.hp = 4;
    player.isAlive = true;
    player.isChained = false;
  }
  state.turnSeat = 1;
  state.phase = "PLAY";
  state.status = "PLAYING";
  state.activeCard = null;
  state.slashesUsedThisTurn = 0;
  return state;
}

function card(id, name, subType, category = CARD_CATEGORIES.BASIC) {
  return { id, name, suit: "Heart", rank: 1, category, subType, desc: "test" };
}

function put(state, seat, value) {
  state.players.find((player) => player.seat === seat).hand.push(value);
}

assert.deepEqual(HEROES.HERO_5.skills, ["DUNG_NU", "THU_MUC"]);
assert.deepEqual(HEROES.HERO_6.skills, ["TRINH_LIET", "BAT_NA"]);
assert.deepEqual(HEROES.HERO_7.skills, ["TIEN_PHONG", "TRAN_TIEN"]);
assert.deepEqual(HEROES.HERO_8.skills, ["KHOI_BINH", "HUYNH_TRUONG"]);
assert.equal(HERO_MAX_HP[7], 4);

{
  const state = initGame("room_tien_phong", players.map((player) => ({
    ...player,
    heroId: player.seat === 1 ? "HERO_7" : "HERO_1"
  })));
  assert.equal(state.players[0].hand.length, 7);
  assert.equal(state.players[0].turnsTaken, 1);
}

{
  const state = initGame("room_ffa_registry", players, "ffa_4");
  assert.equal(state.modeId, "ffa_4");
  assert.equal(new Set(state.players.map((player) => player.teamId)).size, 4);
  assert.equal(getModeRules("ffa_4").victory, "LAST_PLAYER_STANDING");
  assert.throws(() => initGame("room_invalid_mode", players, "not_a_mode"), /Chế độ chơi không hợp lệ/);
  assert.throws(() => initGame("room_invalid_count", players.slice(0, 3), "ffa_4"), /cần từ 4 đến 4/);
}

{
  const shuffledTeams = players.map((player, index) => ({ ...player, isAlly: index === 0 || index === 1 }));
  const state = initGame("room_legacy_draft_teams", shuffledTeams);
  assert.deepEqual(state.players.map((player) => player.teamId), ["dragon", "dragon", "phoenix", "phoenix"]);
}

{
  const eightPlayers = Array.from({ length: 8 }, (_, index) => ({
    seat: index + 1,
    userId: `ffa_8_${index + 1}`,
    generalName: `FFA ${index + 1}`,
    maxHp: 4,
  }));
  const state = initGame("room_ffa_8_registry", eightPlayers, "ffa_8");
  assert.equal(state.players.length, 8);
  assert.equal(state._deck.length + state.players.reduce((total, player) => total + player.hand.length, 0), createDeck(150).length);
  for (const player of state.players.slice(1, 7)) {
    player.hp = 0;
    player.isAlive = false;
  }
  assert.equal(getNextAliveSeat(state, 1), 8);
}

{
  const state = freshState();
  state.players[0].heroId = 1; // Cao Lo
  put(state, 1, { ...card("CHE_NO_SPADE_1", "Trảm Thường", CARD_SUBTYPES.ATTACK_NORMAL), suit: "Spade" });
  put(state, 1, { ...card("CHE_NO_SPADE_2", "Đỡ", CARD_SUBTYPES.DODGE), suit: "Spade" });
  put(state, 1, { ...card("CHE_NO_HEART", "Bánh Chưng", CARD_SUBTYPES.PEACH), suit: "Heart" });
  assert.equal(handleUseSkill(state, 1, "Chế Nỏ").success, true);
  assert.deepEqual(state.players[0].hand.map((item) => item.name), ["Nỏ Thần Kim Quy", "Nỏ Thần Kim Quy", "Bánh Chưng"]);
}

{
  const state = freshState();
  state.players[0].heroId = 1; // Cao Lo
  state.players[0].equipments.push({ id: "NO_THAN", name: "Nỏ Thần Kim Quy", subType: CARD_SUBTYPES.WEAPON, range: 1 });
  put(state, 1, card("LIEN_CHAU_SLASH", "Trảm Thường", CARD_SUBTYPES.ATTACK_NORMAL));
  put(state, 1, card("LIEN_CHAU_COST", "Bài bỏ", CARD_SUBTYPES.PEACH));
  put(state, 2, card("LIEN_CHAU_DODGE_1", "Đỡ", CARD_SUBTYPES.DODGE));
  put(state, 4, card("LIEN_CHAU_DODGE_2", "Đỡ", CARD_SUBTYPES.DODGE));
  assert.equal(handlePlayCard(state, 1, "LIEN_CHAU_SLASH", 2, {
    targetSeats: [4],
    lienChauCardId: "LIEN_CHAU_COST"
  }).success, true);
  assert.equal(handleRespondAction(state, 2, true, "LIEN_CHAU_DODGE_1").success, true);
  assert.equal(state.phase, "AWAIT_SLASH_DEFENSE");
  assert.equal(state.waitingTargetSeat, 4);
  assert.equal(handleRespondAction(state, 4, true, "LIEN_CHAU_DODGE_2").success, true);
  assert.equal(state.phase, "PLAY");
}

{
  const state = freshState();
  state.players[1].heroId = 3; // Thi Sach
  put(state, 1, card("UAT_KHI_SLASH", "Trảm Thường", CARD_SUBTYPES.ATTACK_NORMAL));
  assert.equal(handlePlayCard(state, 1, "UAT_KHI_SLASH", 2).success, true);
  assert.equal(handleRespondAction(state, 2, false, null).success, true);
  assert.equal(state.phase, "AWAIT_UAT_KHI");
  assert.equal(state.waitingTargetSeat, 2);
  assert.equal(state.waitingTimer, 40);
  assert.notEqual(state.activeCard, null);
  state.players[1].isAI = true;
  state.timerStartAt = Date.now() - 3_000;
  tickGameState(state);
  assert.equal(state.phase, "AWAIT_UAT_KHI");
  assert.equal(state.waitingTargetSeat, 2);
  assert.equal(handleUseSkill(state, 2, "Uất Khí", 0).success, true);
  assert.equal(state.phase, "PLAY");
  assert.equal(state.activeCard, null);
}

{
  const state = freshState();
  state.players[1].heroId = 3; // Thi Sach
  const selfHandBefore = state.players[1].hand.length;
  applyDamageToPlayer(state, 2, 1, "Kiểm thử");
  assert.equal(state.phase, "AWAIT_UAT_KHI");
  assert.equal(handleUseSkill(state, 2, "Uất Khí", 2).success, true);
  assert.equal(state.players[1].hand.length, selfHandBefore + 1, "Uất Khí phải cho phép chọn chính mình");
}

{
  const state = freshState();
  state.players[0].heroId = "HERO_4"; // Le Chan
  state.players[0].hp = 3;
  put(state, 1, card("LAP_LANG_A", "Trảm Thường", CARD_SUBTYPES.ATTACK_NORMAL));
  put(state, 1, card("LAP_LANG_B", "Đỡ", CARD_SUBTYPES.DODGE));
  put(state, 1, card("LAP_LANG_C", "Bánh Chưng", CARD_SUBTYPES.PEACH));
  put(state, 1, card("LAP_LANG_D", "Hủ Rượu", CARD_SUBTYPES.WINE));
  const beforeDiscard = state.players[0].hand.length;
  assert.equal(handleEndTurn(state, 1).success, true);
  assert.equal(state.phase, "DISCARD");
  assert.equal(state.players[0].hand.length, beforeDiscard, "Lập Làng chưa được rút trước pha bỏ bài");
  assert.equal(handleDiscardCards(state, 1, ["LAP_LANG_A"]).success, true);
  assert.equal(state.players[0].hand.length, 5, "Lập Làng phải rút 2 lá sau khi bỏ bài xong");
}

{
  const state = freshState();
  for (const player of state.players) put(state, player.seat, card(`HAND_${player.seat}`, "Bài thử", 0));
  for (const viewerSeat of [1, 2, 3, 4]) {
    const visible = sanitizeGameStateForClient(state, viewerSeat).players;
    for (const player of visible) {
      assert.equal(player.hand[0].id, player.seat === viewerSeat ? `HAND_${viewerSeat}` : "HIDDEN");
    }
  }
}

{
  const state = freshState();
  put(state, 1, {
    id: "D80_CN_H2_PhongHoa",
    name: "Phóng Hỏa",
    suit: "Heart",
    rank: 2,
    category: CARD_CATEGORIES.INSTANT_SCROLL,
    subType: 23,
    desc: "Mục tiêu công khai 1 lá; bỏ lá cùng chất để gây 1 sát thương Hỏa"
  });
  const hydrated = hydrateGameState(structuredClone(state));
  const migrated = hydrated.players[0].hand[0];
  assert.equal(migrated.id, "D80_CN_H2_ThuyTrieuRut");
  assert.equal(migrated.name, "Thủy Triều Rút");
  assert.equal(migrated.subType, CARD_SUBTYPES.THUY_TRIEU_RUT);
}

{
  const state = freshState();
  put(state, 1, {
    id: "D80_TL_S8",
    name: "Trảm - Lôi",
    suit: "Spade",
    rank: 8,
    category: CARD_CATEGORIES.BASIC,
    subType: CARD_SUBTYPES.ATTACK_THUNDER,
    desc: "Tấn công gây 1 sát thương thuộc tính Lôi"
  });
  state.players[0].judgements.push({
    id: "D80_TH_CA_SamSet",
    name: "Thần Sấm Báo Ứng",
    suit: "Club",
    rank: 1,
    category: CARD_CATEGORIES.DELAYED_SCROLL,
    subType: CARD_SUBTYPES.LIGHTNING,
    desc: "Phán xét gây sát thương Lôi"
  });
  const hydrated = hydrateGameState(structuredClone(state));
  assert.equal(hydrated.players[0].hand[0].name, "Trảm - Thủy");
  assert.equal(hydrated.players[0].hand[0].subType, CARD_SUBTYPES.ATTACK_WATER);
  assert.match(hydrated.players[0].hand[0].desc, /Thủy/);
  assert.equal(hydrated.players[0].judgements[0].name, "Đại Hồng Thủy");
  assert.equal(hydrated.players[0].judgements[0].subType, CARD_SUBTYPES.DAI_HONG_THUY);
  assert.match(hydrated.players[0].judgements[0].desc, /Thủy/);

  hydrated.players[0].hand = [{
    id: "D150_TL_S11",
    name: "Trảm - Lôi",
    category: CARD_CATEGORIES.BASIC,
    subType: CARD_SUBTYPES.ATTACK_THUNDER,
    desc: "Tấn công gây 1 sát thương thuộc tính Lôi"
  }];
  const migrated150 = hydrateGameState(structuredClone(hydrated));
  assert.equal(migrated150.players[0].hand[0].name, "Trảm - Thủy");
  assert.equal(migrated150.players[0].hand[0].subType, CARD_SUBTYPES.ATTACK_WATER);
}

{
  const state = freshState();
  state.phase = "AWAIT_THUY_TRIEU_RUT_GIVE";
  state.waitingTargetSeat = 1;
  state.waitingReactionType = "THUY_TRIEU_RUT_GIVE";
  state.activeCard = { richerSeat: 1, poorerSeat: 2 };
  state.thuyTrieuRutSelection = { casterSeat: 1, targetSeat: 2, richerSeat: 1, poorerSeat: 2 };
  const hydrated = hydrateGameState(structuredClone(state));
  assert.equal(hydrated.thuyTrieuRutSelection, null);
  assert.equal(hydrated.phase, "PLAY");
  assert.equal(hydrated.waitingTargetSeat, 0);
  assert.equal(hydrated.activeCard, null);
}

{
  const state = freshState();
  const customCard = {
    id: "CUSTOM_DIAMOND_K",
    name: "Trảm Tự Tạo",
    suit: "Diamond",
    rank: 13,
    category: CARD_CATEGORIES.BASIC,
    subType: CARD_SUBTYPES.ATTACK_NORMAL,
    desc: "Lá kiểm thử ngoài bộ bài chuẩn"
  };
  put(state, 1, customCard);
  assert.equal(handlePlayCard(state, 1, customCard.id, 2).success, true);
  assert.equal(state.lastDelta.card.id, customCard.id);
  assert.equal(state.lastDelta.card.name, customCard.name);
  assert.equal(state.lastDelta.card.category, customCard.category);
  assert.equal(state.lastDelta.card.subType, customCard.subType);
  assert.equal(state.lastDelta.card.desc, customCard.desc);
  assert.equal(state.lastDelta.cardName, customCard.name);
  assert.equal(state.lastDelta.card.suit, "Diamond");
  assert.equal(state.lastDelta.card.rank, 13);
}

function assertTeammateTargetAllowed(subType, name) {
  const state = freshState();
  put(state, 1, card("CARD_TGT", name, subType, subType >= CARD_SUBTYPES.DAI_HONG_THUY
    ? CARD_CATEGORIES.DELAYED_SCROLL
    : CARD_CATEGORIES.INSTANT_SCROLL));
  put(state, 3, card("TGT_HAND", "Bài đồng đội", CARD_SUBTYPES.ATTACK_NORMAL));
  // Ghế 1 và Ghế 3 là đồng đội, lá bài được phép nhắm mục tiêu đồng đội
  if (subType === CARD_SUBTYPES.SUPPLY_SHORTAGE || subType === CARD_SUBTYPES.SNATCH) {
    // Cần cự ly <= 1: trang bị Ngựa Công cho Ghế 1
    state.players.find(p => p.seat === 1).equipments.push({ id: "OFF_HORSE", name: "Ngựa Trắng", subType: CARD_SUBTYPES.OFFENSIVE_HORSE, distMod: -1, category: CARD_CATEGORIES.EQUIPMENT });
  }
  const result = handlePlayCard(state, 1, "CARD_TGT", 3);
  assert.equal(result.success, true, `Dùng ${name} lên đồng minh phải thành công!`);
}

assertTeammateTargetAllowed(CARD_SUBTYPES.SNATCH, "Đột Kích Trộm Lương");
assertTeammateTargetAllowed(CARD_SUBTYPES.DISMANTLE, "Vườn Không Nhà Trống");
assertTeammateTargetAllowed(CARD_SUBTYPES.SUPPLY_SHORTAGE, "Cắt Đường Lương");
assertTeammateTargetAllowed(CARD_SUBTYPES.ACEDIA, "Trầm Ảo Sa Bẫy");

{
  const state = freshState();
  put(state, 1, card("BLOOD", "Huyết Chiến", CARD_SUBTYPES.BLOOD_BATTLE, CARD_CATEGORIES.INSTANT_SCROLL));
  const result = handlePlayCard(state, 1, "BLOOD", 3);
  assert.equal(result.success, true);
  assert.equal(state.phase, "AWAIT_DUEL");
}

{
  const state = freshState();
  put(state, 1, card("BLOOD_LEGACY", "Thách Đấu", CARD_SUBTYPES.BLOOD_BATTLE, CARD_CATEGORIES.INSTANT_SCROLL));
  assert.equal(handlePlayCard(state, 1, "BLOOD_LEGACY", 3).success, true);
  assert.equal(state.phase, "AWAIT_DUEL");
}

{
  const state = freshState();
  put(state, 1, card("BAI_COC_PLAY", "Bãi Cọc Bạch Đằng", CARD_SUBTYPES.BAI_COC_BACH_DANG, CARD_CATEGORIES.DELAYED_SCROLL));
  assert.match(handlePlayCard(state, 1, "BAI_COC_PLAY").error, /Cần chọn mục tiêu/);
  assert.equal(handlePlayCard(state, 1, "BAI_COC_PLAY", 2).success, true);
  assert.equal(state.players[1].judgements.length, 1);
}

{
  const state = freshState();
  state.players[0].equipments.push({ id: "WEAPON", name: "Vũ khí thử", subType: CARD_SUBTYPES.WEAPON, range: 2 });
  put(state, 1, card("SLASH_ALLY", "Trảm Thường", CARD_SUBTYPES.ATTACK_NORMAL));
  const result = handlePlayCard(state, 1, "SLASH_ALLY", 3);
  assert.equal(result.success, true);
  assert.equal(state.waitingTargetSeat, 3);
  handleRespondAction(state, 3, false, null);
}

{
  const state = freshState();
  state.players[1].heroId = "47";
  put(state, 1, card("LY_ATTACK", "Trảm Thường", CARD_SUBTYPES.ATTACK_NORMAL));
  put(state, 2, card("LY_DODGE_WITH_SLASH", "Trảm Thường", CARD_SUBTYPES.ATTACK_NORMAL));
  assert.equal(handlePlayCard(state, 1, "LY_ATTACK", 2).success, true);
  assert.equal(handleRespondAction(state, 2, true, "LY_DODGE_WITH_SLASH").success, true);
  assert.equal(state.players[1].hand.length, 0);
  assert.equal(state._discard.some((candidate) => candidate.id === "LY_DODGE_WITH_SLASH"), true);
}

{
  const state = freshState();
  state.players[1].heroId = "";
  state.players[1].generalName = "Nguyễn Cảnh Chân";
  const clubCard = card("NGUYEN_DODGE_WITH_CLUB", "Bài Chuồn", CARD_SUBTYPES.PEACH);
  clubCard.suit = "Club";
  put(state, 1, card("NGUYEN_ATTACK", "Trảm Thường", CARD_SUBTYPES.ATTACK_NORMAL));
  put(state, 2, clubCard);
  assert.equal(handlePlayCard(state, 1, "NGUYEN_ATTACK", 2).success, true);
  assert.equal(handleRespondAction(state, 2, true, "NGUYEN_DODGE_WITH_CLUB").success, true);
  assert.equal(state.players[1].hand.length, 0);
  assert.equal(state._discard.some((candidate) => candidate.id === "NGUYEN_DODGE_WITH_CLUB"), true);
}

{
  const state = freshState();
  const trap = card("TRAP", "Bãi Cọc Bạch Đằng", CARD_SUBTYPES.BAI_COC_BACH_DANG, CARD_CATEGORIES.DELAYED_SCROLL);
  trap.suit = "Spade";
  state.players[1].judgements.push(trap);
  state.turnSeat = 2;
  put(state, 2, card("TRAPPED_SLASH", "Trảm Thường", CARD_SUBTYPES.ATTACK_NORMAL));
  state._deck = [card("BLACK_JUDGE", "Phán Xét", CARD_SUBTYPES.ATTACK_NORMAL)];
  state._deck[0].suit = "Club";
  const result = handlePlayCard(state, 2, "TRAPPED_SLASH", 1);
  assert.equal(result.success, true);
  assert.equal(state.players[1].hp, 3);
  assert.equal(state.players[1].judgements.length, 0);
}

{
  const state = freshState();
  const trap = card("TRAP_NULLIFY", "Bãi Cọc Bạch Đằng", CARD_SUBTYPES.BAI_COC_BACH_DANG, CARD_CATEGORIES.DELAYED_SCROLL);
  trap.attachedBySeat = 1;
  state.players[1].judgements.push(trap);
  state.turnSeat = 2;
  put(state, 2, card("TRAPPED_SLASH_NULLIFY", "Trảm Thường", CARD_SUBTYPES.ATTACK_NORMAL));
  put(state, 3, card("BAI_COC_NULLIFY", "Diệu Kế Phá Mưu", CARD_SUBTYPES.FLAWLESS_DEFENSE, CARD_CATEGORIES.INSTANT_SCROLL));
  assert.equal(handlePlayCard(state, 2, "TRAPPED_SLASH_NULLIFY", 1).success, true);
  assert.equal(state.phase, "AWAIT_NULLIFY");
  assert.equal(state.waitingTargetSeat, 3);
  assert.equal(handleRespondAction(state, 3, true, "BAI_COC_NULLIFY").success, true);
  assert.equal(state.players[1].judgements.length, 0);
  assert.equal(state.phase, "AWAIT_SLASH_DEFENSE");
  assert.equal(state.players[1].hp, 4);
}

for (const [id, name, subType, reqType] of [
  ["AOE_GIAC_TOI", "Giặc Tới", CARD_SUBTYPES.BARBARIAN_INVASION, "SLASH"],
  ["AOE_MUA_TEN", "Mưa Tên Liên Châu", CARD_SUBTYPES.ARROW_RAIN, "DODGE"],
]) {
  const state = freshState();
  state.players[1].equipments.push({ id: `ARMOR_${id}`, name: "Áo Bào Hoàng Tộc", subType: CARD_SUBTYPES.ARMOR });
  put(state, 1, card(id, name, subType, CARD_CATEGORIES.INSTANT_SCROLL));
  assert.equal(handlePlayCard(state, 1, id, 0).success, true);
  assert.equal(state.waitingReactionType, reqType);
  const victimSeat = state.waitingTargetSeat;
  assert.equal(handleRespondAction(state, victimSeat, false, null).success, true);
  assert.equal(state.lastAction.type, "AOE_HIT");
  assert.equal(state.lastAction.armorEffect, "AO_BAO_HOANG_TOC");
}

{
  const state = freshState();
  const trap = card("TRAP_ONE_JUDGEMENT", "Bãi Cọc Bạch Đằng", CARD_SUBTYPES.BAI_COC_BACH_DANG, CARD_CATEGORIES.DELAYED_SCROLL);
  state.players[1].judgements.push(trap);
  state.turnSeat = 2;
  put(state, 2, card("TRAPPED_SLASH_FIRST", "Trảm Thường", CARD_SUBTYPES.ATTACK_NORMAL));
  const firstBlackJudge = card("BLACK_JUDGE_FIRST", "Phán Xét", CARD_SUBTYPES.ATTACK_NORMAL);
  firstBlackJudge.suit = "Club";
  state._deck = [firstBlackJudge];

  assert.equal(handlePlayCard(state, 2, "TRAPPED_SLASH_FIRST", 1).success, true);
  assert.equal(state.players[1].hp, 3);
  assert.equal(state.players[1].judgements.length, 0);
  assert.match(state.actionHistory.findLast((action) => /Bãi Cọc/.test(action.description || ""))?.description || "", /Bãi Cọc rời đi sau phán xét/);
}

{
  const state = freshState();
  const trap = card("TRAP_RED", "Bãi Cọc Bạch Đằng", CARD_SUBTYPES.BAI_COC_BACH_DANG, CARD_CATEGORIES.DELAYED_SCROLL);
  trap.attachedBySeat = 1;
  state.players[1].judgements.push(trap);
  state.turnSeat = 2;
  put(state, 2, card("TRAPPED_SLASH_RED", "Trảm Thường", CARD_SUBTYPES.ATTACK_NORMAL));
  const redJudge = card("RED_JUDGE", "Phán Xét", CARD_SUBTYPES.ATTACK_NORMAL);
  redJudge.suit = "Diamond";
  state._deck = [redJudge];
  assert.equal(handlePlayCard(state, 2, "TRAPPED_SLASH_RED", 1).success, true);
  assert.equal(state.players[1].judgements.length, 0);
  assert.equal(state.phase, "AWAIT_SLASH_DEFENSE");
  assert.equal(state.players[1].hp, 4);
}

{
  const state = freshState();
  put(state, 1, card("HICH", "Hịch Tướng Sĩ", CARD_SUBTYPES.HICH_TUONG_SI, CARD_CATEGORIES.INSTANT_SCROLL));
  put(state, 1, card("HICH_COST", "Bài bỏ", CARD_SUBTYPES.ATTACK_NORMAL));
  put(state, 3, card("ALLY_COST", "Bài đồng đội", CARD_SUBTYPES.ATTACK_NORMAL));
  const result = handlePlayCard(state, 1, "HICH", 0, { targetSeats: [3] });
  assert.equal(result.success, true);
  assert.equal(state.phase, "AWAIT_HICH_CASTER_DISCARD");
  assert.equal(handleRespondAction(state, 1, true, "HICH_COST").success, true);
  assert.equal(state.phase, "AWAIT_HICH_TARGET_DISCARD");
  assert.equal(handleRespondAction(state, 3, true, "ALLY_COST").success, true);
  assert.equal(state.players[0].sucSoiTurnsRemaining, 1);
  assert.equal(state.players[2].sucSoiTurnsRemaining, 1);
  assert.equal(sanitizeGameStateForClient(state, 1).players[0].sucSoiTurnsRemaining, 1);

  // Sục Sôi cho phép Trảm không giới hạn trong lượt hiện tại.
  put(state, 1, card("HICH_SLASH_1", "Trảm Thường", CARD_SUBTYPES.ATTACK_NORMAL));
  put(state, 1, card("HICH_SLASH_2", "Trảm Thường", CARD_SUBTYPES.ATTACK_NORMAL));
  assert.equal(handlePlayCard(state, 1, "HICH_SLASH_1", 2).success, true);
  assert.equal(handleRespondAction(state, 2, false, null).success, true);
  assert.equal(state.slashesUsedThisTurn, 1);
  assert.equal(handlePlayCard(state, 1, "HICH_SLASH_2", 2).success, true);
  assert.equal(state.slashesUsedThisTurn, 2);
}

{
  const state = freshState();
  put(state, 1, card("HICH_PASS", "Hịch Tướng Sĩ", CARD_SUBTYPES.HICH_TUONG_SI, CARD_CATEGORIES.INSTANT_SCROLL));
  put(state, 1, card("HICH_SELF_COST", "Bài bỏ", CARD_SUBTYPES.ATTACK_NORMAL));
  put(state, 3, card("HICH_TARGET_COST", "Bài đồng đội", CARD_SUBTYPES.ATTACK_NORMAL));
  assert.equal(handlePlayCard(state, 1, "HICH_PASS", 0, { targetSeats: [3] }).success, true);
  assert.equal(handleRespondAction(state, 1, false, null).success, true);
  assert.equal(state.phase, "AWAIT_HICH_TARGET_DISCARD");
  assert.equal(handleRespondAction(state, 3, false, null).success, true);
  assert.equal(state.players[0].sucSoiTurnsRemaining, 0);
  assert.equal(state.players[2].sucSoiTurnsRemaining, 0);
}

{
  const state = freshState();
  put(state, 1, card("HICH_NO_TARGET", "Hịch Tướng Sĩ", CARD_SUBTYPES.HICH_TUONG_SI, CARD_CATEGORIES.INSTANT_SCROLL));
  const result = handlePlayCard(state, 1, "HICH_NO_TARGET", 0, { targetSeats: [] });
  assert.match(result.error, /đúng 1 người chơi khác còn sống/);
  assert.equal(state.phase, "PLAY");
  assert.equal(state.players[0].hand.some((candidate) => candidate.id === "HICH_NO_TARGET"), true);
}

{
  const state = freshState();
  put(state, 1, card("HICH_MULTIPLE_TARGETS", "Hịch Tướng Sĩ", CARD_SUBTYPES.HICH_TUONG_SI, CARD_CATEGORIES.INSTANT_SCROLL));
  const result = handlePlayCard(state, 1, "HICH_MULTIPLE_TARGETS", 0, { targetSeats: [2, 3] });
  assert.match(result.error, /đúng 1 người chơi khác còn sống/);
  assert.equal(state.phase, "PLAY");
  assert.equal(state.players[0].hand.some((candidate) => candidate.id === "HICH_MULTIPLE_TARGETS"), true);
}

{
  const state = freshState();
  put(state, 1, card("TIDE", "Thủy Triều Rút", CARD_SUBTYPES.THUY_TRIEU_RUT, CARD_CATEGORIES.INSTANT_SCROLL));
  put(state, 1, card("TIDE_KEPT", "Lá giữ", CARD_SUBTYPES.ATTACK_NORMAL));
  put(state, 2, card("TIDE_GIVEN", "Lá mục tiêu đưa", CARD_SUBTYPES.ATTACK_NORMAL));
  assert.equal(handlePlayCard(state, 1, "TIDE", 2).success, true);
  assert.equal(state.phase, "AWAIT_THUY_TRIEU_RUT_GIVE");
  assert.equal(state.waitingTargetSeat, 2);
  assert.equal(state.players[0].hp, 4);
  assert.equal(state.players[1].hp, 4);
  assert.equal(handleRespondAction(state, 2, true, "TIDE_GIVEN").success, true);
  assert.equal(state.phase, "PLAY");
  assert.equal(state.players[0].hand.some((candidate) => candidate.id === "TIDE_GIVEN"), true);
  assert.equal(state.players[1].hand.some((candidate) => candidate.id === "TIDE_GIVEN"), false);
  assert.equal(state.players[1].hp, 4);
  assert.equal(state.lastAction.type, "THUY_TRIEU_RUT_GIVE");
  assert.match(state.lastAction.description, /Bài Cơ Bản nên không so số bài/);
}

{
  const state = freshState();
  put(state, 1, card("TIDE_EQUAL", "Thủy Triều Rút", CARD_SUBTYPES.THUY_TRIEU_RUT, CARD_CATEGORIES.INSTANT_SCROLL));
  put(state, 2, card("TIDE_EQUAL_GIVEN", "Lá mục tiêu đưa", CARD_SUBTYPES.ATTACK_NORMAL));
  put(state, 2, card("TIDE_EQUAL_KEPT", "Lá mục tiêu giữ", CARD_SUBTYPES.ATTACK_NORMAL));
  assert.equal(handlePlayCard(state, 1, "TIDE_EQUAL", 2).success, true);
  assert.equal(state.phase, "AWAIT_THUY_TRIEU_RUT_GIVE");
  assert.equal(handleRespondAction(state, 2, true, "TIDE_EQUAL_GIVEN").success, true);
  assert.equal(state.players[0].hp, 4);
  assert.equal(state.players[1].hp, 4);
  assert.equal(state.phase, "PLAY");
  assert.equal(state.lastAction.type, "THUY_TRIEU_RUT_GIVE");
}

{
  const state = freshState();
  put(state, 1, card("TIDE_TARGET_RICH", "Thủy Triều Rút", CARD_SUBTYPES.THUY_TRIEU_RUT, CARD_CATEGORIES.INSTANT_SCROLL));
  put(state, 2, card("TIDE_TARGET_GIVEN", "Lá đối thủ đưa", CARD_SUBTYPES.ATTACK_NORMAL));
  put(state, 2, card("TIDE_TARGET_KEEP", "Lá đối thủ giữ", CARD_SUBTYPES.ATTACK_NORMAL));
  put(state, 2, card("TIDE_TARGET_EXTRA", "Lá đối thủ thêm", CARD_SUBTYPES.ATTACK_NORMAL));
  assert.equal(handlePlayCard(state, 1, "TIDE_TARGET_RICH", 2).success, true);
  assert.equal(state.waitingTargetSeat, 2);
  assert.equal(handleRespondAction(state, 2, true, "TIDE_TARGET_GIVEN").success, true);
  assert.equal(state.players[0].hand.some((candidate) => candidate.id === "TIDE_TARGET_GIVEN"), true);
  assert.equal(state.players[0].hp, 4);
  assert.equal(state.players[1].hp, 4);
  assert.equal(state.lastAction.type, "THUY_TRIEU_RUT_GIVE");
  assert.match(state.lastAction.description, /Bài Cơ Bản nên không so số bài/);
}

{
  const state = freshState();
  state.players[0].hp = 1;
  put(state, 1, card("TIDE_NEAR_DEATH", "Thủy Triều Rút", CARD_SUBTYPES.THUY_TRIEU_RUT, CARD_CATEGORIES.INSTANT_SCROLL));
  put(state, 1, card("TIDE_NEAR_DEATH_KEPT", "Lá giữ", CARD_SUBTYPES.ATTACK_NORMAL));
  put(state, 1, card("TIDE_NEAR_DEATH_RESCUE", "Hủ Rượu", CARD_SUBTYPES.WINE));
  put(state, 2, card("TIDE_NEAR_DEATH_GIVEN", "Trang bị mục tiêu", CARD_SUBTYPES.WEAPON, CARD_CATEGORIES.EQUIPMENT));
  for (const id of ["TIDE_NEAR_DEATH_TARGET_2", "TIDE_NEAR_DEATH_TARGET_3", "TIDE_NEAR_DEATH_TARGET_4", "TIDE_NEAR_DEATH_TARGET_5"]) {
    put(state, 2, card(id, "Bài mục tiêu", CARD_SUBTYPES.ATTACK_NORMAL));
  }
  assert.equal(handlePlayCard(state, 1, "TIDE_NEAR_DEATH", 2).success, true);
  assert.equal(state.phase, "AWAIT_THUY_TRIEU_RUT_GIVE");
  assert.equal(handleRespondAction(state, 2, true, "TIDE_NEAR_DEATH_GIVEN").success, true);
  assert.equal(state.phase, "AWAIT_NEAR_DEATH");
  assert.equal(state.waitingTargetSeat, 1);
  assert.equal(handleRespondAction(state, 1, true, "TIDE_NEAR_DEATH_RESCUE").success, true);
  assert.equal(state.phase, "PLAY");
  assert.equal(state.players[0].hand.some((candidate) => candidate.id === "TIDE_NEAR_DEATH_GIVEN"), true);
}

{
  const state = freshState();
  put(state, 1, card("TIDE_EMPTY_TARGET", "Thủy Triều Rút", CARD_SUBTYPES.THUY_TRIEU_RUT, CARD_CATEGORIES.INSTANT_SCROLL));
  const result = handlePlayCard(state, 1, "TIDE_EMPTY_TARGET", 2);
  assert.match(result.error, /phải có ít nhất 1 lá/);
  assert.equal(state.phase, "PLAY");
  assert.equal(state.players[0].hand.some((candidate) => candidate.id === "TIDE_EMPTY_TARGET"), true);
}

{
	const state = freshState();
	put(state, 1, card("BORROW_NO_WEAPON", "Mượn Gươm Diệt Địch", CARD_SUBTYPES.MUON_GUOM_DIET_DICH, CARD_CATEGORIES.INSTANT_SCROLL));
	put(state, 3, card("BORROW_INVALID_NULLIFY", "Diệu Kế Phá Mưu", CARD_SUBTYPES.FLAWLESS_DEFENSE, CARD_CATEGORIES.INSTANT_SCROLL));
	const result = handlePlayCard(state, 1, "BORROW_NO_WEAPON", 2, { targetSeat2: 4 });
	assert.match(result.error, /chưa trang bị Vũ khí/);
	assert.equal(state.phase, "PLAY");
	assert.equal(state.waitingTargetSeat, 0);
	assert.equal(state.nullifyChain ?? null, null);
	assert.equal(state.players[0].hand.some((candidate) => candidate.id === "BORROW_NO_WEAPON"), true);
	assert.equal(state.players[2].hand.some((candidate) => candidate.id === "BORROW_INVALID_NULLIFY"), true);
}

{
	const state = freshState();
	const weapon = card("BORROW_WEAPON", "Vũ khí thử", CARD_SUBTYPES.WEAPON, CARD_CATEGORIES.EQUIPMENT);
  weapon.range = 2;
  state.players[1].equipments.push(weapon);
  put(state, 1, card("BORROW", "Mượn Gươm Diệt Địch", CARD_SUBTYPES.MUON_GUOM_DIET_DICH, CARD_CATEGORIES.INSTANT_SCROLL));
  put(state, 2, card("BORROW_SLASH", "Trảm Thường", CARD_SUBTYPES.ATTACK_NORMAL));
  assert.match(handlePlayCard(state, 1, "BORROW", 2).error, /Cần chọn mục tiêu khác/);
  assert.equal(state.players[0].hand.some((candidate) => candidate.id === "BORROW"), true);
  assert.equal(handlePlayCard(state, 1, "BORROW", 2, { targetSeat2: 4 }).success, true);
  assert.equal(state.phase, "AWAIT_BORROW_SWORD");
  assert.equal(handleRespondAction(state, 2, true, "BORROW_SLASH").success, true);
  assert.equal(state.activeCard.casterSeat, 2);
  assert.equal(state.waitingTargetSeat, 4);
  assert.equal(handleRespondAction(state, 4, false, null).success, true);
  assert.equal(state.players[3].hp, 3);
}

{
  const state = freshState();
  const weapon = card("BORROW_SELF_WEAPON", "Vũ khí thử", CARD_SUBTYPES.WEAPON, CARD_CATEGORIES.EQUIPMENT);
  weapon.range = 2;
  state.players[1].equipments.push(weapon);
  put(state, 1, card("BORROW_SELF", "Mượn Gươm Diệt Địch", CARD_SUBTYPES.MUON_GUOM_DIET_DICH, CARD_CATEGORIES.INSTANT_SCROLL));
  assert.equal(handlePlayCard(state, 1, "BORROW_SELF", 2, { targetSeat2: 1 }).success, true);
  assert.equal(state.activeCard.forcedTargetSeat, 1);
}

{
  const state = freshState();
  const weapon = card("BORROW_AI_WEAPON", "Vũ khí AI", CARD_SUBTYPES.WEAPON, CARD_CATEGORIES.EQUIPMENT);
  weapon.range = 2;
  state.players[1].equipments.push(weapon);
  state.players[1].isAI = true;
  put(state, 1, card("BORROW_AI", "Mượn Gươm Diệt Địch", CARD_SUBTYPES.MUON_GUOM_DIET_DICH, CARD_CATEGORIES.INSTANT_SCROLL));
  put(state, 2, card("BORROW_AI_SLASH", "Trảm Thường", CARD_SUBTYPES.ATTACK_NORMAL));
  assert.equal(handlePlayCard(state, 1, "BORROW_AI", 2, { targetSeat2: 4 }).success, true);
  assert.equal(handleAIReaction(state, 2).success, true);
  assert.equal(state.phase, "AWAIT_SLASH_DEFENSE");
  assert.equal(state.waitingTargetSeat, 4);
}

{
  const state = freshState();
  const weapon = card("BORROW_TIMEOUT_WEAPON", "Vũ khí hết giờ", CARD_SUBTYPES.WEAPON, CARD_CATEGORIES.EQUIPMENT);
  weapon.range = 2;
  state.players[1].equipments.push(weapon);
  put(state, 1, card("BORROW_TIMEOUT", "Mượn Gươm Diệt Địch", CARD_SUBTYPES.MUON_GUOM_DIET_DICH, CARD_CATEGORIES.INSTANT_SCROLL));
  assert.equal(handlePlayCard(state, 1, "BORROW_TIMEOUT", 2, { targetSeat2: 4 }).success, true);
  state.timerStartAt = Date.now() - 41000;
  assert.equal(tickGameState(state).changed, true);
  assert.equal(state.phase, "PLAY");
  assert.equal(state.players[0].hand.some((candidate) => candidate.id === "BORROW_TIMEOUT_WEAPON"), true);
}

{
  const state = freshState();
  const weapon = card("BORROW_GIFT_WEAPON", "Vũ khí chuyển giao", CARD_SUBTYPES.WEAPON, CARD_CATEGORIES.EQUIPMENT);
  weapon.range = 2;
  state.players[1].equipments.push(weapon);
  put(state, 1, card("BORROW_GIFT", "Mượn Gươm Diệt Địch", CARD_SUBTYPES.MUON_GUOM_DIET_DICH, CARD_CATEGORIES.INSTANT_SCROLL));
  assert.equal(handlePlayCard(state, 1, "BORROW_GIFT", 2, { targetSeat2: 4 }).success, true);
  assert.equal(handleRespondAction(state, 2, false, null).success, true);
  assert.equal(state.players[1].equipments.some((candidate) => candidate.id === "BORROW_GIFT_WEAPON"), false);
  assert.equal(state.players[0].hand.some((candidate) => candidate.id === "BORROW_GIFT_WEAPON"), true);
}

{
  const state = freshState();
  const weapon = card("BORROW_SONG_WEAPON", "Song Cung Mường Nhạ", CARD_SUBTYPES.WEAPON, CARD_CATEGORIES.EQUIPMENT);
  weapon.range = 2;
  state.players[1].equipments.push(weapon);
  put(state, 1, card("BORROW_SONG", "Mượn Gươm Diệt Địch", CARD_SUBTYPES.MUON_GUOM_DIET_DICH, CARD_CATEGORIES.INSTANT_SCROLL));
  put(state, 2, card("BORROW_SONG_SLASH", "Trảm Thường", CARD_SUBTYPES.ATTACK_NORMAL));
  put(state, 2, card("BORROW_SONG_COST_1", "Bài bỏ 1", CARD_SUBTYPES.PEACH));
  put(state, 2, card("BORROW_SONG_COST_2", "Bài bỏ 2", CARD_SUBTYPES.WINE));
  put(state, 4, card("BORROW_SONG_DODGE", "Đỡ", CARD_SUBTYPES.DODGE));
  assert.equal(handlePlayCard(state, 1, "BORROW_SONG", 2, { targetSeat2: 4 }).success, true);
  assert.equal(handleRespondAction(state, 2, true, "BORROW_SONG_SLASH").success, true);
  assert.equal(state.activeCard.targetSeat, 4);
  assert.equal(handleRespondAction(state, 4, true, "BORROW_SONG_DODGE").success, true);
  assert.equal(state.phase, "AWAIT_SONG_CUNG_FOLLOW_UP");
  assert.equal(handleRespondAction(state, 2, true, null, null, ["BORROW_SONG_COST_1", "BORROW_SONG_COST_2"]).success, true);
  assert.equal(state.players[1].hp, 4);
  assert.equal(state.players[3].hp, 3);
  assert.equal(state.actionHistory.some((a) => a.type === "SONG_CUNG_TRIGGERED"), true);
}

{
  const state = freshState();
  const weapon = card("BORROW_SONG_WEAPON2", "Song Cung Mường Nhạ", CARD_SUBTYPES.WEAPON, CARD_CATEGORIES.EQUIPMENT);
  weapon.range = 2;
  state.players[1].equipments.push(weapon);
  put(state, 1, card("BORROW_SONG2", "Mượn Gươm Diệt Địch", CARD_SUBTYPES.MUON_GUOM_DIET_DICH, CARD_CATEGORIES.INSTANT_SCROLL));
  put(state, 2, card("BORROW_SONG_SLASH2", "Trảm Thường", CARD_SUBTYPES.ATTACK_NORMAL));
  put(state, 2, card("BORROW_SONG_COST_1B", "Bài bỏ 1", CARD_SUBTYPES.PEACH));
  put(state, 2, card("BORROW_SONG_COST_2B", "Bài bỏ 2", CARD_SUBTYPES.WINE));
  put(state, 4, card("BORROW_SONG_DODGE2", "Đỡ", CARD_SUBTYPES.DODGE));
  assert.equal(handlePlayCard(state, 1, "BORROW_SONG2", 2, { targetSeat2: 4 }).success, true);
  assert.equal(handleRespondAction(state, 2, true, "BORROW_SONG_SLASH2").success, true);
  assert.equal(handleRespondAction(state, 4, true, "BORROW_SONG_DODGE2").success, true);
  assert.equal(state.phase, "AWAIT_SONG_CUNG_FOLLOW_UP");
  assert.equal(state.lastDelta.type, "SONG_CUNG_PROMPT");
  // Player chooses to skip/pass
  assert.equal(handleRespondAction(state, 2, false, null).success, true);
  assert.equal(state.phase, "PLAY");
  assert.equal(state.lastDelta.type, "SONG_CUNG_PASSED");
  assert.equal(state.players[3].hp, 4); // Target took no damage
  assert.equal(state.players[1].hand.length, 2); // Cards kept
}

{
  const state = freshState();
  const weapon = card("SONG_WINE_WEAPON", "Song Cung Mường Nhạ", CARD_SUBTYPES.WEAPON, CARD_CATEGORIES.EQUIPMENT);
  weapon.range = 2;
  state.players[0].equipments.push(weapon);
  put(state, 1, card("SONG_WINE", "Hủ Rượu", CARD_SUBTYPES.WINE));
  put(state, 1, card("SONG_WINE_SLASH", "Trảm Thường", CARD_SUBTYPES.ATTACK_NORMAL));
  put(state, 1, card("SONG_WINE_COST_1", "Bài bỏ 1", CARD_SUBTYPES.PEACH));
  put(state, 1, card("SONG_WINE_COST_2", "Bài bỏ 2", CARD_SUBTYPES.DODGE));
  put(state, 2, card("SONG_WINE_DODGE", "Đỡ", CARD_SUBTYPES.DODGE));
  assert.equal(handlePlayCard(state, 1, "SONG_WINE", 1).success, true);
  assert.equal(handlePlayCard(state, 1, "SONG_WINE_SLASH", 2).success, true);
  assert.equal(handleRespondAction(state, 2, true, "SONG_WINE_DODGE").success, true);
  assert.equal(state.phase, "AWAIT_SONG_CUNG_FOLLOW_UP");
  assert.equal(handleRespondAction(state, 1, true, null, null, ["SONG_WINE_COST_1", "SONG_WINE_COST_2"]).success, true);
  assert.equal(state.players[1].hp, 2);
  assert.equal(state.lastAction.type, "DAMAGE_TAKEN");
  assert.equal(state.lastAction.damage, 2);
}

{
  const state = freshState();
  const weapon = card("BORROW_ARMOR_WEAPON", "Vũ khí thử", CARD_SUBTYPES.WEAPON, CARD_CATEGORIES.EQUIPMENT);
  weapon.range = 2;
  state.players[1].equipments.push(weapon);
  state.players[3].equipments.push(card("BORROW_GIAP_DONG", "Giáp Đồng Sơn Vi", CARD_SUBTYPES.ARMOR, CARD_CATEGORIES.EQUIPMENT));
  put(state, 1, card("BORROW_ARMOR", "Mượn Gươm Diệt Địch", CARD_SUBTYPES.MUON_GUOM_DIET_DICH, CARD_CATEGORIES.INSTANT_SCROLL));
  put(state, 2, card("BORROW_ARMOR_SLASH", "Trảm Thường", CARD_SUBTYPES.ATTACK_NORMAL));
  assert.equal(handlePlayCard(state, 1, "BORROW_ARMOR", 2, { targetSeat2: 4 }).success, true);
  assert.equal(handleRespondAction(state, 2, true, "BORROW_ARMOR_SLASH").success, true);
  assert.equal(state.phase, "PLAY");
  assert.equal(state.players[3].hp, 4);
}

{
  const state = freshState();
  const weapon = card("BORROW_THUAN_WEAPON", "Kiếm Thuận Thiên", CARD_SUBTYPES.WEAPON, CARD_CATEGORIES.EQUIPMENT);
  weapon.range = 2;
  state.players[1].equipments.push(weapon);
  state.players[3].equipments.push(card("BORROW_THUAN_GIAP_DONG", "Giáp Đồng Sơn Vi", CARD_SUBTYPES.ARMOR, CARD_CATEGORIES.EQUIPMENT));
  put(state, 1, card("BORROW_THUAN", "Mượn Gươm Diệt Địch", CARD_SUBTYPES.MUON_GUOM_DIET_DICH, CARD_CATEGORIES.INSTANT_SCROLL));
  put(state, 2, card("BORROW_THUAN_SLASH", "Trảm Thường", CARD_SUBTYPES.ATTACK_NORMAL));
  assert.equal(handlePlayCard(state, 1, "BORROW_THUAN", 2, { targetSeat2: 4 }).success, true);
  assert.equal(handleRespondAction(state, 2, true, "BORROW_THUAN_SLASH").success, true);
  assert.equal(state.phase, "AWAIT_SLASH_DEFENSE");
  assert.equal(handleRespondAction(state, 4, false, null).success, true);
  assert.equal(state.players[3].hp, 3);
}

{
  const state = freshState();
  const weapon = card("BORROW_NAM_SON", "Trường Đao Nam Sơn", CARD_SUBTYPES.WEAPON, CARD_CATEGORIES.EQUIPMENT);
  weapon.range = 2;
  state.players[1].equipments.push(weapon);
  put(state, 1, card("NORMAL_SLASH_BEFORE_BORROW", "Trảm Thường", CARD_SUBTYPES.ATTACK_NORMAL));
  put(state, 1, card("BORROW_NAM_SON_CARD", "Mượn Gươm Diệt Địch", CARD_SUBTYPES.MUON_GUOM_DIET_DICH, CARD_CATEGORIES.INSTANT_SCROLL));
  put(state, 2, card("BORROW_NAM_SON_SLASH", "Trảm Thường", CARD_SUBTYPES.ATTACK_NORMAL));
  put(state, 4, card("BORROW_NAM_SON_DODGE", "Đỡ", CARD_SUBTYPES.DODGE));
  assert.equal(handlePlayCard(state, 1, "NORMAL_SLASH_BEFORE_BORROW", 2).success, true);
  assert.equal(handleRespondAction(state, 2, false, null).success, true);
  assert.equal(state.slashesUsedThisTurn, 1);
  assert.equal(handlePlayCard(state, 1, "BORROW_NAM_SON_CARD", 2, { targetSeat2: 4 }).success, true);
  assert.equal(handleRespondAction(state, 2, true, "BORROW_NAM_SON_SLASH").success, true);
  assert.equal(handleRespondAction(state, 4, true, "BORROW_NAM_SON_DODGE").success, true);
  assert.equal(state.phase, "PLAY");
  assert.equal(state.slashesUsedThisTurn, 1);
}

{
  const state = freshState();
  const weapon = card("BORROW_BAI_COC_WEAPON", "Vũ khí thử", CARD_SUBTYPES.WEAPON, CARD_CATEGORIES.EQUIPMENT);
  weapon.range = 2;
  state.players[1].equipments.push(weapon);
  const trap = card("BORROW_BAI_COC", "Bãi Cọc Bạch Đằng", CARD_SUBTYPES.BAI_COC_BACH_DANG, CARD_CATEGORIES.DELAYED_SCROLL);
  trap.attachedBySeat = 1;
  state.players[1].judgements.push(trap);
  state._deck = [card("BORROW_BAI_COC_RED", "Phán Xét", CARD_SUBTYPES.ATTACK_NORMAL)];
  put(state, 1, card("BORROW_BAI_COC_CARD", "Mượn Gươm Diệt Địch", CARD_SUBTYPES.MUON_GUOM_DIET_DICH, CARD_CATEGORIES.INSTANT_SCROLL));
  put(state, 2, card("BORROW_BAI_COC_SLASH", "Trảm Thường", CARD_SUBTYPES.ATTACK_NORMAL));
  assert.equal(handlePlayCard(state, 1, "BORROW_BAI_COC_CARD", 2, { targetSeat2: 4 }).success, true);
  assert.equal(handleRespondAction(state, 2, true, "BORROW_BAI_COC_SLASH").success, true);
  assert.equal(state.players[1].judgements.length, 0);
  assert.equal(state.phase, "AWAIT_SLASH_DEFENSE");
  assert.equal(state.waitingTargetSeat, 4);
}

{
  const state = freshState();
  put(state, 1, card("CHAIN", "Xích Tâm Tỏa", CARD_SUBTYPES.IRON_CHAIN, CARD_CATEGORIES.INSTANT_SCROLL));
  const result = handlePlayCard(state, 1, "CHAIN", 2, { targetSeats: [2, 4] });
  assert.equal(result.success, true);
  assert.equal(state.players.filter((player) => player.isChained).length, 2);
  assert.deepEqual(state.lastDelta.targetSeats, [2, 4]);
  assert.deepEqual(sanitizeGameStateForClient(state, 3).delta.targetSeats, [2, 4]);
}

{
  const state = freshState();
  put(state, 1, card("CHAIN_RECAST", "Xích Tâm Tỏa", CARD_SUBTYPES.IRON_CHAIN, CARD_CATEGORIES.INSTANT_SCROLL));
  state._deck = [card("CHAIN_RECAST_DRAW", "Lá rút sau đổi", CARD_SUBTYPES.ATTACK_NORMAL)];
  const noTargetResult = handlePlayCard(state, 1, "CHAIN_RECAST", 0, { targetSeats: [] });
  assert.match(noTargetResult.error, /chọn ít nhất 1 mục tiêu.*Đổi lá/);
  assert.equal(state.players[0].hand.some((candidate) => candidate.id === "CHAIN_RECAST"), true);
  assert.equal(handlePlayCard(state, 1, "CHAIN_RECAST", 0, { recast: true }).success, true);
  assert.equal(state.phase, "PLAY");
  assert.equal(state.players[0].hand.some((candidate) => candidate.id === "CHAIN_RECAST"), false);
  assert.equal(state.players[0].hand.some((candidate) => candidate.id === "CHAIN_RECAST_DRAW"), true);
  assert.equal(state.players.some((player) => player.isChained), false);
  assert.equal(state.lastAction.type, "RECAST_IRON_CHAIN");
}

{
  const state = freshState();
  const thuanThien = card("THUAN_AOE", "Kiếm Thuận Thiên", CARD_SUBTYPES.WEAPON, CARD_CATEGORIES.EQUIPMENT);
  thuanThien.range = 2;
  state.players[0].equipments.push(thuanThien);
  state.players[1].equipments.push(card("AO_BAO_AOE", "Áo Bào Hoàng Tộc", CARD_SUBTYPES.ARMOR, CARD_CATEGORIES.EQUIPMENT));
  state.players[1].aoBaoCharges = 2;
  put(state, 1, card("GIAC_TOI_THUAN", "Giặc Tới", CARD_SUBTYPES.BARBARIAN_INVASION, CARD_CATEGORIES.INSTANT_SCROLL));
  assert.equal(handlePlayCard(state, 1, "GIAC_TOI_THUAN").success, true);
  assert.equal(state.phase, "AWAIT_AOE");
  assert.equal(state.waitingTargetSeat, 2);
  assert.equal(handleRespondAction(state, 2, false, null).success, true);
  assert.equal(state.players[1].hp, 4);
  assert.equal(state.players[1].aoBaoCharges, 1);
}

{
  const state = freshState();
  put(state, 1, card("DIRECT_NULLIFY", "Diệu Kế Phá Mưu", CARD_SUBTYPES.FLAWLESS_DEFENSE, CARD_CATEGORIES.INSTANT_SCROLL));
  assert.match(handlePlayCard(state, 1, "DIRECT_NULLIFY", 2).error, /lá bài phản ứng/);
  assert.equal(state.players[0].hand.some((candidate) => candidate.id === "DIRECT_NULLIFY"), true);
}

{
  const state = freshState();
  state.players[0].equipments.push(card("DRUM", "Trống Đồng Đông Sơn", CARD_SUBTYPES.BRONZE_DRUM, CARD_CATEGORIES.EQUIPMENT));
  put(state, 2, card("DRUM_TARGET", "Bài mục tiêu", CARD_SUBTYPES.ATTACK_NORMAL));
  const result = handleUseSkill(state, 1, "Điểm Trống", 2);
  assert.equal(result.success, true);
  assert.equal(state.phase, "AWAIT_DRUM_CHOICE");
  assert.equal(handleRespondAction(state, 2, true, "DRUM_TARGET").success, true);
  assert.equal(state.players[1].hand.length, 0);
}

{
  const state = freshState();
  state.players[0].equipments.push(card("DRUM_REVEAL", "Trống Đồng Đông Sơn", CARD_SUBTYPES.BRONZE_DRUM, CARD_CATEGORIES.EQUIPMENT));
  put(state, 2, card("DRUM_SECRET", "Bài bí mật", CARD_SUBTYPES.ATTACK_NORMAL));
  assert.equal(handleUseSkill(state, 1, "Điểm Trống", 2).success, true);
  assert.equal(handleRespondAction(state, 2, false, null).success, true);
  assert.equal(sanitizeGameStateForClient(state, 1).drumReveal.cards[0].id, "DRUM_SECRET");
  assert.equal(sanitizeGameStateForClient(state, 2).drumReveal, null);
  assert.equal(handleEndTurn(state, 1).success, true);
  assert.equal(state.drumReveal, null);
}

assert.equal(createDeck80().length, 104);
assert.equal(createDeck150().length, 168);
for (const card of [...createDeck80(), ...createDeck150()]) {
  assert.notEqual(getCardRule(card).id, "unknown", `Thiếu rule registry cho ${card.id}`);
}

{
  const state = freshState();
  put(state, 1, card("DELAYED", "Cắt Đường Lương", CARD_SUBTYPES.SUPPLY_SHORTAGE, CARD_CATEGORIES.DELAYED_SCROLL));
  put(state, 2, card("NULLIFY", "Diệu Kế Phá Mưu", CARD_SUBTYPES.FLAWLESS_DEFENSE, CARD_CATEGORIES.INSTANT_SCROLL));
  const result = handlePlayCard(state, 1, "DELAYED", 2);
  assert.equal(result.success, true);
  assert.equal(state.players[1].judgements.length, 1);
  assert.equal(state.phase, "PLAY");
  assert.equal(handleEndTurn(state, 1).success, true);
  assert.equal(state.phase, "AWAIT_NULLIFY");
  assert.equal(state.waitingTargetSeat, 2);
  assert.equal(handleRespondAction(state, 2, false, null).success, true);
  assert.equal(state.phase, "AWAIT_JUDGEMENT");
  assert.ok(state.pendingJudgement);
}

{
  const state = freshState();
  put(state, 1, card("FLOOD", "Đại Hồng Thủy", CARD_SUBTYPES.DAI_HONG_THUY, CARD_CATEGORIES.DELAYED_SCROLL));
  assert.equal(handlePlayCard(state, 1, "FLOOD").success, true);
  assert.equal(state.players[0].judgements[0].name, "Đại Hồng Thủy");
  assert.equal(handleEndTurn(state, 1).success, true);
  assert.equal(handleEndTurn(state, 2).success, true);
  assert.equal(handleEndTurn(state, 3).success, true);
  state._deck = [card("FLOOD_JUDGE", "Phán Xét", CARD_SUBTYPES.ATTACK_NORMAL)];
  state._deck[0].suit = "Spade";
  state._deck[0].rank = 2;
  for (const player of state.players) player.hand = [];
  state.players[0].isChained = true;
  state.players[2].isChained = true;
  assert.equal(handleEndTurn(state, 4).success, true);
  assert.equal(state.phase, "AWAIT_JUDGEMENT");
  assert.equal(state.pendingJudgement.actionType, "DAI_HONG_THUY_HIT");
  state.timerStartAt = Date.now() - 4_000;
  assert.equal(tickGameState(state).changed, true);
  assert.deepEqual(state.players.map((player) => player.hp), [1, 4, 1, 4]);
  assert.equal(state.players.some((player) => player.isChained), false);
  assert.equal(state.actionHistory.some((action) => action.type === "DAI_HONG_THUY_HIT" && action.element === "WATER"), true);
  assert.equal(state.actionHistory.some((action) => action.type === "DAMAGE_TAKEN" && action.element === "WATER"), true);
}

{
  const state = freshState();
  put(state, 1, card("FLOOD_PASS", "Đại Hồng Thủy", CARD_SUBTYPES.DAI_HONG_THUY, CARD_CATEGORIES.DELAYED_SCROLL));
  assert.equal(handlePlayCard(state, 1, "FLOOD_PASS").success, true);
  assert.equal(handleEndTurn(state, 1).success, true);
  assert.equal(handleEndTurn(state, 2).success, true);
  assert.equal(handleEndTurn(state, 3).success, true);
  state._deck = [card("FLOOD_PASS_JUDGE", "Phán Xét", CARD_SUBTYPES.ATTACK_NORMAL)];
  state._deck[0].suit = "Heart";
  state._deck[0].rank = 10;
  for (const player of state.players) player.hand = [];
  assert.equal(handleEndTurn(state, 4).success, true);
  assert.equal(state.pendingJudgement.actionType, "DAI_HONG_THUY_PASSED");
  state.timerStartAt = Date.now() - 4_000;
  assert.equal(tickGameState(state).changed, true);
  assert.equal(state.players[0].judgements.some((card) => card.id === "FLOOD_PASS"), false);
  assert.equal(state.players[1].judgements.some((card) => card.id === "FLOOD_PASS"), true);
  assert.equal(state.actionHistory.some((action) => action.type === "DAI_HONG_THUY_PASSED"), true);
}

{
  const state = freshState();
  state.players[1].hp = 1;
  put(state, 1, card("SLASH", "Trảm Thường", CARD_SUBTYPES.ATTACK_NORMAL));
  const play = handlePlayCard(state, 1, "SLASH", 2);
  assert.equal(play.success, true);
  handleRespondAction(state, 2, false, null);
  assert.equal(state.phase, "AWAIT_NEAR_DEATH");
  assert.equal(state.waitingTargetSeat, 1);
  put(state, 1, card("PEACH", "Bánh Chưng", CARD_SUBTYPES.PEACH));
  assert.equal(handleRespondAction(state, 1, true, "PEACH").success, true);
  assert.equal(state.players[1].hp, 1);
}

{
  const state = freshState();
  state.players[1].heroId = "HERO_6"; // Vũ Thị Thục: Trinh Liệt
  state.players[1].hp = 1;
  put(state, 1, card("TRINH_SLASH", "Trảm Thường", CARD_SUBTYPES.ATTACK_NORMAL));
  put(state, 1, card("TRINH_STEAL_TARGET", "Lá để Trinh Liệt rút", CARD_SUBTYPES.DODGE));
  put(state, 1, card("TRINH_RESCUE", "Bánh Chưng", CARD_SUBTYPES.PEACH));

  assert.equal(handlePlayCard(state, 1, "TRINH_SLASH", 2).success, true);
  assert.equal(handleRespondAction(state, 2, false, null).success, true);
  assert.equal(state.phase, "AWAIT_NEAR_DEATH", "Phải xử lý Cận Tử trước Trinh Liệt");
  assert.notEqual(state.phase, "AWAIT_TARGET_CARD");

  assert.equal(handleRespondAction(state, 1, true, "TRINH_RESCUE").success, true);
  assert.equal(state.players[1].hp, 1);
  assert.equal(state.phase, "AWAIT_TARGET_CARD", "Sau khi cứu sống mới mở Trinh Liệt");
  assert.equal(state.waitingTargetSeat, 2);
}

{
  const state = freshState();
  state.players[1].hp = 1;
  put(state, 1, card("RESCUE_ONE", "Bánh Chưng", CARD_SUBTYPES.PEACH));
  put(state, 1, card("RESCUE_TWO", "Bánh Chưng", CARD_SUBTYPES.PEACH));
  put(state, 2, card("RESCUE_THREE", "Bánh Chưng", CARD_SUBTYPES.PEACH));
  applyDamageToPlayer(state, 2, 3, "test");
  assert.equal(state.players[1].hp, -2);
  assert.equal(hydrateGameState(structuredClone(state)).players[1].hp, -2);
  assert.equal(handleRespondAction(state, 1, true, "RESCUE_ONE").success, true);
  assert.equal(state.players[1].hp, -1);
  assert.equal(state.waitingTargetSeat, 1);
  assert.equal(handleRespondAction(state, 1, true, "RESCUE_TWO").success, true);
  assert.equal(state.players[1].hp, 0);
  assert.equal(state.waitingTargetSeat, 1);
  assert.equal(handleRespondAction(state, 1, false, null).success, true);
  assert.equal(state.waitingTargetSeat, 2);
  assert.equal(handleRespondAction(state, 2, true, "RESCUE_THREE").success, true);
  assert.equal(state.players[1].hp, 1);
  assert.equal(state.phase, "PLAY");
}

{
  const state = freshState();
  state.players[1].hp = 1;
  state.players[1].isChained = true;
  state.players[3].isChained = true;
  put(state, 2, card("CHAIN_PEACH", "Bánh Chưng", CARD_SUBTYPES.PEACH));
  const hit = applyDamageToPlayer(state, 2, 1, "test water", "WATER");
  assert.equal(hit.enteredNearDeath, true);
  assert.deepEqual(state.pendingChainSpread.targetSeats, [4]);
  assert.equal(state.waitingTargetSeat, 1);
  handleRespondAction(state, 1, false, null);
  handleRespondAction(state, 2, true, "CHAIN_PEACH");
  assert.equal(state.players[3].hp, 3);
  assert.equal(state.players[3].isChained, false);
  assert.equal(state.pendingChainSpread, null);
}

{
  const state = freshState();
  state.players[1].isChained = true;
  state.players[3].isChained = true;
  const hit = applyDamageToPlayer(state, 2, 3, "Đại Hồng Thủy", "WATER");
  assert.equal(hit.finalDamage, 3);
  assert.equal(state.players[1].hp, 1);
  assert.equal(state.players[3].hp, 1);
  assert.equal(state.players[1].isChained, false);
  assert.equal(state.players[3].isChained, false);
}

{
  const state = freshState();
  for (const player of state.players) player.isChained = true;
  applyDamageToPlayer(state, 2, 1, "test elemental", "WATER");
  assert.deepEqual(state.pendingChainSpread, null);
  assert.deepEqual(state.players.map((player) => player.hp), [3, 3, 3, 3]);
  assert.equal(state.players.some((player) => player.isChained), false);
}

for (const [subType, name] of [
  [CARD_SUBTYPES.ATTACK_FIRE, "Trảm - Hỏa"],
  [CARD_SUBTYPES.ATTACK_WATER, "Trảm - Thủy"],
]) {
  const state = freshState();
  state.players[1].isChained = true;
  state.players[3].isChained = true;
  put(state, 1, card(`ELEMENT_${subType}`, name, subType));
  assert.equal(handlePlayCard(state, 1, `ELEMENT_${subType}`, 2).success, true);
  assert.equal(handleRespondAction(state, 2, false, null).success, true);
  assert.equal(state.players[1].hp, 3);
  assert.equal(state.players[3].hp, 3);
  assert.equal(state.players.some((player) => player.isChained), false);
}

{
  const state = freshState();
  state.players[0].hp = 1;
  state.players[2].hp = 1;
  applyDamageToPlayer(state, 1, 1, "test");
  while (state.phase === "AWAIT_NEAR_DEATH") {
    handleRespondAction(state, state.waitingTargetSeat, false, null);
  }
  applyDamageToPlayer(state, 3, 1, "test");
  while (state.phase === "AWAIT_NEAR_DEATH") {
    handleRespondAction(state, state.waitingTargetSeat, false, null);
  }
  assert.equal(state.status, "FINISHED");
  assert.match(state.lastAction.description, /Đội 2/);
}

{
  const state = freshState();
  state.players[0].hp = 0;
  state.players[0].isAlive = false;
  state.turnSeat = 2;
  state._deck = [
    card("HARVEST_1", "Bài Kho 1", CARD_SUBTYPES.ATTACK_NORMAL),
    card("HARVEST_2", "Bài Kho 2", CARD_SUBTYPES.ATTACK_NORMAL),
    card("HARVEST_3", "Bài Kho 3", CARD_SUBTYPES.ATTACK_NORMAL)
  ];
  put(state, 2, card("HARVEST", "Mở Kho Cứu Tế", CARD_SUBTYPES.HARVEST, CARD_CATEGORIES.INSTANT_SCROLL));
  assert.equal(handlePlayCard(state, 2, "HARVEST").success, true);
  assert.equal(state.phase, "AWAIT_HARVEST");
  assert.equal(state.waitingTargetSeat, 2);
  assert.deepEqual(state.harvestPool.map((c) => c.id), ["HARVEST_3", "HARVEST_2", "HARVEST_1"]);
  assert.deepEqual(state.harvestDisplayPool.map((c) => c.id), ["HARVEST_3", "HARVEST_2", "HARVEST_1"]);
  assert.equal(handleRespondAction(state, 2, true, "HARVEST_2").success, true);
  assert.equal(state.players[1].hand.at(-1).id, "HARVEST_2");
  assert.deepEqual(state.harvestDisplayPool.map((c) => c.id), ["HARVEST_3", "HARVEST_2", "HARVEST_1"]);
  assert.deepEqual(state.harvestPickedCardIds, ["HARVEST_2"]);
  const harvestView = sanitizeGameStateForClient(state, 2);
  assert.deepEqual(harvestView.harvestDisplayPool.map((c) => c.id), ["HARVEST_3", "HARVEST_2", "HARVEST_1"]);
  assert.deepEqual(harvestView.harvestPickedCardIds, ["HARVEST_2"]);
  assert.equal(state.waitingTargetSeat, 3);
  assert.equal(handleRespondAction(state, 3, true, "HARVEST_1").success, true);
  assert.equal(state.waitingTargetSeat, 4);
  assert.equal(handleRespondAction(state, 4, true, "HARVEST_3").success, true);
  assert.equal(state.phase, "PLAY");
  assert.equal(state.harvestPool.length, 0);
}

{
  const state = freshState();
  state.players[0].hp = 0;
  state.players[0].isAlive = false;
  state.turnSeat = 2;
  state._deck = [
    card("HARVEST_NULL_1", "Bài Kho 1", CARD_SUBTYPES.ATTACK_NORMAL),
    card("HARVEST_NULL_2", "Bài Kho 2", CARD_SUBTYPES.ATTACK_NORMAL),
    card("HARVEST_NULL_3", "Bài Kho 3", CARD_SUBTYPES.ATTACK_NORMAL)
  ];
  put(state, 2, card("HARVEST_NULL", "Mở Kho Cứu Tế", CARD_SUBTYPES.HARVEST, CARD_CATEGORIES.INSTANT_SCROLL));
  put(state, 4, card("NULLIFY_HARVEST", "Diệu Kế Phá Mưu", CARD_SUBTYPES.FLAWLESS_DEFENSE, CARD_CATEGORIES.INSTANT_SCROLL));
  assert.equal(handlePlayCard(state, 2, "HARVEST_NULL").success, true);
  assert.equal(state.phase, "AWAIT_NULLIFY");
  assert.equal(state.waitingTargetSeat, 4);
  assert.equal(sanitizeGameStateForClient(state, 1).waitingTargetSeat, 0);
  assert.equal(sanitizeGameStateForClient(state, 4).waitingTargetSeat, 4);
  assert.equal(sanitizeGameStateForClient(state, 1).nullifyChain.querySeats, undefined);
  assert.match(sanitizeGameStateForClient(state, 1).lastAction.description, /một người chơi/i);
  assert.equal(handleRespondAction(state, 4, true, "NULLIFY_HARVEST").success, true);
  assert.equal(state.phase, "AWAIT_HARVEST");
  assert.equal(state.waitingTargetSeat, 3);
  assert.equal(state.players[1].hand.some((c) => c.id.startsWith("HARVEST_NULL_")), false);
}

{
  const state = freshState();
  state._deck = [
    card("AOE_1", "Bài AOE 1", CARD_SUBTYPES.ATTACK_NORMAL),
    card("AOE_2", "Bài AOE 2", CARD_SUBTYPES.ATTACK_NORMAL),
    card("AOE_3", "Bài AOE 3", CARD_SUBTYPES.ATTACK_NORMAL),
    card("AOE_NULL_JUDGE", "Phán Xét", CARD_SUBTYPES.ATTACK_NORMAL)
  ];
  put(state, 1, card("AOE", "Mưa Tên Liên Châu", CARD_SUBTYPES.ARROW_RAIN, CARD_CATEGORIES.INSTANT_SCROLL));
  put(state, 4, card("NULLIFY_AOE", "Diệu Kế Phá Mưu", CARD_SUBTYPES.FLAWLESS_DEFENSE, CARD_CATEGORIES.INSTANT_SCROLL));
  assert.equal(handlePlayCard(state, 1, "AOE").success, true);
  assert.equal(state.phase, "AWAIT_NULLIFY");
  assert.equal(state.waitingTargetSeat, 4);
  assert.equal(handleRespondAction(state, 4, true, "NULLIFY_AOE").success, true);
  assert.equal(state.phase, "AWAIT_AOE");
  assert.equal(state.waitingTargetSeat, 3);
  assert.equal(state.players[1].hp, 4);
  assert.equal(handleRespondAction(state, 3, false, null).success, true);
  assert.equal(state.players[2].hp, 3);
  assert.equal(handleRespondAction(state, 4, false, null).success, true);
  assert.equal(state.players[3].hp, 3);
  assert.equal(state.phase, "PLAY");
  assert.equal(state.players[0].hp, 4);
}

{
  // Thương Ngâu Lãng Bạc: Trảm trúng phải cho người đánh chọn hủy bài tay hoặc trang bị.
  const state = freshState();
  state.players[0].equipments.push(card("THUONG_NGAU", "Thương Ngâu Lãng Bạc", CARD_SUBTYPES.WEAPON, CARD_CATEGORIES.EQUIPMENT));
  put(state, 2, card("THUONG_TARGET_HAND", "Bài mục tiêu", CARD_SUBTYPES.ATTACK_NORMAL));
  state.phase = "AWAIT_SLASH_DEFENSE";
  state.waitingTargetSeat = 2;
  state.activeCard = { casterSeat: 1, cardName: "Trảm", damage: 1 };

  assert.equal(handleRespondAction(state, 2, false, null).success, true);
  assert.equal(state.phase, "AWAIT_TARGET_CARD");
  assert.equal(state.waitingTargetSeat, 1);
  assert.equal(state.targetCardSelection.effectType, "THUONG_NGAU");
  assert.equal(state.targetCardSelection.options.some((option) => option.token === "HAND:0"), true);
}

{
  // Bỏ từng đợt vẫn phải giữ nguyên lượt cho tới khi số bài trên tay không vượt máu.
  const state = freshState();
  state.players[0].hp = 2;
  for (const id of ["DISCARD_1", "DISCARD_2", "DISCARD_3", "DISCARD_4", "DISCARD_5"]) {
    put(state, 1, card(id, "Bài bỏ", CARD_SUBTYPES.ATTACK_NORMAL));
  }
  assert.equal(handleEndTurn(state, 1).success, true);
  assert.equal(state.phase, "DISCARD");
  assert.equal(handleDiscardCards(state, 1, ["DISCARD_1"]).success, true);
  assert.equal(state.phase, "DISCARD");
  assert.equal(state.turnSeat, 1);
  assert.match(handleEndTurn(state, 1).error, /bỏ đủ bài thừa/);
  assert.equal(state.phase, "DISCARD");
  assert.equal(handleDiscardCards(state, 1, ["DISCARD_2", "DISCARD_3"]).success, true);
  assert.equal(state.phase, "PLAY");
  assert.equal(state.turnSeat, 2);
}

{
  // Test Trống Đồng Đông Sơn: Điểm Trống
  const state = freshState();
  state.players[0].equipments.push(card("BRONZE_DRUM_1", "Trống Đồng Đông Sơn", CARD_SUBTYPES.BRONZE_DRUM, CARD_CATEGORIES.EQUIPMENT));
  put(state, 2, card("TARGET_HAND_1", "Trảm Thường", CARD_SUBTYPES.ATTACK_NORMAL));
  put(state, 2, card("TARGET_HAND_2", "Đỡ", CARD_SUBTYPES.DODGE));

  // 1. Dùng Điểm Trống lên Ghế 2
  const useRes = handleUseSkill(state, 1, "Điểm Trống", 2);
  assert.equal(useRes.success, true);
  assert.equal(state.phase, "AWAIT_DRUM_CHOICE");
  assert.equal(state.waitingTargetSeat, 2);
  assert.equal(state.drumSelection.ownerSeat, 1);
  assert.equal(state.drumSelection.targetSeat, 2);

  // 2. Ghế 2 chọn BỎ 1 LÁ (accepted = true, cardId = TARGET_HAND_1)
  const discardRes = handleRespondAction(state, 2, true, "TARGET_HAND_1");
  assert.equal(discardRes.success, true);
  assert.equal(state.phase, "PLAY");
  assert.equal(state.players[1].hand.length, 1);
  assert.equal(state.players[1].hand[0].id, "TARGET_HAND_2");

  // 3. Dùng Điểm Trống lần 2 và Ghế 2 chọn LỘ BÀI (accepted = false)
  const useRes2 = handleUseSkill(state, 1, "Điểm Trống", 2);
  assert.equal(useRes2.success, true);
  assert.equal(state.phase, "AWAIT_DRUM_CHOICE");
  const revealRes = handleRespondAction(state, 2, false, null);
  assert.equal(revealRes.success, true);
  assert.equal(state.phase, "PLAY");
  assert.equal(state.drumReveal.viewerSeat, 1);
  assert.equal(state.drumReveal.targetSeat, 2);
  assert.equal(state.drumReveal.cards.length, 1);
  assert.equal(state.drumReveal.cards[0].id, "TARGET_HAND_2");

  // Client sanitizer: chỉ viewerSeat 1 mới thấy cards trong drumReveal, viewerSeat 3 thấy null
  assert.equal(sanitizeGameStateForClient(state, 1).drumReveal.cards.length, 1);
  assert.equal(sanitizeGameStateForClient(state, 3).drumReveal, null);
}

{
  // Test Bãi Cọc Bạch Đằng: Phán xét Đỏ (An toàn) vs Đen (Sập bẫy)
  const state = freshState();
  const trapCard = card("TRAP_1", "Bãi Cọc Bạch Đằng", CARD_SUBTYPES.BAI_COC_BACH_DANG, CARD_CATEGORIES.DELAYED_SCROLL);
  state.players[0].judgements.push(trapCard);
  put(state, 1, card("SLASH_1", "Trảm Thường", CARD_SUBTYPES.ATTACK_NORMAL));

  // Đặt bài phán xét trong deck là ĐỎ (Heart)
  state._deck = [{ id: "JUDGE_RED", name: "Bài Đỏ", suit: "Heart", rank: 8, subType: 0 }];
  const playRes = handlePlayCard(state, 1, "SLASH_1", 2);
  assert.equal(playRes.success, true);
  assert.equal(state.players[0].judgements.length, 0);
  assert.equal(playRes.state.lastDelta.baiCocJudgeCard?.suit, "Heart");
  assert.equal(playRes.state.lastDelta.type, "PLAY_SLASH");

  // Thử trường hợp ĐEN (Spade)
  const stateBlack = freshState();
  stateBlack.players[0].judgements.push(trapCard);
  put(stateBlack, 1, card("SLASH_2", "Trảm Thường", CARD_SUBTYPES.ATTACK_NORMAL));
  stateBlack._deck = [{ id: "JUDGE_BLACK", name: "Bài Đen", suit: "Spade", rank: 5, subType: 0 }];
  const playResBlack = handlePlayCard(stateBlack, 1, "SLASH_2", 2);
  assert.equal(playResBlack.success, true);
  assert.equal(stateBlack.players[0].hp, 3);
  assert.equal(stateBlack.actionHistory.some((a) => a.type === "BAI_COC_BACH_DANG_TRIGGERED"), true);
  assert.equal(stateBlack.lastDelta.type, "BAI_COC_BACH_DANG_TRIGGERED");
  assert.equal(stateBlack.lastDelta.judgeCard?.suit, "Spade");
  assert.equal(stateBlack.lastDelta.playerDeltas[0].hp, 3);

  // Thử trường hợp Chiến Mã: ĐỎ trang bị thành công và gỡ Bãi Cọc
  const stateHorseRed = freshState();
  stateHorseRed.players[0].judgements.push(trapCard);
  put(stateHorseRed, 1, card("HORSE_RED", "Voi Chiến Đại Việt", CARD_SUBTYPES.DEFENSIVE_HORSE, CARD_CATEGORIES.EQUIPMENT));
  stateHorseRed._deck = [{ id: "JUDGE_HORSE_RED", name: "Bài Đỏ", suit: "Diamond", rank: 7, subType: 0 }];
  const playHorseRed = handlePlayCard(stateHorseRed, 1, "HORSE_RED", 1);
  assert.equal(playHorseRed.success, true);
  assert.equal(stateHorseRed.players[0].judgements.length, 0);
  assert.equal(stateHorseRed.players[0].equipments.some((e) => e.subType === CARD_SUBTYPES.DEFENSIVE_HORSE), true);
  assert.equal(stateHorseRed.lastDelta.type, "EQUIP");
  assert.equal(stateHorseRed.lastDelta.baiCocJudgeCard?.suit, "Diamond");

  // Thử trường hợp Chiến Mã: ĐEN bị hủy hành động và chịu 1 sát thương
  const stateHorseBlack = freshState();
  stateHorseBlack.players[0].judgements.push(trapCard);
  put(stateHorseBlack, 1, card("HORSE_BLACK", "Ngựa Trắng Thuần Nông", CARD_SUBTYPES.OFFENSIVE_HORSE, CARD_CATEGORIES.EQUIPMENT));
  stateHorseBlack._deck = [{ id: "JUDGE_HORSE_BLACK", name: "Bài Đen", suit: "Club", rank: 4, subType: 0 }];
  const playHorseBlack = handlePlayCard(stateHorseBlack, 1, "HORSE_BLACK", 1);
  assert.equal(playHorseBlack.success, true);
  assert.equal(stateHorseBlack.players[0].hp, 3);
  assert.equal(stateHorseBlack.players[0].equipments.some((e) => e.subType === CARD_SUBTYPES.OFFENSIVE_HORSE), false);
  assert.equal(stateHorseBlack.lastDelta.type, "BAI_COC_BACH_DANG_TRIGGERED");
  assert.equal(stateHorseBlack.lastDelta.judgeCard?.suit, "Club");
}

{
  // Test Khiên Mây Bện: Phán xét Đỏ (KHIEN_MAY_SUCCESS) vs Đen (KHIEN_MAY_FAILED)
  const state = freshState();
  const kmCard = card("KM_1", "Khiên Mây Bện", CARD_SUBTYPES.ARMOR, CARD_CATEGORIES.EQUIPMENT);
  state.players[1].equipments.push(kmCard);
  state.phase = "AWAIT_SLASH_DEFENSE";
  state.waitingTargetSeat = 2;
  state.activeCard = { casterSeat: 1, cardName: "Trảm", suit: "Spade", rank: 7 };
  state._deck.push({ id: "JUDGE_RED", name: "Bài Đỏ", suit: "Heart", rank: 8 });
  const redRes = handleRespondAction(state, 2, true, "KHIEN_MAY");
  assert.equal(redRes.success, true);
  assert.equal(state.lastAction.type, "KHIEN_MAY_SUCCESS");
  assert.equal(state.lastAction.judgeCard?.suit, "Heart");
  assert.equal(state.lastDelta.type, "KHIEN_MAY_SUCCESS");
  assert.equal(state.lastDelta.judgeCard?.suit, "Heart");
  assert.equal(state.phase, "PLAY");

  // Thử trường hợp ĐEN (Spade)
  const stateBlack = freshState();
  stateBlack.players[1].equipments.push(kmCard);
  stateBlack.phase = "AWAIT_SLASH_DEFENSE";
  stateBlack.waitingTargetSeat = 2;
  stateBlack.activeCard = { casterSeat: 1, cardName: "Trảm", suit: "Spade", rank: 7 };
  stateBlack._deck.push({ id: "JUDGE_BLACK", name: "Bài Đen", suit: "Spade", rank: 9 });
  const blackRes = handleRespondAction(stateBlack, 2, true, "KHIEN_MAY");
  assert.equal(blackRes.success, true);
  assert.equal(stateBlack.lastAction.type, "KHIEN_MAY_FAILED");
  assert.equal(stateBlack.lastAction.judgeCard?.suit, "Spade");
  assert.equal(stateBlack.lastDelta.type, "KHIEN_MAY_FAILED");
  assert.equal(stateBlack.lastDelta.judgeCard?.suit, "Spade");
  assert.equal(stateBlack.phase, "AWAIT_SLASH_DEFENSE");
  assert.equal(stateBlack.activeCard.khienMayFailedSeats?.includes(2), true);
}

{
  const state = freshState();
  state.players[1].heroId = 3; // Thi Sach
  const receiver = state.players[2];
  const handBefore = receiver.hand.length;
  state.turnTimer = 7;
  applyDamageToPlayer(state, 2, 1, "Kiểm thử");
  assert.equal(state.phase, "AWAIT_UAT_KHI");
  assert.equal(state.waitingTargetSeat, 2);
  assert.equal(state.waitingTimer, 40);
  assert.match(handleEndTurn(state, 1).error, /đang trong pha phản ứng/);
  assert.equal(handleUseSkill(state, 2, "Uất Khí", 3).success, true);
  assert.equal(receiver.hand.length, handBefore + 1);
  assert.equal(state.phase, "PLAY");
  assert.equal(state.waitingTargetSeat, 0);
  assert.equal(state.turnTimer, 40);

  state.turnTimer = 7;
  applyDamageToPlayer(state, 2, 1, "Kiểm thử timeout");
  state.timerStartAt = Date.now() - 41000;
  tickGameState(state);
  assert.equal(state.phase, "PLAY");
  assert.equal(state.uatKhiQueue.length, 0);
  assert.equal(state.turnTimer, 40);
}

{
  const state = freshState();
  state.players[0].heroId = 5; // Thánh Thiên
  state.players[0].hp = 2;
  put(state, 1, card("DUNG_NU_SLASH", "Trảm Thường", CARD_SUBTYPES.ATTACK_NORMAL));
  put(state, 2, card("DUNG_NU_DODGE_1", "Đỡ", CARD_SUBTYPES.DODGE));
  put(state, 2, card("DUNG_NU_DODGE_2", "Đỡ", CARD_SUBTYPES.DODGE));
  assert.equal(handlePlayCard(state, 1, "DUNG_NU_SLASH", 2).success, true);
  assert.equal(state.activeCard.requiredDodgeCount, 2);
  assert.equal(handleRespondAction(state, 2, true, "DUNG_NU_DODGE_1").success, true);
  assert.equal(state.phase, "AWAIT_SLASH_DEFENSE");
  assert.equal(handleRespondAction(state, 2, true, "DUNG_NU_DODGE_2").success, true);
  assert.equal(state.players[1].hp, 4);
}

{
  const state = freshState();
  state.players[1].heroId = 5; // Thánh Thiên
  put(state, 1, card("THU_MUC_SLASH", "Trảm Thường", CARD_SUBTYPES.ATTACK_NORMAL));
  put(state, 2, { ...card("THU_MUC_RED", "Bài Đỏ", CARD_SUBTYPES.PEACH), suit: "Heart" });
  assert.equal(handlePlayCard(state, 1, "THU_MUC_SLASH", 2).success, true);
  assert.equal(handleRespondAction(state, 2, false, null).success, true);
  assert.equal(state.phase, "AWAIT_THU_MUC");
  assert.equal(handleRespondAction(state, 2, true, "THU_MUC_RED").success, true);
  assert.equal(state.players[1].hp, 4);
}

{
  const state = freshState();
  state.players[1].heroId = 5; // Thánh Thiên
  put(state, 1, card("THU_MUC_SLASH_WHITE", "Trảm Thường", CARD_SUBTYPES.ATTACK_NORMAL));
  put(state, 2, { ...card("THU_MUC_WHITE", "Bài Trắng", CARD_SUBTYPES.DODGE), suit: "Diamond" });
  assert.equal(handlePlayCard(state, 1, "THU_MUC_SLASH_WHITE", 2).success, true);
  assert.equal(handleRespondAction(state, 2, false, null).success, true);
  assert.equal(state.phase, "AWAIT_THU_MUC");
  assert.equal(handleRespondAction(state, 2, true, "THU_MUC_WHITE").success, true);
  assert.equal(state.players[1].hp, 4);
}

{
  const state = freshState();
  state.players[1].heroId = 5; // Thánh Thiên
  put(state, 1, card("THU_MUC_SLASH_BLACK", "Trảm Thường", CARD_SUBTYPES.ATTACK_NORMAL));
  put(state, 2, { ...card("THU_MUC_BLACK", "Bài Đen", CARD_SUBTYPES.SLASH), suit: "Spade" });
  assert.equal(handlePlayCard(state, 1, "THU_MUC_SLASH_BLACK", 2).success, true);
  assert.equal(handleRespondAction(state, 2, false, null).success, true);
  // Black card does not trigger AWAIT_THU_MUC
  assert.notEqual(state.phase, "AWAIT_THU_MUC");
}

{
  const state = freshState();
  state.players[0].heroId = 6; // Vũ Thị Thục
  put(state, 1, card("BAT_NA_BASIC", "Bánh Chưng", CARD_SUBTYPES.PEACH));
  assert.equal(handleUseSkill(state, 1, "Bát Nạ", 2, "BAT_NA_BASIC").success, true);
  assert.equal(state.activeCard.countsTowardTurnSlashLimit, false);
  assert.equal(state.slashesUsedThisTurn, 0);
}

{
  const state = freshState();
  state.players[1].heroId = 6; // Vũ Thị Thục
  state.players[0].equipments.push(card("TRINH_LIET_EQUIP", "Kiếm", CARD_SUBTYPES.WEAPON, CARD_CATEGORIES.EQUIPMENT));
  put(state, 1, card("TRINH_LIET_SLASH", "Trảm Thường", CARD_SUBTYPES.ATTACK_NORMAL));
  assert.equal(handlePlayCard(state, 1, "TRINH_LIET_SLASH", 2).success, true);
  assert.equal(handleRespondAction(state, 2, false, null).success, true);
  assert.equal(state.phase, "AWAIT_TARGET_CARD");
  assert.equal(handleRespondAction(state, 2, true, "EQUIPMENT:TRINH_LIET_EQUIP").success, true);
  assert.equal(state.players[1].hand.some((c) => c.id === "TRINH_LIET_EQUIP"), true);
}

{
  const state = freshState();
  state.players[2].heroId = 8; // Triệu Quốc Đạt
  state.activeCard = { casterSeat: 1 };
  const sourceCards = state.players[0].hand.length;
  const ownerCards = state.players[2].hand.length;
  applyDamageToPlayer(state, 2, 1, "Trảm", "NORMAL", true);
  assert.equal(state.phase, "AWAIT_KHOI_BINH");
  assert.equal(handleRespondAction(state, 3, true, null).success, true);
  assert.equal(state.players[0].hand.length, sourceCards + 1);
  assert.equal(state.players[2].hand.length, ownerCards + 1);
}

{
  const state = freshState();
  state.players[1].heroId = 8; // Triệu Quốc Đạt
  put(state, 2, card("HUYNH_TRUONG_GIVE", "Bài đưa", CARD_SUBTYPES.PEACH));
  applyDamageToPlayer(state, 2, 1, "Kiểm thử");
  assert.equal(state.phase, "AWAIT_HUYNH_TRUONG");
  assert.equal(handleUseSkill(state, 2, "Huynh Trưởng", 3, "HUYNH_TRUONG_GIVE").success, true);
  assert.equal(state.players[2].hand.some((c) => c.id === "HUYNH_TRUONG_GIVE"), true);
}

{
  // 1. Cao Lỗ (#1) - Chế Nỏ: converts any black card (Spade or Đen) into Nỏ Thần Kim Quy
  const state = freshState();
  state.players[0].heroId = 1;
  state.players[0].hand = [
    { id: "CN_SPADE", name: "Đỡ", suit: "Spade", rank: 5, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.DODGE, desc: "test" },
    { id: "CN_DEN", name: "Bánh Chưng", suit: "đen", rank: 6, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.PEACH, desc: "test" },
    { id: "CN_RED", name: "Trảm - Hỏa", suit: "Heart", rank: 7, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.ATTACK_FIRE, desc: "test" }
  ];
  handleToggleSkill(state, 1, "Chế Nỏ");
  assert.equal(state.players[0].hand[0].name, "Nỏ Thần Kim Quy");
  assert.equal(state.players[0].hand[0].subType, CARD_SUBTYPES.WEAPON);
  assert.equal(state.players[0].hand[1].name, "Nỏ Thần Kim Quy");
  assert.equal(state.players[0].hand[1].subType, CARD_SUBTYPES.WEAPON);
  assert.equal(state.players[0].hand[2].name, "Trảm - Hỏa");
}

{
  // 2. Phạm Tu (#13) - Trấn Nam: Black or Yellow Normal Slash bypasses Giáp Đồng Sơn Vi
  const state = freshState();
  state.players[0].heroId = 13; // Phạm Tu
  state.players[1].equipments.push({
    id: "ARMOR_DONG",
    name: "Giáp Đồng Sơn Vi",
    subType: CARD_SUBTYPES.ARMOR,
    category: CARD_CATEGORIES.EQUIPMENT,
    desc: "test"
  });
  // Yellow normal slash bypasses Giáp Đồng Sơn Vi
  put(state, 1, {
    id: "YELLOW_SLASH",
    name: "Trảm Thường",
    suit: "Club",
    rank: 7,
    category: CARD_CATEGORIES.BASIC,
    subType: CARD_SUBTYPES.ATTACK_NORMAL
  });
  const resYellow = handlePlayCard(state, 1, "YELLOW_SLASH", 2);
  assert.equal(resYellow.success, true);
  assert.equal(state.phase, "AWAIT_SLASH_DEFENSE");
  assert.equal(state.waitingTargetSeat, 2);

  // Red normal slash does NOT bypass Giáp Đồng Sơn Vi
  const stateRed = freshState();
  stateRed.players[0].heroId = 13;
  stateRed.players[1].equipments.push({
    id: "ARMOR_DONG_2",
    name: "Giáp Đồng Sơn Vi",
    subType: CARD_SUBTYPES.ARMOR,
    category: CARD_CATEGORIES.EQUIPMENT,
    desc: "test"
  });
  put(stateRed, 1, {
    id: "RED_SLASH",
    name: "Trảm Thường",
    suit: "Heart",
    rank: 7,
    category: CARD_CATEGORIES.BASIC,
    subType: CARD_SUBTYPES.ATTACK_NORMAL
  });
  const resRed = handlePlayCard(stateRed, 1, "RED_SLASH", 2);
  assert.equal(resRed.success, true);
  assert.equal(stateRed.phase, "PLAY");
}

{
  // 3. Khúc Thừa Dụ (#18) - Khoan Giản: Hand limit +(X+1) and draw X+1 cards (X = ceil(equipments / 2))
  const state = freshState();
  state.players[0].heroId = 18;
  state.players[0].hp = 3;
  // 0 equipments: X = 0 -> limit += 1 -> 3 + 1 = 4
  assert.equal(getHandLimit(state.players[0]), 4);

  // 1 equipment: X = 1 -> limit += 2 -> 3 + 2 = 5
  state.players[0].equipments = [{ id: "EQ1", name: "Vũ khí", subType: CARD_SUBTYPES.WEAPON }];
  assert.equal(getHandLimit(state.players[0]), 5);

  // 3 equipments: X = 2 -> limit += 3 -> 3 + 3 = 6
  state.players[0].equipments = [
    { id: "EQ1", name: "Vũ khí", subType: CARD_SUBTYPES.WEAPON },
    { id: "EQ2", name: "Giáp", subType: CARD_SUBTYPES.ARMOR },
    { id: "EQ3", name: "Ngựa", subType: CARD_SUBTYPES.OFFENSIVE_HORSE }
  ];
  assert.equal(getHandLimit(state.players[0]), 6);

  // Draw X+1 cards on discard/endTurn
  state.players[0].hand = [card("H1", "Bài", CARD_SUBTYPES.DODGE)];
  handleEndTurn(state, 1);
  assert.equal(state.players[0].hand.length, 4); // 1 + 3 = 4
}

{
  // 4. Mai Thúc Loan (#17) - Vạn An: max 2 uses/turn, any 2 cards, 1st use draws 1
  const state = freshState();
  state.players[0].heroId = 17;
  state.players[0].hand = [
    { id: "VA_1", name: "Lá 1", suit: "Heart", rank: 1, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.PEACH },
    { id: "VA_2", name: "Lá 2", suit: "Spade", rank: 2, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.DODGE },
    { id: "VA_3", name: "Lá 3", suit: "Club", rank: 3, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.ATTACK_NORMAL },
    { id: "VA_4", name: "Lá 4", suit: "Diamond", rank: 4, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.PEACH },
  ];
  // 1st use: Red + Spade (different colors) on seat 2
  const use1 = handleUseSkill(state, 1, "Vạn An", 2, "VA_1|VA_2");
  assert.equal(use1.success, true);
  assert.equal(state.players[0].hand.length, 3); // 4 - 2 + 1 = 3
  assert.equal(state.players[1].judgements.some((j) => j.subType === CARD_SUBTYPES.BAI_COC_BACH_DANG), true);

  // 2nd use: on seat 3 with remaining cards
  const remainingIds = `${state.players[0].hand[0].id}|${state.players[0].hand[1].id}`;
  const use2 = handleUseSkill(state, 1, "Vạn An", 3, remainingIds);
  assert.equal(use2.success, true);
  assert.equal(state.players[0].hand.length, 1); // 3 - 2 = 1
  assert.equal(state.players[2].judgements.some((j) => j.subType === CARD_SUBTYPES.BAI_COC_BACH_DANG), true);

  // 3rd use attempt should fail
  put(state, 1, card("EXTRA1", "Extra 1", CARD_SUBTYPES.DODGE));
  put(state, 1, card("EXTRA2", "Extra 2", CARD_SUBTYPES.DODGE));
  const use3 = handleUseSkill(state, 1, "Vạn An", 4, `${state.players[0].hand[0].id}|${state.players[0].hand[1].id}`);
  assert.equal(use3.error, "Vạn An chỉ dùng tối đa 2 lần mỗi lượt");
}

{
  // 5. Dương Đình Nghệ (#20) - Nghĩa Tử & Dưỡng Binh
  const state = freshState();
  state.players[0].heroId = 20; // Dương Đình Nghệ
  state.players[0].hp = 4;
  put(state, 1, card("NGHIA_TU_HAND", "Lá hy sinh", CARD_SUBTYPES.PEACH));
  // Player 2 takes damage
  applyDamageToPlayer(state, 2, 1, "Trảm");
  assert.equal(state.phase, "AWAIT_NGHIA_TU");
  // Player 1 uses Nghĩa Tử
  const res = handleRespondAction(state, 1, true, "NGHIA_TU_HAND");
  assert.equal(res.success, true);
  // Player 1 took 1 damage (4 -> 3)
  assert.equal(state.players[0].hp, 3);
  // Player 1 drew 2 cards from Dưỡng Binh
  assert.equal(state.players[0].hand.length, 2);
}

console.log("2v2 regression tests: PASS");
