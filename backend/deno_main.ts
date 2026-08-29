/**
 * ĐẠI VIỆT CHIẾN - UNIFIED REALTIME & REST GAME SERVER (DENO DEPLOY)
 * Tích hợp 100% WebSocket Realtime (<15ms) + REST API Fallback + Appwrite DB Backup
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
  tickGameState,
  hydrateGameState,
  sanitizeGameStateForClient,
  ensureMutationVersion,
} from "./functions/game-engine/src/gameEngine.js";

const APPWRITE_ENDPOINT = Deno.env.get("APPWRITE_ENDPOINT") || "https://sgp.cloud.appwrite.io/v1";
const PROJECT_ID = Deno.env.get("APPWRITE_PROJECT_ID") || "6a885457002da3f3d47e";
const API_KEY = Deno.env.get("APPWRITE_API_KEY") || "";
const DATABASE_ID = Deno.env.get("DATABASE_ID") || "game";
const COLLECTION_ID = Deno.env.get("COLLECTION_ID") || "matchmaking_queue";

// Bộ nhớ In-Memory lưu trữ toàn bộ các phòng đấu đang diễn ra trên RAM
interface RoomData {
  state: any;
  sockets: Map<number, WebSocket>;
  lastActivity: number;
}

const rooms = new Map<string, RoomData>();
const startTime = Date.now();

const STATE_ENCODING_PREFIX = "GZIP1:";
// Appwrite string attributes are limited to 8192 characters. Keep a small
// margin for schema/runtime differences and never persist a truncated JSON.
const MAX_PERSISTED_STATE_CHARS = 8000;
const persistenceQueues = new Map<string, Promise<void>>();

async function encodePersistedState(value: unknown): Promise<string> {
  const stream = new CompressionStream("gzip");
  const output = new Response(stream.readable).arrayBuffer();
  const writer = stream.writable.getWriter();
  await writer.write(new TextEncoder().encode(JSON.stringify(value)));
  await writer.close();
  const bytes = new Uint8Array(await output);
  let binary = "";
  for (let offset = 0; offset < bytes.length; offset += 0x8000) {
    binary += String.fromCharCode(...bytes.subarray(offset, offset + 0x8000));
  }
  const encoded = STATE_ENCODING_PREFIX + btoa(binary);
  if (encoded.length > MAX_PERSISTED_STATE_CHARS) {
    throw new Error(`Serialized GameState exceeds Appwrite limit (${encoded.length} chars)`);
  }
  return encoded;
}

async function decodePersistedState(value: string): Promise<any | null> {
  if (!value) return null;
  if (!value.startsWith(STATE_ENCODING_PREFIX)) {
    try { return JSON.parse(value); } catch { return null; }
  }
  try {
    const binary = atob(value.slice(STATE_ENCODING_PREFIX.length));
    const bytes = Uint8Array.from(binary, (char) => char.charCodeAt(0));
    const stream = new DecompressionStream("gzip");
    const output = new Response(stream.readable).text();
    const writer = stream.writable.getWriter();
    await writer.write(bytes);
    await writer.close();
    return JSON.parse(await output);
  } catch (err) {
    console.error("[DB Decode Error]:", err);
    return null;
  }
}

console.log("🎮 [Deno Server] Đại Việt Chiến 2v2 Unified Game Server is running!");

// Keep timers and AI turns authoritative even when no client sends messages.
setInterval(() => {
  for (const [roomId, room] of rooms.entries()) {
    if (!room?.state || room.state.status === "FINISHED") continue;
    try {
      if (tickGameState(room.state)) {
        room.lastActivity = Date.now();
        broadcastRoom(room, {
          type: "STATE_UPDATE",
          state: room.state,
          delta: room.state.lastDelta || null,
          version: room.state.version,
          action: "SERVER_TICK",
        });
        saveStateToDatabase(roomId, room.state);
      }
    } catch (err) {
      console.error(`[Tick Error room ${roomId}]:`, err);
    }
  }
}, 1000);


async function loadStateFromDatabase(roomId: string) {
  const docId = `gs_${roomId.replace(/[^a-zA-Z0-9_-]/g, '')}`.substring(0, 36);
  try {
    const res = await fetch(`${APPWRITE_ENDPOINT}/databases/${DATABASE_ID}/collections/${COLLECTION_ID}/documents/${docId}`, {
      headers: {
        "X-Appwrite-Project": PROJECT_ID,
        "X-Appwrite-Key": API_KEY,
        "Content-Type": "application/json",
      },
    });
    if (res.ok) {
      const doc = await res.json();
      if (doc && doc.userName) {
        return hydrateGameState(await decodePersistedState(doc.userName), roomId);
      }
    }
  } catch (err) {
    console.error("[DB Load Error]:", err);
  }
  return null;
}

async function persistStateToDatabase(roomId: string, state: any): Promise<void> {
  if (!API_KEY) return; // Nếu không có API Key, chỉ chạy In-Memory
  try {
    const docId = `gs_${roomId.replace(/[^a-zA-Z0-9_-]/g, '')}`.substring(0, 36);
    const stateJson = await encodePersistedState({
      ...state,
    });

    const docData = {
      userId: "GAME_STATE",
      userName: stateJson,
      rankPoints: state.turnSeat,
      timestamp: Date.now(),
    };

    const permissions = [];

    const res = await fetch(`${APPWRITE_ENDPOINT}/databases/${DATABASE_ID}/collections/${COLLECTION_ID}/documents/${docId}`, {
      method: "PATCH",
      headers: {
        "X-Appwrite-Project": PROJECT_ID,
        "X-Appwrite-Key": API_KEY,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ data: docData, permissions }),
    });
    if (!res.ok && res.status === 404) {
      await fetch(`${APPWRITE_ENDPOINT}/databases/${DATABASE_ID}/collections/${COLLECTION_ID}/documents`, {
        method: "POST",
        headers: {
          "X-Appwrite-Project": PROJECT_ID,
          "X-Appwrite-Key": API_KEY,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ documentId: docId, data: docData, permissions }),
      });
    }
  } catch (err) {
    console.error("[DB Save Error]:", err);
  }
}

// Preserve write order so a slower request cannot overwrite a newer backup.
function saveStateToDatabase(roomId: string, state: any): Promise<void> {
  if (!API_KEY) return Promise.resolve();
  const snapshot = structuredClone(state);
  const previous = persistenceQueues.get(roomId) || Promise.resolve();
  const current = previous
    .catch(() => {})
    .then(() => persistStateToDatabase(roomId, snapshot));
  persistenceQueues.set(roomId, current);
  return current.finally(() => {
    if (persistenceQueues.get(roomId) === current) persistenceQueues.delete(roomId);
  });
}

function broadcastRoom(room: RoomData, messageObj: any) {
  const json = JSON.stringify(messageObj);
  for (const [seat, ws] of room.sockets.entries()) {
    if (ws.readyState === WebSocket.OPEN) {
      try {
        if (messageObj.type === "STATE_UPDATE" && messageObj.state) {
          const sanitizedState = sanitizeGameStateForClient(room.state, seat);
          const personalized = {
            ...messageObj,
            state: sanitizedState,
            delta: sanitizedState.delta,
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
  return Number.isInteger(seat) && seat >= 1 && seat <= 4 ? seat : 0;
}

function hasSeat(state: any, seat: number): boolean {
  return !!state?.players?.some((player: any) => player.seat === seat);
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

Deno.serve({ port: Number(Deno.env.get("PORT")) || 8080 }, async (req) => {
  const upgrade = req.headers.get("upgrade") || "";

  // 1. WEBSOCKET REALTIME CONNECTION (<15ms)
  if (upgrade.toLowerCase() === "websocket") {
    const { socket, response } = Deno.upgradeWebSocket(req);

    let currentRoomId: string | null = null;
    let currentSeat = 0;

    socket.onopen = () => {};

    socket.onmessage = (event) => {
      try {
        const payload = JSON.parse(event.data);
        const { action, roomId, cardId, targetCardId, targetSeat, accepted, cardIds, players, expectedVersion } = payload;
        const requestSeat = normalizeSeat(payload.seat);

        if (!roomId) {
          return socket.send(JSON.stringify({ type: "ERROR", error: "Thiếu roomId" }));
        }

        const isJoinAction = action === "JOIN_ROOM" || action === "INIT_GAME";
        if (!isJoinAction && currentRoomId === null) {
          return socket.send(JSON.stringify({ type: "ERROR", error: "Kết nối chưa tham gia phòng" }));
        }
        if (isJoinAction && requestSeat === 0) {
          return socket.send(JSON.stringify({ type: "ERROR", error: "Ghế không hợp lệ (1-4)" }));
        }
        if (currentRoomId !== null && (roomId !== currentRoomId || (requestSeat !== 0 && requestSeat !== currentSeat))) {
          return socket.send(JSON.stringify({ type: "ERROR", error: "Kết nối đã được khóa vào phòng/ghế khác" }));
        }

        const boundSeat = currentRoomId !== null ? currentSeat : requestSeat;

        let room = rooms.get(roomId);

        // A. KHỞI TẠO HOẶC THAM GIA PHÒNG ĐẤU
        if (action === "JOIN_ROOM" || action === "INIT_GAME") {
          if (!room) {
            if (!Array.isArray(players) || players.length !== 4) {
              return socket.send(JSON.stringify({ type: "ERROR", error: "Cần đủ thông tin 4 người chơi để khởi tạo phòng" }));
            }
            room = {
              state: initGame(roomId, players),
              sockets: new Map(),
              lastActivity: Date.now(),
            };
            rooms.set(roomId, room);
            console.log(`[Deno WS] Phòng mới: ${roomId}`);
            saveStateToDatabase(roomId, room.state);
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

        if (!room) {
          return socket.send(JSON.stringify({ type: "ERROR", error: "Phòng đấu không tồn tại hoặc đã kết thúc" }));
        }

        if (!hasSeat(room.state, boundSeat)) {
          return socket.send(JSON.stringify({ type: "ERROR", error: "Ghế không thuộc phòng đấu" }));
        }
        bindSocket(room, boundSeat, socket);
        room.lastActivity = Date.now();

        if (action === "PING") {
          return socket.send(JSON.stringify({ type: "PONG", timestamp: Date.now() }));
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
        if (action === "PLAY_CARD") {
          result = handlePlayCard(room.state, boundSeat, cardId, targetSeat);
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

        // Tự động lưu DB bất đồng bộ không chặn luồng RAM
        saveStateToDatabase(roomId, room.state);
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
      const { action, roomId, cardId, targetCardId, targetSeat, accepted, cardIds, players, expectedVersion } = payload;
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
          return new Response(JSON.stringify({ success: false, error: "Ghế không hợp lệ (1-4)" }), { status: 400 });
        }
        if (room) {
          if (!hasSeat(room.state, requestSeat)) {
            return new Response(JSON.stringify({ success: false, error: "Ghế không thuộc phòng đấu" }), { status: 403 });
          }
          return new Response(JSON.stringify({ success: true, state: sanitizeGameStateForClient(room.state, requestSeat) }), {
            headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
          });
        }
        if (!Array.isArray(players) || players.length !== 4) {
          return new Response(JSON.stringify({ success: false, error: "Cần đủ thông tin 4 người chơi" }), { status: 400 });
        }
        const state = initGame(roomId, players);
        room = { state, sockets: new Map(), lastActivity: Date.now() };
        rooms.set(roomId, room);
        saveStateToDatabase(roomId, state);
        return new Response(JSON.stringify({ success: true, state: sanitizeGameStateForClient(state, requestSeat || 1) }), {
          headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
        });
      }

      if (!room) {
        const dbState = await loadStateFromDatabase(roomId);
        if (dbState) {
          room = { state: dbState, sockets: new Map(), lastActivity: Date.now() };
          rooms.set(roomId, room);
        } else {
          return new Response(JSON.stringify({ success: false, error: "Phòng đấu chưa được khởi tạo" }), { status: 404 });
        }
      }

      if (action !== "INIT_GAME" && requestSeat === 0) {
        return new Response(JSON.stringify({ success: false, error: "Ghế không hợp lệ (1-4)" }), {
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
      } else if (action === "PLAY_CARD") {
        result = handlePlayCard(room.state, requestSeat, cardId, targetSeat);
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

      saveStateToDatabase(roomId, room.state);

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
