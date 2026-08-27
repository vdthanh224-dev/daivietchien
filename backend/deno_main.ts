import {
  initGame,
  handlePlayCard,
  handleRespondAction,
  handleEndTurn,
  handleDiscardCards,
  handleAIStep,
  handleAIReaction,
  sanitizeGameStateForClient,
} from "./functions/game-engine/src/gameEngine.js";

const APPWRITE_ENDPOINT = Deno.env.get("APPWRITE_ENDPOINT") || "https://sgp.cloud.appwrite.io/v1";
const PROJECT_ID = Deno.env.get("APPWRITE_PROJECT_ID") || "6a885457002da3f3d47e";
const API_KEY = Deno.env.get("APPWRITE_API_KEY") || "";
const DATABASE_ID = Deno.env.get("DATABASE_ID") || "game";
const COLLECTION_ID = Deno.env.get("COLLECTION_ID") || "matchmaking_queue";

const liveGames = new Map();

async function loadStateFromDatabase(roomId) {
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
    console.error("DB Load Error:", err);
  }
  return null;
}

async function saveStateToDatabase(roomId, state) {
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
    console.error("DB Save Error:", err);
  }
}

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ success: false, error: "Method not allowed" }), { status: 405 });
  }

  try {
    const payload = await req.json();
    const { action, roomId, seat, cardId, targetSeat, accepted, cardIds, players, expectedVersion } = payload;

    if (!roomId) {
      return new Response(JSON.stringify({ success: false, error: "Thiếu roomId" }), { status: 400 });
    }

    let state = liveGames.get(roomId);

    if (action === "INIT_GAME") {
      if (!Array.isArray(players) || players.length < 4) {
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
        liveGames.set(roomId, state);
      } else {
        return new Response(JSON.stringify({ success: false, error: "Phòng đấu chưa được khởi tạo GameState" }), { status: 404 });
      }
    }

    if (expectedVersion && state.version !== expectedVersion) {
      return new Response(JSON.stringify({
        success: false,
        error: "Conflict: State version mismatch",
        code: "VERSION_CONFLICT",
        state: sanitizeGameStateForClient(state, seat)
      }), { status: 409 });
    }

    let result;
    if (action === "GET_STATE") {
      return new Response(JSON.stringify({ success: true, state: sanitizeGameStateForClient(state, seat) }), {
        headers: { "Content-Type": "application/json" },
      });
    } else if (action === "PLAY_CARD") {
      result = handlePlayCard(state, seat, cardId, targetSeat);
    } else if (action === "RESPOND_ACTION") {
      result = handleRespondAction(state, seat, accepted, cardId);
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

    await saveStateToDatabase(roomId, state);
    return new Response(JSON.stringify({ success: true, state: sanitizeGameStateForClient(state, seat) }), {
      headers: { "Content-Type": "application/json" },
    });

  } catch (err) {
    console.error("Server Error:", err);
    return new Response(JSON.stringify({ success: false, error: err.message }), { status: 500 });
  }
});
