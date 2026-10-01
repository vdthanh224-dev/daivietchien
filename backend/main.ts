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
}

export interface DraftState {
  roomId: string;
  slots: DraftSlot[];
  currentPickerIndex: number;
  timer: number;
  timerStartAt: number;
  isCompleted: boolean;
}

// Bộ nhớ In-Memory lưu trữ toàn bộ các phòng đấu đang diễn ra trên RAM
interface RoomData {
  state: any;
  draft?: DraftState;
  sockets: Map<number, WebSocket>;
  lastActivity: number;
}

const rooms = new Map<string, RoomData>();
const startTime = Date.now();
const MAX_WS_MESSAGE_BYTES = 64 * 1024;
const MAX_ACTIONS_PER_SECOND = 30;
const ALLOWED_WS_ACTIONS = new Set([
  "JOIN_ROOM", "INIT_GAME", "JOIN_DRAFT", "PICK_HERO", "GET_STATE", "PING",
  "USE_SKILL", "TOGGLE_SKILL", "PLAY_CARD", "RESPOND_ACTION", "END_TURN",
  "DISCARD_CARDS", "AI_STEP", "AI_REACTION"
]);

function validateClientPayload(payload: any, rawBytes: number): string | null {
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
  5: "Lê Lợi",
  6: "Nguyễn Trãi",
  19: "Khúc Hạo",
  27: "Kiều Thuận",
  44: "Tông Đản",
  47: "Lý Thường Kiệt",
  59: "Phạm Ngũ Lão",
  72: "Trần Duệ Tông",
  83: "Nguyễn Cảnh Chân"
};

function getHeroName(heroId: number): string {
  return HERO_NAME_MAP[heroId] || `Chiến Tướng #${heroId}`;
}

const DEFAULT_HERO_POOL = [1, 2, 3, 4, 19, 27, 44, 47, 59, 72, 83];

function getAutoPickHeroId(excludeIds: number[]): number {
  for (const id of DEFAULT_HERO_POOL) {
    if (!excludeIds.includes(id)) return id;
  }
  for (let id = 1; id <= 84; id++) {
    if (!excludeIds.includes(id)) return id;
  }
  return 1;
}

function randomTeamSeats(): Set<number> {
  const seats = [1, 2, 3, 4];
  for (let i = seats.length - 1; i > 0; i -= 1) {
    const j = Math.floor(Math.random() * (i + 1));
    [seats[i], seats[j]] = [seats[j], seats[i]];
  }
  return new Set(seats.slice(0, 2));
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
    isAI: s.isAI
  }));

  room.state = initGame(roomId, battlePlayers);
  console.log(`[Deno Server] Chọn tướng hoàn tất phòng: ${roomId}! Bắt đầu trận đấu 2v2!`);

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
        draft.timer = Math.max(0, draft.timer - 1);
        room.lastActivity = now;

        const currentSlot = draft.slots[draft.currentPickerIndex];
        const hasHumanSocket = currentSlot && room.sockets.has(currentSlot.seat);
        const isBot = currentSlot && currentSlot.isAI && !hasHumanSocket;
        // Bot suy nghĩ 3 giây (khi timer <= 37). Ghế có người thật (hoặc có socket kết nối) chờ đủ 40s (khi timer <= 0)
        const shouldAutoPick = (draft.timer <= 0) || (isBot && draft.timer <= 37);

        if (shouldAutoPick && currentSlot && !currentSlot.isLocked) {
          const lockedIds = draft.slots.filter(s => s.isLocked).map(s => s.heroId);
          const autoHeroId = getAutoPickHeroId(lockedIds);
          currentSlot.heroId = autoHeroId;
          currentSlot.heroName = getHeroName(autoHeroId);
          currentSlot.isLocked = true;
          console.log(`[Deno Draft AutoPick] Ghế ${currentSlot.seat} (${isBot ? "Bot" : "Timeout"}) đã tự chọn tướng ${currentSlot.heroName} (#${autoHeroId})`);

          draft.currentPickerIndex++;
          draft.timer = 40;
          draft.timerStartAt = now;

          if (draft.currentPickerIndex >= draft.slots.length || draft.slots.every(s => s.isLocked)) {
            finishDraftAndStartBattle(roomId, room);
            continue;
          }
        }

        // Phát sóng tick đồng bộ mỗi giây cho cả 4 socket
        broadcastRoom(room, {
          type: "DRAFT_STATE_UPDATE",
          roomId,
          currentPickerIndex: draft.currentPickerIndex,
          currentSeat: draft.slots[draft.currentPickerIndex]?.seat || 1,
          timer: draft.timer,
          slots: draft.slots,
          selectedHeroIds: draft.slots.filter(s => s.isLocked).map(s => s.heroId)
        });
        continue;
      }

      // 2. Tick giai đoạn BATTLE (Trận Đấu) - Đồng bộ mỗi giây cho cả 4 người chơi
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
  }, 1000);
}

