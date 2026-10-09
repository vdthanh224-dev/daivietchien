/**
 * 100% In-Memory WebSocket Realtime (<15ms) trên RAM
 */
import {
  initGame,
  checkVersion,
  handlePlayCard,
  handleRespondAction,
  handleUseSkill,
  handleToggleSkill,
  handleEndTurn,
  handleDiscardCards,
  handleAIStep,
  handleAIReaction,
  tickGameState,
  fastForwardMatchForDeadPlayer,
  sanitizeGameStateForClient,
  hydrateGameState,
  ensureMutationVersion,
} from "./gameEngine.js";
import { HERO_MAX_HP, HEROES } from "./heroes.js";
import { getModeRules } from "./modeRegistry.js";

const rooms = new Map();
const startTime = Date.now();
const instanceId = `node_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`;
const clusterChannel = typeof BroadcastChannel !== "undefined" ? new BroadcastChannel("dvc_cluster_bus") : null;

function clusterBroadcast(data) {
  if (clusterChannel) {
    try {
      clusterChannel.postMessage({ ...data, sender: instanceId });
    } catch (err) {
      console.error("[ClusterBroadcast Error]:", err);
    }
  }
}

if (clusterChannel) {
  clusterChannel.onmessage = (event) => {
    const msg = event.data;
    if (!msg || typeof msg !== "object" || msg.sender === instanceId) return;
    const { type, roomId } = msg;
    if (!roomId) return;

    if (type === "DRAFT_SYNC" && msg.draft) {
      let room = rooms.get(roomId);
      if (!room) {
        room = {
          state: null,
          draft: msg.draft,
          sockets: new Map(),
          lastActivity: Date.now(),
          nextTickAt: Date.now(),
          lastLeaderHeartbeat: Date.now(),
        };
        rooms.set(roomId, room);
      } else if (room.draft) {
        const incomingRev = msg.draft.revision || 0;
        const currentRev = room.draft.revision || 0;
        const incomingLockedCount = (msg.draft.slots || []).filter((slot) => slot.isLocked && slot.heroId > 0).length;
        const currentLockedCount = (room.draft.slots || []).filter((slot) => slot.isLocked && slot.heroId > 0).length;
        if (incomingRev >= currentRev || incomingLockedCount > currentLockedCount || msg.draft.isCompleted) {
          const incomingSlots = Array.isArray(msg.draft.slots) ? msg.draft.slots : [];
          const currentBySeat = new Map((room.draft.slots || []).map((slot) => [slot.seat, slot]));
          room.draft.slots = incomingSlots.map((slot) => {
            const current = currentBySeat.get(slot.seat);
            if (current?.isLocked && !slot.isLocked) return { ...slot, ...current };
            return slot;
          });
          room.draft.currentPickerIndex = msg.draft.currentPickerIndex;
          room.draft.activeSeats = Array.isArray(msg.draft.activeSeats) ? msg.draft.activeSeats : room.draft.activeSeats;
          room.draft.round = msg.draft.round || room.draft.round || 1;
          room.draft.timer = msg.draft.timer;
          room.draft.timerStartAt = msg.draft.timerStartAt;
          room.draft.revision = incomingRev;
          room.draft.isCompleted = msg.draft.isCompleted;
          if (msg.draft.leader) room.draft.leader = msg.draft.leader;
        }
        room.lastLeaderHeartbeat = Date.now();
      }
      room.lastActivity = Date.now();
      if (room.draft && !room.draft.isCompleted) {
        broadcastRoom(room, draftMessage(roomId, room.draft));
      }
    }

    if (type === "DRAFT_HOVER_SYNC") {
      let room = rooms.get(roomId);
      if (room?.draft) {
        const slot = room.draft.slots.find((s) => s.seat === msg.seat);
        if (slot && !slot.isLocked) {
          slot.hoverHeroId = msg.heroId;
          slot.hoverHeroName = msg.heroName;
          broadcastRoom(room, {
            type: "DRAFT_HOVER_UPDATE",
            roomId,
            seat: msg.seat,
            heroId: msg.heroId,
            heroName: msg.heroName,
          });
        }
      }
    }

    if (type === "DRAFT_COMPLETED_SYNC") {
      let room = rooms.get(roomId);
      if (room) {
        if (room.draft) {
          room.draft.isCompleted = true;
          if (msg.slots) room.draft.slots = msg.slots;
        }
        if (!room.state && Array.isArray(msg.battlePlayers)) {
          room.state = initGame(roomId, msg.battlePlayers);
        }
        room.lastActivity = Date.now();
        broadcastRoom(room, {
          type: "DRAFT_COMPLETED",
          roomId,
          slots: msg.slots || room.draft?.slots,
          battlePlayers: msg.battlePlayers,
        });
      }
    }

    if (type === "GAME_STATE_SYNC" && msg.state) {
      let room = rooms.get(roomId);
      if (room) {
        room.state = msg.state;
        room.lastActivity = Date.now();
        broadcastStateUpdate(room, msg.action || "STATE_UPDATE");
      }
    }
  };
}

const MAX_WS_MESSAGE_BYTES = 64 * 1024;
const MAX_ACTIONS_PER_SECOND = 30;
const ALLOWED_WS_ACTIONS = new Set([
  "JOIN_ROOM", "INIT_GAME", "JOIN_DRAFT", "PICK_HERO", "HOVER_HERO", "GET_STATE", "PING",
  "USE_SKILL", "TOGGLE_SKILL", "PLAY_CARD", "RESPOND_ACTION", "END_TURN",
  "DISCARD_CARDS", "AI_STEP", "AI_REACTION", "FAST_FORWARD_MATCH"
]);

function validateClientPayload(payload, rawBytes) {
  if (!payload || typeof payload !== "object" || Array.isArray(payload)) return "Gói tin không hợp lệ";
  if (rawBytes > MAX_WS_MESSAGE_BYTES) return "Gói tin vượt giới hạn cho phép";
  if (typeof payload.action !== "string" || !ALLOWED_WS_ACTIONS.has(payload.action)) return "Hành động không hợp lệ";
  if (payload.roomId !== undefined && (typeof payload.roomId !== "string" || payload.roomId.length > 128)) return "Mã phòng không hợp lệ";
  for (const key of ["cardId", "targetCardId", "skillId", "heroName", "userId", "userName"]) {
    if (payload[key] !== undefined && (typeof payload[key] !== "string" || payload[key].length > 256)) return `${key} không hợp lệ`;
  }
  for (const key of ["seat", "targetSeat", "targetSeat2", "expectedVersion"]) {
    if (payload[key] !== undefined && (!Number.isInteger(Number(payload[key])) || Number(payload[key]) < 0)) return `${key} không hợp lệ`;
  }
  if (payload.cardIds !== undefined && (!Array.isArray(payload.cardIds) || payload.cardIds.length > 20 || payload.cardIds.some((id) => typeof id !== "string" || id.length > 256))) return "Danh sách lá bài không hợp lệ";
  if (payload.targetSeats !== undefined && (!Array.isArray(payload.targetSeats) || payload.targetSeats.length > 8)) return "Danh sách mục tiêu không hợp lệ";
  if (payload.players !== undefined && (!Array.isArray(payload.players) || payload.players.length > 8)) return "Danh sách người chơi không hợp lệ";
  return null;
}

