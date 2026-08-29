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
  sanitizeGameStateForClient,
  hydrateGameState,
} from "./gameEngine.js";

const APPWRITE_ENDPOINT = Deno.env.get("APPWRITE_ENDPOINT") || "https://sgp.cloud.appwrite.io/v1";
const PROJECT_ID = Deno.env.get("APPWRITE_PROJECT_ID") || "6a885457002da3f3d47e";
const API_KEY = Deno.env.get("APPWRITE_API_KEY") || "";
const DATABASE_ID = Deno.env.get("DATABASE_ID") || "game";
const COLLECTION_ID = Deno.env.get("COLLECTION_ID") || "matchmaking_queue";

const rooms = new Map();
const startTime = Date.now();
const localKvPath = Deno.build.os === "windows" ? ".dvc-kv" : undefined;
const sharedKv = await Deno.openKv(Deno.env.get("DVC_KV_PATH") || localKvPath);
const STATE_KEY_PREFIX = "dvc-game-state";
const TICK_LEASE_KEY_PREFIX = "dvc-game-tick-lease";
const instanceId = crypto.randomUUID();
let roomLoopRunning = false;

const STATE_ENCODING_PREFIX = "GZIP1:";
// Appwrite string attributes are limited to 8192 characters. Keep a small
// margin for schema/runtime differences and never persist truncated JSON.
const MAX_PERSISTED_STATE_CHARS = 8000;
const persistenceQueues = new Map();