function broadcastRoom(room: RoomData, messageObj: any) {
  const json = JSON.stringify(messageObj);
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
        } else {
          ws.send(json);
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

  // Godot debug windows can share one UID/name through user://; honor their explicit seat.
  if (Number(payload.debugSeat) === requestedSeat && requestedSeat >= 1 && requestedSeat <= 4) {
    return requestedSeat;
  }

  const userId = normalize(payload.userId);
  const userName = normalize(payload.userName);
  const byId = userId ? slots.filter((slot: any) => normalize(slot.userId) === userId) : [];
  if (byId.length === 1) return byId[0].seat;
  const byName = userName ? slots.filter((slot: any) => normalize(slot.userName) === userName) : [];
  if (byName.length === 1) return byName[0].seat;

  // Duplicate debug identities use the requested per-window seat.
  if (!room.sockets.has(requestedSeat) || room.sockets.get(requestedSeat) === socket) return requestedSeat;
  return slots.find((slot: any) => !room.sockets.has(slot.seat))?.seat || 0;
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
        if (!isJoinAction && currentRoomId === null) {
          return socket.send(JSON.stringify({ type: "ERROR", error: "Kết nối chưa tham gia phòng" }));
        }
        if (isJoinAction && requestSeat === 0) {
          return socket.send(JSON.stringify({ type: "ERROR", error: "Ghế không hợp lệ" }));
        }
        if (currentRoomId !== null) {
          if (roomId !== currentRoomId) {
            return socket.send(JSON.stringify({ type: "ERROR", error: "Kết nối đã được khóa vào phòng khác" }));
          }
          if (requestSeat !== 0 && requestSeat !== currentSeat) {
            console.log(`[Deno WS] Socket phòng ${roomId} gửi requestSeat=${requestSeat}, nhưng đã khóa vào ghế ${currentSeat}. Tiếp tục dùng ghế ${currentSeat}.`);
          }
        }

        const boundSeat = currentRoomId !== null ? currentSeat : requestSeat;

        let room = rooms.get(roomId);

        // A.0. THAM GIA HOẶC KHỞI TẠO CHỌN TƯỚNG (DRAFT)
        if (action === "JOIN_DRAFT") {
          const isFreshDraft = !room || (!room.draft?.isCompleted && room.state?.status === "FINISHED");
          if (isFreshDraft) {
            const rawSlots = Array.isArray(payload.slots) ? payload.slots : [];
            const dragonSeats = randomTeamSeats();
            const defaultSlots: DraftSlot[] = [1, 2, 3, 4].map((s) => {
              const matched = rawSlots.find((x: any) => Number(x.seatNumber || x.seat) === s) || rawSlots[s - 1] || {};
              const isAI = Boolean(matched.isAI ?? (s !== boundSeat));
              return {
                seat: s,
                userId: String(matched.userId || (isAI ? `bot_${s}` : (s === boundSeat ? (payload.userId || `user_${s}`) : `user_${s}`))),
                userName: String(matched.userName || (isAI ? `AI Ghế ${s}` : (s === boundSeat ? (payload.userName || `Ghế ${s}`) : `Ghế ${s}`))),
                isAI: isAI,
                isDragon: dragonSeats.has(s),
                heroId: Number(matched.heroId || 0),
                heroName: String(matched.heroName || ""),
                maxHp: HERO_MAX_HP[Number(matched.heroId || 0)] || 4,
                isLocked: Boolean(matched.isLocked || false)
              };
            });

            if (!room) {
              room = {
                state: null,
                draft: {
                  roomId,
                  slots: defaultSlots,
                  currentPickerIndex: 0,
                  timer: 40,
                  timerStartAt: Date.now(),
                  isCompleted: false
                },
                sockets: new Map(),
                lastActivity: Date.now()
              };
              rooms.set(roomId, room);
            } else {
              room.state = null;
              room.draft = {
                roomId,
                slots: defaultSlots,
                currentPickerIndex: 0,
                timer: 40,
                timerStartAt: Date.now(),
                isCompleted: false
              };
              room.lastActivity = Date.now();
            }
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
              slot.isAI = false; // Người thật đã vào ghế
            }
          }

          currentRoomId = roomId;
          currentSeat = draftSeat;
          bindSocket(room, currentSeat, socket);
          room.lastActivity = Date.now();
          socket.send(JSON.stringify({ type: "DRAFT_JOINED", roomId, seat: draftSeat, assignedSeat: draftSeat }));
          console.log(`[Deno WS] Ghế ${currentSeat} kết nối phòng DRAFT: ${roomId} (Sockets: ${room.sockets.size})`);

          if (room.draft && !room.draft.isCompleted) {
            broadcastRoom(room, {
              type: "DRAFT_STATE_UPDATE",
              roomId,
              currentPickerIndex: room.draft.currentPickerIndex,
              currentSeat: room.draft.slots[room.draft.currentPickerIndex]?.seat || 1,
              timer: room.draft.timer,
              slots: room.draft.slots,
              selectedHeroIds: room.draft.slots.filter((s: any) => s.isLocked).map((s: any) => s.heroId)
            });
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
          if (!currentSlot || currentSlot.seat !== boundSeat) {
            return socket.send(JSON.stringify({ type: "ERROR", error: "Chưa đến lượt bạn chọn tướng" }));
          }

          const heroId = Number(payload.heroId || payload.hero_id || 0);
          if (heroId <= 0) {
            return socket.send(JSON.stringify({ type: "ERROR", error: "Tướng không hợp lệ" }));
          }

          const selectedHeroIds = draft.slots.filter((s: any) => s.isLocked).map((s: any) => s.heroId);
          if (selectedHeroIds.includes(heroId)) {
            return socket.send(JSON.stringify({ type: "ERROR", error: "Tướng này đã được chọn" }));
          }

          currentSlot.heroId = heroId;
          currentSlot.heroName = payload.heroName || getHeroName(heroId);
          currentSlot.maxHp = HERO_MAX_HP[heroId] || 4;
          currentSlot.isLocked = true;

          draft.currentPickerIndex++;
          draft.timer = 40;
          draft.timerStartAt = Date.now();

          console.log(`[Deno WS] Ghế ${boundSeat} đã khóa [${currentSlot.heroName}] (#${heroId}) trong phòng ${roomId}`);

          if (draft.currentPickerIndex >= draft.slots.length || draft.slots.every((s: any) => s.isLocked)) {
            finishDraftAndStartBattle(roomId, room);
          } else {
            broadcastRoom(room, {
              type: "DRAFT_STATE_UPDATE",
              roomId,
              currentPickerIndex: draft.currentPickerIndex,
              currentSeat: draft.slots[draft.currentPickerIndex]?.seat || 1,
              timer: draft.timer,
              slots: draft.slots,
              selectedHeroIds: draft.slots.filter((s: any) => s.isLocked).map((s: any) => s.heroId)
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
              if (room?.draft?.slots && room.draft.slots.length === 4 && room.draft.slots.every((s: any) => s.isLocked && s.heroId > 0)) {
                battlePlayers = room.draft.slots.map((s: any) => ({
                  seat: s.seat,
                  userId: s.userId,
                  heroId: `HERO_${s.heroId || 1}`,
                  generalName: s.heroName || getHeroName(s.heroId || 1),
                  maxHp: HERO_MAX_HP[s.heroId || 1] || 4,
                  hp: HERO_MAX_HP[s.heroId || 1] || 4,
                  isAlly: s.isDragon,
                  isAI: s.isAI
                }));
              } else {
                const fallbackDragonSeats = new Set([1, 2, 3, 4].sort(() => Math.random() - 0.5).slice(0, 2));
                battlePlayers = [1, 2, 3, 4].map(seat => ({
                  seat,
                  userId: seat === boundSeat ? (payload.userId || `user_${seat}`) : `bot_${seat}`,
                  heroId: `HERO_${seat}`,
                  generalName: getHeroName(seat),
                  maxHp: HERO_MAX_HP[seat] || 4,
                  hp: HERO_MAX_HP[seat] || 4,
                  isAlly: fallbackDragonSeats.has(seat),
                  isAI: seat !== boundSeat
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
          result = handleRespondAction(room.state, boundSeat, accepted, cardId, targetCardId, cardIds);
        } else if (action === "END_TURN") {
          result = handleEndTurn(room.state, boundSeat);
        } else if (action === "DISCARD_CARDS") {
          result = handleDiscardCards(room.state, boundSeat, cardIds);
        } else if (action === "AI_STEP") {
          result = handleAIStep(room.state, boundSeat);
        } else if (action === "AI_REACTION") {
          result = handleAIReaction(room.state, boundSeat);
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
  if (req.method === "POST") {
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
        result = handleRespondAction(room.state, requestSeat, accepted, cardId, targetCardId, cardIds);
      } else if (action === "END_TURN") {
        result = handleEndTurn(room.state, requestSeat);
      } else if (action === "DISCARD_CARDS") {
        result = handleDiscardCards(room.state, requestSeat, cardIds);
      } else if (action === "AI_STEP") {
        result = handleAIStep(room.state, requestSeat);
      } else if (action === "AI_REACTION") {
        result = handleAIReaction(room.state, requestSeat);
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
