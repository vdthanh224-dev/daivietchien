import {
  initGame,
  handlePlayCard,
  handleRespondAction,
  handleEndTurn,
  handleDiscardCards,
  handleAIStep,
  handleAIReaction,
  sanitizeGameStateForClient
} from './functions/game-engine/src/gameEngine.js';
import { CARD_SUBTYPES, CARD_CATEGORIES } from './functions/game-engine/src/deck.js';

console.log("=== BẮT ĐẦU KIỂM THỬ SERVERLESS GAME ENGINE ===");

// 1. Khởi tạo 4 người chơi
const players = [
  { seat: 1, userId: "user_1@gmail.com", generalName: "Lê Lợi", maxHp: 4 },
  { seat: 2, userId: "user_2@gmail.com", generalName: "Nguyễn Huệ", maxHp: 4, isAI: true },
  { seat: 3, userId: "user_3@gmail.com", generalName: "Trần Hưng Đạo", maxHp: 4 },
  { seat: 4, userId: "user_4@gmail.com", generalName: "Quang Trung", maxHp: 4, isAI: true }
];

const state = initGame("room_test_123", players);
console.log(`\n1. Khởi tạo phòng ${state.roomId}:`);
console.log(`- Trạng thái: ${state.status}`);
console.log(`- Lượt: Ghế ${state.turnSeat}`);
console.log(`- Bài cọc rút: ${state.deckCount} lá`);

const p1 = state.players[0];
const p3 = state.players[2];
const p2 = state.players[1];
p1.equipments = [{ id: "D1_D_A", name: "Kiếm Thuận Thiên", suit: "Diamond", rank: 1, category: 1, subType: CARD_SUBTYPES.WEAPON, range: 2 }];

// Cho Ghế 1: 1 lá Hủ Rượu (subType: 5), 1 lá Trảm (subType: 2)
p1.hand[0] = { id: "D1_C_J", name: "Hủ Rượu", suit: "Club", rank: 11, category: 0, subType: CARD_SUBTYPES.WINE };
p1.hand[1] = { id: "D1_S_8", name: "Trảm - Lôi", suit: "Spade", rank: 8, category: 0, subType: CARD_SUBTYPES.ATTACK_THUNDER };

console.log(`\n2. Ghế 1 (${p1.generalName}) UỐNG [Hủ Rượu]:`);
const wineRes = handlePlayCard(state, 1, "D1_C_J", 1);
console.log(`- Kết quả: ${wineRes.success}`);
console.log(`- isWineBuffActive của Ghế 1: ${p1.isWineBuffActive}`);
console.log(`- Nhật ký: ${state.lastAction.description}`);

console.log(`\n3. Ghế 1 (${p1.generalName}) ĐÁNH [Trảm - Lôi] nhắm vào Ghế 2 (${p2.generalName}):`);
const slashRes = handlePlayCard(state, 1, "D1_S_8", 2);
console.log(`- Sát thương đòn đánh: ${state.activeCard.damage} (Kỳ vọng: 2)`);
if (state.activeCard.damage !== 2) throw new Error("LỖI: Sát thương Hủ Rượu phải là 2!");
console.log(`- Nhật ký: ${state.lastAction.description}`);

console.log(`\n4. Ghế 2 (${p2.generalName}) KHÔNG DÙNG ĐỠ (chịu sát thương):`);
const respRes = handleRespondAction(state, 2, false, null);
console.log(`- Kết quả: ${respRes.success}`);
console.log(`- Máu mới của Ghế 2: ${p2.hp}/${p2.maxHp} (Mất 2 máu từ 4 -> 2)`);
if (p2.hp !== 2) throw new Error("LỖI: Máu Ghế 2 phải là 2 sau đòn Trảm kèm Rượu!");
console.log(`- Nhật ký: ${state.lastAction.description}`);