async function encodePersistedState(value) {
  const stream = new CompressionStream("gzip");
  // Start consuming the readable side before writing to avoid backpressure
  // deadlocks for larger game snapshots.
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

async function decodePersistedState(value) {
  if (!value) return null;
  // Read snapshots written before compression was introduced.
  if (!value.startsWith(STATE_ENCODING_PREFIX)) {
    try {
      return JSON.parse(value);
    } catch {
      return null;
    }
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

async function loadStateFromDatabase(roomId) {
  if (!API_KEY) return null;
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

async function persistStateToDatabase(roomId, state) {
  if (!API_KEY) return;
  try {
    const docId = `gs_${roomId.replace(/[^a-zA-Z0-9_-]/g, '')}`.substring(0, 36);
    // Persist the full authoritative state. A client-safe snapshot omits
    // queues/counters needed to resume AOE, duel, harvest, or near-death flows.
    const stateJson = await encodePersistedState(state);

    const docData = {
      userId: "GAME_STATE",
      userName: stateJson,
      rankPoints: state.turnSeat,
      timestamp: Date.now(),
    };

    // Keep existing Appwrite fallback compatibility; this document contains
    // private hands/deck, so clients must use the sanitized server response.
    const permissions = ["read(\"any\")", "update(\"any\")", "delete(\"any\")"];

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
function saveStateToDatabase(roomId, state) {
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

function stateKey(roomId) {
  return [STATE_KEY_PREFIX, roomId];
}

function tickLeaseKey(roomId) {
  return [TICK_LEASE_KEY_PREFIX, roomId];
}

function hydrateSharedState(entry, roomId) {
  if (!entry?.value) return null;
  return hydrateGameState(structuredClone(entry.value), roomId);
}

async function readSharedState(roomId) {
  const entry = await sharedKv.get(stateKey(roomId));
  return {
    state: hydrateSharedState(entry, roomId),
    versionstamp: entry.versionstamp,
  };
}

async function loadOrCreateSharedState(roomId, players) {
  const existing = await readSharedState(roomId);
  if (existing.state) return existing;

  const restored = await loadStateFromDatabase(roomId);
  if (restored) {
    const restoreCommit = await sharedKv.atomic()
      .check({ key: stateKey(roomId), versionstamp: existing.versionstamp })
      .set(stateKey(roomId), restored)
      .commit();
    if (restoreCommit.ok) {
      return { state: restored, versionstamp: restoreCommit.versionstamp };
    }
    return readSharedState(roomId);
  }

  if (!Array.isArray(players) || players.length !== 4) return existing;
  const initialState = initGame(roomId, players);
  const createCommit = await sharedKv.atomic()
    .check({ key: stateKey(roomId), versionstamp: existing.versionstamp })
    .set(stateKey(roomId), initialState)
    .commit();
  if (createCommit.ok) {
    return { state: initialState, versionstamp: createCommit.versionstamp };
  }
  return readSharedState(roomId);
}

async function ensureLocalRoom(roomId, players = null) {
  const shared = await loadOrCreateSharedState(roomId, players);
  if (!shared.state) return null;

  let room = rooms.get(roomId);
  if (!room) {
    room = {
      state: shared.state,
      sockets: new Map(),
      lastActivity: Date.now(),
      kvVersionstamp: shared.versionstamp,
      nextTickAt: Date.now(),
    };
    rooms.set(roomId, room);
  } else if (!room.state || shared.state.version > room.state.version
      || shared.versionstamp !== room.kvVersionstamp) {
    room.state = shared.state;
    room.kvVersionstamp = shared.versionstamp;
  }
  return room;
}

function updateLocalRoom(roomId, state, versionstamp) {
  const room = rooms.get(roomId);
  if (!room) return null;
  room.state = state;
  room.kvVersionstamp = versionstamp;
  room.lastActivity = Date.now();
  return room;
}

function applyActionToState(state, seat, payload) {
  if (!hasSeat(state, seat)) return { error: "Ghế không thuộc phòng đấu" };

  if (payload.action === "PLAY_CARD") {
    return handlePlayCard(state, seat, payload.cardId, payload.targetSeat);
  }
  if (payload.action === "RESPOND_ACTION") {
    return handleRespondAction(state, seat, payload.accepted, payload.cardId, payload.targetCardId);
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

async function mutateSharedState(roomId, seat, payload) {
  for (let attempt = 0; attempt < 4; attempt++) {
    const entry = await sharedKv.get(stateKey(roomId));
    const state = hydrateSharedState(entry, roomId);
    if (!state) return { error: "Phòng đấu chưa được khởi tạo", state: null };

    const versionError = checkVersion(state, payload.expectedVersion);
    if (versionError) return { error: versionError.error, code: versionError.code, conflict: true, state };

    const result = payload.action === "SERVER_TICK"
      ? { success: true, changed: tickGameState(state) }
      : applyActionToState(state, seat, payload);
    if (result?.error) return { error: result.error, state };
    if (result?.changed === false) return { state, result, committed: false };

    const commit = await sharedKv.atomic()
      .check({ key: stateKey(roomId), versionstamp: entry.versionstamp })
      .set(stateKey(roomId), state)
      .commit();
    if (commit.ok) {
      return {
        state,
        result,
        committed: true,
        versionstamp: commit.versionstamp,
      };
    }

    const latest = await readSharedState(roomId);
    const expected = Number(payload.expectedVersion);
    if (Number.isFinite(expected) && expected > 0 && latest.state?.version !== expected) {
      return {
        error: `Conflict: State version mismatch (expected: ${payload.expectedVersion}, current: ${latest.state?.version || 0})`,
        code: "VERSION_CONFLICT",
        conflict: true,
        state: latest.state,
      };
    }
  }

  const latest = await readSharedState(roomId);
  return {
    error: "Máy chủ đang bận, vui lòng thử lại",
    code: "STATE_BUSY",
    conflict: true,
    state: latest.state,
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

async function synchronizeRoom(roomId, room) {
  const shared = await readSharedState(roomId);
  if (!shared.state || shared.versionstamp === room.kvVersionstamp) return;
  const previousVersion = room.state?.version;
  updateLocalRoom(roomId, shared.state, shared.versionstamp);
  if (shared.state.version !== previousVersion || room.sockets.size > 0) {
    broadcastStateUpdate(room, "SHARED_STATE_UPDATE");
  }
}

async function tryAcquireTickLease(roomId) {
  const key = tickLeaseKey(roomId);
  const now = Date.now();
  const lease = await sharedKv.get(key);
  if (lease.value && lease.value.expiresAt > now && lease.value.owner !== instanceId) return false;

  const commit = await sharedKv.atomic()
    .check({ key, versionstamp: lease.versionstamp })
    .set(key, { owner: instanceId, expiresAt: now + 2500 })
    .commit();
  return commit.ok;
}

async function tickSharedRoom(roomId, room) {
  if (!(await tryAcquireTickLease(roomId))) return;
  const result = await mutateSharedState(roomId, undefined, {
    action: "SERVER_TICK",
  });
  if (result.committed) {
    updateLocalRoom(roomId, result.state, result.versionstamp);
    broadcastStateUpdate(room, "SERVER_TICK");
    saveStateToDatabase(roomId, result.state);
  }
}

function broadcastRoom(room, messageObj) {
  const json = JSON.stringify(messageObj);
  for (const [seat, ws] of room.sockets.entries()) {
    if (ws.readyState === WebSocket.OPEN) {
      try {
        if (messageObj.type === "STATE_UPDATE" && messageObj.state) {
          const sanitizedState = sanitizeGameStateForClient(room.state, seat);
          const personalized = {
            ...messageObj,
            state: sanitizedState,
            delta: messageObj.delta
              ? { ...messageObj.delta, targetCardSelection: sanitizedState.targetCardSelection }
              : null,
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
  return Number.isInteger(seat) && seat >= 1 && seat <= 4 ? seat : 0;
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

setInterval(async () => {
  if (roomLoopRunning) return;
  roomLoopRunning = true;
  try {
    for (const [roomId, room] of rooms.entries()) {
      if (!room?.state || room.state.status === "FINISHED") continue;
      try {
        await synchronizeRoom(roomId, room);
        if (Date.now() >= room.nextTickAt) {
          room.nextTickAt = Date.now() + 1000;
          await tickSharedRoom(roomId, room);
        }
      } catch (err) {
        console.error(`[Room Loop Error room ${roomId}]:`, err);
      }
    }
  } finally {
    roomLoopRunning = false;
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

    socket.onopen = () => {};

    socket.onmessage = (event) => {
      messageQueue = messageQueue.then(async () => {
        try {
        const payload = JSON.parse(event.data);
        const { action, roomId, cardId, targetCardId, targetSeat, accepted, cardIds, players, expectedVersion } = payload;
        const requestSeat = normalizeSeat(payload.seat);

        if (!roomId) {
          return socket.send(JSON.stringify({ type: "ERROR", error: "Thiếu roomId" }));
        }

        const isJoinAction = action === "JOIN_ROOM" || action === "INIT_GAME";

        // A connection receives its identity only after a successful join.
        // Thereafter a client cannot switch rooms or impersonate another seat.
        if (!isJoinAction && currentRoomId === null) {
          return socket.send(JSON.stringify({ type: "ERROR", error: "Kết nối chưa tham gia phòng" }));
        }
        if (isJoinAction && requestSeat === 0) {
          return socket.send(JSON.stringify({ type: "ERROR", error: "Ghế không hợp lệ (1-4)" }));
        }
        if (currentRoomId !== null && (roomId !== currentRoomId || (requestSeat !== 0 && requestSeat !== currentSeat))) {
          return socket.send(JSON.stringify({ type: "ERROR", error: "Kết nối đã được khóa vào phòng/ghế khác" }));
        }

        // For bound connections, an omitted seat is resolved to the bound
        // identity; a supplied seat was checked above and cannot differ.
        const boundSeat = currentRoomId !== null ? currentSeat : requestSeat;

        let room = rooms.get(roomId);

        // A. KHỞI TẠO HOẶC THAM GIA PHÒNG ĐẤU
        if (action === "JOIN_ROOM" || action === "INIT_GAME") {
          room = await ensureLocalRoom(roomId, Array.isArray(players) ? players : null);
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

        // D. XỬ LÝ ATOMIC TRÊN STATE DÙNG CHUNG
        const outcome = await mutateSharedState(roomId, boundSeat, {
          action,
          cardId,
          targetCardId,
          targetSeat,
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

        // E. Cập nhật cache cục bộ và phát cho sockets trong isolate này.
        if (outcome.committed) {
          updateLocalRoom(roomId, outcome.state, outcome.versionstamp);
          broadcastStateUpdate(room, action);
          saveStateToDatabase(roomId, outcome.state);
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
      const { action, roomId, seat, cardId, targetCardId, targetSeat, accepted, cardIds, players, expectedVersion } = payload;
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
          return new Response(JSON.stringify({ success: false, error: "Ghế không hợp lệ (1-4)" }), { status: 400 });
        }
        room = await ensureLocalRoom(roomId, Array.isArray(players) ? players : null);
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
        return new Response(JSON.stringify({ success: false, error: "Ghế không hợp lệ (1-4)" }), { status: 400, headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" } });
      }
      if (action !== "INIT_GAME" && !hasSeat(room.state, requestSeat)) {
        return new Response(JSON.stringify({ success: false, error: "Ghế không thuộc phòng đấu" }), { status: 403, headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" } });
      }

      if (action === "GET_STATE") {
        const shared = await readSharedState(roomId);
        if (shared.state) updateLocalRoom(roomId, shared.state, shared.versionstamp);
        const state = shared.state || room.state;
        return new Response(JSON.stringify({ success: true, state: sanitizeGameStateForClient(state, requestSeat || 1) }), {
          headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
        });
      }

      const outcome = await mutateSharedState(roomId, requestSeat, {
        action,
        cardId,
        targetCardId,
        targetSeat,
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
        updateLocalRoom(roomId, outcome.state, outcome.versionstamp);
        broadcastStateUpdate(room, action);
        saveStateToDatabase(roomId, outcome.state);
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
