import assert from "node:assert/strict";
import {
  applyDamageToPlayer,
  handleDiscardCards,
  handleEndTurn,
  handleRespondAction,
  handleUseSkill,
  initGame,
  sanitizeGameStateForClient,
  tickGameState,
} from "../deploy_deno/functions/game-engine/src/gameEngine.js";
import { CARD_CATEGORIES, CARD_SUBTYPES } from "../deploy_deno/functions/game-engine/src/deck.js";
import { getHeroById } from "../deploy_deno/functions/game-engine/src/heroes.js";

const card = (id, suit = "Heart") => ({
  id,
  name: `Bài ${id}`,
  suit,
  rank: 5,
  category: CARD_CATEGORIES.BASIC,
  subType: CARD_SUBTYPES.ATTACK_NORMAL,
});

function game(heroIds) {
  const state = initGame("heroes-17-20-test", heroIds.map((heroId, index) => ({
    seat: index + 1,
    heroId,
    generalName: `P${index + 1}`,
  })));
  for (const player of state.players) {
    player.hand = [];
    player.equipments = [];
    player.judgements = [];
    player.hp = player.maxHp;
    player.usedSkills = {};
  }
  state._deck = Array.from({ length: 30 }, (_, index) => card(`draw-${index}`));
  state._discard = [];
  state.phase = "PLAY";
  state.turnSeat = 1;
  state.activeCard = null;
  state.turnDamageDealt = false;
  return state;
}

for (const [id, skills] of [
  ["HERO_17", ["VAN_AN", "DE_NGHIEP"]],
  ["HERO_18", ["KHOAN_GIAN", "CHINH_THONG"]],
  ["HERO_19", ["KHOAN_HOA", "CAI_CACH"]],
  ["HERO_20", ["NGHIA_TU", "DUONG_BINH"]],
]) assert.deepEqual(getHeroById(id).skills, skills);

{
  const state = game(["HERO_17", "HERO_1", "HERO_2", "HERO_3"]);
  state.players[0].hand = [
    card("red-1", "Heart"),
    card("red-2", "Diamond"),
    card("red-3", "Heart"),
    card("red-4", "Diamond"),
  ];
  assert.equal(handleUseSkill(state, 1, "Vạn An", 2, "red-1|red-2").success, true);
  assert.equal(state.players[0].hand.length, 3, "Vạn An lần đầu trong lượt phải rút 1 lá");
  assert.equal(state.players[1].judgements.some((item) => item.subType === CARD_SUBTYPES.BAI_COC_BACH_DANG), true);
  assert.equal(handleUseSkill(state, 1, "Vạn An", 3, "red-3|red-4").success, true);
  assert.equal(state.players[0].hand.length, 1, "Vạn An lần hai trong lượt không được rút thêm");
  assert.equal(state.players[2].judgements.some((item) => item.subType === CARD_SUBTYPES.BAI_COC_BACH_DANG), true);

  const before = state.players[0].hand.length;
  state.activeCard = { casterSeat: 1 };
  applyDamageToPlayer(state, 2, 1, "Cẩm Nang", "NORMAL", false, { skipNghiaTu: true, singleTargetScrollCasterSeat: 1 });
  assert.equal(state.players[0].hand.length, before + 1, "Đế Nghiệp phải rút 1 lá");
}

{
  const state = game(["HERO_17", "HERO_1", "HERO_2", "HERO_3"]);
  state.players[0].hand = [card("black", "Spade"), card("red", "Heart")];
  assert.match(handleUseSkill(state, 1, "Vạn An", 2, "black|red").error, /cùng màu/);
}

