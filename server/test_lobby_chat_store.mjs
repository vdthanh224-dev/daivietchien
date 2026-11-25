import assert from "node:assert/strict";
import { createLobbyChatStore, LOBBY_CHAT_DOCUMENT_TYPE } from "./lobby_chat_store.js";
import { createAppwriteChatFixture } from "./test_helpers/appwrite_chat_fixture.mjs";

const db = createAppwriteChatFixture();
const options = { request: db.request, documentsPath: "/databases/game/collections/matchmaking_queue/documents" };
const store = createLobbyChatStore(options);
const message = (i) => ({ id: `message-${i}`, channel: "lobby", roomId: "", userId: `user-${i % 4}`,
  userName: "Người chơi", text: `Tin nhắn số ${i} 👋`, timestamp: 1800000000000 + i });
db.documents.set("unrelated-room", { $id: "unrelated-room", userId: "ROOM_WAITING", timestamp: 1 });
db.documents.set("unrelated-player", { $id: "unrelated-player", userId: "LEADERBOARD_PLAYER", timestamp: 1 });
assert.deepEqual(await store.history(), []);
for (let i = 0; i < 130; i++) await store.append(message(i));
let history = await store.history();
assert.equal(history.length, 50);
assert.deepEqual(history, Array.from({ length: 50 }, (_, i) => message(i + 80)));
assert.equal([...db.documents.values()].filter((d) => d.userId === LOBBY_CHAT_DOCUMENT_TYPE).length, 50);
assert(db.documents.has("unrelated-room") && db.documents.has("unrelated-player"));

// A fresh process/store has no RAM history but reads the same persisted data.
const restarted = createLobbyChatStore(options);
assert.deepEqual(await restarted.history(), history);
await restarted.append(message(129));
assert.equal(db.documents.size, 52, "Retrying the same message is idempotent");
await assert.rejects(restarted.append({ ...message(129), text: "Different text" }), /conflicts/);
await Promise.all(Array.from({ length: 20 }, (_, i) => restarted.append(message(130 + i))));
history = await restarted.history();
assert.deepEqual(history.map((m) => m.id), Array.from({ length: 50 }, (_, i) => `message-${100 + i}`));

db.failWrites = true;
await assert.rejects(restarted.append(message(150)), /save/);
db.failWrites = false;
assert.deepEqual(await restarted.history(), history, "Failed writes cannot appear as sent messages");
db.failReads = true;
await assert.rejects(restarted.history(), /read/);
db.failReads = false;
await restarted.append(message(150));
assert.equal((await restarted.history()).at(-1).id, "message-150", "The queue recovers after storage failures");

// A failed prune keeps a successfully persisted message; later sends retry it.
db.failDeletes = true;
await restarted.append(message(151));
assert.equal((await restarted.history()).length, 50);
assert.equal((await restarted.history()).at(-1).id, "message-151");
db.failDeletes = false;
await restarted.append(message(152));
assert.equal(db.documents.size, 52);

// Same-millisecond messages still retain insertion order at the boundary.
const tiedDb = createAppwriteChatFixture();
const tied = createLobbyChatStore({ ...options, request: tiedDb.request });
for (let i = 0; i < 110; i++) await tied.append({ ...message(i), timestamp: 1800000000000 });
assert.deepEqual((await tied.history()).map((m) => m.id), Array.from({ length: 50 }, (_, i) => `message-${i + 60}`));
assert.rejects(store.append({ ...message(200), channel: "battle" }), /Invalid/);

// Verify Appwrite read quota optimizations:
// 1) When stored total <= limit (known from history()), appending causes 0 list/prune reads.
// 2) When stored total exceeds limit by 1 page, prune() stops after 1 list() instead of a trailing empty query.
const quotaDb = createAppwriteChatFixture();
let getCount = 0;
const countedRequest = async (path, reqOptions = {}) => {
  if ((reqOptions.method || "GET") === "GET") getCount += 1;
  return quotaDb.request(path, reqOptions);
};
const quotaStore = createLobbyChatStore({ ...options, request: countedRequest });
for (let i = 0; i < 38; i++) await quotaStore.append(message(i));
await quotaStore.history();
const readsAfterBaseline = getCount;
for (let i = 38; i < 50; i++) await quotaStore.append(message(i));
assert.equal(getCount, readsAfterBaseline, "Appending while total <= limit must trigger 0 prune reads");
await quotaStore.append(message(50));
assert.equal(getCount - readsAfterBaseline, 1, "Pruning a single overflow item must perform only 1 list read");
assert.equal((await quotaStore.history()).length, 50);

console.log("PASS: durable 50-message lobby history, restart, retention, concurrent sends, idempotency, isolation and recovery");
