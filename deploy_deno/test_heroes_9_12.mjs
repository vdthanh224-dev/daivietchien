import assert from "node:assert/strict";
import {
  applyDamageToPlayer,
  executeCardEffect,
  handleEndTurn,
  handlePlayCard,
  handleRespondAction,
  handleUseSkill,
  initGame,
  sanitizeGameStateForClient,
} from "./functions/game-engine/src/gameEngine.js";
import { CARD_CATEGORIES, CARD_SUBTYPES } from "./functions/game-engine/src/deck.js";

const basic = (id, subType = CARD_SUBTYPES.ATTACK_NORMAL, suit = "Spade") => ({ id, name: subType === CARD_SUBTYPES.ATTACK_FIRE ? "Trảm - Hỏa" : subType === CARD_SUBTYPES.ATTACK_WATER ? "Trảm - Thủy" : "Trảm", suit, rank: 7, category: CARD_CATEGORIES.BASIC, subType });
const dodge = (id, suit = "Heart") => ({ id, name: "Đỡ", suit, rank: 2, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.DODGE });
const trick = (id, subType = CARD_SUBTYPES.EX_NIHILO) => ({ id, name: "Dụng Binh Như Thần", suit: "Heart", rank: 8, category: CARD_CATEGORIES.INSTANT_SCROLL, subType });
const horse = { id: "horse", name: "Voi Chiến Đại Việt", suit: "Club", rank: 5, category: CARD_CATEGORIES.EQUIPMENT, subType: CARD_SUBTYPES.DEFENSIVE_HORSE };

function game(heroIds = ["HERO_9", "HERO_1", "HERO_2", "HERO_3"]) {
  const state = initGame("hero-9-12-test", heroIds.map((heroId, index) => ({ seat: index + 1, heroId, generalName: `P${index + 1}` })));
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
  state.slashesUsedThisTurn = 0;
  state.activeCard = null;
  return state;
}

{
  const state = game();
  state.players[0].equipments = [horse];
  state.players[0].hand = [basic("normal")];
  assert.equal(handlePlayCard(state, 1, "normal", 2).success, true);
  assert.equal(state.activeCard.damage, 2, "Chiến Tượng phải cộng 1 sát thương Trảm khi có Ngựa");
}

{
  const state = game();
  const trap = { id: "bai-coc-once", name: "Bãi Cọc Bạch Đằng", suit: "Spade", rank: 9, category: CARD_CATEGORIES.DELAYED_SCROLL, subType: CARD_SUBTYPES.BAI_COC_BACH_DANG, attachedBySeat: 2 };
  state.players[0].hand = [basic("slash-into-bai-coc")];
  state.players[0].judgements = [trap];
  state._deck = [{ id: "black-judge", name: "Đỡ", suit: "Club", rank: 6, category: CARD_CATEGORIES.BASIC, subType: CARD_SUBTYPES.DODGE }];
  assert.equal(handlePlayCard(state, 1, "slash-into-bai-coc", 2).success, true);
  assert.equal(state.players[0].hp, 3, "Bãi Cọc chỉ được gây 1 sát thương sau một lần phán xét");
  assert.equal(state._deck.length, 0, "Bãi Cọc chỉ được rút đúng 1 lá phán xét");
  assert.equal(state.players[0].judgements.length, 0, "Bãi Cọc phải rời khu phán xét ngay sau lần xét đầu tiên");
  assert.equal(state.actionHistory.filter((action) => action.type === "BAI_COC_BACH_DANG_TRIGGERED").length, 1, "Bãi Cọc chỉ được ghi nhận kích hoạt một lần");
}

{
  const state = game();
  state.players[0].hand = [basic("fire", CARD_SUBTYPES.ATTACK_FIRE, "Heart")];
  state.players[1].hand = [basic("cost"), dodge("dodge")];
  handlePlayCard(state, 1, "fire", 2);
  assert.equal(state.phase, "AWAIT_OAI_NHUOC");
  assert.equal(handleRespondAction(state, 2, true, null, null, ["cost", "dodge"]).success, true);
  assert.equal(state.phase, "PLAY", "Oai Nhược hợp lệ phải hóa giải Trảm ngay, không hỏi Đỡ lần hai");
  assert.equal(state.players[1].hand.length, 0);
  assert.equal(state.activeCard, null);
}

