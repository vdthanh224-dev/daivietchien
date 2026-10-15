import { createLobbyChatStore } from "./lobby_chat_store.js";

// One-time migration from the old RAM-only Render service. Subscribe/read only:
// this script never sends CHAT_SEND or publishes a test message to players.
const watch = process.argv.includes("--watch");
const store = createLobbyChatStore({
  documentsPath: "/databases/game/collections/matchmaking_queue/documents",
  request: (path, options = {}) => fetch(`https://sgp.cloud.appwrite.io/v1${path}${path.includes("?") ? "&" : "?"}chat_nonce=${Date.now()}`, {
    ...options, headers: { "Content-Type": "application/json", "X-Appwrite-Project": "6a885457002da3f3d47e", "Cache-Control": "no-cache" },
  }),
});
const socket = new WebSocket("wss://daivietchien.onrender.com");
let pending = Promise.resolve();
let receivedHistory = false;
let failure;
let copied = 0;
const timeout = setTimeout(() => { failure = new Error("History migration timed out"); socket.close(); }, watch ? 600000 : 30000);
const heartbeat = setInterval(() => { if (socket.readyState === WebSocket.OPEN) socket.send(JSON.stringify({ action: "PING" })); }, 20000);
const closed = new Promise((resolve) => socket.addEventListener("close", resolve, { once: true }));
socket.addEventListener("open", () => socket.send(JSON.stringify({ action: "SOCIAL_REGISTER",
  userId: `history-migration-${Date.now()}`, userName: "Kiểm tra lịch sử" })));
socket.addEventListener("error", () => { failure = new Error("History migration connection failed"); socket.close(); });
socket.addEventListener("message", (event) => {
  pending = pending.then(async () => {
    const data = JSON.parse(event.data);
    if (data.type === "SOCIAL_REGISTERED") socket.send(JSON.stringify({ action: "CHAT_SUBSCRIBE", channel: "lobby" }));
    if (data.type === "CHAT_ERROR" || data.type === "ERROR") throw new Error(data.error || "History migration failed");
    if (data.type === "CHAT_HISTORY" && data.channel === "lobby") {
      for (const message of data.messages.slice(-50)) { await store.append(message); copied++; }
      receivedHistory = true;
      console.log(`Preserved ${copied} existing lobby messages in Appwrite`);
      if (!watch) socket.close();
    }
    if (data.type === "CHAT_MESSAGE" && data.channel === "lobby") { await store.append(data); copied++; }
  }).catch((error) => { failure = error; socket.close(); });
});
await closed;
clearTimeout(timeout);
clearInterval(heartbeat);
await pending;
if (failure) throw failure;
if (!receivedHistory) throw new Error("Server closed before sending lobby history");
console.log(`Migration complete: ${copied} messages preserved; no messages published`);
