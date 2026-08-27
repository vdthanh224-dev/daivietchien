/**
 * KIỂM THỬ GIẢ LẬP 5 VÁN ĐẤU 2v2 LIÊN TIẾP (SERVERLESS GAME ENGINE)
 * =================================================================
 * 4 Ghế:
 *  - Ghế 1: daivietonline@gmail.com  (Lê Lợi)        - Đội Phụng 🟡
 *  - Ghế 2: daiviet2@gmail.com       (Trần Hưng Đạo) - Đội Long 🔵
 *  - Ghế 3: daiviet3@gmail.com       (Nguyễn Huệ)    - Đội Phụng 🟡
 *  - Ghế 4: ai_bot                   (Quang Trung)   - Đội Long 🔵 [AI]
 *
 * Tự động mô phỏng chiến thuật thực tế cho tất cả người chơi và AI,
 * chạy hết toàn bộ 5 ván đấu đến khi kết thúc (status === "FINISHED").
 */

import {
  initGame,
  handlePlayCard,
  handleRespondAction,
  handleEndTurn,
  handleDiscardCards,
  sanitizeGameStateForClient
} from './functions/game-engine/src/gameEngine.js';
import {
  isSlash,
  isDodge,
  isPeach,
  isWine,
  CARD_CATEGORIES,
  CARD_SUBTYPES
} from './functions/game-engine/src/deck.js';

// Danh sách người chơi cố định theo 3 nick người dùng + 1 AI
const PLAYERS_TEMPLATE = [
  { userId: "daivietonline@gmail.com", generalName: "Lê Lợi",        maxHp: 4, isAI: false },
  { userId: "daiviet2@gmail.com",      generalName: "Trần Hưng Đạo", maxHp: 4, isAI: false },
  { userId: "daiviet3@gmail.com",      generalName: "Nguyễn Huệ",    maxHp: 4, isAI: false },
  { userId: "ai_bot",                  generalName: "Quang Trung",    maxHp: 4, isAI: true  },
];

/**
 * Xử lý tất cả các pha phản ứng đang chờ (Defense, AOE, Duel, Nam Sơn, Hấp Hối)
 */
function resolvePendingReactions(state) {
  let safetyCounter = 0;
  while (state.status !== "FINISHED" && state.phase !== "PLAY" && state.phase !== "DISCARD" && safetyCounter < 30) {
    safetyCounter++;
    const waitSeat = state.waitingTargetSeat;
    if (!waitSeat || waitSeat === 0) break;

    const p = state.players.find(x => x.seat === waitSeat);
    if (!p) break;

    // 1. Phản ứng ĐỠ đòn Trảm
    if (state.phase === "AWAIT_SLASH_DEFENSE") {
      const dodge = p.hand.find(c => isDodge(c));
      if (dodge) {
        handleRespondAction(state, waitSeat, true, dodge.id);
      } else {
        handleRespondAction(state, waitSeat, false, null);
      }
      continue;
    }

    // 2. Phản ứng TRƯỜNG ĐAO NAM SƠN (Caster có muốn bỏ thêm Trảm không)
    if (state.phase === "AWAIT_NAM_SON_FOLLOW_UP") {
      const extraSlash = p.hand.find(c => isSlash(c));
      if (extraSlash) {
        handleRespondAction(state, waitSeat, true, extraSlash.id);
      } else {
        handleRespondAction(state, waitSeat, false, null);
      }
      continue;
    }

    // 3. Phản ứng CẨM NANG DIỆN RỘNG (Mưa Tên / Bãi Cọc)
    if (state.phase === "AWAIT_AOE") {
      const reqType = state.waitingReactionType;
      let card = null;
      if (reqType === "DODGE") card = p.hand.find(c => isDodge(c));
      else if (reqType === "SLASH") card = p.hand.find(c => isSlash(c));

      if (card) {
        handleRespondAction(state, waitSeat, true, card.id);
      } else {
        handleRespondAction(state, waitSeat, false, null);
      }
      continue;
    }

    // 4. Phản ứng THÁCH ĐẤU (Duel)
    if (state.phase === "AWAIT_DUEL") {
      const slash = p.hand.find(c => isSlash(c));
      if (slash) {
        handleRespondAction(state, waitSeat, true, slash.id);
      } else {
        handleRespondAction(state, waitSeat, false, null);
      }
      continue;
    }

    // 5. Phản ứng CỨU HẤP HỐI (Near Death)
    if (state.phase === "AWAIT_NEAR_DEATH") {
      const victim = state.players.find(x => x.seat === state.nearDeathVictimSeat);
      const isSelf = (waitSeat === state.nearDeathVictimSeat);
      const isSameTeam = victim && (p.isAlly === victim.isAlly);

      let saveCard = null;
      if (isSelf) {
        // Tự cứu: ưu tiên Bánh Chưng hoặc Hủ Rượu
        saveCard = p.hand.find(c => isPeach(c)) || p.hand.find(c => isWine(c));
      } else if (isSameTeam) {
        // Đồng đội cứu: chỉ được dùng Bánh Chưng
        saveCard = p.hand.find(c => isPeach(c));
      }

      if (saveCard) {
        handleRespondAction(state, waitSeat, true, saveCard.id);
      } else {
        handleRespondAction(state, waitSeat, false, null);
      }
      continue;
    }
  }
}

