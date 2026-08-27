import { createDeck52, isSlash, isDodge, isPeach, isWine, CARD_CATEGORIES, CARD_SUBTYPES } from './deck.js';

// Cache bộ bài chuẩn để tra cứu subType theo ID
let _deckCache = null;
function getDeckCache() {
  if (!_deckCache) {
    _deckCache = {};
    for (const c of createDeck52()) {
      _deckCache[c.id] = c;
    }
  }
  return _deckCache;
}

/**
 * Tìm lá bài trong bộ bài chuẩn theo ID để lấy subType (dùng khi ID client/server không khớp)
 */
function findCardByIdInDeck(cardId) {
  if (!cardId) return null;
  return getDeckCache()[cardId] || null;
}

/**
 * Xáo bài Fisher-Yates chuẩn
 */
export function shuffle(array) {
  const arr = [...array];
  for (let i = arr.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [arr[i], arr[j]] = [arr[j], arr[i]];
  }
  return arr;
}

/**
 * Khởi tạo trận đấu mới (4 người chơi, mỗi người 4 lá, 4 máu)
 */
export function initGame(roomId, playersInput) {
  const deck = shuffle(createDeck52());
  const discard = [];

  const players = playersInput.map((p, index) => {
    const hand = [];
    for (let i = 0; i < 4; i++) {
      if (deck.length > 0) hand.push(deck.pop());
    }
    return {
      seat: index + 1,
      userId: p.userId || `user_${index + 1}`,
      generalName: p.generalName || `Tướng Ghế ${index + 1}`,
      maxHp: p.maxHp || 4,
      hp: p.maxHp || 4,
      isAlly: (index === 0 || index === 2), // Ghế 1 & 3 là Đội 1; Ghế 2 & 4 là Đội 2
      isAI: !!p.isAI,
      isWineBuffActive: false,
      hand: hand,
      equipments: [],
      judgements: []
    };
  });

  const initialState = {
    version: 1,
    roomId,
    status: "PLAYING", // "PLAYING" | "FINISHED"
    turnSeat: 1,
    phase: "PLAY", // "PLAY" | "AWAIT_SLASH_DEFENSE" | "AWAIT_AOE" | "AWAIT_DUEL" | "AWAIT_NEAR_DEATH" | "DISCARD"
    turnTimer: 40,
    waitingTargetSeat: 0,
    waitingReactionType: "NONE", // "DODGE" | "SLASH" | "PEACH" | "NONE"
    waitingTimer: 0,
    aoeVictimsQueue: [], // Ghế các nạn nhân còn lại của đòn diện rộng
    duelCasterSeat: 0,
    duelTargetSeat: 0,
    nearDeathVictimSeat: 0,
    nearDeathAskerQueue: [],
    slashesUsedThisTurn: 0,
    isWineBuffActive: false,
    activeCard: null,
    actionSeq: 1,
    actionHistory: [{
      seq: 1,
      type: "GAME_START",
      description: "Trận đấu bắt đầu! Lượt của Ghế 1.",
      timestamp: Date.now()
    }],
    lastAction: {
      seq: 1,
      type: "GAME_START",
      description: "Trận đấu bắt đầu! Lượt của Ghế 1.",
      timestamp: Date.now()
    },
    discardTop: null,
    deckCount: deck.length,
    discardCount: 0,
    players,
    _deck: deck, // Bộ bài ẩn trên server
    _discard: discard
  };

  return initialState;
}

/**
 * Kiểm tra Optimistic Locking: nếu client gửi expectedVersion thì phải khớp với state.version
 */
export function checkVersion(state, expectedVersion) {
  if (expectedVersion !== undefined && expectedVersion !== null) {
    const exp = parseInt(expectedVersion, 10);
    if (!isNaN(exp) && state.version !== exp) {
      return {
        error: `Conflict: State version mismatch (expected: ${exp}, current: ${state.version})`,
        code: "VERSION_CONFLICT",
        conflict: true
      };
    }
  }
  return null;
}

/**
 * Ghi nhận hành động vào lịch sử trận đấu, tăng version state và tạo Delta Update
 */
export function recordAction(state, action) {
  state.actionSeq = (state.actionSeq || 0) + 1;
  action.seq = state.actionSeq;
  action.timestamp = Date.now();
  state.lastAction = action;
  if (!state.actionHistory) state.actionHistory = [];
  state.actionHistory.push(action);
  if (state.actionHistory.length > 50) state.actionHistory.shift();
  state.version = (state.version || 0) + 1;

  state.lastDelta = {
    version: state.version,
    actionSeq: state.actionSeq,
    type: action.type,
    description: action.description,
    turnSeat: state.turnSeat,
    phase: state.phase,
    waitingTargetSeat: state.waitingTargetSeat,
    waitingReactionType: state.waitingReactionType,
    waitingTimer: state.waitingTimer,
    activeCard: state.activeCard,
    deckCount: state._deck ? state._deck.length : state.deckCount,
    discardCount: state._discard ? state._discard.length : state.discardCount,
    discardTop: state.discardTop,
    status: state.status,
    harvestPool: state.harvestPool || [],
    nullifyChain: state.nullifyChain || null,
    playerDeltas: state.players.map(p => ({
      seat: p.seat,
      hp: p.hp,
      maxHp: p.maxHp,
      handCount: p.hand ? p.hand.length : 0,
      isWineBuffActive: !!p.isWineBuffActive,
      equipments: p.equipments || []
    }))
  };
}

/**
 * Tìm người chơi còn sống kế tiếp
 */
export function getNextAliveSeat(state, currentSeat) {
  for (let i = 1; i <= 4; i++) {
    const next = ((currentSeat - 1 + i) % 4) + 1;
    const p = state.players.find(x => x.seat === next);
    if (p && p.hp > 0) return next;
  }
  return currentSeat;
}

/**
 * Rút N lá bài từ cọc rút cho 1 người chơi
 */
export function drawCards(state, seat, count = 2) {
  const p = state.players.find(x => x.seat === seat);
  if (!p || p.hp <= 0) return [];

  const drawn = [];
  for (let i = 0; i < count; i++) {
    if (state._deck.length === 0) {
      if (state._discard.length > 0) {
        state._deck = shuffle(state._discard);
        state._discard = [];
      } else {
        break;
      }
    }
    const card = state._deck.pop();
    if (card) {
      p.hand.push(card);
      drawn.push(card);
    }
  }
  state.deckCount = state._deck.length;
  state.discardCount = state._discard.length;
  return drawn;
}

/**
 * Xử lý khi một người chơi đánh ra 1 lá bài từ tay
 */