const HERO_NAME_MAP = {
  1: "Cao Lỗ",
  2: "Đào Hãn",
  3: "Thi Sách",
  4: "Lê Chân",
  5: "Thánh Thiên",
  6: "Vũ Thị Thục",
  7: "Nàng Nội",
  8: "Triệu Quốc Đạt",
  9: "Triệu Thị Trinh",
  10: "Lý Bí",
  11: "Triệu Túc",
  12: "Tinh Thiều",
  13: "Phạm Tu",
  14: "Triệu Quang Phục",
  15: "Phùng Hưng",
  16: "Phùng Hải",
  17: "Mai Thúc Loan",
  18: "Khúc Thừa Dụ",
  19: "Khúc Hạo",
  20: "Dương Đình Nghệ",
  21: "Kiều Công Tiễn",
  22: "Ngô Quyền",
  23: "Dương Tam Kha",
  24: "Ngô Xương Ngập",
  25: "Ngô Xương Văn",
  26: "Đỗ Cảnh Thạc",
  27: "Kiều Thuận",
  28: "Nguyễn Siêu",
  29: "Lã Đường",
  30: "Đinh Bộ Lĩnh",
  31: "Đinh Liễn",
  32: "Đinh Điền",
  33: "Nguyễn Bặc",
  34: "Phạm Hạp",
  35: "Lê Hoàn",
  36: "Dương Vân Nga",
  37: "Lê Long Đĩnh",
  38: "Đào Cam Mộc",
  39: "Lý Công Uẩn",
  40: "Lý Phật Mã",
  41: "Lý Nhật Tôn",
  42: "Lý Đạo Thành",
  43: "Ỷ Lan",
  44: "Tông Đản",
  45: "Thân Cảnh Phúc",
  46: "Tô Hiến Thành",
  47: "Lý Thường Kiệt",
  48: "Trần Cảnh",
  49: "Trần Thủ Độ",
  50: "Trần Liễu",
  51: "Trần Hoảng",
  52: "Trần Khâm",
  53: "Trần Quốc Tuấn",
  54: "Trần Quang Khải",
  55: "Trần Nhật Duật",
  56: "Trần Quốc Toản",
  57: "Trần Bình Trọng",
  58: "Trần Khánh Dư",
  59: "Phạm Ngũ Lão",
  60: "Yết Kiêu",
  61: "Dã Tượng",
  62: "Đỗ Khắc Chung",
  63: "Hà Đặc",
  64: "Hà Chương",
  65: "Nguyễn Khoái",
  66: "Trần Thì Kiến",
  67: "Chu Văn An",
  68: "Trương Hán Siêu",
  69: "Mạc Đĩnh Chi",
  70: "Đoàn Nhữ Hài",
  71: "Trần Nghệ Tông",
  72: "Trần Duệ Tông",
  73: "Trần Khát Chân",
  74: "Đỗ Tử Bình",
  75: "Nguyễn Sư Tề",
  76: "Hồ Quý Ly",
  77: "Hồ Hán Thương",
  78: "Hồ Nguyên Trừng",
  79: "Trần Ngỗi",
  80: "Trần Quý Khoáng",
  81: "Đặng Dung",
  82: "Đặng Tất",
  83: "Nguyễn Cảnh Chân",
  84: "Nguyễn Cảnh Dị",
  85: "Nguyễn Biểu",
  86: "Lê Lợi",
  87: "Nguyễn Trãi",
  88: "Trần Nguyên Hãn",
  89: "Lê Khôi",
  90: "Nguyễn Xí",
  91: "Đinh Liệt",
  92: "Lưu Nhân Chú",
  93: "Phạm Vấn",
  94: "Lê Sát",
  95: "Lý Triện",
  96: "Đỗ Bí",
  97: "Trịnh Khả",
  98: "Nguyễn Chích",
  99: "Lê Văn An",
  100: "Bùi Quốc Hưng",
};

function getHeroName(heroId) {
  const numericId = Number(heroId);
  if (HERO_NAME_MAP[numericId]) return HERO_NAME_MAP[numericId];
  const heroKey = `HERO_${numericId}`;
  if (HEROES?.[heroKey]?.name && HEROES[heroKey].name !== heroKey) {
    return HEROES[heroKey].name;
  }
  return `Chiến Tướng #${heroId}`;
}

console.log("🎮 [Deno Server] Đại Việt Chiến 2v2 Unified Game Server (100% In-Memory) is running!");

function ensureLocalRoom(roomId, players = null, forceReinit = false, modeId = "2v2") {
  let room = rooms.get(roomId);
  if (!room) {
    if (!Array.isArray(players) || players.length === 0) return null;
    const initialState = initGame(roomId, players, modeId);
    room = {
      roomId,
      state: initialState,
      sockets: new Map(),
      lastActivity: Date.now(),
      nextTickAt: Date.now(),
    };
    rooms.set(roomId, room);
  } else if (forceReinit && Array.isArray(players)) {
    room.state = initGame(roomId, players, modeId);
    room.lastActivity = Date.now();
  }
  return room;
}

function updateLocalRoom(roomId, state) {
  const room = rooms.get(roomId);
  if (!room) return null;
  room.state = state;
  room.lastActivity = Date.now();
  return room;
}

function applyActionToState(state, seat, payload) {
  if (!hasSeat(state, seat)) return { error: "Ghế không thuộc phòng đấu" };

  if (payload.action === "USE_SKILL") {
    return handleUseSkill(state, seat, payload.skillId, payload.targetSeat, payload.cardId, payload);
  }
  if (payload.action === "TOGGLE_SKILL") {
    return handleToggleSkill(state, seat, payload.skillId);
  }
  if (payload.action === "PLAY_CARD") {
    return handlePlayCard(state, seat, payload.cardId, payload.targetSeat, payload);
  }
  if (payload.action === "RESPOND_ACTION") {
    return handleRespondAction(
      state,
      seat,
      payload.accepted,
      payload.cardId,
      payload.targetCardId,
      payload.cardIds,
      payload.targetSeat,
      payload,
    );
  }
  if (payload.action === "END_TURN") {
    return handleEndTurn(state, seat);
  }
  if (payload.action === "DISCARD_CARDS") {
    return handleDiscardCards(state, seat, payload.cardIds);
  }
  if (payload.action === "AI_STEP") {
    return handleAIStep(state, seat);
  }
  if (payload.action === "AI_REACTION") {
    return handleAIReaction(state, seat);
  }
  if (payload.action === "FAST_FORWARD_MATCH") {
    return fastForwardMatchForDeadPlayer(state, seat);
  }
  return { error: "Hành động không hợp lệ" };
}

function mutateSharedState(roomId, seat, payload) {
  const room = rooms.get(roomId);
  if (!room || !room.state) return { error: "Phòng đấu chưa được khởi tạo", state: null };

  const state = room.state;
  const versionError = checkVersion(state, payload.expectedVersion);
  if (versionError) {
    return { error: versionError.error, code: versionError.code, conflict: true, state };
  }

  const previousVersion = state.version;
  let tickRes = null;
  let result = null;

  if (payload.action === "SERVER_TICK") {
    tickRes = tickGameState(state);
    result = { success: true, changed: tickRes.changed };
  } else {
    result = applyActionToState(state, seat, payload);
    if (result && !result.error && state) {
      state.timerStartAt = Date.now();
    }
  }

  if (result?.error) return { error: result.error, state };
  if (result?.changed === false) return { state, result, committed: false };

  const isImportant = payload.action !== "SERVER_TICK" || (tickRes && tickRes.important);
  if (isImportant) {
    ensureMutationVersion(state, previousVersion);
  }

  room.lastActivity = Date.now();
  return {
    state,
    result,
    important: isImportant,
    committed: true,
  };
}

function broadcastStateUpdate(room, action = "STATE_UPDATE") {
  if (!room?.state) return;
  broadcastRoom(room, {
    type: "STATE_UPDATE",
    state: room.state,
    delta: room.state.lastDelta || null,
    version: room.state.version,
    action,
  });
}

