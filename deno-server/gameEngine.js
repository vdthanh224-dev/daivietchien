import { createDeck, createDeck150, createFullDeck104, isSlash, isDodge, isPeach, isWine, CARD_CATEGORIES, CARD_SUBTYPES } from './deck.js';
import { getHeroById, heroHasSkill, normalizeHeroId } from './heroes.js';
import { cardRequiresTarget, findEquipmentByRule, firstEquipmentHook } from './cardRegistry.js';
import { getModeRules, getModeSeatOrder, requireModeRules } from './modeRegistry.js';

// Cache bộ bài chuẩn để tra cứu subType theo ID
let _deckCache = null;
function getDeckCache() {
  if (!_deckCache) {
    _deckCache = {};
    // Include the 150-card catalog so persisted 8-player snapshots hydrate fully.
    for (const c of [...createFullDeck104(), ...createDeck150()]) {
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

function findCardByIdInState(state, cardId) {
  if (!state || !cardId) return null;
  const rawId = String(cardId);
  const ids = [rawId, rawId.replace(/^EQUIPMENT:/, "")];
  const zones = [
    state._deck,
    state._discard,
    state.harvestPool,
    ...(state.players || []).flatMap((player) => [player.hand, player.equipments, player.judgements])
  ];
  for (const zone of zones) {
    if (!Array.isArray(zone)) continue;
    const found = zone.find((card) => card && ids.includes(String(card.id)));
    if (found) return found;
  }
  return findCardByIdInDeck(rawId);
}

const LEGACY_TIDE_CARD_IDS = Object.freeze({
  D80_CN_H2_PhongHoa: "D80_CN_H2_ThuyTrieuRut",
  D80_CN_H3_PhongHoa: "D80_CN_H3_ThuyTrieuRut",
  D80_CN_DQ_PhongHoa: "D80_CN_DQ_ThuyTrieuRut",
  D150_CN_H2_PhongHoa: "D150_CN_H2_ThuyTrieuRut",
  D150_CN_H3_PhongHoa: "D150_CN_H3_ThuyTrieuRut",
  D150_CN_DQ_PhongHoa: "D150_CN_DQ_ThuyTrieuRut",
});

const LEGACY_WATER_SLASH_ID = /^D(?:80|150)_TL_[SC](?:[1-9]|1[0-3]|[JQKA])$/;
const LEGACY_FLOOD_CARD_ID = /^D(?:80|150)_TH_CA_SamSet$/;

function migrateLegacyWaterCard(card) {
  const legacyId = typeof card === "string" ? card : card?.id;
  const id = LEGACY_TIDE_CARD_IDS[legacyId] || legacyId;
  if (typeof card === "string") return id;
  if (!card || typeof card !== "object") return card;

  if (LEGACY_WATER_SLASH_ID.test(id)) {
    const { id: _legacyId, name: _legacyName, desc: _legacyDesc, category: _legacyCategory, subType: _legacySubType, ...preserved } = card;
    return {
      ...preserved,
      id,
      name: "Trảm - Thủy",
      category: CARD_CATEGORIES.BASIC,
      subType: CARD_SUBTYPES.ATTACK_WATER,
      desc: "Tấn công gây 1 sát thương thuộc tính Thủy"
    };
  }

  if (LEGACY_FLOOD_CARD_ID.test(id)) {
    const { id: _legacyId, name: _legacyName, desc: _legacyDesc, category: _legacyCategory, subType: _legacySubType, ...preserved } = card;
    return {
      ...preserved,
      id,
      name: "Đại Hồng Thủy",
      category: CARD_CATEGORIES.DELAYED_SCROLL,
      subType: CARD_SUBTYPES.DAI_HONG_THUY,
      desc: "Phán xét: Bích ♠ từ 2 đến 9 chịu 3 sát thương Thủy, trượt chuyển người kế"
    };
  }

  if (id === legacyId) return card;

  const { id: _legacyId, name: _legacyName, desc: _legacyDesc, ...preserved } = card;
  return { ...preserved, id };
}

function hydrateCard(card) {
  const migratedCard = migrateLegacyWaterCard(card);
  const id = typeof migratedCard === "string" ? migratedCard : migratedCard?.id;
  const canonical = id ? findCardByIdInDeck(id) : null;
  if (canonical) {
    const supplied = typeof migratedCard === "object" ? migratedCard : {};
    // Persisted partial cards must not erase canonical card fields with blanks.
    const populated = Object.fromEntries(Object.entries(supplied)
      .filter(([, value]) => value !== undefined && value !== null && value !== ""));
    return { ...canonical, ...populated };
  }
  if (migratedCard && typeof migratedCard === "object") return { ...migratedCard };
  return null;
}

function getCardName(card) {
  if (typeof card?.name === "string" && card.name.trim()) return card.name;
  return findCardByIdInDeck(card?.id)?.name || "";
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

function areTeammatesInState(state, leftSeat, rightSeat) {
  const left = state?.players?.find((player) => player.seat === Number(leftSeat));
  const right = state?.players?.find((player) => player.seat === Number(rightSeat));
  if (typeof left?.teamId === "string" && typeof right?.teamId === "string") {
    return left.teamId === right.teamId;
  }
  if (typeof left?.isAlly === "boolean" && typeof right?.isAlly === "boolean") {
    return left.isAlly === right.isAlly;
  }
  return areTeammates(leftSeat, rightSeat);
}

function isSucSoiActive(player) {
  return Number(player?.sucSoiTurnsRemaining) > 0;
}

function isLivingPlayer(player) {
  return !!player && player.isAlive !== false && player.hp > 0;
}

function getModeRulesForState(state) {
  return getModeRules(state?.modeId) || getModeRules("2v2");
}

function resolvePlayerTeamId(modeRules, player, seat) {
  if (typeof player?.teamId === "string" && player.teamId) return player.teamId;
  if (modeRules.victory === "LAST_TEAM_STANDING" && typeof player?.isAlly === "boolean") {
    return player.isAlly ? "dragon" : "phoenix";
  }
  return modeRules.teamForSeat(seat);
}

function resolvePlayerIsAlly(modeRules, player, seat) {
  return modeRules.victory === "LAST_TEAM_STANDING" && typeof player?.isAlly === "boolean"
    ? player.isAlly
    : modeRules.isAllyForSeat(seat);
}

function isSeatInState(state, seat) {
  return getModeSeatOrder(state).includes(Number(seat));
}

function getSeatsAfter(state, currentSeat, includeCurrent = false) {
  const seats = getModeSeatOrder(state);
  const currentIndex = seats.indexOf(Number(currentSeat));
  if (currentIndex < 0) return seats;
  const offset = includeCurrent ? 0 : 1;
  return seats.map((_, index) => seats[(currentIndex + index + offset) % seats.length]);
}

/**
 * Restore a persisted JSON snapshot into the shape expected by the engine.
 * This accepts both current raw snapshots and older sanitized snapshots,
 * including card arrays serialized as either card objects or card IDs.
 */
export function hydrateGameState(rawState, roomId = "") {
  if (!rawState || typeof rawState !== "object") return null;
  const state = rawState;
  const modeRules = getModeRules(state.modeId || "2v2");
  if (!modeRules || !Array.isArray(state.players)
      || state.players.length < modeRules.minPlayers || state.players.length > modeRules.maxPlayers) return null;
  state.modeId = modeRules.id;

  const seenSeats = new Set();
  state.players = state.players.map((rawPlayer, index) => {
    if (!rawPlayer || typeof rawPlayer !== "object") return null;
    const seat = Number(rawPlayer.seat);
    if (!Number.isInteger(seat) || seat < 1 || seat > modeRules.maxPlayers || seenSeats.has(seat)) return null;
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
      // Keep negative HP during the rescue window so repeated rescues have the right cost.
      hp: Number.isFinite(hp) ? Math.min(hp, maxHp) : 0,
      teamId: resolvePlayerTeamId(modeRules, rawPlayer, seat),
      isAlly: resolvePlayerIsAlly(modeRules, rawPlayer, seat),
      isAI: !!rawPlayer.isAI,
      isAlive: rawPlayer.isAlive !== undefined ? !!rawPlayer.isAlive : true,
      isWineBuffActive: !!rawPlayer.isWineBuffActive,
      turnsTaken: Math.max(0, Number(rawPlayer.turnsTaken) || 0),
      sucSoiTurnsRemaining: Math.max(0, Number(rawPlayer.sucSoiTurnsRemaining) || 0),
      aoBaoCharges: Number.isFinite(Number(rawPlayer.aoBaoCharges))
        ? Math.max(0, Math.min(2, Number(rawPlayer.aoBaoCharges)))
        : 2,
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
  const firstSeat = getModeSeatOrder(state)[0] || 1;
  state.turnSeat = isSeatInState(state, state.turnSeat) ? Number(state.turnSeat) : firstSeat;
  state.phase = typeof state.phase === "string" && state.phase.length > 0 ? state.phase : "PLAY";
  state.turnTimer = Math.max(0, Number(state.turnTimer) || 0);
  state.waitingTargetSeat = Math.max(0, Number(state.waitingTargetSeat) || 0);
  state.waitingReactionType = state.waitingReactionType || "NONE";
  state.waitingTimer = Math.max(0, Number(state.waitingTimer) || 0);
  state.aoeVictimsQueue = Array.isArray(state.aoeVictimsQueue)
    ? state.aoeVictimsQueue.map(Number).filter((seat) => isSeatInState(state, seat))
    : [];
  state.harvestPool = hydrateCardList(state.harvestPool);
  state.harvestDisplayPool = hydrateCardList(state.harvestDisplayPool);
  state.harvestPickedCardIds = Array.isArray(state.harvestPickedCardIds)
    ? state.harvestPickedCardIds.map((cardId) => String(cardId)).filter(Boolean)
    : [];
  state.harvestPickers = Array.isArray(state.harvestPickers)
    ? state.harvestPickers.map(Number).filter((seat) => isSeatInState(state, seat))
    : [];
  state.nearDeathAskerQueue = Array.isArray(state.nearDeathAskerQueue)
    ? state.nearDeathAskerQueue.map(Number).filter((seat) => isSeatInState(state, seat))
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
  state.pendingAfterUatKhi = state.pendingAfterUatKhi && typeof state.pendingAfterUatKhi === "object"
    ? { ...state.pendingAfterUatKhi }
    : null;
  state.hoPhuTransfers = Array.isArray(state.hoPhuTransfers)
    ? state.hoPhuTransfers.map((transfer) => ({ ownerSeat: Number(transfer?.ownerSeat) || 0, recipientSeat: Number(transfer?.recipientSeat) || 0, cardId: String(transfer?.cardId || "") })).filter((transfer) => transfer.ownerSeat && transfer.recipientSeat && transfer.cardId)
    : [];
  state.uatKhiQueue = Array.isArray(state.uatKhiQueue)
    ? state.uatKhiQueue.map((pending) => ({ seat: Number(pending?.seat) || 0 })).filter((pending) => isSeatInState(state, pending.seat))
    : [];
  state.pendingChainSpread = state.pendingChainSpread && typeof state.pendingChainSpread === "object"
    ? {
      ...state.pendingChainSpread,
      sourceSeat: Number(state.pendingChainSpread.sourceSeat) || 0,
      damage: Math.max(0, Number(state.pendingChainSpread.damage) || 0),
      targetSeats: Array.isArray(state.pendingChainSpread.targetSeats)
        ? state.pendingChainSpread.targetSeats.map(Number).filter((seat) => isSeatInState(state, seat))
        : [],
    }
    : null;
  state.slashesUsedThisTurn = Math.max(0, Number(state.slashesUsedThisTurn) || 0);
  state.khoiBinhQueue = Array.isArray(state.khoiBinhQueue)
    ? state.khoiBinhQueue.map((pending) => ({
      seat: Number(pending?.seat) || 0,
      sourceSeat: Number(pending?.sourceSeat) || 0
    })).filter((pending) => isSeatInState(state, pending.seat) && isSeatInState(state, pending.sourceSeat))
    : [];
  state.turnDamageDealt = !!state.turnDamageDealt;
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
        ? state.nullifyChain.querySeats.map(Number).filter((seat) => isSeatInState(state, seat))
        : [],
      currentIdx: Math.max(0, Number(state.nullifyChain.currentIdx) || 0),
      whoUsedLast: Number(state.nullifyChain.whoUsedLast) || 0
    };
  } else {
    state.nullifyChain = null;
  }
  if (state.pendingJudgement && typeof state.pendingJudgement === "object") {
    state.pendingJudgement = { ...state.pendingJudgement };
  } else {
    state.pendingJudgement = null;
  }
  if (state.targetCardSelection && typeof state.targetCardSelection === "object") {
    state.targetCardSelection = {
      ...state.targetCardSelection,
      chooserSeat: Number(state.targetCardSelection.chooserSeat) || 0,
      targetSeat: Number(state.targetCardSelection.targetSeat) || 0,
      operation: ["STEAL", "RETURN"].includes(state.targetCardSelection.operation) ? state.targetCardSelection.operation : "DESTROY",
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
  state.hichSelection = state.hichSelection && typeof state.hichSelection === "object"
    ? { ...state.hichSelection, casterSeat: Number(state.hichSelection.casterSeat) || 0, targetSeat: Number(state.hichSelection.targetSeat) || 0 }
    : null;
  const rawTideSelection = state.thuyTrieuRutSelection;
  const hasLegacyTideSelection = rawTideSelection && typeof rawTideSelection === "object"
    && (Object.hasOwn(rawTideSelection, "richerSeat") || Object.hasOwn(rawTideSelection, "poorerSeat"));
  state.thuyTrieuRutSelection = rawTideSelection && typeof rawTideSelection === "object" && !hasLegacyTideSelection
    ? {
      ...rawTideSelection,
      casterSeat: Number(rawTideSelection.casterSeat) || 0,
      targetSeat: Number(rawTideSelection.targetSeat) || 0,
      giverSeat: Number(rawTideSelection.giverSeat) || 0,
      receiverSeat: Number(rawTideSelection.receiverSeat) || 0
    }
    : null;
  if (hasLegacyTideSelection && state.phase === "AWAIT_THUY_TRIEU_RUT_GIVE") {
    state.phase = "PLAY";
    state.waitingTargetSeat = 0;
    state.waitingReactionType = "NONE";
    state.waitingTimer = 0;
    state.activeCard = null;
  }
  state.drumSelection = state.drumSelection && typeof state.drumSelection === "object"
    ? { ...state.drumSelection, ownerSeat: Number(state.drumSelection.ownerSeat) || 0, targetSeat: Number(state.drumSelection.targetSeat) || 0 }
    : null;
  state.drumReveal = state.drumReveal && typeof state.drumReveal === "object"
    ? { ...state.drumReveal, viewerSeat: Number(state.drumReveal.viewerSeat) || 0, targetSeat: Number(state.drumReveal.targetSeat) || 0, cards: hydrateCardList(state.drumReveal.cards) }
    : null;
  state.deckCount = state._deck.length;
  state.discardCount = state._discard.length;
  return state;
}

function formatCardText(card) {
  if (!card) return "";
  if (!card.suit && !card.rank) return `[${card.name}]`;
  
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

  return `[${card.name} (${suitSym} ${rankStr})]`;
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
export function initGame(roomId, playersInput, modeId = "2v2") {
  const modeRules = requireModeRules(modeId);
  if (!Array.isArray(playersInput) || playersInput.length < modeRules.minPlayers || playersInput.length > modeRules.maxPlayers) {
    throw new Error(`Chế độ ${modeRules.id} cần từ ${modeRules.minPlayers} đến ${modeRules.maxPlayers} người chơi`);
  }

  const deck = shuffle(createDeck(modeRules.deckSize));
  const deckSize = deck.length;
  const discard = [];

  const normalizedInputs = playersInput.map((input, index) => {
    const p = input || {};
    const hasExplicitSeat = p.seat !== undefined && p.seat !== null && p.seat !== "";
    const requestedSeat = hasExplicitSeat ? Number(p.seat) : index + 1;
    if (!Number.isInteger(requestedSeat) || requestedSeat < 1 || requestedSeat > modeRules.maxPlayers) {
      throw new Error(`Mỗi người chơi phải có ghế hợp lệ từ 1 đến ${modeRules.maxPlayers}`);
    }
    return {
      ...p,
      seat: requestedSeat
    };
  }).sort((left, right) => left.seat - right.seat);

  if (new Set(normalizedInputs.map((player) => player.seat)).size !== normalizedInputs.length) {
    throw new Error("Các ghế trong trận đấu không được trùng nhau");
  }

  const players = normalizedInputs.map((p, index) => {
    // Keep the wire protocol backwards compatible: older Unity clients send
    // only generalName/maxHp, while newer clients send a string heroId.
    const heroId = normalizeHeroId(p.heroId, p.generalName);
    const hero = getHeroById(heroId);
    const maxHp = (Number.isFinite(Number(p.maxHp)) && Number(p.maxHp) > 0)
      ? Number(p.maxHp)
      : (hero?.maxHp || 4);
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
      teamId: resolvePlayerTeamId(modeRules, p, p.seat || index + 1),
      isAlly: resolvePlayerIsAlly(modeRules, p, p.seat || index + 1),
      isAI: !!p.isAI,
      isAlive: true,
      isWineBuffActive: false,
      turnsTaken: 0,
      sucSoiTurnsRemaining: 0,
      aoBaoCharges: 2,
      hand: hand,
      equipments: [],
      judgements: [],
      skills: []
    };
  });

  const initialState = {
    version: 1,
    roomId,
    modeId: modeRules.id,
    status: "PLAYING", // "PLAYING" | "FINISHED"
    turnSeat: 1,
    phase: "PLAY", // "PLAY" | "AWAIT_NULLIFY" | "AWAIT_TARGET_CARD" | "AWAIT_SLASH_DEFENSE" | "AWAIT_AOE" | "AWAIT_DUEL" | "AWAIT_NEAR_DEATH" | "DISCARD"
    turnTimer: 40,
    waitingTargetSeat: 0,
    waitingReactionType: "NONE", // "DODGE" | "SLASH" | "PEACH" | "NONE"
    waitingTimer: 0,
    aoeVictimsQueue: [], // Ghế các nạn nhân còn lại của đòn diện rộng
    harvestDisplayPool: [], // Các lá Mở Kho công khai, giữ nguyên đến khi kết thúc để client làm tối lá đã lấy.
    harvestPickedCardIds: [],
    duelCasterSeat: 0,
    duelTargetSeat: 0,
    nearDeathVictimSeat: 0,
    nearDeathAskerQueue: [],
    slashesUsedThisTurn: 0,
    turnDamageDealt: false,
    isWineBuffActive: false,
    activeCard: null,
    targetCardSelection: null,
    hichSelection: null,
    thuyTrieuRutSelection: null,
    drumSelection: null,
    drumReveal: null,
    turnStart: null,
    pendingAfterNearDeath: null,
    pendingAfterUatKhi: null,
    hoPhuTransfers: [],
    uatKhiQueue: [],
    khoiBinhQueue: [],
    pendingChainSpread: null,
    actionSeq: 1,
    actionHistory: [{
      seq: 1,
      type: "GAME_START",
        description: `Trận đấu bắt đầu với bộ bài ${deckSize} lá! Ghế 1 được rút thêm 1 lá và bắt đầu lượt.`,
      timestamp: Date.now()
    }],
    lastAction: {
      seq: 1,
      type: "GAME_START",
      description: `Trận đấu bắt đầu với bộ bài ${deckSize} lá! Ghế 1 được rút thêm 1 lá và bắt đầu lượt.`,
      timestamp: Date.now()
    },
    discardTop: null,
    deckCount: deck.length,
    discardCount: 0,
    players,
    _deck: deck, // Bộ bài ẩn trên server
    _discard: discard
  };

  // Match setup and local client both use two cards for first turn draw.
  drawCards(initialState, initialState.turnSeat, 1);
  const firstPlayer = initialState.players.find((player) => player.seat === initialState.turnSeat);
  if (firstPlayer) {
    firstPlayer.turnsTaken = 1;
    if (heroHasSkill(firstPlayer, "TIEN_PHONG")) drawCards(initialState, firstPlayer.seat, 2);
  }
  return initialState;
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
  const playedCard = action.card || findCardByIdInState(state, action.cardId);
  return {
    version: state.version,
    actionSeq: state.actionSeq,
    type: action.type,
    casterSeat: action.casterSeat !== undefined ? action.casterSeat : 0,
    targetSeat: action.targetSeat !== undefined ? action.targetSeat : 0,
    targetSeats: Array.isArray(action.targetSeats) ? action.targetSeats.map(Number) : [],
    cardId: action.cardId || "",
    cardName: action.cardName || getCardName(playedCard),
    card: cardSummary(playedCard),
    aoeName: action.aoeName || "",
    judgeCard: action.judgeCard || null,
    baiCocJudgeCard: action.baiCocJudgeCard || null,
    revealedCard: action.revealedCard || null,
    element: action.element || action.damageElement || "NORMAL",
    damage: Number(action.damage) || 0,
    isWineBuff: action.isWineBuff === true,
    armorEffect: action.armorEffect || "",
    armorChargesRemaining: Number.isFinite(Number(action.armorChargesRemaining)) ? Number(action.armorChargesRemaining) : -1,
    armorExpired: action.armorExpired === true,
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
    harvestDisplayPool: state.harvestDisplayPool || state.harvestPool || [],
    harvestPickedCardIds: state.harvestPickedCardIds || [],
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
    hichSelection: state.hichSelection || null,
    thuyTrieuRutSelection: state.thuyTrieuRutSelection || null,
    uatKhiQueue: state.uatKhiQueue || [],
    drumSelection: state.drumSelection || null,
    drumReveal: state.drumReveal || null,
    actionHistory: (state.actionHistory || []).map((item) => ({
      seq: item.seq,
      type: item.type,
      casterSeat: item.casterSeat || 0,
      targetSeat: item.targetSeat || 0,
      targetSeats: Array.isArray(item.targetSeats) ? item.targetSeats.map(Number) : [],
      cardId: item.cardId || "",
      cardName: item.cardName || "",
      judgeCard: item.judgeCard || null,
      description: item.description || ""
    })),
    playerDeltas: state.players.map(p => ({
      seat: p.seat,
      hp: p.hp,
      maxHp: p.maxHp,
      handCount: p.hand ? p.hand.length : 0,
      sucSoiTurnsRemaining: Math.max(0, Number(p.sucSoiTurnsRemaining) || 0),
      isWineBuffActive: !!p.isWineBuffActive,
      isChained: !!p.isChained,
      aoBaoCharges: Number.isFinite(Number(p.aoBaoCharges))
        ? Math.max(0, Math.min(2, Number(p.aoBaoCharges)))
        : 2,
      equipments: p.equipments || [],
      judgements: p.judgements || [],
      activeSkillsKeys: p.activeSkills ? Object.keys(p.activeSkills) : [],
      activeSkillsValues: p.activeSkills ? Object.values(p.activeSkills) : [],
      usedSkillsKeys: p.usedSkills ? Object.keys(p.usedSkills) : [],
      usedSkillsValues: p.usedSkills ? Object.values(p.usedSkills) : []
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

/**
 * Ghi nhận hành động vào lịch sử trận đấu, tăng version state và tạo Delta Update
 */
export function recordAction(state, action) {
  const actionCard = action.card || findCardByIdInState(state, action.cardId);
  if (actionCard) {
    // Snapshot the real card before later state mutations can change it.
    action.card = cardSummary(actionCard);
    if (!action.cardName) action.cardName = getCardName(action.card);
  }
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

/**
 * Tìm người chơi còn sống kế tiếp
 */
export function getNextAliveSeat(state, currentSeat) {
  for (const next of getSeatsAfter(state, currentSeat)) {
    const p = state.players.find(x => x.seat === next);
    if (isLivingPlayer(p)) return next;
  }
  return currentSeat;
}

/**
 * Rút N lá bài từ cọc rút cho 1 người chơi
 */
export function drawCards(state, seat, count = 2, allowDying = false) {
  const p = state.players.find(x => x.seat === seat);
  if (!p || (p.hp <= 0 && !allowDying)) return [];

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
      if (p.activeSkills && p.activeSkills["Chế Nỏ"] && card.suit === "Spade" && card.subType !== CARD_SUBTYPES.WEAPON) {
          card.orig_name = card.name;
          card.orig_subType = card.subType;
          card.orig_category = card.category;
          card.orig_desc = card.desc;
          card.name = "Nỏ Thần Kim Quy";
          card.subType = CARD_SUBTYPES.WEAPON;
          card.category = CARD_CATEGORIES.EQUIPMENT;
          card.desc = "Tầm 1. Không giới hạn số Trảm trong lượt";
      }
      p.hand.push(card);
      drawn.push(card);
    }
  }
  state.deckCount = state._deck.length;
  return drawn;
}

function discardCard(state, card, reveal = true) {
    if (!card) return;
    if (card.originalCardId) { const orig = findCardByIdInDeck(card.originalCardId); if (orig) card = orig; }
    if (card.orig_name) {
        card.name = card.orig_name;
        card.subType = card.orig_subType;
        card.category = card.orig_category;
        card.desc = card.orig_desc;
        delete card.orig_name; delete card.orig_subType; delete card.orig_category; delete card.orig_desc;
    }
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
    .filter(isLivingPlayer)
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
  if (heroHasSkill(from, "XA_THUAN")) {
    distance -= 2;
  }
  return Math.max(1, distance);
}

function hasWeaponRange(state, fromSeat, toSeat) {
  const from = state.players.find((player) => player.seat === fromSeat);
  if (!from) return false;
  const weapon = (from.equipments || []).find((equipment) => equipment.subType === CARD_SUBTYPES.WEAPON);
  const isNoThan = weapon && (
    String(weapon.name || weapon.cardName || "").includes("Nỏ Thần")
      || String(weapon.id || "").toLowerCase().includes("nothan")
      || String(weapon.desc || "").includes("Không giới hạn số Trảm")
  );
  const range = isNoThan ? 1 : (weapon && Number.isFinite(Number(weapon.range)) ? Number(weapon.range) : 1);
  const distance = getDistance(state, fromSeat, toSeat);
  return distance <= range + (isSucSoiActive(from) ? 1 : 0);
}

function hasBachDangBoat(player) {
  return !!findEquipmentByRule(player, 'thuyen_bach_dang');
}

function cardColor(suit) {
  if (suit === "Heart" || suit === "Diamond") return "RED";
  if (suit === "Club" || suit === "Spade") return "BLACK";
  return "";
}

function sameCardColor(leftSuit, rightSuit) {
  const leftColor = cardColor(leftSuit);
  return leftColor !== "" && leftColor === cardColor(rightSuit);
}

function getEquippedWeapon(player, nameFragment = "") {
  if (!player) return null;
  return (player.equipments || []).find((equipment) =>
    equipment.subType === CARD_SUBTYPES.WEAPON
      && (!nameFragment || equipment.name?.includes(nameFragment))
  ) || null;
}

function hasEquippedZhuge(player) {
  if (!player || !Array.isArray(player.equipments)) return false;
  return player.equipments.some(e => 
    (e.subType === CARD_SUBTYPES.WEAPON || e.category === CARD_CATEGORIES.EQUIPMENT) && (
      (e.name && (e.name.includes("Nỏ Thần") || e.name.includes("No Than") || e.name.includes("Nỏ"))) ||
      (e.cardName && (e.cardName.includes("Nỏ Thần") || e.cardName.includes("No Than") || e.cardName.includes("Nỏ"))) ||
      (e.id && e.id.toLowerCase().includes("nothan")) ||
      (e.desc && e.desc.includes("Không giới hạn số Trảm"))
    )
  );
}

function getEquippedKhienMay(player) {
  if (!player || !Array.isArray(player.equipments)) return null;
  return player.equipments.find(e =>
    (e.subType === CARD_SUBTYPES.ARMOR) && (
      (e.name && (e.name.includes("Khiên Mây") || e.name.includes("Khien May") || e.name.includes("Khiên"))) ||
      (e.cardName && (e.cardName.includes("Khiên Mây") || e.cardName.includes("Khien May") || e.cardName.includes("Khiên"))) ||
      (e.id && e.id.toLowerCase().includes("khienmay")) ||
      (e.desc && e.desc.includes("chất Đỏ tự động Đỡ"))
    )
  ) || null;
}

function canUseCardAsDodge(player, card) {
  if (isDodge(card)) return true;

  const rawHeroId = String(player?.heroId ?? "").trim().toUpperCase();
  const heroId = normalizeHeroId(player?.heroId, player?.generalName);
  const heroName = String(player?.generalName ?? "")
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/Đ/g, "D")
    .replace(/đ/g, "d")
    .trim()
    .toUpperCase();
  const isLyThuongKiet = heroId === "LY_THUONG_KIET"
    || rawHeroId === "LY_THUONG_KIET"
    || heroName === "LY THUONG KIET";
  const isNguyenCanhChan = heroId === "HERO_83"
    || rawHeroId === "NGUYEN_CANH_CHAN"
    || heroName === "NGUYEN CANH CHAN";

  return (isLyThuongKiet && isSlash(card))
    || (isNguyenCanhChan && card?.suit === "Club");
}

function resetWaitingState(state, clearActiveCard = true) {
  state.phase = "PLAY";
  state.waitingTargetSeat = 0;
  state.waitingReactionType = "NONE";
  state.waitingTimer = 0;
  state.turnTimer = 40;
  state.timerStartAt = Date.now();
  if (clearActiveCard) state.activeCard = null;
  refreshLastDelta(state);
}

function startNextUatKhiPrompt(state) {
  state.uatKhiQueue = (state.uatKhiQueue || []).filter(({ seat }) => {
    const player = state.players.find((candidate) => candidate.seat === seat);
    return player && player.hp > 0 && heroHasSkill(player, "UAT_KHI");
  });
  const next = state.uatKhiQueue[0];
  if (!next) return false;
  state.phase = "AWAIT_UAT_KHI";
  state.waitingTargetSeat = next.seat;
  state.waitingReactionType = "UAT_KHI";
  state.waitingTimer = 40;
  state.timerStartAt = Date.now();
  return true;
}

function startNextKhoiBinhPrompt(state) {
  state.khoiBinhQueue = (state.khoiBinhQueue || []).filter((pending) => {
    const player = state.players.find((candidate) => candidate.seat === pending.seat);
    const source = state.players.find((candidate) => candidate.seat === pending.sourceSeat);
    return isLivingPlayer(player) && heroHasSkill(player, "KHOI_BINH") && isLivingPlayer(source);
  });
  const next = state.khoiBinhQueue[0];
  if (!next) return false;
  state.phase = "AWAIT_KHOI_BINH";
  state.waitingTargetSeat = next.seat;
  state.waitingReactionType = "KHOI_BINH";
  state.waitingTimer = 40;
  state.timerStartAt = Date.now();
  const source = state.players.find((player) => player.seat === next.sourceSeat);
  const owner = state.players.find((player) => player.seat === next.seat);
  recordAction(state, {
    type: "KHOI_BINH_PROMPT",
    casterSeat: next.seat,
    targetSeat: next.sourceSeat,
    description: `⚔️ ${owner?.generalName || "Triệu Quốc Đạt"} có thể phát động [Khởi Binh]: bản thân và ${source?.generalName || "người dùng Trảm"} mỗi người rút 1 lá.`
  });
  return true;
}

function requiresTarget(card) {
  return cardRequiresTarget(card);
}

function validateTarget(state, casterSeat, targetSeat, card) {
  if (!requiresTarget(card)) return null;
  const normalizedTarget = Number(targetSeat);
  if (!Number.isInteger(normalizedTarget) || normalizedTarget < 1 || normalizedTarget > 4) {
    return { error: "Cần chọn mục tiêu" };
  }
  if (normalizedTarget === casterSeat) return { error: "Không thể chọn chính mình" };
  const target = state.players.find((player) => player.seat === normalizedTarget);
  if (!isLivingPlayer(target)) return { error: "Mục tiêu không hợp lệ" };
  const caster = state.players.find((player) => player.seat === casterSeat);
  const waterSlashIgnoresDistance = card?.subType === CARD_SUBTYPES.ATTACK_WATER && hasBachDangBoat(caster);
  if (isSlash(card) && !waterSlashIgnoresDistance && !hasWeaponRange(state, casterSeat, normalizedTarget)) {
    return { error: "Mục tiêu ngoài tầm đánh" };
  }
  if (card.subType === CARD_SUBTYPES.SUPPLY_SHORTAGE
      && getDistance(state, casterSeat, normalizedTarget) > 1) {
    return { error: "Lá bài này cần dùng trong tầm Ngựa" };
  }
  if (card.subType === CARD_SUBTYPES.SNATCH
      && getDistance(state, casterSeat, normalizedTarget) > 1) {
    return { error: "Mục tiêu ngoài tầm" };
  }
  
  if ([CARD_SUBTYPES.SNATCH, CARD_SUBTYPES.DISMANTLE].includes(card.subType)) {
    const targetHand = target.hand ? target.hand.length : 0;
    const targetEquip = target.equipments ? target.equipments.length : 0;
    const targetJudge = target.judgements ? target.judgements.length : 0;
    if (targetHand + targetEquip + targetJudge === 0) {
      return { error: "Mục tiêu không có bài để chọn" };
    }
  }
  if (card.subType === CARD_SUBTYPES.PHU_DE_TRUU_TAN && !(target.equipments || []).length) return { error: "Mục tiêu không có Trang bị để trả về tay" };
  return null;
}

function collectHichTarget(state, casterSeat, targetSeat, card, payload = {}) {
  const rawSeats = [
    ...(Array.isArray(card?.targetSeats) ? card.targetSeats : []),
    ...(Array.isArray(payload?.targetSeats) ? payload.targetSeats : []),
    targetSeat,
    card?.targetSeat2,
    payload?.targetSeat2,
  ];
  const seats = [];
  for (const rawSeat of rawSeats) {
    if (rawSeat === undefined || rawSeat === null || rawSeat === "" || Number(rawSeat) === 0) continue;
    const seat = Number(rawSeat);
    if (!isSeatInState(state, seat) || seat === casterSeat) {
      return { error: "Cần chọn đúng 1 người chơi khác còn sống cho Hịch Tướng Sĩ" };
    }
    if (!isLivingPlayer(state.players.find((player) => player.seat === seat))) {
      return { error: "Người được chọn cho Hịch Tướng Sĩ không còn sống" };
    }
    if (!seats.includes(seat)) seats.push(seat);
  }
  return seats.length === 1
    ? { targetSeat: seats[0] }
    : { error: "Cần chọn đúng 1 người chơi khác còn sống cho Hịch Tướng Sĩ" };
}

function validateBorrowSwordTargets(state, weaponOwnerSeat, forcedTargetSeat) {
  const weaponOwner = state.players.find((player) => player.seat === Number(weaponOwnerSeat));
  if (!isLivingPlayer(weaponOwner)) return { error: "Mục tiêu Mượn Gươm không còn hợp lệ" };
  const weapon = weaponOwner?.equipments?.find((equipment) => equipment.subType === CARD_SUBTYPES.WEAPON);
  if (!weapon) return { error: "Mục tiêu chưa trang bị Vũ khí" };

  const forcedSeat = Number(forcedTargetSeat);
  const forcedTarget = state.players.find((player) => player.seat === forcedSeat);
  if (!Number.isInteger(forcedSeat) || !isLivingPlayer(forcedTarget)
      || forcedSeat === weaponOwner.seat || !hasWeaponRange(state, weaponOwner.seat, forcedSeat)) {
    return { error: "Cần chọn mục tiêu khác trong tầm đánh của người đang có vũ khí" };
  }
  return { weaponOwner, weapon, forcedTargetSeat: forcedSeat };
}

function collectIronChainTargets(state, card, targetSeat, payload = {}) {
  const rawTargetSeats = [
    ...(Array.isArray(card?.targetSeats) ? card.targetSeats : []),
    ...(Array.isArray(payload?.targetSeats) ? payload.targetSeats : []),
    targetSeat,
    card?.targetSeat2,
    payload?.targetSeat2,
  ];
  const seats = [];
  for (const rawSeat of rawTargetSeats) {
    if (rawSeat === undefined || rawSeat === null || rawSeat === "" || Number(rawSeat) === 0) continue;
    const seat = Number(rawSeat);
    if (!isSeatInState(state, seat)) {
      return { error: "Mục tiêu Xích Tâm Tỏa không hợp lệ" };
    }
    if (seats.includes(seat)) continue;
    if (seats.length >= 2) {
      return { error: "Xích Tâm Tỏa chỉ được chọn tối đa 2 mục tiêu" };
    }
    if (!isLivingPlayer(state.players.find((player) => player.seat === seat))) {
      return { error: "Mục tiêu Xích Tâm Tỏa không còn sống" };
    }
    seats.push(seat);
  }
  if (seats.length === 0) {
    return payload?.recast === true || card?.recast === true
      ? { seats: [], recast: true }
      : { error: "Cần chọn ít nhất 1 mục tiêu cho Xích Tâm Tỏa hoặc chọn Đổi lá" };
  }
  if (payload?.recast === true || card?.recast === true) {
    return { error: "Đổi lá Xích Tâm Tỏa không thể chọn mục tiêu" };
  }
  return { seats, recast: false };
}

function startSlashResolution(state, slashCard, casterSeat, targetSeat, options = {}) {
  const caster = state.players.find((player) => player.seat === casterSeat);
  const target = state.players.find((player) => player.seat === targetSeat);
  const countsTowardTurnSlashLimit = options.countsTowardTurnSlashLimit !== false;
  if (!caster || !target || !isLivingPlayer(target)) {
    if (options.resetOnFailure) resetWaitingState(state);
    return { error: "Mục tiêu Trảm không còn hợp lệ" };
  }

  discardCard(state, slashCard);
  if (countsTowardTurnSlashLimit) state.slashesUsedThisTurn++;

  if (heroHasSkill(caster, "PHU_TRAN") && !getEquippedWeapon(caster)) {
    drawCards(state, casterSeat, 1);
    recordAction(state, {
      type: "PHU_TRAN_DRAW",
      casterSeat,
      cardId: slashCard.id,
      cardName: slashCard.name,
      description: `🏹 ${caster.generalName} kích hoạt [Phù Trấn], rút 1 lá vì dùng Trảm khi không đeo vũ khí.`
    });
  }

  const isCurrentTurnActor = casterSeat === state.turnSeat;
  const isWine = !!caster.isWineBuffActive || (isCurrentTurnActor && state.isWineBuffActive);
  const damage = 1 + (isWine ? 1 : 0);
  caster.isWineBuffActive = false;
  if (isCurrentTurnActor) state.isWineBuffActive = false;

  const hasThuanThien = getEquippedWeapon(caster, "Thuận Thiên");
  if (!hasThuanThien && firstEquipmentHook(target, 'blockSlash', { slash: slashCard })) {
    if (options.resetOnBlock) resetWaitingState(state);
    recordAction(state, { type: "SLASH_BLOCKED_BY_GIAP_TAY_SON", casterSeat, targetSeat, cardId: slashCard.id, cardName: slashCard.name, description: `🛡️ [Giáp Tây Sơn] vô hiệu hóa Trảm đen của ${caster.generalName}!` });
    return { success: true, state };
  }
  if (!hasThuanThien && slashCard.subType === CARD_SUBTYPES.ATTACK_NORMAL
      && target.equipments?.some((equipment) =>
        equipment.subType === CARD_SUBTYPES.ARMOR && equipment.name?.includes("Giáp Đồng"))) {
    if (options.resetOnBlock) resetWaitingState(state);
    recordAction(state, {
      type: "SLASH_BLOCKED_BY_ARMOR",
      casterSeat,
      targetSeat,
      cardId: slashCard.id,
      cardName: slashCard.name,
      description: `🛡️ [Giáp Đồng Sơn Vi] vô hiệu hóa ${formatCardText(slashCard)} của ${caster.generalName}!`
    });
    return { success: true, state };
  }

  const damageElement = slashCard.subType === CARD_SUBTYPES.ATTACK_FIRE
    ? "FIRE"
    : slashCard.subType === CARD_SUBTYPES.ATTACK_WATER ? "WATER" : firstEquipmentHook(caster, 'slashElement', { slash: slashCard })?.value || "NORMAL";
  state.phase = "AWAIT_SLASH_DEFENSE";
  state.waitingTargetSeat = targetSeat;
  state.waitingReactionType = "DODGE";
  state.waitingTimer = 40;
  state.timerStartAt = Date.now();
  state.activeCard = {
    ...(options.inheritedActiveCard || {}),
    cardId: slashCard.id,
    cardName: slashCard.name,
    name: slashCard.name,
    subType: slashCard.subType,
    category: slashCard.category,
    suit: slashCard.suit,
    casterSeat,
    targetSeat,
    damage,
    damageElement,
    isWineBuff: isWine,
    countsTowardTurnSlashLimit,
    requiredDodgeCount: heroHasSkill(caster, "DUNG_NU") && target.hp > caster.hp ? 2 : 1,
    dodgesUsed: 0,
    liemDaoEligible: !!firstEquipmentHook(caster, 'slashHitDrawOnce', { target })
  };

  const cannon = getEquippedWeapon(caster, "Súng Thần Công");
  const requiredDodges = state.activeCard.requiredDodgeCount;
  const requiredDodgeText = `${requiredDodges > 1 ? ` (cần ${requiredDodges} lá Đỡ do [Dũng Nữ])` : ""}${cannon ? " (KHÔNG được dùng lá Đỡ cùng màu với Trảm)" : ""}`;
  recordAction(state, {
    type: options.actionType || "PLAY_SLASH",
    casterSeat,
    targetSeat,
    cardId: slashCard.id,
    cardName: slashCard.name,
    damage,
    element: damageElement,
    isWineBuff: isWine,
    baiCocJudgeCard: options.baiCocJudgeCard || null,
    description: options.description || `🗡️ <b>${caster.generalName}</b> tung chiêu ${formatCardText(slashCard)}${isWine ? " <color=#FFD700><b>(kèm hiệu ứng Hủ Rượu: +1 Sát thương)</b></color>" : ""} nhắm vào <b>${target.generalName}</b>! (Mục tiêu có 40s để Đỡ${requiredDodgeText})`
  });
  return { success: true, state };
}

function resolveBorrowSwordSlash(state, continuation) {
  const weaponOwnerSeat = Number(continuation?.weaponOwnerSeat) || 0;
  const forcedTargetSeat = Number(continuation?.forcedTargetSeat) || 0;
  const validation = validateBorrowSwordTargets(state, weaponOwnerSeat, forcedTargetSeat);
  if (validation.error) {
    resetWaitingState(state);
    return validation;
  }

  const slashIndex = validation.weaponOwner.hand.findIndex((handCard) =>
    (handCard.id === continuation?.actionCardId || handCard.name === continuation?.actionCardId) && isSlash(handCard));
  if (slashIndex < 0) {
    resetWaitingState(state);
    return { error: "Lá Trảm cho Mượn Gươm không còn hợp lệ" };
  }

  const slashCard = validation.weaponOwner.hand.splice(slashIndex, 1)[0];
  return startSlashResolution(state, slashCard, weaponOwnerSeat, forcedTargetSeat, {
    countsTowardTurnSlashLimit: false,
    resetOnBlock: true,
    resetOnFailure: true,
    inheritedActiveCard: {
      forcedTargetSeat,
      weaponId: validation.weapon.id,
      effectCasterSeat: Number(continuation?.borrowCasterSeat) || 0,
      borrowCardId: continuation?.borrowCardId || "",
      borrowCardName: continuation?.borrowCardName || "Mượn Gươm Diệt Địch"
    },
    actionType: "BORROW_SWORD_SLASH",
    description: `🗡️ ${validation.weaponOwner.generalName} đã dùng vũ khí bị Mượn Gươm để đánh Ghế ${forcedTargetSeat}.`
  });
}

function beginBorrowSwordSlash(state, respondent, cardId) {
  const activeCard = state.activeCard || {};
  const forcedTargetSeat = Number(activeCard.forcedTargetSeat) || 0;
  const validation = validateBorrowSwordTargets(state, respondent.seat, forcedTargetSeat);
  if (validation.error) return validation;

  const slashCard = respondent.hand.find((handCard) =>
    (handCard.id === cardId || handCard.name === cardId) && isSlash(handCard));
  if (!slashCard) return { error: "Cần chọn một lá Trảm hợp lệ để Mượn Gươm" };

  const continuation = {
    type: "BORROW_SWORD_SLASH",
    seat: respondent.seat,
    actionCardId: slashCard.id,
    actionTargetSeat: forcedTargetSeat,
    weaponOwnerSeat: respondent.seat,
    forcedTargetSeat,
    borrowCasterSeat: Number(activeCard.casterSeat) || 0,
    borrowCardId: activeCard.cardId || "",
    borrowCardName: activeCard.cardName || "Mượn Gươm Diệt Địch"
  };
  const trap = respondent.judgements?.find((judgement) => judgement.subType === CARD_SUBTYPES.BAI_COC_BACH_DANG);
  if (trap) {
    continuation.trapId = trap.id;
    return startNullifyChain(state, trap, Number(trap.attachedBySeat) || respondent.seat, respondent.seat, continuation);
  }
  return resolveBorrowSwordSlash(state, continuation);
}

/**
 * Tra cứu linh hoạt lá bài trong tay theo ID, Tên tiếng Việt, hoặc bí danh viết tắt (xichtam, dotkich, vuonkhong,...)
 */
export function resolveCardInHand(hand, cardIdOrName) {
  if (!Array.isArray(hand) || !cardIdOrName) return -1;
  const target = String(cardIdOrName).trim();
  const targetLower = target.toLowerCase();

  // 1. Direct match by exact ID or exact Name
  let idx = hand.findIndex(c => c && (c.id === target || c.name === target));
  if (idx >= 0) return idx;

  // 2. Case-insensitive ID or Name
  idx = hand.findIndex(c => c && ((c.id && c.id.toLowerCase() === targetLower) || (c.name && c.name.toLowerCase() === targetLower)));
  if (idx >= 0) return idx;

  // 3. Known aliases and abbreviations
  if (targetLower === "xichtam" || targetLower === "xich" || targetLower === "xt" || targetLower.includes("xichtam")) {
    idx = hand.findIndex(c => c && ((c.id && c.id.includes("XT")) || (c.name && c.name.includes("Xích Tâm"))));
    if (idx >= 0) return idx;
  }
  if (targetLower === "dotkich" || targetLower === "dk" || targetLower.includes("dotkich")) {
    idx = hand.findIndex(c => c && ((c.id && c.id.includes("DotKich")) || (c.name && c.name.includes("Đột Kích"))));
    if (idx >= 0) return idx;
  }
  if (targetLower === "vuonkhong" || targetLower === "vk" || targetLower.includes("vuonkhong")) {
    idx = hand.findIndex(c => c && ((c.id && c.id.includes("VuonKhong")) || (c.name && c.name.includes("Vườn Không"))));
    if (idx >= 0) return idx;
  }
  if (targetLower === "dieuke" || targetLower.includes("dieuke")) {
    idx = hand.findIndex(c => c && ((c.id && c.id.includes("DieuKe")) || (c.name && c.name.includes("Diệu Kế"))));
    if (idx >= 0) return idx;
  }
  if (targetLower === "dungbinh" || targetLower.includes("dungbinh")) {
    idx = hand.findIndex(c => c && ((c.id && c.id.includes("DungBinh")) || (c.name && c.name.includes("Dụng Binh"))));
    if (idx >= 0) return idx;
  }
  if (targetLower === "mokho" || targetLower.includes("mokho")) {
    idx = hand.findIndex(c => c && ((c.id && c.id.includes("MoKho")) || (c.name && c.name.includes("Mở Kho"))));
    if (idx >= 0) return idx;
  }
  if (targetLower === "baicoc" || targetLower.includes("baicoc") || targetLower === "giac toi" || targetLower.includes("giac toi")) {
    idx = hand.findIndex(c => c && ((c.id && (c.id.includes("BaiCoc") || c.id.includes("GiacToi"))) || (c.name && (c.name.includes("Bãi Cọc") || c.name.includes("Giặc Tới")))));
    if (idx >= 0) return idx;
  }
  if (targetLower === "muaten" || targetLower.includes("muaten")) {
    idx = hand.findIndex(c => c && ((c.id && c.id.includes("MuaTen")) || (c.name && c.name.includes("Mưa Tên"))));
    if (idx >= 0) return idx;
  }
  if (targetLower === "thachdau" || targetLower.includes("thachdau") || targetLower === "huyet chien" || targetLower.includes("huyet chien")) {
    idx = hand.findIndex(c => c && ((c.id && (c.id.includes("ThachDau") || c.id.includes("HuyetChien"))) || (c.name && (c.name.includes("Thách Đấu") || c.name.includes("Huyết Chiến")))));
    if (idx >= 0) return idx;
  }
  if (targetLower === "banh" || targetLower === "banh_chung" || targetLower.includes("banh")) {
    idx = hand.findIndex(c => c && ((c.id && c.id.includes("BC")) || (c.name && c.name.includes("Bánh Chưng"))));
    if (idx >= 0) return idx;
  }
  if (targetLower === "ruou" || targetLower.includes("ruou")) {
    idx = hand.findIndex(c => c && ((c.id && c.id.includes("HR")) || (c.name && c.name.includes("Hủ Rượu"))));
    if (idx >= 0) return idx;
  }
  if (targetLower === "do" || targetLower.includes("do")) {
    idx = hand.findIndex(c => c && (isDodge(c) || (c.id && c.id.includes("DO")) || (c.name && c.name.includes("Đỡ"))));
    if (idx >= 0) return idx;
  }
  if (targetLower === "tram" || targetLower === "danh" || targetLower.includes("tram")) {
    idx = hand.findIndex(c => c && (isSlash(c) || (c.name && c.name.includes("Trảm"))));
    if (idx >= 0) return idx;
  }
  if (targetLower.includes("thuytrieurut") || targetLower.includes("thủy triều rút")) {
    idx = hand.findIndex(c => c && ((c.id && c.id.includes("ThuyTrieuRut")) || c.name === "Thủy Triều Rút"));
    if (idx >= 0) return idx;
  }
  if (targetLower.includes("muonguom") || targetLower.includes("mượn gươm")) {
    idx = hand.findIndex(c => c && ((c.id && c.id.includes("MuonGuom")) || c.name === "Mượn Gươm Diệt Địch"));
    if (idx >= 0) return idx;
  }
  if (targetLower.includes("moyentiec") || targetLower.includes("mở yến tiệc")) {
    idx = hand.findIndex(c => c && ((c.id && c.id.includes("MoYenTiec")) || c.name === "Mở Yến Tiệc"));
    if (idx >= 0) return idx;
  }
  if (targetLower.includes("hichtuongs") || targetLower.includes("hịch tướng sĩ")) {
    idx = hand.findIndex(c => c && ((c.id && c.id.includes("HichTuongSi")) || c.name === "Hịch Tướng Sĩ"));
    if (idx >= 0) return idx;
  }
  if (targetLower.includes("baicocbachdang") || targetLower.includes("bãi cọc bạch đằng")) {
    idx = hand.findIndex(c => c && ((c.id && c.id.includes("BaiCocBachDang")) || c.name === "Bãi Cọc Bạch Đằng"));
    if (idx >= 0) return idx;
  }
  if (targetLower.includes("trongdong") || targetLower.includes("trống đồng")) {
    idx = hand.findIndex(c => c && ((c.id && c.id.includes("BronzeDrum")) || c.name === "Trống Đồng Đông Sơn"));
    if (idx >= 0) return idx;
  }

  return -1;
}

/**
 * Xử lý khi một người chơi đánh ra 1 lá bài từ tay
 */
export function handlePlayCard(state, casterSeat, cardId, targetSeat = 0, payload = {}) {
  if (state.status === "FINISHED") return { error: "Trận đấu đã kết thúc" };
  casterSeat = Number(casterSeat);
  if (targetSeat !== undefined && targetSeat !== null && targetSeat !== "") {
    const parsedTarget = Number(targetSeat);
    targetSeat = Number.isFinite(parsedTarget) ? parsedTarget : targetSeat;
  }
  if (state.phase !== "PLAY" || state.turnSeat !== casterSeat) {
    if (state.turnSeat !== casterSeat) {
      const turnP = state.players.find(p => p.seat === state.turnSeat);
      return { error: `Chưa tới lượt của bạn (Đang trong lượt của ${turnP ? turnP.generalName : `Ghế ${state.turnSeat}`})` };
    }
    if (state.phase === "AWAIT_SLASH_DEFENSE") {
      return { error: "Đang chờ mục tiêu phản hồi lá Đỡ" };
    }
    if (state.phase === "AWAIT_TARGET_CARD") {
      return { error: "Đang chờ chọn lá bài mục tiêu" };
    }
    if (state.phase === "DISCARD") {
      return { error: "Đang trong giai đoạn bỏ bài thừa" };
    }
    return { error: `Chưa thể ra bài lúc này (Trạng thái: ${state.phase})` };
  }

  const caster = state.players.find(x => x.seat === casterSeat);
  if (!caster || caster.hp <= 0) return { error: "Người chơi không hợp lệ" };

  // Card IDs are authoritative; also support name and alias matching for resilient client messaging
  let cardIndex = resolveCardInHand(caster.hand, cardId);
  let card = null;
  if (cardIndex >= 0) {
      card = caster.hand[cardIndex];
      if (caster.activeSkills && caster.activeSkills["Chế Nỏ"] && card.suit === "Spade" && card.subType !== CARD_SUBTYPES.WEAPON) {
          card = { ...card, name: "Nỏ Thần Kim Quy", subType: CARD_SUBTYPES.WEAPON, category: CARD_CATEGORIES.EQUIPMENT, range: 1, distMod: 0, desc: "Tầm 1. Không giới hạn số Trảm trong lượt" };
      }
  }
  if (payload && card) {
    card.targetSeats = payload.targetSeats;
    card.targetSeat2 = payload.targetSeat2;
    card.recast = payload.recast === true;
  }
  if (cardIndex < 0) {
     console.error("[handlePlayCard] Mismatch! Client requested cardId:", cardId, "but hand has:", caster.hand.map(c => c.id));
     return { error: "Không tìm thấy lá bài trên tay (" + cardId + ")" };
  }

  const selectedCard = card;
  if (isDodge(selectedCard)) {
    return { error: "Lá Đỡ chỉ được dùng khi đang phản ứng một đòn tấn công" };
  }
  if (selectedCard.subType === CARD_SUBTYPES.FLAWLESS_DEFENSE
      || selectedCard.name?.includes("Diệu Kế")) {
    return { error: "Diệu Kế Phá Mưu là lá bài phản ứng, chỉ dùng qua bảng hỏi khi có Cẩm nang được thi triển!" };
  }
  const isHichRecast = selectedCard.subType === CARD_SUBTYPES.HICH_TUONG_SI && payload?.recast === true;
  const targetValidation = isHichRecast ? null : validateTarget(state, casterSeat, targetSeat, selectedCard);
  if (targetValidation) return targetValidation;
  if (selectedCard.subType === CARD_SUBTYPES.HICH_TUONG_SI) {
    if (isHichRecast) {
      selectedCard.recast = true;
    } else {
      const hichTarget = collectHichTarget(state, casterSeat, targetSeat, selectedCard, payload);
      if (hichTarget.error) return hichTarget;
      selectedCard.targetSeats = [hichTarget.targetSeat];
      targetSeat = hichTarget.targetSeat;
    }
  }
  if (selectedCard.subType === CARD_SUBTYPES.THUY_TRIEU_RUT) {
    const tideTarget = state.players.find((player) => player.seat === targetSeat);
    if (!tideTarget?.hand?.length) return { error: "Mục tiêu Thủy Triều Rút phải có ít nhất 1 lá trên tay" };
  }
  if (selectedCard.subType === CARD_SUBTYPES.MUON_GUOM_DIET_DICH) {
    const borrowValidation = validateBorrowSwordTargets(state, targetSeat, selectedCard.targetSeat2);
    if (borrowValidation.error) return borrowValidation;
    selectedCard.targetSeat2 = borrowValidation.forcedTargetSeat;
  }
  if (selectedCard.subType === CARD_SUBTYPES.IRON_CHAIN) {
    const ironChainTargets = collectIronChainTargets(state, selectedCard, targetSeat, payload);
    if (ironChainTargets.error) return ironChainTargets;
    selectedCard.targetSeats = ironChainTargets.seats;
    selectedCard.targetSeat2 = ironChainTargets.seats[1] || 0;
    selectedCard.recast = ironChainTargets.recast;
    targetSeat = ironChainTargets.seats[0] || 0;
  }
  if (selectedCard.subType === CARD_SUBTYPES.PEACH && caster.hp >= caster.maxHp) {
    return { error: "Máu đã đầy, không thể dùng Bánh Chưng" };
  }
  if ([CARD_SUBTYPES.DAI_HONG_THUY, CARD_SUBTYPES.SUPPLY_SHORTAGE, CARD_SUBTYPES.ACEDIA, CARD_SUBTYPES.BAI_COC_BACH_DANG].includes(selectedCard.subType)) {
    const attachTarget = selectedCard.subType === CARD_SUBTYPES.DAI_HONG_THUY
      ? caster
      : state.players.find((player) => player.seat === targetSeat);
    if (attachTarget?.judgements?.some((judgement) => judgement.subType === selectedCard.subType)) {
      return { error: "Mục tiêu đã có cẩm nang trì hoãn cùng loại" };
    }
  }
  if (isSlash(card)
      && state.slashesUsedThisTurn > 0
      && !hasEquippedZhuge(caster)
      && !isSucSoiActive(caster)) {
    return { error: "Đã dùng hết lượt Trảm trong lượt" };
  }

  if (!payload?._baiCocResolved
      && [isSlash(card), card.subType === CARD_SUBTYPES.OFFENSIVE_HORSE, card.subType === CARD_SUBTYPES.DEFENSIVE_HORSE].some(Boolean)) {
    const trap = caster.judgements?.find((judgement) => judgement.subType === CARD_SUBTYPES.BAI_COC_BACH_DANG);
    if (trap) {
      return startNullifyChain(state, trap, Number(trap.attachedBySeat) || casterSeat, casterSeat, {
        type: "BAI_COC_ACTION",
        seat: casterSeat,
        actionCardId: selectedCard.id,
        actionTargetSeat: targetSeat,
        actionPayload: { ...(payload || {}), _baiCocResolved: true },
        trapId: trap.id
      });
    }
  }

  const realCard = caster.hand.splice(cardIndex, 1)[0];
  const transferIndex = (state.hoPhuTransfers || []).findIndex((transfer) => transfer.recipientSeat === casterSeat && transfer.cardId === realCard.id);
  if (transferIndex >= 0) {
    const transfer = state.hoPhuTransfers.splice(transferIndex, 1)[0];
    const owner = state.players.find((player) => player.seat === transfer.ownerSeat);
    if (isLivingPlayer(owner)) drawCards(state, owner.seat, 1);
  }
  if (selectedCard.subType === CARD_SUBTYPES.TAU_VI_THUONG_SACH && !(caster.equipments || []).length) {
    return { error: "Cần có ít nhất 1 Trang bị để dùng Tẩu Vi Thượng Sách" };
  }
  card = { ...selectedCard }; // Use the properly modified copy with Nỏ Thần
  card.originalCardId = realCard.id;
  card.targetSeats = card.targetSeats || [];
  card.targetSeat2 = card.targetSeat2 || 0;
  card.recast = selectedCard.recast === true;
  const target = state.players.find(x => x.seat === targetSeat);
  state.turnTimer = 40;

  if (card.subType === CARD_SUBTYPES.FLAWLESS_DEFENSE) {
    return startNullifyChain(state, card, casterSeat, targetSeat);
  }

  // 1. LÁ TRẢM (Slash)
  if (isSlash(card)) {
    return startSlashResolution(state, card, casterSeat, targetSeat, {
      baiCocJudgeCard: payload?.baiCocJudgeCard || null
    });
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
      description: `💮 <b>${caster.generalName}</b> dùng ${formatCardText(card)} hồi 1 đóa sen máu (${caster.hp}/${caster.maxHp})!`
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
      description: `🍶 <b>${caster.generalName}</b> uống ${formatCardText(card)}: Đòn Trảm kế tiếp được +1 sát thương!`
    });
    refreshLastDelta(state);
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
      caster.aoBaoCharges = 2;
    }
    recordAction(state, {
      type: "EQUIP",
      casterSeat,
      cardId: card.id,
      cardName: card.name,
      baiCocJudgeCard: payload?.baiCocJudgeCard || null,
      description: `🛡️ <b>${caster.generalName}</b> trang bị ${formatCardText(card)}: ${card.desc}`
    });
    refreshLastDelta(state);
    return { success: true, state };
  }

  // 5. CẨM NANG TỨC THỜI hỏi Diệu Kế ngay; Cẩm Nang Trì Hoãn gài trước, hỏi ở lượt phán xét.
  if (card.subType === CARD_SUBTYPES.SNATCH || card.subType === CARD_SUBTYPES.DISMANTLE) {
    const t = state.players.find(x => x.seat === targetSeat);
    if (t && (t.hand || []).length === 0 && (t.equipments || []).length === 0 && (t.judgements || []).length === 0) {
       return { error: "Mục tiêu không có bài để chọn!" };
    }
  }

  if (card.category === CARD_CATEGORIES.DELAYED_SCROLL || card.subType === CARD_SUBTYPES.DAI_HONG_THUY || card.subType === CARD_SUBTYPES.SUPPLY_SHORTAGE || card.subType === CARD_SUBTYPES.ACEDIA) {
    return executeCardEffect(state, card, casterSeat, targetSeat);
  }
  if (card.subType === CARD_SUBTYPES.IRON_CHAIN && card.recast) {
    return executeCardEffect(state, card, casterSeat, targetSeat);
  }
  if (card.subType === CARD_SUBTYPES.HICH_TUONG_SI && card.recast) {
    return executeCardEffect(state, card, casterSeat, targetSeat);
  }
  if (card.subType === CARD_SUBTYPES.ARROW_RAIN || card.subType === CARD_SUBTYPES.BARBARIAN_INVASION || card.subType === CARD_SUBTYPES.HARVEST) {
    return executeCardEffect(state, card, casterSeat, targetSeat);
  }
  return startNullifyChain(state, card, casterSeat, targetSeat);
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
  for (const s of getSeatsAfter(state, firstSeat, true)) {
    const p = state.players.find(x => x.seat === s);
    // Chỉ hỏi những người CÓ Diệu Kế Phá Mưu trên tay
    if (p && p.hp > 0) {
      // Khi vừa dùng cẩm nang ban đầu, người dùng (caster) không tự hóa giải cẩm nang của chính mình
      if (s === casterSeat && (!state.nullifyChain || state.nullifyChain.whoUsedLast === null)) {
        continue;
      }
      const hasNullify = p.hand && p.hand.some(c => c.subType === CARD_SUBTYPES.FLAWLESS_DEFENSE || (c.name && c.name.includes("Diệu Kế")));
      if (hasNullify) {
        querySeats.push(s);
      }
    }
  }

  // Nếu không ai có Diệu Kế, thực thi ngay mưu kế
  if (querySeats.length === 0) {
    if (["BAI_COC_ACTION", "BORROW_SWORD_SLASH"].includes(continuation?.type)) {
      return resolveBaiCocAction(state, continuation, false);
    }
    if (continuation?.type === "TURN_JUDGEMENT") {
      resolveJudgementCard(state, card, continuation.seat);
      if (state.phase === "AWAIT_NEAR_DEATH") return { success: true, state };
      refreshLastDelta(state);
      return { success: true, state };
    }
    if (continuation?.type === "CONTINUE_AOE") {
      const nextVictim = targetSeat;
      if (state.activeCard?.reqType === "DODGE" && tryKhienMayDefense(state, nextVictim, "đòn diện rộng")) {
         beginNextAoeVictim(state);
      } else {
         state.phase = "AWAIT_AOE";
         state.waitingReactionType = state.activeCard?.reqType || "DODGE";
         state.waitingTargetSeat = nextVictim;
         state.waitingTimer = 40;
    state.timerStartAt = Date.now();
         refreshLastDelta(state);
      }
      return { success: true, state };
    }
    if (continuation?.type === "CONTINUE_HARVEST") {
      state.phase = "AWAIT_HARVEST";
      state.waitingTargetSeat = targetSeat;
      state.waitingReactionType = "HARVEST";
      state.waitingTimer = 40;
    state.timerStartAt = Date.now();
      refreshLastDelta(state);
      return { success: true, state };
    }
    return executeCardEffect(state, card, casterSeat, targetSeat);
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
    state.timerStartAt = Date.now();
  state.activeCard = {
    ...(state.activeCard || {}),
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
    description: continuation?.type === "TURN_JUDGEMENT"
      ? `⚖️ Cẩm nang trì hoãn ${formatCardText(card)} chuẩn bị phán xét${targetDesc}! Đang chờ người chơi phản hồi có dùng Diệu Kế Phá Mưu không (40s)...`
      : ["BAI_COC_ACTION", "BORROW_SWORD_SLASH"].includes(continuation?.type)
        ? `🪵 ${formatCardText(card)} kích hoạt khi ${target?.generalName || "mục tiêu"} tuyên bố dùng bài! Đang hỏi người chơi có dùng Diệu Kế Phá Mưu để phá phán xét không (40s)...`
        : `📜 <b>${caster ? caster.generalName : "Ghế " + casterSeat}</b> thi triển ${formatCardText(card)}${targetDesc}! Đang chờ người chơi phản hồi có dùng Diệu Kế Phá Mưu không (40s)...`
  });

  return { success: true, state };
}

function resolveBaiCocAction(state, continuation, nullified) {
  const actorSeat = Number(continuation?.seat) || 0;
  const actor = state.players.find((player) => player.seat === actorSeat);
  const trapIndex = actor?.judgements?.findIndex((judgement) => judgement.id === continuation?.trapId) ?? -1;
  const trap = trapIndex >= 0 ? actor.judgements[trapIndex] : null;

  const consumeTrap = () => {
    if (!trap) return;
    actor.judgements.splice(trapIndex, 1);
    discardCard(state, trap);
  };

  state.nullifyChain = null;
  resetWaitingState(state);

  if (nullified) {
    consumeTrap();
    recordAction(state, {
      type: "BAI_COC_BACH_DANG_NULLIFIED",
      casterSeat: actorSeat,
      targetSeat: actorSeat,
      cardId: continuation?.trapId || "",
      cardName: "Bãi Cọc Bạch Đằng",
      description: `🛡️ Diệu Kế Phá Mưu đã phá Bãi Cọc Bạch Đằng. ${actor?.generalName || "Người chơi"} được dùng hành động bình thường.`
    });
  } else {
    const judgeCard = drawJudgementCard(state) || { id: "JUDGECARD", suit: "Heart", rank: 10 };
    const safe = judgeCard.suit === "Heart" || judgeCard.suit === "Diamond";
    const judgementCount = 1;
    if (trap) trap.baiCocJudgementCount = judgementCount;
    recordAction(state, {
      type: safe ? "BAI_COC_BACH_DANG_SAFE" : "BAI_COC_BACH_DANG_TRIGGERED",
      casterSeat: actorSeat,
      targetSeat: actorSeat,
      cardId: continuation?.trapId || "",
      cardName: "Bãi Cọc Bạch Đằng",
      judgeCard: { id: judgeCard.id, suit: judgeCard.suit, rank: judgeCard.rank, name: judgeCard.name || "Bài Phán Xét" },
      description: safe
        ? `🪵 [Bãi Cọc Bạch Đằng] phán xét Đỏ, ${actor?.generalName || "Người chơi"} được dùng hành động. Bãi Cọc rời đi sau phán xét.`
        : `🪵 [Bãi Cọc Bạch Đằng] phán xét Đen, hủy hành động của ${actor?.generalName || "người chơi"} và gây 1 sát thương thường. Bãi Cọc rời đi sau phán xét.`
    });
    if (!safe) {
      const actionIndex = actor?.hand?.findIndex((card) => card.id === continuation?.actionCardId) ?? -1;
      if (actionIndex >= 0) discardCard(state, actor.hand.splice(actionIndex, 1)[0]);
      consumeTrap();
      const damageResult = applyDamageToPlayer(state, actorSeat, 1, "Bãi Cọc Bạch Đằng", "NORMAL", false, { skipRecordDamageTaken: true });
      if (state.phase !== "AWAIT_NEAR_DEATH") resetWaitingState(state);
      checkGameOver(state);
      refreshLastDelta(state);
      return { success: true, state, damageResult };
    }
    consumeTrap();

    if (continuation?.type === "BORROW_SWORD_SLASH") {
      return resolveBorrowSwordSlash(state, continuation);
    }

    return handlePlayCard(
      state,
      actorSeat,
      continuation?.actionCardId,
      continuation?.actionTargetSeat || 0,
      {
        ...(continuation?.actionPayload || {}),
        _baiCocResolved: true,
        baiCocJudgeCard: { id: judgeCard.id, suit: judgeCard.suit, rank: judgeCard.rank, name: judgeCard.name || "Bài Phán Xét" }
      }
    );
  }

  if (continuation?.type === "BORROW_SWORD_SLASH") {
    return resolveBorrowSwordSlash(state, continuation);
  }

  return handlePlayCard(
    state,
    actorSeat,
    continuation?.actionCardId,
    continuation?.actionTargetSeat || 0,
    continuation?.actionPayload || { _baiCocResolved: true }
  );
}

function resolveCanceledNullifyChain(state, chain) {
  const rootCard = chain.rootCard;
  const continuation = chain.continuation;
  state.nullifyChain = null;

  if (["BAI_COC_ACTION", "BORROW_SWORD_SLASH"].includes(continuation?.type)) {
    return resolveBaiCocAction(state, continuation, true);
  }

  recordAction(state, {
    type: "EFFECT_CANCELED",
    casterSeat: chain.casterSeat,
    targetSeat: chain.targetSeat,
    cardId: rootCard?.id || "",
    cardName: getCardName(rootCard),
    description: `🚫 Mưu kế ${formatCardText(rootCard)} đã bị vô hiệu hóa hoàn toàn!`
  });

  if (continuation?.type === "TURN_JUDGEMENT") {
    const target = state.players.find((player) => player.seat === continuation.seat);
    const index = target?.judgements?.findIndex((card) => card.id === rootCard.id) ?? -1;
    if (index >= 0) discardCard(state, target.judgements.splice(index, 1)[0]);
    return continueTurnStart(state);
  }
  if (continuation?.type === "CONTINUE_AOE") {
    beginNextAoeVictim(state);
    refreshLastDelta(state);
    return { success: true, state };
  }
  if (continuation?.type === "CONTINUE_HARVEST") {
    state.harvestPickers.shift();
    beginNextHarvestPicker(state);
    refreshLastDelta(state);
    return { success: true, state };
  }

  // Instant scrolls reach this branch still outside discard pile.
  discardCard(state, rootCard);
  resetWaitingState(state);
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
  const armor = getEquippedKhienMay(target);
  if (!armor) return false;

  const judgeCard = drawJudgementCard(state);
  if (!judgeCard) return false;
  const isRed = judgeCard.suit === "Heart" || judgeCard.suit === "Diamond";
  recordAction(state, {
    type: isRed ? "KHIEN_MAY_SUCCESS" : "KHIEN_MAY_FAILED",
    casterSeat: targetSeat,
    targetSeat,
    cardId: armor.id,
    cardName: armor.name || "Khiên Mây Bện",
    judgeCard: {
      id: judgeCard.id,
      name: judgeCard.name,
      suit: judgeCard.suit,
      rank: judgeCard.rank
    },
    description: isRed
      ? `🛡️ [Khiên Mây Bện] của ${target.generalName} lật ${judgeCard.suit} ${judgeCard.rank} (ĐỎ) và tự động Đỡ ${sourceDescription}!`
      : `🛡️ [Khiên Mây Bện] của ${target.generalName} lật ${judgeCard.suit} ${judgeCard.rank} (ĐEN) và phán xét thất bại.`
  });
  return isRed;
}

function beginSlashAfterDodge(state, caster, targetSeat, defenseName = "Đỡ") {
  const target = state.players.find((player) => player.seat === targetSeat);
  const activeCard = state.activeCard || {};
  const requiredDodgeCount = Math.max(1, Number(activeCard.requiredDodgeCount) || 1);
  const dodgesUsed = Math.max(0, Number(activeCard.dodgesUsed) || 0) + 1;
  if (dodgesUsed < requiredDodgeCount) {
    state.activeCard = { ...activeCard, dodgesUsed };
    state.phase = "AWAIT_SLASH_DEFENSE";
    state.waitingTargetSeat = targetSeat;
    state.waitingReactionType = "DODGE";
    state.waitingTimer = 40;
    state.timerStartAt = Date.now();
    recordAction(state, {
      type: "DODGE_PARTIAL",
      casterSeat: targetSeat,
      targetSeat,
      description: `🛡️ ${target?.generalName || `Ghế ${targetSeat}`} đã dùng ${defenseName}; còn cần ${requiredDodgeCount - dodgesUsed} lá Đỡ để hóa giải Trảm [Dũng Nữ].`
    });
    return;
  }
  const songCung = getEquippedWeapon(caster, "Song Cung");
  const hasNamSon = !!caster?.equipments?.some((equipment) =>
    equipment.name?.includes("Trường Đao")
  );
  const consumedSlashAllowance = state.activeCard?.countsTowardTurnSlashLimit !== false;

  if (hasNamSon) {
    // Trường Đao restores the slash spent on the dodged attack; it does not create a follow-up attack.
    if (consumedSlashAllowance) {
      state.slashesUsedThisTurn = Math.max(0, (Number(state.slashesUsedThisTurn) || 0) - 1);
    }
    resetWaitingState(state);
    const defenseCard = state.discardTop;
    recordAction(state, {
      type: "DODGE_SUCCESS",
      casterSeat: targetSeat,
      targetSeat,
      cardId: defenseCard?.id || "",
      cardName: defenseCard?.name || defenseName,
      description: `🛡️ ${target?.generalName || `Ghế ${targetSeat}`} đã dùng ${defenseName} hóa giải đòn Trảm!${consumedSlashAllowance ? " [Trường Đao Nam Sơn] xem như chưa sử dụng lượt Trảm." : ""}`
    });
    return;
  }

  if (songCung && caster.hand.length >= 2) {
    state.phase = "AWAIT_SONG_CUNG_FOLLOW_UP";
    state.waitingTargetSeat = caster.seat;
    state.waitingTimer = 40;
    state.timerStartAt = Date.now();
    state.waitingReactionType = "DISCARD_TWO";
    state.activeCard = {
      ...(state.activeCard || {}),
      cardName: "Song Cung Mường Nhạ",
      casterSeat: caster.seat,
      targetSeat
    };
    recordAction(state, {
      type: "SONG_CUNG_PROMPT",
      casterSeat: caster.seat,
      targetSeat,
      description: `🏹 [Song Cung Mường Nhạ]: ${defenseName} đã hóa giải đòn đánh! ${caster.generalName} có thể bỏ 2 lá để bỏ qua Đỡ; Trảm vẫn gây ${Number(state.activeCard?.damage) || 1} sát thương. (40s)`
    });
    return;
  }

  resetWaitingState(state);
  if (defenseName !== "Khiên Mây Bện") {
    const defenseCard = state.discardTop;
    recordAction(state, {
      type: "DODGE_SUCCESS",
      casterSeat: targetSeat,
      targetSeat,
      cardId: defenseCard?.id || "",
      cardName: defenseCard?.name || defenseName,
      description: `🛡️ ${target?.generalName || `Ghế ${targetSeat}`} đã dùng ${defenseName} hóa giải đòn Trảm!`
    });
  } else {
    refreshLastDelta(state);
  }
}

function beginNextAoeVictim(state) {
  while (state.aoeVictimsQueue && state.aoeVictimsQueue.length > 0) {
    const nextVictim = state.aoeVictimsQueue.shift();
    const victim = state.players.find((player) => player.seat === nextVictim);
    if (!victim || victim.hp <= 0) continue;
    // Hỏi Diệu Kế Phá Mưu trước khi bắt buộc nạn nhân Đỡ/Trảm
    if (state.activeCard && state.activeCard.cardName) {
      const aoecard = { id: state.activeCard.cardId, name: state.activeCard.cardName, subType: state.activeCard.reqType === "DODGE" ? "ARROW_RAIN" : "BARBARIAN_INVASION" };
      return startNullifyChain(state, aoecard, state.activeCard.casterSeat, nextVictim, { type: "CONTINUE_AOE" });
    }

    if (state.activeCard?.reqType === "DODGE" && tryKhienMayDefense(state, nextVictim, "đòn diện rộng")) {
      continue;
    }

    state.phase = "AWAIT_AOE";
    state.waitingReactionType = state.activeCard?.reqType || "DODGE";
    state.waitingTargetSeat = nextVictim;
    state.waitingTimer = 40;
    state.timerStartAt = Date.now();
    return true;
  }

  resetWaitingState(state);
  return false;
}

function beginNextHarvestPicker(state) {
  while (state.harvestPickers && state.harvestPickers.length > 0 && state.harvestPool.length > 0) {
    const nextPicker = state.harvestPickers[0];
    const player = state.players.find(p => p.seat === nextPicker);
    if (!player || player.hp <= 0) {
      state.harvestPickers.shift();
      continue;
    }
    
    // Nếu activeCard có cờ harvestNullifiedForSeat, nghĩa là mưu kế đã bị Diệu Kế phá giải cho ghế này
    // Cờ này được đặt ở nullify chain để bỏ qua nạn nhân, nhưng nếu không có cờ, ta sẽ hỏi Diệu Kế.
    if (state.activeCard && state.activeCard.cardName && state.activeCard.harvestNullifiedForSeat !== nextPicker) {
      const aoecard = { id: state.activeCard.cardId, name: state.activeCard.cardName, subType: CARD_SUBTYPES.HARVEST };
      return startNullifyChain(state, aoecard, state.activeCard.casterSeat, nextPicker, { type: "CONTINUE_HARVEST" });
    }
    
    state.phase = "AWAIT_HARVEST";
    state.waitingTargetSeat = nextPicker;
    state.waitingReactionType = "HARVEST";
    state.waitingTimer = 40;
    state.timerStartAt = Date.now();
    
    recordAction(state, {
      type: "HARVEST_PICK_START",
      targetSeat: nextPicker,
      description: `Đang tới lượt <b>${player.generalName}</b> chọn bài từ Kho Cứu Tế (40s)...`
    });
    return true;
  }
  
  // Finish Harvest
  if (state.harvestPool && state.harvestPool.length > 0) {
    for (const card of state.harvestPool) {
      discardCard(state, card);
    }
  }
  state.harvestPool = [];
  state.harvestDisplayPool = [];
  state.harvestPickedCardIds = [];
  state.harvestPickers = [];
  recordAction(state, {
    type: "HARVEST_EMPTY",
    description: "🍚 Mở Kho Cứu Tế đã chia xong, các lá còn dư được bỏ vào Mộ."
  });
  resetWaitingState(state);
  return false;
}


function buildTargetCardOptions(state, targetSeat, allowDelayed = true, includeHand = true) {
  const target = state.players.find((player) => player.seat === targetSeat);
  if (!target) return [];

  const options = [];
  if (includeHand) {
    for (let index = 0; index < (target.hand || []).length; index++) {
      options.push({
        token: `HAND:${index}`,
        zone: "HAND",
        label: "TRÊN TAY",
        card: null
      });
    }
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
  const includeHand = selectionOptions.includeHand !== undefined
    ? selectionOptions.includeHand !== false
    : [CARD_SUBTYPES.SNATCH, CARD_SUBTYPES.DISMANTLE].includes(card.subType);
  const options = buildTargetCardOptions(state, targetSeat, allowDelayed, includeHand);
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
    effectType: selectionOptions.effectType || "TARGET_CARD",
    remainingCount: Math.max(1, Number(selectionOptions.remainingCount) || 1)
  };
  state.phase = "AWAIT_TARGET_CARD";
  state.waitingTargetSeat = casterSeat;
  state.waitingReactionType = "TARGET_CARD";
  state.waitingTimer = 40;
    state.timerStartAt = Date.now();
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
  } else if (selection.operation === "RETURN") {
    target.hand.push(card);
  } else {
    discardCard(state, card, option.zone !== "HAND");
  }

  const actionType = selection.effectType === "TRIEU_DANG" ? "TRIEU_DANG_DESTROY"
    : selection.effectType === "THUONG_NGAU" ? "THUONG_NGAU_DESTROY"
    : selection.effectType === "DOAN_DAO" ? "DOAN_DAO_DESTROY"
    : selection.effectType === "TAU_VI" ? "TAU_VI_DISCARD_EQUIPMENT"
    : selection.effectType === "PHU_DE" ? "PHU_DE_RETURN_EQUIPMENT"
    : selection.effectType === "FLAWLESS_DEFENSE" ? "PLAY_FLAWLESS_DEFENSE"
    : selection.operation === "STEAL" ? "PLAY_SNATCH" : "PLAY_DISMANTLE";
  const actionVerb = selection.operation === "STEAL" ? "cướp" : selection.operation === "RETURN" ? "đưa về tay" : "phá hủy";
  const publicTargetName = option.zone === "HAND" ? "lá úp trên tay" : formatCardText(card);
  let desc = `${selection.operation === "STEAL" ? "🌾" : "🏚️"} <b>${caster ? caster.generalName : 'Người chơi'}</b> dùng [${selection.cardName}] ${actionVerb} [${publicTargetName}] của <b>${target.generalName}</b>!`;
  if (selection.effectType === "TRIEU_DANG") {
    desc = `🌊 <b>${caster ? caster.generalName : 'Người chơi'}</b> dùng kỹ năng <b>Triều Dâng</b> phá hủy trang bị [${publicTargetName}] của <b>${target.generalName}</b>!`;
  }
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
    description: desc
  });
  checkGameOver(state);
  return { success: true, state };
}

function cardSummary(card) {
  return card ? {
    id: card.id,
    name: getCardName(card),
    suit: card.suit,
    rank: card.rank,
    category: card.category,
    subType: card.subType,
    desc: card.desc || ""
  } : null;
}

function finishHichSelection(state, reason = "") {
  const selection = state.hichSelection;
  const names = [];
  for (const seat of [selection?.casterSeat, selection?.targetSeat]) {
    const player = state.players.find((candidate) => candidate.seat === seat);
    if (player && isSucSoiActive(player)) names.push(player.generalName);
  }
  state.hichSelection = null;
  resetWaitingState(state);
  recordAction(state, {
    type: "HICH_TUONG_SI_COMPLETE",
    casterSeat: selection?.casterSeat || 0,
    targetSeat: selection?.targetSeat || 0,
    cardId: selection?.cardId || "",
    cardName: selection?.cardName || "Hịch Tướng Sĩ",
    description: `📣 Hịch Tướng Sĩ kết thúc${reason ? `: ${reason}` : "."} ${names.length ? `${names.join(", ")} nhận Sục Sôi.` : "Không ai bỏ bài để nhận Sục Sôi."}`
  });
  return { success: true, state };
}

function beginThuyTrieuRutTransfer(state, selection) {
  const giver = state.players.find((player) => player.seat === selection?.giverSeat);
  const receiver = state.players.find((player) => player.seat === selection?.receiverSeat);

  if (state.status === "FINISHED" || !isLivingPlayer(giver) || !isLivingPlayer(receiver) || !giver.hand.length) {
    state.thuyTrieuRutSelection = null;
    if (state.status !== "FINISHED") resetWaitingState(state);
    recordAction(state, {
      type: "THUY_TRIEU_RUT_TRANSFER_SKIPPED",
      casterSeat: selection?.casterSeat || 0,
      targetSeat: selection?.targetSeat || 0,
      cardId: selection?.cardId || "",
      cardName: selection?.cardName || "Thủy Triều Rút",
      description: "🌊 Thủy Triều Rút không thể chuyển bài vì một người chơi không còn đủ điều kiện."
    });
    return { success: true, state };
  }

  state.phase = "AWAIT_THUY_TRIEU_RUT_GIVE";
  state.waitingTargetSeat = giver.seat;
  state.waitingReactionType = "THUY_TRIEU_RUT_GIVE";
  state.waitingTimer = 40;
  state.timerStartAt = Date.now();
  state.activeCard = {
    cardId: selection.cardId,
    cardName: selection.cardName,
    casterSeat: selection.casterSeat,
    targetSeat: selection.targetSeat,
    giverSeat: giver.seat,
    receiverSeat: receiver.seat
  };
  recordAction(state, {
    type: "THUY_TRIEU_RUT_PROMPT_GIVE",
    casterSeat: selection.casterSeat,
    targetSeat: selection.targetSeat,
    cardId: selection.cardId,
    cardName: selection.cardName,
    giverSeat: giver.seat,
    receiverSeat: receiver.seat,
    description: `🌊 <b>${giver.generalName}</b> phải chọn 1 lá trên tay đưa cho <b>${receiver.generalName}</b>. Nếu lá đưa không phải Bài Cơ Bản, người ít bài hơn sau chuyển chịu 1 sát thương Thủy. (40s).`
  });
  return { success: true, state };
}

/**
 * Thực thi hiệu ứng cẩm nang sau khi chuỗi Diệu Kế kết thúc và không bị hóa giải
 */
export function executeCardEffect(state, card, casterSeat, targetSeat = 0, payload = {}) {
  const caster = state.players.find(x => x.seat === casterSeat);
  const target = state.players.find(x => x.seat === targetSeat);

  if (card.subType === CARD_SUBTYPES.KHO_NHUC_KE) {
    discardCard(state, card);
    const damageResult = applyDamageToPlayer(state, casterSeat, 1, "Khổ Nhục Kế");
    if (damageResult.enteredNearDeath) { state.pendingAfterNearDeath = { type: "KHO_NHUC_KE", casterSeat }; return { success: true, state }; }
    drawCards(state, casterSeat, 3);
    resetWaitingState(state);
    return { success: true, state };
  }
  if (card.subType === CARD_SUBTYPES.TAU_VI_THUONG_SACH) {
    discardCard(state, card);
    return startTargetCardSelection(state, card, casterSeat, casterSeat, { allowDelayed: false, includeHand: false, operation: "DESTROY", effectType: "TAU_VI" });
  }
  if (card.subType === CARD_SUBTYPES.PHU_DE_TRUU_TAN) {
    discardCard(state, card);
    return startTargetCardSelection(state, card, casterSeat, targetSeat, { allowDelayed: false, includeHand: false, operation: "RETURN", effectType: "PHU_DE" });
  }

  // 0. XÍCH TÂM TỎA (Iron Chain - Hỗ trợ chọn tối đa 2 mục tiêu)
  if (card.subType === CARD_SUBTYPES.IRON_CHAIN) {
    const ironChainTargets = collectIronChainTargets(state, card, targetSeat, payload);
    if (ironChainTargets.error) return ironChainTargets;
    const seatsToChain = ironChainTargets.seats;

    discardCard(state, card);
    if (ironChainTargets.recast || card.recast === true) {
      const drawn = drawCards(state, casterSeat, 1);
      resetWaitingState(state);
      recordAction(state, {
        type: "RECAST_IRON_CHAIN",
        casterSeat,
        cardId: card.id,
        cardName: card.name,
        description: `⛓️ <b>${caster ? caster.generalName : "Người chơi"}</b> đổi [Xích Tâm Tỏa] để rút 1 lá bài.`,
        drawnCount: drawn.length
      });
      refreshLastDelta(state);
      return { success: true, state };
    }
    const changedDescs = [];
    for (const s of seatsToChain) {
      const p = state.players.find(x => x.seat === s);
      if (p && p.hp > 0) {
        p.isChained = !p.isChained;
        changedDescs.push(`<b>${p.generalName}</b> (${p.isChained ? "⛓️ Trói" : "🔓 Gỡ"})`);
      }
    }
    resetWaitingState(state);
    recordAction(state, {
      type: "PLAY_IRON_CHAIN",
      casterSeat,
      targetSeats: seatsToChain,
      cardId: card.id,
      cardName: card.name,
      description: `⛓️ <b>${caster ? caster.generalName : 'Người chơi'}</b> dùng [Xích Tâm Tỏa] lên ${changedDescs.join(", ")}!`
    });
    refreshLastDelta(state);
    return { success: true, state };
  }

  // 1. THỦY TRIỀU RÚT: mục tiêu đưa người dùng 1 lá; lá không cơ bản mới so bài và gây sát thương Thủy.
  if (card.subType === CARD_SUBTYPES.THUY_TRIEU_RUT) {
    if (!caster || !target || !target.hand.length) {
      resetWaitingState(state);
      discardCard(state, card);
      return { error: "Mục tiêu Thủy Triều Rút phải có ít nhất 1 lá trên tay" };
    }
    discardCard(state, card);

    const selection = {
      cardId: card.id,
      cardName: card.name,
      casterSeat,
      targetSeat,
      giverSeat: target.seat,
      receiverSeat: caster.seat
    };
    state.thuyTrieuRutSelection = selection;
    state.activeCard = { ...selection };
    recordAction(state, {
      type: "PLAY_THUY_TRIEU_RUT",
      casterSeat,
      targetSeat,
      cardId: card.id,
      cardName: card.name,
      giverSeat: target.seat,
      receiverSeat: caster.seat,
      description: `🌊 ${caster.generalName} dùng Thủy Triều Rút. ${target.generalName} phải đưa 1 lá cho ${caster.generalName}; chỉ khi lá đó không phải Bài Cơ Bản mới so số bài và gây sát thương Thủy.`
    });
    return beginThuyTrieuRutTransfer(state, selection);
  }

  // 1.1. MỞ YẾN TIỆC
  if (card.subType === CARD_SUBTYPES.MO_YEN_TIEC) {
    discardCard(state, card);
    const healed = [];
    for (const player of state.players) {
      if (isLivingPlayer(player) && player.hp < player.maxHp) {
        player.hp++;
        healed.push(player.generalName);
      }
    }
    resetWaitingState(state);
    recordAction(state, {
      type: "PLAY_MO_YEN_TIEC",
      casterSeat,
      cardId: card.id,
      cardName: card.name,
      description: `🍽️ ${caster.generalName} mở Yến Tiệc. ${healed.length ? healed.join(", ") + " được hồi 1 Máu." : "Không ai cần hồi Máu."}`
    });
    return { success: true, state };
  }

  // 1.2. HỊCH TƯỚNG SĨ
  if (card.subType === CARD_SUBTYPES.HICH_TUONG_SI && card.recast === true) {
    discardCard(state, card);
    const drawn = drawCards(state, casterSeat, 1);
    resetWaitingState(state);
    recordAction(state, {
      type: "RECAST_HICH_TUONG_SI",
      casterSeat,
      cardId: card.id,
      cardName: card.name,
      drawnCount: drawn.length,
      description: `📣 ${caster ? caster.generalName : "Người chơi"} đổi [Hịch Tướng Sĩ] để rút 1 lá bài khác.`
    });
    refreshLastDelta(state);
    return { success: true, state };
  }
  const remainingCount = Math.max(0, Number(selection.remainingCount) - 1);
  if (selection.effectType === "DOAN_DAO" && remainingCount > 0) {
    return startTargetCardSelection(state, { id: selection.cardId, name: selection.cardName, subType: CARD_SUBTYPES.DISMANTLE }, chooserSeat, target.seat, { allowDelayed: false, includeHand: true, operation: "DESTROY", effectType: "DOAN_DAO", remainingCount });
  }
  if (selection.effectType === "TAU_VI") drawCards(state, chooserSeat, 2);
  if (card.subType === CARD_SUBTYPES.HICH_TUONG_SI) {
    const hichTarget = collectHichTarget(state, casterSeat, targetSeat, card, payload);
    if (hichTarget.error) {
      discardCard(state, card);
      resetWaitingState(state);
      return hichTarget;
    }
    discardCard(state, card);
    targetSeat = hichTarget.targetSeat;
    state.hichSelection = {
      cardId: card.id,
      cardName: card.name,
      casterSeat,
      targetSeat,
      casterDiscarded: false,
      targetDiscarded: false
    };
    state.phase = "AWAIT_HICH_CASTER_DISCARD";
    state.waitingTargetSeat = casterSeat;
    state.waitingReactionType = "HICH_DISCARD";
    state.waitingTimer = 40;
    state.timerStartAt = Date.now();
    state.activeCard = { cardId: card.id, cardName: card.name, casterSeat, targetSeat };
    recordAction(state, {
      type: "HICH_TUONG_SI_PROMPT",
      casterSeat,
      targetSeat,
      cardId: card.id,
      cardName: card.name,
      description: `📣 ${caster.generalName} phát Hịch Tướng Sĩ. ${caster.generalName} chọn 1 lá trên tay để bỏ và nhận Sục Sôi; sau đó hỏi Ghế ${targetSeat}.`
    });
    return { success: true, state };
  }

  // 1.3. MƯỢN GƯƠM DIỆT ĐỊCH: ép chủ vũ khí đánh mục tiêu khác.
  if (card.subType === CARD_SUBTYPES.MUON_GUOM_DIET_DICH) {
    const borrowValidation = validateBorrowSwordTargets(state, targetSeat, card.targetSeat2);
    if (borrowValidation.error) {
      discardCard(state, card);
      resetWaitingState(state);
      return borrowValidation;
    }
    const weaponOwner = borrowValidation.weaponOwner;
    const weapon = borrowValidation.weapon;
    const forcedTargetSeat = borrowValidation.forcedTargetSeat;
    discardCard(state, card);
    state.phase = "AWAIT_BORROW_SWORD";
    state.waitingTargetSeat = targetSeat;
    state.waitingReactionType = "SLASH";
    state.waitingTimer = 40;
    state.timerStartAt = Date.now();
    state.activeCard = { cardId: card.id, cardName: card.name, casterSeat, targetSeat, forcedTargetSeat, weaponId: weapon.id };
    recordAction(state, {
      type: "PLAY_MUON_GUOM_DIET_DICH",
      casterSeat,
      targetSeat,
      targetSeat2: forcedTargetSeat,
      cardId: card.id,
      cardName: card.name,
      description: `🗡️ ${caster.generalName} buộc ${weaponOwner.generalName} dùng vũ khí đánh Ghế ${forcedTargetSeat}. Không đánh sẽ mất vũ khí.`
    });
    return { success: true, state };
  }

  // 2. DỤNG BINH NHƯ THẦN (Ex Nihilo)
  if (card.subType === CARD_SUBTYPES.EX_NIHILO) {
    discardCard(state, card);
    const drawn = drawCards(state, casterSeat, 2);
    resetWaitingState(state);
    recordAction(state, {
      type: "PLAY_EX_NIHILO",
      casterSeat,
      cardId: card.id,
      cardName: card.name,
      description: `📜 <b>${caster ? caster.generalName : 'Người chơi'}</b> dùng ${formatCardText(card)} rút thêm 2 lá bài vào tay!`
    });
    return { success: true, state };
  }

  // 2. MỞ KHO CỨU TẾ (Harvest)
  if (card.subType === CARD_SUBTYPES.HARVEST) {
    discardCard(state, card);
    const living = [];
    for (const s of getSeatsAfter(state, casterSeat, true)) {
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
    state.harvestDisplayPool = pool.slice();
    state.harvestPickedCardIds = [];
    state.harvestPickers = living.slice(0, pool.length).map(p => p.seat);
      
      state.activeCard = { cardId: card.id, cardName: card.name, casterSeat };
      recordAction(state, {
        type: "HARVEST_START",
        casterSeat,
        cardId: card.id,
        cardName: card.name,
        harvestPool: pool,
        description: `🌾 <b>${caster ? caster.generalName : 'Người chơi'}</b> ${formatCardText(card)} lật ${pool.length} lá bài công khai!`
      });

      if (state.harvestPool.length === 0 || state.harvestPickers.length === 0) {
        state.harvestPool = [];
        state.harvestPickers = [];
        resetWaitingState(state);
        return { success: true, state };
      }

      const hasMore = beginNextHarvestPicker(state);
    if (!hasMore && state.harvestPickers && state.harvestPickers.length === 0 && (!state.harvestPool || state.harvestPool.length === 0)) {
        state.phase = "PLAY";
        state.waitingTargetSeat = 0;
        state.waitingReactionType = null;
        state.activeCard = null;
    }
      refreshLastDelta(state);
      return { success: true, state };
    }

    // 3. DIỆN RỘNG (Mưa Tên / Giặc Tới)
    if (card.subType === CARD_SUBTYPES.ARROW_RAIN || card.subType === CARD_SUBTYPES.BARBARIAN_INVASION) {
    discardCard(state, card);
    const reqType = (card.subType === CARD_SUBTYPES.ARROW_RAIN) ? "DODGE" : "SLASH";
    const reqName = (card.subType === CARD_SUBTYPES.ARROW_RAIN) ? "Đỡ" : "Trảm";
    const victims = [];
    for (const nextSeat of getSeatsAfter(state, casterSeat)) {
      if (nextSeat === casterSeat) continue;
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
    state.timerStartAt = Date.now();
    state.activeCard = { cardId: card.id, cardName: card.name, casterSeat, targetSeat };
    recordAction(state, {
      type: "PLAY_DUEL",
      casterSeat,
      targetSeat,
      cardId: card.id,
      cardName: card.name,
      description: `⚔️ <b>${caster ? caster.generalName : 'Người chơi'}</b> phát động ${formatCardText(card)} nhắm vào <b>${target ? target.generalName : 'đối thủ'}</b>! (Có 40s để đáp trả Trảm)`
    });
    return { success: true, state };
  }

  // 5. CÁC LÁ CẨM NANG TRÌ HOÃN (Đại Hồng Thủy / Cắt Đường Lương / Trầm Ảo Sa Bẫy)
  if (card.category === CARD_CATEGORIES.DELAYED_SCROLL || card.subType === CARD_SUBTYPES.DAI_HONG_THUY || card.subType === CARD_SUBTYPES.SUPPLY_SHORTAGE || card.subType === CARD_SUBTYPES.ACEDIA || card.subType === CARD_SUBTYPES.BAI_COC_BACH_DANG) {
    const attachTarget = (card.subType === CARD_SUBTYPES.DAI_HONG_THUY) ? caster : target;
    if (attachTarget) {
      if (!attachTarget.judgements) attachTarget.judgements = [];
      card.attachedBySeat = casterSeat;
      if (card.subType === CARD_SUBTYPES.BAI_COC_BACH_DANG) card.baiCocJudgementCount = 0;
      attachTarget.judgements.push(card);
      recordAction(state, {
        type: "DELAYED_SCROLL_ATTACHED",
        casterSeat,
        targetSeat: attachTarget.seat,
        cardId: card.id,
        cardName: card.name,
        description: `⚡ <b>${caster ? caster.generalName : 'Người chơi'}</b> đã gài cẩm nang trì hoãn ${formatCardText(card)} vào khu phán xét của <b>${attachTarget.generalName}</b>!`
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
    allowDelayed: card.subType === CARD_SUBTYPES.SNATCH || card.subType === CARD_SUBTYPES.DISMANTLE || card.subType === CARD_SUBTYPES.FLAWLESS_DEFENSE,
    includeHand: [CARD_SUBTYPES.SNATCH, CARD_SUBTYPES.DISMANTLE].includes(card.subType)
  });
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

    if (state.pendingChainSpread) {
      const chainResult = continueChainSpread(state);
      if (state.phase === "AWAIT_NEAR_DEATH") return chainResult;
    }

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
              includeHand: true,
              operation: "DESTROY",
              effectType: "THUONG_NGAU"
            });
        }
        if (pending.type === "THUY_TRIEU_RUT") {
          return beginThuyTrieuRutTransfer(state, pending);
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

function continueChainSpread(state) {
  const pending = state.pendingChainSpread;
  if (!pending) return null;

  if (state.status === "FINISHED") {
    state.pendingChainSpread = null;
    return null;
  }

  while (pending.targetSeats.length > 0) {
    if (state.status === "FINISHED") {
      state.pendingChainSpread = null;
      return null;
    }
    const peerSeat = pending.targetSeats.shift();
    const peer = state.players.find((player) => player.seat === peerSeat);
    if (!isLivingPlayer(peer) || !peer.isChained) continue;

    peer.isChained = false;
    recordAction(state, {
      type: "CHAIN_DAMAGE_SPREAD",
      sourceSeat: pending.sourceSeat,
      targetSeat: peer.seat,
      damage: pending.damage,
      element: pending.element,
      description: `⛓️🌊 <color=#FFD700><b>[XÍCH LIÊN HOÀN]</b></color>: Sát thương ${pending.element === "FIRE" ? "Hỏa" : "Thủy"} (${pending.damage} điểm) lan truyền sang <b>${peer.generalName}</b> và gỡ xích!`
    });

    const result = applyDamageToPlayer(state, peer.seat, pending.damage, "sát thương xích lan truyền", pending.element);
    if (result.enteredNearDeath) return { success: true, state };
  }

  state.pendingChainSpread = null;
  return null;
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
  victim.isAlive = false;
  victim.isChained = false;
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

  if (state.phase === "AWAIT_KHOI_BINH") {
    const pending = state.khoiBinhQueue?.[0];
    if (!pending || pending.seat !== respondentSeat) return { error: "Khởi Binh không còn hiệu lực" };
    state.khoiBinhQueue.shift();
    const source = state.players.find((player) => player.seat === pending.sourceSeat);
    if (accepted && isLivingPlayer(source)) {
      drawCards(state, respondentSeat, 1);
      drawCards(state, source.seat, 1);
      recordAction(state, {
        type: "KHOI_BINH_DRAW",
        casterSeat: respondentSeat,
        targetSeat: source.seat,
        description: `⚔️ ${respondent.generalName} kích hoạt [Khởi Binh], ${respondent.generalName} và ${source.generalName} mỗi người rút 1 lá.`
      });
    } else {
      recordAction(state, {
        type: "KHOI_BINH_DECLINED",
        casterSeat: respondentSeat,
        targetSeat: pending.sourceSeat,
        description: `⚔️ ${respondent.generalName} không kích hoạt [Khởi Binh].`
      });
    }
    if (!startNextKhoiBinhPrompt(state)) resetWaitingState(state);
    return { success: true, state };
  }

  if (state.phase === "AWAIT_DOAN_DAO_CHOICE") {
    const activeCard = state.activeCard || {};
    const target = state.players.find((player) => player.seat === activeCard.targetSeat);
    const doanDao = getEquippedWeapon(respondent, "Đoản Đao");
    if (accepted && doanDao && target && buildTargetCardOptions(state, target.seat, false, true).length >= 2) {
      return startTargetCardSelection(state, doanDao, respondent.seat, target.seat, { allowDelayed: false, includeHand: true, operation: "DESTROY", effectType: "DOAN_DAO", remainingCount: 2 });
    }
    state.phase = "AWAIT_SLASH_DEFENSE";
    state.waitingTargetSeat = activeCard.targetSeat;
    return handleRespondAction(state, activeCard.targetSeat, false, null);
  }

  // --- 0. PHẢN HỒI CHUỖI DIỆU KẾ PHÁ MƯU (AWAIT_NULLIFY) ---
  if (state.phase === "AWAIT_NULLIFY" && state.nullifyChain) {
    const chain = state.nullifyChain;
    const rootCard = chain.rootCard;

    if (accepted && cardId) {
      const idx = respondent.hand.findIndex(c => (c.id === cardId || c.name === cardId)
        && (c.subType === CARD_SUBTYPES.FLAWLESS_DEFENSE
          || (c.name && c.name.includes("Diệu Kế"))));
      if (idx < 0) return { error: "Lá Diệu Kế Phá Mưu không còn hợp lệ" };
      {
        const nullifyCard = respondent.hand.splice(idx, 1)[0];
        discardCard(state, nullifyCard);

        chain.isCanceled = !chain.isCanceled;
        chain.whoUsedLast = respondentSeat;
        state.activeCard = {
          ...state.activeCard,
          isCanceled: chain.isCanceled
        };

        // Bắt đầu vòng hỏi mới cho 3 người chơi còn lại (tuyệt đối KHÔNG hỏi lại người vừa dùng Diệu Kế)
        const newQuerySeats = [];
        for (const s of getSeatsAfter(state, respondentSeat)) {
          if (s === respondentSeat) continue;
          const p = state.players.find(x => x.seat === s);
          if (p && p.hp > 0) {
            const hasNullify = p.hand && p.hand.some(c => c.subType === CARD_SUBTYPES.FLAWLESS_DEFENSE || (c.name && c.name.includes("Diệu Kế")));
            if (hasNullify) newQuerySeats.push(s);
          }
        }
        state.activeCard = {
          ...state.activeCard,
          nullifyRound: (Number(state.activeCard?.nullifyRound) || 0) + 1,
          nullifyBySeat: respondentSeat
        };

        if (newQuerySeats.length > 0) {
            chain.querySeats = newQuerySeats;
            chain.currentIdx = 0;
            state.waitingTargetSeat = newQuerySeats[0];
            state.waitingTimer = 40;
    state.timerStartAt = Date.now();

            recordAction(state, {
              type: "NULLIFY_PLAYED",
              casterSeat: respondentSeat,
              cardId: nullifyCard.id,
              cardName: nullifyCard.name,
              description: `🛡️ <b>${respondent.generalName}</b> đã tung <color=#55FF55><b>[Diệu Kế Phá Mưu]</b></color>! Trạng thái mưu kế ${formatCardText(rootCard)}: ${chain.isCanceled ? '<color=#FF5555>BỊ VÔ HIỆU HÓA</color>' : '<color=#55FF55>ĐƯỢC BẢO VỆ THÀNH CÔNG</color>'}. Đang chờ người chơi phản hồi tiếp theo (40s)...`
            });
            return { success: true, state };
        } else {
            recordAction(state, {
              type: "NULLIFY_PLAYED",
              casterSeat: respondentSeat,
              cardId: nullifyCard.id,
              cardName: nullifyCard.name,
              description: `🛡️ <b>${respondent.generalName}</b> đã tung <color=#55FF55><b>[Diệu Kế Phá Mưu]</b></color>! Trạng thái mưu kế ${formatCardText(rootCard)}: ${chain.isCanceled ? '<color=#FF5555>BỊ VÔ HIỆU HÓA</color>' : '<color=#55FF55>ĐƯỢC BẢO VỆ THÀNH CÔNG</color>'}. Không ai khác có Diệu Kế, tiến hành thực thi.`
            });
            
            if (chain.isCanceled) {
                return resolveCanceledNullifyChain(state, chain);
            } else {
                const cont = chain.continuation;
                const effCard = chain.rootCard;
                const target = chain.targetSeat;
                const effCaster = chain.casterSeat;
                state.nullifyChain = null;

                if (["BAI_COC_ACTION", "BORROW_SWORD_SLASH"].includes(cont?.type)) {
                  return resolveBaiCocAction(state, cont, false);
                }
                if (cont?.type === "TURN_JUDGEMENT") {
                  resolveJudgementCard(state, effCard, cont.seat);
                  if (state.phase === "AWAIT_NEAR_DEATH") return { success: true, state };
                  refreshLastDelta(state);
                  return { success: true, state };
                }
                if (cont?.type === "CONTINUE_AOE") {
                  const nextVictim = target;
                  if (state.activeCard?.reqType === "DODGE" && tryKhienMayDefense(state, nextVictim, "đòn diện rộng")) {
                     beginNextAoeVictim(state);
                  } else {
                     state.phase = "AWAIT_AOE";
                     state.waitingReactionType = state.activeCard?.reqType || "DODGE";
                     state.waitingTargetSeat = nextVictim;
                     state.waitingTimer = 40;
                     state.timerStartAt = Date.now();
                     refreshLastDelta(state);
                  }
                  return { success: true, state };
                }
                if (cont?.type === "CONTINUE_HARVEST") {
                  state.phase = "AWAIT_HARVEST";
                  state.waitingTargetSeat = target;
                  state.waitingTimer = 40;
    state.timerStartAt = Date.now();
                  recordAction(state, {
                    type: "AWAIT_HARVEST",
                    casterSeat: target,
                    description: `Kho Cứu Tế: Đang chờ <b>${state.players.find(p=>p.seat===target)?.generalName}</b> chọn bài (40s)...`
                  });
                  return { success: true, state };
                }
                return executeCardEffect(state, effCard, effCaster, target);
            }
        }
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
    state.timerStartAt = Date.now();
      recordAction(state, {
        type: "NULLIFY_PASS",
        casterSeat: respondentSeat,
        description: `⏭️ <b>${respondent.generalName}</b> không dùng Diệu Kế Phá Mưu. Đang hỏi <b>${nextGen ? nextGen.generalName : 'Ghế ' + nextSeat}</b> (40s)...`
      });
      return { success: true, state };
    }

    // ĐÃ HỎI HẾT CẢ VÒNG MÀ KHÔNG AI PHÁ TIẾP:
    if (chain.isCanceled) {
      return resolveCanceledNullifyChain(state, chain);
    }

    // Mưu kế được thực thi thành công!
    const { casterSeat, targetSeat } = chain;
    state.nullifyChain = null;
    if (["BAI_COC_ACTION", "BORROW_SWORD_SLASH"].includes(chain.continuation?.type)) {
      return resolveBaiCocAction(state, chain.continuation, false);
    }
    if (chain.continuation?.type === "TURN_JUDGEMENT") {
      resolveJudgementCard(state, rootCard, chain.continuation.seat);
      if (state.phase === "AWAIT_NEAR_DEATH") return { success: true, state };
      refreshLastDelta(state);
      return { success: true, state };
    }
    if (chain.continuation?.type === "CONTINUE_AOE") {
      // Mưu kế diện rộng không bị hóa giải cho mục tiêu này -> Bắt đầu chờ Đỡ/Trảm từ nạn nhân
      const nextVictim = chain.targetSeat;
      if (state.activeCard?.reqType === "DODGE" && tryKhienMayDefense(state, nextVictim, "đòn diện rộng")) {
         beginNextAoeVictim(state);
      } else {
         state.phase = "AWAIT_AOE";
         state.waitingReactionType = state.activeCard?.reqType || "DODGE";
         state.waitingTargetSeat = nextVictim;
         state.waitingTimer = 40;
    state.timerStartAt = Date.now();
         refreshLastDelta(state);
      }
      return { success: true, state };
    }
    if (chain.continuation?.type === "CONTINUE_HARVEST") {
      // Mưu kế diện rộng không bị hóa giải cho mục tiêu này -> Bắt đầu chờ nạn nhân chọn bài
      const nextVictim = chain.targetSeat;
      state.phase = "AWAIT_HARVEST";
      state.waitingReactionType = "HARVEST";
      state.waitingTargetSeat = nextVictim;
      state.waitingTimer = 40;
    state.timerStartAt = Date.now();
      refreshLastDelta(state);
      return { success: true, state };
    }
    return executeCardEffect(state, rootCard, casterSeat, targetSeat);
  }

  if (state.phase === "AWAIT_HICH_CASTER_DISCARD" || state.phase === "AWAIT_HICH_TARGET_DISCARD") {
    const selection = state.hichSelection;
    const isCaster = state.phase === "AWAIT_HICH_CASTER_DISCARD";
    const expectedSeat = isCaster ? selection?.casterSeat : selection?.targetSeat;
    if (!selection || respondentSeat !== expectedSeat) return { error: "Hịch Tướng Sĩ không còn hiệu lực" };

    if (accepted && cardId) {
      const index = respondent.hand.findIndex((candidate) => candidate.id === cardId || candidate.name === cardId);
      if (index < 0) return { error: "Lá bài bỏ cho Hịch Tướng Sĩ không còn hợp lệ" };
      const discarded = respondent.hand.splice(index, 1)[0];
      discardCard(state, discarded);
      if (isCaster) {
        selection.casterDiscarded = true;
        respondent.sucSoiTurnsRemaining = Math.max(1, Number(respondent.sucSoiTurnsRemaining) || 0);
      } else {
        selection.targetDiscarded = true;
        respondent.sucSoiTurnsRemaining = Math.max(1, Number(respondent.sucSoiTurnsRemaining) || 0);
      }
      recordAction(state, {
        type: "HICH_TUONG_SI_DISCARD",
        casterSeat: selection.casterSeat,
        targetSeat: selection.targetSeat,
        cardId: discarded.id,
        cardName: discarded.name,
        description: `📣 ${respondent.generalName} đã tự chọn và bỏ 1 lá bài để nhận Sục Sôi.`
      });
    } else if (accepted) {
      return { error: "Cần chọn 1 lá bài để bỏ" };
    }

    if (isCaster && selection.targetSeat > 0) {
      const target = state.players.find((player) => player.seat === selection.targetSeat);
      if (target && isLivingPlayer(target) && target.hand.length > 0) {
        state.phase = "AWAIT_HICH_TARGET_DISCARD";
        state.waitingTargetSeat = target.seat;
        state.waitingReactionType = "HICH_DISCARD";
        state.waitingTimer = 40;
        state.timerStartAt = Date.now();
        recordAction(state, {
          type: "HICH_TUONG_SI_PROMPT_TARGET",
          casterSeat: selection.casterSeat,
          targetSeat: target.seat,
          description: `📣 ${target.generalName} được hỏi: có muốn bỏ 1 lá để nhận Sục Sôi không? Có thể Bỏ qua (40s).`
        });
        refreshLastDelta(state);
        return { success: true, state };
      }
    }
    return finishHichSelection(state, "đã xử lý lựa chọn bỏ bài");
  }

  if (state.phase === "AWAIT_THUY_TRIEU_RUT_GIVE") {
    const selection = state.thuyTrieuRutSelection;
    if (!selection || respondentSeat !== selection.giverSeat) return { error: "Không phải lượt đưa bài cho Thủy Triều Rút" };
    const giver = state.players.find((player) => player.seat === selection.giverSeat);
    const receiver = state.players.find((player) => player.seat === selection.receiverSeat);
    const index = accepted && cardId
      ? giver?.hand?.findIndex((candidate) => candidate.id === cardId) ?? -1
      : -1;
    if (!accepted || !cardId) return { error: "Cần chọn 1 lá trên tay để đưa" };
    if (index < 0) return { error: "Lá đưa không còn nằm trên tay" };
    if (!receiver || !isLivingPlayer(receiver)) return { error: "Người nhận không còn hợp lệ" };

    const given = giver.hand.splice(index, 1)[0];
    receiver.hand.push(given);
    const isBasicGivenCard = given.category === CARD_CATEGORIES.BASIC;
    const handCountsAreEqual = giver.hand.length === receiver.hand.length;
    const victim = !isBasicGivenCard && !handCountsAreEqual
      ? (giver.hand.length < receiver.hand.length ? giver : receiver)
      : null;
    state.thuyTrieuRutSelection = null;
    recordAction(state, {
      type: "THUY_TRIEU_RUT_GIVE",
      casterSeat: selection.casterSeat,
      targetSeat: selection.targetSeat,
      cardId: selection.cardId,
      cardName: selection.cardName,
      givenCard: cardSummary(given),
      giverSeat: giver.seat,
      receiverSeat: receiver.seat,
      description: isBasicGivenCard
        ? `🌊 ${giver.generalName} đưa [${given.name}] cho ${receiver.generalName}. Đây là Bài Cơ Bản nên không so số bài, không gây sát thương Thủy.`
        : handCountsAreEqual
          ? `🌊 ${giver.generalName} đưa [${given.name}] cho ${receiver.generalName}. Lá không phải Bài Cơ Bản, nhưng hai bên bằng số bài nên không ai chịu sát thương Thủy.`
          : `🌊 ${giver.generalName} đưa [${given.name}] cho ${receiver.generalName}. Lá không phải Bài Cơ Bản; ${victim.generalName} ít bài hơn sau chuyển và chịu 1 sát thương Thủy.`
    });
    if (victim) {
      const damageResult = applyDamageToPlayer(state, victim.seat, 1, "Thủy Triều Rút", "WATER");
      if (damageResult?.enteredNearDeath) return { success: true, state };
    }
    resetWaitingState(state);
    return { success: true, state };
  }

  if (state.phase === "AWAIT_DRUM_CHOICE") {
    const selection = state.drumSelection;
    if (!selection || respondentSeat !== selection.targetSeat) return { error: "Không phải lượt phản hồi Điểm Trống" };
    const target = state.players.find((player) => player.seat === selection.targetSeat);
    const owner = state.players.find((player) => player.seat === selection.ownerSeat);
    if (!target || target.hand.length === 0) {
      state.drumSelection = null;
      resetWaitingState(state);
      return { success: true, state };
    }
    if (accepted && cardId) {
      const index = target.hand.findIndex((candidate) => candidate.id === cardId || candidate.name === cardId);
      if (index < 0) return { error: "Lá bỏ cho Điểm Trống không còn hợp lệ" };
      const discarded = target.hand.splice(index, 1)[0];
      discardCard(state, discarded);
      state.drumSelection = null;
      resetWaitingState(state);
      recordAction(state, {
        type: "DRUM_DISCARD",
        casterSeat: selection.ownerSeat,
        targetSeat: selection.targetSeat,
        cardId: discarded.id,
        cardName: discarded.name,
        description: `🥁 ${target.generalName} chọn bỏ 1 lá bài theo Điểm Trống của ${owner?.generalName || "người dùng Trống Đồng"}.`
      });
      return { success: true, state };
    }
    state.drumReveal = {
      viewerSeat: selection.ownerSeat,
      targetSeat: selection.targetSeat,
      cards: target.hand.map(cardSummary)
    };
    state.drumSelection = null;
    resetWaitingState(state);
    recordAction(state, {
      type: "DRUM_REVEAL",
      casterSeat: selection.ownerSeat,
      targetSeat: selection.targetSeat,
      description: `🥁 ${target.generalName} chọn lộ toàn bộ bài trên tay cho ${owner?.generalName || "người dùng Trống Đồng"} xem đến hết lượt.`
    });
    return { success: true, state };
  }

  if (state.phase === "AWAIT_TARGET_CARD") {
    if (!accepted) return { error: "Cần chọn một lá bài mục tiêu" };
    return completeTargetCardSelection(state, respondentSeat, targetCardId || cardId);
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
      state.harvestPickedCardIds = [...(state.harvestPickedCardIds || []), pickedCard.id];
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

    // Continue to next picker (this will check for Nullify again)
    const hasMore = beginNextHarvestPicker(state);
    if (!hasMore && state.harvestPickers && state.harvestPickers.length === 0 && (!state.harvestPool || state.harvestPool.length === 0)) {
        state.phase = "PLAY";
        state.waitingTargetSeat = 0;
        state.waitingReactionType = null;
        state.activeCard = null;
    }
    refreshLastDelta(state);
    return { success: true, state };
  }

  if (state.phase === "AWAIT_SLASH_DEFENSE") {
    if (accepted && cardId) {
      if (cardId === "KHIEN_MAY" || cardId === "KHIEN_MAY_BEN" || cardId === "khien_may") {
        const caster = state.players.find(x => x.seat === (state.activeCard ? state.activeCard.casterSeat : 0));
        const hasThuanThien = getEquippedWeapon(caster, "Thuận Thiên");
        if (hasThuanThien) {
          return { error: "Đối phương trang bị Kiếm Thuận Thiên, đòn Trảm bỏ qua Trang bị Giáp!" };
        }
        const armor = getEquippedKhienMay(respondent);
        if (!armor) return { error: "Không có Khiên Mây Bện để phán xét" };
        const judgeCard = drawJudgementCard(state);
        const isRed = judgeCard && (judgeCard.suit === "Heart" || judgeCard.suit === "Diamond");
        recordAction(state, {
          type: isRed ? "KHIEN_MAY_SUCCESS" : "KHIEN_MAY_FAILED",
          casterSeat: respondentSeat,
          targetSeat: respondentSeat,
          cardId: armor.id,
          cardName: armor.name || "Khiên Mây Bện",
          judgeCard: judgeCard ? { id: judgeCard.id, name: judgeCard.name, suit: judgeCard.suit, rank: judgeCard.rank } : null,
          description: isRed
            ? `🛡️ [Khiên Mây Bện] của ${respondent.generalName} lật ${judgeCard.suit} ${judgeCard.rank} (ĐỎ) và tự động Đỡ đòn Trảm!`
            : `🛡️ [Khiên Mây Bện] của ${respondent.generalName} lật ${judgeCard.suit} ${judgeCard.rank} (ĐEN) và phán xét thất bại.`
        });
        if (isRed) {
          const caster = state.players.find(x => x.seat === (state.activeCard ? state.activeCard.casterSeat : 0));
          beginSlashAfterDodge(state, caster, respondentSeat, "Khiên Mây Bện");
          return { success: true, state };
        } else {
          if (!state.activeCard) state.activeCard = {};
          if (!state.activeCard.khienMayFailedSeats) state.activeCard.khienMayFailedSeats = [];
          state.activeCard.khienMayFailedSeats.push(respondentSeat);
          refreshLastDelta(state);
          return { success: true, state };
        }
      }

      const caster = state.players.find(x => x.seat === (state.activeCard ? state.activeCard.casterSeat : 0));
      const holyCannon = getEquippedWeapon(caster, "Súng Thần Công");
      const idx = respondent.hand.findIndex(c => (c.id === cardId || c.name === cardId || ((cardId === "DO" || cardId === "do") && isDodge(c))) && canUseCardAsDodge(respondent, c)
        && (!holyCannon || !sameCardColor(c.suit, state.activeCard?.suit)));
      if (idx < 0) return { error: "Lá Đỡ không còn hợp lệ cho đòn Trảm này" };
      {
        const dodgeCard = respondent.hand.splice(idx, 1)[0];
        discardCard(state, dodgeCard);

        beginSlashAfterDodge(state, caster, respondentSeat, formatCardText(dodgeCard));
        return { success: true, state };
      }
    }

    if (accepted) return { error: "Cần chọn một lá Đỡ hợp lệ" };

    // Không né hoặc hết giờ -> Đoản Đao có thể thay sát thương bằng hủy 2 lá.
    const doanDao = getEquippedWeapon(state.players.find((player) => player.seat === state.activeCard?.casterSeat), "Đoản Đao");
    if (doanDao && buildTargetCardOptions(state, respondentSeat, false, true).length >= 2) {
      state.phase = "AWAIT_DOAN_DAO_CHOICE";
      state.waitingTargetSeat = state.activeCard.casterSeat;
      state.waitingReactionType = "DOAN_DAO_CHOICE";
      state.waitingTimer = 40;
      state.timerStartAt = Date.now();
      return { success: true, state };
    }
    // Không né hoặc hết giờ -> Chịu sát thương
    const damage = (state.activeCard && state.activeCard.damage) ? state.activeCard.damage : 1;
    const activeCard = state.activeCard;
    let slashElement = activeCard?.damageElement || "NORMAL";
      if (slashElement === "NORMAL" && activeCard && (activeCard.subType === CARD_SUBTYPES.ATTACK_FIRE || (activeCard.name && activeCard.name.includes("Hỏa")))) slashElement = "FIRE";
      else if (slashElement === "NORMAL" && activeCard && (activeCard.subType === CARD_SUBTYPES.ATTACK_WATER || (activeCard.name && activeCard.name.includes("Thủy")))) slashElement = "WATER";
      const damageResult = applyDamageToPlayer(state, respondentSeat, damage, "đòn Trảm", slashElement, true);
    if (["AWAIT_UAT_KHI", "AWAIT_KHOI_BINH"].includes(state.phase)) return { success: true, state };
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
            includeHand: true,
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
        description: `🏹 <b>${caster.generalName}</b> bỏ 2 lá kích hoạt [Song Cung Mường Nhạ], bỏ qua Đỡ để Trảm gây ${Number(state.activeCard?.damage) || 1} sát thương!`
      });
      state.activeCard = { ...state.activeCard, songCungBypassDodge: true };
      return resolveSlashDamageAfterDefense(state, targetSeat);
    }

    resetWaitingState(state);
    recordAction(state, {
      type: "SONG_CUNG_PASSED",
      casterSeat: caster.seat,
      targetSeat,
      description: `🏹 ${caster.generalName} không kích hoạt Song Cung Mường Nhạ. Mục tiêu né Trảm thành công.`
    });
    refreshLastDelta(state);
    return { success: true, state };
  }

  // Migrate states created by the old follow-up prompt.
  if (state.phase === "AWAIT_NAM_SON_FOLLOW_UP") {
    const caster = respondent;
    const targetSeat = Number(state.activeCard?.targetSeat) || 0;
    const target = state.players.find(x => x.seat === targetSeat);
    if (state.activeCard?.countsTowardTurnSlashLimit !== false) {
      state.slashesUsedThisTurn = Math.max(0, (Number(state.slashesUsedThisTurn) || 0) - 1);
    }
    resetWaitingState(state);
    recordAction(state, {
      type: "DODGE_SUCCESS",
      casterSeat: caster.seat,
      targetSeat,
      description: `🛡️ ${target?.generalName || `Ghế ${targetSeat}`} đã né đòn. [Trường Đao Nam Sơn] xem như chưa sử dụng lượt Trảm.`
    });
    return { success: true, state };
  }

  if (state.phase === "AWAIT_BORROW_SWORD") {
    const weapon = respondent.equipments?.find((equipment) => equipment.id === state.activeCard?.weaponId);
    if (accepted && cardId) {
      if (!weapon) {
        return { error: "Mục tiêu Mượn Gươm không còn hợp lệ" };
      }
      return beginBorrowSwordSlash(state, respondent, cardId);
    }
    if (accepted) return { error: "Cần chọn một lá Trảm hợp lệ để Mượn Gươm" };

    const borrowCard = state.activeCard;
    if (weapon) {
      respondent.equipments = respondent.equipments.filter((equipment) => equipment.id !== weapon.id);
      const owner = state.players.find((player) => player.seat === borrowCard?.casterSeat);
      if (owner) owner.hand.push(weapon);
    }
    resetWaitingState(state);
    recordAction(state, {
      type: "BORROW_SWORD_PASSED",
      casterSeat: borrowCard?.casterSeat || 0,
      targetSeat: respondentSeat,
      description: `🗡️ ${respondent.generalName} không đánh Trảm. Vũ khí đã về tay người dùng Mượn Gươm.`
    });
    return { success: true, state };
  }

  // --- 2. PHẢN HỒI CẨM NANG DIỆN RỘNG (Mưa Tên / Giặc Tới) ---
  if (state.phase === "AWAIT_AOE") {
    const isArrow = state.waitingReactionType === "DODGE"
      || state.activeCard?.reqType === "DODGE";
    const aoeName = state.activeCard?.cardName || "";
    let satisfied = false;

    if (accepted && (cardId === "KHIEN_MAY" || cardId === "KHIEN_MAY_BEN")) {
      if (!isArrow) return { error: "Khiên Mây Bện chỉ có tác dụng khi cần Đỡ (Né)" };
      const armor = getEquippedKhienMay(respondent);
      if (!armor) return { error: "Không có Khiên Mây Bện để phán xét" };
      const judgeCard = drawJudgementCard(state);
      const isRed = judgeCard && (judgeCard.suit === "Heart" || judgeCard.suit === "Diamond");
      recordAction(state, {
          type: isRed ? "KHIEN_MAY_SUCCESS" : "KHIEN_MAY_FAILED",
          casterSeat: respondentSeat,
          targetSeat: respondentSeat,
        cardId: armor.id,
        cardName: armor.name || "Khiên Mây Bện",
        judgeCard: judgeCard ? { id: judgeCard.id, name: judgeCard.name, suit: judgeCard.suit, rank: judgeCard.rank } : null,
        description: isRed
          ? `🛡️ [Khiên Mây Bện] của ${respondent.generalName} lật ${judgeCard.suit} ${judgeCard.rank} (ĐỎ) và tự động né đòn diện rộng!`
          : `🛡️ [Khiên Mây Bện] của ${respondent.generalName} lật ${judgeCard.suit} ${judgeCard.rank} (ĐEN) và phán xét thất bại.`
      });
      if (isRed) {
        beginNextAoeVictim(state);
        refreshLastDelta(state);
        checkGameOver(state);
        return { success: true, state };
      } else {
        if (!state.activeCard) state.activeCard = {};
        if (!state.activeCard.khienMayFailedSeats) state.activeCard.khienMayFailedSeats = [];
        state.activeCard.khienMayFailedSeats.push(respondentSeat);
        refreshLastDelta(state);
        return { success: true, state };
      }
    }

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

    let aoeDamageResult = { finalDamage: 0, armorEffect: "", armorChargesRemaining: -1, armorExpired: false };
    if (!satisfied) {
      aoeDamageResult = applyDamageToPlayer(state, respondentSeat, 1, "đòn diện rộng");
      if (state.phase === "AWAIT_NEAR_DEATH") {
        return { success: true, state };
      }
    }

    recordAction(state, {
      type: satisfied ? "AOE_DEFENDED" : "AOE_HIT",
      targetSeat: respondentSeat,
      cardId: satisfied ? (state.discardTop?.id || "") : "",
      cardName: satisfied ? (state.discardTop?.name || (isArrow ? "Đỡ" : "Trảm")) : "",
      aoeName,
      armorEffect: aoeDamageResult.armorEffect || "",
      armorChargesRemaining: Number.isFinite(Number(aoeDamageResult.armorChargesRemaining)) ? aoeDamageResult.armorChargesRemaining : -1,
      armorExpired: aoeDamageResult.armorExpired === true,
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
    state.timerStartAt = Date.now();
        refreshLastDelta(state);
        recordAction(state, {
          type: "DUEL_RESPOND",
          casterSeat: respondentSeat,
          cardId: s.id,
          description: `⚔️ ${respondent.generalName} đáp trả 1 lá ${formatCardText(s)} trong Huyết Chiến!`
        });
        return { success: true, state };
      }
    }

    if (accepted) return { error: "Cần chọn một lá Trảm hợp lệ để đáp trả" };

    // Không ra Trảm -> Nhận thua Huyết Chiến và mất 1 Máu
    applyDamageToPlayer(state, respondentSeat, 1, "Huyết Chiến");
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
      const idx = respondent.hand.findIndex(c => (c.id === cardId || c.name === cardId || cardId === "banh_chung" || cardId === "ruou") && (isPeach(c) || (isWine(c) && respondentSeat === victim.seat)));
      if (idx < 0) return { error: "Lá cứu không còn hợp lệ" };
      const rescueCard = respondent.hand.splice(idx, 1)[0];
      discardCard(state, rescueCard);

      victim.hp = Math.min(victim.maxHp, victim.hp + 1);
      
      if (victim.hp > 0) {
        state.phase = "PLAY";
        state.waitingTargetSeat = 0;
        state.waitingTimer = 0;
        recordAction(state, {
          type: "RESCUE_SUCCESS",
          casterSeat: respondentSeat,
          targetSeat: victim.seat,
          cardId: rescueCard.id,
          cardName: rescueCard.name,
          description: `💮 <b>${respondent.generalName}</b> đã dùng ${formatCardText(rescueCard)} cứu sống <b>${victim.generalName}</b> (${victim.hp}/${victim.maxHp})!`
        });



        const resume = resolveNearDeathResume(state);
        refreshLastDelta(state);
        return resume;
      } else {
        state.waitingTimer = 40;
        state.timerStartAt = Date.now();
        recordAction(state, {
          type: "RESCUE_ATTEMPT",
          casterSeat: respondentSeat,
          targetSeat: victim.seat,
          cardId: rescueCard.id,
          cardName: rescueCard.name,
          description: `💮 <b>${respondent.generalName}</b> đã dùng ${formatCardText(rescueCard)} cứu <b>${victim.generalName}</b> nhưng vẫn còn (${victim.hp}/${victim.maxHp}) Máu; cần tiếp tục cứu.`
        });
        refreshLastDelta(state);
        return { success: true, state };
      }
    }

    // Nếu người này không cứu -> Hỏi người tiếp theo trong danh sách cứu viện
    if (state.nearDeathAskerQueue && state.nearDeathAskerQueue.length > 0) {
      const nextAsker = state.nearDeathAskerQueue.shift();
      state.waitingTargetSeat = nextAsker;
      state.waitingTimer = 40;
    state.timerStartAt = Date.now();
      recordAction(state, {
        type: "NEAR_DEATH_PROMPT",
        casterSeat: nextAsker,
        targetSeat: victim ? victim.seat : 0,
        description: `🆘 Đang hỏi Ghế ${nextAsker} có muốn dùng ${nextAsker === victim?.seat ? "Bánh Chưng hoặc Hủ Rượu" : "Bánh Chưng"} cứu <b>${victim ? victim.generalName : "người chơi"}</b> (${victim?.hp ?? 0} Máu; cần ${Math.max(1, 1 - (victim?.hp ?? 0))} lá, 40s)...`
      });
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

/**
 * Áp dụng sát thương lên người chơi và kích hoạt pha Hấp Hối (Near Death) nếu HP <= 0
 */
export function applyDamageToPlayer(state, targetSeat, damage, sourceDescription = "", damageElement = "NORMAL", isDirectSlashDamage = false, options = {}) {
  const target = state.players.find(x => x.seat === targetSeat);
  if (!target || target.hp <= 0) return { finalDamage: 0, enteredNearDeath: false };

  const rawDamage = Math.max(0, Number(damage) || 0);
  let finalDamage = rawDamage;
  let armorEffect = "";
  let armorChargesRemaining = -1;
  let armorExpired = false;
  const armorIndex = target.equipments.findIndex((equipment) =>
    equipment.subType === CARD_SUBTYPES.ARMOR && equipment.name?.includes("Áo Bào")
  );
  const attackerSeat = state.activeCard ? state.activeCard.casterSeat : 0;
  const attacker = state.players.find(p => p.seat === attackerSeat);
  const attackerHasThuanThien = isDirectSlashDamage && getEquippedWeapon(attacker, "Thuận Thiên");

  if (armorIndex >= 0 && rawDamage > 0 && !attackerHasThuanThien) {
    target.aoBaoCharges = Number.isFinite(Number(target.aoBaoCharges))
      ? Math.max(0, Math.min(2, Number(target.aoBaoCharges)))
      : 2;
    if (target.aoBaoCharges > 0) {
      target.aoBaoCharges--;
      finalDamage = Math.max(0, rawDamage - 1);
      armorEffect = "AO_BAO_HOANG_TOC";
      armorChargesRemaining = target.aoBaoCharges;
      if (target.aoBaoCharges === 0) {
        const expiredArmor = target.equipments.splice(armorIndex, 1)[0];
        discardCard(state, expiredArmor);
        armorExpired = true;
      }
    }
  }

  target.hp -= finalDamage;
  if (finalDamage > 0 && attackerSeat === state.turnSeat && attackerSeat !== targetSeat) {
    state.turnDamageDealt = true;
  }

  // XỬ LÝ LAN TRUYỀN SÁT THƯƠNG XÍCH LIÊN HOÀN (HỎA / THỦY)
  const isElemental = (damageElement === "FIRE" || damageElement === "WATER");
  const wasTargetChained = Boolean(target.isChained);
  if (isElemental && wasTargetChained) {
    target.isChained = false; // Gỡ xích người chịu đòn đầu tiên
  }
  if (isElemental && wasTargetChained && finalDamage > 0) {
    state.pendingChainSpread = {
      sourceSeat: targetSeat,
      damage: finalDamage,
      element: damageElement,
      targetSeats: getSeatsAfter(state, targetSeat)
        .map((seat) => state.players.find((player) => player.seat === seat))
        .filter((player) => isLivingPlayer(player) && player.isChained)
        .map((player) => player.seat),
    };
  }

  if (target.hp <= 0) {
    if (heroHasSkill(target, "HICH_NGHIA")) {
      drawCards(state, target.seat, 3, true);
      recordAction(state, {
        type: "USE_SKILL",
        casterSeat: target.seat,
        description: `✨ <b>${target.generalName}</b> kích hoạt <color=#FFD700><b>[Hịch Nghĩa]</b></color>: Rơi vào trạng thái Cận Tử, lập tức rút 3 lá bài!`
      });
    }

    // Máu có thể âm khi sát thương lớn hơn máu hiện tại
    // target.hp = 0; // KHÔNG SET VỀ 0 NẾU ÂM! Để dành cho Bánh Chưng cộng dồn
    
    // Thứ tự hỏi cứu: Người trong lượt trước (state.turnSeat), sau đó đến người kế bên phải (ngược chiều kim đồng hồ) cho đến hết vòng
    const startSeat = state.turnSeat || 1;
    const askers = [];
    for (const s of getSeatsAfter(state, startSeat, true)) {
      const p = state.players.find(x => x.seat === s);
      if (p && (isLivingPlayer(p) || s === targetSeat)) {
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
    state.timerStartAt = Date.now();
      recordAction(state, {
        type: "NEAR_DEATH",
        targetSeat,
        casterSeat: attackerSeat,
         damage: finalDamage,
         armorEffect,
         armorChargesRemaining,
         armorExpired,
         description: `🆘 <b>${target.generalName}</b> trúng đòn bị mất ${finalDamage} máu và rơi vào trạng thái Hấp Hối (${target.hp} Máu; cần ${Math.max(1, 1 - target.hp)} lá cứu)! Đang chờ Ghế ${firstAsker} cứu viện (40s)...`
      });
       return { finalDamage, enteredNearDeath: true, armorEffect, armorChargesRemaining, armorExpired };
    } else {
      // Không còn ai có thể cứu
      target.hp = 0;
      state.phase = "PLAY";
      state.waitingTargetSeat = 0;
      state.waitingTimer = 0;
      const deathSummary = finalizePlayerDeath(state, target);
      recordAction(state, {
        type: "PLAYER_DIED",
        casterSeat: attackerSeat,
        targetSeat,
        armorEffect,
        armorChargesRemaining,
        armorExpired,
        description: `☠️ <b>${target.generalName}</b> đã tử trận!${deathSummary}`
      });
      checkGameOver(state);
      if (state.status === "FINISHED") state.pendingChainSpread = null;
      const chainResult = continueChainSpread(state);
      if (state.phase === "AWAIT_NEAR_DEATH") return chainResult;
      return { finalDamage, enteredNearDeath: false, armorEffect, armorChargesRemaining, armorExpired };
    }
  }

  state.phase = "PLAY";
  state.waitingTargetSeat = 0;
  state.waitingTimer = 0;
  if (!options.skipRecordDamageTaken) {
    recordAction(state, {
      type: "DAMAGE_TAKEN",
      casterSeat: attackerSeat,
      targetSeat,
      damage: finalDamage,
      element: damageElement,
      armorEffect,
      armorChargesRemaining,
      armorExpired,
      description: `💥 <b>${target.generalName}</b> bị mất ${finalDamage} đóa sen máu (${target.hp}/${target.maxHp})!`
    });
  }

  if (finalDamage > 0 && heroHasSkill(target, "UAT_KHI")) {
    state.uatKhiQueue = state.uatKhiQueue || [];
    if (!state.uatKhiQueue.some((pending) => pending.seat === target.seat)) {
      state.uatKhiQueue.push({ seat: target.seat });
      recordAction(state, {
        type: "UAT_KHI_PROMPT",
        casterSeat: target.seat,
        description: `💢 ${target.generalName} có thể phát động [Uất Khí]: chọn 1 người khác rút 1 lá, hoặc từ chối.`
      });
    }
  }

  if (finalDamage > 0 && isDirectSlashDamage && attackerSeat > 0) {
    state.khoiBinhQueue = state.khoiBinhQueue || [];
    for (const player of state.players) {
      if (player.seat !== attackerSeat && isLivingPlayer(player) && heroHasSkill(player, "KHOI_BINH")
          && !state.khoiBinhQueue.some((pending) => pending.seat === player.seat && pending.sourceSeat === attackerSeat)) {
        state.khoiBinhQueue.push({ seat: player.seat, sourceSeat: attackerSeat });
      }
    }
  }

  if (startNextUatKhiPrompt(state) || startNextKhoiBinhPrompt(state)) {
    return { finalDamage, enteredNearDeath: false, armorEffect, armorChargesRemaining, armorExpired };
  }

  if (state.pendingChainSpread) {
    const chainResult = continueChainSpread(state);
    if (["AWAIT_NEAR_DEATH", "AWAIT_UAT_KHI", "AWAIT_KHOI_BINH"].includes(state.phase)) return chainResult;
  }
  return { finalDamage, enteredNearDeath: false, armorEffect, armorChargesRemaining, armorExpired };
}

/**
 * Kết thúc lượt đánh (Chuyển sang bỏ bài nếu thừa, hoặc rút bài cho người kế tiếp)
 */
export function handleEndTurn(state, casterSeat) {
  if (state.status === "FINISHED") return { error: "Trận đấu đã kết thúc" };
  casterSeat = Number(casterSeat);
  const isPlayPhase = (state.phase === "PLAY" && state.turnSeat === casterSeat);
  const isDiscardPhase = (state.phase === "DISCARD" && (state.waitingTargetSeat === casterSeat || state.turnSeat === casterSeat));
  if (!isPlayPhase && !isDiscardPhase) {
    return { error: "Chưa tới lượt hoặc đang trong pha phản ứng" };
  }

  const caster = state.players.find(x => x.seat === casterSeat);
  if (!caster || caster.hp <= 0) return { error: "Người chơi không hợp lệ" };
  caster.isWineBuffActive = false;
  state.isWineBuffActive = false;
  if (state.drumReveal?.viewerSeat === casterSeat) state.drumReveal = null;

  if (isPlayPhase && heroHasSkill(caster, "LAP_LANG") && !state.turnDamageDealt && !caster.usedSkills?.LapLang) {
    if (!caster.usedSkills) caster.usedSkills = {};
    caster.usedSkills.LapLang = true;
    drawCards(state, casterSeat, 2);
    recordAction(state, {
      type: "LAP_LANG_DRAW",
      casterSeat,
      description: `🏘️ <b>${caster.generalName}</b> không gây sát thương trong lượt, kích hoạt [Lập Làng] rút 2 lá bài.`
    });
  }

  // Không được kết thúc lượt khi vẫn còn bài thừa. Chỉ DISCARD_CARDS mới được
  // xác nhận số bài đã bỏ và chuyển lượt sau khi số bài trên tay hợp lệ.
  if (isDiscardPhase) {
    return { error: "Cần bỏ đủ bài thừa trước khi kết thúc lượt" };
  }

  // Nếu đang ở PLAY phase: Kiểm tra bài thừa so với máu
  const excess = caster.hand.length - caster.hp;
  if (excess > 0 && caster.hp > 0) {
    state.phase = "DISCARD";
    state.waitingTargetSeat = casterSeat;
    state.waitingReactionType = "DISCARD";
    state.waitingTimer = 40;
    state.timerStartAt = Date.now();
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
  seat = Number(seat);
  const isDiscardPhase = (state.phase === "DISCARD" && (state.waitingTargetSeat === seat || state.turnSeat === seat));
  const isPlayPhase = (state.phase === "PLAY" && state.turnSeat === seat);
  if (!isDiscardPhase && !isPlayPhase) {
    return { error: "Không trong giai đoạn bỏ bài" };
  }

  const p = state.players.find(x => x.seat === seat);
  if (!p) return { error: "Người chơi không hợp lệ" };

  const excess = Math.max(0, p.hand.length - p.hp);
  const requestedIds = Array.isArray(cardIds) ? [...new Set(cardIds.filter(Boolean))] : [];
  if (requestedIds.length > excess) {
    return { error: `Chỉ được bỏ tối đa ${excess} lá bài thừa` };
  }

  for (const id of requestedIds) {
    const idx = p.hand.findIndex(c => c.id === id || c.name === id);
    if (idx >= 0) {
      const discarded = p.hand.splice(idx, 1)[0];
      discardCard(state, discarded, false);
    }
  }

  recordAction(state, {
    type: "DISCARD_CARDS",
    casterSeat: seat,
    discardedCount: requestedIds.length,
    description: p.hand.length > p.hp
      ? `🗑️ <b>${p.generalName}</b> đã bỏ ${requestedIds.length} lá và còn phải bỏ ${p.hand.length - p.hp} lá bài thừa.`
      : `🗑️ <b>${p.generalName}</b> đã bỏ bài thừa và hoàn thành lượt.`
  });

  if (p.hand.length > p.hp) {
    state.phase = "DISCARD";
    state.waitingTargetSeat = seat;
    state.waitingTimer = 40;
    state.timerStartAt = Date.now();
    refreshLastDelta(state);
    return { success: true, state };
  }

  return advanceTurn(state);
}

function findNextJudgementRecipient(state, currentSeat, subType) {
  for (const seat of getSeatsAfter(state, currentSeat)) {
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
  const judgeCard = drawJudgementCard(state) || { suit: "Heart", rank: 10, name: "Bài Phán Xét", id: "JUDGECARD" };

  let isHit = false;
  let triggered = false;
  let actionType = "";
  let description = "";
  let nextRecipient = 0;

  if (judgementCard.subType === CARD_SUBTYPES.DAI_HONG_THUY) {
    isHit = judgeCard.suit === "Spade" && judgeCard.rank >= 2 && judgeCard.rank <= 9;
    actionType = isHit ? "DAI_HONG_THUY_HIT" : "DAI_HONG_THUY_PASSED";
    const recipient = !isHit ? findNextJudgementRecipient(state, targetSeat, CARD_SUBTYPES.DAI_HONG_THUY) : null;
    nextRecipient = recipient ? recipient.seat : 0;
    description = isHit
      ? "🌊🌊🌊 [Đại Hồng Thủy] phán xét " + judgeCard.suit + " " + judgeCard.rank + ": <b>" + target.generalName + "</b> chuẩn bị chịu 3 sát thương Thủy!"
      : (recipient ? "🌊 [Đại Hồng Thủy] phán xét " + judgeCard.suit + " " + judgeCard.rank + " không trúng, chuẩn bị chuyển sang <b>" + recipient.generalName + "</b>." : "🌊 [Đại Hồng Thủy] không trúng và không còn vùng phán xét hợp lệ, lá bài bị bỏ.");
  } else if (judgementCard.subType === CARD_SUBTYPES.SUPPLY_SHORTAGE) {
    triggered = judgeCard.suit !== "Club";
    actionType = triggered ? "SUPPLY_SHORTAGE_TRIGGERED" : "SUPPLY_SHORTAGE_PASSED";
    description = triggered ? "🌾❌ <b>" + target.generalName + "</b> phán xét " + judgeCard.suit + " " + judgeCard.rank + ", chuẩn bị bỏ qua Giai đoạn Rút bài." : "🌾✅ <b>" + target.generalName + "</b> phán xét ra Chuồn, hóa giải Cắt Đường Lương.";
  } else if (judgementCard.subType === CARD_SUBTYPES.ACEDIA) {
    triggered = judgeCard.suit !== "Heart";
    actionType = triggered ? "ACEDIA_TRIGGERED" : "ACEDIA_PASSED";
    description = triggered ? "🕸️❌ <b>" + target.generalName + "</b> phán xét " + judgeCard.suit + " " + judgeCard.rank + ", chuẩn bị bỏ qua Giai đoạn Ra bài." : "🕸️✅ <b>" + target.generalName + "</b> phán xét ra Cơ, thoát khỏi Sa Bẫy.";
  }

  state.phase = "AWAIT_JUDGEMENT";
  state.waitingTargetSeat = 0;
  state.waitingTimer = 3;
  state.timerStartAt = Date.now();
  state.pendingJudgement = {
    actionType,
    targetSeat,
    judgeCardId: judgeCard.id,
    judgementCardId: judgementCard.id,
    judgementCardType: judgementCard.subType,
    isHit,
    triggered,
    nextRecipient
  };

  recordAction(state, {
    type: actionType,
    targetSeat,
    cardId: judgeCard.id,
    judgeCard: cardSummary(judgeCard),
    element: actionType === "DAI_HONG_THUY_HIT" ? "WATER" : "NORMAL",
    description
  });
}

function applyPendingJudgement(state) {
  const pending = state.pendingJudgement;
  if (!pending) {
     return continueTurnStart(state);
  }
  const { actionType, targetSeat, judgementCardId, judgementCardType, isHit, triggered, nextRecipient } = pending;
  const target = state.players.find(p => p.seat === targetSeat);
  state.pendingJudgement = null;
  state.phase = "PLAY";
  state.waitingTimer = 0;
  
  if (!target) return continueTurnStart(state);

  const judgementCard = target.judgements?.find(c => c.id === judgementCardId);
  if (judgementCard) {
      target.judgements = target.judgements.filter(c => c.id !== judgementCardId);
  }
  
  const cardObj = judgementCard || { id: judgementCardId, subType: judgementCardType };

  if (judgementCardType === CARD_SUBTYPES.DAI_HONG_THUY) {
    if (isHit) {
      discardCard(state, cardObj);
      applyDamageToPlayer(state, targetSeat, 3, "Đại Hồng Thủy", "WATER");
      if (state.phase === "AWAIT_NEAR_DEATH") return;
    } else {
      if (nextRecipient > 0) {
        const recipient = state.players.find(p => p.seat === nextRecipient);
        if (recipient) {
           recipient.judgements = recipient.judgements || [];
           recipient.judgements.push(cardObj);
        } else {
           discardCard(state, cardObj);
        }
      } else {
        discardCard(state, cardObj);
      }
    }
  } else {
    discardCard(state, cardObj);
    if (judgementCardType === CARD_SUBTYPES.SUPPLY_SHORTAGE && triggered) {
      if (state.turnStart) state.turnStart.skipDraw = true;
    } else if (judgementCardType === CARD_SUBTYPES.ACEDIA && triggered) {
      if (state.turnStart) state.turnStart.skipPlay = true;
    }
  }

  return continueTurnStart(state);
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
  const firstTienPhongTurn = heroHasSkill(player, "TIEN_PHONG") && Math.max(0, Number(player.turnsTaken) || 0) === 0;
  player.turnsTaken = Math.max(0, Number(player.turnsTaken) || 0) + 1;
  if (!skipDraw) drawCards(state, player.seat, firstTienPhongTurn ? 4 : 2);
  if (firstTienPhongTurn) {
    recordAction(state, {
      type: "TIEN_PHONG_DRAW",
      casterSeat: player.seat,
      description: `⚔️ ${player.generalName} kích hoạt [Tiên Phong], rút thêm 2 lá trong lượt đầu tiên.`
    });
  }

  if (skipPlay) {
    const excess = player.hand.length - player.hp;
    if (excess > 0 && player.hp > 0) {
      state.phase = "DISCARD";
      state.waitingTargetSeat = player.seat;
      state.waitingReactionType = "DISCARD";
      state.waitingTimer = 40;
    state.timerStartAt = Date.now();
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
    description: `👉 Lượt của <b>${player.generalName}</b>! ${skipDraw ? '🌾 Bị Cắt Đường Lương tước quyền rút bài' : 'Đã rút 2 lá bài'} (40s).`
  });
  checkGameOver(state);
  return { success: true, state };
}

/**
 * Chuyển sang lượt kế tiếp; mọi phán xét và rút bài đều do server tiếp tục điều phối.
 */
function advanceTurn(state) {
  const previousSeat = state.turnSeat;
  const nextSeat = getNextAliveSeat(state, state.turnSeat);
  state.turnSeat = nextSeat;
  state.hoPhuTransfers = (state.hoPhuTransfers || []).filter((transfer) => transfer.ownerSeat !== nextSeat);
  state.turnTimer = 40;
  state.slashesUsedThisTurn = 0;
  state.turnDamageDealt = false;
  state.isWineBuffActive = false;
  const previousPlayer = state.players.find((player) => player.seat === previousSeat);
  if (previousPlayer) {
    previousPlayer.isWineBuffActive = false;
    previousPlayer.usedSkills = {};
    if (previousPlayer.sucSoiTurnsRemaining > 0) previousPlayer.sucSoiTurnsRemaining--;
  }
  state.pendingAfterNearDeath = null;
  if (state.drumReveal?.targetSeat === previousSeat) state.drumReveal = null;
  resetWaitingState(state);

  const nextPlayer = state.players.find((player) => player.seat === nextSeat);
  if (!nextPlayer || nextPlayer.hp <= 0) {
    checkGameOver(state);
    refreshLastDelta(state);
    return { success: true, state };
  }
  state.turnStart = {
    seat: nextSeat,
    judgementCards: [...(nextPlayer.judgements || [])]
      .filter((card) => card.subType !== CARD_SUBTYPES.BAI_COC_BACH_DANG)
      .sort((left, right) => {
      const priority = {
        [CARD_SUBTYPES.DAI_HONG_THUY]: 0,
        [CARD_SUBTYPES.SUPPLY_SHORTAGE]: 1,
        [CARD_SUBTYPES.ACEDIA]: 2
      };
      return (priority[left.subType] ?? 99) - (priority[right.subType] ?? 99);
      }),
    judgementIndex: 0,
    skipDraw: false,
    skipPlay: false
  };
  // Quét từng lá phán xét theo thứ tự ưu tiên; mỗi lá được gỡ khỏi judgements khi phán xét xong
  return continueTurnStart(state);
}

/**
 * Kiểm tra xem trận đấu đã ngã ngũ chưa (1 trong 2 đội bị hạ gục hết)
 * Lưu ý: Người đang trong Hấp Hối (hp=0 nhưng chưa tử trận) không được tính là đã chết
 */
function checkGameOver(state) {
  // Nếu đang trong pha Hấp Hối, chưa kết thúc được
  if (state.phase === "AWAIT_NEAR_DEATH") return;

  const modeRules = getModeRulesForState(state);
  const aliveTeams = new Map();
  for (const player of state.players) {
    if (!isLivingPlayer(player)) continue;
    const teamId = player.teamId || modeRules.teamForSeat(player.seat);
    if (!aliveTeams.has(teamId)) aliveTeams.set(teamId, player);
  }

  if (aliveTeams.size <= 1) {
    state.status = "FINISHED";
    const [winningTeamId, winner] = aliveTeams.entries().next().value || ["", null];
    const winningTeam = modeRules.victory === "LAST_PLAYER_STANDING"
      ? (winner?.generalName || "Không có người sống sót")
      : (modeRules.teamLabel(winningTeamId) || "Không có đội chiến thắng");
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
  aiSeat = Number(aiSeat);
  const ai = state.players.find(x => x.seat === aiSeat);
  if (!ai || ai.hp <= 0) return { error: "Người chơi không hợp lệ" };
  if (state.turnSeat !== aiSeat) return { error: "Không phải lượt của AI này" };



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

  const enemies = state.players.filter(x => !areTeammatesInState(state, x.seat, aiSeat) && x.hp > 0);

  // D. Cẩm nang trì hoãn và Đại Hồng Thủy
  const delayed = ai.hand.find((card) => card.subType === CARD_SUBTYPES.DAI_HONG_THUY);
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

  const borrowSword = ai.hand.find((card) => card.subType === CARD_SUBTYPES.MUON_GUOM_DIET_DICH);
  const weaponOwner = borrowSword
    ? state.players.find((player) => player.seat !== aiSeat && isLivingPlayer(player)
      && player.equipments?.some((equipment) => equipment.subType === CARD_SUBTYPES.WEAPON)
      && state.players.some((target) => target.seat !== player.seat && isLivingPlayer(target)
        && hasWeaponRange(state, player.seat, target.seat)))
    : null;
  const forcedTarget = weaponOwner
    ? state.players.find((player) => player.seat !== weaponOwner.seat && isLivingPlayer(player)
      && hasWeaponRange(state, weaponOwner.seat, player.seat))
    : null;
  if (borrowSword && weaponOwner && forcedTarget) {
    return handlePlayCard(state, aiSeat, borrowSword.id, weaponOwner.seat, { targetSeat2: forcedTarget.seat });
  }

  // E. Uống rượu trước khi Trảm nếu có cả Rượu và Trảm
  const wine = ai.hand.find(c => c.subType === CARD_SUBTYPES.WINE);
  const slash = ai.hand.find(c => isSlash(c));
  const slashTarget = enemies.find((enemy) => hasWeaponRange(state, aiSeat, enemy.seat)) || null;

  if (wine && slash && !ai.isWineBuffActive && slashTarget) {
    return handlePlayCard(state, aiSeat, wine.id, aiSeat);
  }

  // F. Huyết Chiến nếu có mục tiêu hợp lệ
  const duel = ai.hand.find((card) => card.subType === CARD_SUBTYPES.DUEL);
  const duelTarget = enemies.find((enemy) => enemy.hp > 0) || null;
  if (duel && duelTarget) {
    return handlePlayCard(state, aiSeat, duel.id, duelTarget.seat);
  }

  // G. Đánh Trảm nếu chưa vượt giới hạn
  const hasZhuge = hasEquippedZhuge(ai);
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
  // Ưu tiên cứu đồng đội khỏi các lá Phán Xét (Trì hoãn)
  const allies = state.players.filter(x => areTeammatesInState(state, x.seat, aiSeat) && x.hp > 0);
  const allyNeedHelp = allies.find((ally) => (ally.judgements && ally.judgements.length > 0));
  
  const snatch = ai.hand.find((card) => card.subType === CARD_SUBTYPES.SNATCH);
  const dismantle = ai.hand.find((card) => card.subType === CARD_SUBTYPES.DISMANTLE);

  if (allyNeedHelp) {
    if (dismantle) {
      return handlePlayCard(state, aiSeat, dismantle.id, allyNeedHelp.seat);
    }
    if (snatch && getDistance(state, aiSeat, allyNeedHelp.seat) <= 1) {
      return handlePlayCard(state, aiSeat, snatch.id, allyNeedHelp.seat);
    }
  }

  // Nếu không có đồng đội cần cứu, dùng để phá bài kẻ địch (Chỉ Hand và Equipment)
  const snatchTarget = enemies.find((enemy) =>
    getDistance(state, aiSeat, enemy.seat) <= 1 && buildTargetCardOptions(state, enemy.seat, false).length > 0
  ) || null;
  if (snatch && snatchTarget) {
    return handlePlayCard(state, aiSeat, snatch.id, snatchTarget.seat);
  }

  const dismantleTarget = enemies.find((enemy) => buildTargetCardOptions(state, enemy.seat, false).length > 0) || null;
  if (dismantle && dismantleTarget) {
    return handlePlayCard(state, aiSeat, dismantle.id, dismantleTarget.seat);
  }

  // H. Không còn bài muốn đánh -> Kết thúc lượt
  return handleEndTurn(state, aiSeat);
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
    const hasThuanThien = !!getEquippedWeapon(caster, "Thuận Thiên");
    const hasKhienMay = !hasThuanThien && !!getEquippedKhienMay(ai);
    const alreadyFailed = state.activeCard?.khienMayFailedSeats?.includes(aiSeat);
    if (hasKhienMay && !alreadyFailed) {
      return handleRespondAction(state, aiSeat, true, "KHIEN_MAY");
    }
    const cannon = getEquippedWeapon(caster, "Súng Thần Công");
    const dodge = ai.hand.find(c => isDodge(c)
      && (!cannon || !sameCardColor(c.suit, state.activeCard?.suit)));
    if (dodge) {
      return handleRespondAction(state, aiSeat, true, dodge.id);
    } else {
      return handleRespondAction(state, aiSeat, false, null);
    }
  }

  if (state.phase === "AWAIT_BORROW_SWORD" && state.waitingTargetSeat === aiSeat) {
    const forcedTargetSeat = Number(state.activeCard?.forcedTargetSeat) || 0;
    const weapon = ai.equipments?.find((equipment) => equipment.id === state.activeCard?.weaponId);
    const slash = ai.hand.find((card) => isSlash(card)
      && weapon && forcedTargetSeat > 0 && hasWeaponRange(state, aiSeat, forcedTargetSeat));
    return slash
      ? handleRespondAction(state, aiSeat, true, slash.id)
      : handleRespondAction(state, aiSeat, false, null);
  }

  if (state.phase === "AWAIT_AOE" && state.waitingTargetSeat === aiSeat) {
    const reqType = state.waitingReactionType;
    const isArrow = reqType === "DODGE" || state.activeCard?.reqType === "DODGE";
    const hasKhienMay = !!getEquippedKhienMay(ai);
    const alreadyFailed = state.activeCard?.khienMayFailedSeats?.includes(aiSeat);
    if (isArrow && hasKhienMay && !alreadyFailed) {
      return handleRespondAction(state, aiSeat, true, "KHIEN_MAY");
    }
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
      const isCasterAlly = caster && areTeammatesInState(state, caster.seat, aiSeat);
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

  if (state.phase === "AWAIT_HICH_CASTER_DISCARD" && state.waitingTargetSeat === aiSeat) {
    const card = ai.hand[0];
    return card ? handleRespondAction(state, aiSeat, true, card.id) : handleRespondAction(state, aiSeat, false, null);
  }

  if (state.phase === "AWAIT_HICH_TARGET_DISCARD" && state.waitingTargetSeat === aiSeat) {
    const card = ai.hand[0];
    return card ? handleRespondAction(state, aiSeat, true, card.id) : handleRespondAction(state, aiSeat, false, null);
  }

  if (state.phase === "AWAIT_THUY_TRIEU_RUT_GIVE" && state.waitingTargetSeat === aiSeat) {
    const card = ai.hand[0];
    return card ? handleRespondAction(state, aiSeat, true, card.id) : { error: "Không còn lá để đưa cho Thủy Triều Rút" };
  }

  if (state.phase === "AWAIT_DRUM_CHOICE" && state.waitingTargetSeat === aiSeat) {
    const card = ai.hand[0];
    return card ? handleRespondAction(state, aiSeat, true, card.id) : handleRespondAction(state, aiSeat, false, null);
  }

  if (state.phase === "AWAIT_HARVEST" && state.waitingTargetSeat === aiSeat) {
    const pickedCard = state.harvestPool && state.harvestPool.length > 0 ? state.harvestPool[0] : null;
    return handleRespondAction(state, aiSeat, true, pickedCard ? pickedCard.id : null);
  }

  if (state.phase === "DISCARD" && state.waitingTargetSeat === aiSeat) {
    const excess = ai.hand.length - ai.hp;
    const ids = excess > 0 ? ai.hand.slice(0, excess).map((card) => card.id) : [];
    return handleDiscardCards(state, aiSeat, ids);
  }

  return { error: "Không có phản ứng nào đang chờ AI này" };
}

/**
 * Nhịp đếm thời gian và tự động hành động trên Server (Authoritative Server Loop)
 * Chạy mỗi giây (1000ms) trên Server In-Memory
 */
export function tickGameState(state, connectedSeats = null) {
  if (!state || state.status === "FINISHED") return { changed: false, important: false };
  let changed = false;
  let important = false;
  const startingVersion = state.version || 0;

  if (!state.timerStartAt) {
      state.timerStartAt = Date.now();
      changed = true;
  }
  const elapsed = Math.floor((Date.now() - state.timerStartAt) / 1000);
  const newTimer = Math.max(0, 40 - elapsed);

  // Giai đoạn chờ lật bài phán xét (AWAIT_JUDGEMENT)
  if (state.phase === "AWAIT_JUDGEMENT") {
    if (elapsed >= 3) {
      applyPendingJudgement(state);
      important = true;
      state.timerStartAt = Date.now();
      return { changed: true, important };
    }
    return { changed, important };
  }
  
  if (state.waitingTargetSeat > 0) {
    if (state.waitingTimer !== newTimer) {
       state.waitingTimer = newTimer;
       changed = true;
       important = true; // Đồng bộ mỗi giây cho cả 4 người chơi
    }
    const waitingSeat = state.waitingTargetSeat;
    const waitingPlayer = state.players.find(p => p.seat === waitingSeat);

    
    
    if (elapsed >= 40) {
      // Hết 40s phản ứng: Cho AI phản ứng giúp người chơi (chống mất máu / tránh chết oan)
      recordAction(state, {
        type: "TIMEOUT_AI_REACTION",
        casterSeat: waitingSeat,
        description: `⏰ <b>${waitingPlayer ? waitingPlayer.generalName : 'Người chơi'}</b> hết 40s: AI tự động phản ứng hỗ trợ!`
      });
      const aiRes = handleAIReaction(state, waitingSeat);
      if (!aiRes || aiRes.error) {
        if (state.phase === "AWAIT_SLASH_DEFENSE") {
          handleRespondAction(state, waitingSeat, false, null);
        } else if (state.phase === "AWAIT_BORROW_SWORD") {
          handleRespondAction(state, waitingSeat, false, null);
        } else if (state.phase === "AWAIT_NULLIFY") {
          handleRespondAction(state, waitingSeat, false, null);
        } else if (state.phase === "AWAIT_TARGET_CARD") {
          handleRespondAction(state, waitingSeat, true, null, null);
        } else if (state.phase === "AWAIT_HICH_CASTER_DISCARD" || state.phase === "AWAIT_HICH_TARGET_DISCARD"
          || state.phase === "AWAIT_DRUM_CHOICE") {
          handleRespondAction(state, waitingSeat, false, null);
        } else if (state.phase === "AWAIT_THUY_TRIEU_RUT_GIVE") {
          const card = waitingPlayer?.hand?.[0];
          if (card) handleRespondAction(state, waitingSeat, true, card.id);
          else {
            state.thuyTrieuRutSelection = null;
            resetWaitingState(state);
          }
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
        } else if (state.phase === "AWAIT_UAT_KHI") {
          handleUseSkill(state, waitingSeat, "Uất Khí", 0);
        } else if (state.phase === "AWAIT_KHOI_BINH") {
          handleRespondAction(state, waitingSeat, false, null);
        } else if (state.phase === "DISCARD") {
          const discardCount = Math.max(0, (waitingPlayer?.hand?.length || 0) - (waitingPlayer?.hp || 0));
          const discardIds = (waitingPlayer?.hand || []).slice(0, discardCount).map((card) => card.id);
          handleDiscardCards(state, waitingSeat, discardIds);
        }
      }
      important = true;
      state.timerStartAt = Date.now();
      return { changed: true, important };
    }

    const isAISlot = waitingPlayer && waitingPlayer.isAI === true;
    // Uất Khí is an exclusive 40s choice. AI must not resolve it early.
    const canAIReact = !["AWAIT_UAT_KHI", "AWAIT_KHOI_BINH"].includes(state.phase)
      && isAISlot
      && (waitingPlayer.hp > 0 || state.phase === "AWAIT_NEAR_DEATH");
    if (canAIReact && elapsed >= 2 && elapsed < 40) {
        const res = handleAIReaction(state, waitingSeat);
        if (res && res.error) {
            console.log("[AI ERROR]", res.error, state.phase, waitingSeat);
            return { changed: false, important: false };
        }
        important = true;
        state.timerStartAt = Date.now();
        return { changed: true, important };
      }
  }
  else if (state.phase === "PLAY" && state.turnSeat > 0) {
    if (state.turnTimer !== newTimer) {
       state.turnTimer = newTimer;
       changed = true;
       important = true; // Đồng bộ mỗi giây cho cả 4 người chơi
    }
    const turnPlayer = state.players.find(p => p.seat === state.turnSeat);

    if (elapsed >= 40) {
      if (!turnPlayer || turnPlayer.hp <= 0) {
        advanceTurn(state);
      } else {
        // Hết 40s ra bài: AI hành động giúp người chơi
        recordAction(state, {
          type: "TIMEOUT_AI_ASSIST",
          casterSeat: state.turnSeat,
          description: `⏰ <b>${turnPlayer.generalName}</b> hết 40s: AI tự động ra bài hỗ trợ!`
        });
        const res = handleAIStep(state, state.turnSeat);
        if (!res || res.error) {
          handleEndTurn(state, state.turnSeat);
        }
      }
      important = true;
      state.timerStartAt = Date.now();
      return { changed: true, important };
    }

    const isAITurn = turnPlayer && (turnPlayer.isAI || (Array.isArray(connectedSeats) && !connectedSeats.includes(state.turnSeat)));
    if (isAITurn && turnPlayer.hp > 0 && elapsed >= 2 && elapsed < 40) {
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

function sanitizePrivateNullifyAction(action) {
  if (!action || ![
    "NULLIFY_START",
    "NULLIFY_PASS",
    "NULLIFY_PLAYED",
    "NULLIFY_SUCCEEDED"
  ].includes(action.type)) {
    return action;
  }

  return {
    ...action,
    casterSeat: 0,
    description: action.type === "NULLIFY_START"
      ? "📜 Đang hỏi một người chơi có muốn dùng Diệu Kế Phá Mưu không..."
      : action.type === "NULLIFY_PASS"
        ? "📜 Người chơi được hỏi đã bỏ qua Diệu Kế Phá Mưu. Đang hỏi người tiếp theo..."
        : action.type === "NULLIFY_PLAYED"
          ? "📜 Một người chơi đã dùng Diệu Kế Phá Mưu. Đang kiểm tra phản ứng tiếp theo..."
          : "📜 Diệu Kế Phá Mưu đã hoàn tất xử lý mưu kế."
  };
}

function sanitizeNullifyChainForClient(chain) {
  if (!chain) return null;
  const { querySeats, currentIdx, whoUsedLast, ...safeChain } = chain;
  return safeChain;
}

function sanitizeDeltaForClient(delta, requestingSeat) {
  if (!delta) return null;
  return sanitizePrivateNullifyAction({
    ...delta,
    targetCardSelection: sanitizeTargetCardSelection(delta.targetCardSelection, requestingSeat),
    drumReveal: delta.drumReveal?.viewerSeat === Number(requestingSeat) ? delta.drumReveal : null
  });
}

export function sanitizeGameStateForClient(state, requestingSeat = 0) {
  if (!state) return null;
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
    waitingTargetSeat: state.phase === "AWAIT_NULLIFY" && viewerSeat !== state.waitingTargetSeat
      ? 0
      : state.waitingTargetSeat,
    waitingReactionType: state.waitingReactionType,
    waitingTimer: (state.waitingTargetSeat > 0) ? remaining : 0,
    nearDeathVictimSeat: state.nearDeathVictimSeat,
    nearDeathAskerQueue: state.nearDeathAskerQueue || [],
    aoeVictimsQueue: state.aoeVictimsQueue || [],
    harvestPickers: state.harvestPickers || [],
    slashesUsedThisTurn: state.slashesUsedThisTurn || 0,
    duelCasterSeat: state.duelCasterSeat || 0,
    duelTargetSeat: state.duelTargetSeat || 0,
    activeCard: state.phase === "AWAIT_NULLIFY" && state.activeCard
      ? Object.fromEntries(Object.entries(state.activeCard).filter(([key]) => key !== "nullifyBySeat"))
      : state.activeCard,
    harvestPool: (state.harvestPool || []).map(c => ({
      id: c.id,
      name: getCardName(c),
      suit: c.suit,
      rank: c.rank,
      category: c.category,
      subType: c.subType,
      desc: c.desc || ""
    })),
    harvestDisplayPool: (state.harvestDisplayPool || state.harvestPool || []).map(c => ({
      id: c.id,
      name: getCardName(c),
      suit: c.suit,
      rank: c.rank,
      category: c.category,
      subType: c.subType,
      desc: c.desc || ""
    })),
    harvestPickedCardIds: state.harvestPickedCardIds || [],
    nullifyChain: sanitizeNullifyChainForClient(state.nullifyChain),
    pendingJudgement: state.pendingJudgement || null,
    targetCardSelection: sanitizeTargetCardSelection(state.targetCardSelection, requestingSeat),
    hichSelection: state.hichSelection || null,
    thuyTrieuRutSelection: state.thuyTrieuRutSelection || null,
    uatKhiQueue: state.uatKhiQueue || [],
    drumSelection: state.drumSelection || null,
      drumReveal: state.drumReveal?.viewerSeat === viewerSeat ? {
        viewerSeat: state.drumReveal.viewerSeat,
        targetSeat: state.drumReveal.targetSeat,
        cards: (state.drumReveal.cards || []).map((card) => ({
          id: card.id,
          name: card.name,
          suit: card.suit,
          rank: card.rank,
          category: card.category,
          subType: card.subType,
          desc: card.desc || ""
        }))
      } : null,
    lastAction: sanitizePrivateNullifyAction(state.lastAction),
    actionHistory: (state.actionHistory || []).map(sanitizePrivateNullifyAction),
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
      isAlly: p.isAlly === true,
      isAI: p.isAI,
      isAlive: p.isAlive !== false,
      sucSoiTurnsRemaining: Math.max(0, Number(p.sucSoiTurnsRemaining) || 0),
      isWineBuffActive: !!p.isWineBuffActive,
      isChained: !!p.isChained,
      aoBaoCharges: Number.isFinite(Number(p.aoBaoCharges))
        ? Math.max(0, Math.min(2, Number(p.aoBaoCharges)))
        : 2,
      skills: [],
        activeSkillsKeys: p.activeSkills ? Object.keys(p.activeSkills) : [],
        activeSkillsValues: p.activeSkills ? Object.values(p.activeSkills) : [],
        usedSkillsKeys: p.usedSkills ? Object.keys(p.usedSkills) : [],
        usedSkillsValues: p.usedSkills ? Object.values(p.usedSkills) : [],
      handCount: p.hand ? p.hand.length : 0,
      hand: (viewerSeat > 0 && viewerSeat === p.seat)
        ? (p.hand || []).map(c => ({
            id: c.id,
            name: getCardName(c),
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
        name: getCardName(e),
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
        name: getCardName(j),
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












export function handleUseSkill(state, seat, skillId, targetSeat = 0, cardId = null) {
  if (state.status === "FINISHED") return { error: "Trận đấu đã kết thúc" };
  seat = Number(seat);
  const player = state.players.find(p => p.seat === seat);
  if (!player || player.hp <= 0) return { error: "Người chơi không hợp lệ" };

  const norm = String(skillId || "").trim().toLowerCase();

  if (norm.includes("uất khí") || norm.includes("uat khi")) {
    const pendingIndex = (state.uatKhiQueue || []).findIndex((pending) => pending.seat === seat);
    if (state.phase !== "AWAIT_UAT_KHI" || state.waitingTargetSeat !== seat || pendingIndex < 0 || !heroHasSkill(player, "UAT_KHI")) return { error: "Bạn không có Uất Khí đang chờ chọn" };
    state.uatKhiQueue.splice(pendingIndex, 1);
    const target = state.players.find((candidate) => candidate.seat === Number(targetSeat));
    if (!Number(targetSeat)) {
      recordAction(state, { type: "UAT_KHI_DECLINED", casterSeat: seat, description: `💢 ${player.generalName} từ chối phát động [Uất Khí].` });
    } else if (!target || !isLivingPlayer(target) || target.seat === seat) {
      state.uatKhiQueue.splice(pendingIndex, 0, { seat });
      return { error: "Uất Khí cần chọn 1 người khác còn sống" };
    } else {
      drawCards(state, target.seat, 1);
      recordAction(state, { type: "UAT_KHI_DRAW", casterSeat: seat, targetSeat: target.seat, description: `💢 ${player.generalName} phát động [Uất Khí], cho ${target.generalName} rút 1 lá.` });
    }
    if (!startNextUatKhiPrompt(state) && !startNextKhoiBinhPrompt(state)) {
      if (state.pendingChainSpread) continueChainSpread(state);
      if (state.phase !== "AWAIT_NEAR_DEATH" && (state.phase !== "AWAIT_UAT_KHI" || state.uatKhiQueue.length === 0)) resetWaitingState(state);
    }
    refreshLastDelta(state);
    return { success: true, state };
  }

  if (state.phase !== "PLAY" || state.turnSeat !== seat) return { error: "Chỉ được dùng kỹ năng trong lượt của bạn" };

  if (norm.includes("bát nạ") || norm.includes("bat na")) {
    if (!heroHasSkill(player, "BAT_NA")) return { error: "Chỉ Vũ Thị Thục mới có thể dùng Bát Nạ" };
    if (player.usedSkills?.BatNa) return { error: "Bát Nạ chỉ dùng 1 lần mỗi lượt" };
    const cardIndex = player.hand.findIndex((card) => card.id === cardId && card.category === CARD_CATEGORIES.BASIC);
    if (cardIndex < 0) return { error: "Bát Nạ cần chọn 1 lá Bài Cơ Bản trên tay" };
    const sourceCard = player.hand.splice(cardIndex, 1)[0];
    const slash = {
      ...sourceCard,
      name: "Trảm Thường",
      subType: CARD_SUBTYPES.ATTACK_NORMAL,
      category: CARD_CATEGORIES.BASIC
    };
    const target = state.players.find((candidate) => candidate.seat === Number(targetSeat));
    if (!target || !isLivingPlayer(target) || target.seat === seat || !hasWeaponRange(state, seat, target.seat)) {
      player.hand.splice(cardIndex, 0, sourceCard);
      return { error: "Bát Nạ cần chọn 1 mục tiêu khác trong tầm đánh" };
    }
    if (!player.usedSkills) player.usedSkills = {};
    player.usedSkills.BatNa = true;
    recordAction(state, {
      type: "BAT_NA_TRIGGERED",
      casterSeat: seat,
      targetSeat: target.seat,
      cardId: slash.id,
      cardName: slash.name,
      description: `🎭 ${player.generalName} dùng [Bát Nạ], biến 1 Bài Cơ Bản thành Trảm không tính giới hạn lượt.`
    });
    return startSlashResolution(state, slash, seat, target.seat, { countsTowardTurnSlashLimit: false });
  }

  if (norm.includes("hổ phù") || norm.includes("ho phu")) {
    const hoPhu = player.equipments?.find((equipment) => equipment.subType === CARD_SUBTYPES.BRONZE_DRUM && equipment.name?.includes("Hổ Phù"));
    const target = state.players.find((candidate) => candidate.seat === Number(targetSeat));
    if (!hoPhu) return { error: "Bạn chưa trang bị Hổ Phù Trần Triều" };
    if (player.usedSkills?.HoPhu) return { error: "Hổ Phù Trần Triều chỉ dùng 1 lần mỗi lượt" };
    if (!target || !isLivingPlayer(target) || target.seat === seat) return { error: "Cần chọn một người khác còn sống" };
    const cardIndex = player.hand.findIndex((card) => card.id === cardId);
    if (cardIndex < 0) return { error: "Cần chọn một lá trên tay để giao" };
    const givenCard = player.hand.splice(cardIndex, 1)[0];
    target.hand.push(givenCard);
    if (!player.usedSkills) player.usedSkills = {};
    player.usedSkills.HoPhu = true;
    state.hoPhuTransfers = [{ ownerSeat: seat, recipientSeat: target.seat, cardId: givenCard.id }];
    refreshLastDelta(state);
    return { success: true, state };
  }

  if (state.phase === "AWAIT_DOAN_DAO_CHOICE" && state.waitingTargetSeat === aiSeat) {
    return handleRespondAction(state, aiSeat, true, null);
  }

  // 1. Chế Nỏ (Cao Lỗ) - Nếu client gọi action là USE_SKILL thay vì TOGGLE_SKILL
  if (norm.includes("chế nỏ") || norm.includes("che no") || norm === "1") {
    return handleToggleSkill(state, seat, "Chế Nỏ");
  }

  // 2. Triều Dâng (Lê Chân)
  if (norm.includes("triều dâng") || norm.includes("trieu dang") || norm === "4") {
      if (!heroHasSkill(player, "TRIEU_DANG")) return { error: "Chỉ Lê Chân mới có thể dùng Triều Dâng" };
      if (player.usedSkills && (player.usedSkills["Triều Dâng"] || player.usedSkills["trieu_dang"])) {
        return { error: "Kỹ năng Triều Dâng chỉ được dùng 1 lần mỗi lượt" };
      }
      
      const target = state.players.find(p => p.seat === Number(targetSeat));
      if (!target) return { error: "Mục tiêu không hợp lệ" };
      if (target.seat === seat) return { error: "Không thể chọn bản thân" };
      
      if (!target.equipments || target.equipments.length === 0) return { error: "Mục tiêu không có trang bị để hủy" };
      
      if (!player.usedSkills) player.usedSkills = {};
      player.usedSkills["Triều Dâng"] = true;

      // Nếu client đã chỉ định cardId hoặc đối phương chỉ có 1 trang bị -> Hủy trực tiếp ngay lập tức
      let equipToDestroy = null;
      if (cardId) {
        const idx = target.equipments.findIndex(c => c.id === cardId || ("EQUIPMENT:" + c.id) === cardId);
        if (idx >= 0) equipToDestroy = target.equipments.splice(idx, 1)[0];
      }
      if (equipToDestroy) {
        discardCard(state, equipToDestroy);
        recordAction(state, {
          type: "USE_SKILL",
          casterSeat: seat,
          targetSeat: target.seat,
          cardId: equipToDestroy.id,
          cardName: equipToDestroy.name,
          description: `🌊 <b>${player.generalName}</b> dùng [Triều Dâng] phá hủy ${formatCardText(equipToDestroy)} của <b>${target.generalName}</b>!`
        });
        refreshLastDelta(state);
        return { success: true, state };
      }

      const options = target.equipments.map(c => ({
        token: "EQUIPMENT:" + c.id,
        zone: "EQUIPMENT",
        label: "TRANG BỊ",
        card: c
      }));

      state.phase = "AWAIT_TARGET_CARD";
      state.targetCardSelection = {
        chooserSeat: seat,
        targetSeat: target.seat,
        operation: "DESTROY",
        effectType: "TRIEU_DANG",
        options: options
      };
      state.waitingTargetSeat = seat;
      state.waitingReactionType = "TARGET_CARD";
      state.waitingTimer = 40;
      state.timerStartAt = Date.now();

      recordAction(state, {
        type: "USE_SKILL",
        casterSeat: seat,
        targetSeat: target.seat,
        description: "🌊 <b>" + player.generalName + "</b> phát động [Triều Dâng] nhằm vào <b>" + target.generalName + "</b>!"
      });
      refreshLastDelta(state);
      return { success: true, state };
  }

  if (norm.includes("điểm trống") || norm.includes("diem trong") || norm.includes("trống đồng") || norm.includes("trong dong")) {
    const hasDrum = player.equipments?.some((equipment) => equipment.subType === CARD_SUBTYPES.BRONZE_DRUM);
    if (!hasDrum) return { error: "Bạn chưa trang bị Trống Đồng Đông Sơn" };
    const target = state.players.find((candidate) => candidate.seat === Number(targetSeat));
    if (!target || target.seat === seat || !isLivingPlayer(target)) return { error: "Mục tiêu Điểm Trống không hợp lệ" };
    if (!target.hand?.length) return { error: "Mục tiêu không có bài trên tay" };
    state.drumSelection = {
      ownerSeat: seat,
      targetSeat: target.seat
    };
    state.phase = "AWAIT_DRUM_CHOICE";
    state.waitingTargetSeat = target.seat;
    state.waitingReactionType = "DRUM_CHOICE";
    state.waitingTimer = 40;
    state.timerStartAt = Date.now();
    state.activeCard = { cardName: "Điểm Trống", casterSeat: seat, targetSeat: target.seat };
    recordAction(state, {
      type: "DRUM_PROMPT",
      casterSeat: seat,
      targetSeat: target.seat,
      skillId: "Điểm Trống",
      description: `🥁 ${player.generalName} dùng Điểm Trống lên ${target.generalName}. Mục tiêu phải chọn: bỏ 1 lá hoặc lộ toàn bộ bài cho người dùng Trống Đồng xem.`
    });
    return { success: true, state };
  }

  // Mặc định trả về thành công nếu là kỹ năng xem hướng dẫn / bị động
  refreshLastDelta(state);
  return { success: true, state };
}

export function handleToggleSkill(state, seat, skillId) {
  seat = Number(seat);
  const player = state.players.find(p => p.seat === seat);
  if (!player || player.hp <= 0) return { error: "Người chơi không hợp lệ" };

  const norm = String(skillId || "").trim().toLowerCase();
  const canonicalSkill = (norm.includes("chế nỏ") || norm.includes("che no") || norm === "1") ? "Chế Nỏ" : skillId;

  if (!player.activeSkills) player.activeSkills = {};
  player.activeSkills[canonicalSkill] = !player.activeSkills[canonicalSkill];
  const isActive = !!player.activeSkills[canonicalSkill];

  if (canonicalSkill === "Chế Nỏ") {
    if (isActive) {
      if (player.hand) {
        player.hand.forEach(c => {
          if (c.suit === "Spade" && c.subType !== CARD_SUBTYPES.WEAPON) {
            c.originalCardId = c.id;
            c.orig_name = c.name;
            c.orig_subType = c.subType;
            c.orig_category = c.category;
            c.orig_desc = c.desc;
            c.name = "Nỏ Thần Kim Quy";
            c.subType = CARD_SUBTYPES.WEAPON;
            c.category = CARD_CATEGORIES.EQUIPMENT;
            c.desc = "Tầm 1. Không giới hạn số Trảm trong lượt";
          }
        });
      }
    } else {
      if (player.hand) {
        player.hand.forEach(c => {
          if (c.orig_name) {
            c.name = c.orig_name;
            c.subType = c.orig_subType;
            c.category = c.orig_category;
            c.desc = c.orig_desc;
            delete c.orig_name; delete c.orig_subType; delete c.orig_category; delete c.orig_desc;
          }
        });
      }
    }
  }

  recordAction(state, {
    type: "TOGGLE_SKILL",
    casterSeat: seat,
    description: "⚔️ <b>" + player.generalName + "</b> " + (isActive ? "bật" : "tắt") + " tuyệt kỹ <b>[" + canonicalSkill + "]</b>."
  });

  refreshLastDelta(state);
  return { success: true, state };
}