export function handlePlayCard(state, casterSeat, cardId, targetSeat = 0) {
  if (state.status === "FINISHED") return { error: "Trận đấu đã kết thúc" };
  if (state.turnSeat !== casterSeat && state.phase === "PLAY") {
    return { error: "Chưa tới lượt của bạn" };
  }

  const caster = state.players.find(x => x.seat === casterSeat);
  if (!caster || caster.hp <= 0) return { error: "Người chơi không hợp lệ" };

  // Tìm lá bài: ưu tiên ID chính xác, fallback sang subType khi ID client và server khác nhau (do bộ bài độc lập)
  let cardIndex = caster.hand.findIndex(c => c.id === cardId);
  if (cardIndex < 0 && cardId) {
    // Lấy subType từ card cùng ID trong bộ bài chuẩn dựa trên suffix ID
    // Ví dụ: client gửi "D1_S_3" -> subType 11 (Dismantle/Vườn Không Nhà Trống)
    // Tìm lá bài cùng subType trên server hand
    const refCard = findCardByIdInDeck(cardId);
    if (refCard !== null) {
      cardIndex = caster.hand.findIndex(c => c.subType === refCard.subType);
    }
  }
  if (cardIndex < 0) return { error: "Không tìm thấy lá bài trên tay" };

  const card = caster.hand.splice(cardIndex, 1)[0];
  state._discard.push(card);
  state.discardTop = { id: card.id, name: card.name, suit: card.suit, rank: card.rank };
  state.discardCount = state._discard.length;

  const target = state.players.find(x => x.seat === targetSeat);

  // 1. LÁ TRẢM (Slash)
  if (isSlash(card)) {
    state.slashesUsedThisTurn++;
    const isWine = !!(caster.isWineBuffActive || state.isWineBuffActive);
    const damage = isWine ? 2 : 1;
    caster.isWineBuffActive = false;
    state.isWineBuffActive = false;

    state.phase = "AWAIT_SLASH_DEFENSE";
    state.waitingTargetSeat = targetSeat;
    state.waitingReactionType = "DODGE";
    state.waitingTimer = 40;
    state.activeCard = {
      cardId: card.id,
      cardName: card.name,
      casterSeat,
      targetSeat,
      damage,
      isWineBuff: isWine
    };
    recordAction(state, {
      type: "PLAY_SLASH",
      casterSeat,
      targetSeat,
      cardId: card.id,
      cardName: card.name,
      damage,
      isWineBuff: isWine,
      description: `🗡️ <b>${caster.generalName}</b> tung chiêu [${card.name}]${isWine ? ' <color=#FFD700><b>(kèm hiệu ứng Hủ Rượu: +1 Sát thương -> 2 Tổng!)</b></color>' : ''} nhắm vào <b>${target ? target.generalName : 'đối thủ'}</b>! (Mục tiêu có 40s để Đỡ)`
    });
    return { success: true, state };
  }

  // 2. BÁNH CHƯNG (Peach)
  if (card.subType === CARD_SUBTYPES.PEACH) {
    if (caster.hp < caster.maxHp) {
      caster.hp++;
    }
    recordAction(state, {
      type: "PLAY_PEACH",
      casterSeat,
      targetSeat: casterSeat,
      cardId: card.id,
      cardName: card.name,
      description: `💮 <b>${caster.generalName}</b> dùng [Bánh Chưng] hồi 1 đóa sen máu (${caster.hp}/${caster.maxHp})!`
    });
    return { success: true, state };
  }

  // 3. HỦ RƯỢU (Wine)
  if (card.subType === CARD_SUBTYPES.WINE) {
    caster.isWineBuffActive = true;
    state.isWineBuffActive = true;
    recordAction(state, {
      type: "PLAY_WINE",
      casterSeat,
      cardId: card.id,
      cardName: card.name,
      description: `🍶 <b>${caster.generalName}</b> uống [Hủ Rượu]: Đòn Trảm kế tiếp gây +1 sát thương (+2 tổng)!`
    });
    return { success: true, state };
  }

  // 4. TRANG BỊ (Equipment)
  if (card.category === CARD_CATEGORIES.EQUIPMENT) {
    caster.equipments.push(card);
    recordAction(state, {
      type: "EQUIP",
      casterSeat,
      cardId: card.id,
      cardName: card.name,
      description: `🛡️ <b>${caster.generalName}</b> trang bị [${card.name}]: ${card.desc}`
    });
    return { success: true, state };
  }

  // 5. CÁC LÁ CẨM NANG (Instant / Delayed Scroll) -> BẮT ĐẦU CHUỖI HỎI DIỆU KẾ PHÁ MƯU (AWAIT_NULLIFY)
  return startNullifyChain(state, card, casterSeat, targetSeat);
}

/**
 * Khởi động chuỗi hỏi Diệu Kế Phá Mưu (AWAIT_NULLIFY) theo vòng 4 ghế
 */
export function startNullifyChain(state, card, casterSeat, targetSeat = 0) {
  const caster = state.players.find(x => x.seat === casterSeat);
  const target = state.players.find(x => x.seat === targetSeat);

  const querySeats = [];
  for (let i = 0; i < 4; i++) {
    const s = ((casterSeat - 1 + i) % 4) + 1;
    const p = state.players.find(x => x.seat === s);
    if (p && p.hp > 0) querySeats.push(s);
  }

  state.phase = "AWAIT_NULLIFY";
  state.nullifyChain = {
    rootCard: card,
    casterSeat,
    targetSeat,
    isCanceled: false,
    querySeats,
    currentIdx: 0,
    whoUsedLast: null
  };
  state.waitingTargetSeat = querySeats[0];
  state.waitingReactionType = "FLAWLESS_DEFENSE";
  state.waitingTimer = 40;
  state.activeCard = {
    cardId: card.id,
    cardName: card.name,
    casterSeat,
    targetSeat
  };

  const targetDesc = target ? ` lên #${target.seat} (${target.generalName})` : "";
  const firstQueriedGen = state.players.find(x => x.seat === querySeats[0]);
  recordAction(state, {
    type: "NULLIFY_START",
    casterSeat,
    targetSeat,
    cardId: card.id,
    cardName: card.name,
    description: `📜 <b>${caster ? caster.generalName : 'Ghế ' + casterSeat}</b> thi triển [${card.name}]${targetDesc}! Đang hỏi <b>${firstQueriedGen ? firstQueriedGen.generalName : 'Ghế ' + querySeats[0]}</b> có dùng Diệu Kế Phá Mưu không (40s)...`
  });

  return { success: true, state };
}

/**
 * Thực thi hiệu ứng cẩm nang sau khi chuỗi Diệu Kế kết thúc và không bị hóa giải
 */