function tickSharedRoom(roomId, room) {
  const result = mutateSharedState(roomId, undefined, {
    action: "SERVER_TICK",
  });
  if (result.committed) {
    updateLocalRoom(roomId, result.state);
    if (result.important) {
      broadcastStateUpdate(room, "SERVER_TICK");
      clusterBroadcast({
        type: "GAME_STATE_SYNC",
        roomId,
        state: result.state,
        action: "SERVER_TICK",
      });
    }
  }
}

function broadcastRoom(room, messageObj) {
  for (const [seat, ws] of room.sockets.entries()) {
    if (ws.readyState === WebSocket.OPEN) {
      try {
        if ((messageObj.type === "STATE_UPDATE" || messageObj.type === "STATE_SNAPSHOT") && messageObj.state) {
          const sanitizedState = sanitizeGameStateForClient(room.state, seat);
          const personalized = {
            ...messageObj,
            state: sanitizedState,
          };
          ws.send(JSON.stringify(personalized));
        } else if (messageObj.type === "DRAFT_STATE_UPDATE") {
          const safe = { ...messageObj, activeSeats: messageObj.activeSeats, round: messageObj.round, slots: (messageObj.slots || []).map((slot) => { const { role, heroId, heroName, hoverHeroId, hoverHeroName, candidateHeroIds, availableHeroIds, ...publicSlot } = slot; const own = slot.seat === seat; const locked = Boolean(slot.isLocked && heroId > 0); return { ...publicSlot, role: own ? (role || "") : undefined, heroId: own || locked ? heroId : 0, heroName: own || locked ? heroName : "", hoverHeroId: own ? (hoverHeroId || 0) : 0, hoverHeroName: own ? (hoverHeroName || "") : "", candidateHeroIds: own ? (candidateHeroIds || []) : [] }; }) };
          if (String(room.draft?.modeId || "").startsWith("dynasty_")) {
            const own = safe.slots.find((slot) => slot.seat === seat);
            safe.selectedHeroIds = own && own.heroId > 0 ? [own.heroId] : [];
          }
          ws.send(JSON.stringify(safe));
        } else if (messageObj.type === "DRAFT_COMPLETED") {
          const safe = { ...messageObj, activeSeats: messageObj.activeSeats, round: messageObj.round, slots: (messageObj.slots || []).map((slot) => { const { role, ...publicSlot } = slot; return { ...publicSlot, role: slot.seat === seat ? (role || "") : undefined }; }) };
          ws.send(JSON.stringify(safe));
        } else {
          ws.send(JSON.stringify(messageObj));
        }
      } catch (e) {
        console.error(`[Broadcast error seat ${seat}]:`, e);
      }
    }
  }
}

function normalizeSeat(value) {
  const seat = Number(value);
  return Number.isInteger(seat) && seat >= 1 && seat <= 8 ? seat : 0;
}

function hasSeat(state, seat) {
  return !!state?.players?.some((player) => player.seat === seat);
}

/**
 * Bind one WebSocket to one seat, replacing any stale connection safely.
 * A socket can only have one mapping in a room, and an older socket for the
 * same seat must not remain able to receive or remove the new mapping.
 */
function bindSocket(room, seat, socket) {
  for (const [mappedSeat, mappedSocket] of room.sockets.entries()) {
    if (mappedSocket === socket && mappedSeat !== seat) {
      room.sockets.delete(mappedSeat);
    }
  }

  const previousSocket = room.sockets.get(seat);
  if (previousSocket && previousSocket !== socket) {
    try {
      previousSocket.close(1000, "Seat reconnected");
    } catch {
      // The old socket may already be closed; map replacement is sufficient.
    }
  }
  room.sockets.set(seat, socket);
}

function randomTeamSeats(count = 4) {
  const seats = Array.from({ length: count }, (_, index) => index + 1);
  for (let i = seats.length - 1; i > 0; i -= 1) {
    const j = Math.floor(Math.random() * (i + 1));
    [seats[i], seats[j]] = [seats[j], seats[i]];
  }
  return new Set(seats.slice(0, 2));
}

function draftSeatCount(modeId) { return modeId === "dynasty_5" ? 5 : (modeId === "dynasty_8" ? 8 : 4); }
function arrangeDraftSlots(slots, modeId) {
  if (!String(modeId).startsWith("dynasty_")) return slots;
  // Assign seats once per room, independently of join order. The king occupies seat 1.
  const shuffled = [...slots];
  for (let i = shuffled.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [shuffled[i], shuffled[j]] = [shuffled[j], shuffled[i]];
  }
  const roles = draftRoles(modeId);
  for (let i = roles.length - 1; i > 1; i--) {
    const j = 1 + Math.floor(Math.random() * i);
    [roles[i], roles[j]] = [roles[j], roles[i]];
  }
  return shuffled.map((slot, index) => ({ ...slot, seat: index + 1, seatNumber: index + 1, role: roles[index] }));
}

function draftRoles(modeId) { return modeId === "dynasty_5" ? ["KING", "LOYALIST", "REBEL", "REBEL", "SPY"] : (modeId === "dynasty_8" ? ["KING", "LOYALIST", "REBEL", "REBEL", "SPY", "LOYALIST", "REBEL", "REBEL"] : []); }
function isDynastyDraft(draft) { return String(draft?.modeId || "").startsWith("dynasty_"); }

function resolveDraftSeat(room, requestedSeat, payload, socket) {
  const slots = room.draft?.slots || [];
  const normalize = (value) => String(value || "").trim().toLowerCase();
  const userId = normalize(payload.userId);
  const userName = normalize(payload.userName);

  const isAvailable = (slot) => {
    if (!slot) return false;
    const slotUid = normalize(slot.userId);
    const slotName = normalize(slot.userName);
    const placeholderUid = /^user_\d+$/.test(slotUid) || slotUid === "empty";
    const placeholderName = /^ghế\s*\d+$/.test(slotName) || /^chiến tướng\s*\d+$/.test(slotName);
    if (userId && slotUid === userId) return true;
    if (userName && slotName === userName) return true;
    if (!slot.isAI && slotUid && !placeholderUid && (!userId || slotUid !== userId)) return false;
    if (!slot.isAI && slotName && !placeholderName && userName && slotName !== userName && slotUid !== userId) return false;
    const existing = room.sockets.get(slot.seat);
    if (existing && existing !== socket && existing.readyState === WebSocket.OPEN) return false;
    return true;
  };

  // Ưu tiên 1: Khớp chính xác theo userId từ phòng ghép
  const byId = userId
    ? slots.filter((slot) => normalize(slot.userId) === userId)
    : [];
  if (byId.length === 1 && isAvailable(byId[0])) {
    return byId[0].seat;
  }

  // Ưu tiên 2: Explicit debug seat / assigned seat
  const debugSeat = Number(payload.debugSeat || requestedSeat);
  if (!isDynastyDraft(room.draft) && debugSeat >= 1 && debugSeat <= 4) {
    const s = slots.find((e) => e.seat === debugSeat);
    if (isAvailable(s)) return debugSeat;
  }

  // Ưu tiên 3: Khớp theo userName
  const byName = userName
    ? slots.filter((slot) => normalize(slot.userName) === userName)
    : [];
  if (byName.length === 1 && isAvailable(byName[0])) {
    return byName[0].seat;
  }

  const reqSlot = slots.find((slot) => slot.seat === requestedSeat);
  if (reqSlot && isAvailable(reqSlot)) {
    return requestedSeat;
  }

  return slots.find(isAvailable)?.seat || 0;
}


