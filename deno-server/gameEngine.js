import { createDeck52, createFullDeck104, isSlash, isDodge, isPeach, isWine, CARD_CATEGORIES, CARD_SUBTYPES } from './deck.js';
import { getHeroById, normalizeHeroId } from './heroes.js';

// Cache bộ bài chuẩn để tra cứu subType theo ID
let _deckCache = null;
function getDeckCache() {
  if (!_deckCache) {
    _deckCache = {};
    for (const c of createFullDeck104()) {
      _deckCache[c.id] = c;
    }
  }
  return _deckCache;
}

function formatCardText(card) {
  if (!card) return """";
  if (!card.suit && !card.rank) return "${formatCardText(card)}";
  
  let suitSym = """";
  switch (card.suit) {
    case ""Spade"": suitSym = ""♠""; break;
    case ""Heart"": suitSym = ""<color=#FF5555>♥</color>""; break;
    case ""Club"": suitSym = ""♣""; break;
    case ""Diamond"": suitSym = ""<color=#FF5555>♦</color>""; break;
    default: suitSym = card.suit; break;
  }

  let rankStr = String(card.rank);
  if (card.rank === 1) rankStr = ""A"";
  else if (card.rank === 11) rankStr = ""J"";
  else if (card.rank === 12) rankStr = ""Q"";
  else if (card.rank === 13) rankStr = ""K"";

  return "[${card.name} (${suitSym} ${rankStr})]";
}

/**
 * Tìm lá bài trong bộ bài chuẩn theo ID để lấy subType (dùng khi ID client/server không khớp)
 */
function findCardByIdInDeck(cardId) {
  if (!cardId) return null;
  return getDeckCache()[cardId] || null;
}

function hydrateCard(card) {
  const id = typeof card === "string" ? card : card?.id;
  const canonical = id ? findCardByIdInDeck(id) : null;
  if (canonical) return { ...canonical, ...(typeof card === "object" ? card : {}) };
  if (card && typeof card === "object") return { ...card };
  return null;
}

function hydrateCardList(cards) {
  return Array.isArray(cards) ? cards.map(hydrateCard).filter(Boolean) : [];
}

function isTeamOneSeat(seat) {
  return Number(seat) === 1 || Number(seat) === 3;
}

function areTeammates(leftSeat, rightSeat) {
  return isTeamOneSeat(leftSeat) === isTeamOneSeat(rightSeat);
}

function formatCardText(card) {
  if (!card) return """";
  if (!card.suit && !card.rank) return "${formatCardText(card)}";
  
  let suitSym = """";
  switch (card.suit) {
    case ""Spade"": suitSym = ""♠""; break;
    case ""Heart"": suitSym = ""<color=#FF5555>♥</color>""; break;
    case ""Club"": suitSym = ""♣""; break;
    case ""Diamond"": suitSym = ""<color=#FF5555>♦</color>""; break;
    default: suitSym = card.suit; break;
  }

  let rankStr = String(card.rank);
  if (card.rank === 1) rankStr = ""A"";
  else if (card.rank === 11) rankStr = ""J"";
  else if (card.rank === 12) rankStr = ""Q"";
  else if (card.rank === 13) rankStr = ""K"";

  return "[${card.name} (${suitSym} ${rankStr})]";
}

/**
 * Restore a persisted JSON snapshot into the shape expected by the engine.
 * This accepts both current raw snapshots and older sanitized snapshots,
 * including card arrays serialized as either card objects or card IDs.
 */
export function hydrateGameState(rawState, roomId = "") {
  if (!rawState || typeof rawState !== "object") return null;
  const state = rawState;
  if (!Array.isArray(state.players) || state.players.length !== 4) return null;

  const seenSeats = new Set();
  state.players = state.players.map((rawPlayer, index) => {
    if (!rawPlayer || typeof rawPlayer !== "object") return null;
    const seat = Number(rawPlayer.seat);
    if (!Number.isInteger(seat) || seat < 1 || seat > 4 || seenSeats.has(seat)) return null;
    seenSeats.add(seat);
    const heroId = normalizeHeroId(rawPlayer.heroId, rawPlayer.generalName);
    const hero = getHeroById(heroId);
    const suppliedMaxHp = Number(rawPlayer.maxHp);
    const maxHp = hero?.maxHp || (Number.isFinite(suppliedMaxHp)
      ? Math.max(3, Math.min(4, suppliedMaxHp))
      : 4);
    const hp = Number(rawPlayer.hp);
    return {
      ...rawPlayer,
      seat,
      userId: rawPlayer.userId || `user_${index + 1}`,
      generalName: rawPlayer.generalName || `Tướng Ghế ${seat}`,
      heroId,
      maxHp: Number.isFinite(maxHp) && maxHp > 0 ? maxHp : 4,
      hp: Number.isFinite(hp) ? Math.max(0, Math.min(hp, maxHp)) : 0,
      isAlly: isTeamOneSeat(seat),
      isAI: !!rawPlayer.isAI,
      isWineBuffActive: !!rawPlayer.isWineBuffActive,
      aoBaoCharges: Number.isFinite(Number(rawPlayer.aoBaoCharges))
        ? Math.max(0, Math.min(3, Number(rawPlayer.aoBaoCharges)))
        : 3,
      hand: hydrateCardList(rawPlayer.hand),
      equipments: hydrateCardList(rawPlayer.equipments),
      judgements: hydrateCardList(rawPlayer.judgements),
      // Skills are display-only until their gameplay rules are implemented.
      skills: []
    };
  });
  if (state.players.some((player) => !player)) return null;

  const version = Number(state.version);
  if (!Number.isInteger(version) || version < 1) return null;
  state.version = version;
  state.roomId = roomId || state.roomId || "";
  state.status = state.status === "FINISHED" ? "FINISHED" : "PLAYING";
  state.turnSeat = Number.isInteger(Number(state.turnSeat)) && Number(state.turnSeat) >= 1 && Number(state.turnSeat) <= 4
    ? Number(state.turnSeat) : 1;
  state.phase = typeof state.phase === "string" && state.phase.length > 0 ? state.phase : "PLAY";
  state.turnTimer = Math.max(0, Number(state.turnTimer) || 0);
  state.waitingTargetSeat = Math.max(0, Number(state.waitingTargetSeat) || 0);
  state.waitingReactionType = state.waitingReactionType || "NONE";
  state.waitingTimer = Math.max(0, Number(state.waitingTimer) || 0);
  state.aoeVictimsQueue = Array.isArray(state.aoeVictimsQueue)
    ? state.aoeVictimsQueue.map(Number).filter((seat) => Number.isInteger(seat) && seat >= 1 && seat <= 4)
    : [];
  state.harvestPool = hydrateCardList(state.harvestPool);
  state.harvestPickers = Array.isArray(state.harvestPickers)
    ? state.harvestPickers.map(Number).filter((seat) => Number.isInteger(seat) && seat >= 1 && seat <= 4)
    : [];
  state.nearDeathAskerQueue = Array.isArray(state.nearDeathAskerQueue)
    ? state.nearDeathAskerQueue.map(Number).filter((seat) => Number.isInteger(seat) && seat >= 1 && seat <= 4)
    : [];
  state.duelCasterSeat = Math.max(0, Number(state.duelCasterSeat) || 0);
  state.duelTargetSeat = Math.max(0, Number(state.duelTargetSeat) || 0);
  state.nearDeathVictimSeat = Math.max(0, Number(state.nearDeathVictimSeat) || 0);
  state.turnStart = state.turnStart && typeof state.turnStart === "object"
    ? {
      ...state.turnStart,
      seat: Number(state.turnStart.seat) || 0,
      judgementIndex: Math.max(0, Number(state.turnStart.judgementIndex) || 0),
      judgementCards: hydrateCardList(state.turnStart.judgementCards),
      skipDraw: !!state.turnStart.skipDraw,
      skipPlay: !!state.turnStart.skipPlay
    }
    : null;
  state.pendingAfterNearDeath = state.pendingAfterNearDeath && typeof state.pendingAfterNearDeath === "object"
    ? { ...state.pendingAfterNearDeath }
    : null;
  state.slashesUsedThisTurn = Math.max(0, Number(state.slashesUsedThisTurn) || 0);
  state.isWineBuffActive = !!state.isWineBuffActive;
  state.actionSeq = Math.max(1, Number(state.actionSeq) || Number(state.lastAction?.seq) || 1);
  state.actionHistory = Array.isArray(state.actionHistory) ? state.actionHistory : [];
  state.lastDelta = state.lastDelta || state.delta || null;
  state._deck = hydrateCardList(state._deck);
  state._discard = hydrateCardList(state._discard);
  state.discardTop = hydrateCard(state.discardTop);
  if (state.nullifyChain && typeof state.nullifyChain === "object") {
    state.nullifyChain = {
      ...state.nullifyChain,
      rootCard: hydrateCard(state.nullifyChain.rootCard),
      querySeats: Array.isArray(state.nullifyChain.querySeats)
        ? state.nullifyChain.querySeats.map(Number).filter((seat) => Number.isInteger(seat) && seat >= 1 && seat <= 4)
        : [],
      currentIdx: Math.max(0, Number(state.nullifyChain.currentIdx) || 0),
      whoUsedLast: Number(state.nullifyChain.whoUsedLast) || 0
    };
  } else {
    state.nullifyChain = null;
  }
  if (state.targetCardSelection && typeof state.targetCardSelection === "object") {
    state.targetCardSelection = {
      ...state.targetCardSelection,
      chooserSeat: Number(state.targetCardSelection.chooserSeat) || 0,
      targetSeat: Number(state.targetCardSelection.targetSeat) || 0,
      operation: state.targetCardSelection.operation === "STEAL" ? "STEAL" : "DESTROY",
      options: Array.isArray(state.targetCardSelection.options)
        ? state.targetCardSelection.options.map((option) => ({
          ...option,
          token: String(option?.token || ""),
          zone: String(option?.zone || ""),
          label: String(option?.label || ""),
          card: option?.card ? hydrateCard(option.card) : null
        })).filter((option) => option.token && option.zone)
        : []
    };
  } else {
    state.targetCardSelection = null;
  }
  state.deckCount = state._deck.length;
  state.discardCount = state._discard.length;
  return state;
}

function formatCardText(card) {
  if (!card) return """";
  if (!card.suit && !card.rank) return "${formatCardText(card)}";
  
  let suitSym = """";
  switch (card.suit) {
    case ""Spade"": suitSym = ""♠""; break;
    case ""Heart"": suitSym = ""<color=#FF5555>♥</color>""; break;
    case ""Club"": suitSym = ""♣""; break;
    case ""Diamond"": suitSym = ""<color=#FF5555>♦</color>""; break;
    default: suitSym = card.suit; break;
  }

  let rankStr = String(card.rank);
  if (card.rank === 1) rankStr = ""A"";
  else if (card.rank === 11) rankStr = ""J"";
  else if (card.rank === 12) rankStr = ""Q"";
  else if (card.rank === 13) rankStr = ""K"";

  return "[${card.name} (${suitSym} ${rankStr})]";
}