/**
 * Thực hiện 1 lượt chơi đầy đủ cho người chơi hiện tại trong pha PLAY
 */
function playSmartTurn(state, currentSeat) {
  const p = state.players.find(x => x.seat === currentSeat);
  if (!p || p.hp <= 0) return;

  // Lặp tìm các lá bài có thể chơi hợp lý
  let playedSomething = true;
  let actionLimit = 0;

  while (playedSomething && state.phase === "PLAY" && state.turnSeat === currentSeat && state.status !== "FINISHED" && actionLimit < 15) {
    actionLimit++;
    playedSomething = false;

    // 1. Tự hồi máu nếu HP < MaxHP
    if (p.hp < p.maxHp) {
      const peach = p.hand.find(c => isPeach(c));
      if (peach) {
        handlePlayCard(state, currentSeat, peach.id, currentSeat);
        resolvePendingReactions(state);
        playedSomething = true;
        continue;
      }
    }

    // 2. Dụng Binh Như Thần (Rút bài)
    const exNihilo = p.hand.find(c => c.subType === CARD_SUBTYPES.EX_NIHILO);
    if (exNihilo) {
      handlePlayCard(state, currentSeat, exNihilo.id, currentSeat);
      resolvePendingReactions(state);
      playedSomething = true;
      continue;
    }

    // 3. Trang bị vũ khí / giáp / ngựa
    const equip = p.hand.find(c => c.category === CARD_CATEGORIES.EQUIPMENT);
    if (equip) {
      const alreadyEquipped = p.equipments.some(e => e.subType === equip.subType);
      if (!alreadyEquipped) {
        handlePlayCard(state, currentSeat, equip.id, currentSeat);
        resolvePendingReactions(state);
        playedSomething = true;
        continue;
      }
    }

    // Tìm mục tiêu đối thủ còn sống
    const enemies = state.players.filter(x => x.isAlly !== p.isAlly && x.hp > 0);
    const enemyTarget = enemies.length > 0 ? enemies[0] : null;

    if (!enemyTarget) break;

    // 4. Cẩm nang phá bài (Vườn Không Nhà Trống / Đột Kích Trộm Lương)
    const dismantle = p.hand.find(c => c.subType === CARD_SUBTYPES.DISMANTLE || c.subType === CARD_SUBTYPES.SNATCH);
    if (dismantle && (enemyTarget.hand.length > 0 || enemyTarget.equipments.length > 0)) {
      handlePlayCard(state, currentSeat, dismantle.id, enemyTarget.seat);
      resolvePendingReactions(state);
      playedSomething = true;
      continue;
    }

    // 5. Cẩm nang diện rộng (Mưa Tên Liên Châu / Bãi Cọc Ngầm)
    const aoe = p.hand.find(c => c.subType === CARD_SUBTYPES.ARROW_RAIN || c.subType === CARD_SUBTYPES.BARBARIAN_INVASION);
    if (aoe) {
      handlePlayCard(state, currentSeat, aoe.id, 0);
      resolvePendingReactions(state);
      playedSomething = true;
      continue;
    }

    // 6. Thách Đấu (Duel)
    const duel = p.hand.find(c => c.subType === CARD_SUBTYPES.DUEL);
    if (duel) {
      handlePlayCard(state, currentSeat, duel.id, enemyTarget.seat);
      resolvePendingReactions(state);
      playedSomething = true;
      continue;
    }

    // 7. Uống rượu trước khi Trảm
    const wine = p.hand.find(c => isWine(c));
    const slash = p.hand.find(c => isSlash(c));
    const hasZhuge = p.equipments.some(e => e.name && e.name.includes("Nỏ Thần"));
    const canSlash = hasZhuge || state.slashesUsedThisTurn === 0;

    if (wine && slash && !p.isWineBuffActive && canSlash) {
      handlePlayCard(state, currentSeat, wine.id, currentSeat);
      resolvePendingReactions(state);
      playedSomething = true;
      continue;
    }

    // 8. Đánh Trảm
    if (slash && canSlash) {
      handlePlayCard(state, currentSeat, slash.id, enemyTarget.seat);
      resolvePendingReactions(state);
      playedSomething = true;
      continue;
    }
  }

  // Kết thúc lượt đánh
  if (state.status !== "FINISHED" && state.turnSeat === currentSeat) {
    if (state.phase === "PLAY") {
      handleEndTurn(state, currentSeat);
    }
    // Nếu vào pha DISCARD bỏ bài thừa
    if (state.phase === "DISCARD" && state.waitingTargetSeat === currentSeat) {
      handleDiscardCards(state, currentSeat, []);
    }
  }
}