{
  const state = game();
  state.players[0].hand = [basic("fire-invalid", CARD_SUBTYPES.ATTACK_FIRE, "Heart")];
  state.players[1].hand = [basic("cost-a"), basic("cost-b")];
  handlePlayCard(state, 1, "fire-invalid", 2);
  assert.match(handleRespondAction(state, 2, true, null, null, ["cost-a"]).error, /đúng 2 lá/);
  assert.match(handleRespondAction(state, 2, true, null, null, ["cost-a", "cost-b"]).error, /lá Đỡ hợp lệ/);
  assert.equal(state.players[1].hand.length, 2, "Lựa chọn Oai Nhược lỗi không được bỏ bài");
}

{
  const state = game();
  state.players[0].equipments = [{ id: "cannon", name: "Súng Thần Công Hồ Triều", category: CARD_CATEGORIES.EQUIPMENT, subType: CARD_SUBTYPES.WEAPON }];
  state.players[0].hand = [basic("fire-cannon", CARD_SUBTYPES.ATTACK_FIRE, "Heart")];
  state.players[1].hand = [basic("cost-cannon"), dodge("red-dodge", "Diamond")];
  handlePlayCard(state, 1, "fire-cannon", 2);
  assert.match(handleRespondAction(state, 2, true, null, null, ["cost-cannon", "red-dodge"]).error, /lá Đỡ hợp lệ/, "Oai Nhược phải giữ hạn chế màu của Súng Thần Công");
}

{
  const state = game();
  state.players[0].hand = [basic("fire-hp", CARD_SUBTYPES.ATTACK_FIRE, "Heart")];
  state.players[1].hand = [basic("kept-card")];
  state.players[1].equipments = [{ id: "armor", name: "Áo Bào Hoàng Tộc", category: CARD_CATEGORIES.EQUIPMENT, subType: CARD_SUBTYPES.ARMOR }];
  handlePlayCard(state, 1, "fire-hp", 2);
  handleRespondAction(state, 2, false, null);
  assert.equal(state.players[1].hp, 4, "Chịu Trảm qua Oai Nhược vẫn phải được Áo Bào chặn");
  assert.equal(state.players[1].hand.length, 1, "Chọn mất Máu không được bỏ bài");
  assert.equal(state.players[1].aoBaoCharges, 1, "Áo Bào phải tiêu hao đúng 1 điểm chặn");
  assert.equal(state.phase, "PLAY", "Chọn chịu sát thương phải kết thúc đòn Trảm, không hỏi Đỡ tiếp");
  assert.equal(state.activeCard, null);
}

{
  const state = game();
  state.players[0].equipments = [horse];
  state.players[0].hand = [basic("fire-two-damage", CARD_SUBTYPES.ATTACK_FIRE, "Heart")];
  handlePlayCard(state, 1, "fire-two-damage", 2);
  assert.equal(state.activeCard.damage, 2);
  handleRespondAction(state, 2, false, null);
  assert.equal(state.players[1].hp, 2, "Oai Nhược phải dùng toàn bộ sát thương Trảm đã cộng Chiến Tượng");
}

{
  const state = game();
  state.players[0].hand = [basic("water-empty", CARD_SUBTYPES.ATTACK_WATER, "Club")];
  handlePlayCard(state, 1, "water-empty", 2);
  assert.equal(state.phase, "AWAIT_OAI_NHUOC", "Không có bài vẫn phải chọn chịu sát thương do Oai Nhược");
  handleRespondAction(state, 2, false, null);
  assert.equal(state.players[1].hp, 3);
  assert.equal(state.phase, "PLAY");
}

{
  const state = game(["HERO_9", "HERO_3", "HERO_2", "HERO_4"]);
  state.players[0].hand = [basic("fire-one-damage", CARD_SUBTYPES.ATTACK_FIRE, "Heart")];
  handlePlayCard(state, 1, "fire-one-damage", 2);
  handleRespondAction(state, 2, false, null);
  assert.equal(state.turnDamageDealt, true, "Chịu đòn qua Oai Nhược phải tính đúng một lần gây sát thương Trảm");
  assert.equal(state.phase, "AWAIT_UAT_KHI");
  assert.equal(state.uatKhiQueue.length, 1, "Mất 1 Máu do Oai Nhược chỉ kích hoạt Uất Khí một lần");
  handleUseSkill(state, 2, "Uất Khí", 0);
  assert.equal(state.players[1].hp, 3, "Kết thúc Oai Nhược không được nhận thêm sát thương Trảm");
  assert.equal(state.phase, "PLAY");
  assert.equal(state.activeCard, null);
}

{
  const state = game(["HERO_1", "HERO_10", "HERO_2", "HERO_3"]);
  state.players[1].hp = 3;
  state._discard = [{ id: "heart", name: "Đỡ", suit: "Heart", rank: 3, category: 0, subType: CARD_SUBTYPES.DODGE }];
  handleEndTurn(state, 1);
  assert.equal(state.phase, "AWAIT_DUNG_NUOC");
  handleRespondAction(state, 2, true, null);
  assert.equal(state.players[1].hp, 4);
  assert.equal(state.players[1].hand.some((card) => card.id === "heart"), true);
}

