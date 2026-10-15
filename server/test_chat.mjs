import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import vm from "node:vm";
import { createAppwriteChatFixture } from "./test_helpers/appwrite_chat_fixture.mjs";

// Run the actual Render WebSocket handlers with isolated connections and no network.
const modules = [];
let source = await readFile(new URL("./server.js", import.meta.url), "utf8");
for (const [statement, names, path] of [...source.matchAll(/^import\s+\{([\s\S]*?)\}\s+from\s+"([^"]+)";/gm)]) {
  const index = modules.push(await import(new URL(path, import.meta.url))) - 1;
  source = source.replace(statement, `const {${names}} = modules[${index}];`);
}
let handler;
const errors = [];
let testNow = Date.now();
const chatDb = createAppwriteChatFixture();
class TestDate extends Date { static now() { return testNow; } }
const sandbox = {
  modules, URL, Response, TextEncoder, structuredClone, crypto, Date: TestDate,
  console: { log() {}, warn() {}, error: (...args) => errors.push(args.join(" ")) },
  WebSocket: { OPEN: 1, CLOSED: 3 },
  setInterval() {}, setTimeout() {}, clearInterval() {}, clearTimeout() {},
  fetch: chatDb.request,
  Deno: {
    env: { get() {} },
    serve(_options, callback) { handler = callback; },
    upgradeWebSocket(request) { return { socket: request.socket, response: {} }; },
  },
};
source += "\nglobalThis.chatTests = { rooms, lobbyChatSockets };";
vm.runInNewContext(source, sandbox, { filename: "server.js" });
const { rooms, lobbyChatSockets } = sandbox.chatTests;
async function connect(userId) {
  const socket = {
    readyState: 1, messages: [],
    send(message) { this.messages.push(JSON.parse(message)); },
    close() { this.readyState = 3; this.onclose(); },
  };
  await handler({ headers: new Headers({ upgrade: "websocket" }), socket });
  socket.action = async (payload) => {
    socket.onmessage({ data: JSON.stringify(payload) });
    await new Promise((resolve) => setImmediate(resolve));
  };
  if (userId) await socket.action({ action: "SOCIAL_REGISTER", userId, userName: `Tên ${userId}` });
  return socket;
}
const last = (socket, type) => socket.messages.findLast((m) => m.type === type);
const count = (socket) => socket.messages.filter((m) => m.type === "CHAT_MESSAGE").length;
const subscribe = (socket, channel = "lobby", roomId = "") => socket.action({ action: "CHAT_SUBSCRIBE", channel, roomId });
const send = (socket, text, channel = "lobby", roomId = "", extra = {}) => socket.action({ action: "CHAT_SEND", channel, text, roomId, ...extra });

const a = await connect("a");
const b = await connect("b");
const guest = await connect();
await subscribe(guest);
assert.match(last(guest, "CHAT_ERROR").error, /đăng nhập/);
await subscribe(a);
await subscribe(b);
await send(a, "  Xin chào\nĐại Việt!  ", "lobby", "", { userId: "b", userName: "Giả mạo" });
assert.equal(last(a, "CHAT_MESSAGE").text, "Xin chào Đại Việt!");
assert.deepEqual(last(a, "CHAT_MESSAGE"), last(b, "CHAT_MESSAGE"));
assert.equal(last(b, "CHAT_MESSAGE").userName, "Tên a");
assert.equal(count(guest), 0);
await send(a, "Gửi quá nhanh");
assert.match(last(a, "CHAT_ERROR").error, /1 giây/);
assert.equal(count(b), 1);
await subscribe(guest, "bad-channel");
assert.match(last(guest, "CHAT_ERROR").error, /Kênh/);
for (const text of [" \n\t ", "x".repeat(281), {}, null]) {
  const previousCount = count(b);
  await send(a, text);
  assert(last(a, "CHAT_ERROR"));
  assert.equal(count(b), previousCount);
}
const c = await connect("c");
await subscribe(c);
assert.equal(last(c, "CHAT_HISTORY").messages.length, 1);
await b.action({ action: "CHAT_UNSUBSCRIBE", channel: "lobby" });
await send(c, "[b]Văn bản thường[/b]");
assert.equal(count(b), 1);
assert.equal(last(a, "CHAT_MESSAGE").text, "[b]Văn bản thường[/b]");

// A battle room shares messages only with sockets actually bound to that room.
const roomId = "chat-battle";
const slots = Array.from({ length: 4 }, (_, i) => ({ seatNumber: i + 1, userId: `battle${i}`, userName: `Tướng ${i + 1}`, isAI: false }));
for (const [index, socket] of [a, b].entries()) {
  await socket.action({ action: "JOIN_DRAFT", roomId, modeId: "2v2", seat: index + 1,
    ...slots[index], slots, availableHeroIds: [1, 2, 3, 4, 5, 6, 7, 8] });
  assert(last(socket, "DRAFT_JOINED"));
}
await subscribe(a, "battle", roomId);
await subscribe(b, "battle", roomId);
await subscribe(c, "battle", roomId);
assert.match(last(c, "CHAT_ERROR").error, /chưa tham gia/);
a.lastChatSentAt = 0;
await send(a, "Tập trung nào!", "battle", roomId, { seat: 2, userName: "Giả mạo" });
assert.equal(last(b, "CHAT_MESSAGE").channel, "battle");
assert.equal(last(b, "CHAT_MESSAGE").seat, 1);
assert.equal(last(b, "CHAT_MESSAGE").userName, "Tướng 1");
assert(!("role" in last(b, "CHAT_MESSAGE")));
assert(!("heroId" in last(b, "CHAT_MESSAGE")));
assert.equal(last(c, "CHAT_MESSAGE").channel, "lobby");
await subscribe(b, "battle", roomId);
assert.equal(last(b, "CHAT_HISTORY").messages.length, 1);
const before = count(b);
a.lastChatSentAt = 0;
await send(a, "Sai phòng", "battle", "another-room");
assert.equal(count(b), before);
assert.match(last(a, "CHAT_ERROR").error, /chưa tham gia/);
// A replaced/stale socket cannot send using its old seat.
rooms.get(roomId).sockets.set(1, guest);
await send(a, "Kết nối cũ", "battle", roomId);
assert.equal(count(b), before);
rooms.get(roomId).sockets.set(1, a);
// History is bounded and retains the most recent messages.
for (let i = 0; i < 60; i++) {
  testNow += 1100;
  await send(a, `Tin ${i}`, "battle", roomId);
}
await subscribe(b, "battle", roomId);
const history = last(b, "CHAT_HISTORY").messages;
assert.equal(history.length, 50);
assert.equal(history[0].text, "Tin 10");
assert.equal(history.at(-1).text, "Tin 59");
c.close();
assert(!lobbyChatSockets.has(c));
await guest.action(null);
assert(last(guest, "ERROR"));
assert.deepEqual(errors, []);
console.log("PASS: lobby broadcast/history, identity, room isolation, stale sockets, limits, cooldown, cleanup and malformed payloads");