function formatCardText(card) {
  if (!card) return "";
  if (!card.suit && !card.rank) return "${formatCardText(card)}";
  
  let suitSym = "";
  switch (card.suit) {
    case "Spade": suitSym = "♠"; break;
    case "Heart": suitSym = "<color=#FF5555>♥</color>"; break;
    case "Club": suitSym = "♣"; break;
    case "Diamond": suitSym = "<color=#FF5555>♦</color>"; break;
    default: suitSym = card.suit; break;
  }

  let rankStr = String(card.rank);
  if (card.rank === 1) rankStr = "A";
  else if (card.rank === 11) rankStr = "J";
  else if (card.rank === 12) rankStr = "Q";
  else if (card.rank === 13) rankStr = "K";

  return "[${card.name} (${suitSym} ${rankStr})]";
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

function formatCardText(card) {
  if (!card) return """";
  if (!card.suit && !card.rank) return "${formatCardText(card)}";
  
  let suitSym = """";
  switch (card.suit) {
    case ""Spade"": suitSym = ""♠""; break;
    case ""Heart"": suitSym = ""<color=#FF5555>♥</color>""; break;
    case ""Club"": suitSym = ""♣""; break;
    case ""Diamond"": suitSym = ""<color=#FF5555>♦</color>""; break;
    default: suitSym = card.suit; break;
  }

  let rankStr = String(card.rank);
  if (card.rank === 1) rankStr = ""A"";
  else if (card.rank === 11) rankStr = ""J"";
  else if (card.rank === 12) rankStr = ""Q"";
  else if (card.rank === 13) rankStr = ""K"";

  return "[${card.name} (${suitSym} ${rankStr})]";
}

/**
 * Khởi tạo trận đấu mới (4 người chơi, mỗi người 4 lá, 4 máu)
 */
export function initGame(roomId, playersInput) {
  if (!Array.isArray(playersInput) || playersInput.length !== 4) {
    throw new Error("Trận 2v2 cần đúng 4 người chơi");
  }

  const deckMode = playersInput.length <= 4 ? 52 : 104;
  const deck = shuffle(deckMode === 52 ? createDeck52() : createFullDeck104());
  const discard = [];

  const normalizedInputs = playersInput.map((input, index) => {
    const p = input || {};
    const hasExplicitSeat = p.seat !== undefined && p.seat !== null && p.seat !== "";
    const requestedSeat = hasExplicitSeat ? Number(p.seat) : index + 1;
    if (!Number.isInteger(requestedSeat) || requestedSeat < 1 || requestedSeat > 4) {
      throw new Error("Mỗi người chơi phải có ghế hợp lệ từ 1 đến 4");
    }
    return {
      ...p,
      seat: requestedSeat
    };
  }).sort((left, right) => left.seat - right.seat);

  if (new Set(normalizedInputs.map((player) => player.seat)).size !== 4) {
    throw new Error("Các ghế trong trận đấu không được trùng nhau");
  }

  const players = normalizedInputs.map((p, index) => {
    // Keep the wire protocol backwards compatible: older Unity clients send
    // only generalName/maxHp, while newer clients send a string heroId.
    const heroId = normalizeHeroId(p.heroId, p.generalName);
    const hero = getHeroById(heroId);
    const maxHp = hero?.maxHp || 4;
    const hand = [];
    for (let i = 0; i < 4; i++) {
      if (deck.length > 0) hand.push(deck.pop());
    }
    return {
      seat: p.seat || index + 1,
      userId: p.userId || `user_${index + 1}`,
      heroId,
      generalName: p.generalName || hero?.name || `Tướng Ghế ${index + 1}`,
      maxHp,
      hp: maxHp,
      isAlly: isTeamOneSeat(p.seat || index + 1), // Ghế 1 & 3 là Đội 1; Ghế 2 & 4 là Đội 2
      isAI: !!p.isAI,
      isWineBuffActive: false,
      aoBaoCharges: 3,
      hand: hand,
      equipments: [],
      judgements: [],
      skills: []
    };
  });

  const initialState = {
    version: 1,
    roomId,
    status: "PLAYING", // "PLAYING" | "FINISHED"
    turnSeat: 1,
    phase: "PLAY", // "PLAY" | "AWAIT_NULLIFY" | "AWAIT_TARGET_CARD" | "AWAIT_SLASH_DEFENSE" | "AWAIT_AOE" | "AWAIT_DUEL" | "AWAIT_NEAR_DEATH" | "DISCARD"
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
    targetCardSelection: null,
    turnStart: null,
    pendingAfterNearDeath: null,
    actionSeq: 1,
    actionHistory: [{
      seq: 1,
      type: "GAME_START",
      description: `Trận đấu bắt đầu với bộ bài ${deckMode} lá! Ghế 1 được rút thêm 1 lá và bắt đầu lượt.`,
      timestamp: Date.now()
    }],
    lastAction: {
      seq: 1,
      type: "GAME_START",
      description: `Trận đấu bắt đầu với bộ bài ${deckMode} lá! Ghế 1 được rút thêm 1 lá và bắt đầu lượt.`,
      timestamp: Date.now()
    },
    discardTop: null,
    deckCount: deck.length,
    discardCount: 0,
    players,
    _deck: deck, // Bộ bài ẩn trên server
    _discard: discard
  };

  // The first player receives one draw at match start; later turns draw two.
  drawCards(initialState, initialState.turnSeat, 1);
  return initialState;
}

function formatCardText(card) {
  if (!card) return """";
  if (!card.suit && !card.rank) return "${formatCardText(card)}";
  
  let suitSym = """";
  switch (card.suit) {
    case ""Spade"": suitSym = ""♠""; break;
    case ""Heart"": suitSym = ""<color=#FF5555>♥</color>""; break;
    case ""Club"": suitSym = ""♣""; break;
    case ""Diamond"": suitSym = ""<color=#FF5555>♦</color>""; break;
    default: suitSym = card.suit; break;
  }

  let rankStr = String(card.rank);
  if (card.rank === 1) rankStr = ""A"";
  else if (card.rank === 11) rankStr = ""J"";
  else if (card.rank === 12) rankStr = ""Q"";
  else if (card.rank === 13) rankStr = ""K"";

  return "[${card.name} (${suitSym} ${rankStr})]";
}

/**
 * Kiểm tra Optimistic Locking: nếu client gửi expectedVersion thì phải khớp với state.version
 */
export function checkVersion(state, expectedVersion) {
  if (expectedVersion !== undefined && expectedVersion !== null) {
    const exp = parseInt(expectedVersion, 10);
    if (!isNaN(exp) && exp > 0 && state.version !== exp) {
      return {
        error: `Conflict: State version mismatch (expected: ${exp}, current: ${state.version})`,
        code: "VERSION_CONFLICT",
        conflict: true
      };
    }
  }
  return null;
}

function buildStateDelta(state) {
  const action = state.lastAction || {};
  return {
    version: state.version,
    actionSeq: state.actionSeq,
    type: action.type,
    description: action.description,
    turnSeat: state.turnSeat,
    phase: state.phase,
    turnTimer: state.turnTimer,
    waitingTargetSeat: state.waitingTargetSeat,
    waitingReactionType: state.waitingReactionType,
    waitingTimer: state.waitingTimer,
    nearDeathVictimSeat: state.nearDeathVictimSeat,
    nearDeathAskerQueue: state.nearDeathAskerQueue || [],
    aoeVictimsQueue: state.aoeVictimsQueue || [],
    harvestPickers: state.harvestPickers || [],
    slashesUsedThisTurn: state.slashesUsedThisTurn || 0,
    duelCasterSeat: state.duelCasterSeat || 0,
    duelTargetSeat: state.duelTargetSeat || 0,
    activeCard: state.activeCard,
    deckCount: state._deck ? state._deck.length : state.deckCount,
    discardCount: state._discard ? state._discard.length : state.discardCount,
    discardTop: state.discardTop,
    status: state.status,
    harvestPool: state.harvestPool || [],
    nullifyChain: state.nullifyChain || null,
    targetCardSelection: state.targetCardSelection || null,
    playerDeltas: state.players.map(p => ({
      seat: p.seat,
      hp: p.hp,
      maxHp: p.maxHp,
      handCount: p.hand ? p.hand.length : 0,
      isWineBuffActive: !!p.isWineBuffActive,
      aoBaoCharges: Number.isFinite(Number(p.aoBaoCharges)) ? Number(p.aoBaoCharges) : 3,
      equipments: p.equipments || [],
      judgements: p.judgements || []
    }))
  };
}

export function refreshLastDelta(state) {
  if (!state || !state.lastAction) return null;
  state.lastDelta = buildStateDelta(state);
  return state.lastDelta;
}

// Give every accepted action a fresh version, including a pass that only
// advances a response queue.
export function ensureMutationVersion(state, previousVersion) {
  if (!state || state.version !== previousVersion) return state?.version || previousVersion;
  state.version = previousVersion + 1;
  refreshLastDelta(state);
  return state.version;
}

function formatCardText(card) {
  if (!card) return """";
  if (!card.suit && !card.rank) return "${formatCardText(card)}";
  
  let suitSym = """";
  switch (card.suit) {
    case ""Spade"": suitSym = ""♠""; break;
    case ""Heart"": suitSym = ""<color=#FF5555>♥</color>""; break;
    case ""Club"": suitSym = ""♣""; break;
    case ""Diamond"": suitSym = ""<color=#FF5555>♦</color>""; break;
    default: suitSym = card.suit; break;
  }

  let rankStr = String(card.rank);
  if (card.rank === 1) rankStr = ""A"";
  else if (card.rank === 11) rankStr = ""J"";
  else if (card.rank === 12) rankStr = ""Q"";
  else if (card.rank === 13) rankStr = ""K"";

  return "[${card.name} (${suitSym} ${rankStr})]";
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
  refreshLastDelta(state);
}

function formatCardText(card) {
  if (!card) return """";
  if (!card.suit && !card.rank) return "${formatCardText(card)}";
  
  let suitSym = """";
  switch (card.suit) {
    case ""Spade"": suitSym = ""♠""; break;
    case ""Heart"": suitSym = ""<color=#FF5555>♥</color>""; break;
    case ""Club"": suitSym = ""♣""; break;
    case ""Diamond"": suitSym = ""<color=#FF5555>♦</color>""; break;
    default: suitSym = card.suit; break;
  }

  let rankStr = String(card.rank);
  if (card.rank === 1) rankStr = ""A"";
  else if (card.rank === 11) rankStr = ""J"";
  else if (card.rank === 12) rankStr = ""Q"";
  else if (card.rank === 13) rankStr = ""K"";

  return "[${card.name} (${suitSym} ${rankStr})]";
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

function formatCardText(card) {
  if (!card) return """";
  if (!card.suit && !card.rank) return "${formatCardText(card)}";
  
  let suitSym = """";
  switch (card.suit) {
    case ""Spade"": suitSym = ""♠""; break;
    case ""Heart"": suitSym = ""<color=#FF5555>♥</color>""; break;
    case ""Club"": suitSym = ""♣""; break;
    case ""Diamond"": suitSym = ""<color=#FF5555>♦</color>""; break;
    default: suitSym = card.suit; break;
  }

  let rankStr = String(card.rank);
  if (card.rank === 1) rankStr = ""A"";
  else if (card.rank === 11) rankStr = ""J"";
  else if (card.rank === 12) rankStr = ""Q"";
  else if (card.rank === 13) rankStr = ""K"";

  return "[${card.name} (${suitSym} ${rankStr})]";
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

function discardCard(state, card, reveal = true) {
  if (!card) return;
  state._discard.push(card);
  state.discardTop = {
    id: reveal ? card.id : "HIDDEN",
    name: reveal ? card.name : "Lá úp",
    suit: reveal ? card.suit : "",
    rank: reveal ? card.rank : 0
  };
  state.discardCount = state._discard.length;
}

function getDistance(state, fromSeat, toSeat) {
  if (fromSeat === toSeat) return 0;
  const livingPlayers = (state.players || [])
    .filter((player) => player && player.hp > 0)
    .sort((left, right) => left.seat - right.seat);
  const fromIndex = livingPlayers.findIndex((player) => player.seat === fromSeat);
  const toIndex = livingPlayers.findIndex((player) => player.seat === toSeat);
  if (fromIndex < 0 || toIndex < 0 || livingPlayers.length <= 1) {
    return Number.POSITIVE_INFINITY;
  }

  const count = livingPlayers.length;
  const clockwiseDistance = (toIndex - fromIndex + count) % count;
  const counterClockwiseDistance = (fromIndex - toIndex + count) % count;
  let distance = Math.min(clockwiseDistance, counterClockwiseDistance);
  const from = livingPlayers[fromIndex];
  const to = livingPlayers[toIndex];
  distance += (from.equipments || [])
    .filter((equipment) => equipment.subType === CARD_SUBTYPES.OFFENSIVE_HORSE)
    .reduce((total, equipment) => total + (Number(equipment.distMod) || -1), 0);
  distance += (to.equipments || [])
    .filter((equipment) => equipment.subType === CARD_SUBTYPES.DEFENSIVE_HORSE)
    .reduce((total, equipment) => total + (Number(equipment.distMod) || 1), 0);
  return Math.max(1, distance);
}

function hasWeaponRange(state, fromSeat, toSeat) {
  const from = state.players.find((player) => player.seat === fromSeat);
  if (!from) return false;
  const weapon = (from.equipments || []).find((equipment) => equipment.subType === CARD_SUBTYPES.WEAPON);
  const range = weapon && Number.isFinite(Number(weapon.range)) ? Number(weapon.range) : 1;
  return getDistance(state, fromSeat, toSeat) <= range;
}

function getEquippedWeapon(player, nameFragment = "") {
  if (!player) return null;
  return (player.equipments || []).find((equipment) =>
    equipment.subType === CARD_SUBTYPES.WEAPON
      && (!nameFragment || equipment.name?.includes(nameFragment))
  ) || null;
}

function resetWaitingState(state, clearActiveCard = true) {
  state.phase = "PLAY";
  state.waitingTargetSeat = 0;
  state.waitingReactionType = "NONE";
  state.waitingTimer = 0;
  if (clearActiveCard) state.activeCard = null;
  refreshLastDelta(state);
}

function requiresTarget(card) {
  return isSlash(card) || [
    CARD_SUBTYPES.DUEL,
    CARD_SUBTYPES.SNATCH,
    CARD_SUBTYPES.DISMANTLE,
    CARD_SUBTYPES.SUPPLY_SHORTAGE,
    CARD_SUBTYPES.ACEDIA,
    CARD_SUBTYPES.FLAWLESS_DEFENSE,
  ].includes(card?.subType);
}

function validateTarget(state, casterSeat, targetSeat, card) {
  if (!requiresTarget(card)) return null;
  const normalizedTarget = Number(targetSeat);
  if (!Number.isInteger(normalizedTarget) || normalizedTarget < 1 || normalizedTarget > 4) {
    return { error: "Cần chọn mục tiêu" };
  }
  if (normalizedTarget === casterSeat) return { error: "Không thể chọn chính mình" };
  const target = state.players.find((player) => player.seat === normalizedTarget);
  if (!target || target.hp <= 0) return { error: "Mục tiêu không hợp lệ" };
  if (areTeammates(casterSeat, normalizedTarget)) return { error: "Chỉ được chọn tướng đối phương" };
  if (isSlash(card) && !hasWeaponRange(state, casterSeat, normalizedTarget)) {
    return { error: "Mục tiêu ngoài tầm đánh" };
  }
  if ([CARD_SUBTYPES.SNATCH, CARD_SUBTYPES.SUPPLY_SHORTAGE].includes(card.subType)
      && getDistance(state, casterSeat, normalizedTarget) > 1) {
    return { error: "Mục tiêu ngoài tầm" };
  }
  return null;
}

function formatCardText(card) {
  if (!card) return """";
  if (!card.suit && !card.rank) return "${formatCardText(card)}";
  
  let suitSym = """";
  switch (card.suit) {
    case ""Spade"": suitSym = ""♠""; break;
    case ""Heart"": suitSym = ""<color=#FF5555>♥</color>""; break;
    case ""Club"": suitSym = ""♣""; break;
    case ""Diamond"": suitSym = ""<color=#FF5555>♦</color>""; break;
    default: suitSym = card.suit; break;
  }

  let rankStr = String(card.rank);
  if (card.rank === 1) rankStr = ""A"";
  else if (card.rank === 11) rankStr = ""J"";
  else if (card.rank === 12) rankStr = ""Q"";
  else if (card.rank === 13) rankStr = ""K"";

  return "[${card.name} (${suitSym} ${rankStr})]";
}

/**
 * Xử lý khi một người chơi đánh ra 1 lá bài từ tay
 */
export function handlePlayCard(state, casterSeat, cardId, targetSeat = 0) {
  if (state.status === "FINISHED") return { error: "Trận đấu đã kết thúc" };
  casterSeat = Number(casterSeat);
  if (targetSeat !== undefined && targetSeat !== null && targetSeat !== "") {
    const parsedTarget = Number(targetSeat);
    targetSeat = Number.isFinite(parsedTarget) ? parsedTarget : targetSeat;
  }
  if (state.phase !== "PLAY" || state.turnSeat !== casterSeat) {
    return { error: "Chưa tới lượt của bạn" };
  }

  const caster = state.players.find(x => x.seat === casterSeat);
  if (!caster || caster.hp <= 0) return { error: "Người chơi không hợp lệ" };

  // Card IDs are authoritative; never substitute a different card by subtype.
  let cardIndex = caster.hand.findIndex(c => c.id === cardId);
  if (cardIndex < 0) {
     console.error("[handlePlayCard] Mismatch! Client requested cardId:", cardId, "but hand has:", caster.hand.map(c => c.id));
     return { error: "Không tìm thấy lá bài trên tay (" + cardId + ")" };
  }

  const targetValidation = validateTarget(state, casterSeat, targetSeat, caster.hand[cardIndex]);
  if (targetValidation) return targetValidation;
  const selectedCard = caster.hand[cardIndex];
  if (isDodge(selectedCard)) {
    return { error: "Lá Đỡ chỉ được dùng khi đang phản ứng một đòn tấn công" };
  }
  if (selectedCard.subType === CARD_SUBTYPES.PEACH && caster.hp >= caster.maxHp) {
    return { error: "Máu đã đầy, không thể dùng Bánh Chưng" };
  }
  if ([CARD_SUBTYPES.LIGHTNING, CARD_SUBTYPES.SUPPLY_SHORTAGE, CARD_SUBTYPES.ACEDIA].includes(selectedCard.subType)) {
    const attachTarget = selectedCard.subType === CARD_SUBTYPES.LIGHTNING
      ? caster
      : state.players.find((player) => player.seat === targetSeat);
    if (attachTarget?.judgements?.some((judgement) => judgement.subType === selectedCard.subType)) {
      return { error: "Mục tiêu đã có cẩm nang trì hoãn cùng loại" };
    }
  }
  if (isSlash(caster.hand[cardIndex])
      && state.slashesUsedThisTurn > 0
      && !caster.equipments.some(e => e.name && e.name.includes("Nỏ Thần"))) {
    return { error: "Đã dùng hết lượt Trảm" };
  }

  const card = caster.hand.splice(cardIndex, 1)[0];
  const target = state.players.find(x => x.seat === targetSeat);
  state.turnTimer = 40;

  if (card.subType === CARD_SUBTYPES.FLAWLESS_DEFENSE) {
    return startNullifyChain(state, card, casterSeat, targetSeat);
  }

  // 1. LÁ TRẢM (Slash)
  if (isSlash(card)) {
    discardCard(state, card);
    state.slashesUsedThisTurn++;
    const isWine = !!(caster.isWineBuffActive || state.isWineBuffActive);
    const damage = isWine ? 2 : 1;
    caster.isWineBuffActive = false;
    state.isWineBuffActive = false;

    if (card.subType === CARD_SUBTYPES.ATTACK_NORMAL
        && target?.equipments?.some((equipment) =>
          equipment.subType === CARD_SUBTYPES.ARMOR && equipment.name?.includes("Giáp Đồng"))) {
      recordAction(state, {
        type: "SLASH_BLOCKED_BY_ARMOR",
        casterSeat,
        targetSeat,
        cardId: card.id,
        cardName: card.name,
        description: `🛡️ [Giáp Đồng Sơn Vi] vô hiệu hóa ${formatCardText(card)} của ${caster.generalName}!`
      });
      return { success: true, state };
    }

    state.phase = "AWAIT_SLASH_DEFENSE";
    state.waitingTargetSeat = targetSeat;
    state.waitingReactionType = "DODGE";
    state.waitingTimer = 40;
    state.activeCard = {
        cardId: card.id,
        cardName: card.name,
        suit: card.suit,
        casterSeat,
        targetSeat,
        damage,
        isWineBuff: isWine
      };

      const cannon = getEquippedWeapon(caster, "Súng Thần Công");
      const requiredDodgeText = cannon ? ` (yêu cầu lá Đỡ khác chất <b>${card.suit === "Heart" ? "<color=#FF5555>♥</color>" : card.suit === "Diamond" ? "<color=#FF5555>♦</color>" : card.suit === "Club" ? "♣" : "♠"}</b>)` : ``;

      recordAction(state, {
        type: "PLAY_SLASH",
        casterSeat,
        targetSeat,
        cardId: card.id,
        cardName: card.name,
        damage,
        isWineBuff: isWine,
        description: `🗡️ <b>${caster.generalName}</b> tung chiêu ${formatCardText(card)} nhắm vào <b>${target ? target.generalName : 'đối thủ'}</b>! (Mục tiêu có 40s để Đỡ${requiredDodgeText})`
      });
    if (tryKhienMayDefense(state, targetSeat, "đòn Trảm")) {
      beginSlashAfterDodge(state, caster, targetSeat, "Khiên Mây Bện");
      return { success: true, state };
    }
    return { success: true, state };
  }

  // 2. BÁNH CHƯNG (Peach)
  if (card.subType === CARD_SUBTYPES.PEACH) {
    if (caster.hp >= caster.maxHp) {
      caster.hand.push(card);
      return { error: "Máu đã đầy, không thể dùng Bánh Chưng" };
    }
    discardCard(state, card);
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
    discardCard(state, card);
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
    const replacedIndex = caster.equipments.findIndex((equipment) => equipment.subType === card.subType);
    if (replacedIndex >= 0) {
      const replaced = caster.equipments.splice(replacedIndex, 1)[0];
      discardCard(state, replaced);
    }
    caster.equipments.push(card);
    if (card.subType === CARD_SUBTYPES.ARMOR && card.name && card.name.includes("Áo Bào")) {
      caster.aoBaoCharges = 3;
    }
    recordAction(state, {
      type: "EQUIP",
      casterSeat,
      cardId: card.id,
      cardName: card.name,
      description: `🛡️ <b>${caster.generalName}</b> trang bị ${formatCardText(card)}: ${card.desc}`
    });
    return { success: true, state };
  }

  // 5. CÁC LÁ CẨM NANG (Instant / Delayed Scroll) -> BẮT ĐẦU CHUỖI HỎI DIỆU KẾ PHÁ MƯU (AWAIT_NULLIFY)
  if (card.category === CARD_CATEGORIES.DELAYED_SCROLL || card.subType === CARD_SUBTYPES.LIGHTNING || card.subType === CARD_SUBTYPES.SUPPLY_SHORTAGE || card.subType === CARD_SUBTYPES.ACEDIA) {
    return executeCardEffect(state, card, casterSeat, targetSeat);
  }
  return startNullifyChain(state, card, casterSeat, targetSeat);
}

function formatCardText(card) {
  if (!card) return """";
  if (!card.suit && !card.rank) return "${formatCardText(card)}";
  
  let suitSym = """";
  switch (card.suit) {
    case ""Spade"": suitSym = ""♠""; break;
    case ""Heart"": suitSym = ""<color=#FF5555>♥</color>""; break;
    case ""Club"": suitSym = ""♣""; break;
    case ""Diamond"": suitSym = ""<color=#FF5555>♦</color>""; break;
    default: suitSym = card.suit; break;
  }

  let rankStr = String(card.rank);
  if (card.rank === 1) rankStr = ""A"";
  else if (card.rank === 11) rankStr = ""J"";
  else if (card.rank === 12) rankStr = ""Q"";
  else if (card.rank === 13) rankStr = ""K"";

  return "[${card.name} (${suitSym} ${rankStr})]";
}

/**
 * Khởi động chuỗi hỏi Diệu Kế Phá Mưu (AWAIT_NULLIFY) theo vòng 4 ghế
 */
export function startNullifyChain(state, card, casterSeat, targetSeat = 0, continuation = null) {
  const caster = state.players.find(x => x.seat === casterSeat);
  const target = state.players.find(x => x.seat === targetSeat);
  const firstSeat = Number.isInteger(Number(state.turnSeat)) && Number(state.turnSeat) >= 1
    ? Number(state.turnSeat)
    : casterSeat;

  const querySeats = [];
  for (let i = 0; i < 4; i++) {
    const s = ((firstSeat - 1 + i) % 4) + 1;
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
    whoUsedLast: null,
    continuation
  };
  state.waitingTargetSeat = querySeats[0];
  state.waitingReactionType = "FLAWLESS_DEFENSE";
  state.waitingTimer = 40;
  state.activeCard = {
    cardId: card.id,
    cardName: card.name,
    casterSeat,
    targetSeat,
    nullifyRound: 0,
    nullifyBySeat: 0
  };

  const targetDesc = target ? ` lên #${target.seat} (${target.generalName})` : "";
  const firstQueriedGen = state.players.find(x => x.seat === querySeats[0]);
  recordAction(state, {
    type: "NULLIFY_START",
    casterSeat,
    targetSeat,
    cardId: card.id,
    cardName: card.name,
    description: `📜 <b>${caster ? caster.generalName : 'Ghế ' + casterSeat}</b> thi triển ${formatCardText(card)}${targetDesc}! Đang hỏi <b>${firstQueriedGen ? firstQueriedGen.generalName : 'Ghế ' + querySeats[0]}</b> có dùng Diệu Kế Phá Mưu không (40s)...`
  });

  return { success: true, state };
}

function drawJudgementCard(state) {
  if (state._deck.length === 0 && state._discard.length > 0) {
    state._deck = shuffle(state._discard);
    state._discard = [];
  }
  const card = state._deck.pop() || null;
  if (card) discardCard(state, card);
  state.deckCount = state._deck.length;
  return card;
}

function tryKhienMayDefense(state, targetSeat, sourceDescription) {
  const target = state.players.find((player) => player.seat === targetSeat);
  const armor = target?.equipments?.find((equipment) =>
    equipment.subType === CARD_SUBTYPES.ARMOR && equipment.name?.includes("Khiên Mây")
  );
  if (!armor) return false;

  const judgeCard = drawJudgementCard(state);
  if (!judgeCard) return false;
  const isRed = judgeCard.suit === "Heart" || judgeCard.suit === "Diamond";
  recordAction(state, {
    type: isRed ? "KHIEN_MAY_SUCCESS" : "KHIEN_MAY_FAILED",
    targetSeat,
    cardId: armor.id,
    cardName: armor.name,
    description: isRed
      ? `🛡️ [Khiên Mây Bện] của ${target.generalName} lật ${judgeCard.suit} ${judgeCard.rank} và tự động Đỡ ${sourceDescription}!`
      : `🛡️ [Khiên Mây Bện] của ${target.generalName} lật ${judgeCard.suit} ${judgeCard.rank} và phán xét thất bại.`
  });
  return isRed;
}

function beginSlashAfterDodge(state, caster, targetSeat, defenseName = "Đỡ") {
  const target = state.players.find((player) => player.seat === targetSeat);
  const songCung = getEquippedWeapon(caster, "Song Cung");
  const hasNamSon = !!caster?.equipments?.some((equipment) =>
    equipment.name?.includes("Trường Đao")
  );
  const canFollowWithNamSon = hasNamSon
    && !state.activeCard?.namSonFollowUp
    && caster.hand.some(isSlash);

  if (songCung && caster.hand.length >= 2) {
    state.phase = "AWAIT_SONG_CUNG_FOLLOW_UP";
    state.waitingTargetSeat = caster.seat;
    state.waitingTimer = 40;
    state.waitingReactionType = "DISCARD_TWO";
    recordAction(state, {
      type: "SONG_CUNG_PROMPT",
      casterSeat: caster.seat,
      targetSeat,
      description: `🏹 [Song Cung Mường Nhạ]: ${defenseName} đã hóa giải đòn đánh! ${caster.generalName} có muốn bỏ 2 lá trên tay để ép mục tiêu chịu 1 sát thương không? (40s)`
    });
    return;
  }

  if (canFollowWithNamSon) {
    state.phase = "AWAIT_NAM_SON_FOLLOW_UP";
    state.waitingTargetSeat = caster.seat;
    state.waitingTimer = 40;
    state.waitingReactionType = "SLASH";
    recordAction(state, {
      type: "NAM_SON_PROMPT",
      casterSeat: caster.seat,
      targetSeat,
      description: `🗡️ [Trường Đao Nam Sơn]: ${defenseName} đã hóa giải đòn đánh! ${caster.generalName} có muốn bỏ 1 Trảm tiếp tục truy kích không? (40s)`
    });
    return;
  }

  resetWaitingState(state);
  recordAction(state, {
    type: "DODGE_SUCCESS",
    casterSeat: targetSeat,
    targetSeat,
    cardId: state.discardTop?.id || "",
    description: `🛡️ ${target?.generalName || `Ghế ${targetSeat}`} đã dùng ${defenseName} hóa giải đòn Trảm!`
  });
}

function beginNextAoeVictim(state) {
  while (state.aoeVictimsQueue && state.aoeVictimsQueue.length > 0) {
    const nextVictim = state.aoeVictimsQueue.shift();
    const victim = state.players.find((player) => player.seat === nextVictim);
    if (!victim || victim.hp <= 0) continue;

    if (state.activeCard?.reqType === "DODGE" && tryKhienMayDefense(state, nextVictim, "đòn diện rộng")) {
      continue;
    }

    state.phase = "AWAIT_AOE";
    state.waitingReactionType = state.activeCard?.reqType || "DODGE";
    state.waitingTargetSeat = nextVictim;
    state.waitingTimer = 40;
    return true;
  }

  resetWaitingState(state);
  return false;
}

function buildTargetCardOptions(state, targetSeat, allowDelayed = true) {
  const target = state.players.find((player) => player.seat === targetSeat);
  if (!target) return [];

  const options = [];
  for (let index = 0; index < (target.hand || []).length; index++) {
    options.push({
      token: `HAND:${index}`,
      zone: "HAND",
      label: "TRÊN TAY",
      card: null
    });
  }
  for (const equipment of target.equipments || []) {
    options.push({
      token: `EQUIPMENT:${equipment.id}`,
      zone: "EQUIPMENT",
      label: "TRANG BỊ",
      card: equipment
    });
  }
  if (allowDelayed) {
    for (const judgement of target.judgements || []) {
      options.push({
        token: `JUDGEMENT:${judgement.id}`,
        zone: "JUDGEMENT",
        label: "TRÌ HOÃN",
        card: judgement
      });
    }
  }
  return options;
}

function resetTargetCardSelection(state) {
  state.targetCardSelection = null;
  resetWaitingState(state);
}

function startTargetCardSelection(state, card, casterSeat, targetSeat, selectionOptions = {}) {
  const allowDelayed = selectionOptions.allowDelayed !== undefined
    ? selectionOptions.allowDelayed !== false
    : card.subType === CARD_SUBTYPES.SNATCH || card.subType === CARD_SUBTYPES.DISMANTLE || card.subType === CARD_SUBTYPES.FLAWLESS_DEFENSE;
  const options = buildTargetCardOptions(state, targetSeat, allowDelayed);
  const caster = state.players.find((player) => player.seat === casterSeat);
  const target = state.players.find((player) => player.seat === targetSeat);
  if (options.length === 0) {
    resetTargetCardSelection(state);
    recordAction(state, {
      type: "PLAY_SCROLL",
      casterSeat,
      targetSeat,
      cardId: card.id,
      cardName: card.name,
      description: `📜 <b>${caster ? caster.generalName : 'Người chơi'}</b> dùng ${formatCardText(card)} lên <b>${target ? target.generalName : 'mục tiêu'}</b>, nhưng mục tiêu không có bài để chọn.`
    });
    return { success: true, state };
  }

  const operation = selectionOptions.operation || (card.subType === CARD_SUBTYPES.SNATCH ? "STEAL" : "DESTROY");
  state.targetCardSelection = {
    chooserSeat: casterSeat,
    targetSeat,
    operation,
    cardId: card.id,
    cardName: card.name,
    options,
    effectType: selectionOptions.effectType || "TARGET_CARD"
  };
  state.phase = "AWAIT_TARGET_CARD";
  state.waitingTargetSeat = casterSeat;
  state.waitingReactionType = "TARGET_CARD";
  state.waitingTimer = 40;
  state.activeCard = {
    cardId: card.id,
    cardName: card.name,
    casterSeat,
    targetSeat,
    selectionOperation: operation
  };
  recordAction(state, {
    type: "TARGET_CARD_PROMPT",
    casterSeat,
    targetSeat,
    cardId: card.id,
    cardName: card.name,
    description: `${operation === "STEAL" ? "🌾" : "🏚️"} <b>${caster ? caster.generalName : 'Người chơi'}</b> đang ${operation === "STEAL" ? "chọn 1 lá để cướp" : "chọn 1 lá để hủy"} từ <b>${target ? target.generalName : 'mục tiêu'}</b> (40s)...`
  });
  return { success: true, state };
}

function resolveTargetCardToken(state, selection, targetCardId) {
  if (!selection || !targetCardId) return null;
  const option = selection.options?.find((candidate) => candidate.token === targetCardId);
  if (!option) return null;
  const target = state.players.find((player) => player.seat === selection.targetSeat);
  if (!target) return null;

  if (option.zone === "HAND") {
    const index = Number(targetCardId.slice("HAND:".length));
    if (!Number.isInteger(index) || index < 0 || index >= target.hand.length) return null;
    return { target, option, index, card: target.hand[index] };
  }

  const prefix = option.zone === "EQUIPMENT" ? "EQUIPMENT:" : "JUDGEMENT:";
  if (!targetCardId.startsWith(prefix)) return null;
  const cardId = targetCardId.slice(prefix.length);
  const cards = option.zone === "EQUIPMENT" ? target.equipments : target.judgements;
  const index = cards.findIndex((card) => card.id === cardId);
  if (index < 0) return null;
  return { target, option, index, card: cards[index] };
}

function completeTargetCardSelection(state, chooserSeat, targetCardId) {
  const selection = state.targetCardSelection;
  if (!selection || selection.chooserSeat !== chooserSeat) {
    return { error: "Không có lựa chọn bài mục tiêu đang chờ" };
  }

  const token = targetCardId || selection.options[0]?.token;
  const resolved = resolveTargetCardToken(state, selection, token);
  if (!resolved) return { error: "Lá bài mục tiêu không còn hợp lệ" };

  const { target, option, index, card } = resolved;
  const cards = option.zone === "HAND" ? target.hand
    : option.zone === "EQUIPMENT" ? target.equipments
      : target.judgements;
  cards.splice(index, 1);

  const caster = state.players.find((player) => player.seat === chooserSeat);
  if (selection.operation === "STEAL") {
    caster.hand.push(card);
  } else {
    discardCard(state, card, option.zone !== "HAND");
  }

  const actionType = selection.effectType === "THUONG_NGAU"
    ? "THUONG_NGAU_DESTROY"
    : selection.effectType === "FLAWLESS_DEFENSE"
      ? "PLAY_FLAWLESS_DEFENSE"
    : selection.operation === "STEAL" ? "PLAY_SNATCH" : "PLAY_DISMANTLE";
  const actionVerb = selection.operation === "STEAL" ? "cướp" : "phá hủy";
  const publicTargetName = option.zone === "HAND" ? "lá úp trên tay" : card.name;
  resetTargetCardSelection(state);
  recordAction(state, {
    type: actionType,
    casterSeat: chooserSeat,
    targetSeat: target.seat,
    cardId: selection.cardId,
    cardName: selection.cardName,
    targetCardId: option.zone === "HAND" ? null : card.id,
    targetCardName: publicTargetName,
    targetCardZone: option.zone,
    description: `${selection.operation === "STEAL" ? "🌾" : "🏚️"} <b>${caster ? caster.generalName : 'Người chơi'}</b> dùng [${selection.cardName}] ${actionVerb} [${publicTargetName}] của <b>${target.generalName}</b>!`
  });
  checkGameOver(state);
  return { success: true, state };
}

function formatCardText(card) {
  if (!card) return """";
  if (!card.suit && !card.rank) return "${formatCardText(card)}";
  
  let suitSym = """";
  switch (card.suit) {
    case ""Spade"": suitSym = ""♠""; break;
    case ""Heart"": suitSym = ""<color=#FF5555>♥</color>""; break;
    case ""Club"": suitSym = ""♣""; break;
    case ""Diamond"": suitSym = ""<color=#FF5555>♦</color>""; break;
    default: suitSym = card.suit; break;
  }

  let rankStr = String(card.rank);
  if (card.rank === 1) rankStr = ""A"";
  else if (card.rank === 11) rankStr = ""J"";
  else if (card.rank === 12) rankStr = ""Q"";
  else if (card.rank === 13) rankStr = ""K"";

  return "[${card.name} (${suitSym} ${rankStr})]";
}

/**
 * Thực thi hiệu ứng cẩm nang sau khi chuỗi Diệu Kế kết thúc và không bị hóa giải
 */
export function executeCardEffect(state, card, casterSeat, targetSeat = 0) {
  const caster = state.players.find(x => x.seat === casterSeat);
  const target = state.players.find(x => x.seat === targetSeat);

  // 1. DỤNG BINH NHƯ THẦN (Ex Nihilo)
  if (card.subType === CARD_SUBTYPES.EX_NIHILO) {
    discardCard(state, card);
    const drawn = drawCards(state, casterSeat, 2);
    resetWaitingState(state);
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
    discardCard(state, card);
    const living = [];
    for (let i = 0; i < 4; i++) {
      const s = ((state.turnSeat - 1 + i) % 4) + 1;
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
    state.harvestPickers = living.slice(0, pool.length).map(p => p.seat);
    if (state.harvestPool.length === 0 || state.harvestPickers.length === 0) {
      state.harvestPool = [];
      state.harvestPickers = [];
      resetWaitingState(state);
      recordAction(state, {
        type: "HARVEST_EMPTY",
        casterSeat,
        cardId: card.id,
        cardName: card.name,
        description: `🍚 [Mở Kho Cứu Tế] không còn lá bài để chia.`
      });
      return { success: true, state };
    }
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
    discardCard(state, card);
    const reqType = (card.subType === CARD_SUBTYPES.ARROW_RAIN) ? "DODGE" : "SLASH";
    const reqName = (card.subType === CARD_SUBTYPES.ARROW_RAIN) ? "Đỡ" : "Trảm";
    const victims = [];
    for (let i = 1; i <= 3; i++) {
      const nextSeat = ((casterSeat - 1 + i) % 4) + 1;
      const v = state.players.find(x => x.seat === nextSeat);
      if (v && v.hp > 0) victims.push(nextSeat);
    }

    if (victims.length > 0) {
      state.aoeVictimsQueue = victims;
      state.activeCard = { cardId: card.id, cardName: card.name, casterSeat, reqType, reqName };
      beginNextAoeVictim(state);
      const firstVictim = state.waitingTargetSeat || victims[0];
      recordAction(state, {
        type: "PLAY_AOE",
        casterSeat,
        targetSeat: firstVictim,
        cardId: card.id,
        cardName: card.name,
        description: `🏹 <b>${caster ? caster.generalName : 'Người chơi'}</b> thi triển ${formatCardText(card)}! Đang kiểm tra <b>Ghế ${firstVictim}</b> (cần [${reqName}] - 40s)...`
      });
    } else {
      resetWaitingState(state);
    }
    return { success: true, state };
  }

  // 4. THÁCH ĐẤU (Duel)
  if (card.subType === CARD_SUBTYPES.DUEL) {
    discardCard(state, card);
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
      card.attachedBySeat = casterSeat;
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
    resetWaitingState(state);
    return { success: true, state };
  }

  // 6. CÁC LÁ CẨM NANG ĐƠN MỤC TIÊU (Vườn Không Nhà Trống, Đột Kích Trộm Lương...)
  if (card.subType === CARD_SUBTYPES.FLAWLESS_DEFENSE) {
    discardCard(state, card);
    return startTargetCardSelection(state, card, casterSeat, targetSeat, {
      allowDelayed: true,
      operation: "DESTROY",
      effectType: "FLAWLESS_DEFENSE"
    });
  }
  discardCard(state, card);
  return startTargetCardSelection(state, card, casterSeat, targetSeat, {
    allowDelayed: card.subType === CARD_SUBTYPES.SNATCH || card.subType === CARD_SUBTYPES.DISMANTLE || card.subType === CARD_SUBTYPES.FLAWLESS_DEFENSE
  });
}

function formatCardText(card) {
  if (!card) return """";
  if (!card.suit && !card.rank) return "${formatCardText(card)}";
  
  let suitSym = """";
  switch (card.suit) {
    case ""Spade"": suitSym = ""♠""; break;
    case ""Heart"": suitSym = ""<color=#FF5555>♥</color>""; break;
    case ""Club"": suitSym = ""♣""; break;
    case ""Diamond"": suitSym = ""<color=#FF5555>♦</color>""; break;
    default: suitSym = card.suit; break;
  }

  let rankStr = String(card.rank);
  if (card.rank === 1) rankStr = ""A"";
  else if (card.rank === 11) rankStr = ""J"";
  else if (card.rank === 12) rankStr = ""Q"";
  else if (card.rank === 13) rankStr = ""K"";

  return "[${card.name} (${suitSym} ${rankStr})]";
}

/**
 * Xử lý phản ứng từ người bị nhắm tới (Đỡ, Trảm, Bỏ qua / Hết giờ, Diệu Kế Phá Mưu, Chọn bài kho lương)
 */

function formatCardText(card) {
  if (!card) return """";
  if (!card.suit && !card.rank) return "${formatCardText(card)}";
  
  let suitSym = """";
  switch (card.suit) {
    case ""Spade"": suitSym = ""♠""; break;
    case ""Heart"": suitSym = ""<color=#FF5555>♥</color>""; break;
    case ""Club"": suitSym = ""♣""; break;
    case ""Diamond"": suitSym = ""<color=#FF5555>♦</color>""; break;
    default: suitSym = card.suit; break;
  }

  let rankStr = String(card.rank);
  if (card.rank === 1) rankStr = ""A"";
  else if (card.rank === 11) rankStr = ""J"";
  else if (card.rank === 12) rankStr = ""Q"";
  else if (card.rank === 13) rankStr = ""K"";

  return "[${card.name} (${suitSym} ${rankStr})]";
}

/**
* KhÃ´i phá»¥c láº¡i luá»“ng game sau khi pha Háº¥p Há»“i (Near Death) káº¿t thÃºc (cá»©u sá»‘ng hoáº·c cháº¿t)
*/
function resolveNearDeathResume(state) {
    state.waitingTargetSeat = 0;
    state.waitingTimer = 0;
    state.nearDeathAskerQueue = [];
    state.nearDeathVictimSeat = 0;

    if (state.turnStart) {
        return continueTurnStart(state);
    }

    if (state.pendingAfterNearDeath) {
        const pending = state.pendingAfterNearDeath;
        state.pendingAfterNearDeath = null;
        const target = state.players.find((player) => player.seat === pending.targetSeat);
        if (pending.type === "THUONG_NGAU" && target && target.hp > 0) {
            const weapon = state.players
              .find((player) => player.seat === pending.casterSeat)
              ?.equipments?.find((equipment) => equipment.id === pending.weaponId)
              || { id: pending.weaponId, name: pending.weaponName };
            return startTargetCardSelection(state, weapon, pending.casterSeat, pending.targetSeat, {
              allowDelayed: false,
              operation: "DESTROY",
              effectType: "THUONG_NGAU"
            });
        }
    }
    
    // Náº¿u Ä‘ang dá»Ÿ dang AOE (MÆ°a TÃªn / BÃ£i Cá»c), tiáº¿p tá»¥c há»i náº¡n nhÃ¢n káº¿ tiáº¿p
    if (state.aoeVictimsQueue && state.aoeVictimsQueue.length > 0) {
        beginNextAoeVictim(state);
        refreshLastDelta(state);
        return { success: true, state };
    }
    
    // Náº¿u Ä‘ang dá»Ÿ dang ThÃ¡ch Ä‘áº¥u, xá»a tráº¡ng thÃ¡i (vÃ¬ ngÆ°á»i bá»‹ thÆ°Æ¡ng Ä‘Ã£ thua cuá»™c Ä‘áº¥u)
    state.duelCasterSeat = 0;
    state.duelTargetSeat = 0;
    state.activeCard = null;
    resetWaitingState(state);
    const currentPlayer = state.players.find((player) => player.seat === state.turnSeat);
    if (!currentPlayer || currentPlayer.hp <= 0) {
      return advanceTurn(state);
    }
    refreshLastDelta(state);
    return { success: true, state };
}

function finalizePlayerDeath(state, victim) {
  if (!victim) return "";

  const discardedCount = (victim.hand || []).length;
  const equipmentCount = (victim.equipments || []).length;
  const judgementCount = (victim.judgements || []).length;
  for (const card of victim.hand || []) discardCard(state, card, false);
  for (const card of victim.equipments || []) discardCard(state, card, true);
  for (const card of victim.judgements || []) discardCard(state, card, true);
  victim.hand = [];
  victim.equipments = [];
  victim.judgements = [];
  victim.isWineBuffActive = false;
  victim.aoBaoCharges = 0;

  const discardedTotal = discardedCount + equipmentCount + judgementCount;
  return discardedTotal > 0
    ? ` Đã bỏ ${discardedCount} lá trên tay, ${equipmentCount} lá trang bị và ${judgementCount} lá trì hoãn của nạn nhân.`
    : "";
}

export function handleRespondAction(state, respondentSeat, accepted, cardId, targetCardId = null, cardIds = null) {
  if (state.status === "FINISHED") return { error: "Trận đấu đã kết thúc" };
  respondentSeat = Number(respondentSeat);
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
      const idx = respondent.hand.findIndex(c => c.id === cardId
        && (c.subType === CARD_SUBTYPES.FLAWLESS_DEFENSE
          || (c.name && c.name.includes("Diệu Kế"))));
      if (idx < 0) return { error: "Lá Diệu Kế Phá Mưu không còn hợp lệ" };
      {
        const nullifyCard = respondent.hand.splice(idx, 1)[0];
        discardCard(state, nullifyCard);

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
        state.activeCard = {
          ...state.activeCard,
          nullifyRound: (Number(state.activeCard?.nullifyRound) || 0) + 1,
          nullifyBySeat: respondentSeat
        };

        recordAction(state, {
          type: "NULLIFY_PLAYED",
          casterSeat: respondentSeat,
          cardId: nullifyCard.id,
          cardName: nullifyCard.name,
          description: `🛡️ <b>${respondent.generalName}</b> đã tung <color=#55FF55><b>[Diệu Kế Phá Mưu]</b></color>! Trạng thái mưu kế ${formatCardText(rootCard)}: ${chain.isCanceled ? '<color=#FF5555>BỊ VÔ HIỆU HÓA</color>' : '<color=#55FF55>ĐƯỢC BẢO VỆ THÀNH CÔNG</color>'}. Đang hỏi Ghế ${newQuerySeats[0]} (40s)...`
        });
        return { success: true, state };
      }
    }

    if (accepted) return { error: "Cần chọn một lá Diệu Kế Phá Mưu hợp lệ" };

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
      discardCard(state, rootCard);
      state.nullifyChain = null;
      resetWaitingState(state);
      recordAction(state, {
        type: "NULLIFY_SUCCEEDED",
        description: `🛡️ Mưu kế ${formatCardText(rootCard)} đã chính thức bị vô hiệu hóa hoàn toàn bởi Diệu Kế Phá Mưu!`
      });
      if (chain.continuation?.type === "TURN_JUDGEMENT") {
        return continueTurnStart(state);
      }
      return { success: true, state };
    }

    // Mưu kế được thực thi thành công!
    const { casterSeat, targetSeat } = chain;
    state.nullifyChain = null;
    if (chain.continuation?.type === "TURN_JUDGEMENT") {
      resolveJudgementCard(state, rootCard, chain.continuation.seat);
      if (state.phase === "AWAIT_NEAR_DEATH") return { success: true, state };
      return continueTurnStart(state);
    }
    return executeCardEffect(state, rootCard, casterSeat, targetSeat);
  }

  if (state.phase === "AWAIT_TARGET_CARD") {
    if (!accepted) return { error: "Cần chọn một lá bài mục tiêu" };
    return completeTargetCardSelection(state, respondentSeat, targetCardId);
  }

  // --- 0.5. PHẢN HỒI CHỌN BÀI KHO LƯƠNG (AWAIT_HARVEST) ---
  if (state.phase === "AWAIT_HARVEST" && state.harvestPool) {
    let pickedCard = null;
    if (cardId) {
      const idx = state.harvestPool.findIndex(c => c.id === cardId);
      if (idx < 0) return { error: "Lá Kho Cứu Tế không còn hợp lệ" };
      pickedCard = state.harvestPool.splice(idx, 1)[0];
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
      refreshLastDelta(state);
      return { success: true, state };
    } else {
      // Đã chia xong toàn bộ bài trong kho
      resetWaitingState(state);
      state.harvestPool = [];
      state.harvestPickers = [];
      refreshLastDelta(state);
      return { success: true, state };
    }
  }

  // --- 1. PHẢN HỒI ĐÒN TRẢM ---
  if (state.phase === "AWAIT_SLASH_DEFENSE") {
    if (accepted && cardId) {
      const caster = state.players.find(x => x.seat === (state.activeCard ? state.activeCard.casterSeat : 0));
      const holyCannon = getEquippedWeapon(caster, "Súng Thần Công");
      const idx = respondent.hand.findIndex(c => c.id === cardId && isDodge(c)
        && (!holyCannon || c.suit !== state.activeCard?.suit));
      if (idx < 0) return { error: "Lá Đỡ không còn hợp lệ cho đòn Trảm này" };
      {
        const dodgeCard = respondent.hand.splice(idx, 1)[0];
        discardCard(state, dodgeCard);

        beginSlashAfterDodge(state, caster, respondentSeat, `[${dodgeCard.name}]`);
        return { success: true, state };
      }
    }

    if (accepted) return { error: "Cần chọn một lá Đỡ hợp lệ" };

    // Không né hoặc hết giờ -> Chịu sát thương
    const damage = (state.activeCard && state.activeCard.damage) ? state.activeCard.damage : 1;
    const activeCard = state.activeCard;
    const damageResult = applyDamageToPlayer(state, respondentSeat, damage, "đòn Trảm");
    const caster = state.players.find((player) => player.seat === activeCard?.casterSeat);
    const thuongNgau = getEquippedWeapon(caster, "Thương Ngâu");
    if (damageResult?.finalDamage > 0 && thuongNgau) {
      if (state.phase === "AWAIT_NEAR_DEATH") {
        state.pendingAfterNearDeath = {
          type: "THUONG_NGAU",
          casterSeat: caster.seat,
          targetSeat: respondentSeat,
          weaponId: thuongNgau.id,
          weaponName: thuongNgau.name
        };
      } else {
        const target = state.players.find((player) => player.seat === respondentSeat);
        if (target?.hp > 0) {
          return startTargetCardSelection(state, thuongNgau, caster.seat, respondentSeat, {
            allowDelayed: false,
            operation: "DESTROY",
            effectType: "THUONG_NGAU"
          });
        }
      }
    }
    if (state.phase !== "AWAIT_NEAR_DEATH" && state.phase !== "AWAIT_TARGET_CARD") {
      resetWaitingState(state);
    }
    checkGameOver(state);
    return { success: true, state };
  }

  if (state.phase === "AWAIT_SONG_CUNG_FOLLOW_UP") {
    const caster = respondent;
    const targetSeat = state.activeCard?.targetSeat || 0;
    const requestedIds = Array.isArray(cardIds) ? cardIds : [];
    if (accepted) {
      const distinctIds = [...new Set(requestedIds.filter(Boolean))];
      if (distinctIds.length !== 2) return { error: "Cần chọn đúng 2 lá để kích hoạt Song Cung" };
      const indexes = distinctIds.map((id) => caster.hand.findIndex((card) => card.id === id));
      if (indexes.some((index) => index < 0)) return { error: "Lá bỏ cho Song Cung không còn hợp lệ" };
      const cards = indexes
        .sort((left, right) => right - left)
        .map((index) => caster.hand.splice(index, 1)[0]);
      for (const card of cards) discardCard(state, card);
      recordAction(state, {
        type: "SONG_CUNG_TRIGGERED",
        casterSeat: caster.seat,
        targetSeat,
        description: `🏹 <b>${caster.generalName}</b> bỏ 2 lá kích hoạt [Song Cung Mường Nhạ], ép Ghế ${targetSeat} chịu 1 sát thương!`
      });
      applyDamageToPlayer(state, targetSeat, 1, "Song Cung Mường Nhạ", true);
      if (state.phase !== "AWAIT_NEAR_DEATH") resetWaitingState(state);
      checkGameOver(state);
      return { success: true, state };
    }

    resetWaitingState(state);
    recordAction(state, {
      type: "SONG_CUNG_PASSED",
      casterSeat: caster.seat,
      targetSeat,
      description: `🏹 ${caster.generalName} không kích hoạt Song Cung Mường Nhạ. Mục tiêu né Trảm thành công.`
    });
    return { success: true, state };
  }

  // --- 1.5. PHẢN HỒI TRƯỜNG ĐAO NAM SƠN (CASTER CHỌN BỎ TRẢM ĐỂ TRUY KÍCH) ---
  if (state.phase === "AWAIT_NAM_SON_FOLLOW_UP") {
    const caster = respondent;
    const targetSeat = state.activeCard ? state.activeCard.targetSeat : 0;
    const target = state.players.find(x => x.seat === targetSeat);

    if (accepted && cardId) {
      const idx = caster.hand.findIndex(c => c.id === cardId && isSlash(c));
      if (idx < 0) return { error: "Lá Trảm truy kích không còn hợp lệ" };
      {
        const slashCard = caster.hand.splice(idx, 1)[0];
        discardCard(state, slashCard);

        // Ép mục tiêu lại phải Đỡ tiếp (40s)
        state.phase = "AWAIT_SLASH_DEFENSE";
        state.waitingTargetSeat = targetSeat;
        state.waitingReactionType = "DODGE";
        state.waitingTimer = 40;
        state.activeCard = {
          ...state.activeCard,
          cardId: slashCard.id,
          cardName: slashCard.name,
          suit: slashCard.suit,
          damage: 1,
          isWineBuff: false,
          namSonFollowUp: true
        };
        if (slashCard.subType === CARD_SUBTYPES.ATTACK_NORMAL
            && target?.equipments?.some((equipment) =>
              equipment.subType === CARD_SUBTYPES.ARMOR && equipment.name?.includes("Giáp Đồng"))) {
          resetWaitingState(state);
          recordAction(state, {
            type: "SLASH_BLOCKED_BY_ARMOR",
            casterSeat: caster.seat,
            targetSeat,
            cardId: slashCard.id,
            cardName: slashCard.name,
            description: `🛡️ [Giáp Đồng Sơn Vi] vô hiệu hóa lá Trảm truy kích của ${caster.generalName}!`
          });
          return { success: true, state };
        }
        recordAction(state, {
          type: "NAM_SON_FOLLOW_UP_PLAYED",
          casterSeat: caster.seat,
          targetSeat: targetSeat,
          cardId: slashCard.id,
          cardName: slashCard.name,
          description: `🗡️ <color=#FFD700><b>[TRƯỜNG ĐAO NAM SƠN]</b></color>: <b>${caster.generalName}</b> bỏ thêm lá [<b>${slashCard.name}</b>] tiếp tục truy kích <b>${target ? target.generalName : 'đối thủ'}</b>!`
        });
        if (tryKhienMayDefense(state, targetSeat, "đòn Trảm truy kích")) {
          beginSlashAfterDodge(state, caster, targetSeat, "Khiên Mây Bện");
        }
        return { success: true, state };
      }
    }

    if (accepted) return { error: "Cần chọn một lá Trảm truy kích hợp lệ" };

    // Caster từ chối ra Trảm hoặc hết giờ -> Hóa giải thành công, quay về PLAY
    resetWaitingState(state);
    recordAction(state, {
      type: "NAM_SON_PASSED",
      casterSeat: caster.seat,
      description: `🛡️ ${caster.generalName} từ chối dùng thêm Trảm. ${target ? target.generalName : 'Mục tiêu'} đã né đòn thành công!`
    });
    return { success: true, state };
  }

  // --- 2. PHẢN HỒI CẨM NANG DIỆN RỘNG (Mưa Tên / Bãi Cọc Ngầm) ---
  if (state.phase === "AWAIT_AOE") {
    const isArrow = state.waitingReactionType === "DODGE"
      || state.activeCard?.reqType === "DODGE";
    let satisfied = false;

    if (accepted && cardId) {
      const idx = respondent.hand.findIndex(c => c.id === cardId && (isArrow ? isDodge(c) : isSlash(c)));
      if (idx < 0) return { error: `Lá ${isArrow ? "Đỡ" : "Trảm"} không còn hợp lệ` };
      const c = respondent.hand.splice(idx, 1)[0];
      discardCard(state, c);
      satisfied = true;
    }

    if (accepted && !cardId) {
      return { error: `Cần chọn một lá ${isArrow ? "Đỡ" : "Trảm"} hợp lệ` };
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
      cardId: satisfied ? (state.discardTop?.id || "") : "",
      description: satisfied
        ? `🛡️ ${respondent.generalName} đã né đòn diện rộng thành công!`
        : `💥 ${respondent.generalName} không ra bài né, bị mất 1 máu (${respondent.hp}/${respondent.maxHp})!`
    });

    // Chuyển sang nạn nhân kế tiếp nếu còn
    beginNextAoeVictim(state);
    refreshLastDelta(state);

    checkGameOver(state);
    return { success: true, state };
  }

  // --- 3. PHẢN HỒI THÁCH ĐẤU ---
  if (state.phase === "AWAIT_DUEL") {
    if (accepted && cardId) {
      const idx = respondent.hand.findIndex(c => c.id === cardId && isSlash(c));
      if (idx < 0) return { error: "Lá Trảm đáp trả không còn hợp lệ" };
      {
        const s = respondent.hand.splice(idx, 1)[0];
        discardCard(state, s);

        // Đổi lượt sang đối phương
        const otherSeat = (respondentSeat === state.duelCasterSeat) ? state.duelTargetSeat : state.duelCasterSeat;
        state.waitingTargetSeat = otherSeat;
        state.waitingTimer = 40;
        refreshLastDelta(state);
        recordAction(state, {
          type: "DUEL_RESPOND",
          casterSeat: respondentSeat,
          cardId: s.id,
          description: `⚔️ ${respondent.generalName} đáp trả 1 lá ${formatCardText(s)} trong Thách Đấu!`
        });
        return { success: true, state };
      }
    }

    if (accepted) return { error: "Cần chọn một lá Trảm hợp lệ để đáp trả" };

    // Không ra Trảm -> Nhận thua Thách Đấu và mất 1 Máu
    applyDamageToPlayer(state, respondentSeat, 1, "Thách Đấu");
    if (state.phase !== "AWAIT_NEAR_DEATH") {
      state.duelCasterSeat = 0;
      state.duelTargetSeat = 0;
      resetWaitingState(state);
    }
    checkGameOver(state);
    return { success: true, state };
  }

  // --- 4. PHẢN HỒI CỨU HẤP HỐI (Bánh Chưng / Hủ Rượu) ---
  if (state.phase === "AWAIT_NEAR_DEATH") {
    const victim = state.players.find(x => x.seat === state.nearDeathVictimSeat);
    if (accepted && victim) {
      if (!cardId) return { error: "Cần chọn Bánh Chưng hoặc Hủ Rượu hợp lệ để cứu" };
      const idx = respondent.hand.findIndex(c => c.id === cardId && (isPeach(c) || (isWine(c) && respondentSeat === victim.seat)));
      if (idx < 0) return { error: "Lá cứu không còn hợp lệ" };
      const rescueCard = respondent.hand.splice(idx, 1)[0];
      discardCard(state, rescueCard);

      victim.hp = Math.min(victim.maxHp, Math.max(1, victim.hp + 1));
      state.phase = "PLAY";
      state.waitingTargetSeat = 0;
      state.waitingTimer = 0;
      recordAction(state, {
        type: "RESCUE_SUCCESS",
        casterSeat: respondentSeat,
        targetSeat: victim.seat,
        description: `💮 <b>${respondent.generalName}</b> đã dùng ${formatCardText(rescueCard)} cứu sống <b>${victim.generalName}</b> (${victim.hp}/${victim.maxHp})!`
      });
      const resume = resolveNearDeathResume(state);
      refreshLastDelta(state);
      return resume;
    }

    // Nếu người này không cứu -> Hỏi người tiếp theo trong danh sách cứu viện
    if (state.nearDeathAskerQueue && state.nearDeathAskerQueue.length > 0) {
      const nextAsker = state.nearDeathAskerQueue.shift();
      state.waitingTargetSeat = nextAsker;
      state.waitingTimer = 40;
      refreshLastDelta(state);
      return { success: true, state };
    } else {
      // Không ai cứu -> Tử trận
      state.phase = "PLAY";
      state.waitingTargetSeat = 0;
      state.waitingTimer = 0;
      if (victim) victim.hp = 0;
      const deathSummary = finalizePlayerDeath(state, victim);
      recordAction(state, {
        type: "PLAYER_DIED",
        targetSeat: victim ? victim.seat : 0,
        description: `☠️ Không ai cứu viện! <b>${victim ? victim.generalName : 'Người chơi'}</b> đã tử trận!${deathSummary}`
      });
      checkGameOver(state);
      if (state.status !== "FINISHED") return resolveNearDeathResume(state);
      return { success: true, state };
    }
  }

  return { error: "Giai đoạn không hỗ trợ phản hồi này" };
}

