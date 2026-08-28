/**
 * GIẢ LẬP TRẬN ĐẤU ĐẦY ĐỦ 2v2 - 3 Nick Người Chơi + 1 AI
 * ============================================================
 * Ghế 1: daivietonline@gmail.com  (Lê Lợi)        - Đội Phụng 🟡
 * Ghế 2: daiviet2@gmail.com       (Trần Hưng Đạo) - Đội Long 🔵
 * Ghế 3: daiviet3@gmail.com       (Nguyễn Huệ)    - Đội Phụng 🟡
 * Ghế 4: ai_bot                   (Quang Trung)   - Đội Long 🔵 [AI]
 *
 * Kịch bản:
 *  Lượt 1 (G1): Uống Rượu → Trảm G2 (damage 2) → G2 Đỡ
 *  Lượt 2 (G2): Bãi Cọc Ngầm → G1 Trảm né, G3 không Trảm mất máu (1→0) → HẤP HỐI
 *    Hấp hối: Hỏi G2(lượt) → G3(nạn nhân) → G4 → G1 → G3 tự cứu bằng Bánh Chưng
 *  Lượt 3 (G3): Thách Đấu G4 → G4 không Trảm → G4 mất máu (2→1)
 *  Lượt 4 (G4 AI): AI Trảm G1 → G1 chịu đòn (4→3)
 *  Lượt 5 (G1): Trảm G2 → G2 không Đỡ (3→2)
 *  Lượt 6 (G2): Trảm G3 → G3 Đỡ
 *  Lượt 7 (G3): Trảm G2 → G2 chịu (2→1)
 *  Lượt 8 (G4 AI): AI Trảm G3 → G3 chịu (1→0) → HẤP HỐI → không ai cứu → G3 chết
 *  ...Tiếp tục đến khi 1 đội toàn thua
 */

import {
  initGame,
  handlePlayCard,
  handleRespondAction,
  handleEndTurn,
  handleDiscardCards,
  handleAIStep,
  sanitizeGameStateForClient
} from './functions/game-engine/src/gameEngine.js';
import { CARD_SUBTYPES } from './functions/game-engine/src/deck.js';

// ===== UTILS =====

let stepNum = 0;
function step(title) {
  stepNum++;
  console.log(`\n  [B${String(stepNum).padStart(2,'0')}] ${title}`);
}
function hp(state) {
  return state.players.map(p =>
    `G${p.seat}:${p.hp}/${p.maxHp}${p.hp<=0?' ☠️':''}${p.isWineBuffActive?'🍶':''}`
  ).join('  ');
}
function log(state) {
  const desc = state.lastAction.description.replace(/<[^>]+>/g,'');
  console.log(`       HP: ${hp(state)}`);
  console.log(`       Pha: ${state.phase}  WaitSeat: ${state.waitingTargetSeat}  Lượt: G${state.turnSeat}`);
  console.log(`       Log: ${desc}`);
}
function assert(cond, msg) {
  if (!cond) { console.error(`\n❌ ASSERT THẤT BẠI: ${msg}`); process.exit(1); }
}
function resolveNullify(state) {
  while (state.phase === "AWAIT_NULLIFY") {
    handleRespondAction(state, state.waitingTargetSeat, false, null);
  }
}
// Tạo lá bài nhanh
const C = (id, name, suit, rank, cat, sub) => ({id,name,suit,rank,category:cat,subType:sub});
const SLASH  = (id) => C(id, "Trảm Thường", "Club", 9, 0, CARD_SUBTYPES.ATTACK_NORMAL);
const DODGE  = (id) => C(id, "Đỡ", "Diamond", 5, 0, CARD_SUBTYPES.DODGE);
const PEACH  = (id) => C(id, "Bánh Chưng", "Heart", 7, 0, CARD_SUBTYPES.PEACH);
const WINE   = (id) => C(id, "Hủ Rượu", "Club", 11, 0, CARD_SUBTYPES.WINE);
const EX     = (id) => C(id, "Dụng Binh Như Thần", "Heart", 3, 2, CARD_SUBTYPES.EX_NIHILO);
const BAI_COC= (id) => C(id, "Bãi Cọc Ngầm", "Club", 2, 2, CARD_SUBTYPES.BARBARIAN_INVASION);
const DUEL   = (id) => C(id, "Thách Đấu", "Club", 3, 2, CARD_SUBTYPES.DUEL);

