import assert from "node:assert/strict";
import {
  executeCardEffect,
  handleEndTurn,
  handlePlayCard,
  handleRespondAction,
  handleUseSkill,
  initGame,
} from "../deploy_deno/functions/game-engine/src/gameEngine.js";
import { CARD_CATEGORIES, CARD_SUBTYPES } from "../deploy_deno/functions/game-engine/src/deck.js";

const slash = (id, suit = "Spade", subType = CARD_SUBTYPES.ATTACK_NORMAL) => ({
  id,
  name: subType === CARD_SUBTYPES.ATTACK_FIRE ? "Trảm - Hỏa" : "Trảm",
  suit,
  rank: 7,
  category: CARD_CATEGORIES.BASIC,
  subType,
});
const weapon = (id, name, range = 1) => ({
  id,
  name,
  suit: "Spade",
  rank: 5,
  category: CARD_CATEGORIES.EQUIPMENT,
  subType: CARD_SUBTYPES.WEAPON,
  range,
});
const armor = (id = "armor") => ({
  id,
  name: "Giáp Đồng Sơn Vi",
  suit: "Club",
  rank: 2,
  category: CARD_CATEGORIES.EQUIPMENT,
  subType: CARD_SUBTYPES.ARMOR,
});
const duel = (id = "duel") => ({
  id,
  name: "Huyết Chiến",
  suit: "Spade",
  rank: 1,
  category: CARD_CATEGORIES.INSTANT_SCROLL,
  subType: CARD_SUBTYPES.BLOOD_BATTLE,
});