{
  const state = initGame("dung-nuoc-first-turn", ["HERO_10", "HERO_1", "HERO_2", "HERO_3"].map((heroId, index) => ({ seat: index + 1, heroId, generalName: `P${index + 1}` })));
  const firstPlayer = state.players[0];
  assert.equal(state.phase, "AWAIT_DUNG_NUOC", "Dựng Nước phải được hỏi ở lượt đầu tiên");
  assert.equal(firstPlayer.hand.length, 4, "Chưa chọn Dựng Nước thì chưa được rút đầu lượt");
  handleRespondAction(state, 1, false, null);
  assert.equal(firstPlayer.hand.length, 5, "Từ chối Dựng Nước phải tiếp tục rút 1 lá của lượt đầu");
  assert.equal(state.phase, "PLAY");
}

{
  const state = game(["HERO_10", "HERO_1", "HERO_2", "HERO_3"]);
  state.players[0].hand = Array.from({ length: 6 }, (_, index) => basic(`xung-${index}`));
  handleEndTurn(state, 1);
  assert.notEqual(state.phase, "DISCARD", "Xưng Đế phải cho giữ thêm 2 lá khi đầy Máu");
}

{
  const state = game(["HERO_11", "HERO_1", "HERO_2", "HERO_3"]);
  state.players[0].equipments = [horse];
  state.players[0].hand = Array.from({ length: 4 }, (_, index) => basic(`tung-${index}`));
  state._deck = [basic("tung-draw")];
  handleEndTurn(state, 1);
  assert.equal(state.players[0].hand.length, 5);
  assert.notEqual(state.phase, "DISCARD", "Tùng Nghĩa phải cộng 1 giới hạn trữ bài");
}

{
  const state = game(["HERO_1", "HERO_11", "HERO_2", "HERO_3"]);
  state.players[0].hp = 1;
  state.players[1].hp = 4;
  applyDamageToPlayer(state, 1, 1, "test");
  assert.equal(state.phase, "AWAIT_TRUNG_KIEN");
  handleRespondAction(state, 2, true, null);
  assert.equal(state.players[0].hp, 1);
  assert.equal(state.players[1].hp, 3);
}

{
  const state = game(["HERO_1", "HERO_11", "HERO_2", "HERO_3"]);
  state.players[0].hp = 1;
  state.players[1].hp = 1;
  applyDamageToPlayer(state, 1, 1, "test");
  assert.equal(state.phase, "AWAIT_TRUNG_KIEN", "Triệu Túc còn 1 Máu vẫn phải được hỏi Trung Kiên");
  handleRespondAction(state, 2, true, null);
  assert.equal(state.players[0].hp, 1, "Trung Kiên phải cứu mục tiêu trước");
  assert.equal(state.players[1].hp, 0, "Triệu Túc còn 1 Máu sẽ tự giảm xuống Hấp Hối");
  assert.equal(state.phase, "AWAIT_NEAR_DEATH");
  assert.equal(state.nearDeathVictimSeat, 2, "Sau Trung Kiên phải chuyển sang cứu Triệu Túc");
}

{
  const state = game(["HERO_1", "HERO_2", "HERO_11", "HERO_3"]);
  state.players[0].hand = [basic("fatal-slash")];
  state.players[1].hp = 1;
  handlePlayCard(state, 1, "fatal-slash", 2);
  handleRespondAction(state, 2, false, null);
  assert.equal(state.phase, "AWAIT_TRUNG_KIEN");
  handleRespondAction(state, 3, true, null);
  assert.equal(state.players[1].hp, 1);
  assert.equal(state.phase, "PLAY", "Trung Kiên xong phải tiếp tục hoàn tất luồng Trảm");
  assert.equal(state.activeCard, null, "Luồng Trảm phải được dọn sau Trung Kiên");
  assert.equal(state.pendingAfterUatKhi, null);
}

{
  const state = game(["HERO_1", "HERO_2", "HERO_11", "HERO_3"]);
  state.players[1].hp = 1;
  state.activeCard = { casterSeat: 1, cardId: "aoe", cardName: "Mưa Tên Liên Châu", reqType: "DODGE" };
  state.aoeVictimsQueue = [4];
  applyDamageToPlayer(state, 2, 1, "đòn diện rộng");
  state.pendingAfterUatKhi = { type: "AOE" };
  handleRespondAction(state, 3, true, null);
  assert.equal(state.phase, "AWAIT_AOE", "Trung Kiên xong phải chuyển đúng sang nạn nhân AOE kế tiếp");
  assert.equal(state.waitingTargetSeat, 4);
  assert.equal(state.aoeVictimsQueue.length, 0, "Nạn nhân AOE kế tiếp chỉ được lấy một lần");
  assert.equal(state.pendingAfterUatKhi, null);
}

