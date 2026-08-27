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

console.log("🎮 [Deno Server] Đại Việt Chiến 2v2 Unified Game Server is running!");

// Authoritative 1-second server tick loop for all active rooms on RAM
setInterval(() => {
  for (const [roomId, room] of rooms.entries()) {
    if (room && room.state && room.state.status === "PLAYING") {
      try {
        const changed = tickGameState(room.state);
        if (changed) {
          room.lastActivity = Date.now();
          broadcastRoom(room, {
            type: "STATE_UPDATE",
            state: room.state,
            delta: room.state.lastDelta || null,
            version: room.state.version,
            action: "SERVER_TICK"
          });
        }
      } catch (err) {
        console.error(`[Tick Error room ${roomId}]:`, err);
      }
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
        return JSON.parse(doc.userName);
      }
    }
  } catch (err) {
    console.error("[DB Load Error]:", err);
  }
  return null;
}

async function saveStateToDatabase(roomId: string, state: any) {
  if (!API_KEY) return; // Nếu không có API Key, chỉ chạy In-Memory
  const docId = `gs_${roomId.replace(/[^a-zA-Z0-9_-]/g, '')}`.substring(0, 36);
  const sanitized = sanitizeGameStateForClient(state, 0);
  const stateJson = JSON.stringify({
    ...sanitized,
    _deck: state._deck,
    _discard: state._discard,
  });

  const docData = {
    userId: "GAME_STATE",
    userName: stateJson.substring(0, 8100),
    rankPoints: state.turnSeat,
    timestamp: Date.now(),
  };

  const permissions = ["read(\"any\")", "update(\"any\")", "delete(\"any\")"];

  try {
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

function broadcastRoom(room: RoomData, messageObj: any) {
  const json = JSON.stringify(messageObj);
  for (const [seat, ws] of room.sockets.entries()) {
    if (ws.readyState === WebSocket.OPEN) {
      try {
        if (messageObj.type === "STATE_UPDATE" && messageObj.state) {
          const personalized = {
            ...messageObj,
            state: sanitizeGameStateForClient(room.state, seat),
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

Deno.serve({ port: Number(Deno.env.get("PORT")) || 8080 }, async (req) => {
  const upgrade = req.headers.get("upgrade") || "";

  // 1. WEBSOCKET REALTIME CONNECTION (<15ms)
  if (upgrade.toLowerCase() === "websocket") {
    const { socket, response } = Deno.upgradeWebSocket(req);

    let currentRoomId: string | null = null;
    let currentSeat = 0;

    socket.onopen = () => {};

    socket.onmessage = async (event) => {
      try {
        const payload = JSON.parse(event.data);
        const { action, roomId, seat, cardId, targetSeat, accepted, cardIds, players, expectedVersion } = payload;

        if (!roomId) {
          return socket.send(JSON.stringify({ type: "ERROR", error: "Thiếu roomId" }));
        }

        currentRoomId = roomId;
        if (seat) currentSeat = seat;

        let room = rooms.get(roomId);

        // A. KHỞI TẠO HOẶC THAM GIA PHÒNG ĐẤU
        if (action === "JOIN_ROOM" || action === "INIT_GAME") {
          if (!room) {
            if (!Array.isArray(players) || players.length < 4) {
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

          room.sockets.set(seat, socket);
          room.lastActivity = Date.now();

          // Gửi Snapshot đầy đủ cho người vừa kết nối
          socket.send(JSON.stringify({
            type: "STATE_SNAPSHOT",
            state: sanitizeGameStateForClient(room.state, seat),
            version: room.state.version,
          }));

          broadcastRoom(room, {
            type: "PLAYER_JOINED",
            seat: seat,
            activeSeats: Array.from(room.sockets.keys()),
          });
          return;
        }

        if (!room) {
          return socket.send(JSON.stringify({ type: "ERROR", error: "Phòng đấu không tồn tại hoặc đã kết thúc" }));
        }

        room.sockets.set(seat, socket);
        room.lastActivity = Date.now();

        // B. LẤY SNAPSHOT TRẠNG THÁI HIỆN TẠI
        if (action === "GET_STATE") {
          return socket.send(JSON.stringify({
            type: "STATE_SNAPSHOT",
            state: sanitizeGameStateForClient(room.state, seat),
            version: room.state.version,
          }));
        }

        // C. HEARTBEAT PING / PONG
        if (action === "PING") {
          return socket.send(JSON.stringify({ type: "PONG", timestamp: Date.now() }));
        }

        // D. KIỂM TRA KHÓA LẠC QUAN (OPTIMISTIC LOCKING)
        const vCheck = checkVersion(room.state, expectedVersion);
        if (vCheck) {
          return socket.send(JSON.stringify({
            type: "CONFLICT",
            error: vCheck.error,
            code: "VERSION_CONFLICT",
            state: sanitizeGameStateForClient(room.state, seat),
          }));
        }

        let result: any = null;

        // E. XỬ LÝ HÀNH ĐỘNG ĐÁNH BÀI TRÊN RAM SIÊU TỐC
        if (action === "PLAY_CARD") {
          result = handlePlayCard(room.state, seat, cardId, targetSeat);
        } else if (action === "RESPOND_ACTION") {
          result = handleRespondAction(room.state, seat, accepted, cardId);
        } else if (action === "END_TURN") {
          result = handleEndTurn(room.state, seat);
        } else if (action === "DISCARD_CARDS") {
          result = handleDiscardCards(room.state, seat, cardIds);
        } else if (action === "AI_STEP") {
          result = handleAIStep(room.state, seat);
        } else if (action === "AI_REACTION") {
          result = handleAIReaction(room.state, seat);
        } else {
          return socket.send(JSON.stringify({ type: "ERROR", error: "Hành động không hợp lệ" }));
        }

        if (result && result.error) {
          return socket.send(JSON.stringify({
            type: "ACTION_REJECTED",
            error: result.error,
            state: sanitizeGameStateForClient(room.state, seat),
          }));
        }

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
      if (currentRoomId) {
        const room = rooms.get(currentRoomId);
        if (room) {
          room.sockets.delete(currentSeat);
          if (room.sockets.size === 0) {
            setTimeout(() => {
              const r = rooms.get(currentRoomId!);
              if (r && r.sockets.size === 0 && Date.now() - r.lastActivity > 600000) {
                rooms.delete(currentRoomId!);
                console.log(`[Deno] Đã dọn dẹp phòng trống: ${currentRoomId}`);
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
      const { action, roomId, seat, cardId, targetSeat, accepted, cardIds, players, expectedVersion } = payload;

      if (!roomId) {
        return new Response(JSON.stringify({ success: false, error: "Thiếu roomId" }), {
          status: 400,
          headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
        });
      }

      let room = rooms.get(roomId);

      if (action === "INIT_GAME") {
        if (!Array.isArray(players) || players.length < 4) {
          return new Response(JSON.stringify({ success: false, error: "Cần đủ thông tin 4 người chơi" }), { status: 400 });
        }
        const state = initGame(roomId, players);
        room = { state, sockets: new Map(), lastActivity: Date.now() };
        rooms.set(roomId, room);
        saveStateToDatabase(roomId, state);
        return new Response(JSON.stringify({ success: true, state: sanitizeGameStateForClient(state, seat || 1) }), {
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

      if (expectedVersion && room.state.version !== expectedVersion) {
        return new Response(JSON.stringify({
          success: false,
          error: "Conflict: State version mismatch",
          code: "VERSION_CONFLICT",
          state: sanitizeGameStateForClient(room.state, seat || 1),
        }), { status: 409 });
      }

      let result: any = null;
      if (action === "GET_STATE") {
        return new Response(JSON.stringify({ success: true, state: sanitizeGameStateForClient(room.state, seat || 1) }), {
          headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
        });
      } else if (action === "PLAY_CARD") {
        result = handlePlayCard(room.state, seat, cardId, targetSeat);
      } else if (action === "RESPOND_ACTION") {
        result = handleRespondAction(room.state, seat, accepted, cardId);
      } else if (action === "END_TURN") {
        result = handleEndTurn(room.state, seat);
      } else if (action === "DISCARD_CARDS") {
        result = handleDiscardCards(room.state, seat, cardIds);
      } else if (action === "AI_STEP") {
        result = handleAIStep(room.state, seat);
      } else if (action === "AI_REACTION") {
        result = handleAIReaction(room.state, seat);
      } else {
        return new Response(JSON.stringify({ success: false, error: "Hành động không hợp lệ" }), { status: 400 });
      }

      if (result && result.error) {
        return new Response(JSON.stringify({ success: false, error: result.error, state: sanitizeGameStateForClient(room.state, seat || 1) }), { status: 400 });
      }

      // Phát sóng cập nhật qua WebSocket nếu có người đang kết nối
      broadcastRoom(room, {
        type: "STATE_UPDATE",
        state: room.state,
        delta: room.state.lastDelta || null,
        version: room.state.version,
        action: action,
      });

      saveStateToDatabase(roomId, room.state);

      return new Response(JSON.stringify({ success: true, state: sanitizeGameStateForClient(room.state, seat || 1) }), {
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