{
  const state = game(["HERO_18", "HERO_1", "HERO_2", "HERO_3"]);
  state.players[0].hand = Array.from({ length: 6 }, (_, index) => card(`held-${index}`));
  state.players[0].equipments = [
    { ...card("armor"), category: CARD_CATEGORIES.EQUIPMENT, subType: CARD_SUBTYPES.ARMOR },
    { ...card("weapon"), category: CARD_CATEGORIES.EQUIPMENT, subType: CARD_SUBTYPES.WEAPON },
  ];
  handleEndTurn(state, 1);
  assert.equal(state.phase, "DISCARD", "Khoan Giản phải cộng X vào giới hạn trữ bài");
  assert.equal(state.players[0].hand.length, 6, "Khoan Giản chỉ rút sau khi hoàn tất Bỏ bài");
  handleDiscardCards(state, 1, ["held-4", "held-5"]);
  assert.equal(state.players[0].hand.length, 5, "Hai Trang bị phải cho X = 1");
  assert.equal(state.turnSeat, 2);
}

{
  const state = game(["HERO_18", "HERO_1", "HERO_2", "HERO_3"]);
  state.players[0].hand = Array.from({ length: 4 }, (_, index) => card(`minimum-${index}`));
  handleEndTurn(state, 1);
  assert.equal(state.players[0].hand.length, 5, "Không có Trang bị vẫn phải cho X tối thiểu bằng 1");
  assert.equal(state.turnSeat, 2);
}

{
  const state = game(["HERO_1", "HERO_18", "HERO_2", "HERO_3"]);
  state.players[2].hand = [card("tribute")];
  handleEndTurn(state, 1);
  assert.equal(state.phase, "AWAIT_CHINH_THONG_TARGET");
  handleUseSkill(state, 2, "Chính Thống", 3);
  assert.equal(state.phase, "AWAIT_CHINH_THONG_GIVE");
  handleRespondAction(state, 3, true, "tribute");
  assert.equal(state.players[1].hand.some((item) => item.id === "tribute"), true);
}

{
  const state = game(["HERO_1", "HERO_18", "HERO_2", "HERO_3"]);
  state.players[2].hand = [card("revealed")];
  handleEndTurn(state, 1);
  handleUseSkill(state, 2, "Chính Thống", 3);
  handleRespondAction(state, 3, false, "");
  assert.equal(sanitizeGameStateForClient(state, 2).chinhThongReveal.cards[0].id, "revealed");
  assert.equal(sanitizeGameStateForClient(state, 1).chinhThongReveal, null, "Bài lộ chỉ được gửi cho Khúc Thừa Dụ");
}

{
  const state = game(["HERO_19", "HERO_1", "HERO_2", "HERO_3"]);
  state.players[0].hand = [card("old-hand")];
  state.players[0].equipments = [{ ...card("old-equipment"), category: CARD_CATEGORIES.EQUIPMENT, subType: CARD_SUBTYPES.ARMOR }];
  assert.equal(handleUseSkill(state, 1, "Cải Cách", 0, "old-hand|old-equipment").success, true);
  assert.equal(state.players[0].hand.length, 2);
  assert.equal(state.players[0].equipments.length, 0, "Cải Cách phải đổi được Trang bị đang mang");
  assert.equal(state._discard.some((item) => item.id === "old-hand"), true);
  assert.equal(state._discard.some((item) => item.id === "old-equipment"), true);
  assert.match(handleUseSkill(state, 1, "Cải Cách", 0, "x|y").error, /1 lần/);

  const allyBefore = state.players[1].hand.length;
  handleEndTurn(state, 1);
  assert.equal(state.phase, "AWAIT_KHOAN_HOA");
  handleUseSkill(state, 1, "Khoan Hòa", 2);
  assert.equal(state.players[1].hand.length, allyBefore + 1);
  handleRespondAction(state, 1, false, null);
  assert.equal(state.turnSeat, 2);
}

{
  const state = game(["HERO_19", "HERO_1", "HERO_2", "HERO_3"]);
  state.players[0].hand = [card("a"), card("b"), card("c"), card("d"), card("e")];
  handleEndTurn(state, 1);
  assert.equal(state.phase, "DISCARD", "Khúc Hạo phải bỏ bài trước khi hỏi Khoan Hòa");
  assert.equal(state.waitingReactionType, "DISCARD");
  handleDiscardCards(state, 1, ["a", "b"]);
  assert.equal(state.phase, "AWAIT_KHOAN_HOA", "Chỉ hỏi Khoan Hòa sau khi bỏ đủ bài thừa");
}

