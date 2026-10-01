import assert from "node:assert/strict";
import {
  handlePlayCard,
  handleRespondAction,
  initGame,
  sanitizeGameStateForClient,
} from "../deno-server/gameEngine.js";
import { CARD_CATEGORIES, CARD_SUBTYPES } from "../deno-server/deck.js";

const players = [
  { seat: 1, userId: "user_seat_1", generalName: "Trần Hưng Đạo", maxHp: 4, hp: 4, isAlly: true, isAI: false },
  { seat: 2, userId: "user_seat_2", generalName: "Thoát Hoan", maxHp: 4, hp: 4, isAlly: false, isAI: false },
  { seat: 3, userId: "user_seat_3", generalName: "Yết Kiêu", maxHp: 4, hp: 4, isAlly: true, isAI: false },
  { seat: 4, userId: "user_seat_4", generalName: "Ô Mã Nhi", maxHp: 4, hp: 4, isAlly: false, isAI: false },
];

const card = (id, name, subType, category = CARD_CATEGORIES.BASIC) => ({
  id,
  name,
  category,
  subType,
  suit: "Heart",
  rank: 1,
  desc: "test",
});

const state = initGame("room_test_live_4clients", players);
for (const player of state.players) player.hand = [];
state.players[0].hand.push(card("C_MUA_TEN", "Mưa Tên Liên Châu", CARD_SUBTYPES.ARROW_RAIN, CARD_CATEGORIES.INSTANT_SCROLL));
state.players[1].hand.push(card("C_DO_1", "Đỡ", CARD_SUBTYPES.DODGE));
state.players[2].hand.push(card("C_DIEU_KE_3", "Diệu Kế Phá Mưu", CARD_SUBTYPES.FLAWLESS_DEFENSE, CARD_CATEGORIES.INSTANT_SCROLL));
state.players[3].hand.push(card("C_DIEU_KE_4", "Diệu Kế Phá Mưu", CARD_SUBTYPES.FLAWLESS_DEFENSE, CARD_CATEGORIES.INSTANT_SCROLL));

console.log("🧪 Kiểm tra 4 client: Mưa Tên hỏi Diệu Kế đúng vòng và đúng ghế");

let result = handlePlayCard(state, 1, "C_MUA_TEN", 0);
assert.equal(result.success, true);
assert.equal(state.phase, "AWAIT_NULLIFY");
assert.equal(state.waitingTargetSeat, 3);

for (const viewerSeat of [1, 2, 4]) {
  const visible = sanitizeGameStateForClient(state, viewerSeat);
  assert.equal(visible.waitingTargetSeat, 0);
  assert.equal(visible.nullifyChain.querySeats, undefined);
  assert.doesNotMatch(JSON.stringify(visible.lastAction), /Yết Kiêu|Ô Mã Nhi/);
}
assert.equal(sanitizeGameStateForClient(state, 3).waitingTargetSeat, 3);

result = handleRespondAction(state, 3, true, "C_DIEU_KE_3");
assert.equal(result.success, true);
assert.equal(state.phase, "AWAIT_NULLIFY");
assert.equal(state.waitingTargetSeat, 4);

result = handleRespondAction(state, 4, true, "C_DIEU_KE_4");
assert.equal(result.success, true);
assert.equal(state.phase, "AWAIT_AOE");
assert.equal(state.waitingTargetSeat, 2);
assert.equal(state.waitingReactionType, "DODGE");

result = handleRespondAction(state, 2, true, "C_DO_1");
assert.equal(result.success, true);
assert.equal(state.phase, "AWAIT_AOE");
assert.equal(state.waitingTargetSeat, 3);
assert.equal(state.players[1].hp, 4);

result = handleRespondAction(state, 3, false, null);
assert.equal(result.success, true);
assert.equal(state.phase, "AWAIT_AOE");
assert.equal(state.waitingTargetSeat, 4);
assert.equal(state.players[2].hp, 3);

result = handleRespondAction(state, 4, false, null);
assert.equal(result.success, true);
assert.equal(state.phase, "PLAY");
assert.equal(state.players[3].hp, 3);
assert.equal(state.players[0].hand.length, 0);

console.log("4-client Diệu Kế/Mưa Tên: PASS");
