/**
 * ĐẠI VIỆT CHIẾN - UNIFIED REALTIME & REST GAME SERVER (DENO DEPLOY)
 * 100% In-Memory WebSocket Realtime (<15ms) trên RAM
 */
import {
  initGame,
  checkVersion,
  handlePlayCard,
  handleRespondAction,
  handleEndTurn,
  handleDiscardCards,
  handleAIStep,
  handleAIReaction,
  handleToggleSkill,
  handleUseSkill,
  tickGameState,
  fastForwardMatchForDeadPlayer,
  sanitizeGameStateForClient,
  ensureMutationVersion,
} from "./functions/game-engine/src/gameEngine.js";
import { HERO_MAX_HP } from "./functions/game-engine/src/heroes.js";
import { getModeRules } from "./functions/game-engine/src/modeRegistry.js";

export interface DraftSlot {
  seat: number;
  userId: string;
  userName: string;
  isAI: boolean;
  isDragon: boolean;
  heroId: number;
  heroName: string;
  maxHp: number;
  isLocked: boolean;
  availableHeroIds?: number[];
  candidateHeroIds?: number[];
  role?: string;
}

export interface DraftState {
  roomId: string;
  modeId?: string;
  slots: DraftSlot[];
  currentPickerIndex: number;
  timer: number;
  timerStartAt: number;
  // Monotonic snapshot number lets clients discard delayed/out-of-order frames.
  revision: number;
  isCompleted: boolean;
  availableHeroIds?: number[];
}

// Bộ nhớ In-Memory lưu trữ toàn bộ các phòng đấu đang diễn ra trên RAM
interface RoomData {
  state: any;
  draft?: DraftState;
  sockets: Map<number, WebSocket>;
  lastActivity: number;
}

function arrangeDraftSlots(slots: any[], modeId: string): any[] {
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

function draftRoles(modeId: string): string[] {
  return modeId === "dynasty_5" ? ["KING", "LOYALIST", "REBEL", "REBEL", "SPY"] : (modeId === "dynasty_8" ? ["KING", "LOYALIST", "REBEL", "REBEL", "SPY", "LOYALIST", "REBEL", "REBEL"] : []);
}

function isDynastyDraft(draft: DraftState | undefined): boolean {
  return String(draft?.modeId || "").startsWith("dynasty_");
}

const rooms = new Map<string, RoomData>();
const instanceId = `node_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`;
const clusterChannel = typeof BroadcastChannel !== "undefined" ? new BroadcastChannel("dvc_cluster_bus") : null;

function clusterBroadcast(data: any) {
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
        }
      }
      room.lastActivity = Date.now();
      if (room.draft && !room.draft.isCompleted) {
        broadcastRoom(room, draftStateMessage(roomId, room.draft));
      }
    }

    if (type === "DRAFT_HOVER_SYNC") {
      let room = rooms.get(roomId);
      if (room?.draft) {
        const slot = room.draft.slots.find((s: any) => s.seat === msg.seat);
        if (slot && !slot.isLocked) {
          (slot as any).hoverHeroId = msg.heroId;
          (slot as any).hoverHeroName = msg.heroName;
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
          state: room.state,
        });
      }
    }

    if (type === "GAME_STATE_SYNC" && msg.state) {
      let room = rooms.get(roomId);
      if (room) {
        room.state = msg.state;
        room.lastActivity = Date.now();
        broadcastRoom(room, {
          type: "STATE_UPDATE",
          state: room.state,
          delta: null,
          version: room.state.version,
          action: msg.action || "STATE_UPDATE",
        });
      }
    }
  };
}
interface MatchmakingRoom {
  roomId: string;
  hostUserId: string;
  status: string;
  version: number;
  hostRankPoints: number;
  createdAt: number;
  updatedAt: number;
  slots: any[];
}
const matchmakingRooms = new Map<string, MatchmakingRoom>();
const startTime = Date.now();
const MAX_WS_MESSAGE_BYTES = 64 * 1024;
const MAX_ACTIONS_PER_SECOND = 30;
const ALLOWED_WS_ACTIONS = new Set([
  "JOIN_ROOM", "INIT_GAME", "JOIN_DRAFT", "PICK_HERO", "HOVER_HERO", "GET_STATE", "PING",
  "USE_SKILL", "TOGGLE_SKILL", "PLAY_CARD", "RESPOND_ACTION", "END_TURN",
  "DISCARD_CARDS", "AI_STEP", "AI_REACTION", "FAST_FORWARD_MATCH"
]);

function matchmakingJson(data: any, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json; charset=utf-8", "Access-Control-Allow-Origin": "*" },
  });
}

function cleanupMatchmakingRooms() {
  const now = Date.now();
  for (const [id, room] of matchmakingRooms) {
    if ((room.status === "WAITING" && now - room.updatedAt > 180000) || now - room.updatedAt > 900000) {
      matchmakingRooms.delete(id);
    }
  }
}

function findMatchmakingRoom(userId: string, rankPoints: number, maxRankDiff: number) {
  cleanupMatchmakingRooms();
  let best: MatchmakingRoom | null = null;
  let bestDiff = Number.MAX_SAFE_INTEGER;
  for (const room of matchmakingRooms.values()) {
    if (room.status !== "WAITING") continue;
    if (room.slots.some((slot) => !slot.isEmpty && slot.userId === userId)) continue;
    if (!room.slots.some((slot) => slot.isEmpty)) continue;
    const diff = Math.abs(Number(room.hostRankPoints) - rankPoints);
    if (diff <= maxRankDiff && diff < bestDiff) {
      best = room;
      bestDiff = diff;
    }
  }
  return best;
}

function isValidMatchmakingRoom(room: any): boolean {
  return !!room && typeof room.roomId === "string" && room.roomId.length > 0 && room.roomId.length <= 128
    && typeof room.hostUserId === "string" && Array.isArray(room.slots) && room.slots.length === 4;
}

function isEmptyMatchSlot(slot: any): boolean {
  return !slot || slot.isEmpty === true || !slot.userId;
}