export function executeCardEffect(state, card, casterSeat, targetSeat = 0) {
  const caster = state.players.find(x => x.seat === casterSeat);
  const target = state.players.find(x => x.seat === targetSeat);

  // 1. DỤNG BINH NHƯ THẦN (Ex Nihilo)
  if (card.subType === CARD_SUBTYPES.EX_NIHILO) {
    const drawn = drawCards(state, casterSeat, 2);
    state.phase = "PLAY";
    state.waitingTargetSeat = 0;
    state.waitingTimer = 0;
    recordAction(state, {
      type: "PLAY_EX_NIHILO",
      casterSeat,
      cardId: card.id,
      cardName: card.name,
      description: `📜 <b>${caster ? caster.generalName : 'Người chơi'}</b> dùng [Dụng Binh Như Thần] rút thêm 2 lá bài vào tay!`
    });
    return { success: true, state };
  }

  // 2. MỞ KHO CỨU TẾ (Harvest)
  if (card.subType === CARD_SUBTYPES.HARVEST) {
    const living = [];
    for (let i = 0; i < 4; i++) {
      const s = ((casterSeat - 1 + i) % 4) + 1;
      const p = state.players.find(x => x.seat === s);
      if (p && p.hp > 0) living.push(p);
    }
    const pool = [];
    for (let i = 0; i < living.length; i++) {
      if (state._deck.length === 0) {
        if (state._discard.length > 0) {
          state._deck = shuffle(state._discard);
          state._discard = [];
        }
      }
      const c = state._deck.pop();
      if (c) pool.push(c);
    }
    state.deckCount = state._deck.length;
    state.harvestPool = pool;
    state.harvestPickers = living.map(p => p.seat);
    state.phase = "AWAIT_HARVEST";
    state.waitingTargetSeat = state.harvestPickers[0];
    state.waitingTimer = 40;
    state.activeCard = { cardId: card.id, cardName: card.name, casterSeat };

    const firstPicker = state.players.find(x => x.seat === state.harvestPickers[0]);
    recordAction(state, {
      type: "HARVEST_START",
      casterSeat,
      cardId: card.id,
      cardName: card.name,
      harvestPool: pool,
      description: `🌾 <b>${caster ? caster.generalName : 'Người chơi'}</b> [Mở Kho Cứu Tế] lật ${pool.length} lá bài công khai! Đang tới lượt <b>${firstPicker ? firstPicker.generalName : 'Ghế 1'}</b> chọn bài (40s)...`
    });
    return { success: true, state };
  }

  // 3. DIỆN RỘNG (Mưa Tên / Bãi Cọc Ngầm)
  if (card.subType === CARD_SUBTYPES.ARROW_RAIN || card.subType === CARD_SUBTYPES.BARBARIAN_INVASION) {
    const reqType = (card.subType === CARD_SUBTYPES.ARROW_RAIN) ? "DODGE" : "SLASH";
    const reqName = (card.subType === CARD_SUBTYPES.ARROW_RAIN) ? "Đỡ" : "Trảm";
    const victims = [];
    for (let i = 1; i <= 3; i++) {
      const nextSeat = ((casterSeat - 1 + i) % 4) + 1;
      const v = state.players.find(x => x.seat === nextSeat);
      if (v && v.hp > 0) victims.push(nextSeat);
    }

    if (victims.length > 0) {
      const firstVictim = victims.shift();
      state.phase = "AWAIT_AOE";
      state.aoeVictimsQueue = victims;
      state.waitingTargetSeat = firstVictim;
      state.waitingReactionType = reqType;
      state.waitingTimer = 40;
      state.activeCard = { cardId: card.id, cardName: card.name, casterSeat, reqType, reqName };
      recordAction(state, {
        type: "PLAY_AOE",
        casterSeat,
        targetSeat: firstVictim,
        cardId: card.id,
        cardName: card.name,
        description: `🏹 <b>${caster ? caster.generalName : 'Người chơi'}</b> thi triển [${card.name}]! Đang kiểm tra <b>Ghế ${firstVictim}</b> (cần [${reqName}] - 40s)...`
      });
    } else {
      state.phase = "PLAY";
      state.waitingTargetSeat = 0;
    }
    return { success: true, state };
  }

  // 4. THÁCH ĐẤU (Duel)
  if (card.subType === CARD_SUBTYPES.DUEL) {
    state.phase = "AWAIT_DUEL";
    state.duelCasterSeat = casterSeat;
    state.duelTargetSeat = targetSeat;
    state.waitingTargetSeat = targetSeat;
    state.waitingReactionType = "SLASH";
    state.waitingTimer = 40;
    state.activeCard = { cardId: card.id, cardName: card.name, casterSeat, targetSeat };
    recordAction(state, {
      type: "PLAY_DUEL",
      casterSeat,
      targetSeat,
      cardId: card.id,
      cardName: card.name,
      description: `⚔️ <b>${caster ? caster.generalName : 'Người chơi'}</b> phát động [Thách Đấu] nhắm vào <b>${target ? target.generalName : 'đối thủ'}</b>! (Có 40s để đáp trả Trảm)`
    });
    return { success: true, state };
  }

  // 5. CÁC LÁ CẨM NANG TRÌ HOÃN (Thần Sấm Báo Ứng / Cắt Đường Lương / Trầm Ảo Sa Bẫy)
  if (card.category === CARD_CATEGORIES.DELAYED_SCROLL || card.subType === CARD_SUBTYPES.LIGHTNING || card.subType === CARD_SUBTYPES.SUPPLY_SHORTAGE || card.subType === CARD_SUBTYPES.ACEDIA) {
    const attachTarget = (card.subType === CARD_SUBTYPES.LIGHTNING) ? caster : target;
    if (attachTarget) {
      if (!attachTarget.judgements) attachTarget.judgements = [];
      attachTarget.judgements.push(card);
      recordAction(state, {
        type: "DELAYED_SCROLL_ATTACHED",
        casterSeat,
        targetSeat: attachTarget.seat,
        cardId: card.id,
        cardName: card.name,
        description: `⚡ <b>${caster ? caster.generalName : 'Người chơi'}</b> đã gài cẩm nang trì hoãn [<b>${card.name}</b>] vào khu phán xét của <b>${attachTarget.generalName}</b>!`
      });
    }
    state.phase = "PLAY";
    state.waitingTargetSeat = 0;
    state.waitingTimer = 0;
    return { success: true, state };
  }

  // 6. CÁC LÁ CẨM NANG ĐƠN MỤC TIÊU (Vườn Không Nhà Trống, Đột Kích Trộm Lương...)
  if (target && target.hand.length > 0) {
    const removedCard = target.hand.pop();
    state._discard.push(removedCard);
    state.discardTop = { id: removedCard.id, name: removedCard.name };
    if (card.subType === CARD_SUBTYPES.SNATCH) {
      if (caster) caster.hand.push(removedCard);
      recordAction(state, {
        type: "PLAY_SNATCH",
        casterSeat,
        targetSeat,
        cardId: card.id,
        cardName: card.name,
        description: `🌾 <b>${caster ? caster.generalName : 'Người chơi'}</b> dùng [${card.name}] cướp 1 lá bài từ <b>${target.generalName}</b>!`
      });
    } else {
      recordAction(state, {
        type: "PLAY_DISMANTLE",
        casterSeat,
        targetSeat,
        cardId: card.id,
        cardName: card.name,
        description: `🏚️ <b>${caster ? caster.generalName : 'Người chơi'}</b> dùng [${card.name}] phá hủy 1 lá bài của <b>${target.generalName}</b>!`
      });
    }
  } else {
    recordAction(state, {
      type: "PLAY_SCROLL",
      casterSeat,
      targetSeat,
      cardId: card.id,
      cardName: card.name,
      description: `📜 <b>${caster ? caster.generalName : 'Người chơi'}</b> dùng [${card.name}] lên <b>${target ? target.generalName : 'mục tiêu'}</b>!`
    });
  }

  state.phase = "PLAY";
  state.waitingTargetSeat = 0;
  state.waitingTimer = 0;
  return { success: true, state };
}

/**
 * Xử lý phản ứng từ người bị nhắm tới (Đỡ, Trảm, Bỏ qua / Hết giờ, Diệu Kế Phá Mưu, Chọn bài kho lương)
 */