function generate2v2RoundPools(draft, _round) {
  if (isDynastyDraft(draft)) return;
  const activeSeats = draft.activeSeats || [draft.slots.find((slot) => !slot.isLocked)?.seat || draft.slots[0]?.seat || 1];
  const locked = new Set(draft.slots.filter((slot) => slot.isLocked).map((slot) => Number(slot.heroId)));
  const requestedIds = [
    ...(draft.availableHeroIds || []),
    ...draft.slots.flatMap((slot) => slot.availableHeroIds || []),
  ];
  const allIds = Array.from(new Set(requestedIds.length > 0 ? requestedIds : Array.from({ length: 40 }, (_, i) => i + 1)))
    .map(Number)
    .filter((id) => Number.isInteger(id) && id >= 1 && id <= 40);
  for (let i = allIds.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [allIds[i], allIds[j]] = [allIds[j], allIds[i]];
  }
  for (const slot of draft.slots) {
    if (!slot || !activeSeats.includes(slot.seat) || slot.isLocked) continue;
    if (Array.isArray(slot.candidateHeroIds) && slot.candidateHeroIds.length > 0) continue;
    const own = new Set((slot.availableHeroIds || []).map(Number));
    slot.candidateHeroIds = allIds
      .filter((id) => !locked.has(id) && (own.size === 0 || own.has(id)))
      .slice(0, 8);
  }
}

function getCandidateIdsForSlot(slot) {
  return Array.isArray(slot?.candidateHeroIds) ? slot.candidateHeroIds.map(Number) : [];
}

function draftMessage(roomId, draft) {
  const is2v2 = !isDynastyDraft(draft);
  const activeSeats = draft.activeSeats || [draft.slots.find((slot) => !slot.isLocked)?.seat || draft.slots[0]?.seat || 1];
  const currentSeat = activeSeats[0] || 1;
  const slots = [...draft.slots]
    .sort((a, b) => a.seat - b.seat)
    .map((slot) => ({
      ...slot,
      seatNumber: slot.seat,
      hoverHeroId: slot.hoverHeroId || 0,
      hoverHeroName: slot.hoverHeroName || "",
      candidateHeroIds: slot.candidateHeroIds || [],
    }));
  const currentPickerIndex = slots.findIndex((slot) => slot.seat === currentSeat);
  return {
    type: "DRAFT_STATE_UPDATE",
    roomId,
    revision: draft.revision || 1,
    currentPickerIndex: currentPickerIndex >= 0 ? currentPickerIndex : draft.currentPickerIndex,
    currentSeat,
    activeSeats,
    round: draft.round || 1,
    timer: draft.timer,
    slots,
    selectedHeroIds: slots.filter((slot) => slot.isLocked).map((slot) => slot.heroId),
  };
}

function makeDraftSlots(rawSlots, boundSeat, payload) {
  const modeId = String(payload.modeId || "2v2");
  const seatCount = draftSeatCount(modeId);
  const dragonSeats = randomTeamSeats(seatCount);
  return arrangeDraftSlots(Array.from({ length: seatCount }, (_, index) => index + 1).map((seat) => {
    const matched = rawSlots.find((slot) => Number(slot?.seatNumber || slot?.seat) === seat) || rawSlots[seat - 1] || {};
    const matchedUid = String(matched.userId || "").trim();
    const isBotUid = matchedUid.startsWith("bot_");
    const isRealUid = matchedUid !== "" && matchedUid !== "empty" && !isBotUid;
    const isAI = isRealUid ? false : (matched.isAI !== undefined ? Boolean(matched.isAI) : isBotUid);
    const heroId = Number(matched.heroId || matched.hero_id || 0);
    return {
      seat,
      seatNumber: seat,
      userId: String(matched.userId && matched.userId !== "empty" ? matched.userId : (isAI ? `bot_${seat}` : (seat === boundSeat ? (payload.userId || "") : ""))),
      userName: String(matched.userName && matched.userName !== "empty" ? matched.userName : (isAI ? `AI Ghế ${seat}` : (seat === boundSeat ? (payload.userName || "") : ""))),
      isAI,
      isDragon: matched.isDragon !== undefined ? Boolean(matched.isDragon) : dragonSeats.has(seat),
      availableHeroIds: Array.isArray(matched.availableHeroIds) ? matched.availableHeroIds.map(Number) : [],
      role: "",
      heroId,
      heroName: String(matched.heroName || ""),
      hoverHeroId: 0,
      hoverHeroName: "",
      maxHp: HERO_MAX_HP[heroId] || 4,
      isLocked: Boolean(matched.isLocked && heroId > 0),
    };
  }), modeId);
}

function createDraftRoom(roomId, payload, boundSeat) {
  const rawSlots = Array.isArray(payload.slots) ? payload.slots : [];
  const modeId = String(payload.modeId || "2v2");
  const slots = makeDraftSlots(rawSlots, boundSeat, payload);
  const is2v2 = !modeId.startsWith("dynasty_");
  const draft = {
    roomId,
    modeId,
    slots,
    round: 1,
    activeSeats: is2v2 ? [slots[0]?.seat || 1] : [slots[0]?.seat || 1],
    currentPickerIndex: 0,
    timer: 40,
    timerStartAt: Date.now(),
    lastBroadcastTimer: 40,
    revision: 1,
    isCompleted: false,
    leader: instanceId,
    availableHeroIds: [],
  };
  const requestedHeroIds = Array.isArray(payload.availableHeroIds) ? payload.availableHeroIds.map(Number).filter((id) => Number.isInteger(id) && id > 0) : [];
  draft.availableHeroIds = Array.from(new Set(requestedHeroIds));
  const initialSlot = slots.find((slot) => slot.seat === boundSeat);
  if (initialSlot) initialSlot.availableHeroIds = draft.availableHeroIds;
  if (is2v2) {
    generate2v2RoundPools(draft, 1);
  }
  const room = {
    state: null,
    draft,
    sockets: new Map(),
    lastActivity: Date.now(),
    nextTickAt: Date.now(),
    lastLeaderHeartbeat: Date.now(),
  };
  rooms.set(roomId, room);
  clusterBroadcast({ type: "DRAFT_SYNC", roomId, draft: room.draft });
  return room;
}

function finishDraftAndStartBattle(roomId, room) {
  const draft = room?.draft;
  if (!draft || draft.isCompleted || !draft.slots.every((slot) => slot.isLocked && slot.heroId > 0)) return;

  const battlePlayers = draft.slots.map((slot) => ({
    seat: slot.seat,
    userId: slot.userId,
    heroId: `HERO_${slot.heroId}`,
    generalName: slot.heroName || getHeroName(slot.heroId),
    maxHp: HERO_MAX_HP[slot.heroId] || 4,
    hp: HERO_MAX_HP[slot.heroId] || 4,
    isAlly: slot.isDragon,
    isAI: slot.isAI,
    role: slot.role || "",
  }));
  const state = initGame(roomId, battlePlayers, draft.modeId || "2v2");

  draft.isCompleted = true;
  room.state = state;
  room.lastActivity = Date.now();
  clusterBroadcast({
    type: "DRAFT_COMPLETED_SYNC",
    roomId,
    slots: draft.slots,
    battlePlayers,
  });
  broadcastRoom(room, { type: "DRAFT_COMPLETED", roomId, slots: draft.slots, battlePlayers });
}

