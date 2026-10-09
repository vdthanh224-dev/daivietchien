import assert from "node:assert/strict";
import {
  executeCardEffect,
  handleEndTurn,
  handlePlayCard,
  applyDamageToPlayer,
  handleToggleSkill,
  initGame,
  sanitizeGameStateForClient,
} from "../server/functions/game-engine/src/gameEngine.js";
import { CARD_CATEGORIES, CARD_SUBTYPES } from "../server/functions/game-engine/src/deck.js";

const slash = (id, suit = "Spade") => ({ id, name: "Trảm", suit, rank: 7, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.ATTACK_NORMAL });
const weapon = (id) => ({ id, name: id, suit: "Spade", rank: 5, category: CARD_CATEGORIES.EQUIPMENT, subType: CARD_SUBTYPES.WEAPON, range: 1 });
const hasActivation = (action, name, seat) => action?.skillActivations?.some((item) => item.name === name && item.seat === seat);

function game(heroIds) {
  const state = initGame("skill-feedback-test", heroIds.map((heroId, index) => ({ seat: index + 1, heroId, generalName: `P${index + 1}` })));
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
  const state = initGame("tien-phong-feedback", ["HERO_7", "HERO_1", "HERO_2", "HERO_3"].map((heroId, index) => ({ seat: index + 1, heroId, generalName: `P${index + 1}` })));
  assert.equal(hasActivation(state.lastAction, "Tiên Phong", 1), true);
}

{
  const state = game(["HERO_1", "HERO_2", "HERO_3", "HERO_4"]);
  handleToggleSkill(state, 1, "Chế Nỏ");
  assert.equal(hasActivation(state.lastAction, "Chế Nỏ", 1), true);
}

for (const [heroId, skillName, prepare] of [
  ["HERO_2", "Xạ Thuẫn", () => {}],
  ["HERO_5", "Dũng Nữ", (state) => { state.players[0].hp = 3; }],
  ["HERO_9", "Chiến Tượng", (state) => { state.players[0].equipments = [{ id: "horse", name: "Voi", category: CARD_CATEGORIES.EQUIPMENT, subType: CARD_SUBTYPES.DEFENSIVE_HORSE }]; }],
  ["HERO_14", "Nỏ Đỉnh", (state) => { state.players[0].hp = 2; }],
]) {
  const state = game([heroId, "HERO_1", "HERO_2", "HERO_3"]);
  prepare(state);
  state.players[0].hand = [slash(`${skillName}-slash`)];
  const targetSeat = skillName === "Nỏ Đỉnh" ? 3 : 2;
  assert.equal(handlePlayCard(state, 1, state.players[0].hand[0].id, targetSeat).success, true);
  assert.equal(hasActivation(state.lastAction, skillName, 1), true, `${skillName} phải gửi metadata kích hoạt`);
}

{
  const state = game(["HERO_13", "HERO_1", "HERO_2", "HERO_3"]);
  state.players[0].hand = [slash("tran-nam")];
  state.players[1].equipments = [{ id: "armor", name: "Giáp Đồng Sơn Vi", category: CARD_CATEGORIES.EQUIPMENT, subType: CARD_SUBTYPES.ARMOR }];
  handlePlayCard(state, 1, "tran-nam", 2);
  assert.equal(hasActivation(state.lastAction, "Trấn Nam", 1), true);
}

{
  const state = game(["HERO_1", "HERO_14", "HERO_2", "HERO_3"]);
  state.players[0].hand = [slash("da-trach")];
  handlePlayCard(state, 1, "da-trach", 2);
  assert.equal(hasActivation(state.lastAction, "Dạ Trạch", 2), true, "Dạ Trạch phải hiện chữ trên tướng bị nhắm");
}

{
  const state = game(["HERO_15", "HERO_1", "HERO_2", "HERO_3"]);
  executeCardEffect(state, { id: "duel", name: "Huyết Chiến", category: CARD_CATEGORIES.INSTANT_SCROLL, subType: CARD_SUBTYPES.BLOOD_BATTLE }, 1, 2);
  assert.equal(hasActivation(state.lastAction, "Phục Hổ", 1), true);
}

{
  const state = game(["HERO_16", "HERO_1", "HERO_2", "HERO_3"]);
  state.players[0].hand = [weapon("w1"), weapon("w2")];
  handlePlayCard(state, 1, "w1");
  handlePlayCard(state, 1, "w2");
  assert.equal(hasActivation(state.lastAction, "Lực Địch", 1), true);
}

{
  const state = game(["HERO_10", "HERO_1", "HERO_2", "HERO_3"]);
  state.players[0].hand = Array.from({ length: 5 }, (_, index) => ({ id: `c${index}`, name: "Đỡ", category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.DODGE }));
  handleEndTurn(state, 1);
  assert.equal(state.actionHistory.some((action) => action.type === "XUNG_DE_TRIGGERED" && hasActivation(action, "Xưng Đế", 1)), true);
}

{
  const state = game(["HERO_14", "HERO_1", "HERO_2", "HERO_3"]);
  state.players[0].hp = 2;
  state.players[0].hand = [slash("sanitized")];
  handlePlayCard(state, 1, "sanitized", 3);
  const clientState = sanitizeGameStateForClient(state, 1);
  assert.equal(hasActivation(clientState.delta, "Nỏ Đỉnh", 1), true);
  assert.equal(clientState.actionHistory.some((action) => hasActivation(action, "Nỏ Đỉnh", 1)), true);
}

{
  const state = game(["HERO_24", "HERO_1", "HERO_2", "HERO_3"]);
  state.players[0].hp = 1;
  state.players[0].judgements = [{ id: "delayed", name: "Cẩm Nang Trì Hoãn", category: CARD_CATEGORIES.DELAYED_SCROLL }];
  applyDamageToPlayer(state, 1, 1, "test", "NORMAL", false);
  assert.equal(state.actionHistory.some((action) => hasActivation(action, "Thiên Cảm", 1)), true, "Thiên Cảm phải gửi metadata kích hoạt khi xóa Cẩm Nang Trì Hoãn");
}

{
  const state = game(["HERO_24", "HERO_1", "HERO_2", "HERO_3"]);
  state.players[0].hp = 1;
  state.players[0].hand = [];
  state.turnSeat = 2;
  const delayed = { id: "delayed-blocked", name: "Cẩm Nang Trì Hoãn", category: CARD_CATEGORIES.DELAYED_SCROLL, subType: CARD_SUBTYPES.ACEDIA };
  state.players[1].hand = [delayed];
  const result = handlePlayCard(state, 2, delayed.id, 1);
  assert.equal(result.success, true);
  assert.equal(hasActivation(state.lastAction, "Thiên Cảm", 1), true, "Thiên Cảm phải hiện khi chặn Cẩm Nang Trì Hoãn nhắm vào Ngô Xương Ngập");
}

console.log("[TEST PASS] Skill activation feedback metadata");