/**
* KhÃ´i phá»¥c láº¡i luá»“ng game sau khi pha Háº¥p Há»“i (Near Death) káº¿t thÃºc (cá»©u sá»‘ng hoáº·c cháº¿t)
*/
function resolveNearDeathResume(state) {
    state.waitingTargetSeat = 0;
    state.waitingTimer = 0;
    state.nearDeathAskerQueue = [];
    state.nearDeathVictimSeat = 0;
    
    // Náº¿u Ä‘ang dá»Ÿ dang AOE (MÆ°a TÃªn / BÃ£i Cá»c), tiáº¿p tá»¥c há»i náº¡n nhÃ¢n káº¿ tiáº¿p
    if (state.aoeVictimsQueue && state.aoeVictimsQueue.length > 0) {
        const nextVictim = state.aoeVictimsQueue.shift();
        state.phase = "AWAIT_AOE";
        state.waitingTargetSeat = nextVictim;
        state.waitingTimer = 40;
        return { success: true, state };
    }
    
    // Náº¿u Ä‘ang dá»Ÿ dang ThÃ¡ch Ä‘áº¥u, xá»a tráº¡ng thÃ¡i (vÃ¬ ngÆ°á»i bá»‹ thÆ°Æ¡ng Ä‘Ã£ thua cuá»™c Ä‘áº¥u)
    if (state.duelCasterSeat > 0 && state.duelTargetSeat > 0) {
        state.duelCasterSeat = 0;
        state.duelTargetSeat = 0;
    }
    
    state.phase = "PLAY";
    return { success: true, state };
}

