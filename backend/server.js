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
        if (incomingRev >= currentRev || msg.draft.isCompleted) {
          room.draft.slots = msg.draft.slots;
          room.draft.currentPickerIndex = msg.draft.currentPickerIndex;
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
  "DISCARD_CARDS", "AI_STEP", "AI_REACTION"
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
  47: "Lý Thường Kiệt",
  53: "Trần Quốc Tuấn",
  56: "Trần Quốc Toản",
  68: "Trương Hán Siêu",
  72: "Trần Duệ Tông",
  83: "Nguyễn Cảnh Chân",
  86: "Lê Lợi",
  87: "Nguyễn Trãi",
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
    return handleUseSkill(state, seat, payload.skillId, payload.targetSeat, payload.cardId);
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
  const json = JSON.stringify(messageObj);
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
        } else {
          ws.send(json);
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

function randomTeamSeats() {
  const seats = [1, 2, 3, 4];
  for (let i = seats.length - 1; i > 0; i -= 1) {
    const j = Math.floor(Math.random() * (i + 1));
    [seats[i], seats[j]] = [seats[j], seats[i]];
  }
  return new Set(seats.slice(0, 2));
}

function resolveDraftSeat(room, requestedSeat, payload, socket) {
  const slots = room.draft?.slots || [];
  const normalize = (value) => String(value || "").trim().toLowerCase();
  const userId = normalize(payload.userId);
  const userName = normalize(payload.userName);

  const isAvailable = (slot) => {
    if (!slot) return false;
    const slotUid = normalize(slot.userId);
    const slotName = normalize(slot.userName);
    if (userId && slotUid === userId) return true;
    if (userName && slotName === userName) return true;
    if (!slot.isAI && slotUid && (!userId || slotUid !== userId)) return false;
    const existing = room.sockets.get(slot.seat);
    if (existing && existing !== socket && existing.readyState === WebSocket.OPEN) return false;
    return true;
  };

  // Ưu tiên 1: Explicit debug seat (dành cho multi-instance debug cửa sổ 1, 2, 3, 4 trên cùng máy)
  const debugSeat = Number(payload.debugSeat);
  if (debugSeat >= 1 && debugSeat <= 4) {
    const s = slots.find((e) => e.seat === debugSeat);
    if (isAvailable(s)) return debugSeat;
  }

  // Ưu tiên 2: Khớp chính xác theo userId từ phòng ghép
  const byId = userId
    ? slots.filter((slot) => normalize(slot.userId) === userId)
    : [];
  if (byId.length === 1 && isAvailable(byId[0])) {
    return byId[0].seat;
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

function draftMessage(roomId, draft) {
  const slots = [...draft.slots]
    .sort((a, b) => a.seat - b.seat)
    .map((slot) => ({
      ...slot,
      seatNumber: slot.seat,
      hoverHeroId: slot.hoverHeroId || 0,
      hoverHeroName: slot.hoverHeroName || "",
    }));
  const currentSeat = draft.slots[draft.currentPickerIndex]?.seat || 1;
  const currentPickerIndex = slots.findIndex((slot) => slot.seat === currentSeat);
  return {
    type: "DRAFT_STATE_UPDATE",
    roomId,
    revision: draft.revision || 1,
    currentPickerIndex: currentPickerIndex >= 0 ? currentPickerIndex : draft.currentPickerIndex,
    currentSeat,
    timer: draft.timer,
    slots,
    selectedHeroIds: slots.filter((slot) => slot.isLocked).map((slot) => slot.heroId),
  };
}

function makeDraftSlots(rawSlots, boundSeat, payload) {
  const dragonSeats = randomTeamSeats();
  return [1, 2, 3, 4].map((seat) => {
    const matched = rawSlots.find((slot) => Number(slot?.seatNumber || slot?.seat) === seat) || rawSlots[seat - 1] || {};
    const matchedUid = String(matched.userId || "").trim();
    const isBotUid = matchedUid.startsWith("bot_");
    const isRealUid = matchedUid !== "" && matchedUid !== "empty" && !isBotUid;
    const isAI = isRealUid ? false : (matched.isAI !== undefined ? Boolean(matched.isAI) : (isBotUid || (rawSlots.length > 0 && !matchedUid)));
    const heroId = Number(matched.heroId || matched.hero_id || 0);
    return {
      seat,
      seatNumber: seat,
      userId: String(matched.userId || (isAI ? `bot_${seat}` : (seat === boundSeat ? (payload.userId || `user_${seat}`) : `user_${seat}`))),
      userName: String(matched.userName || (isAI ? `AI Ghế ${seat}` : (seat === boundSeat ? (payload.userName || `Ghế ${seat}`) : `Ghế ${seat}`))),
      isAI,
      isDragon: matched.isDragon !== undefined ? Boolean(matched.isDragon) : dragonSeats.has(seat),
      heroId,
      heroName: String(matched.heroName || ""),
      hoverHeroId: 0,
      hoverHeroName: "",
      maxHp: HERO_MAX_HP[heroId] || 4,
      isLocked: Boolean(matched.isLocked && heroId > 0),
    };
  });
}

function createDraftRoom(roomId, payload, boundSeat) {
  const rawSlots = Array.isArray(payload.slots) ? payload.slots : [];
  const room = {
    state: null,
    draft: {
      roomId,
      slots: makeDraftSlots(rawSlots, boundSeat, payload),
      currentPickerIndex: 0,
      timer: 40,
      timerStartAt: Date.now(),
      lastBroadcastTimer: 40,
      revision: 1,
      isCompleted: false,
      leader: instanceId,
    },
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
  }));
  const state = initGame(roomId, battlePlayers);

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

  const currentSlot = draft.slots[draft.currentPickerIndex];
  if (!currentSlot) {
    finishDraftAndStartBattle(roomId, room);
    return;
  }

  const elapsedMs = Date.now() - draft.timerStartAt;
  const elapsed = Math.floor(elapsedMs / 1000);
  const isSocketOpen = room.sockets.has(currentSlot.seat) && room.sockets.get(currentSlot.seat)?.readyState === WebSocket.OPEN;
  const isBot = Boolean(currentSlot.isAI) || !isSocketOpen;

  // Bot suy nghĩ: hover tướng ở 0.8s để UI sinh động, sau đó khóa ở 1.5s
  if (isBot && !currentSlot.isLocked) {
    const used = new Set(draft.slots.filter((slot) => slot.isLocked).map((slot) => slot.heroId));
    const heroId = Array.from({ length: 28 }, (_, i) => i + 1).find((id) => !used.has(id)) || 1;
    if (elapsedMs >= 800 && (currentSlot.hoverHeroId === 0 || !currentSlot.hoverHeroId)) {
      currentSlot.hoverHeroId = heroId;
      currentSlot.hoverHeroName = getHeroName(heroId);
      broadcastRoom(room, {
        type: "DRAFT_HOVER_UPDATE",
        roomId,
        seat: currentSlot.seat,
        heroId,
        heroName: currentSlot.hoverHeroName,
      });
    }
  }

  // Khóa tướng: Bot thực sự khóa sau 1.5s; Slot mất kết nối khóa sau 5s; Người chơi bình thường có 40s
  const botThresholdSec = Boolean(currentSlot.isAI) ? 1.5 : (isSocketOpen ? 40.0 : 5.0);
  if ((elapsedMs >= botThresholdSec * 1000 || elapsed >= 40) && !currentSlot.isLocked) {
    const used = new Set(draft.slots.filter((slot) => slot.isLocked).map((slot) => slot.heroId));
    const heroId = currentSlot.hoverHeroId > 0 && !used.has(currentSlot.hoverHeroId)
      ? currentSlot.hoverHeroId
      : (Array.from({ length: 28 }, (_, i) => i + 1).find((id) => !used.has(id)) || 1);
    currentSlot.heroId = heroId;
    currentSlot.heroName = getHeroName(heroId);
    currentSlot.hoverHeroId = 0;
    currentSlot.hoverHeroName = "";
    currentSlot.maxHp = HERO_MAX_HP[heroId] || 4;
    currentSlot.isLocked = true;
    draft.currentPickerIndex += 1;
    draft.timerStartAt = Date.now();
    draft.timer = 40;
    draft.lastBroadcastTimer = 40;
    draft.revision = (draft.revision || 0) + 1;
    room.lastActivity = Date.now();
    if (draft.currentPickerIndex >= draft.slots.length) {
      finishDraftAndStartBattle(roomId, room);
      return;
    }
    broadcastRoom(room, draftMessage(roomId, draft));
    clusterBroadcast({ type: "DRAFT_SYNC", roomId, draft });
    return;
  } else {
    draft.timer = Math.max(0, 40 - elapsed);
  }

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
          const fresh = !room || room.draft?.isCompleted || (noActiveSockets && Date.now() - room.lastActivity > 15000);
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
          const currentSlot = room.draft.slots[room.draft.currentPickerIndex];
          if (!currentSlot || currentSlot.seat !== boundSeat) {
            return socket.send(JSON.stringify({ type: "ERROR", error: "Chưa đến lượt bạn chọn tướng" }));
          }
          const heroId = Number(payload.heroId || payload.hero_id || 0);
          if (!Number.isInteger(heroId) || heroId < 1 || heroId > 100) {
            return socket.send(JSON.stringify({ type: "ERROR", error: "Tướng không hợp lệ" }));
          }
          const selectedHeroIds = room.draft.slots.filter((entry) => entry.isLocked).map((entry) => entry.heroId);
          if (selectedHeroIds.includes(heroId)) {
            return socket.send(JSON.stringify({ type: "ERROR", error: "Tướng này đã được chọn" }));
          }
          currentSlot.heroId = heroId;
          currentSlot.heroName = String(payload.heroName || getHeroName(heroId));
          currentSlot.hoverHeroId = 0;
          currentSlot.hoverHeroName = "";
          currentSlot.maxHp = HERO_MAX_HP[heroId] || 4;
          currentSlot.isLocked = true;
          room.draft.currentPickerIndex += 1;
          room.draft.timer = 40;
          room.draft.timerStartAt = Date.now();
          room.draft.lastBroadcastTimer = 40;
          room.draft.revision = (room.draft.revision || 0) + 1;
          room.lastActivity = Date.now();
          if (room.draft.currentPickerIndex >= room.draft.slots.length) {
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
            broadcastRoom(room, {
              type: "DRAFT_HOVER_UPDATE",
              roomId,
              seat: targetSeat,
              heroId,
              heroName,
            });
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



