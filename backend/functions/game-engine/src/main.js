import { Client, Databases, Query, ID } from 'node-appwrite';
import { gzip, gunzip } from 'node:zlib';
import { promisify } from 'node:util';
import {
  initGame,
  checkVersion,
  handlePlayCard,
  handleRespondAction,
  handleEndTurn,
  handleDiscardCards,
  handleAIStep,
  handleAIReaction,
  sanitizeGameStateForClient
} from './gameEngine.js';

const ENDPOINT = process.env.APPWRITE_FUNCTION_ENDPOINT || "https://sgp.cloud.appwrite.io/v1";
const PROJECT_ID = process.env.APPWRITE_FUNCTION_PROJECT_ID || "6a885457002da3f3d47e";
const API_KEY = process.env.APPWRITE_API_KEY || "";
const DATABASE_ID = process.env.DATABASE_ID || "game";
const COLLECTION_ID = process.env.COLLECTION_ID || "matchmaking_queue";

// In-memory cache cho các trận đấu đang diễn ra để phản hồi siêu tốc (<15ms)
const liveGames = new Map();
const gzipAsync = promisify(gzip);
const gunzipAsync = promisify(gunzip);
const STATE_ENCODING_PREFIX = 'GZIP1:';
const MAX_PERSISTED_STATE_CHARS = 8000;

async function encodePersistedState(value) {
  const compressed = await gzipAsync(Buffer.from(JSON.stringify(value), 'utf8'));
  const encoded = STATE_ENCODING_PREFIX + compressed.toString('base64');
  if (encoded.length > MAX_PERSISTED_STATE_CHARS) {
    throw new Error(`Serialized GameState exceeds Appwrite limit (${encoded.length} chars)`);
  }
  return encoded;
}

async function decodePersistedState(value) {
  if (!value) return null;
  if (!value.startsWith(STATE_ENCODING_PREFIX)) {
    try { return JSON.parse(value); } catch { return null; }
  }
  try {
    const compressed = Buffer.from(value.slice(STATE_ENCODING_PREFIX.length), 'base64');
    const json = await gunzipAsync(compressed);
    return JSON.parse(json.toString('utf8'));
  } catch (err) {
    console.error('[GameEngine DB Decode Error]:', err);
    return null;
  }
}

export default async ({ req, res, log, error }) => {
  try {
    const payload = typeof req.body === 'string' ? JSON.parse(req.body || '{}') : (req.body || {});
    const { action, roomId, seat, cardId, targetSeat, accepted, cardIds, players, expectedVersion } = payload;

    if (!roomId) {
      return res.json({ success: false, error: "Thiếu roomId" }, 400);
    }

    log(`[GameEngine] Request: action=${action}, roomId=${roomId}, seat=${seat}, expectedVersion=${expectedVersion}`);

    let state = liveGames.get(roomId);

    // 1. Khởi tạo trận đấu
    if (action === "INIT_GAME") {
      if (!Array.isArray(players) || players.length < 4) {
        return res.json({ success: false, error: "Cần đủ thông tin 4 người chơi để bắt đầu trận" }, 400);
      }
      state = initGame(roomId, players);
      liveGames.set(roomId, state);
      await saveStateToDatabase(roomId, state, log, error);
      return res.json({ success: true, state: sanitizeGameStateForClient(state, seat) });
    }

    // Nếu chưa có state trong RAM, thử đọc từ Appwrite Database
    if (!state) {
      state = await loadStateFromDatabase(roomId, log, error);
      if (state) {
        liveGames.set(roomId, state);
      } else {
        return res.json({ success: false, error: "Phòng đấu chưa được khởi tạo GameState" }, 404);
      }
    }

    // 2. Lấy trạng thái hiện tại (GET_STATE)
    if (action === "GET_STATE") {
      return res.json({ success: true, state: sanitizeGameStateForClient(state, seat) });
    }

    // ─── OPTIMISTIC LOCKING CHECK ───
    const versionConflict = checkVersion(state, expectedVersion);
    if (versionConflict) {
      log(`[GameEngine Conflict] Expected v${expectedVersion} but current is v${state.version}`);
      return res.json({
        success: false,
        error: versionConflict.error,
        code: "VERSION_CONFLICT",
        state: sanitizeGameStateForClient(state, seat)
      }, 409);
    }

    // 3. Đánh bài (PLAY_CARD)
    if (action === "PLAY_CARD") {
      const result = handlePlayCard(state, seat, cardId, targetSeat);
      if (result.error) {
        return res.json({ success: false, error: result.error, state: sanitizeGameStateForClient(state, seat) });
      }
      await saveStateToDatabase(roomId, state, log, error);
      return res.json({ success: true, state: sanitizeGameStateForClient(state, seat), delta: state.lastDelta });
    }

    // 4. Phản hồi đòn đánh / cẩm nang (RESPOND_ACTION)
    if (action === "RESPOND_ACTION") {
      const result = handleRespondAction(state, seat, accepted, cardId);
      if (result.error) {
        return res.json({ success: false, error: result.error, state: sanitizeGameStateForClient(state, seat) });
      }
      await saveStateToDatabase(roomId, state, log, error);
      return res.json({ success: true, state: sanitizeGameStateForClient(state, seat), delta: state.lastDelta });
    }

    // 5. Kết thúc lượt (END_TURN)
    if (action === "END_TURN") {
      const result = handleEndTurn(state, seat);
      if (result.error) {
        return res.json({ success: false, error: result.error, state: sanitizeGameStateForClient(state, seat) });
      }
      await saveStateToDatabase(roomId, state, log, error);
      return res.json({ success: true, state: sanitizeGameStateForClient(state, seat), delta: state.lastDelta });
    }

    // 6. Bỏ bài thừa (DISCARD_CARDS)
    if (action === "DISCARD_CARDS") {
      const result = handleDiscardCards(state, seat, cardIds);
      if (result.error) {
        return res.json({ success: false, error: result.error, state: sanitizeGameStateForClient(state, seat) });
      }
      await saveStateToDatabase(roomId, state, log, error);
      return res.json({ success: true, state: sanitizeGameStateForClient(state, seat), delta: state.lastDelta });
    }

    // 7. AI tự động thực hiện bước đánh (AI_STEP)
    if (action === "AI_STEP") {
      const result = handleAIStep(state, seat);
      if (result.error) {
        return res.json({ success: false, error: result.error, state: sanitizeGameStateForClient(state, seat) });
      }
      await saveStateToDatabase(roomId, state, log, error);
      return res.json({ success: true, state: sanitizeGameStateForClient(state, seat), delta: state.lastDelta });
    }

    // 8. AI tự động phản ứng đòn đánh (AI_REACTION)
    if (action === "AI_REACTION") {
      const result = handleAIReaction(state, seat);
      if (result.error) {
        return res.json({ success: false, error: result.error, state: sanitizeGameStateForClient(state, seat) });
      }
      await saveStateToDatabase(roomId, state, log, error);
      return res.json({ success: true, state: sanitizeGameStateForClient(state, seat), delta: state.lastDelta });
    }

    return res.json({ success: false, error: "Hành động không được hỗ trợ" }, 400);

  } catch (err) {
    error(`[GameEngine Error] ${err.message}\n${err.stack}`);
    return res.json({ success: false, error: err.message }, 500);
  }
};