function validateClientPayload(payload: any, rawBytes: number): string | null {
  if (!payload || typeof payload !== "object" || Array.isArray(payload)) return "Gói tin không hợp lệ";
  if (rawBytes > MAX_WS_MESSAGE_BYTES) return "Gói tin vượt giới hạn cho phép";
  if (typeof payload.action !== "string" || !ALLOWED_WS_ACTIONS.has(payload.action)) return "Hành động không hợp lệ";
  if (payload.roomId !== undefined && (typeof payload.roomId !== "string" || payload.roomId.length > 128)) return "Mã phòng không hợp lệ";
  for (const key of ["cardId", "targetCardId", "skillId", "heroName", "userId", "userName", "phaTongCardId", "phaTongCostCardId"]) {
    if (payload[key] !== undefined && typeof payload[key] === "number") payload[key] = String(payload[key]);
    if (payload[key] !== undefined && (typeof payload[key] !== "string" || payload[key].length > 256)) return `${key} không hợp lệ`;
  }
  for (const key of ["seat", "targetSeat", "targetSeat2", "expectedVersion"]) {
    if (payload[key] !== undefined && (!Number.isInteger(Number(payload[key])) || Number(payload[key]) < 0)) return `${key} không hợp lệ`;
  }
  if (payload.cardIds !== undefined && (!Array.isArray(payload.cardIds) || payload.cardIds.length > 20 || payload.cardIds.some((id: any) => typeof id !== "string" || id.length > 256))) return "Danh sách lá bài không hợp lệ";
  if (payload.targetSeats !== undefined && (!Array.isArray(payload.targetSeats) || payload.targetSeats.length > 8)) return "Danh sách mục tiêu không hợp lệ";
  if (payload.players !== undefined && (!Array.isArray(payload.players) || payload.players.length > 8)) return "Danh sách người chơi không hợp lệ";
  return null;
}

console.log("🎮 [Deno Server] Đại Việt Chiến 2v2 Unified Game Server is running!");

const HERO_NAME_MAP: Record<number, string> = {
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
  100: "Bùi Quốc Hưng"
};

function getHeroName(heroId: number): string {
  return HERO_NAME_MAP[heroId] || `Chiến Tướng #${heroId}`;
}

const DEFAULT_HERO_POOL = Array.from({ length: 40 }, (_, i) => i + 1);

function generate2v2CandidatePool(draft: DraftState, slot: any) {
  if (isDynastyDraft(draft) || !slot || slot.isLocked) return;
  const locked = new Set(draft.slots.filter((s) => s.isLocked).map((s) => Number(s.heroId)));
  const requested = [...(draft.availableHeroIds || []), ...(slot.availableHeroIds || [])];
  const own = new Set((slot.availableHeroIds || []).map(Number));
  const source = Array.from(new Set(requested.length > 0 ? requested : DEFAULT_HERO_POOL))
    .map(Number).filter((id) => Number.isInteger(id) && id >= 1 && id <= 40 && !locked.has(id) && (own.size === 0 || own.has(id)));
  for (let i = source.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [source[i], source[j]] = [source[j], source[i]];
  }
  slot.candidateHeroIds = source.slice(0, 8);
}

function generate2v2CandidateForCurrent(draft: DraftState) {
  if (isDynastyDraft(draft)) return;
  const slot = draft.slots[draft.currentPickerIndex];
  if (slot && !slot.isLocked) generate2v2CandidatePool(draft, slot);
}

function getAutoPickHeroId(excludeIds: number[]): number {
  for (const id of DEFAULT_HERO_POOL) {
    if (!excludeIds.includes(id)) return id;
  }
  for (let id = 1; id <= 84; id++) {
    if (!excludeIds.includes(id)) return id;
  }
  return 1;
}

function randomTeamSeats(count = 4): Set<number> {
  const seats = Array.from({ length: count }, (_, index) => index + 1);
  for (let i = seats.length - 1; i > 0; i -= 1) {
    const j = Math.floor(Math.random() * (i + 1));
    [seats[i], seats[j]] = [seats[j], seats[i]];
  }
  return new Set(seats.slice(0, 2));
}

function draftStateMessage(roomId: string, draft: DraftState) {
  // Always publish seats in canonical order so all clients apply the same
  // picker index even when their matchmaking snapshots arrived in a different order.
  const slots = [...draft.slots]
    .sort((a, b) => a.seat - b.seat)
    .map((slot) => ({
      ...slot,
      seatNumber: slot.seat,
      hoverHeroId: (slot as any).hoverHeroId || 0,
      hoverHeroName: (slot as any).hoverHeroName || "",
      candidateHeroIds: (slot as any).candidateHeroIds || [],
    }));
  const currentSeat = draft.slots[draft.currentPickerIndex]?.seat || 1;
  const currentPickerIndex = slots.findIndex((slot) => slot.seat === currentSeat);
  return {
    type: "DRAFT_STATE_UPDATE",
    roomId,
    revision: draft.revision,
    currentPickerIndex: currentPickerIndex >= 0 ? currentPickerIndex : draft.currentPickerIndex,
    currentSeat,
    timer: draft.timer,
    slots,
    selectedHeroIds: slots.filter((slot) => slot.isLocked).map((slot) => slot.heroId)
  };
}

function finishDraftAndStartBattle(roomId: string, room: RoomData) {
  if (!room.draft) return;
  room.draft.isCompleted = true;
  const battlePlayers = room.draft.slots.map(s => ({
    seat: s.seat,
    userId: s.userId,
    heroId: `HERO_${s.heroId}`,
    generalName: s.heroName || getHeroName(s.heroId),
    maxHp: HERO_MAX_HP[s.heroId] || 4,
    hp: HERO_MAX_HP[s.heroId] || 4,
    isAlly: s.isDragon,
    isAI: s.isAI,
    role: s.role || ""
  }));

  room.state = initGame(roomId, battlePlayers, room.draft.modeId || "2v2");
  console.log(`[Deno Server] Chọn tướng hoàn tất phòng: ${roomId}! Bắt đầu trận đấu 2v2!`);

  clusterBroadcast({
    type: "DRAFT_COMPLETED_SYNC",
    roomId,
    slots: room.draft.slots,
    battlePlayers,
  });
  broadcastRoom(room, {
    type: "DRAFT_COMPLETED",
    roomId,
    slots: room.draft.slots,
    battlePlayers,
    state: room.state
  });
}

// Dynamic Tick Timer: Only runs when active rooms exist, allowing Deno to scale to 0 CPU when idle
let tickTimer: ReturnType<typeof setInterval> | null = null;