export function handleRespondAction(state, respondentSeat, accepted, cardId) {
  if (state.status === "FINISHED") return { error: "Trận đấu đã kết thúc" };
  if (state.waitingTargetSeat !== respondentSeat) {
    return { error: "Không phải lượt phản ứng của bạn" };
  }

  const respondent = state.players.find(x => x.seat === respondentSeat);
  if (!respondent) return { error: "Người chơi không hợp lệ" };

  // --- 0. PHẢN HỒI CHUỖI DIỆU KẾ PHÁ MƯU (AWAIT_NULLIFY) ---
  if (state.phase === "AWAIT_NULLIFY" && state.nullifyChain) {
    const chain = state.nullifyChain;
    const rootCard = chain.rootCard;

    if (accepted && cardId) {
      // Tìm Diệu Kế: ưu tiên ID chính xác, fallback sang subType
      let idx = respondent.hand.findIndex(c => c.id === cardId && (c.subType === CARD_SUBTYPES.FLAWLESS_DEFENSE || (c.name && c.name.includes("Diệu Kế"))));
      if (idx < 0) {
        // Fallback: tìm bất kỳ Diệu Kế trên tay (subType FLAWLESS_DEFENSE = 10)
        idx = respondent.hand.findIndex(c => c.subType === CARD_SUBTYPES.FLAWLESS_DEFENSE || (c.name && c.name.includes("Diệu Kế")));
      }
      if (idx >= 0) {
        const nullifyCard = respondent.hand.splice(idx, 1)[0];
        state._discard.push(nullifyCard);
        state.discardTop = { id: nullifyCard.id, name: nullifyCard.name };

        chain.isCanceled = !chain.isCanceled;
        chain.whoUsedLast = respondentSeat;

        // Bắt đầu vòng hỏi mới từ người bên phải của người vừa dùng Diệu Kế
        const newQuerySeats = [];
        for (let i = 0; i < 4; i++) {
          const s = ((respondentSeat + i) % 4) + 1;
          const p = state.players.find(x => x.seat === s);
          if (p && p.hp > 0) newQuerySeats.push(s);
        }
        chain.querySeats = newQuerySeats;
        chain.currentIdx = 0;
        state.waitingTargetSeat = newQuerySeats[0];
        state.waitingTimer = 40;

        recordAction(state, {
          type: "NULLIFY_PLAYED",
          casterSeat: respondentSeat,
          cardId: nullifyCard.id,
          cardName: nullifyCard.name,
          description: `🛡️ <b>${respondent.generalName}</b> đã tung <color=#55FF55><b>[Diệu Kế Phá Mưu]</b></color>! Trạng thái mưu kế [${rootCard.name}]: ${chain.isCanceled ? '<color=#FF5555>BỊ VÔ HIỆU HÓA</color>' : '<color=#55FF55>ĐƯỢC BẢO VỆ THÀNH CÔNG</color>'}. Đang hỏi Ghế ${newQuerySeats[0]} (40s)...`
        });
        return { success: true, state };
      }
    }

    // Nếu không dùng Diệu Kế (hoặc hết giờ):
    chain.currentIdx++;
    if (chain.currentIdx < chain.querySeats.length) {
      const nextSeat = chain.querySeats[chain.currentIdx];
      const nextGen = state.players.find(x => x.seat === nextSeat);
      state.waitingTargetSeat = nextSeat;
      state.waitingTimer = 40;
      recordAction(state, {
        type: "NULLIFY_PASS",
        casterSeat: respondentSeat,
        description: `⏭️ <b>${respondent.generalName}</b> không dùng Diệu Kế Phá Mưu. Đang hỏi <b>${nextGen ? nextGen.generalName : 'Ghế ' + nextSeat}</b> (40s)...`
      });
      return { success: true, state };
    }

    // ĐÃ HỎI HẾT CẢ VÒNG MÀ KHÔNG AI PHÁ TIẾP:
    if (chain.isCanceled) {
      // Mưu kế bị hủy
      state.phase = "PLAY";
      state.waitingTargetSeat = 0;
      state.waitingTimer = 0;
      state.nullifyChain = null;
      recordAction(state, {
        type: "NULLIFY_SUCCEEDED",
        description: `🛡️ Mưu kế [${rootCard.name}] đã chính thức bị vô hiệu hóa hoàn toàn bởi Diệu Kế Phá Mưu!`
      });
      return { success: true, state };
    }

    // Mưu kế được thực thi thành công!
    const { casterSeat, targetSeat } = chain;
    state.nullifyChain = null;
    return executeCardEffect(state, rootCard, casterSeat, targetSeat);
  }

  // --- 0.5. PHẢN HỒI CHỌN BÀI KHO LƯƠNG (AWAIT_HARVEST) ---
  if (state.phase === "AWAIT_HARVEST" && state.harvestPool) {
    let pickedCard = null;
    if (cardId) {
      const idx = state.harvestPool.findIndex(c => c.id === cardId);
      if (idx >= 0) {
        pickedCard = state.harvestPool.splice(idx, 1)[0];
      }
    }
    if (!pickedCard && state.harvestPool.length > 0) {
      pickedCard = state.harvestPool.shift(); // Tự động lấy lá đầu nếu không chọn hoặc hết giờ
    }

    if (pickedCard) {
      respondent.hand.push(pickedCard);
      recordAction(state, {
        type: "HARVEST_PICKED",
        casterSeat: respondentSeat,
        cardId: pickedCard.id,
        cardName: pickedCard.name,
        description: `🍚 <b>${respondent.generalName}</b> đã chọn lá [<b>${pickedCard.name}</b>] từ Kho Cứu Tế!`
      });
    }

    // Chuyển sang người chọn tiếp theo
    if (state.harvestPickers && state.harvestPickers.length > 0) {
      state.harvestPickers.shift(); // Bỏ người vừa chọn
    }

    if (state.harvestPickers && state.harvestPickers.length > 0 && state.harvestPool.length > 0) {
      const nextSeat = state.harvestPickers[0];
      state.waitingTargetSeat = nextSeat;
      state.waitingTimer = 40;
      return { success: true, state };
    } else {
      // Đã chia xong toàn bộ bài trong kho
      state.phase = "PLAY";
      state.waitingTargetSeat = 0;
      state.waitingTimer = 0;
      state.harvestPool = [];
      state.harvestPickers = [];
      return { success: true, state };
    }
  }

  // --- 1. PHẢN HỒI ĐÒN TRẢM ---
  if (state.phase === "AWAIT_SLASH_DEFENSE") {
    if (accepted && cardId) {
      const idx = respondent.hand.findIndex(c => c.id === cardId && isDodge(c));
      if (idx >= 0) {
        const dodgeCard = respondent.hand.splice(idx, 1)[0];
        state._discard.push(dodgeCard);
        state.discardTop = { id: dodgeCard.id, name: dodgeCard.name };

        const caster = state.players.find(x => x.seat === (state.activeCard ? state.activeCard.casterSeat : 0));
        const hasNamSon = caster && caster.equipments && caster.equipments.some(e => e.name && e.name.includes("Trường Đao"));
        const hasSlashToFollowUp = caster && caster.hand && caster.hand.some(isSlash);

        if (hasNamSon && hasSlashToFollowUp) {
          state.phase = "AWAIT_NAM_SON_FOLLOW_UP";
          state.waitingTargetSeat = caster.seat;
          state.waitingTimer = 40;
          state.waitingReactionType = "SLASH";
          recordAction(state, {
            type: "NAM_SON_PROMPT",
            casterSeat: caster.seat,
            targetSeat: respondentSeat,
            description: `🗡️ [Trường Đao Nam Sơn]: Đối phương đã Đỡ! ${caster.generalName} có muốn bỏ 1 Trảm tiếp tục truy kích không? (40s)`
          });
          return { success: true, state };
        }

        state.phase = "PLAY";
        state.waitingTargetSeat = 0;
        state.waitingTimer = 0;
        recordAction(state, {
          type: "DODGE_SUCCESS",
          casterSeat: respondentSeat,
          description: `🛡️ ${respondent.generalName} đã đánh [${dodgeCard.name}] hóa giải đòn Trảm!`
        });
        return { success: true, state };
      }
    }

    // Không né hoặc hết giờ -> Chịu sát thương
    const damage = (state.activeCard && state.activeCard.damage) ? state.activeCard.damage : 1;
    applyDamageToPlayer(state, respondentSeat, damage, "đòn Trảm");
    checkGameOver(state);
    return { success: true, state };
  }

  // --- 1.5. PHẢN HỒI TRƯỜNG ĐAO NAM SƠN (CASTER CHỌN BỎ TRẢM ĐỂ TRUY KÍCH) ---
  if (state.phase === "AWAIT_NAM_SON_FOLLOW_UP") {
    const caster = respondent;
    const targetSeat = state.activeCard ? state.activeCard.targetSeat : 0;
    const target = state.players.find(x => x.seat === targetSeat);

    if (accepted && cardId) {
      const idx = caster.hand.findIndex(c => c.id === cardId && isSlash(c));
      if (idx >= 0) {
        const slashCard = caster.hand.splice(idx, 1)[0];
        state._discard.push(slashCard);
        state.discardTop = { id: slashCard.id, name: slashCard.name };

        // Ép mục tiêu lại phải Đỡ tiếp (40s)
        state.phase = "AWAIT_SLASH_DEFENSE";
        state.waitingTargetSeat = targetSeat;
        state.waitingReactionType = "DODGE";
        state.waitingTimer = 40;
        recordAction(state, {
          type: "NAM_SON_FOLLOW_UP_PLAYED",
          casterSeat: caster.seat,
          targetSeat: targetSeat,
          cardId: slashCard.id,
          cardName: slashCard.name,
          description: `🗡️ <color=#FFD700><b>[TRƯỜNG ĐAO NAM SƠN]</b></color>: <b>${caster.generalName}</b> bỏ thêm lá [<b>${slashCard.name}</b>] tiếp tục truy kích <b>${target ? target.generalName : 'đối thủ'}</b>!`
        });
        return { success: true, state };
      }
    }

    // Caster từ chối ra Trảm hoặc hết giờ -> Hóa giải thành công, quay về PLAY
    state.phase = "PLAY";
    state.waitingTargetSeat = 0;
    state.waitingTimer = 0;
    recordAction(state, {
      type: "NAM_SON_PASSED",
      casterSeat: caster.seat,
      description: `🛡️ ${caster.generalName} từ chối dùng thêm Trảm. ${target ? target.generalName : 'Mục tiêu'} đã né đòn thành công!`
    });
    return { success: true, state };
  }

  // --- 2. PHẢN HỒI CẨM NANG DIỆN RỘNG (Mưa Tên / Bãi Cọc Ngầm) ---
  if (state.phase === "AWAIT_AOE") {
    const isArrow = (state.activeCard && state.activeCard.cardName.includes("Mưa Tên"));
    let satisfied = false;

    if (accepted && cardId) {
      const idx = respondent.hand.findIndex(c => c.id === cardId && (isArrow ? isDodge(c) : isSlash(c)));
      if (idx >= 0) {
        const c = respondent.hand.splice(idx, 1)[0];
        state._discard.push(c);
        state.discardTop = { id: c.id, name: c.name };
        satisfied = true;
      }
    }

    if (!satisfied) {
      applyDamageToPlayer(state, respondentSeat, 1, "đòn diện rộng");
      if (state.phase === "AWAIT_NEAR_DEATH") {
        return { success: true, state };
      }
    }

    recordAction(state, {
      type: satisfied ? "AOE_DEFENDED" : "AOE_HIT",
      targetSeat: respondentSeat,
      description: satisfied
        ? `🛡️ ${respondent.generalName} đã né đòn diện rộng thành công!`
        : `💥 ${respondent.generalName} không ra bài né, bị mất 1 máu (${respondent.hp}/${respondent.maxHp})!`
    });

    // Chuyển sang nạn nhân kế tiếp nếu còn
    if (state.aoeVictimsQueue && state.aoeVictimsQueue.length > 0) {
      const nextVictim = state.aoeVictimsQueue.shift();
      state.waitingTargetSeat = nextVictim;
      state.waitingTimer = 40;
    } else {
      state.phase = "PLAY";
      state.waitingTargetSeat = 0;
      state.waitingTimer = 0;
    }

    checkGameOver(state);
    return { success: true, state };
  }

  // --- 3. PHẢN HỒI THÁCH ĐẤU ---
  if (state.phase === "AWAIT_DUEL") {
    if (accepted && cardId) {
      const idx = respondent.hand.findIndex(c => c.id === cardId && isSlash(c));
      if (idx >= 0) {
        const s = respondent.hand.splice(idx, 1)[0];
        state._discard.push(s);
        state.discardTop = { id: s.id, name: s.name };

        // Đổi lượt sang đối phương
        const otherSeat = (respondentSeat === state.duelCasterSeat) ? state.duelTargetSeat : state.duelCasterSeat;
        state.waitingTargetSeat = otherSeat;
        state.waitingTimer = 40;
        recordAction(state, {
          type: "DUEL_RESPOND",
          casterSeat: respondentSeat,
          description: `⚔️ ${respondent.generalName} đáp trả 1 lá [${s.name}] trong Thách Đấu!`
        });
        return { success: true, state };
      }
    }

    // Không ra Trảm -> Nhận thua Thách Đấu và mất 1 Máu
    applyDamageToPlayer(state, respondentSeat, 1, "Thách Đấu");
    checkGameOver(state);
    return { success: true, state };
  }

  // --- 4. PHẢN HỒI CỨU HẤP HỐI (Bánh Chưng / Hủ Rượu) ---
  if (state.phase === "AWAIT_NEAR_DEATH") {
    const victim = state.players.find(x => x.seat === state.nearDeathVictimSeat);
    if (accepted && cardId && victim) {
      const idx = respondent.hand.findIndex(c => c.id === cardId && (isPeach(c) || (isWine(c) && respondentSeat === victim.seat)));
      if (idx >= 0) {
        const rescueCard = respondent.hand.splice(idx, 1)[0];
        state._discard.push(rescueCard);
        state.discardTop = { id: rescueCard.id, name: rescueCard.name };

        victim.hp = Math.min(victim.maxHp, Math.max(1, victim.hp + 1));
        state.phase = "PLAY";
        state.waitingTargetSeat = 0;
        state.waitingTimer = 0;
        recordAction(state, {
          type: "RESCUE_SUCCESS",
          casterSeat: respondentSeat,
          targetSeat: victim.seat,
          description: `💮 <b>${respondent.generalName}</b> đã dùng [${rescueCard.name}] cứu sống <b>${victim.generalName}</b> (${victim.hp}/${victim.maxHp})!`
        });
        return { success: true, state };
      }
    }

    // Nếu người này không cứu -> Hỏi người tiếp theo trong danh sách cứu viện
    if (state.nearDeathAskerQueue && state.nearDeathAskerQueue.length > 0) {
      const nextAsker = state.nearDeathAskerQueue.shift();
      state.waitingTargetSeat = nextAsker;
      state.waitingTimer = 40;
      return { success: true, state };
    } else {
      // Không ai cứu -> Tử trận
      state.phase = "PLAY";
      state.waitingTargetSeat = 0;
      state.waitingTimer = 0;
      if (victim) victim.hp = 0;
      recordAction(state, {
        type: "PLAYER_DIED",
        targetSeat: victim ? victim.seat : 0,
        description: `☠️ Không ai cứu viện! <b>${victim ? victim.generalName : 'Người chơi'}</b> đã tử trận!`
      });
      checkGameOver(state);
      return { success: true, state };
    }
  }

  return { error: "Giai đoạn không hỗ trợ phản hồi này" };
}