/**
 * Lưu GameState vào Appwrite Database Document
 */
async function saveStateToDatabase(roomId, state, log, error) {
  try {
    const client = new Client().setEndpoint(ENDPOINT).setProject(PROJECT_ID);
    if (API_KEY) client.setKey(API_KEY);
    const db = new Databases(client);

    const docId = `gs_${roomId.replace(/[^a-zA-Z0-9_-]/g, '')}`.substring(0, 36);
    // Persist the complete authoritative state so restart recovery retains
    // reaction queues, delayed judgements, and duel/near-death bookkeeping.
    const stateJson = await encodePersistedState(state);

    const docData = {
      userId: "GAME_STATE",
      userName: stateJson,
      rankPoints: state.turnSeat,
      timestamp: Date.now()
    };

    const permissions = ["read(\"any\")", "update(\"any\")", "delete(\"any\")"];

    try {
      await db.updateDocument(DATABASE_ID, COLLECTION_ID, docId, docData, permissions);
      log(`[GameEngine DB] Đã cập nhật GameState cho docId=${docId}`);
    } catch (updateErr) {
      if (updateErr.code === 404) {
        await db.createDocument(DATABASE_ID, COLLECTION_ID, docId, docData, permissions);
        log(`[GameEngine DB] Đã tạo mới GameState cho docId=${docId}`);
      } else {
        throw updateErr;
      }
    }
  } catch (dbErr) {
    error(`[GameEngine DB Error] Không thể lưu Database: ${dbErr.message}`);
  }
}

/**
 * Đọc GameState từ Appwrite Database Document
 */
async function loadStateFromDatabase(roomId, log, error) {
  try {
    const client = new Client().setEndpoint(ENDPOINT).setProject(PROJECT_ID);
    if (API_KEY) client.setKey(API_KEY);
    const db = new Databases(client);

    const docId = `gs_${roomId.replace(/[^a-zA-Z0-9_-]/g, '')}`.substring(0, 36);
    const doc = await db.getDocument(DATABASE_ID, COLLECTION_ID, docId);
    if (doc && doc.userName) {
      return await decodePersistedState(doc.userName);
    }
  } catch (err) {
    log(`[GameEngine DB] Chưa tìm thấy GameState trong DB cho phòng ${roomId}`);
  }
  return null;
}