function ensureTickTimer() {
  if (tickTimer !== null) return;
  tickTimer = setInterval(() => {
    if (rooms.size === 0) {
      if (tickTimer !== null) {
        clearInterval(tickTimer);
        tickTimer = null;
      }
      return;
    }
    const now = Date.now();
    for (const [roomId, room] of rooms.entries()) {
      // Dọn dẹp phòng đã kết thúc hoặc không hoạt động quá 15 phút
      if ((!room?.state && !room?.draft) || (room.state && room.state.status === "FINISHED") || (now - room.lastActivity > 900000)) {
        rooms.delete(roomId);
        continue;
      }

      // 1. Tick giai đoạn DRAFT (Chọn Tướng)
      if (room.draft && !room.draft.isCompleted) {
        const draft = room.draft;
        const draftElapsed = Math.floor((now - (draft.timerStartAt || now)) / 1000);
        const newDraftTimer = Math.max(0, 40 - draftElapsed);
        const timerChanged = draft.timer !== newDraftTimer;
        draft.timer = newDraftTimer;
        room.lastActivity = now;

        const dynastyReady = isDynastyDraft(draft) && Boolean(draft.slots[0]?.isLocked);
        const indexes = dynastyReady
          ? draft.slots.map((_, index) => index).filter(index => index > 0 && !draft.slots[index].isLocked)
          : [draft.currentPickerIndex];
        let changed = false;
        for (const index of indexes) {
          const currentSlot = draft.slots[index];
          if (!currentSlot || currentSlot.isLocked) continue;
          const hasHumanSocket = room.sockets.has(currentSlot.seat);
          const isBot = Boolean(currentSlot.isAI) && !hasHumanSocket;
          const shouldAutoPick = (draft.timer <= 0) || (isBot && draft.timer <= 30);
          if (!shouldAutoPick) continue;
          const lockedIds = draft.slots.filter(s => s.isLocked).map(s => s.heroId);
          const candidateIds = ((currentSlot as any).candidateHeroIds || []).filter((id: number) => !lockedIds.includes(id));
          const autoHeroId = candidateIds.length > 0
            ? candidateIds[Math.floor(Math.random() * candidateIds.length)]
            : getAutoPickHeroId(lockedIds);
          currentSlot.heroId = autoHeroId;
          currentSlot.heroName = getHeroName(autoHeroId);
          (currentSlot as any).hoverHeroId = 0;
          (currentSlot as any).hoverHeroName = "";
          currentSlot.isLocked = true;
          changed = true;
          console.log(`[Deno Draft AutoPick] Ghế ${currentSlot.seat} (${isBot ? "Bot" : "Timeout"}) đã tự chọn tướng ${currentSlot.heroName} (#${autoHeroId})`);
        }
        if (changed) {
          if (!dynastyReady) draft.currentPickerIndex++;
          if (!dynastyReady) generate2v2CandidateForCurrent(draft);
          if (!dynastyReady) {
            draft.timer = 40;
            draft.timerStartAt = now;
          }
          draft.revision += 1;
          if (draft.slots.every(s => s.isLocked && s.heroId > 0)) {
            finishDraftAndStartBattle(roomId, room);
            continue;
          }
          broadcastRoom(room, draftStateMessage(roomId, draft));
          clusterBroadcast({ type: "DRAFT_SYNC", roomId, draft });
        } else if (timerChanged) {
          draft.revision += 1;
          broadcastRoom(room, draftStateMessage(roomId, draft));
          clusterBroadcast({ type: "DRAFT_SYNC", roomId, draft });
        }
        continue;
      }

      // 2. Tick giai đoạn BATTLE (Trận Đấu) - Đồng bộ phản ứng nhanh nhạy cho cả 4 người chơi
      if (room.state) {
        try {
          const connectedSeats = Array.from(room.sockets.keys());
          const startingActionSeq = room.state.actionSeq || 0;
          const tickRes = (tickGameState as any)(room.state, connectedSeats);
          if (tickRes?.changed || tickRes?.important) {
            room.lastActivity = now;
            const hasNewAction = (room.state.actionSeq || 0) > startingActionSeq;
            const tickDelta = hasNewAction ? (room.state.lastDelta || null) : null;
            broadcastRoom(room, {
              type: "STATE_UPDATE",
              state: room.state,
              delta: tickDelta,
              version: room.state.version,
              action: "SERVER_TICK",
            });
            if (tickDelta) {
              room.state.lastDelta = null;
            }
            // 100% In-Memory RAM: Không gọi Appwrite trong trận đấu
          }
        } catch (err) {
          console.error(`[Tick Error room ${roomId}]:`, err);
        }
      }
    }
  }, 250);
}

function broadcastRoom(room: RoomData, messageObj: any) {
  for (const [seat, ws] of room.sockets.entries()) {
    if (ws.readyState === WebSocket.OPEN) {
      try {
        // Any broadcast carrying game state must hide other players' hands.
        if (messageObj.state && room.state) {
          const sanitizedState = sanitizeGameStateForClient(room.state, seat);
          const personalized = {
            ...messageObj,
            state: sanitizedState,
          };
          ws.send(JSON.stringify(personalized));
        } else if (messageObj.type === "DRAFT_STATE_UPDATE") {
          const safeSlots = (messageObj.slots || []).map((slot: any) => { const { role, heroId, heroName, hoverHeroId, hoverHeroName, candidateHeroIds, ...publicSlot } = slot; const own = slot.seat === seat; return { ...publicSlot, role: own ? (role || "") : undefined, heroId: own || (slot.isLocked && heroId > 0) ? heroId : 0, heroName: own || (slot.isLocked && heroId > 0) ? heroName : "", hoverHeroId: own ? (hoverHeroId || 0) : 0, hoverHeroName: own ? (hoverHeroName || "") : "", candidateHeroIds: own ? (candidateHeroIds || []) : [] }; });
          const safeMessage: any = { ...messageObj, slots: safeSlots };
          if (String(room.draft?.modeId || "").startsWith("dynasty_")) {
            const own = safeSlots.find((slot: any) => slot.seat === seat);
            safeMessage.selectedHeroIds = own && own.heroId > 0 ? [own.heroId] : [];
          }
          ws.send(JSON.stringify(safeMessage));
        } else if (messageObj.type === "DRAFT_COMPLETED") {
          const safeSlots = (messageObj.slots || []).map((slot: any) => { const { role, ...publicSlot } = slot; return { ...publicSlot, role: slot.seat === seat ? (role || "") : undefined }; });
          ws.send(JSON.stringify({ ...messageObj, slots: safeSlots }));
        } else {
          ws.send(JSON.stringify(messageObj));
        }
      } catch (e) {
        console.error(`[Broadcast error seat ${seat}]:`, e);
      }
    }
  }
}

function normalizeSeat(value: unknown): number {
  const seat = Number(value);
  return Number.isInteger(seat) && seat >= 1 && seat <= 8 ? seat : 0;
}

function hasSeat(target: any, seat: number): boolean {
  if (!target) return false;
  if (target.draft) {
    return !!target.draft.slots?.some((s: any) => s.seat === seat);
  }
  if (target.players) {
    return !!target.players?.some((player: any) => player.seat === seat);
  }
  if (target.state?.players) {
    return !!target.state.players?.some((player: any) => player.seat === seat);
  }
  return false;
}