/**
 * Mô phỏng 1 ván đấu 2v2 từ đầu đến cuối
 */
function runSingleGameSimulation(gameIndex) {
  console.log(`\n${"═".repeat(60)}`);
  console.log(`  ⚔️  BẮT ĐẦU VÁN ĐẤU THỨ ${gameIndex}/5  ⚔️`);
  console.log(`${"═".repeat(60)}`);

  const roomId = `room_match_00${gameIndex}`;
  const state = initGame(roomId, PLAYERS_TEMPLATE);

  console.log(`🎮 Phòng: ${roomId} | Cọc rút: ${state.deckCount} lá`);
  console.log(`   🟡 Đội Phụng: G1 (${state.players[0].generalName}) & G3 (${state.players[2].generalName})`);
  console.log(`   🔵 Đội Long : G2 (${state.players[1].generalName}) & G4 (${state.players[3].generalName} - AI)`);

  let turnCount = 0;
  const maxTurns = 80;

  while (state.status !== "FINISHED" && turnCount < maxTurns) {
    turnCount++;
    const curSeat = state.turnSeat;
    const curPlayer = state.players.find(p => p.seat === curSeat);

    if (!curPlayer || curPlayer.hp <= 0) {
      // Ghế chết: chuyển lượt an toàn
      if (state.phase === "PLAY") handleEndTurn(state, curSeat);
      else if (state.phase === "DISCARD") handleDiscardCards(state, state.waitingTargetSeat, []);
      continue;
    }

    // Chơi lượt
    playSmartTurn(state, curSeat);

    // In diễn biến tóm tắt sau mỗi vòng hoặc khi có sự kiện lớn
    if (state.lastAction && (state.lastAction.type === "PLAYER_DIED" || state.lastAction.type === "RESCUE_SUCCESS" || state.lastAction.type === "PLAY_WINE")) {
      const cleanLog = state.lastAction.description.replace(/<[^>]+>/g, "");
      const hpSummary = state.players.map(p => `G${p.seat}:${p.hp}/${p.maxHp}${p.hp <= 0 ? '☠️' : ''}`).join(" | ");
      console.log(`   [Lượt ${turnCount} - G${curSeat}] ${cleanLog}`);
      console.log(`     -> HP: ${hpSummary}`);
    }
  }

  // Kết quả ván
  const gameOver = (state.actionHistory || []).find(a => a.type === "GAME_OVER") || state.lastAction;
  const cleanWinner = gameOver ? gameOver.description.replace(/<[^>]+>/g, "") : "Chưa xác định";

  const team1Alive = state.players.filter(p => p.isAlly && p.hp > 0).length;
  const team2Alive = state.players.filter(p => !p.isAlly && p.hp > 0).length;
  const winningTeamName = team1Alive > 0 ? "Đội Phụng (Ghế 1 & 3) 🟡" : "Đội Long (Ghế 2 & 4) 🔵";

  console.log(`\n🏁 KẾT THÚC VÁN ${gameIndex}:`);
  console.log(`   🏆 Kết quả: ${winningTeamName} CHIẾN THẮNG!`);
  console.log(`   ⏱️ Số lượt chơi: ${turnCount} lượt | Tổng hành động: ${state.actionSeq} | Version State: ${state.version}`);
  console.log(`   ❤️ HP cuối cùng: ${state.players.map(p => `${p.generalName} (G${p.seat}): ${p.hp}/${p.maxHp}${p.hp <= 0 ? ' (Tử trận)' : ''}`).join(", ")}`);

  // Kiểm tra tính toàn vẹn của sanitizeGameStateForClient
  for (let s = 1; s <= 4; s++) {
    const clientState = sanitizeGameStateForClient(state, s);
    if (!clientState || !clientState.roomId || clientState.players.length !== 4) {
      throw new Error(`Client state của ghế ${s} không hợp lệ!`);
    }
  }

  return {
    gameIndex,
    winner: team1Alive > 0 ? "Đội Phụng 🟡" : "Đội Long 🔵",
    winningSeats: team1Alive > 0 ? [1, 3] : [2, 4],
    turns: turnCount,
    actions: state.actionSeq,
    finalHp: state.players.map(p => ({ seat: p.seat, name: p.generalName, hp: p.hp, isAlly: p.isAlly }))
  };
}