{
  const state = game(["HERO_1", "HERO_2", "HERO_11", "HERO_3"]);
  state.players[1].hp = 1;
  state.phase = "AWAIT_DUEL";
  state.waitingTargetSeat = 2;
  state.duelCasterSeat = 1;
  state.duelTargetSeat = 2;
  handleRespondAction(state, 2, false, null);
  assert.equal(state.phase, "AWAIT_TRUNG_KIEN");
  handleRespondAction(state, 3, true, null);
  assert.equal(state.phase, "PLAY", "Trung Kiên xong phải kết thúc đúng luồng Huyết Chiến");
  assert.equal(state.duelCasterSeat, 0);
  assert.equal(state.duelTargetSeat, 0);
}

{
  const state = game(["HERO_12", "HERO_1", "HERO_2", "HERO_3"]);
  state.players[0].hand = [basic("van-cost")];
  state._deck = [basic("van-draw"), trick("van-trick")];
  handleUseSkill(state, 1, "Văn Sách", 0, "van-cost");
  assert.equal(state.players[0].usedSkills.VanSach, true);
  assert.equal(state.players[0].hand.some((card) => card.id === "van-trick"), true);
  assert.equal(state.players[0].hand.length, 2);
}

{
  const state = game(["HERO_12", "HERO_1", "HERO_2", "HERO_3"]);
  state._deck = [basic("han-draw-1"), basic("han-draw-2"), basic("han-top")];
  executeCardEffect(state, trick("han-trick"), 1, 1);
  assert.equal(state.phase, "AWAIT_HAN_LAM");
  assert.equal(sanitizeGameStateForClient(state, 1).hanLamRevealedCard.id, "han-top");
  assert.equal(sanitizeGameStateForClient(state, 2).hanLamRevealedCard, null);
  assert.equal(sanitizeGameStateForClient(state, 1).lastAction.revealedCard.id, "han-top");
  assert.equal(sanitizeGameStateForClient(state, 2).lastAction.revealedCard, null, "Hán Lâm không được lộ lá cho người khác");
  handleRespondAction(state, 1, true, null);
  assert.equal(state.players[0].hand.some((card) => card.id === "han-top"), true, "Để trên cùng thì lá Hán Lâm phải được rút ngay");
  assert.equal(state.players[0].hand.length, 3);
  assert.notEqual(state.phase, "AWAIT_HAN_LAM", "Một lá Cẩm Nang chỉ kích hoạt Hán Lâm một lần");
}

{
  const state = game(["HERO_12", "HERO_1", "HERO_2", "HERO_3"]);
  state._deck = [basic("han-bottom"), basic("han-effect-1"), basic("han-effect-2"), basic("han-next"), basic("han-revealed")];
  executeCardEffect(state, trick("han-bottom-trick"), 1, 1);
  handleRespondAction(state, 1, false, null);
  assert.equal(state.players[0].hand.some((card) => card.id === "han-next"), true, "Đặt lá xem xuống đáy thì phải rút lá kế tiếp");
  assert.equal(state.players[0].hand.some((card) => card.id === "han-revealed"), false);
  assert.equal(state._deck[0]?.id, "han-revealed", "Lá đã xem phải nằm dưới đáy xấp rút");
}

{
  const state = game(["HERO_12", "HERO_1", "HERO_2", "HERO_3"]);
  const usedTrick = trick("nullified-trick");
  const nullify = { id: "nullify", name: "Diệu Kế Phá Mưu", suit: "Spade", rank: 11, category: CARD_CATEGORIES.INSTANT_SCROLL, subType: CARD_SUBTYPES.FLAWLESS_DEFENSE };
  state.players[0].hand = [usedTrick];
  state.players[1].hand = [nullify];
  handlePlayCard(state, 1, usedTrick.id, 1);
  assert.equal(state.phase, "AWAIT_NULLIFY");
  handleRespondAction(state, 2, true, nullify.id);
  assert.equal(state.actionHistory.some((action) => action.type === "HAN_LAM_PROMPT"), false, "Cẩm Nang bị hóa giải không được kích hoạt Hán Lâm");
}

console.log("[TEST PASS] Hero 9-12 skills");