// ===== KHỞI TẠO =====
console.log("\n╔══════════════════════════════════════════════════════╗");
console.log("║  GIẢ LẬP 2v2: 3 Nick Người Chơi + 1 AI (Full Flow)  ║");
console.log("╚══════════════════════════════════════════════════════╝");

const players = [
  { userId: "daivietonline@gmail.com", generalName: "Lê Lợi",        maxHp: 4, isAI: false },
  { userId: "daiviet2@gmail.com",      generalName: "Trần Hưng Đạo", maxHp: 4, isAI: false },
  { userId: "daiviet3@gmail.com",      generalName: "Nguyễn Huệ",    maxHp: 4, isAI: false },
  { userId: "ai_bot",                  generalName: "Quang Trung",    maxHp: 4, isAI: true  },
];

const state = initGame("room_sim_01", players);


const [p1,p2,p3,p4] = state.players;

console.log(`\n  Đội Phụng 🟡: G1 ${p1.generalName} (daivietonline)  |  G3 ${p3.generalName} (daiviet3)`);
console.log(`  Đội Long  🔵: G2 ${p2.generalName} (daiviet2)  |  G4 ${p4.generalName} [AI]`);
console.log(`  Cọc rút: ${state.deckCount} lá  |  Lượt đầu: Ghế ${state.turnSeat}`);

// ═══════════════════════════════════════════
// LƯỢT 1 — LÊ LỢI (G1) 🟡
// ═══════════════════════════════════════════
console.log("\n\n══ LƯỢT 1 — Lê Lợi (G1) [Đội Phụng 🟡] ══");
p1.hand = [WINE("w1"), SLASH("s1"), DODGE("d1"), PEACH("pc1")];
p2.hand = [DODGE("d2"), SLASH("s2"), BAI_COC("bc1"), EX("ex1")];
p3.hand = [DODGE("d3"), DODGE("d3b"), PEACH("pc3"), DUEL("duel3")];
p4.hand = [SLASH("s4"), DODGE("d4"), EX("ex4")];
p3.hp = 1; // Dễ vào Hấp Hối ở lượt 2

step("G1 uống [Hủ Rượu] → bùa +1 công");
handlePlayCard(state, 1, "w1", 1);
log(state);
assert(p1.isWineBuffActive, "G1 phải có bùa Rượu");

step("G1 Trảm G2 — Hủ Rượu → damage phải là 2");
handlePlayCard(state, 1, "s1", 2);
log(state);
assert(state.phase === "AWAIT_SLASH_DEFENSE", "Phase: AWAIT_SLASH_DEFENSE");
assert(state.activeCard.damage === 2, `Damage phải 2, nhận: ${state.activeCard.damage}`);
console.log(`       💡 G2 có 40s để Đỡ (damage = ${state.activeCard.damage})`);

step("G2 Đỡ bằng [Đỡ]");
handleRespondAction(state, 2, true, "d2");
log(state);
assert(state.phase === "PLAY" && p2.hp === 4, "G2 phải đỡ được, vẫn 4 máu");
console.log(`       ✅ G2 Đỡ thành công — HP G2: ${p2.hp}/4`);

step("G1 kết thúc lượt");
handleEndTurn(state, 1);
log(state);
assert(state.turnSeat === 2, "Đến lượt G2");

// ═══════════════════════════════════════════
// LƯỢT 2 — TRẦN HƯNG ĐẠO (G2) 🔵
// ═══════════════════════════════════════════
console.log("\n\n══ LƯỢT 2 — Trần Hưng Đạo (G2) [Đội Long 🔵] ══");
p2.hand = [BAI_COC("bc2"), SLASH("s2b"), EX("ex2")];

step("G2 tung [Bãi Cọc Ngầm] — AOE tất cả đối thủ phải Trảm hoặc mất máu");
handlePlayCard(state, 2, "bc2", 0);
log(state);