{
  const state = game(["HERO_23", "HERO_1", "HERO_2", "HERO_3"]);
  state.players[0].hand = [];
  state.players[1].hand = [card("target-hand")];
  state.players[1].equipments = [{ ...card("target-equipment"), category: CARD_CATEGORIES.EQUIPMENT, subType: CARD_SUBTYPES.ARMOR }];
  state.turnSeat = 1;
  assert.equal(handleEndTurn(state, 1).success, true);
  assert.equal(handleEndTurn(state, 2).success, true);
  assert.equal(handleEndTurn(state, 3).success, true);
  assert.equal(handleEndTurn(state, 4).success, true);
  assert.equal(state.phase, "AWAIT_XUNG_VUONG_TARGET", "Dương Tam Kha phải kích hoạt Xưng Vương khi ít bài nhất");
  assert.equal(handleRespondAction(state, 1, true, "2").success, true);
  assert.equal(state.phase, "AWAIT_TARGET_CARD", "Mục tiêu phải được hỏi tự bỏ bài hoặc trang bị");
}

{
  const tiedMost = game(["HERO_23", "HERO_1", "HERO_2", "HERO_3"]);
  tiedMost.players[0].hand = [card("m1"), card("m2")];
  tiedMost.players[1].hand = [card("m3"), card("m4")];
  tiedMost.players[2].hand = [card("m5")];
  tiedMost.players[3].hand = [card("m6")];
  tiedMost.turnSeat = 4;
  assert.equal(handleEndTurn(tiedMost, 4).success, true);
  assert.equal(tiedMost.actionHistory.some((action) => action.type === "XUNG_VUONG_DRAW"), true, "Đồng hạng nhiều bài nhất vẫn phải được rút thêm 1 lá");
}

{
  const tiedLeast = game(["HERO_23", "HERO_1", "HERO_2", "HERO_3"]);
  tiedLeast.players[0].hand = [];
  tiedLeast.players[1].hand = [];
  tiedLeast.players[2].hand = [card("l1")];
  tiedLeast.players[3].hand = [card("l2")];
  tiedLeast.players[2].equipments = [{ ...card("l-equip"), category: CARD_CATEGORIES.EQUIPMENT, subType: CARD_SUBTYPES.ARMOR }];
  tiedLeast.turnSeat = 4;
  assert.equal(handleEndTurn(tiedLeast, 4).success, true);
  assert.equal(tiedLeast.phase, "AWAIT_XUNG_VUONG_TARGET", "Đồng hạng ít bài nhất vẫn phải được chọn mục tiêu");
}

{
  const state = game(["HERO_1", "HERO_2", "HERO_20", "HERO_3"]);
  state.players[2].hand = [card("cost-1")];
  state.activeCard = { casterSeat: 1 };
  applyDamageToPlayer(state, 2, 1, "đòn đánh");
  assert.equal(state.phase, "AWAIT_NGHIA_TU");
  assert.equal(sanitizeGameStateForClient(state, 3).nghiaTuTargetSeat, 2, "Client phải biết Nghĩa Tử đang chịu thay cho ai");
  handleRespondAction(state, 3, true, "", null, ["cost-1"]);
  assert.equal(state.players[1].hp, state.players[1].maxHp, "Nghĩa Tử phải đỡ 1 sát thương cho mục tiêu");
  assert.equal(state.players[2].hp, state.players[2].maxHp - 1);
  assert.equal(state.players[2].hand.length, 2, "Dưỡng Binh phải rút 2 lá");
}

{
  const state = game(["HERO_1", "HERO_2", "HERO_20", "HERO_3"]);
  state.players[2].hand = [card("timeout-1")];
  state.activeCard = { casterSeat: 1 };
  applyDamageToPlayer(state, 2, 1, "đòn đánh");
  state.timerStartAt = Date.now() - 41_000;
  tickGameState(state);
  assert.notEqual(state.phase, "AWAIT_NGHIA_TU", "Nghĩa Tử hết giờ không được làm kẹt trận");
  assert.equal(state.players[1].hp, state.players[1].maxHp - 1);
}

console.log("[TEST PASS] Hero 17-20 skills");