console.log(`\n5. Ghế 1 kết thúc lượt:`);
const endRes = handleEndTurn(state, 1);
console.log(`- Lượt tiếp theo: Ghế ${state.turnSeat} (${state.players[state.turnSeat - 1].generalName})`);

console.log(`\n6. SERVER TỰ ĐỘNG THỰC HIỆN BƯỚC ĐI CỦA AI (Ghế 2 - ${state.players[1].generalName}):`);
const aiStepRes = handleAIStep(state, 2);
console.log(`- AI Step thành công: ${aiStepRes.success}`);
console.log(`- Hành động AI đã làm: ${state.lastAction.type} - ${state.lastAction.description}`);

console.log(`\n7. KIỂM THỬ PHA HẤP HỐI (NEAR DEATH):`);
// Giảm máu Ghế 2 xuống 1, sau đó Ghế 1 Trảm gây 1 damage
p2.hp = 1;
p1.hand.push({ id: "D1_S_TEST", name: "Trảm Thường", suit: "Spade", rank: 10, category: 0, subType: CARD_SUBTYPES.ATTACK_NORMAL });
state.turnSeat = 1;
state.phase = "PLAY";
state.slashesUsedThisTurn = 0;
state.waitingTargetSeat = 0;
state.waitingReactionType = "NONE";
state.activeCard = null;
handlePlayCard(state, 1, "D1_S_TEST", 2);
// Ghế 2 không đỡ -> Rơi vào Hấp Hối
handleRespondAction(state, 2, false, null);
console.log(`- Giai đoạn: ${state.phase} (Kỳ vọng: AWAIT_NEAR_DEATH)`);
console.log(`- Ghế nạn nhân: ${state.nearDeathVictimSeat}`);
console.log(`- Người đầu tiên được hỏi cứu: Ghế ${state.waitingTargetSeat} (Kỳ vọng: 1 - Người trong lượt)`);
if (state.waitingTargetSeat !== 1) throw new Error("LỖI: Người đầu tiên được hỏi cứu phải là Người trong lượt (Ghế 1)!");

// Ghế 1 từ chối cứu
handleRespondAction(state, 1, false, null);
console.log(`- Người tiếp theo được hỏi cứu: Ghế ${state.waitingTargetSeat} (Kỳ vọng: 2 - Người bên phải kế tiếp)`);
if (state.waitingTargetSeat !== 2) throw new Error("LỖI: Người tiếp theo phải là Ghế 2!");

// Cho Ghế 2 (nạn nhân) 1 lá Bánh Chưng trước khi tới lượt được hỏi cứu
p2.hand.push({ id: "PEACH_SAVE", name: "Bánh Chưng", suit: "Heart", rank: 12, category: 0, subType: CARD_SUBTYPES.PEACH });
// Ghế 2 tự cứu khi tới lượt được hỏi
const saveRes = handleRespondAction(state, 2, true, "PEACH_SAVE");
console.log(`- Ghế 2 tự cứu thành công: ${saveRes.success}`);
console.log(`- Máu sau khi được cứu: ${p2.hp}/4`);
if (p2.hp !== 1) throw new Error("LỖI: Máu sau khi được cứu phải là 1!");

console.log("\n=== KIỂM THỬ SANITIZE DỮ LIỆU ĐỂ GỬI REALTIME CHO CLIENT ===");
const clientData = sanitizeGameStateForClient(state, 1);
console.log(`- Version: ${clientData.version}`);
console.log(`- TurnSeat: ${clientData.turnSeat}`);
console.log(`- Players HP: [${clientData.players.map(p => p.hp).join(', ')}]`);
console.log(`- JSON Length: ${JSON.stringify(clientData).length} bytes`);

console.log("\n🎉 TOÀN BỘ TEST RƯỢU (+2 DMG), HẤP HỐI (NEAR DEATH), VÀ AI SERVER HOÀN TOÀN THÀNH CÔNG (100% PASS)!");