// Cẩm nang diện rộng first opens the server-authoritative nullify window.
// Resolve each seat's pass explicitly before handling the victim queue.
while (state.phase === "AWAIT_NULLIFY") {
  const who = state.waitingTargetSeat;
  step(`G${who} kiểm tra Diệu Kế Phá Mưu → bỏ qua`);
  handleRespondAction(state, who, false, null);
  log(state);
}
assert(state.phase === "AWAIT_AOE", "Phase: AWAIT_AOE");
console.log(`       Hỏi AOE theo thứ tự: G${state.waitingTargetSeat} đầu tiên...`);

// G3 đến trước (seat 3 = đối thủ của G2 đứng kế bên)
while (state.phase === "AWAIT_AOE") {
  const who = state.waitingTargetSeat;
  const wp  = state.players.find(p => p.seat === who);
  const hasSlash = wp.hand.some(c => c.subType === CARD_SUBTYPES.ATTACK_NORMAL || c.subType === CARD_SUBTYPES.ATTACK_THUNDER || c.subType === CARD_SUBTYPES.ATTACK_FIRE);

  if (who === 3) {
    // G3 chỉ còn 1 máu, không có Trảm → mất máu → Hấp Hối
    step(`G3 (${wp.generalName}) không có Trảm → chịu 1 sát thương (${wp.hp} → ${wp.hp-1})`);
    handleRespondAction(state, who, false, null);
  } else if (who === 1 && hasSlash) {
    // G1 có Trảm → né
    const sl = p1.hand.find(c => c.subType === CARD_SUBTYPES.ATTACK_NORMAL);
    if (sl) {
      step(`G1 (${wp.generalName}) ra Trảm hóa giải Bãi Cọc`);
      handleRespondAction(state, who, true, sl.id);
    } else {
      step(`G1 không còn Trảm → chịu 1 sát thương`);
      handleRespondAction(state, who, false, null);
    }
  } else {
    step(`G${who} (${wp.generalName}) không có Trảm → chịu 1 sát thương`);
    handleRespondAction(state, who, false, null);
  }
  log(state);

  if (state.phase === "AWAIT_NEAR_DEATH") {
    console.log(`\n       ⚠️ G3 (Nguyễn Huệ) HẤP HỐI! (0 máu)`);
    break;
  }
}

// ─── Xử lý Hấp Hối G3 ───
if (state.phase === "AWAIT_NEAR_DEATH") {
  console.log(`\n  ⚡ PHA HẤP HỐI — Nguyễn Huệ (G3) 0 máu`);
  console.log(`     Thứ tự hỏi cứu: bắt đầu từ G${state.waitingTargetSeat} (người trong lượt G2)`);
  const rescueOrder = [];
  while (state.phase === "AWAIT_NEAR_DEATH") {
    const asker = state.waitingTargetSeat;
    const ap    = state.players.find(p => p.seat === asker);
    rescueOrder.push(asker);

    if (asker === 3) {
      // G3 (nạn nhân) tự cứu bằng Bánh Chưng
      const pc = p3.hand.find(c => c.subType === CARD_SUBTYPES.PEACH);
      if (pc) {
        step(`G3 (Nguyễn Huệ) tự cứu bằng [Bánh Chưng]`);
        handleRespondAction(state, 3, true, pc.id);
        console.log(`       ✅ G3 được cứu! HP: ${p3.hp}/4`);
      } else {
        step(`G3 không có Bánh Chưng → bỏ qua`);
        handleRespondAction(state, 3, false, null);
      }
    } else {
      step(`G${asker} (${ap?.generalName}) từ chối cứu G3`);
      handleRespondAction(state, asker, false, null);
    }
    log(state);
  }
  console.log(`     Thứ tự đã hỏi: ${rescueOrder.join(' → ')} ✅`);
  // Xác nhận thứ tự đúng (bắt từ G2 = người trong lượt)
  assert(rescueOrder[0] === 2, `Người đầu tiên được hỏi phải là G2 (người trong lượt), nhận: G${rescueOrder[0]}`);
}