/**
 * Áp dụng sát thương lên người chơi và kích hoạt pha Hấp Hối (Near Death) nếu HP <= 0
 */
export function applyDamageToPlayer(state, targetSeat, damage, sourceDescription = "") {
  const target = state.players.find(x => x.seat === targetSeat);
  if (!target) return;

  target.hp -= damage;

  if (target.hp <= 0) {
    target.hp = 0;
    // Thứ tự hỏi cứu: Người trong lượt trước (state.turnSeat), sau đó đến người kế bên phải (ngược chiều kim đồng hồ) cho đến hết vòng
    const startSeat = state.turnSeat || 1;
    const askers = [];
    for (let i = 0; i < 4; i++) {
      const s = ((startSeat - 1 + i) % 4) + 1;
      const p = state.players.find(x => x.seat === s);
      if (p && (p.hp > 0 || s === targetSeat)) {
        askers.push(s);
      }
    }

    if (askers.length > 0) {
      const firstAsker = askers.shift();
      state.phase = "AWAIT_NEAR_DEATH";
      state.nearDeathVictimSeat = targetSeat;
      state.nearDeathAskerQueue = askers;
      state.waitingTargetSeat = firstAsker;
      state.waitingReactionType = "PEACH";
      state.waitingTimer = 40;
      recordAction(state, {
        type: "NEAR_DEATH",
        targetSeat,
        damage,
        description: `🆘 <b>${target.generalName}</b> trúng đòn bị mất ${damage} máu và rơi vào trạng thái Hấp Hối (0 Máu)! Đang chờ Ghế ${firstAsker} cứu viện (40s)...`
      });
      return;
    } else {
      // Không còn ai có thể cứu
      target.hp = 0;
      state.phase = "PLAY";
      state.waitingTargetSeat = 0;
      state.waitingTimer = 0;
      recordAction(state, {
        type: "PLAYER_DIED",
        targetSeat,
        description: `☠️ <b>${target.generalName}</b> đã tử trận!`
      });
      checkGameOver(state);
      return;
    }
  }

  state.phase = "PLAY";
  state.waitingTargetSeat = 0;
  state.waitingTimer = 0;
  recordAction(state, {
    type: "DAMAGE_TAKEN",
    targetSeat,
    damage,
    description: `💥 <b>${target.generalName}</b> bị mất ${damage} đóa sen máu (${target.hp}/${target.maxHp})!`
  });
}

/**
 * Kết thúc lượt đánh (Chuyển sang bỏ bài nếu thừa, hoặc rút bài cho người kế tiếp)
 */
export function handleEndTurn(state, casterSeat) {
  if (state.status === "FINISHED") return { error: "Trận đấu đã kết thúc" };
  if (state.phase !== "PLAY" || state.turnSeat !== casterSeat) {
    return { error: "Chưa tới lượt hoặc đang trong pha phản ứng" };
  }

  const caster = state.players.find(x => x.seat === casterSeat);
  if (!caster) return { error: "Người chơi không hợp lệ" };

  // Kiểm tra bài thừa so với máu
  const excess = caster.hand.length - caster.hp;
  if (excess > 0 && caster.hp > 0) {
    state.phase = "DISCARD";
    state.waitingTargetSeat = casterSeat;
    state.waitingTimer = 40;
    recordAction(state, {
      type: "DISCARD_PHASE",
      casterSeat,
      excess,
      description: `⚠️ ${caster.generalName} có ${caster.hand.length} lá nhưng chỉ còn ${caster.hp} máu. Cần bỏ ${excess} lá thừa (40s)!`
    });
    return { success: true, state };
  }

  // Chuyển sang lượt người tiếp theo
  return advanceTurn(state);
}

/**
 * Xử lý bỏ bài thừa
 */
export function handleDiscardCards(state, seat, cardIds) {
  if (state.phase !== "DISCARD" || state.waitingTargetSeat !== seat) {
    return { error: "Không trong giai đoạn bỏ bài" };
  }

  const p = state.players.find(x => x.seat === seat);
  if (!p) return { error: "Người chơi không hợp lệ" };

  if (Array.isArray(cardIds)) {
    for (const id of cardIds) {
      const idx = p.hand.findIndex(c => c.id === id);
      if (idx >= 0) {
        const discarded = p.hand.splice(idx, 1)[0];
        state._discard.push(discarded);
      }
    }
  }

  // Nếu vẫn còn thừa (do tự động hết giờ), tự động bỏ lá cuối
  while (p.hand.length > p.hp && p.hand.length > 0) {
    const discarded = p.hand.pop();
    state._discard.push(discarded);
  }

  return advanceTurn(state);
}

/**
 * Chuyển sang lượt kế tiếp, phán xét các cẩm nang trì hoãn và rút bài
 */