/** Bind one socket to one immutable room/seat identity. */
function bindSocket(room: RoomData, seat: number, socket: WebSocket): void {
  for (const [mappedSeat, mappedSocket] of room.sockets.entries()) {
    if (mappedSocket === socket && mappedSeat !== seat) room.sockets.delete(mappedSeat);
  }
  const previousSocket = room.sockets.get(seat);
  if (previousSocket && previousSocket !== socket) {
    try { previousSocket.close(1000, "Seat reconnected"); } catch { /* already closed */ }
  }
  room.sockets.set(seat, socket);
}

function resolveDraftSeat(room: RoomData, requestedSeat: number, payload: any, socket: WebSocket): number {
  const slots = room.draft?.slots || [];
  const normalize = (value: unknown) => String(value || "").trim().toLowerCase();

  const userId = normalize(payload.userId);
  const userName = normalize(payload.userName);
  const byId = userId ? slots.filter((slot: any) => normalize(slot.userId) === userId) : [];
  if (byId.length === 1) {
    const existingSocket = room.sockets.get(byId[0].seat);
    if (!existingSocket || existingSocket === socket || existingSocket.readyState !== WebSocket.OPEN) {
      return byId[0].seat;
    }
  }

  // Next priority: requested assigned seat
  if (requestedSeat >= 1 && requestedSeat <= slots.length) {
    const existingSocket = room.sockets.get(requestedSeat);
    if (!existingSocket || existingSocket === socket || existingSocket.readyState !== WebSocket.OPEN) {
      return requestedSeat;
    }
  }

  const debugSeat = Number(payload.debugSeat);
  if (debugSeat >= 1 && debugSeat <= slots.length) {
    const existingSocket = room.sockets.get(debugSeat);
    if (!existingSocket || existingSocket === socket || existingSocket.readyState !== WebSocket.OPEN) {
      return debugSeat;
    }
  }

  const byName = userName ? slots.filter((slot: any) => normalize(slot.userName) === userName) : [];
  if (byName.length === 1) {
    const existingSocket = room.sockets.get(byName[0].seat);
    if (!existingSocket || existingSocket === socket || existingSocket.readyState !== WebSocket.OPEN) {
      return byName[0].seat;
    }
  }

  // Duplicate debug identities or extra players use the requested per-window seat if available.
  if (!room.sockets.has(requestedSeat) || room.sockets.get(requestedSeat) === socket || room.sockets.get(requestedSeat)?.readyState !== WebSocket.OPEN) {
    return requestedSeat;
  }
  return slots.find((slot: any) => {
    const s = room.sockets.get(slot.seat);
    return !s || s.readyState !== WebSocket.OPEN;
  })?.seat || 0;
}