// Tiếp AOE còn lại nếu có
while (state.phase === "AWAIT_AOE") {
  const who = state.waitingTargetSeat;
  step(`G${who} xử lý AOE tiếp theo → chịu đòn`);
  handleRespondAction(state, who, false, null);
  log(state);
}

assert(p3.hp >= 1, `G3 phải được cứu sống (HP: ${p3.hp})`);

step("G2 kết thúc lượt");
handleEndTurn(state, 2);
log(state);
assert(state.turnSeat === 3, "Đến lượt G3");

// ═══════════════════════════════════════════
// LƯỢT 3 — NGUYỄN HUỆ (G3) 🟡
// ═══════════════════════════════════════════
console.log("\n\n══ LƯỢT 3 — Nguyễn Huệ (G3) [Đội Phụng 🟡] ══");
p3.hand = [DUEL("duel3b"), SLASH("s3"), PEACH("pc3b")];
p4.hp = 2; // G4 còn 2 máu

step("G3 phát động [Thách Đấu] nhắm G4 (AI) — G4 không có Trảm");
p4.hand = [DODGE("d4b")]; // AI chỉ có Đỡ, không có Trảm → thua Thách Đấu
handlePlayCard(state, 3, "duel3b", 4);
log(state);
resolveNullify(state);
assert(state.phase === "AWAIT_DUEL", "Phase: AWAIT_DUEL");

step("G4 (AI Quang Trung) không có Trảm → từ chối → mất 1 máu");
handleRespondAction(state, 4, false, null);
log(state);
console.log(`       Quang Trung HP sau Thách Đấu: ${p4.hp}/4`);

// Nếu G4 vào Hấp Hối
if (state.phase === "AWAIT_NEAR_DEATH") {
  console.log(`\n       ⚠️ G4 (Quang Trung) HẤP HỐI!`);
  while (state.phase === "AWAIT_NEAR_DEATH") {
    const asker = state.waitingTargetSeat;
    step(`Hỏi G${asker} cứu G4 → không ai có Bánh Chưng → bỏ qua`);
    handleRespondAction(state, asker, false, null);
    log(state);
  }
  if (p4.hp <= 0) console.log(`       ☠️ Quang Trung tử trận!`);
}

step("G3 kết thúc lượt");
handleEndTurn(state, 3);
log(state);

// ═══════════════════════════════════════════
// LƯỢT 4+ — AUTO PLAY ĐẾN KẾT THÚC
// ═══════════════════════════════════════════
console.log("\n\n══ CÁC LƯỢT TIẾP THEO (TỰ ĐỘNG) ══");
let autoRound = 0;
while (state.status !== "FINISHED" && autoRound < 25) {
  autoRound++;
  const cur = state.turnSeat;
  const cp  = state.players.find(p => p.seat === cur);
  if (!cp || cp.hp <= 0) {
    // Ghế chết: không gọi handleEndTurn, getNextAliveSeat sẽ tự bỏ qua
    // Nhưng state.turnSeat có thể không tự cập nhật → dùng handleEndTurn an toàn
    if (state.phase === "PLAY") handleEndTurn(state, cur);
    else break;
    continue;
  }
  console.log(`\n  [Auto-${autoRound}] Lượt G${cur} (${cp.generalName}) — HP: ${cp.hp}`);

  // Xử lý pha DISCARD trước nếu đang chờ
  if (state.phase === "DISCARD" && state.waitingTargetSeat === cur) {
    // Gọi handleDiscardCards với mảng rỗng: server tự bỏ bài thừa
    handleDiscardCards(state, cur, []);
    const hpStr2 = state.players.map(p=>`G${p.seat}:${p.hp>0?p.hp:' ☠️'}`).join(' | ');
    console.log(`       (Bỏ bài thừa) ${hpStr2} | Phase: ${state.phase}`);
    continue;
  }

  if (cp.isAI) {
    // AI: cấp Trảm để tấn công
    const enemy = state.players.find(p => (p.isAlly !== cp.isAlly) && p.hp > 0);
    if (enemy) {
      cp.hand = [SLASH(`ai_auto_${autoRound}`)];
    } else {
      cp.hand = [PEACH(`ai_pc_${autoRound}`)];
    }
    handleAIStep(state, cur);
  } else {
    // Người chơi: tấn công đối thủ đối diện
    const enemy = state.players.find(p => (p.isAlly !== cp.isAlly) && p.hp > 0);
    if (enemy) {
      const sid = `user_auto_${autoRound}`;
      cp.hand = [SLASH(sid)];
      handlePlayCard(state, cur, sid, enemy.seat);
    }
  }

  // Resolve server reaction windows before advancing the scripted turn.
  while (state.phase !== "PLAY" && state.status !== "FINISHED") {
    if (state.phase === "AWAIT_NULLIFY" || state.phase === "AWAIT_SLASH_DEFENSE"
      || state.phase === "AWAIT_AOE" || state.phase === "AWAIT_DUEL"
      || state.phase === "AWAIT_NAM_SON_FOLLOW_UP" || state.phase === "AWAIT_NEAR_DEATH") {
      handleRespondAction(state, state.waitingTargetSeat, false, null);
    } else {
      break;
    }
  }
  if (state.status === "FINISHED") break;
  if (state.phase === "DISCARD") {
    handleDiscardCards(state, state.waitingTargetSeat, []);
  } else if (state.phase === "PLAY" && state.turnSeat === cur) {
    handleEndTurn(state, cur);
  }

  const hpStr = state.players.map(p => `G${p.seat}:${p.hp>0?p.hp:' ☠️'}`).join(' | ');
  console.log(`       ${hpStr} | Phase: ${state.phase}`);
  if (state.status === "FINISHED") break;
}