function advanceTurn(state) {
  const nextSeat = getNextAliveSeat(state, state.turnSeat);
  state.turnSeat = nextSeat;
  state.phase = "PLAY";
  state.turnTimer = 40;
  state.waitingTargetSeat = 0;
  state.waitingTimer = 0;
  state.slashesUsedThisTurn = 0;
  state.isWineBuffActive = false;

  const nextPlayer = state.players.find(x => x.seat === nextSeat);
  if (!nextPlayer || nextPlayer.hp <= 0) return { success: true, state };

  let skipDraw = false;
  let skipPlay = false;

  // 1. XỬ LÝ PHÁN XÉT CẨM NANG TRÌ HOÃN
  if (nextPlayer.judgements && nextPlayer.judgements.length > 0) {
    const pendingJudgements = [...nextPlayer.judgements];
    nextPlayer.judgements = [];

    for (const jCard of pendingJudgements) {
      if (state._deck.length === 0) {
        if (state._discard.length > 0) {
          state._deck = shuffle(state._discard);
          state._discard = [];
        }
      }
      const judgeCard = state._deck.pop() || { suit: "Heart", rank: 10, name: "Bài Phán Xét" };
      state._discard.push(judgeCard);
      state.discardTop = { id: judgeCard.id, name: judgeCard.name, suit: judgeCard.suit, rank: judgeCard.rank };

      // A. THẦN SẤM BÁO ỨNG (Lightning)
      if (jCard.subType === CARD_SUBTYPES.LIGHTNING) {
        const isHit = (judgeCard.suit === "Spade" && judgeCard.rank >= 2 && judgeCard.rank <= 9);
        if (isHit) {
          state._discard.push(jCard);
          recordAction(state, {
            type: "LIGHTNING_HIT",
            targetSeat: nextSeat,
            cardId: jCard.id,
            description: `⚡⚡⚡ <color=#FF5555><b>[THẦN SẤM BÁO ỨNG]</b></color>: Lá phán xét là [${judgeCard.name} (${judgeCard.suit} ${judgeCard.rank})]. <b>${nextPlayer.generalName}</b> bị sét đánh trúng chịu 3 sát thương lôi!`
          });
          applyDamageToPlayer(state, nextSeat, 3, "Thần Sấm Báo Ứng");
        } else {
          // Chuyển sang cho người sống kế tiếp
          const nextVictimSeat = getNextAliveSeat(state, nextSeat);
          const nextVictim = state.players.find(x => x.seat === nextVictimSeat);
          if (nextVictim) {
            if (!nextVictim.judgements) nextVictim.judgements = [];
            nextVictim.judgements.push(jCard);
          }
          recordAction(state, {
            type: "LIGHTNING_PASSED",
            targetSeat: nextSeat,
            description: `⚡ [Thần Sấm Báo Ứng]: Lá phán xét [${judgeCard.suit} ${judgeCard.rank}] không trúng. Sấm sét chuyển sang ${nextVictim ? nextVictim.generalName : 'Ghế ' + nextVictimSeat}!`
          });
        }
      }
      // B. CẮT ĐƯỜNG LƯƠNG (Supply Shortage)
      else if (jCard.subType === CARD_SUBTYPES.SUPPLY_SHORTAGE) {
        state._discard.push(jCard);
        if (judgeCard.suit !== "Club") {
          skipDraw = true;
          recordAction(state, {
            type: "SUPPLY_SHORTAGE_TRIGGERED",
            targetSeat: nextSeat,
            description: `🌾❌ <b>${nextPlayer.generalName}</b> [Cắt Đường Lương] phán xét [${judgeCard.suit} ${judgeCard.rank}] -> BỊ MẤT PHA RÚT BÀI!`
          });
        } else {
          recordAction(state, {
            type: "SUPPLY_SHORTAGE_PASSED",
            targetSeat: nextSeat,
            description: `🌾✅ <b>${nextPlayer.generalName}</b> phán xét ra Chuồn (${judgeCard.suit} ${judgeCard.rank}) -> Vượt qua Cắt Đường Lương thành công!`
          });
        }
      }
      // C. TRẦM ẢO SA BẪY (Acedia)
      else if (jCard.subType === CARD_SUBTYPES.ACEDIA) {
        state._discard.push(jCard);
        if (judgeCard.suit !== "Heart") {
          skipPlay = true;
          recordAction(state, {
            type: "ACEDIA_TRIGGERED",
            targetSeat: nextSeat,
            description: `🕸️❌ <b>${nextPlayer.generalName}</b> [Trầm Ảo Sa Bẫy] phán xét [${judgeCard.suit} ${judgeCard.rank}] -> BỊ MẤT PHA RA BÀI!`
          });
        } else {
          recordAction(state, {
            type: "ACEDIA_PASSED",
            targetSeat: nextSeat,
            description: `🕸️✅ <b>${nextPlayer.generalName}</b> phán xét ra Cơ (${judgeCard.suit} ${judgeCard.rank}) -> Phá giải Trầm Ảo Sa Bẫy thành công!`
          });
        }
      }
    }
  }

  // 2. RÚT BÀI (Nếu không bị mất lượt rút bài)
  if (!skipDraw) {
    drawCards(state, nextSeat, 2);
  }

  // 3. NẾU BỊ MẤT PHA RA BÀI -> Chuyển thẳng sang BỎ BÀI hoặc HẾT LƯỢT
  if (skipPlay) {
    const excess = nextPlayer.hand.length - nextPlayer.hp;
    if (excess > 0 && nextPlayer.hp > 0) {
      state.phase = "DISCARD";
      state.waitingTargetSeat = nextSeat;
      state.waitingTimer = 40;
      recordAction(state, {
        type: "DISCARD_PHASE",
        casterSeat: nextSeat,
        excess,
        description: `⚠️ <b>${nextPlayer.generalName}</b> bị khóa ra bài và thừa ${excess} lá -> Cần bỏ bài (40s)!`
      });
      return { success: true, state };
    } else {
      return advanceTurn(state);
    }
  }

  recordAction(state, {
    type: "TURN_START",
    turnSeat: nextSeat,
    description: `👉 Lượt của <b>${nextPlayer.generalName}</b>! ${!skipDraw ? 'Đã rút 2 lá bài' : 'Bị mất lượt rút bài'} (Thời gian: 40s).`
  });

  checkGameOver(state);
  return { success: true, state };
}

/**
 * Kiểm tra xem trận đấu đã ngã ngũ chưa (1 trong 2 đội bị hạ gục hết)
 * Lưu ý: Người đang trong Hấp Hối (hp=0 nhưng chưa tử trận) không được tính là đã chết
 */
function checkGameOver(state) {
  // Nếu đang trong pha Hấp Hối, chưa kết thúc được
  if (state.phase === "AWAIT_NEAR_DEATH") return;

  const team1Alive = state.players.some(p => p.isAlly && p.hp > 0);
  const team2Alive = state.players.some(p => !p.isAlly && p.hp > 0);

  if (!team1Alive || !team2Alive) {
    state.status = "FINISHED";
    const winningTeam = team1Alive ? "Đội 1 (Ghế 1 & 3)" : "Đội 2 (Ghế 2 & 4)";
    recordAction(state, {
      type: "GAME_OVER",
      winningTeam,
      description: `🏆 <b>TRẬN ĐẤU KẾT THÚC!</b> ${winningTeam} ĐÃ GIÀNH CHIẾN THẮNG!`
    });
  }
}

/**
 * Trọng tài AI tự động chọn lá bài tối ưu nhất để đánh hoặc kết thúc lượt
 */