async function tickDraftRoom(roomId, room) {
  const draft = room?.draft;
  if (!draft || draft.isCompleted) return;

  const isLeader = !draft.leader || draft.leader === instanceId;
  if (!isLeader) {
    if (Date.now() - (room.lastLeaderHeartbeat || room.lastActivity) > 4000) {
      draft.leader = instanceId;
    } else {
      return;
    }
  }

  const is2v2 = !isDynastyDraft(draft);
  const dynastyReady = isDynastyDraft(draft) && draft.slots[0]?.isLocked;

  let indexes = [];
  if (is2v2) {
    const activeSeats = draft.activeSeats || [draft.slots.find((slot) => !slot.isLocked)?.seat || draft.slots[0]?.seat || 1];
    indexes = draft.slots
      .map((slot, index) => index)
      .filter((index) => activeSeats.includes(draft.slots[index]?.seat) && !draft.slots[index]?.isLocked);
  } else if (dynastyReady) {
    indexes = draft.slots.map((slot, index) => index).filter((index) => index > 0 && !draft.slots[index].isLocked);
  } else {
    indexes = draft.currentPickerIndex < draft.slots.length && !draft.slots[draft.currentPickerIndex]?.isLocked
      ? [draft.currentPickerIndex]
      : [];
  }

  if (indexes.length === 0) {
    if (is2v2) {
      if (draft.round === 1) {
        draft.round = 2;
        draft.activeSeats = [draft.slots.find((slot) => !slot.isLocked)?.seat || draft.slots[2]?.seat || 3];
        generate2v2RoundPools(draft, draft.round);
        draft.timer = 40;
        draft.timerStartAt = Date.now();
        draft.lastBroadcastTimer = 40;
        draft.revision = (draft.revision || 0) + 1;
        room.lastActivity = Date.now();
        broadcastRoom(room, draftMessage(roomId, draft));
        clusterBroadcast({ type: "DRAFT_SYNC", roomId, draft });
        return;
      } else {
        const next = draft.slots.find((slot) => !slot.isLocked);
        if (next) { draft.activeSeats = [next.seat]; generate2v2RoundPools(draft, draft.round); draft.timer = 40; draft.timerStartAt = Date.now(); draft.lastBroadcastTimer = 40; draft.revision = (draft.revision || 0) + 1; broadcastRoom(room, draftMessage(roomId, draft)); clusterBroadcast({ type: "DRAFT_SYNC", roomId, draft }); }
        else finishDraftAndStartBattle(roomId, room);
        return;
      }
    } else {
      finishDraftAndStartBattle(roomId, room);
      return;
    }
  }

  const elapsedMs = Date.now() - draft.timerStartAt;
  const elapsed = Math.floor(elapsedMs / 1000);
  let changed = false;

  for (const index of indexes) {
    const currentSlot = draft.slots[index];
    if (!currentSlot || currentSlot.isLocked) continue;
    const isSocketOpen = room.sockets.has(currentSlot.seat) && room.sockets.get(currentSlot.seat)?.readyState === WebSocket.OPEN;
    const isBot = Boolean(currentSlot.isAI) || !isSocketOpen;

    if (isBot && elapsedMs >= 800 && !currentSlot.hoverHeroId) {
      const used = new Set(draft.slots.filter((slot) => slot.isLocked).map((slot) => slot.heroId));
      for (const idx of indexes) {
        if (idx !== index && draft.slots[idx]?.hoverHeroId) {
          used.add(draft.slots[idx].hoverHeroId);
        }
      }
      const candidates = (currentSlot.candidateHeroIds && currentSlot.candidateHeroIds.length > 0)
        ? currentSlot.candidateHeroIds.filter((id) => !used.has(id))
        : Array.from({ length: 40 }, (_, i) => i + 1).filter((id) => !used.has(id));
      const heroId = candidates.length > 0
        ? candidates[Math.floor(Math.random() * candidates.length)]
        : 1;
      currentSlot.hoverHeroId = heroId;
      currentSlot.hoverHeroName = getHeroName(heroId);
      if (isDynastyDraft(draft)) {
        const owner = room.sockets.get(currentSlot.seat);
        if (owner?.readyState === WebSocket.OPEN) owner.send(JSON.stringify({ type: "DRAFT_HOVER_UPDATE", roomId, seat: currentSlot.seat, heroId, heroName: currentSlot.hoverHeroName }));
      } else {
        broadcastRoom(room, { type: "DRAFT_HOVER_UPDATE", roomId, seat: currentSlot.seat, heroId, heroName: currentSlot.hoverHeroName });
      }
    }

    const botThresholdSec = Boolean(currentSlot.isAI) ? 1.5 : (isSocketOpen ? 40.0 : 5.0);
    if (elapsedMs >= botThresholdSec * 1000 || elapsed >= 40) {
      const used = new Set(draft.slots.filter((slot) => slot.isLocked).map((slot) => slot.heroId));
      let heroId = currentSlot.hoverHeroId > 0 && !used.has(currentSlot.hoverHeroId) ? currentSlot.hoverHeroId : 0;
      if (!heroId) {
        const candidates = (currentSlot.candidateHeroIds || []).filter((id) => !used.has(id));
        heroId = candidates.length > 0
          ? candidates[Math.floor(Math.random() * candidates.length)]
          : 1;
      }
      currentSlot.heroId = heroId;
      currentSlot.heroName = getHeroName(heroId);
      currentSlot.hoverHeroId = 0;
      currentSlot.hoverHeroName = "";
      currentSlot.maxHp = (HERO_MAX_HP[heroId] || 4) + (currentSlot.role === "KING" ? 1 : 0);
      currentSlot.isLocked = true;
      changed = true;
    }
  }

  if (changed) {
    if (is2v2) {
      const activeSeats = draft.activeSeats || [draft.slots.find((slot) => !slot.isLocked)?.seat || draft.slots[0]?.seat || 1];
      const allActiveLocked = draft.slots.filter((s) => activeSeats.includes(s.seat)).every((s) => s.isLocked && s.heroId > 0);
      if (allActiveLocked && draft.round === 1) {
        draft.round = 2;
        draft.activeSeats = [draft.slots.find((slot) => !slot.isLocked)?.seat || draft.slots[2]?.seat || 3];
        generate2v2RoundPools(draft, draft.round);
        draft.timerStartAt = Date.now();
        draft.timer = 40;
        draft.lastBroadcastTimer = 40;
      }
    } else if (!dynastyReady) {
      draft.currentPickerIndex += 1;
      draft.timerStartAt = Date.now();
      draft.timer = 40;
      draft.lastBroadcastTimer = 40;
    }

    draft.revision = (draft.revision || 0) + 1;
    room.lastActivity = Date.now();
    if (draft.slots.every((slot) => slot.isLocked && slot.heroId > 0)) {
      finishDraftAndStartBattle(roomId, room);
      return;
    }
    broadcastRoom(room, draftMessage(roomId, draft));
    clusterBroadcast({ type: "DRAFT_SYNC", roomId, draft });
    return;
  }

  draft.timer = Math.max(0, 40 - elapsed);
  if (draft.timer !== draft.lastBroadcastTimer) {
    draft.lastBroadcastTimer = draft.timer;
    draft.revision = (draft.revision || 0) + 1;
    broadcastRoom(room, draftMessage(roomId, draft));
    clusterBroadcast({ type: "DRAFT_SYNC", roomId, draft });
  }
}