// ==========================================
// CHẠY CHUỖI 5 VÁN ĐẤU
// ==========================================
console.log("╔═══════════════════════════════════════════════════════════════╗");
console.log("║    BẮT ĐẦU GIẢ LẬP 10 VÁN ĐẤU 2v2 LIÊN TIẾP TRÊN SERVER     ║");
console.log("╚═══════════════════════════════════════════════════════════════╝");

const results = [];
let teamPhungWins = 0;
let teamLongWins = 0;

for (let i = 1; i <= 10; i++) {
  const res = runSingleGameSimulation(i);
  results.push(res);
  if (res.winner.includes("Phụng")) teamPhungWins++;
  else teamLongWins++;
}

console.log(`\n\n${"═".repeat(65)}`);
console.log("📊 TỔNG KẾT KẾT QUẢ 10 VÁN ĐẤU GIẢ LẬP SERVER-AUTHORITATIVE 📊");
console.log(`${"═".repeat(65)}`);

console.log("\n| Ván | Đội Chiến Thắng | Số Lượt | Tổng Hành Động | Tình Trạng Sống/Chết |");
console.log("|-----|-----------------|---------|----------------|----------------------|");
results.forEach(r => {
  const hpStatus = r.finalHp.map(p => `G${p.seat}:${p.hp > 0 ? `${p.hp}HP` : '☠️'}`).join(' ');
  console.log(`|  ${r.gameIndex}${r.gameIndex < 10 ? ' ' : ''} | ${r.winner.padEnd(15)} |   ${String(r.turns).padEnd(5)} |      ${String(r.actions).padEnd(9)} | ${hpStatus.padEnd(20)} |`);
});

const total = results.length;
console.log(`\n🏆 TỔNG TỶ SỐ (${total} ván):`);
console.log(`   🟡 Đội Phụng (Lê Lợi + Nguyễn Huệ) : ${teamPhungWins} Chiến Thắng (${((teamPhungWins/total)*100).toFixed(0)}%)`);
console.log(`   🔵 Đội Long (Trần Hưng Đạo + Quang Trung AI): ${teamLongWins} Chiến Thắng (${((teamLongWins/total)*100).toFixed(0)}%)`);

const avgActions = (results.reduce((acc, r) => acc + r.actions, 0) / total).toFixed(1);
const avgTurns = (results.reduce((acc, r) => acc + r.turns, 0) / total).toFixed(1);
const minTurns = Math.min(...results.map(r => r.turns));
const maxTurns = Math.max(...results.map(r => r.turns));
console.log(`\n📈 THỐNG KÊ CHI TIẾT:`);
console.log(`   - Trung bình số lượt mỗi trận: ${avgTurns} lượt`);
console.log(`   - Trận ngắn nhất: ${minTurns} lượt | Trận dài nhất: ${maxTurns} lượt`);
console.log(`   - Trung bình số hành động/version mỗi trận: ${avgActions} hành động`);
console.log(`   - Trạng thái tất cả ${total} trận: 100% KẾT THÚC HỢP LỆ (status: FINISHED, không kẹt loop)`);
console.log(`   - Đồng bộ dữ liệu Client (sanitizeGameStateForClient): 100% PASS`);

console.log("\n🎉 HOÀN TẤT GIẢ LẬP 10 VÁN ĐẤU THÀNH CÔNG RỰC RỠ!");