function formatCardText(card) {
  if (!card) return """";
  if (!card.suit && !card.rank) return "${formatCardText(card)}";
  
  let suitSym = """";
  switch (card.suit) {
    case ""Spade"": suitSym = ""♠""; break;
    case ""Heart"": suitSym = ""<color=#FF5555>♥</color>""; break;
    case ""Club"": suitSym = ""♣""; break;
    case ""Diamond"": suitSym = ""<color=#FF5555>♦</color>""; break;
    default: suitSym = card.suit; break;
  }

  let rankStr = String(card.rank);
  if (card.rank === 1) rankStr = ""A"";
  else if (card.rank === 11) rankStr = ""J"";
  else if (card.rank === 12) rankStr = ""Q"";
  else if (card.rank === 13) rankStr = ""K"";

  return "[${card.name} (${suitSym} ${rankStr})]";
}

/**
 * Áp dụng sát thương lên người chơi và kích hoạt pha Hấp Hối (Near Death) nếu HP <= 0
 */
export function applyDamageToPlayer(state, targetSeat, damage, sourceDescription = "") {
  const target = state.players.find(x => x.seat === targetSeat);
  if (!target || target.hp <= 0) return { finalDamage: 0, enteredNearDeath: false };

  const rawDamage = Math.max(0, Number(damage) || 0);
  let finalDamage = rawDamage;
  const armorIndex = target.equipments.findIndex((equipment) =>
    equipment.subType === CARD_SUBTYPES.ARMOR && equipment.name?.includes("Áo Bào")
  );
  if (armorIndex >= 0 && rawDamage > 0) {
    target.aoBaoCharges = Number.isFinite(Number(target.aoBaoCharges)) ? Number(target.aoBaoCharges) : 3;
    if (target.aoBaoCharges > 0) {
      target.aoBaoCharges--;
      finalDamage = Math.max(0, rawDamage - 1);
      if (target.aoBaoCharges === 0) {
        const expiredArmor = target.equipments.splice(armorIndex, 1)[0];
        discardCard(state, expiredArmor);
      }
    }
  }

  target.hp -= finalDamage;

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
         damage: finalDamage,
         description: `🆘 <b>${target.generalName}</b> trúng đòn bị mất ${finalDamage} máu và rơi vào trạng thái Hấp Hối (0 Máu)! Đang chờ Ghế ${firstAsker} cứu viện (40s)...`
      });
       return { finalDamage, enteredNearDeath: true };
    } else {
      // Không còn ai có thể cứu
      target.hp = 0;
      state.phase = "PLAY";
      state.waitingTargetSeat = 0;
      state.waitingTimer = 0;
      const deathSummary = finalizePlayerDeath(state, target);
      recordAction(state, {
        type: "PLAYER_DIED",
        targetSeat,
        description: `☠️ <b>${target.generalName}</b> đã tử trận!${deathSummary}`
      });
      checkGameOver(state);
       return { finalDamage, enteredNearDeath: false };
    }
  }

  state.phase = "PLAY";
  state.waitingTargetSeat = 0;
  state.waitingTimer = 0;
  recordAction(state, {
    type: "DAMAGE_TAKEN",
    targetSeat,
     damage: finalDamage,
     description: `💥 <b>${target.generalName}</b> bị mất ${finalDamage} đóa sen máu (${target.hp}/${target.maxHp})!`
  });
  return { finalDamage, enteredNearDeath: false };
}