setInterval(() => {
  if (rooms.size === 0) return;
  const now = Date.now();
  for (const [roomId, room] of rooms.entries()) {
    if (!room) continue;
    try {
      const isFinished = room.state && room.state.status === "FINISHED";
      const noSockets = !room.sockets || room.sockets.size === 0;
      const isIdleTooLong = now - room.lastActivity > 900000;
      const isFinishedTooLong = isFinished && (now - room.lastActivity > 30000);
      const isAbandoned = noSockets && (now - room.lastActivity > 120000);

      if (isIdleTooLong || isFinishedTooLong || isAbandoned) {
        if (room.sockets) {
          for (const ws of room.sockets.values()) {
            try { ws.close(1000, "Room cleaned up"); } catch {}
          }
          room.sockets.clear();
        }
        rooms.delete(roomId);
        console.log(`[Deno Server] Đã dọn dẹp phòng: ${roomId}`);
        continue;
      }

      if (room.draft && !room.draft.isCompleted) {
        tickDraftRoom(roomId, room);
        continue;
      }
      if (!room.state || isFinished) continue;

      if (now >= (room.nextTickAt || 0)) {
        room.nextTickAt = now + 250;
        tickSharedRoom(roomId, room);
      }
    } catch (err) {
      console.error(`[Room Loop Error room ${roomId}]:`, err);
    }
  }
}, 250);