const port = Number(Deno.env.get("PORT")) || 8080;
const hostname = Deno.env.get("HOST") || "0.0.0.0";
Deno.serve({ port, hostname }, async (req) => {
  const upgrade = req.headers.get("upgrade") || "";

  // 1. WEBSOCKET REALTIME CONNECTION (<15ms)
  if (upgrade.toLowerCase() === "websocket") {
    const { socket, response } = Deno.upgradeWebSocket(req);

    let currentRoomId: string | null = null;
    let currentSeat = 0;
    let rateWindowStartedAt = Date.now();
    let rateWindowCount = 0;

    socket.onopen = () => {};

    socket.onmessage = (event) => {
      try {
        const raw = typeof event.data === "string" ? event.data : String(event.data || "");
        const rawBytes = new TextEncoder().encode(raw).length;
        if (rawBytes > MAX_WS_MESSAGE_BYTES) { socket.close(1009, "Message too big"); return; }
        const payload = JSON.parse(raw);
        const payloadError = validateClientPayload(payload, rawBytes);
        if (payloadError) return socket.send(JSON.stringify({ type: "ERROR", error: payloadError }));
        if (payload.action !== "PING") {
          const now = Date.now();
          if (now - rateWindowStartedAt >= 1000) { rateWindowStartedAt = now; rateWindowCount = 0; }
          if (++rateWindowCount > MAX_ACTIONS_PER_SECOND) return socket.send(JSON.stringify({ type: "ERROR", error: "Gửi hành động quá nhanh, vui lòng chờ một chút" }));
        }
        const { action, roomId, cardId, targetCardId, targetSeat, accepted, cardIds, players, modeId, expectedVersion } = payload;
        const requestSeat = normalizeSeat(payload.seat);

        if (!roomId) {
          return socket.send(JSON.stringify({ type: "ERROR", error: "Thiếu roomId" }));
        }

        const isJoinAction = action === "JOIN_ROOM" || action === "INIT_GAME" || action === "JOIN_DRAFT";
        if (isJoinAction) {
          if (requestSeat === 0) {
            return socket.send(JSON.stringify({ type: "ERROR", error: "Ghế không hợp lệ" }));
          }
          if (currentRoomId !== null && currentRoomId !== roomId) {
            const oldRoom = rooms.get(currentRoomId);
            if (oldRoom && oldRoom.sockets && oldRoom.sockets.get(currentSeat) === socket) {
              oldRoom.sockets.delete(currentSeat);
            }
            currentRoomId = null;
            currentSeat = 0;
          }
        } else {
          if (currentRoomId === null) {
            return socket.send(JSON.stringify({ type: "ERROR", error: "Kết nối chưa tham gia phòng" }));
          }
          if (roomId !== currentRoomId || (requestSeat !== 0 && requestSeat !== currentSeat)) {
            return socket.send(JSON.stringify({ type: "ERROR", error: "Kết nối đã được khóa vào phòng khác" }));
          }
        }

        const boundSeat = currentRoomId !== null ? currentSeat : requestSeat;

        let room = rooms.get(roomId);

        // A.0. THAM GIA HOẶC KHỞI TẠO CHỌN TƯỚNG (DRAFT)
        if (action === "JOIN_DRAFT") {
          const requestedModeId = String(payload.modeId || "2v2");
          const requestedSeatCount = requestedModeId === "dynasty_5" ? 5 : (requestedModeId === "dynasty_8" ? 8 : 4);
          const draftShapeChanged = !!room?.draft && (String(room.draft.modeId || "2v2") !== requestedModeId || room.draft.slots.length !== requestedSeatCount);
          const isFreshDraft = !room || draftShapeChanged || (!room.draft?.isCompleted && room.state?.status === "FINISHED");
          if (isFreshDraft) {
            const rawSlots = Array.isArray(payload.slots) ? payload.slots : [];
            const modeId = String(payload.modeId || "2v2");
            const seatCount = modeId === "dynasty_5" ? 5 : (modeId === "dynasty_8" ? 8 : 4);
            const dragonSeats = randomTeamSeats(seatCount);
            const defaultSlots: DraftSlot[] = arrangeDraftSlots(Array.from({ length: seatCount }, (_, index) => index + 1).map((s) => {
              const matched = rawSlots.find((x: any) => Number(x.seatNumber || x.seat) === s) || rawSlots[s - 1] || {};
              const matchedUid = String(matched.userId || "").trim();
              const isBotUid = matchedUid.startsWith("bot_");
              const isRealUid = matchedUid !== "" && matchedUid !== "empty" && !isBotUid;
              const isAI = isRealUid ? false : (matched.isAI !== undefined ? Boolean(matched.isAI) : (isBotUid || (rawSlots.length > 0 && !matchedUid)));
              return {
                seat: s,
                seatNumber: s,
                userId: String(matched.userId || (isAI ? `bot_${s}` : (s === boundSeat ? (payload.userId || `user_${s}`) : `user_${s}`))),
                userName: String(matched.userName || (isAI ? `AI Ghế ${s}` : (s === boundSeat ? (payload.userName || `Ghế ${s}`) : `Ghế ${s}`))),
                isAI: isAI,
                role: "",
                isDragon: matched.isDragon !== undefined ? Boolean(matched.isDragon) : dragonSeats.has(s),
                availableHeroIds: Array.isArray(matched.availableHeroIds) ? matched.availableHeroIds.map(Number).filter((id: number) => Number.isInteger(id) && id >= 1 && id <= 40) : [],
                heroId: Number(matched.heroId || 0),
                heroName: String(matched.heroName || ""),
                maxHp: HERO_MAX_HP[Number(matched.heroId || 0)] || 4,
                isLocked: Boolean(matched.isLocked || false)
              };
            }), modeId);

            if (!room) {
              room = {
                state: null,
                draft: {
                  roomId,
                  modeId,
                  slots: defaultSlots,
                  currentPickerIndex: 0,
                  timer: 40,
                  timerStartAt: Date.now(),
                  revision: 1,
                  isCompleted: false,
                  availableHeroIds: Array.isArray(payload.availableHeroIds) ? payload.availableHeroIds.map(Number) : []
                },
                sockets: new Map(),
                lastActivity: Date.now()
              };
              rooms.set(roomId, room);
            } else {
              room.state = null;
              room.draft = {
                roomId,
                modeId,
                slots: defaultSlots,
                currentPickerIndex: 0,
                timer: 40,
                timerStartAt: Date.now(),
                revision: 1,
                isCompleted: false,
                availableHeroIds: Array.isArray(payload.availableHeroIds) ? payload.availableHeroIds.map(Number) : []
              };
              room.lastActivity = Date.now();
            }
            if (room.draft) generate2v2CandidateForCurrent(room.draft);
            ensureTickTimer();
            console.log(`[Deno WS] Khởi tạo phòng DRAFT mới: ${roomId}`);
          }

          if (!room) {
            return socket.send(JSON.stringify({ type: "ERROR", error: "Không thể khởi tạo phòng chọn tướng" }));
          }

          const draftSeat = currentRoomId === null
            ? resolveDraftSeat(room, boundSeat, payload, socket)
            : boundSeat;
          if (!draftSeat) {
            return socket.send(JSON.stringify({ type: "ERROR", error: "Phòng đã đủ 4 ghế" }));
          }

          if (room.draft) {
            const slot = room.draft.slots.find((s: any) => s.seat === draftSeat);
            if (slot) {
              if (payload.userId) slot.userId = String(payload.userId);
              if (payload.userName) slot.userName = String(payload.userName);
              if (Array.isArray(payload.availableHeroIds)) slot.availableHeroIds = payload.availableHeroIds.map(Number).filter((id: number) => Number.isInteger(id) && id >= 1 && id <= 40);
              if (!room.draft.availableHeroIds?.length && slot.availableHeroIds?.length) room.draft.availableHeroIds = slot.availableHeroIds.slice();
              generate2v2CandidateForCurrent(room.draft!);
              slot.isAI = false; // Người thật đã vào ghế
            }
            room.draft.revision += 1;
          }

          currentRoomId = roomId;
          currentSeat = draftSeat;
          bindSocket(room, currentSeat, socket);
          room.lastActivity = Date.now();
          socket.send(JSON.stringify({ type: "DRAFT_JOINED", roomId, seat: draftSeat, assignedSeat: draftSeat }));
          console.log(`[Deno WS] Ghế ${currentSeat} kết nối phòng DRAFT: ${roomId} (Sockets: ${room.sockets.size})`);

          if (room.draft && !room.draft.isCompleted) {
            broadcastRoom(room, draftStateMessage(roomId, room.draft));
            clusterBroadcast({ type: "DRAFT_SYNC", roomId, draft: room.draft });
          } else if (room.state) {
            socket.send(JSON.stringify({
              type: "DRAFT_COMPLETED",
              roomId,
              slots: room.draft ? room.draft.slots : [],
              battlePlayers: room.state.players,
              state: sanitizeGameStateForClient(room.state, currentSeat)
            }));
          }
          return;
        }

        // A.0.1. NGƯỜI CHƠI KHÓA TƯỚNG (PICK_HERO)
        if (action === "PICK_HERO") {
          if (!room || !room.draft || room.draft.isCompleted) {
            return socket.send(JSON.stringify({ type: "ERROR", error: "Không trong giai đoạn chọn tướng" }));
          }
          const draft = room.draft;
          const currentSlot = draft.slots[draft.currentPickerIndex];
          const dynastyReady = isDynastyDraft(draft) && draft.slots[0]?.isLocked;
          const requestedSlot = draft.slots.find((slot: any) => slot.seat === boundSeat);
          if ((!dynastyReady && (!currentSlot || currentSlot.seat !== boundSeat)) || (dynastyReady && (!requestedSlot || requestedSlot.seat === 1 || requestedSlot.isLocked))) {
            return socket.send(JSON.stringify({ type: "ERROR", error: "Chưa đến lượt bạn chọn tướng" }));
          }

          const heroId = Number(payload.heroId || payload.hero_id || 0);
          if (heroId <= 0) {
            return socket.send(JSON.stringify({ type: "ERROR", error: "Tướng không hợp lệ" }));
          }

          const selectedHeroIds = draft.slots.filter((s: any) => s.isLocked).map((s: any) => s.heroId);
          if (!isDynastyDraft(draft) && selectedHeroIds.includes(heroId)) {
            return socket.send(JSON.stringify({ type: "ERROR", error: "Tướng này đã được chọn" }));
          }

          if (!isDynastyDraft(draft) && Array.isArray((requestedSlot as any)?.candidateHeroIds) && !(requestedSlot as any).candidateHeroIds.includes(heroId)) {
            return socket.send(JSON.stringify({ type: "ERROR", error: "Tướng này không nằm trong bể tướng của bạn" }));
          }

          const pickedSlot = dynastyReady ? requestedSlot : currentSlot;
          if (!pickedSlot) {
            return socket.send(JSON.stringify({ type: "ERROR", error: "Ghế chọn tướng không hợp lệ" }));
          }
          pickedSlot.heroId = heroId;
          pickedSlot.heroName = payload.heroName || getHeroName(heroId);
          (pickedSlot as any).hoverHeroId = 0;
          (pickedSlot as any).hoverHeroName = "";
          pickedSlot.maxHp = HERO_MAX_HP[heroId] || 4;
          pickedSlot.isLocked = true;

          if (!dynastyReady) draft.currentPickerIndex++;
          if (!dynastyReady) {
            draft.timer = 40;
            draft.timerStartAt = Date.now();
          }
          draft.revision += 1;

          console.log(`[Deno WS] Ghế ${boundSeat} đã khóa [${currentSlot.heroName}] (#${heroId}) trong phòng ${roomId}`);

          if (draft.slots.every((s: any) => s.isLocked && s.heroId > 0)) {
            finishDraftAndStartBattle(roomId, room);
          } else {
            broadcastRoom(room, draftStateMessage(roomId, draft));
            clusterBroadcast({ type: "DRAFT_SYNC", roomId, draft });
          }
          return;
        }

        // A.0.2. XEM TRƯỚC / RÊ CHUỘT CHỌN TƯỚNG (HOVER_HERO)
        if (action === "HOVER_HERO") {
          if (!room || !room.draft || room.draft.isCompleted) return;
          const heroId = Number(payload.heroId || payload.hero_id || 0);
          const heroName = String(payload.heroName || getHeroName(heroId) || "");
          const targetSeat = currentSeat || boundSeat || Number(payload.seat || 0);
          const slot = room.draft.slots.find((s: any) => s.seat === targetSeat);
          if (slot && !slot.isLocked) {
            (slot as any).hoverHeroId = heroId;
            (slot as any).hoverHeroName = heroName;
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

        // A. KHỞI TẠO HOẶC THAM GIA PHÒNG ĐẤU (BATTLE)
        if (action === "JOIN_ROOM" || action === "INIT_GAME") {
          const requestedMode = getModeRules(modeId || "2v2");
          const hasFullPlayers = Array.isArray(players) && !!requestedMode
            && players.length >= requestedMode.minPlayers && players.length <= requestedMode.maxPlayers;
          const isFreshMatch = (!room || !room.state || room.state.status === "FINISHED");
          if (!room || !room.state || isFreshMatch) {
            let battlePlayers = hasFullPlayers ? players : null;
            if (!battlePlayers) {
              if (room?.draft?.slots && room.draft.slots.length >= 4 && room.draft.slots.every((s: any) => s.isLocked && s.heroId > 0)) {
                battlePlayers = room.draft.slots.map((s: any) => ({
                  seat: s.seat,
                  userId: s.userId,
                  heroId: `HERO_${s.heroId || 1}`,
                  generalName: s.heroName || getHeroName(s.heroId || 1),
                  maxHp: HERO_MAX_HP[s.heroId || 1] || 4,
                  hp: HERO_MAX_HP[s.heroId || 1] || 4,
                  isAlly: s.isDragon,
                  isAI: s.isAI,
                  role: (s as any).role || ""
                }));
              } else {
                const fallbackCount = requestedMode?.maxPlayers || 4;
                const fallbackDragonSeats = new Set(Array.from({ length: fallbackCount }, (_, i) => i + 1).sort(() => Math.random() - 0.5).slice(0, Math.ceil(fallbackCount / 2)));
                battlePlayers = Array.from({ length: fallbackCount }, (_, i) => i + 1).map(seat => ({
                  seat,
                  userId: seat === boundSeat ? (payload.userId || `user_${seat}`) : `bot_${seat}`,
                  heroId: `HERO_${seat}`,
                  generalName: getHeroName(seat),
                  maxHp: HERO_MAX_HP[seat] || 4,
                  hp: HERO_MAX_HP[seat] || 4,
                  isAlly: fallbackDragonSeats.has(seat),
                  isAI: seat !== boundSeat,
                  role: requestedMode?.roleDistribution?.[seat - 1] || ""
                }));
              }
            }
            if (!room) {
              room = {
                state: initGame(roomId, battlePlayers, modeId || "2v2"),
                sockets: new Map(),
                lastActivity: Date.now(),
              };
              rooms.set(roomId, room);
            } else {
              room.state = initGame(roomId, battlePlayers, modeId || "2v2");
            }
            ensureTickTimer();
            console.log(`[Deno WS] Khởi tạo trận đấu (Authoritative Battle State): ${roomId} với 4 tướng:`, battlePlayers.map((p: any) => `${p.generalName} (Ghế ${p.seat})`).join(", "));
          }

          if (!hasSeat(room, boundSeat)) {
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
          console.log(`[Deno WS] Ghế ${currentSeat} đã vào phòng: ${roomId} (Tổng sockets: ${room.sockets.size})`);

          const joinedPlayer = room.state?.players?.find((p: any) => p.seat === boundSeat);
          if (joinedPlayer) {
            joinedPlayer.isAI = false;
          }

          // Gửi Snapshot đầy đủ cho người vừa kết nối
          if (room.state) {
            socket.send(JSON.stringify({
              type: "STATE_SNAPSHOT",
              state: sanitizeGameStateForClient(room.state, currentSeat),
              version: room.state.version,
            }));
          }

          broadcastRoom(room, {
            type: "PLAYER_JOINED",
            seat: currentSeat,
            activeSeats: Array.from(room.sockets.keys()),
          });
          return;
        }

        if (!room) {
          return socket.send(JSON.stringify({ type: "ERROR", error: "Phòng đấu không tồn tại hoặc đã kết thúc" }));
        }

        if (!hasSeat(room, boundSeat)) {
          return socket.send(JSON.stringify({ type: "ERROR", error: "Ghế không thuộc phòng đấu" }));
        }
        bindSocket(room, boundSeat, socket);
        room.lastActivity = Date.now();

        if (action === "PING") {
          return socket.send(JSON.stringify({ type: "PONG", timestamp: Date.now() }));
        }

        if (!room.state) {
          return socket.send(JSON.stringify({ type: "ERROR", error: "Trận đấu chưa bắt đầu (đang trong giai đoạn chọn tướng)" }));
        }

        // B. LẤY SNAPSHOT TRẠNG THÁI HIỆN TẠI
        if (action === "GET_STATE") {
          return socket.send(JSON.stringify({
            type: "STATE_SNAPSHOT",
            state: sanitizeGameStateForClient(room.state, boundSeat),
            version: room.state.version,
          }));
        }

        // C. KIỂM TRA KHÓA LẠC QUAN (OPTIMISTIC LOCKING)
        const vCheck = checkVersion(room.state, expectedVersion);
        if (vCheck) {
          return socket.send(JSON.stringify({
            type: "CONFLICT",
            error: vCheck.error,
            code: "VERSION_CONFLICT",
            state: sanitizeGameStateForClient(room.state, boundSeat),
          }));
        }

        const previousVersion = room.state.version;
        let result: any = null;

        // E. XỬ LÝ HÀNH ĐỘNG ĐÁNH BÀI TRÊN RAM SIÊU TỐC
        if (action === "USE_SKILL") {
          result = handleUseSkill(room.state, boundSeat, payload.skillId, targetSeat, cardId);
        } else if (action === "TOGGLE_SKILL") {
          result = handleToggleSkill(room.state, boundSeat, payload.skillId);
        } else if (action === "PLAY_CARD") {
          result = handlePlayCard(room.state, boundSeat, cardId, targetSeat, payload);
        } else if (action === "RESPOND_ACTION") {
          result = handleRespondAction(room.state, boundSeat, accepted, cardId, targetCardId, cardIds, targetSeat, payload);
        } else if (action === "END_TURN") {
          result = handleEndTurn(room.state, boundSeat);
        } else if (action === "DISCARD_CARDS") {
          result = handleDiscardCards(room.state, boundSeat, cardIds);
        } else if (action === "AI_STEP") {
          result = handleAIStep(room.state, boundSeat);
        } else if (action === "AI_REACTION") {
          result = handleAIReaction(room.state, boundSeat);
        } else if (action === "FAST_FORWARD_MATCH") {
          result = fastForwardMatchForDeadPlayer(room.state, boundSeat);
        } else {
          return socket.send(JSON.stringify({ type: "ERROR", error: "Hành động không hợp lệ" }));
        }

        if (result && result.error) {
          return socket.send(JSON.stringify({
            type: "ACTION_REJECTED",
            error: result.error,
            state: sanitizeGameStateForClient(room.state, boundSeat),
          }));
        }

        ensureMutationVersion(room.state, previousVersion);

        // F. PHÁT SÓNG ĐỒNG BỘ CHO CẢ PHÒNG TRONG RAM (<15ms)
        broadcastRoom(room, {
          type: "STATE_UPDATE",
          state: room.state,
          delta: room.state.lastDelta || null,
          version: room.state.version,
          action: action,
        });
        room.state.lastDelta = null;
      } catch (err: any) {
        console.error("[WS Message Error]:", err);
        socket.send(JSON.stringify({ type: "ERROR", error: err.message }));
      }
    };

    socket.onclose = () => {
      // Capture identity before delayed cleanup; reconnects can mutate these
      // handler variables before the timer fires.
      const closedRoomId = currentRoomId;
      const closedSeat = currentSeat;
      if (closedRoomId) {
        const room = rooms.get(closedRoomId);
        if (room) {
          // Do not remove a newer connection that replaced this socket.
          if (room.sockets.get(closedSeat) === socket) {
            room.sockets.delete(closedSeat);
            console.log(`[Deno WS] Ghế ${closedSeat} đã ngắt kết nối phòng: ${closedRoomId} (Còn lại: ${room.sockets.size})`);
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
  if (req.method === "POST" && !new URL(req.url).pathname.startsWith("/matchmaking/")) {
    try {
      const payload = await req.json();
      const { action, roomId, cardId, targetCardId, targetSeat, accepted, cardIds, players, modeId, expectedVersion } = payload;
      const requestSeat = normalizeSeat(payload.seat);

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
        if (room) {
          if (!hasSeat(room.state, requestSeat)) {
            return new Response(JSON.stringify({ success: false, error: "Ghế không thuộc phòng đấu" }), { status: 403 });
          }
          return new Response(JSON.stringify({ success: true, state: sanitizeGameStateForClient(room.state, requestSeat) }), {
            headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
          });
        }
        if (!Array.isArray(players)) {
          return new Response(JSON.stringify({ success: false, error: "Cần thông tin người chơi" }), { status: 400 });
        }
        const state = initGame(roomId, players, modeId || "2v2");
        room = { state, sockets: new Map(), lastActivity: Date.now() };
        rooms.set(roomId, room);
        ensureTickTimer();
        return new Response(JSON.stringify({ success: true, state: sanitizeGameStateForClient(state, requestSeat || 1) }), {
          headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
        });
      }

      if (!room) {
        return new Response(JSON.stringify({ success: false, error: "Phòng đấu không tồn tại hoặc đã kết thúc" }), {
          status: 404,
          headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
        });
      }

      if (action !== "INIT_GAME" && requestSeat === 0) {
        return new Response(JSON.stringify({ success: false, error: "Ghế không hợp lệ" }), {
          status: 400,
          headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
        });
      }
      if (action !== "INIT_GAME" && !hasSeat(room.state, requestSeat)) {
        return new Response(JSON.stringify({ success: false, error: "Ghế không thuộc phòng đấu" }), {
          status: 403,
          headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
        });
      }

      const vCheck = checkVersion(room.state, expectedVersion);
      if (vCheck) {
        return new Response(JSON.stringify({
          success: false,
          error: vCheck.error,
          code: vCheck.code,
          state: sanitizeGameStateForClient(room.state, requestSeat || 1),
        }), { status: 409 });
      }

      const previousVersion = room.state.version;
      let result: any = null;
      if (action === "GET_STATE") {
        return new Response(JSON.stringify({ success: true, state: sanitizeGameStateForClient(room.state, requestSeat || 1) }), {
          headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
        });
      } else if (action === "USE_SKILL") {
        result = handleUseSkill(room.state, requestSeat, payload.skillId, targetSeat, cardId);
      } else if (action === "TOGGLE_SKILL") {
        result = handleToggleSkill(room.state, requestSeat, payload.skillId);
      } else if (action === "PLAY_CARD") {
        result = handlePlayCard(room.state, requestSeat, cardId, targetSeat, payload);
      } else if (action === "RESPOND_ACTION") {
        result = handleRespondAction(room.state, requestSeat, accepted, cardId, targetCardId, cardIds, targetSeat, payload);
      } else if (action === "END_TURN") {
        result = handleEndTurn(room.state, requestSeat);
      } else if (action === "DISCARD_CARDS") {
        result = handleDiscardCards(room.state, requestSeat, cardIds);
      } else if (action === "AI_STEP") {
        result = handleAIStep(room.state, requestSeat);
      } else if (action === "AI_REACTION") {
        result = handleAIReaction(room.state, requestSeat);
      } else if (action === "FAST_FORWARD_MATCH") {
        result = fastForwardMatchForDeadPlayer(room.state, requestSeat);
      } else {
        return new Response(JSON.stringify({ success: false, error: "Hành động không hợp lệ" }), { status: 400 });
      }

      if (result && result.error) {
        return new Response(JSON.stringify({ success: false, error: result.error, state: sanitizeGameStateForClient(room.state, requestSeat) }), { status: 400 });
      }

      ensureMutationVersion(room.state, previousVersion);

      // Phát sóng cập nhật qua WebSocket nếu có người đang kết nối
      broadcastRoom(room, {
        type: "STATE_UPDATE",
        state: room.state,
        delta: room.state.lastDelta || null,
        version: room.state.version,
        action: action,
      });

      return new Response(JSON.stringify({ success: true, state: sanitizeGameStateForClient(room.state, requestSeat || 1) }), {
        headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
      });
    } catch (err: any) {
      return new Response(JSON.stringify({ success: false, error: err.message }), { status: 500 });
    }
  }

  // 3. Matchmaking REST API. Queue state lives beside the WebSocket rooms so
  // clients do not need a second backend service for finding a match.
  if (req.method === "GET" && new URL(req.url).pathname === "/matchmaking/find") {
    const url = new URL(req.url);
    const userId = url.searchParams.get("userId") || "";
    const rankPoints = Number(url.searchParams.get("rankPoints") || 0);
    const maxRankDiff = Number(url.searchParams.get("maxRankDiff") || 500);
    if (!userId) return matchmakingJson({ success: false, error: "Thiếu userId" }, 400);
    const room = findMatchmakingRoom(userId, rankPoints, maxRankDiff);
    return matchmakingJson({ success: true, room });
  }

  if (req.method === "POST" && new URL(req.url).pathname === "/matchmaking/rooms") {
    try {
      const payload = await req.json();
      const room = payload?.room;
      if (!isValidMatchmakingRoom(room)) {
        return matchmakingJson({ success: false, error: "Phòng tìm trận không hợp lệ" }, 400);
      }
      if (matchmakingRooms.has(room.roomId)) {
        return matchmakingJson({ success: false, error: "Mã phòng đã tồn tại" }, 409);
      }
      const now = Date.now();
      const stored: MatchmakingRoom = {
        ...room,
        status: "WAITING",
        version: 1,
        createdAt: now,
        updatedAt: now,
        slots: room.slots.map((slot: any, index: number) => ({
          ...slot,
          seatNumber: index + 1,
          isEmpty: isEmptyMatchSlot(slot),
          isAI: Boolean(slot?.isAI),
        })),
      };
      matchmakingRooms.set(stored.roomId, stored);
      return matchmakingJson({ success: true, room: stored }, 201);
    } catch (err: any) {
      return matchmakingJson({ success: false, error: err.message }, 400);
    }
  }

  if (req.method === "POST" && new URL(req.url).pathname.startsWith("/matchmaking/rooms/") && new URL(req.url).pathname.endsWith("/join")) {
    const parts = new URL(req.url).pathname.split("/");
    const roomId = decodeURIComponent(parts[parts.length - 2] || "");
    const current = matchmakingRooms.get(roomId);
    if (!current || current.status !== "WAITING") return matchmakingJson({ success: false, error: "Phòng không còn nhận người" }, 409);
    try {
      const payload = await req.json();
      const userId = String(payload?.userId || "");
      const userName = String(payload?.userName || "");
      const rankPoints = Number(payload?.rankPoints || 0);
      if (!userId || userId.length > 256) return matchmakingJson({ success: false, error: "Thiếu userId" }, 400);
      const existing = current.slots.find((slot: any) => !isEmptyMatchSlot(slot) && slot.userId === userId);
      if (existing) return matchmakingJson({ success: true, room: current });
      const target = current.slots.find((slot: any) => isEmptyMatchSlot(slot));
      if (!target) return matchmakingJson({ success: false, error: "Phòng đã đầy" }, 409);
      target.userId = userId;
      target.userName = userName;
      target.rankPoints = rankPoints;
      target.isAI = false;
      target.isEmpty = false;
      current.version += 1;
      current.updatedAt = Date.now();
      return matchmakingJson({ success: true, room: current });
    } catch (err: any) {
      return matchmakingJson({ success: false, error: err.message }, 400);
    }
  }

  if (req.method === "PATCH" && new URL(req.url).pathname.startsWith("/matchmaking/rooms/")) {
    const roomId = decodeURIComponent(new URL(req.url).pathname.split("/").pop() || "");
    const current = matchmakingRooms.get(roomId);
    if (!current) return matchmakingJson({ success: false, error: "Không tìm thấy phòng" }, 404);
    try {
      const payload = await req.json();
      const updated = payload?.room || payload;
      const expectedVersion = payload?.expectedVersion;
      if (expectedVersion !== undefined && Number(expectedVersion) !== current.version) {
        return matchmakingJson({ success: false, error: "Phòng đã được cập nhật, hãy tải lại", code: "STALE_ROOM" }, 409);
      }
      if (updated.hostUserId !== undefined && updated.hostUserId !== current.hostUserId) {
        return matchmakingJson({ success: false, error: "Không được đổi chủ phòng" }, 403);
      }
      if (!Array.isArray(updated.slots) || updated.slots.length !== 4) {
        return matchmakingJson({ success: false, error: "Danh sách ghế không hợp lệ" }, 400);
      }
      const nextVersion = Number(updated.version);
      if (!Number.isInteger(nextVersion) || nextVersion !== current.version + 1) {
        return matchmakingJson({ success: false, error: "Phiên bản phòng không hợp lệ" }, 409);
      }
      const next: MatchmakingRoom = { ...current, ...updated, roomId, updatedAt: Date.now(), version: nextVersion };
      matchmakingRooms.set(roomId, next);
      return matchmakingJson({ success: true, room: next });
    } catch (err: any) {
      return matchmakingJson({ success: false, error: err.message }, 400);
    }
  }

  if (req.method === "GET" && new URL(req.url).pathname.startsWith("/matchmaking/rooms/")) {
    const roomId = decodeURIComponent(new URL(req.url).pathname.split("/").pop() || "");
    return matchmakingJson({ success: true, room: matchmakingRooms.get(roomId) || null });
  }

  if (req.method === "DELETE" && new URL(req.url).pathname.startsWith("/matchmaking/rooms/")) {
    const roomId = decodeURIComponent(new URL(req.url).pathname.split("/").pop() || "");
    matchmakingRooms.delete(roomId);
    return matchmakingJson({ success: true });
  }

  // 4. HTTP HEALTH CHECK & DASHBOARD
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