export function handleAIStep(state, aiSeat) {
  if (state.status === "FINISHED") return { error: "Trận đấu đã kết thúc" };
  const ai = state.players.find(x => x.seat === aiSeat);
  if (!ai || ai.hp <= 0) return { error: "Người chơi không hợp lệ" };
  if (state.turnSeat !== aiSeat) return { error: "Không phải lượt của AI này" };

  // 1. Nếu đang ở giai đoạn BỎ BÀI (DISCARD)
  if (state.phase === "DISCARD") {
    const excess = ai.hand.length - ai.hp;
    if (excess > 0) {
      const discarded = ai.hand.splice(0, excess);
      for (const d of discarded) {
        state._discard.push(d);
        state.discardTop = { id: d.id, name: d.name };
      }
    }
    return handleEndTurn(state, aiSeat);
  }

  // 2. Nếu đang ở giai đoạn AWAIT phản ứng từ người khác thì chưa thể ra bài mới
  if (state.phase !== "PLAY") {
    return { success: true, state, message: "Đang chờ phản ứng" };
  }

  // 3. AI tìm lá bài để sử dụng theo thứ tự ưu tiên:
  // A. Hồi máu nếu HP < MaxHP
  if (ai.hp < ai.maxHp) {
    const peach = ai.hand.find(c => c.subType === CARD_SUBTYPES.PEACH);
    if (peach) {
      return handlePlayCard(state, aiSeat, peach.id, aiSeat);
    }
  }

  // B. Rút bài (Dụng Binh Như Thần)
  const exNihilo = ai.hand.find(c => c.subType === CARD_SUBTYPES.EX_NIHILO);
  if (exNihilo) {
    return handlePlayCard(state, aiSeat, exNihilo.id, aiSeat);
  }

  // C. Trang bị vũ khí / giáp / ngựa nếu chưa có
  const equip = ai.hand.find(c => c.category === CARD_CATEGORIES.EQUIPMENT);
  if (equip) {
    const alreadyEquipped = ai.equipments.some(e => e.subType === equip.subType);
    if (!alreadyEquipped) {
      return handlePlayCard(state, aiSeat, equip.id, aiSeat);
    }
  }

  // D. Uống rượu trước khi Trảm nếu có cả Rượu và Trảm
  const wine = ai.hand.find(c => c.subType === CARD_SUBTYPES.WINE);
  const slash = ai.hand.find(c => isSlash(c));
  const enemies = state.players.filter(x => x.isAlly !== ai.isAlly && x.hp > 0);
  const enemyTarget = enemies.length > 0 ? enemies[0] : null;

  if (wine && slash && !ai.isWineBuffActive && enemyTarget) {
    return handlePlayCard(state, aiSeat, wine.id, aiSeat);
  }

  // E. Đánh Trảm nếu chưa vượt giới hạn
  const hasZhuge = ai.equipments.some(e => e.name && e.name.includes("Nỏ Thần"));
  const canSlash = hasZhuge || state.slashesUsedThisTurn === 0;
  if (slash && canSlash && enemyTarget) {
    return handlePlayCard(state, aiSeat, slash.id, enemyTarget.seat);
  }

  // F. Cẩm nang diện rộng (Mưa Tên / Bãi Cọc)
  const aoe = ai.hand.find(c => c.subType === CARD_SUBTYPES.ARROW_RAIN || c.subType === CARD_SUBTYPES.BARBARIAN_INVASION);
  if (aoe) {
    return handlePlayCard(state, aiSeat, aoe.id, 0);
  }

  // G. Cẩm nang phá bài (Vườn Không / Đột Kích)
  const dismantle = ai.hand.find(c => c.subType === CARD_SUBTYPES.DISMANTLE || c.subType === CARD_SUBTYPES.SNATCH);
  if (dismantle && enemyTarget) {
    return handlePlayCard(state, aiSeat, dismantle.id, enemyTarget.seat);
  }

  // H. Không còn bài muốn đánh -> Kết thúc lượt
  return handleEndTurn(state, aiSeat);
}

/**
 * AI tự động phản ứng khi bị nhắm tới (Đỡ, Trảm, Bỏ qua)
 */
export function handleAIReaction(state, aiSeat) {
  if (state.status === "FINISHED") return { error: "Trận đấu đã kết thúc" };
  const ai = state.players.find(x => x.seat === aiSeat);
  if (!ai || (ai.hp <= 0 && state.phase !== "AWAIT_NEAR_DEATH")) return { error: "Người chơi không hợp lệ" };

  if (state.phase === "AWAIT_SLASH_DEFENSE" && state.waitingTargetSeat === aiSeat) {
    const dodge = ai.hand.find(c => isDodge(c));
    if (dodge) {
      return handleRespondAction(state, aiSeat, true, dodge.id);
    } else {
      return handleRespondAction(state, aiSeat, false, null);
    }
  }

  if (state.phase === "AWAIT_AOE" && state.waitingTargetSeat === aiSeat) {
    const reqType = state.waitingReactionType;
    let matchingCard = null;
    if (reqType === "DODGE") matchingCard = ai.hand.find(c => isDodge(c));
    else if (reqType === "SLASH") matchingCard = ai.hand.find(c => isSlash(c));

    if (matchingCard) {
      return handleRespondAction(state, aiSeat, true, matchingCard.id);
    } else {
      return handleRespondAction(state, aiSeat, false, null);
    }
  }

  if (state.phase === "AWAIT_DUEL" && state.waitingTargetSeat === aiSeat) {
    const slash = ai.hand.find(c => isSlash(c));
    if (slash) {
      return handleRespondAction(state, aiSeat, true, slash.id);
    } else {
      return handleRespondAction(state, aiSeat, false, null);
    }
  }

  if (state.phase === "AWAIT_NAM_SON_FOLLOW_UP" && state.waitingTargetSeat === aiSeat) {
    const slash = ai.hand.find(c => isSlash(c));
    if (slash) {
      return handleRespondAction(state, aiSeat, true, slash.id);
    } else {
      return handleRespondAction(state, aiSeat, false, null);
    }
  }

  if (state.phase === "AWAIT_NEAR_DEATH" && state.waitingTargetSeat === aiSeat) {
    const isSelf = (aiSeat === state.nearDeathVictimSeat);
    const peach = ai.hand.find(c => isPeach(c));
    const wine = isSelf ? ai.hand.find(c => isWine(c)) : null;
    const saveCard = peach || wine;

    if (saveCard) {
      return handleRespondAction(state, aiSeat, true, saveCard.id);
    } else {
      return handleRespondAction(state, aiSeat, false, null);
    }
  }

  return { error: "Không có phản ứng nào đang chờ AI này" };
}

/**
 * Format GameState an toàn để gửi về client (ẩn bài của đối thủ nếu cần hoặc gửi công khai 4 tay)
 */
export function sanitizeGameStateForClient(state, requestingSeat = 0) {
  return {
    version: state.version,
    roomId: state.roomId,
    status: state.status,
    turnSeat: state.turnSeat,
    phase: state.phase,
    turnTimer: state.turnTimer,
    waitingTargetSeat: state.waitingTargetSeat,
    waitingReactionType: state.waitingReactionType,
    waitingTimer: state.waitingTimer,
    activeCard: state.activeCard,
    harvestPool: state.harvestPool || [],
    nullifyChain: state.nullifyChain || null,
    lastAction: state.lastAction,
    actionHistory: state.actionHistory || [],
    discardTop: state.discardTop,
    deckCount: state._deck ? state._deck.length : state.deckCount,
    discardCount: state._discard ? state._discard.length : state.discardCount,
    players: state.players.map(p => ({
      seat: p.seat,
      userId: p.userId,
      generalName: p.generalName,
      maxHp: p.maxHp,
      hp: p.hp,
      isAlly: p.isAlly,
      isAI: p.isAI,
      isWineBuffActive: p.isWineBuffActive,
      handCount: p.hand.length,
      // Gửi danh sách bài nếu là chính mình, hoặc nếu muốn công khai
      hand: (requestingSeat === 0 || requestingSeat === p.seat) ? p.hand : p.hand.map(() => ({ id: "HIDDEN", name: "Ẩn" })),
      equipments: p.equipments
    })),
    delta: state.lastDelta || null
  };
}