function formatCardText(card) {
  if (!card) return """";
  if (!card.suit && !card.rank) return "${formatCardText(card)}";
  
  let suitSym = """";
  switch (card.suit) {
    case ""Spade"": suitSym = ""♠""; break;
    case ""Heart"": suitSym = ""<color=#FF5555>♥</color>""; break;
    case ""Club"": suitSym = ""♣""; break;
    case ""Diamond"": suitSym = ""<color=#FF5555>♦</color>""; break;
    default: suitSym = card.suit; break;
  }

  let rankStr = String(card.rank);
  if (card.rank === 1) rankStr = ""A"";
  else if (card.rank === 11) rankStr = ""J"";
  else if (card.rank === 12) rankStr = ""Q"";
  else if (card.rank === 13) rankStr = ""K"";

  return "[${card.name} (${suitSym} ${rankStr})]";
}

/**
 * Kết thúc lượt đánh (Chuyển sang bỏ bài nếu thừa, hoặc rút bài cho người kế tiếp)
 */
export function handleEndTurn(state, casterSeat) {
  if (state.status === "FINISHED") return { error: "Trận đấu đã kết thúc" };
  casterSeat = Number(casterSeat);
  if (state.phase !== "PLAY" || state.turnSeat !== casterSeat) {
    return { error: "Chưa tới lượt hoặc đang trong pha phản ứng" };
  }

  const caster = state.players.find(x => x.seat === casterSeat);
  if (!caster || caster.hp <= 0) return { error: "Người chơi không hợp lệ" };
  caster.isWineBuffActive = false;
  state.isWineBuffActive = false;

  // Kiểm tra bài thừa so với máu
  const excess = caster.hand.length - caster.hp;
  if (excess > 0 && caster.hp > 0) {
    state.phase = "DISCARD";
    state.waitingTargetSeat = casterSeat;
    state.waitingReactionType = "DISCARD";
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

function formatCardText(card) {
  if (!card) return """";
  if (!card.suit && !card.rank) return "${formatCardText(card)}";
  
  let suitSym = """";
  switch (card.suit) {
    case ""Spade"": suitSym = ""♠""; break;
    case ""Heart"": suitSym = ""<color=#FF5555>♥</color>""; break;
    case ""Club"": suitSym = ""♣""; break;
    case ""Diamond"": suitSym = ""<color=#FF5555>♦</color>""; break;
    default: suitSym = card.suit; break;
  }

  let rankStr = String(card.rank);
  if (card.rank === 1) rankStr = ""A"";
  else if (card.rank === 11) rankStr = ""J"";
  else if (card.rank === 12) rankStr = ""Q"";
  else if (card.rank === 13) rankStr = ""K"";

  return "[${card.name} (${suitSym} ${rankStr})]";
}

/**
 * Xử lý bỏ bài thừa
 */
export function handleDiscardCards(state, seat, cardIds) {
  seat = Number(seat);
  if (state.phase !== "DISCARD" || state.waitingTargetSeat !== seat) {
    return { error: "Không trong giai đoạn bỏ bài" };
  }

  const p = state.players.find(x => x.seat === seat);
  if (!p) return { error: "Người chơi không hợp lệ" };

  const excess = Math.max(0, p.hand.length - p.hp);
  const requestedIds = Array.isArray(cardIds) ? [...new Set(cardIds.filter(Boolean))] : [];
  if (requestedIds.length > excess) {
    return { error: `Chỉ được bỏ ${excess} lá bài thừa` };
  }
  if (requestedIds.length > 0 && requestedIds.length !== excess) {
    return { error: `Cần chọn đủ ${excess} lá bài thừa` };
  }

  for (const id of requestedIds) {
    const idx = p.hand.findIndex(c => c.id === id);
    if (idx < 0) return { error: "Lá bài bỏ không còn trên tay" };
    const discarded = p.hand.splice(idx, 1)[0];
    discardCard(state, discarded, false);
  }

  // Nếu vẫn còn thừa (do tự động hết giờ), tự động bỏ lá cuối
  while (p.hand.length > p.hp && p.hand.length > 0) {
    const discarded = p.hand.pop();
    discardCard(state, discarded, false);
  }

  return advanceTurn(state);
}

function findNextJudgementRecipient(state, currentSeat, subType) {
  for (let offset = 1; offset <= 4; offset++) {
    const seat = ((currentSeat - 1 + offset) % 4) + 1;
    const player = state.players.find((candidate) => candidate.seat === seat);
    if (player?.hp > 0 && !(player.judgements || []).some((card) => card.subType === subType)) {
      return player;
    }
  }
  return null;
}

function resolveJudgementCard(state, judgementCard, targetSeat) {
  const target = state.players.find((player) => player.seat === targetSeat);
  if (!target || !judgementCard) return;
  const judgeCard = drawJudgementCard(state) || { suit: "Heart", rank: 10, name: "Bài Phán Xét" };

  if (judgementCard.subType === CARD_SUBTYPES.LIGHTNING) {
    const isHit = judgeCard.suit === "Spade" && judgeCard.rank >= 2 && judgeCard.rank <= 9;
    if (isHit) {
      discardCard(state, judgementCard);
      recordAction(state, {
        type: "LIGHTNING_HIT",
        targetSeat,
        cardId: judgementCard.id,
        description: `⚡⚡⚡ [Thần Sấm Báo Ứng] phán xét ${judgeCard.suit} ${judgeCard.rank}: <b>${target.generalName}</b> chịu 3 sát thương Lôi!`
      });
      applyDamageToPlayer(state, targetSeat, 3, "Thần Sấm Báo Ứng");
      return;
    }

    const recipient = findNextJudgementRecipient(state, targetSeat, CARD_SUBTYPES.LIGHTNING);
    if (recipient) recipient.judgements.push(judgementCard);
    else discardCard(state, judgementCard);
    recordAction(state, {
      type: "LIGHTNING_PASSED",
      targetSeat,
      description: recipient
        ? `⚡ [Thần Sấm Báo Ứng] phán xét ${judgeCard.suit} ${judgeCard.rank} không trúng, chuyển sang <b>${recipient.generalName}</b>.`
        : `⚡ [Thần Sấm Báo Ứng] không trúng và không còn vùng phán xét hợp lệ, lá bài bị bỏ.`
    });
    return;
  }

  discardCard(state, judgementCard);
  if (judgementCard.subType === CARD_SUBTYPES.SUPPLY_SHORTAGE) {
    const triggered = judgeCard.suit !== "Club";
    if (state.turnStart) state.turnStart.skipDraw ||= triggered;
    recordAction(state, {
      type: triggered ? "SUPPLY_SHORTAGE_TRIGGERED" : "SUPPLY_SHORTAGE_PASSED",
      targetSeat,
      description: triggered
        ? `🌾❌ <b>${target.generalName}</b> phán xét ${judgeCard.suit} ${judgeCard.rank}, bị bỏ qua Giai đoạn Rút bài.`
        : `🌾✅ <b>${target.generalName}</b> phán xét ra Chuồn, hóa giải Cắt Đường Lương.`
    });
    return;
  }

  if (judgementCard.subType === CARD_SUBTYPES.ACEDIA) {
    const triggered = judgeCard.suit !== "Heart";
    if (state.turnStart) state.turnStart.skipPlay ||= triggered;
    recordAction(state, {
      type: triggered ? "ACEDIA_TRIGGERED" : "ACEDIA_PASSED",
      targetSeat,
      description: triggered
        ? `🕸️❌ <b>${target.generalName}</b> phán xét ${judgeCard.suit} ${judgeCard.rank}, bị bỏ qua Giai đoạn Ra bài.`
        : `🕸️✅ <b>${target.generalName}</b> phán xét ra Cơ, thoát Trầm Ảo Sa Bẫy.`
    });
  }
}

function continueTurnStart(state) {
  const turnStart = state.turnStart;
  if (!turnStart) return { success: true, state };
  const player = state.players.find((candidate) => candidate.seat === turnStart.seat);
  if (!player || player.hp <= 0) {
    state.turnStart = null;
    return advanceTurn(state);
  }

  if (turnStart.judgementIndex < turnStart.judgementCards.length) {
    const judgementCard = turnStart.judgementCards[turnStart.judgementIndex++];
    const attachedBySeat = Number(judgementCard.attachedBySeat) || turnStart.seat;
    return startNullifyChain(state, judgementCard, attachedBySeat, turnStart.seat, {
      type: "TURN_JUDGEMENT",
      seat: turnStart.seat
    });
  }

  const skipDraw = turnStart.skipDraw;
  const skipPlay = turnStart.skipPlay;
  state.turnStart = null;
  resetWaitingState(state);
  if (!skipDraw) drawCards(state, player.seat, 2);

  if (skipPlay) {
    const excess = player.hand.length - player.hp;
    if (excess > 0 && player.hp > 0) {
      state.phase = "DISCARD";
      state.waitingTargetSeat = player.seat;
      state.waitingReactionType = "DISCARD";
      state.waitingTimer = 40;
      recordAction(state, {
        type: "DISCARD_PHASE",
        casterSeat: player.seat,
        excess,
        description: `⚠️ <b>${player.generalName}</b> bị khóa Giai đoạn Ra bài và cần bỏ ${excess} lá thừa (40s).`
      });
      return { success: true, state };
    }
    return advanceTurn(state);
  }

  recordAction(state, {
    type: "TURN_START",
    turnSeat: player.seat,
    description: `👉 Lượt của <b>${player.generalName}</b>! ${skipDraw ? 'Bị mất Giai đoạn Rút bài' : 'Đã rút 2 lá bài'} (40s).`
  });
  checkGameOver(state);
  return { success: true, state };
}

function formatCardText(card) {
  if (!card) return """";
  if (!card.suit && !card.rank) return "${formatCardText(card)}";
  
  let suitSym = """";
  switch (card.suit) {
    case ""Spade"": suitSym = ""♠""; break;
    case ""Heart"": suitSym = ""<color=#FF5555>♥</color>""; break;
    case ""Club"": suitSym = ""♣""; break;
    case ""Diamond"": suitSym = ""<color=#FF5555>♦</color>""; break;
    default: suitSym = card.suit; break;
  }

  let rankStr = String(card.rank);
  if (card.rank === 1) rankStr = ""A"";
  else if (card.rank === 11) rankStr = ""J"";
  else if (card.rank === 12) rankStr = ""Q"";
  else if (card.rank === 13) rankStr = ""K"";

  return "[${card.name} (${suitSym} ${rankStr})]";
}

/**
 * Chuyển sang lượt kế tiếp; mọi phán xét và rút bài đều do server tiếp tục điều phối.
 */
function advanceTurn(state) {
  const previousSeat = state.turnSeat;
  const nextSeat = getNextAliveSeat(state, state.turnSeat);
  state.turnSeat = nextSeat;
  state.turnTimer = 40;
  state.slashesUsedThisTurn = 0;
  state.isWineBuffActive = false;
  const previousPlayer = state.players.find((player) => player.seat === previousSeat);
  if (previousPlayer) previousPlayer.isWineBuffActive = false;
  state.pendingAfterNearDeath = null;
  resetWaitingState(state);

  const nextPlayer = state.players.find((player) => player.seat === nextSeat);
  if (!nextPlayer || nextPlayer.hp <= 0) {
    checkGameOver(state);
    refreshLastDelta(state);
    return { success: true, state };
  }
  state.turnStart = {
    seat: nextSeat,
    judgementCards: [...(nextPlayer.judgements || [])].sort((left, right) => {
      const priority = {
        [CARD_SUBTYPES.LIGHTNING]: 0,
        [CARD_SUBTYPES.SUPPLY_SHORTAGE]: 1,
        [CARD_SUBTYPES.ACEDIA]: 2
      };
      return (priority[left.subType] ?? 99) - (priority[right.subType] ?? 99);
    }),
    judgementIndex: 0,
    skipDraw: false,
    skipPlay: false
  };
  nextPlayer.judgements = [];
  return continueTurnStart(state);
}

function formatCardText(card) {
  if (!card) return """";
  if (!card.suit && !card.rank) return "${formatCardText(card)}";
  
  let suitSym = """";
  switch (card.suit) {
    case ""Spade"": suitSym = ""♠""; break;
    case ""Heart"": suitSym = ""<color=#FF5555>♥</color>""; break;
    case ""Club"": suitSym = ""♣""; break;
    case ""Diamond"": suitSym = ""<color=#FF5555>♦</color>""; break;
    default: suitSym = card.suit; break;
  }

  let rankStr = String(card.rank);
  if (card.rank === 1) rankStr = ""A"";
  else if (card.rank === 11) rankStr = ""J"";
  else if (card.rank === 12) rankStr = ""Q"";
  else if (card.rank === 13) rankStr = ""K"";

  return "[${card.name} (${suitSym} ${rankStr})]";
}

/**
 * Kiểm tra xem trận đấu đã ngã ngũ chưa (1 trong 2 đội bị hạ gục hết)
 * Lưu ý: Người đang trong Hấp Hối (hp=0 nhưng chưa tử trận) không được tính là đã chết
 */
function checkGameOver(state) {
  // Nếu đang trong pha Hấp Hối, chưa kết thúc được
  if (state.phase === "AWAIT_NEAR_DEATH") return;

  const team1Alive = state.players.some(p => isTeamOneSeat(p.seat) && p.hp > 0);
  const team2Alive = state.players.some(p => !isTeamOneSeat(p.seat) && p.hp > 0);

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

function formatCardText(card) {
  if (!card) return """";
  if (!card.suit && !card.rank) return "${formatCardText(card)}";
  
  let suitSym = """";
  switch (card.suit) {
    case ""Spade"": suitSym = ""♠""; break;
    case ""Heart"": suitSym = ""<color=#FF5555>♥</color>""; break;
    case ""Club"": suitSym = ""♣""; break;
    case ""Diamond"": suitSym = ""<color=#FF5555>♦</color>""; break;
    default: suitSym = card.suit; break;
  }

  let rankStr = String(card.rank);
  if (card.rank === 1) rankStr = ""A"";
  else if (card.rank === 11) rankStr = ""J"";
  else if (card.rank === 12) rankStr = ""Q"";
  else if (card.rank === 13) rankStr = ""K"";

  return "[${card.name} (${suitSym} ${rankStr})]";
}

/**
 * Trọng tài AI tự động chọn lá bài tối ưu nhất để đánh hoặc kết thúc lượt
 */
export function handleAIStep(state, aiSeat) {
  if (state.status === "FINISHED") return { error: "Trận đấu đã kết thúc" };
  aiSeat = Number(aiSeat);
  const ai = state.players.find(x => x.seat === aiSeat);
  if (!ai || ai.hp <= 0) return { error: "Người chơi không hợp lệ" };
  if (state.turnSeat !== aiSeat) return { error: "Không phải lượt của AI này" };

  // 1. Nếu đang ở giai đoạn BỎ BÀI (DISCARD)
  if (state.phase === "DISCARD") {
    const excess = ai.hand.length - ai.hp;
    const ids = excess > 0 ? ai.hand.slice(0, excess).map((card) => card.id) : [];
    return handleDiscardCards(state, aiSeat, ids);
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

  const enemies = state.players.filter(x => !areTeammates(x.seat, aiSeat) && x.hp > 0);

  // D. Cẩm nang trì hoãn và Thần Sấm
  const delayed = ai.hand.find((card) => card.subType === CARD_SUBTYPES.LIGHTNING);
  if (delayed) {
    return handlePlayCard(state, aiSeat, delayed.id, aiSeat);
  }
  const delayedAttack = ai.hand.find((card) =>
    card.subType === CARD_SUBTYPES.SUPPLY_SHORTAGE || card.subType === CARD_SUBTYPES.ACEDIA
  );
  const delayedTarget = delayedAttack
    ? enemies.find((enemy) =>
      getDistance(state, aiSeat, enemy.seat) <= 1
      && !enemy.judgements.some((judgement) => judgement.subType === delayedAttack.subType)
    )
    : null;
  if (delayedAttack && delayedTarget) {
    return handlePlayCard(state, aiSeat, delayedAttack.id, delayedTarget.seat);
  }

  // E. Uống rượu trước khi Trảm nếu có cả Rượu và Trảm
  const wine = ai.hand.find(c => c.subType === CARD_SUBTYPES.WINE);
  const slash = ai.hand.find(c => isSlash(c));
  const slashTarget = enemies.find((enemy) => hasWeaponRange(state, aiSeat, enemy.seat)) || null;

  if (wine && slash && !ai.isWineBuffActive && slashTarget) {
    return handlePlayCard(state, aiSeat, wine.id, aiSeat);
  }

  // F. Thách Đấu nếu có mục tiêu hợp lệ
  const duel = ai.hand.find((card) => card.subType === CARD_SUBTYPES.DUEL);
  const duelTarget = enemies.find((enemy) => enemy.hp > 0) || null;
  if (duel && duelTarget) {
    return handlePlayCard(state, aiSeat, duel.id, duelTarget.seat);
  }

  // G. Đánh Trảm nếu chưa vượt giới hạn
  const hasZhuge = ai.equipments.some(e => e.name && e.name.includes("Nỏ Thần"));
  const canSlash = hasZhuge || state.slashesUsedThisTurn === 0;
  if (slash && canSlash && slashTarget) {
    return handlePlayCard(state, aiSeat, slash.id, slashTarget.seat);
  }

  // H. Cẩm nang diện rộng (Mưa Tên / Bãi Cọc)
  const aoe = ai.hand.find(c => c.subType === CARD_SUBTYPES.ARROW_RAIN || c.subType === CARD_SUBTYPES.BARBARIAN_INVASION);
  if (aoe) {
    return handlePlayCard(state, aiSeat, aoe.id, 0);
  }



  // J. Cẩm nang phá bài (Vườn Không / Đột Kích)
  const snatchTarget = enemies.find((enemy) =>
    getDistance(state, aiSeat, enemy.seat) <= 1 && buildTargetCardOptions(state, enemy.seat, true).length > 0
  ) || null;
  const snatch = ai.hand.find((card) => card.subType === CARD_SUBTYPES.SNATCH);
  if (snatch && snatchTarget) {
    return handlePlayCard(state, aiSeat, snatch.id, snatchTarget.seat);
  }

  const dismantleTarget = enemies.find((enemy) => buildTargetCardOptions(state, enemy.seat, false).length > 0) || null;
  const dismantle = ai.hand.find((card) => card.subType === CARD_SUBTYPES.DISMANTLE);
  if (dismantle && dismantleTarget) {
    return handlePlayCard(state, aiSeat, dismantle.id, dismantleTarget.seat);
  }

  // H. Không còn bài muốn đánh -> Kết thúc lượt
  return handleEndTurn(state, aiSeat);
}

function formatCardText(card) {
  if (!card) return """";
  if (!card.suit && !card.rank) return "${formatCardText(card)}";
  
  let suitSym = """";
  switch (card.suit) {
    case ""Spade"": suitSym = ""♠""; break;
    case ""Heart"": suitSym = ""<color=#FF5555>♥</color>""; break;
    case ""Club"": suitSym = ""♣""; break;
    case ""Diamond"": suitSym = ""<color=#FF5555>♦</color>""; break;
    default: suitSym = card.suit; break;
  }

  let rankStr = String(card.rank);
  if (card.rank === 1) rankStr = ""A"";
  else if (card.rank === 11) rankStr = ""J"";
  else if (card.rank === 12) rankStr = ""Q"";
  else if (card.rank === 13) rankStr = ""K"";

  return "[${card.name} (${suitSym} ${rankStr})]";
}

/**
 * AI tự động phản ứng khi bị nhắm tới (Đỡ, Trảm, Bỏ qua)
 */
export function handleAIReaction(state, aiSeat) {
  if (state.status === "FINISHED") return { error: "Trận đấu đã kết thúc" };
  aiSeat = Number(aiSeat);
  const ai = state.players.find(x => x.seat === aiSeat);
  if (!ai || (ai.hp <= 0 && state.phase !== "AWAIT_NEAR_DEATH")) return { error: "Người chơi không hợp lệ" };

  if (state.phase === "AWAIT_SLASH_DEFENSE" && state.waitingTargetSeat === aiSeat) {
    const caster = state.players.find((player) => player.seat === state.activeCard?.casterSeat);
    const cannon = getEquippedWeapon(caster, "Súng Thần Công");
    const dodge = ai.hand.find(c => isDodge(c)
      && (!cannon || c.suit !== state.activeCard?.suit));
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

  if (state.phase === "AWAIT_NULLIFY" && state.waitingTargetSeat === aiSeat) {
    const chain = state.nullifyChain;
    const flawless = ai.hand.find(c => c.subType === CARD_SUBTYPES.FLAWLESS_DEFENSE || (c.name && c.name.includes("Diệu Kế")));
    if (flawless && chain) {
      const caster = state.players.find(x => x.seat === chain.casterSeat);
      const isCasterAlly = caster && areTeammates(caster.seat, aiSeat);
      const shouldNullify = (!chain.isCanceled && !isCasterAlly) || (chain.isCanceled && isCasterAlly);
      if (shouldNullify) {
        return handleRespondAction(state, aiSeat, true, flawless.id);
      }
    }
    return handleRespondAction(state, aiSeat, false, null);
  }

  if (state.phase === "AWAIT_SONG_CUNG_FOLLOW_UP" && state.waitingTargetSeat === aiSeat) {
    if (ai.hand.length >= 2) {
      return handleRespondAction(state, aiSeat, true, null, null, ai.hand.slice(0, 2).map((card) => card.id));
    }
    return handleRespondAction(state, aiSeat, false, null);
  }

  if (state.phase === "AWAIT_TARGET_CARD" && state.waitingTargetSeat === aiSeat) {
    const selection = state.targetCardSelection;
    const token = selection?.options?.[0]?.token || null;
    return handleRespondAction(state, aiSeat, true, null, token);
  }

  if (state.phase === "AWAIT_HARVEST" && state.waitingTargetSeat === aiSeat) {
    const pickedCard = state.harvestPool && state.harvestPool.length > 0 ? state.harvestPool[0] : null;
    return handleRespondAction(state, aiSeat, true, pickedCard ? pickedCard.id : null);
  }

  return { error: "Không có phản ứng nào đang chờ AI này" };
}

function formatCardText(card) {
  if (!card) return """";
  if (!card.suit && !card.rank) return "${formatCardText(card)}";
  
  let suitSym = """";
  switch (card.suit) {
    case ""Spade"": suitSym = ""♠""; break;
    case ""Heart"": suitSym = ""<color=#FF5555>♥</color>""; break;
    case ""Club"": suitSym = ""♣""; break;
    case ""Diamond"": suitSym = ""<color=#FF5555>♦</color>""; break;
    default: suitSym = card.suit; break;
  }

  let rankStr = String(card.rank);
  if (card.rank === 1) rankStr = ""A"";
  else if (card.rank === 11) rankStr = ""J"";
  else if (card.rank === 12) rankStr = ""Q"";
  else if (card.rank === 13) rankStr = ""K"";

  return "[${card.name} (${suitSym} ${rankStr})]";
}

/**
 * Nhịp đếm thời gian và tự động hành động trên Server (Authoritative Server Loop)
 * Chạy mỗi giây (1000ms) trên Server In-Memory
 */
export function tickGameState(state) {
  if (!state || state.status === "FINISHED") return { changed: false, important: false };
  let changed = false;
  let important = false;
  const startingVersion = state.version || 0;

  if (!state.timerStartAt) {
      state.timerStartAt = Date.now();
      changed = true;
  }
  const elapsed = Math.floor((Date.now() - state.timerStartAt) / 1000);

  if (state.waitingTargetSeat > 0) {
    const waitingSeat = state.waitingTargetSeat;
    const waitingPlayer = state.players.find(p => p.seat === waitingSeat);

    if (elapsed >= 40) {
      if (state.phase === "AWAIT_SLASH_DEFENSE") {
        handleRespondAction(state, waitingSeat, false, null);
      } else if (state.phase === "AWAIT_NULLIFY") {
        handleRespondAction(state, waitingSeat, false, null);
      } else if (state.phase === "AWAIT_TARGET_CARD") {
        handleRespondAction(state, waitingSeat, true, null, null);
      } else if (state.phase === "AWAIT_AOE") {
        handleRespondAction(state, waitingSeat, false, null);
      } else if (state.phase === "AWAIT_DUEL") {
        handleRespondAction(state, waitingSeat, false, null);
      } else if (state.phase === "AWAIT_HARVEST") {
        handleRespondAction(state, waitingSeat, true, null);
      } else if (state.phase === "AWAIT_NEAR_DEATH") {
        handleRespondAction(state, waitingSeat, false, null);
      } else if (state.phase === "AWAIT_NAM_SON_FOLLOW_UP") {
        handleRespondAction(state, waitingSeat, false, null);
      } else if (state.phase === "AWAIT_SONG_CUNG_FOLLOW_UP") {
        handleRespondAction(state, waitingSeat, false, null);
      } else if (state.phase === "DISCARD") {
        handleDiscardCards(state, waitingSeat, []);
      }
      important = true;
      state.timerStartAt = Date.now();
      return { changed: true, important };
    }

    const canAIReact = waitingPlayer && waitingPlayer.isAI
      && (waitingPlayer.hp > 0 || state.phase === "AWAIT_NEAR_DEATH");
    if (canAIReact && elapsed >= 2 && elapsed < 40) {
      handleAIReaction(state, waitingSeat);
      important = true;
      state.timerStartAt = Date.now();
      return { changed: true, important };
    }
  }
  else if (state.phase === "PLAY" && state.turnSeat > 0) {
    const turnPlayer = state.players.find(p => p.seat === state.turnSeat);

    if (elapsed >= 40) {
      if (!turnPlayer || turnPlayer.hp <= 0) advanceTurn(state);
      else handleEndTurn(state, state.turnSeat);
      important = true;
      state.timerStartAt = Date.now();
      return { changed: true, important };
    }

    if (turnPlayer && turnPlayer.isAI && turnPlayer.hp > 0 && elapsed >= 2 && elapsed < 40) {
      handleAIStep(state, state.turnSeat);
      important = true;
      state.timerStartAt = Date.now();
      return { changed: true, important };
    }
  }

  if (state.version !== startingVersion) {
    important = true;
  }

  return { changed, important };
}

function formatCardText(card) {
  if (!card) return """";
  if (!card.suit && !card.rank) return "${formatCardText(card)}";
  
  let suitSym = """";
  switch (card.suit) {
    case ""Spade"": suitSym = ""♠""; break;
    case ""Heart"": suitSym = ""<color=#FF5555>♥</color>""; break;
    case ""Club"": suitSym = ""♣""; break;
    case ""Diamond"": suitSym = ""<color=#FF5555>♦</color>""; break;
    default: suitSym = card.suit; break;
  }

  let rankStr = String(card.rank);
  if (card.rank === 1) rankStr = ""A"";
  else if (card.rank === 11) rankStr = ""J"";
  else if (card.rank === 12) rankStr = ""Q"";
  else if (card.rank === 13) rankStr = ""K"";

  return "[${card.name} (${suitSym} ${rankStr})]";
}

/**
 * Format GameState an toàn để gửi về client (ẩn bài của đối thủ nếu cần hoặc gửi công khai 4 tay)
 */
function sanitizeTargetCardSelection(selection, requestingSeat) {
  const viewerSeat = Number(requestingSeat);
  if (!selection || selection.chooserSeat !== viewerSeat) return null;
  return {
    chooserSeat: selection.chooserSeat,
    targetSeat: selection.targetSeat,
    operation: selection.operation,
    cardId: selection.cardId,
    cardName: selection.cardName,
    effectType: selection.effectType || "TARGET_CARD",
    options: (selection.options || []).map((option) => ({
      token: option.token,
      zone: option.zone,
      label: option.label,
      card: option.zone === "HAND" || !option.card ? null : {
        id: option.card.id,
        name: option.card.name,
        suit: option.card.suit,
        rank: option.card.rank,
        category: option.card.category,
        subType: option.card.subType,
        desc: option.card.desc || "",
        attackRange: option.card.range || 1,
        distMod: option.card.distMod || 0
      }
    }))
  };
}

function sanitizeDeltaForClient(delta, requestingSeat) {
  if (!delta) return null;
  return {
    ...delta,
    targetCardSelection: sanitizeTargetCardSelection(delta.targetCardSelection, requestingSeat)
  };
}

export function sanitizeGameStateForClient(state, requestingSeat = 0) {
  const viewerSeat = Number(requestingSeat);
  const elapsed = state.timerStartAt ? Math.floor((Date.now() - state.timerStartAt) / 1000) : 0;
  const remaining = Math.max(0, 40 - elapsed);
  
  return {
    version: state.version,
    roomId: state.roomId,
    status: state.status,
    turnSeat: state.turnSeat,
    phase: state.phase,
    turnTimer: (state.phase === "PLAY") ? remaining : 0,
    waitingTargetSeat: state.waitingTargetSeat,
    waitingReactionType: state.waitingReactionType,
    waitingTimer: (state.waitingTargetSeat > 0) ? remaining : 0,
    nearDeathVictimSeat: state.nearDeathVictimSeat,
    nearDeathAskerQueue: state.nearDeathAskerQueue || [],
    aoeVictimsQueue: state.aoeVictimsQueue || [],
    harvestPickers: state.harvestPickers || [],
    slashesUsedThisTurn: state.slashesUsedThisTurn || 0,
    duelCasterSeat: state.duelCasterSeat || 0,
    duelTargetSeat: state.duelTargetSeat || 0,
    activeCard: state.activeCard,
    harvestPool: (state.harvestPool || []).map(c => ({
      id: c.id,
      name: c.name,
      suit: c.suit,
      rank: c.rank,
      category: c.category,
      subType: c.subType,
      desc: c.desc || ""
    })),
    nullifyChain: state.nullifyChain || null,
    targetCardSelection: sanitizeTargetCardSelection(state.targetCardSelection, requestingSeat),
    lastAction: state.lastAction,
    actionHistory: state.actionHistory || [],
    discardTop: state.discardTop,
    deckCount: state._deck ? state._deck.length : state.deckCount,
    discardCount: state._discard ? state._discard.length : state.discardCount,
    players: state.players.map(p => ({
      seat: p.seat,
      userId: p.userId,
      heroId: p.heroId,
      generalName: p.generalName,
      maxHp: p.maxHp,
      hp: p.hp,
      isAlly: isTeamOneSeat(p.seat),
      isAI: p.isAI,
      isWineBuffActive: !!p.isWineBuffActive,
      aoBaoCharges: Number.isFinite(Number(p.aoBaoCharges)) ? Number(p.aoBaoCharges) : 3,
      skills: [],
      handCount: p.hand ? p.hand.length : 0,
      hand: (viewerSeat > 0 && viewerSeat === p.seat)
        ? (p.hand || []).map(c => ({
            id: c.id,
            name: c.name,
            suit: c.suit,
            rank: c.rank,
            category: c.category,
            subType: c.subType,
            desc: c.desc || "",
            attackRange: c.range || 1,
            distMod: c.distMod || 0
          }))
        : (p.hand || []).map(() => ({ id: "HIDDEN", name: "Ẩn" })),
      equipments: (p.equipments || []).map(e => ({
        id: e.id,
        name: e.name,
        suit: e.suit,
        rank: e.rank,
        category: e.category,
        subType: e.subType,
        desc: e.desc || "",
        attackRange: e.range || 1,
        distMod: e.distMod || 0
      })),
      judgements: (p.judgements || []).map(j => ({
        id: j.id,
        name: j.name,
        suit: j.suit,
        rank: j.rank,
        category: j.category,
        subType: j.subType,
        desc: j.desc || ""
      }))
    })),
    delta: sanitizeDeltaForClient(state.lastDelta, requestingSeat)
  };
}