// ═══════════════════════════════════════════
// KẾT QUẢ CUỐI CÙNG
// ═══════════════════════════════════════════
console.log("\n\n╔══════════════════════════════════════════════════════╗");
console.log("║                  KẾT QUẢ TRẬN ĐẤU                   ║");
console.log("╚══════════════════════════════════════════════════════╝");
console.log(`  Trạng thái: ${state.status}`);
console.log(`  State version: ${state.version}  |  Tổng hành động: ${state.actionSeq}`);
state.players.forEach(p => {
  const team = p.isAlly ? "Đội Phụng 🟡" : "Đội Long 🔵";
  const nick = players.find(x => x.generalName === p.generalName)?.userId || p.userId;
  console.log(`  G${p.seat} | ${p.generalName.padEnd(16)} | ${team} | HP: ${p.hp}/${p.maxHp} ${p.hp>0?'✅':'☠️'} | (${nick})`);
});

const gameOverAction = (state.actionHistory||[]).find(a=>a.type==="GAME_OVER");
if (gameOverAction) {
  const clean = gameOverAction.description.replace(/<[^>]+>/g,'');
  console.log(`\n  🏆 ${clean}`);
}

console.log("\n  📜 LỊCH SỬ HÀNH ĐỘNG (10 bước gần nhất):");
(state.actionHistory||[]).slice(-10).forEach(a => {
  const d = a.description.replace(/<[^>]+>/g,'');
  console.log(`    [seq${String(a.seq).padStart(3,'0')}] ${a.type.padEnd(28)} ${d.substring(0,80)}`);
});

const cs1 = sanitizeGameStateForClient(state, 1);
const cs2 = sanitizeGameStateForClient(state, 2);
console.log(`\n  📦 State gửi về các Client:`);
console.log(`    G1 (daivietonline): version=${cs1.version}, tay=${cs1.players.find(p=>p.seat===1)?.handCount} lá, JSON=${(JSON.stringify(cs1).length/1024).toFixed(1)}KB`);
console.log(`    G2 (daiviet2)     : version=${cs2.version}, tay=${cs2.players.find(p=>p.seat===2)?.handCount} lá`);
console.log(`    actionHistory gửi về: ${cs1.actionHistory.length} hành động`);

if (state.status === "FINISHED") {
  console.log("\n✅ GIẢ LẬP HOÀN THÀNH — TRẬN ĐẤU KẾT THÚC ĐÚNG LUẬT!");
} else {
  console.log(`\n⚠️  Trận chưa kết thúc sau ${autoRound} lượt auto (phase: ${state.phase})`);
}