Deno.serve({ port: Number(Deno.env.get("PORT")) || 8080 }, async (req) => {
  const upgrade = req.headers.get("upgrade") || "";

  // 1. WEBSOCKET REALTIME CONNECTION (<15ms)
  if (upgrade.toLowerCase() === "websocket") {
    const { socket, response } = Deno.upgradeWebSocket(req);

    let currentRoomId = null;
    let currentSeat = 0;
    let messageQueue = Promise.resolve();
    let rateWindowStartedAt = Date.now();
    let rateWindowCount = 0;

    socket.onopen = () => {};

    socket.onmessage = (event) => {
      messageQueue = messageQueue.then(async () => {
        try {
        const raw = typeof event.data === "string" ? event.data : String(event.data || "");
        const rawBytes = new TextEncoder().encode(raw).length;
        if (rawBytes > MAX_WS_MESSAGE_BYTES) {
          socket.close(1009, "Message too big");
          return;
        }
        const payload = JSON.parse(raw);
        const payloadError = validateClientPayload(payload, rawBytes);
        if (payloadError) return socket.send(JSON.stringify({ type: "ERROR", error: payloadError }));
        if (payload.action === "PING") {
          return socket.send(JSON.stringify({
            type: "PONG",
            clientTime: payload.clientTime ?? null,
            timestamp: Date.now()
          }));
        }
        if (payload.action !== "PING") {
          const now = Date.now();
          if (now - rateWindowStartedAt >= 1000) {
            rateWindowStartedAt = now;
            rateWindowCount = 0;
          }
          if (++rateWindowCount > MAX_ACTIONS_PER_SECOND) {
            return socket.send(JSON.stringify({ type: "ERROR", error: "Gửi hành động quá nhanh, vui lòng chờ một chút" }));
          }
        }
        const { action, roomId, cardId, targetCardId, targetSeat, targetSeat2, targetSeats, recast, skillId, accepted, cardIds, players, modeId, expectedVersion } = payload;
        const requestSeat = normalizeSeat(payload.seat);

        if (!roomId) {
          return socket.send(JSON.stringify({ type: "ERROR", error: "Thiếu roomId" }));
        }

        const isJoinAction = action === "JOIN_ROOM" || action === "INIT_GAME" || action === "JOIN_DRAFT";

        if (isJoinAction) {
          if (requestSeat === 0) {
            return socket.send(JSON.stringify({ type: "ERROR", error: "Ghế không hợp lệ" }));
          }
          // Chuyển sang phòng mới: tháo gỡ socket khỏi phòng cũ một cách sạch sẽ
          if (currentRoomId !== null && currentRoomId !== roomId) {
            const oldRoom = rooms.get(currentRoomId);
            if (oldRoom && oldRoom.sockets && oldRoom.sockets.get(currentSeat) === socket) {
              oldRoom.sockets.delete(currentSeat);
            }
            currentRoomId = null;
            currentSeat = 0;
          }
        } else {
          // Các hành động trong trận (PICK_HERO, PLAY_CARD, ...):
          // Kết nối phải đã tham gia phòng, và không được đổi phòng hoặc ghế khác.
          if (currentRoomId === null) {
            return socket.send(JSON.stringify({ type: "ERROR", error: "Kết nối chưa tham gia phòng" }));
          }
          if (roomId !== currentRoomId || (requestSeat !== 0 && requestSeat !== currentSeat)) {
            return socket.send(JSON.stringify({ type: "ERROR", error: "Kết nối đã được khóa vào phòng/ghế khác" }));
          }
        }

        // For bound connections, an omitted seat is resolved to the bound
        // identity; a supplied seat was checked above and cannot differ.
        const boundSeat = currentRoomId !== null ? currentSeat : requestSeat;

        let room = rooms.get(roomId);

        // A. KHỞI TẠO HOẶC THAM GIA PHÒNG CHỌN TƯỚNG
        if (action === "JOIN_DRAFT") {
          const noActiveSockets = !room || !room.sockets || Array.from(room.sockets.values()).every((s) => s.readyState !== WebSocket.OPEN);
          const requestedSeatCount = draftSeatCount(String(payload.modeId || "2v2"));
          const draftShapeChanged = !!room?.draft && (String(room.draft.modeId || "2v2") !== String(payload.modeId || "2v2") || room.draft.slots.length !== requestedSeatCount);
          const fresh = !room || draftShapeChanged || room.draft?.isCompleted || (noActiveSockets && Date.now() - room.lastActivity > 15000);
          if (fresh) room = createDraftRoom(roomId, payload, boundSeat);
          if (!room?.draft) {
            return socket.send(JSON.stringify({ type: "ERROR", error: "Không thể khởi tạo phòng chọn tướng" }));
          }
          const draftSeat = resolveDraftSeat(room, currentSeat || boundSeat || requestSeat, payload, socket);
          if (!draftSeat) {
            return socket.send(JSON.stringify({ type: "ERROR", error: "Phòng đã đủ 4 ghế" }));
          }
          const slot = room.draft.slots.find((entry) => entry.seat === draftSeat);
          if (!slot) {
            return socket.send(JSON.stringify({ type: "ERROR", error: "Ghế không thuộc phòng chọn tướng" }));
          }
          if (payload.userId) slot.userId = String(payload.userId);
          if (payload.userName) slot.userName = String(payload.userName);
          if (Array.isArray(payload.availableHeroIds)) {
            slot.availableHeroIds = Array.from(new Set(payload.availableHeroIds.map(Number).filter((id) => Number.isInteger(id) && id > 0)));
            if (room.draft.availableHeroIds.length === 0) room.draft.availableHeroIds = slot.availableHeroIds.slice();
            generate2v2RoundPools(room.draft, room.draft.round || 1);
          }
          slot.isAI = false;
          room.draft.revision = (room.draft.revision || 0) + 1;
          currentRoomId = roomId;
          currentSeat = draftSeat;
          bindSocket(room, currentSeat, socket);
          room.lastActivity = Date.now();
          socket.send(JSON.stringify({ type: "DRAFT_JOINED", roomId, seat: draftSeat, assignedSeat: draftSeat }));
          if (room.draft.isCompleted && room.state) {
            return socket.send(JSON.stringify({
              type: "DRAFT_COMPLETED",
              roomId,
              slots: room.draft.slots,
              battlePlayers: room.state.players,
            }));
          }
          broadcastRoom(room, draftMessage(roomId, room.draft));
          clusterBroadcast({ type: "DRAFT_SYNC", roomId, draft: room.draft });
          return;
        }

        // B. KHÓA TƯỚNG TRONG PHÒNG CHỌN TƯỚNG
        if (action === "PICK_HERO") {
          if (!room?.draft || room.draft.isCompleted) {
            return socket.send(JSON.stringify({ type: "ERROR", error: "Không trong giai đoạn chọn tướng" }));
          }
          const is2v2 = !isDynastyDraft(room.draft);
          const dynastyReady = isDynastyDraft(room.draft) && room.draft.slots[0]?.isLocked;
          const requestedSlot = room.draft.slots.find((slot) => slot.seat === boundSeat);
          if (!requestedSlot || requestedSlot.isLocked) {
            return socket.send(JSON.stringify({ type: "ERROR", error: "Chưa đến lượt bạn chọn tướng hoặc bạn đã khóa tướng" }));
          }

          if (is2v2) {
            const activeSeats = room.draft.activeSeats || [room.draft.slots[0]?.seat || 1];
            if (!activeSeats.includes(boundSeat)) {
              return socket.send(JSON.stringify({ type: "ERROR", error: "Chưa đến lượt bạn chọn tướng. Đang chờ người khác chọn tướng." }));
            }
          } else if (!dynastyReady) {
            const currentSlot = room.draft.slots[room.draft.currentPickerIndex];
            if (!currentSlot || currentSlot.seat !== boundSeat) {
              return socket.send(JSON.stringify({ type: "ERROR", error: "Chưa đến lượt bạn chọn tướng" }));
            }
          }

          const heroId = Number(payload.heroId || payload.hero_id || 0);
          if (!Number.isInteger(heroId) || heroId < 1 || heroId > 100) {
            return socket.send(JSON.stringify({ type: "ERROR", error: "Tướng không hợp lệ" }));
          }
          const selectedHeroIds = room.draft.slots.filter((entry) => entry.isLocked).map((entry) => entry.heroId);
          if (!isDynastyDraft(room.draft) && selectedHeroIds.includes(heroId)) {
            return socket.send(JSON.stringify({ type: "ERROR", error: "Tướng này đã được chọn" }));
          }
          if (is2v2 && !getCandidateIdsForSlot(requestedSlot).includes(heroId)) {
            return socket.send(JSON.stringify({ type: "ERROR", error: "Tướng này không nằm trong bể tướng của bạn" }));
          }
          const pickedSlot = requestedSlot;
          pickedSlot.heroId = heroId;
          pickedSlot.heroName = String(payload.heroName || getHeroName(heroId));
          pickedSlot.hoverHeroId = 0;
          pickedSlot.hoverHeroName = "";
          pickedSlot.maxHp = (HERO_MAX_HP[heroId] || 4) + (pickedSlot.role === "KING" ? 1 : 0);
          pickedSlot.isLocked = true;

          if (is2v2) {
            const activeSeats = room.draft.activeSeats || [room.draft.slots.find((slot) => !slot.isLocked)?.seat || room.draft.slots[0]?.seat || 1];
            const allActiveLocked = room.draft.slots.filter((s) => activeSeats.includes(s.seat)).every((s) => s.isLocked && s.heroId > 0);
            if (allActiveLocked) {
              const nextIndex = room.draft.slots.findIndex((slot) => slot.seat === boundSeat) + 1;
              if (nextIndex >= 0 && nextIndex < room.draft.slots.length) {
                room.draft.activeSeats = [room.draft.slots[nextIndex].seat];
                if (room.draft.round === 1 && nextIndex >= 2) room.draft.round = 2;
                generate2v2RoundPools(room.draft, room.draft.round);
                room.draft.timer = 40; room.draft.timerStartAt = Date.now(); room.draft.lastBroadcastTimer = 40;
              }
            }
          } else if (!dynastyReady) {
            room.draft.currentPickerIndex += 1;
            room.draft.timer = 40;
            room.draft.timerStartAt = Date.now();
            room.draft.lastBroadcastTimer = 40;
          }

          room.draft.revision = (room.draft.revision || 0) + 1;
          room.lastActivity = Date.now();
          if (room.draft.slots.every((slot) => slot.isLocked && slot.heroId > 0)) {
            await finishDraftAndStartBattle(roomId, room);
          } else {
            broadcastRoom(room, draftMessage(roomId, room.draft));
            clusterBroadcast({ type: "DRAFT_SYNC", roomId, draft: room.draft });
          }
          return;
        }

        // B2. XEM TRƯỚC / RÊ CHUỘT CHỌN TƯỚNG (HOVER PREVIEW SYNC)
        if (action === "HOVER_HERO") {
          if (!room?.draft || room.draft.isCompleted) return;
          const heroId = Number(payload.heroId || payload.hero_id || 0);
          const heroName = String(payload.heroName || getHeroName(heroId) || "");
          const targetSeat = currentSeat || boundSeat || Number(payload.seat || 0);
          const slot = room.draft.slots.find((s) => s.seat === targetSeat);
          if (slot && !slot.isLocked) {
            slot.hoverHeroId = heroId;
            slot.hoverHeroName = heroName;
            if (isDynastyDraft(room.draft)) {
              const owner = room.sockets.get(targetSeat);
              if (owner?.readyState === WebSocket.OPEN) owner.send(JSON.stringify({ type: "DRAFT_HOVER_UPDATE", roomId, seat: targetSeat, heroId, heroName }));
            } else {
              broadcastRoom(room, { type: "DRAFT_HOVER_UPDATE", roomId, seat: targetSeat, heroId, heroName });
            }
            clusterBroadcast({
              type: "DRAFT_HOVER_SYNC",
              roomId,
              seat: targetSeat,
              heroId,
              heroName,
            });
          }
          return;
        }

        // C. KHỞI TẠO HOẶC THAM GIA PHÒNG ĐẤU
        if (action === "JOIN_ROOM" || action === "INIT_GAME") {
          const requestedMode = getModeRules(modeId || "2v2");
          const hasFullPlayers = Array.isArray(players) && !!requestedMode
            && players.length >= requestedMode.minPlayers && players.length <= requestedMode.maxPlayers;
          const forceReinit = hasFullPlayers && (!room || !room.state || room.state.status === "FINISHED");
          room = await ensureLocalRoom(roomId, hasFullPlayers ? players : null, forceReinit, modeId || "2v2");
          if (!room) {
            return socket.send(JSON.stringify({ type: "ERROR", error: "Cần đủ thông tin 4 người chơi để khởi tạo phòng" }));
          }

          if (!hasSeat(room.state, boundSeat)) {
            return socket.send(JSON.stringify({ type: "ERROR", error: "Ghế không thuộc phòng đấu" }));
          }
          if (currentRoomId !== null) {
            const mappedSocket = room.sockets.get(boundSeat);
            if (mappedSocket && mappedSocket !== socket) {
              return socket.send(JSON.stringify({ type: "ERROR", error: "Kết nối đã bị thay thế, vui lòng kết nối lại" }));
            }
          }
          currentRoomId = roomId;
          currentSeat = boundSeat;
          bindSocket(room, currentSeat, socket);
          room.lastActivity = Date.now();

          // Gửi Snapshot đầy đủ cho người vừa kết nối
          socket.send(JSON.stringify({
            type: "STATE_SNAPSHOT",
            state: sanitizeGameStateForClient(room.state, currentSeat),
            version: room.state.version,
          }));

          broadcastRoom(room, {
            type: "PLAYER_JOINED",
            seat: currentSeat,
            activeSeats: Array.from(room.sockets.keys()),
          });
          return;
        }

        if (!room) room = await ensureLocalRoom(roomId);
        if (!room) {
          return socket.send(JSON.stringify({ type: "ERROR", error: "Phòng đấu không tồn tại hoặc đã kết thúc" }));
        }

        if (!hasSeat(room.state, boundSeat)) {
          return socket.send(JSON.stringify({ type: "ERROR", error: "Ghế không thuộc phòng đấu" }));
        }
        // A replaced/older socket may still deliver a queued message after a
        // reconnect. Never let it rebind the seat and disconnect the newer
        // socket; require the stale connection to reconnect instead.
        const mappedSocket = room.sockets.get(boundSeat);
        if (mappedSocket && mappedSocket !== socket) {
          return socket.send(JSON.stringify({ type: "ERROR", error: "Kết nối đã bị thay thế, vui lòng kết nối lại" }));
        }
        if (!mappedSocket) bindSocket(room, boundSeat, socket);
        room.lastActivity = Date.now();

        // B. LẤY SNAPSHOT TRẠNG THÁI HIỆN TẠI
        if (action === "GET_STATE") {
          return socket.send(JSON.stringify({
            type: "STATE_SNAPSHOT",
            state: sanitizeGameStateForClient(room.state, boundSeat),
            version: room.state.version,
          }));
        }

        // C. HEARTBEAT PING / PONG
        if (action === "PING") {
          return socket.send(JSON.stringify({ type: "PONG", timestamp: Date.now() }));
        }

        // D. XỬ LÝ TRÊN STATE TRONG BỘ NHỚ RAM
        const outcome = mutateSharedState(roomId, boundSeat, {
          action,
          cardId,
          targetCardId,
          targetSeat,
          targetSeat2,
          targetSeats,
          recast: recast === true,
          skillId,
          accepted,
          cardIds,
          expectedVersion,
        });
        if (outcome.conflict) {
          return socket.send(JSON.stringify({
            type: "CONFLICT",
            error: outcome.error,
            code: outcome.code || "VERSION_CONFLICT",
            state: outcome.state ? sanitizeGameStateForClient(outcome.state, boundSeat) : null,
          }));
        }
        if (outcome.error) {
          return socket.send(JSON.stringify({
            type: "ACTION_REJECTED",
            error: outcome.error,
            state: outcome.state ? sanitizeGameStateForClient(outcome.state, boundSeat) : null,
          }));
        }

        // E. Cập nhật trạng thái phòng và phát broadcast cho toàn bộ người chơi trong phòng
        if (outcome.committed) {
          updateLocalRoom(roomId, outcome.state);
          broadcastStateUpdate(room, action);
          clusterBroadcast({
            type: "GAME_STATE_SYNC",
            roomId,
            state: outcome.state,
            action,
          });
        }
        } catch (err) {
          console.error("[WS Message Error]:", err);
          socket.send(JSON.stringify({ type: "ERROR", error: err.message }));
        }
      });
    };

    socket.onclose = () => {
      // Capture identity before delayed cleanup; reconnects can mutate these
      // handler variables before the timer fires.
      const closedRoomId = currentRoomId;
      const closedSeat = currentSeat;
      if (closedRoomId) {
        const room = rooms.get(closedRoomId);
        if (room) {
          // A reconnect can replace the socket for the same seat. Do not let
          // the old socket's close event remove the newer connection.
          if (closedSeat && room.sockets.get(closedSeat) === socket) {
            room.sockets.delete(closedSeat);
          }
          if (room.sockets.size === 0) {
            setTimeout(() => {
              const r = rooms.get(closedRoomId);
              if (r && r.sockets.size === 0 && Date.now() - r.lastActivity > 600000) {
                rooms.delete(closedRoomId);
                console.log(`[Deno] Đã dọn dẹp phòng trống: ${closedRoomId}`);
              }
            }, 600000);
          }
        }
      }
    };

    return response;
  }

  // 2. HTTP REST API (FALLBACK & EXTERNAL CALLS)
  if (req.method === "POST") {
    try {
      const payload = await req.json();
      const { action, roomId, seat, cardId, targetCardId, targetSeat, targetSeat2, targetSeats, recast, skillId, accepted, cardIds, players, modeId, expectedVersion } = payload;
      const requestSeat = normalizeSeat(seat);

      if (!roomId) {
        return new Response(JSON.stringify({ success: false, error: "Thiếu roomId" }), {
          status: 400,
          headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
        });
      }

      let room = rooms.get(roomId);

      if (action === "INIT_GAME") {
        if (requestSeat === 0) {
          return new Response(JSON.stringify({ success: false, error: "Ghế không hợp lệ" }), { status: 400 });
        }
        room = await ensureLocalRoom(roomId, Array.isArray(players) ? players : null, false, modeId || "2v2");
        if (!room) {
          return new Response(JSON.stringify({ success: false, error: "Cần đủ thông tin 4 người chơi" }), { status: 400 });
        }
        if (!hasSeat(room.state, requestSeat)) {
          return new Response(JSON.stringify({ success: false, error: "Ghế không thuộc phòng đấu" }), { status: 403 });
        }
        return new Response(JSON.stringify({ success: true, state: sanitizeGameStateForClient(room.state, requestSeat || 1) }), {
          headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
        });
      }

      if (!room) room = await ensureLocalRoom(roomId);
      if (!room) {
        return new Response(JSON.stringify({ success: false, error: "Phòng đấu chưa được khởi tạo" }), { status: 404 });
      }

      if (action !== "INIT_GAME" && requestSeat === 0) {
        return new Response(JSON.stringify({ success: false, error: "Ghế không hợp lệ" }), { status: 400, headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" } });
      }
      if (action !== "INIT_GAME" && !hasSeat(room.state, requestSeat)) {
        return new Response(JSON.stringify({ success: false, error: "Ghế không thuộc phòng đấu" }), { status: 403, headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" } });
      }

      if (action === "GET_STATE") {
        const state = room.state;
        return new Response(JSON.stringify({ success: true, state: sanitizeGameStateForClient(state, requestSeat || 1) }), {
          headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
        });
      }

      const outcome = mutateSharedState(roomId, requestSeat, {
        action,
        cardId,
        targetCardId,
        targetSeat,
        targetSeat2,
        targetSeats,
        recast: recast === true,
        skillId,
        accepted,
        cardIds,
        expectedVersion,
      });
      if (outcome.error) {
        return new Response(JSON.stringify({
          success: false,
          error: outcome.error,
          code: outcome.code,
          state: outcome.state ? sanitizeGameStateForClient(outcome.state, requestSeat) : null,
        }), { status: outcome.conflict ? 409 : 400, headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" } });
      }

      if (outcome.committed) {
        updateLocalRoom(roomId, outcome.state);
        broadcastStateUpdate(room, action);
      }

      return new Response(JSON.stringify({ success: true, state: sanitizeGameStateForClient(outcome.state, requestSeat || 1) }), {
        headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
      });
    } catch (err) {
      return new Response(JSON.stringify({ success: false, error: err.message }), { status: 500 });
    }
  }

  // 3. HTTP HEALTH CHECK & DASHBOARD
  let totalConnections = 0;
  for (const r of rooms.values()) {
    totalConnections += r.sockets ? r.sockets.size : 0;
  }

  const uptimeSec = Math.floor((Date.now() - startTime) / 1000);
  return new Response(JSON.stringify({
    status: "online",
    server: "Dai Viet Chien Unified Engine (Deno Deploy)",
    uptime: `${uptimeSec}s`,
    activeRooms: rooms.size,
    activeConnections: totalConnections,
    timestamp: new Date().toISOString(),
  }, null, 2), {
    status: 200,
    headers: { "Content-Type": "application/json; charset=utf-8", "Access-Control-Allow-Origin": "*" },
  });
});



