import {
  initGame,
  handlePlayCard,
  handleRespondAction,
  handleEndTurn,
  handleDiscardCards,
  handleAIStep,
  handleAIReaction,
  checkVersion,
  hydrateGameState,
  sanitizeGameStateForClient,
  ensureMutationVersion,
} from "./functions/game-engine/src/gameEngine.js";

const APPWRITE_ENDPOINT = Deno.env.get("APPWRITE_ENDPOINT") || "https://sgp.cloud.appwrite.io/v1";
const PROJECT_ID = Deno.env.get("APPWRITE_PROJECT_ID") || "6a885457002da3f3d47e";
const API_KEY = Deno.env.get("APPWRITE_API_KEY") || "";
const DATABASE_ID = Deno.env.get("DATABASE_ID") || "game";
const COLLECTION_ID = Deno.env.get("COLLECTION_ID") || "matchmaking_queue";

const liveGames = new Map();
const STATE_ENCODING_PREFIX = "GZIP1:";
const MAX_PERSISTED_STATE_CHARS = 8000;

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
    console.error("DB Decode Error:", err);
    return null;
  }
}

async function loadStateFromDatabase(roomId: string): Promise<any | null> {
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
        return await decodePersistedState(doc.userName);
      }
    }
  } catch (err) {
    console.error("DB Load Error:", err);
  }
  return null;
}

async function saveStateToDatabase(roomId: string, state: any): Promise<void> {
  try {
    const docId = `gs_${roomId.replace(/[^a-zA-Z0-9_-]/g, '')}`.substring(0, 36);
    const stateJson = await encodePersistedState(state);
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
    console.error("DB Save Error:", err);
  }
}

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ success: false, error: "Method not allowed" }), { status: 405 });
  }

  try {
    const payload = await req.json();
    const { action, roomId, seat, cardId, targetCardId, targetSeat, accepted, cardIds, players, expectedVersion } = payload;

    if (!roomId) {
      return new Response(JSON.stringify({ success: false, error: "Thiếu roomId" }), { status: 400 });
    }

    let state = liveGames.get(roomId);

    if (action === "INIT_GAME") {
      if (!state) {
        const persistedState = await loadStateFromDatabase(roomId);
        if (persistedState) {
          state = hydrateGameState(persistedState, roomId);
          if (state) liveGames.set(roomId, state);
        }
      }
      if (state) {
        const requestedSeat = Number(seat);
        if (!state.players.some((player: any) => player.seat === requestedSeat)) {
          return new Response(JSON.stringify({ success: false, error: "Ghế không thuộc phòng đấu" }), { status: 403 });
        }
        return new Response(JSON.stringify({ success: true, state: sanitizeGameStateForClient(state, requestedSeat) }), {
          headers: { "Content-Type": "application/json" },
        });
      }
      if (!Array.isArray(players) || players.length !== 4) {
        return new Response(JSON.stringify({ success: false, error: "Cần đủ thông tin 4 người chơi" }), { status: 400 });
      }
      state = initGame(roomId, players);
      liveGames.set(roomId, state);
      await saveStateToDatabase(roomId, state);
      return new Response(JSON.stringify({ success: true, state: sanitizeGameStateForClient(state, seat) }), {
        headers: { "Content-Type": "application/json" },
      });
    }

    if (!state) {
      state = await loadStateFromDatabase(roomId);
      if (state) {
        state = hydrateGameState(state, roomId);
        if (state) liveGames.set(roomId, state);
      } else {
        return new Response(JSON.stringify({ success: false, error: "Phòng đấu chưa được khởi tạo GameState" }), { status: 404 });
      }
      if (!state) {
        return new Response(JSON.stringify({ success: false, error: "GameState trong Database không hợp lệ" }), { status: 500 });
      }
    }

    const versionError = checkVersion(state, expectedVersion);
    if (versionError) {
      return new Response(JSON.stringify({
        success: false,
        error: versionError.error,
        code: versionError.code,
        state: sanitizeGameStateForClient(state, seat)
      }), { status: 409 });
    }

    const previousVersion = state.version;
    let result: any;
    if (action === "GET_STATE") {
      return new Response(JSON.stringify({ success: true, state: sanitizeGameStateForClient(state, seat) }), {
        headers: { "Content-Type": "application/json" },
      });
    } else if (action === "PLAY_CARD") {
      result = handlePlayCard(state, seat, cardId, targetSeat);
    } else if (action === "RESPOND_ACTION") {
      result = handleRespondAction(state, seat, accepted, cardId, targetCardId, cardIds);
    } else if (action === "END_TURN") {
      result = handleEndTurn(state, seat);
    } else if (action === "DISCARD_CARDS") {
      result = handleDiscardCards(state, seat, cardIds);
    } else if (action === "AI_STEP") {
      result = handleAIStep(state, seat);
    } else if (action === "AI_REACTION") {
      result = handleAIReaction(state, seat);
    } else {
      return new Response(JSON.stringify({ success: false, error: "Hành động không được hỗ trợ" }), { status: 400 });
    }

    if (result && result.error) {
      return new Response(JSON.stringify({ success: false, error: result.error, state: sanitizeGameStateForClient(state, seat) }), { status: 400 });
    }

    ensureMutationVersion(state, previousVersion);

    await saveStateToDatabase(roomId, state);
    return new Response(JSON.stringify({ success: true, state: sanitizeGameStateForClient(state, seat) }), {
      headers: { "Content-Type": "application/json" },
    });

  } catch (err: any) {
    console.error("Server Error:", err);
    return new Response(JSON.stringify({ success: false, error: err.message }), { status: 500 });
  }
});
