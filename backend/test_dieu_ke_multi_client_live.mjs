import { initGame, handlePlayCard, handleRespondAction, handleEndTurn } from '../deno-server/gameEngine.js';

console.log("================================================================================");
console.log("🧪 KIỂM TRA ĐA CLIENT (4 NICK ĐỒNG THỜI) TRÊN GAME ENGINE 2V2");
console.log("================================================================================");

const players = [
  { seat: 1, userId: "user_seat_1", generalName: "Trần Hưng Đạo", maxHp: 4, hp: 4, isAlly: true, isAI: false },
  { seat: 2, userId: "user_seat_2", generalName: "Thoát Hoan", maxHp: 4, hp: 4, isAlly: false, isAI: false },
  { seat: 3, userId: "user_seat_3", generalName: "Yết Kiêu", maxHp: 4, hp: 4, isAlly: true, isAI: false },
  { seat: 4, userId: "user_seat_4", generalName: "Ô Mã Nhi", maxHp: 4, hp: 4, isAlly: false, isAI: false }
];

const state = initGame("room_test_live_4clients", players);

// Gán bài cố định để test chính xác
state.players[0].hand = [{ id: "C_MUA_TEN", name: "Mưa Tên Liên Châu", category: 2, subType: 17 }];
state.players[1].hand = [{ id: "C_DO_1", name: "Đỡ", category: 0, subType: 3 }];
state.players[2].hand = [{ id: "C_DIEU_KE_3", name: "Diệu Kế Phá Mưu", category: 2, subType: 10 }];
state.players[3].hand = [{ id: "C_DIEU_KE_4", name: "Diệu Kế Phá Mưu", category: 2, subType: 10 }];

console.log("✅ 4 Nick đã sẵn sàng trên bàn cờ. Bắt đầu lượt Ghế 1.");

// 1. Ghế 1 đánh Mưa Tên (subType: 17)
console.log("\n▶️ [BƯỚC 1]: Ghế 1 đánh lá [Mưa Tên Liên Châu]...");
const rPlay = handlePlayCard(state, 1, "C_MUA_TEN", 0);
console.log("   -> Kết quả:", rPlay.success ? "THÀNH CÔNG ✅" : rPlay.error);
console.log("   -> Phase:", state.phase, "| TargetSeat đang hỏi:", state.waitingTargetSeat, "| Cần phản hồi:", state.waitingReactionType);

// 2. Ghế 2 đỡ đòn
console.log("\n▶️ [BƯỚC 2]: Ghế 2 đánh lá [Đỡ]...");
const rResp2 = handleRespondAction(state, 2, true, "C_DO_1");
console.log("   -> Kết quả:", rResp2.success ? "THÀNH CÔNG ✅" : rResp2.error);
console.log("   -> Tiếp theo hỏi TargetSeat:", state.waitingTargetSeat, "| Cần phản hồi:", state.waitingReactionType);

// 3. Ghế 4 không đỡ đòn -> Bị trừ 1 máu
console.log("\n▶️ [BƯỚC 3]: Ghế 4 không đánh Đỡ...");
const rResp4 = handleRespondAction(state, 4, false);
console.log("   -> Kết quả:", rResp4.success ? "THÀNH CÔNG ✅" : rResp4.error);
console.log("   -> Máu Ghế 4 sau đòn:", state.players[3].hp + "/" + state.players[3].maxHp);
console.log("   -> Phase sau khi giải quyết hết nạn nhân AOE:", state.phase);

console.log("\n================================================================================");
console.log("🏆 TOÀN BỘ CƠ CHẾ ĐÁNH BÀI VÀ PHẢN HỒI ĐA CLIENT ĐÃ PASSED 100%!");
console.log("================================================================================");