function game(heroIds) {
  const state = initGame("heroes-13-16-test", heroIds.map((heroId, index) => ({
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
  state._deck = [];
  state._discard = [];
  state.phase = "PLAY";
  state.turnSeat = 1;
  state.activeCard = null;
  state.slashesUsedThisTurn = 0;
  return state;
}

{
  const state = game(["HERO_13", "HERO_1", "HERO_2", "HERO_3"]);
  const giacToi = { id: "giac", name: "Giặc Tới", category: CARD_CATEGORIES.INSTANT_SCROLL, subType: CARD_SUBTYPES.GIAC_TOI };
  executeCardEffect(state, giacToi, 4);
  assert.equal(state.players[0].hp, 4);
  assert.equal(state.actionHistory.some((action) => action.type === "TRAN_NAM_IMMUNE"), true, "Trấn Nam phải miễn nhiễm Giặc Tới");
  assert.notEqual(state.waitingTargetSeat, 1, "Giặc Tới không được chờ Phạm Tu phản ứng");
}

{
  const state = game(["HERO_13", "HERO_1", "HERO_2", "HERO_3"]);
  state.players[0].hand = [slash("black")];
  state.players[1].equipments = [armor()];
  assert.equal(handlePlayCard(state, 1, "black", 2).success, true);
  assert.equal(state.phase, "AWAIT_SLASH_DEFENSE", "Trảm thường Đen của Phạm Tu phải xuyên Giáp Đồng Sơn Vi");
  handleRespondAction(state, 2, false, null);
  assert.equal(state.players[1].hp, 3);
}

{
  const state = game(["HERO_13", "HERO_1", "HERO_2", "HERO_3"]);
  state.players[0].hand = [slash("red", "Heart")];
  state.players[1].equipments = [armor()];
  handlePlayCard(state, 1, "red", 2);
  assert.equal(state.players[1].hp, 4);
  assert.equal(state.phase, "PLAY", "Trảm thường Đỏ vẫn phải bị Giáp Đồng Sơn Vi chặn");
}

{
  const state = game(["HERO_13", "HERO_1", "HERO_2", "HERO_3"]);
  state.players[0].hp = 3;
  state.players[0].equipments = [armor("hoa-dan-armor"), weapon("hoa-dan-weapon", "Kiếm Thử", 2)];
  handleEndTurn(state, 1);
  assert.equal(state.phase, "AWAIT_HOA_DAN");
  handleRespondAction(state, 1, true, null);
  assert.equal(state.phase, "AWAIT_TARGET_CARD");
  const token = state.targetCardSelection.options.find((option) => option.token.includes("hoa-dan-weapon"))?.token;
  handleRespondAction(state, 1, true, null, token);
  assert.equal(state.players[0].hp, 4);
  assert.equal(state.players[0].equipments.some((card) => card.id === "hoa-dan-weapon"), false);
  assert.equal(state.turnSeat, 2, "Hóa Dân xong phải tiếp tục kết thúc lượt");
}

{
  const state = game(["HERO_1", "HERO_14", "HERO_2", "HERO_3"]);
  state.players[0].hand = [slash("normal")];
  assert.equal(handlePlayCard(state, 1, "normal", 2).success, true);
  assert.equal(state.lastAction.type, "DA_TRACH_TRIGGERED");
  assert.equal(state.players[0].hand[0].id, "normal", "Dạ Trạch chặn mục tiêu nên không tiêu hao lá Trảm");
  state.players[0].hand = [slash("fire", "Heart", CARD_SUBTYPES.ATTACK_FIRE)];
  assert.equal(handlePlayCard(state, 1, "fire", 2).success, true, "Dạ Trạch không chặn Trảm Hỏa");
}

{
  const lowHp = game(["HERO_14", "HERO_1", "HERO_2", "HERO_3"]);
  lowHp.players[0].hp = 2;
  lowHp.players[0].hand = [slash("long-range")];
  assert.equal(handlePlayCard(lowHp, 1, "long-range", 3).success, true, "Nỏ Đỉnh phải cho Trảm không giới hạn tầm khi còn 2 Máu");

  const highHp = game(["HERO_14", "HERO_1", "HERO_2", "HERO_3"]);
  highHp.players[0].hp = 3;
  highHp.players[0].hand = [slash("too-far")];
  assert.match(handlePlayCard(highHp, 1, "too-far", 3).error, /ngoài tầm/);
}

{
  const state = game(["HERO_14", "HERO_1", "HERO_2", "HERO_3"]);
  state.players[0].hand = [slash("d1"), slash("d2"), slash("d3"), slash("d4"), slash("d5")];
  assert.equal(handleEndTurn(state, 1).success, true);
  assert.equal(state.phase, "DISCARD", "Dạ Trạch phải chờ sau giai đoạn bỏ bài thừa");
  assert.equal(state.waitingReactionType, "DISCARD");
  assert.equal(handleRespondAction(state, 1, false, null).error, "Giai đoạn không hỗ trợ phản hồi này");
}

{
  const state = game(["HERO_15", "HERO_1", "HERO_2", "HERO_3"]);
  state.players[1].hand = [slash("reply-1"), slash("reply-2")];
  executeCardEffect(state, duel(), 1, 2);
  handleRespondAction(state, 2, true, "reply-1");
  assert.equal(state.waitingTargetSeat, 2);
  assert.equal(state.activeCard.duelSlashesUsed, 1);
  handleRespondAction(state, 2, true, "reply-2");
  assert.equal(state.waitingTargetSeat, 1, "Đối phương phải ra đủ 2 Trảm mới chuyển lượt Huyết Chiến");
}

{
  const state = game(["HERO_1", "HERO_15", "HERO_2", "HERO_3"]);
  state.players[1].hand = [slash("phung-reply")];
  state.players[0].hand = [slash("caster-reply-1"), slash("caster-reply-2")];
  executeCardEffect(state, duel(), 1, 2);
  handleRespondAction(state, 2, true, "phung-reply");
  handleRespondAction(state, 1, true, "caster-reply-1");
  assert.equal(state.waitingTargetSeat, 1);
  assert.equal(state.activeCard.duelSlashesUsed, 1, "Người dùng Huyết Chiến lên Phùng Hưng cũng phải ra 2 Trảm");
}

{
  const state = game(["HERO_1", "HERO_2", "HERO_3", "HERO_15"]);
  const delayed = { id: "delayed", name: "Cắt Đường Lương", category: CARD_CATEGORIES.DELAYED_SCROLL, subType: CARD_SUBTYPES.SUPPLY_SHORTAGE };
  state.players[1].judgements = [delayed];
  state.turnSeat = 3;
  handleEndTurn(state, 3);
  assert.equal(state.phase, "AWAIT_AN_DAN");
  handleRespondAction(state, 4, true, null);
  const option = state.targetCardSelection.options.find((item) => item.token === "AN_DAN|2|delayed|1");
  assert.ok(option);
  handleRespondAction(state, 4, true, null, option.token);
  assert.equal(state.players[1].judgements.length, 0);
  assert.equal(state.players[0].judgements[0].id, "delayed");
  assert.equal(state.players[3].hand.length, 0, "An Dân phải bỏ qua rút bài");
  assert.equal(state.phase, "AWAIT_AN_DAN_DUEL");
  handleRespondAction(state, 4, false, null);
  assert.equal(state.phase, "PLAY");
}

{
  const state = game(["HERO_16", "HERO_1", "HERO_2", "HERO_3"]);
  state.players[0].hand = [weapon("w1", "Vũ Khí Một", 1), weapon("w2", "Vũ Khí Hai", 1), weapon("w3", "Vũ Khí Ba", 1), slash("range-two")];
  handlePlayCard(state, 1, "w1");
  handlePlayCard(state, 1, "w2");
  assert.equal(state.players[0].equipments.filter((card) => card.subType === CARD_SUBTYPES.WEAPON).length, 2);
  handlePlayCard(state, 1, "w3");
  assert.equal(state.players[0].equipments.filter((card) => card.subType === CARD_SUBTYPES.WEAPON).length, 2, "Lực Địch không được vượt quá 2 Vũ Khí");
  assert.equal(state.players[0].equipments.some((card) => card.id === "w1"), false);
  assert.equal(handlePlayCard(state, 1, "range-two", 3).success, true, "Lực Địch phải cộng tầm của 2 Vũ Khí");
}

{
  const state = game(["HERO_16", "HERO_1", "HERO_2", "HERO_3"]);
  state.players[0].hand = [weapon("hung-suc", "Vũ Khí Hiến", 2)];
  assert.equal(handleUseSkill(state, 1, "Hùng Sức", 2, "hung-suc").success, true);
  assert.equal(state.players[0].hand.length, 1, "Hùng Sức phải rút 1 lá sau khi gây sát thương");
  assert.equal(state.players[1].hp, 3);
  assert.equal(state.players[0].hand.length, 1, "Hùng Sức phải rút 1 lá sau khi gây sát thương");
  assert.equal(state.lastAction.type, "HUNG_SUC_TRIGGERED", "Bản tin Hùng Sức phải là sự kiện cuối để client hiện hiệu ứng kích hoạt");

  const tooFar = game(["HERO_16", "HERO_1", "HERO_2", "HERO_3"]);
  tooFar.players[0].hand = [weapon("hung-suc-far", "Vũ Khí Hiến", 2)];
  assert.match(handleUseSkill(tooFar, 1, "Hùng Sức", 3, "hung-suc-far").error, /Tầm 1/);
}

{
  const state = game(["HERO_16", "HERO_1", "HERO_2", "HERO_3"]);
  state.players[0].equipments = [weapon("hung-suc-equipped", "Vũ Khí Đang Mang", 2)];
  assert.equal(handleUseSkill(state, 1, "Hùng Sức", 2, "hung-suc-equipped").success, true, "Hùng Sức phải cho phép bỏ Vũ Khí đang trang bị");
  assert.equal(state.players[0].equipments.length, 0, "Vũ Khí đang trang bị phải được tháo và bỏ");
  assert.equal(state.players[1].hp, 3, "Hùng Sức từ Vũ Khí đang trang bị vẫn gây 1 sát thương");
}

console.log("[TEST PASS] Hero 13-16 skills");
