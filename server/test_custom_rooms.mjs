import assert from "node:assert/strict";
import { createCustomRoomStore, mergeAppwriteMatchmakingRooms, normalizeRoomCode } from "./custom_room_store.js";

// 1. Code normalization
assert.equal(normalizeRoomCode("482913"), "482913");
assert.equal(normalizeRoomCode(" #482 913 "), "482913");
assert.equal(normalizeRoomCode("12345"), "");
assert.equal(normalizeRoomCode("12ab56"), "");

// 2. Unique 6-digit code generation & collisions skipped cleanly
let seq = 0;
const deterministicSeq = [0.0, 0.0, 0.0, 0.25];
const store = createCustomRoomStore({
  nowFn: () => 1700000000000,
  randomFn: () => deterministicSeq[Math.min(seq++, deterministicSeq.length - 1)],
});

const r1 = store.createRoom({ userId: "u1", userName: "Host 1", rankIndex: 2, rankStars: 3, rankPoints: 15, level: 4 }, "2v2");
assert.equal(r1.ok, true);
assert.match(r1.room.code, /^\d{6}$/);
assert.equal(r1.room.modeId, "2v2");
assert.equal(r1.room.slots.length, 2, "2v2 custom room must expose exactly 2 duo slots");
assert.equal(r1.room.slots[0].isDragon, true);
assert.equal(r1.room.slots[1].isDragon, true, "Both 2v2 duo slots must belong to same team");

const r2 = store.createRoom({ userId: "u2", userName: "Host 2", rankPoints: 20 }, "dynasty_5");
assert.equal(r2.ok, true);
assert.match(r2.room.code, /^\d{6}$/);
assert.notEqual(r1.room.code, r2.room.code, "Two active rooms must receive distinct 6-digit IDs");
assert.equal(r2.room.slots.length, 5, "dynasty_5 room must expose 5 slots");

// 3. Join room by 6-digit ID + same-team 2v2 matchmaking seed + full rejection
const badJoin = store.joinRoom("999999", { userId: "u3", userName: "Guest 3" });
assert.equal(badJoin.ok, false);

const join2v2 = store.joinRoom(r1.room.code, { userId: "u3", userName: "Guest 3", rankPoints: 12 });
assert.equal(join2v2.ok, true);
assert.equal(join2v2.room.slots[1].userId, "u3");
assert.equal(join2v2.room.slots[1].isDragon, true);

const full2v2 = store.joinRoom(r1.room.code, { userId: "u4", userName: "Guest 4" });
assert.equal(full2v2.ok, false, "3rd player cannot enter a 2-slot 2v2 duo room");

const start2v2 = store.startRoom(r1.room.code, "u1");
assert.equal(start2v2.ok, true);
assert.equal(start2v2.kind, "MATCHMAKING");
assert.equal(start2v2.matchRoom.slots.length, 4);
assert.equal(start2v2.matchRoom.slots[0].userId, "u1");
assert.equal(start2v2.matchRoom.slots[0].isDragon, true);
assert.equal(start2v2.matchRoom.slots[1].isEmpty, true);
assert.equal(start2v2.matchRoom.slots[1].isDragon, false);
assert.equal(start2v2.matchRoom.slots[2].userId, "u3", "2nd duo player must sit at seat 3 (Dragon teammate)");
assert.equal(start2v2.matchRoom.slots[2].isDragon, true);
assert.equal(start2v2.matchRoom.slots[3].isEmpty, true);
assert.equal(start2v2.matchRoom.slots[3].isDragon, false);

const cancel2v2 = store.cancelMatchmaking(r1.room.code, "u1");
assert.equal(cancel2v2.ok, true);
assert.equal(cancel2v2.room.status, "WAITING");

// 4. Mode switch constraints + Dynasty 5 direct start when 5/5 full vs matchmaking when < 5
for (const uid of ["u5", "u6", "u7"]) {
  assert.equal(store.joinRoom(r2.room.code, { userId: uid, userName: `Player ${uid}` }).ok, true);
}
const denyDowngrade = store.setMode(r2.room.code, "u2", "2v2");
assert.equal(denyDowngrade.ok, false, "Cannot downgrade 4-player room to 2v2 (2 slots)");
assert.equal(store.setMode(r2.room.code, "u2", "dynasty_8").ok, true);
assert.equal(r2.room.slots.length, 8);
assert.equal(store.setMode(r2.room.code, "u2", "dynasty_5").ok, true);
assert.equal(r2.room.slots.length, 5);

// Partial 4/5 dynasty -> enters matchmaking with 1 empty seat
const partialStart = store.startRoom(r2.room.code, "u2");
assert.equal(partialStart.ok, true);
assert.equal(partialStart.kind, "MATCHMAKING");
assert.equal(partialStart.matchRoom.slots.filter((s) => !s.isEmpty).length, 4);
assert.equal(partialStart.matchRoom.slots.filter((s) => s.isEmpty).length, 1);
assert.equal(store.cancelMatchmaking(r2.room.code, "u2").ok, true);

// Full 5/5 dynasty -> starts direct draft without public matchmaking
assert.equal(store.joinRoom(r2.room.code, { userId: "u8", userName: "Player u8" }).ok, true);
const fullDynastyStart = store.startRoom(r2.room.code, "u2");
assert.equal(fullDynastyStart.ok, true);
assert.equal(fullDynastyStart.kind, "DIRECT_DRAFT");
assert.equal(fullDynastyStart.matchRoom.status, "STARTED");
assert.equal(fullDynastyStart.matchRoom.slots.filter((s) => !s.isEmpty).length, 5);

// 5. Kick, leave, and host promotion
const r3 = store.createRoom({ userId: "h1", userName: "Host A" }, "dynasty_8");
assert.equal(r3.room.slots.length, 8);
assert.equal(store.joinRoom(r3.room.code, { userId: "g1", userName: "Guest 1" }).ok, true);
assert.equal(store.joinRoom(r3.room.code, { userId: "g2", userName: "Guest 2" }).ok, true);
const kicked = store.kickMember(r3.room.code, "h1", 2);
assert.equal(kicked.ok, true);
assert.equal(kicked.kickedUserId, "g1");
const hostLeft = store.leaveRoom("h1", r3.room.code);
assert.equal(hostLeft.ok, true);
assert.equal(hostLeft.room.hostUserId, "g2", "Host role must transfer when original host leaves");

// 6. Matchmaking merge preserves 2v2 duo team pair & dynasty party atomicity
const duoAnchor = {
  roomId: "rc_111111_a",
  modeId: "2v2",
  slots: [
    { seatNumber: 1, userId: "a1", userName: "A1", isDragon: true, isAI: false, isEmpty: false },
    { seatNumber: 2, userId: "empty", userName: "", isDragon: false, isAI: false, isEmpty: true },
    { seatNumber: 3, userId: "a2", userName: "A2", isDragon: true, isAI: false, isEmpty: false },
    { seatNumber: 4, userId: "empty", userName: "", isDragon: false, isAI: false, isEmpty: true },
  ],
};
const duoSource = {
  roomId: "rc_222222_b",
  modeId: "2v2",
  slots: [
    { seatNumber: 1, userId: "b1", userName: "B1", isDragon: true, isAI: false, isEmpty: false },
    { seatNumber: 2, userId: "empty", userName: "", isDragon: false, isAI: false, isEmpty: true },
    { seatNumber: 3, userId: "b2", userName: "B2", isDragon: true, isAI: false, isEmpty: false },
    { seatNumber: 4, userId: "empty", userName: "", isDragon: false, isAI: false, isEmpty: true },
  ],
};
const mergeDuos = mergeAppwriteMatchmakingRooms(duoAnchor, duoSource);
assert.equal(mergeDuos.changed, true);
assert.deepEqual(mergeDuos.assignedSeats, [2, 4]);
assert.equal(duoAnchor.slots[1].userId, "b1");
assert.equal(duoAnchor.slots[1].isDragon, false);
assert.equal(duoAnchor.slots[3].userId, "b2");
assert.equal(duoAnchor.slots[3].isDragon, false, "Second duo must stay together on Team Phoenix");

const mixedAnchor = {
  roomId: "room_solo_mix",
  modeId: "2v2",
  slots: [
    { seatNumber: 1, userId: "s1", userName: "S1", isDragon: true, isAI: false, isEmpty: false },
    { seatNumber: 2, userId: "s2", userName: "S2", isDragon: false, isAI: false, isEmpty: false },
    { seatNumber: 3, userId: "empty", userName: "", isDragon: true, isAI: false, isEmpty: true },
    { seatNumber: 4, userId: "empty", userName: "", isDragon: false, isAI: false, isEmpty: true },
  ],
};
const blockedSplit = mergeAppwriteMatchmakingRooms(mixedAnchor, duoSource);
assert.equal(blockedSplit.changed, false, "Must NEVER split a 2v2 duo across opposite teams");

const dynastyAnchor = {
  roomId: "room_dynasty_anchor",
  modeId: "dynasty_5",
  slots: [
    { seatNumber: 1, userId: "d1", userName: "D1", isDragon: true, isAI: false, isEmpty: false },
    { seatNumber: 2, userId: "d2", userName: "D2", isDragon: false, isAI: false, isEmpty: false },
    { seatNumber: 3, userId: "d3", userName: "D3", isDragon: false, isAI: false, isEmpty: false },
    { seatNumber: 4, userId: "empty", userName: "", isDragon: false, isAI: false, isEmpty: true },
    { seatNumber: 5, userId: "empty", userName: "", isDragon: false, isAI: false, isEmpty: true },
  ],
};
const dynastyParty3 = {
  roomId: "rc_333333_c",
  modeId: "dynasty_5",
  slots: [
    { seatNumber: 1, userId: "p1", userName: "P1", isDragon: true, isAI: false, isEmpty: false },
    { seatNumber: 2, userId: "p2", userName: "P2", isDragon: false, isAI: false, isEmpty: false },
    { seatNumber: 3, userId: "p3", userName: "P3", isDragon: false, isAI: false, isEmpty: false },
    { seatNumber: 4, userId: "empty", userName: "", isDragon: false, isAI: false, isEmpty: true },
    { seatNumber: 5, userId: "empty", userName: "", isDragon: false, isAI: false, isEmpty: true },
  ],
};
assert.equal(mergeAppwriteMatchmakingRooms(dynastyAnchor, dynastyParty3).changed, false, "Must not split a 3-player dynasty party into 2 empty seats");

console.log("CUSTOM ROOM STORE & PARTY MATCHMAKING MERGE TESTS: PASS");

// 7. End-to-end verification against actual server.js WebSocket handlers (zero Appwrite reads!)
import { readFile } from "node:fs/promises";
import vm from "node:vm";

const modules = [];
let source = await readFile(new URL("./server.js", import.meta.url), "utf8");
for (const [statement, names, modPath] of [...source.matchAll(/^import\s+\{([\s\S]*?)\}\s+from\s+"([^"]+)";/gm)]) {
  const index = modules.push(await import(new URL(modPath, import.meta.url))) - 1;
  source = source.replace(statement, `const {${names}} = modules[${index}];`);
}

let handler;
let fetchCount = 0;
const sandbox = {
  modules,
  URL,
  Response,
  TextEncoder,
  structuredClone,
  crypto,
  Date,
  console: { log() {}, warn() {}, error() {} },
  WebSocket: { OPEN: 1, CLOSED: 3 },
  setInterval() {},
  setTimeout() {},
  clearInterval() {},
  clearTimeout() {},
  fetch: () => {
    fetchCount += 1;
    return Promise.resolve({ ok: true, json: async () => ({ documents: [] }) });
  },
  Deno: {
    env: { get() { return undefined; } },
    serve(_options, callback) { handler = callback; },
    upgradeWebSocket(request) { return { socket: request.socket, response: {} }; },
  },
};
source += "\nglobalThis.customRoomWsTests = { rooms, customRoomStore };";
vm.runInNewContext(source, sandbox, { filename: "server.js" });

async function connectSocket(userId, userName) {
  const socket = {
    readyState: 1,
    messages: [],
    send(raw) { this.messages.push(JSON.parse(raw)); },
    close() { this.readyState = 3; if (this.onclose) this.onclose(); },
  };
  await handler({ headers: new Headers({ upgrade: "websocket" }), socket });
  socket.act = async (payload) => {
    socket.onmessage({ data: JSON.stringify({ userId, userName, ...payload }) });
    await new Promise((r) => setImmediate(r));
  };
  return socket;
}
const lastMsg = (sock, type) => sock.messages.findLast((m) => m.type === type);

const s1 = await connectSocket("ws_u1", "Vua Trần");
const s2 = await connectSocket("ws_u2", "Tướng Lý");

await s1.act({ action: "CUSTOM_ROOM_CREATE", modeId: "2v2", rankIndex: 1, rankStars: 2, rankPoints: 8 });
const wsRoom2v2 = lastMsg(s1, "CUSTOM_ROOM_STATE")?.room;
assert.ok(wsRoom2v2 && /^\d{6}$/.test(wsRoom2v2.code), "WS CUSTOM_ROOM_CREATE must assign 6-digit code");
assert.equal(wsRoom2v2.lobbySlots, 2);

await s2.act({ action: "CUSTOM_ROOM_JOIN", code: wsRoom2v2.code, rankPoints: 6 });
assert.equal(lastMsg(s1, "CUSTOM_ROOM_STATE").room.memberCount, 2);
assert.equal(lastMsg(s2, "CUSTOM_ROOM_STATE").room.memberCount, 2);

await s1.act({ action: "CUSTOM_ROOM_START", code: wsRoom2v2.code });
assert.equal(lastMsg(s1, "CUSTOM_ROOM_MATCHMAKING").modeId, "2v2");
assert.equal(lastMsg(s2, "CUSTOM_ROOM_MATCHMAKING").modeId, "2v2");
const mSlots = lastMsg(s1, "CUSTOM_ROOM_MATCHMAKING").matchRoom.slots;
assert.equal(mSlots[0].userId, "ws_u1");
assert.equal(mSlots[2].userId, "ws_u2");
assert.equal(mSlots[0].isDragon, true);
assert.equal(mSlots[2].isDragon, true);

await s1.act({ action: "CUSTOM_ROOM_REDIRECT_MATCH", code: wsRoom2v2.code, newMatchRoomId: "rc_anchor_99" });
assert.equal(lastMsg(s2, "CUSTOM_ROOM_PARTY_REDIRECT").matchRoomId, "rc_anchor_99");

await s1.act({ action: "CUSTOM_ROOM_CANCEL_MATCH", code: wsRoom2v2.code });
assert.equal(lastMsg(s2, "CUSTOM_ROOM_STATE").returnedFromMatchmaking, true);

// Test Dynasty 5 direct draft flow with 5 sockets (ZERO Appwrite fetches!)
const s3 = await connectSocket("ws_u3", "P3");
const s4 = await connectSocket("ws_u4", "P4");
const s5 = await connectSocket("ws_u5", "P5");
await s1.act({ action: "CUSTOM_ROOM_SET_MODE", code: wsRoom2v2.code, modeId: "dynasty_5" });
for (const sock of [s3, s4, s5]) {
  await sock.act({ action: "CUSTOM_ROOM_JOIN", code: wsRoom2v2.code });
}
assert.equal(lastMsg(s1, "CUSTOM_ROOM_STATE").room.memberCount, 5);
await s1.act({ action: "CUSTOM_ROOM_START", code: wsRoom2v2.code });
const started5 = lastMsg(s5, "CUSTOM_ROOM_STARTED");
assert.ok(started5 && started5.roomId, "Full 5/5 Dynasty room must emit CUSTOM_ROOM_STARTED directly");
assert.equal(started5.room.slots.length, 5);
const mySeat5 = started5.room.slots.find((sl) => sl.userId === "ws_u5").seatNumber;
await s5.act({ action: "JOIN_DRAFT", roomId: started5.roomId, seat: mySeat5, modeId: "dynasty_5", slots: started5.room.slots });
assert.equal(lastMsg(s5, "DRAFT_JOINED").assignedSeat, mySeat5, "JOIN_DRAFT must bind into the directly started draft room");
assert.equal(fetchCount, 0, "Custom room creation, join, and full Dynasty start must perform 0 Appwrite calls");

// Test disconnect promotes remaining member cleanly in a waiting room
const d1 = await connectSocket("dc_1", "DC Host");
const d2 = await connectSocket("dc_2", "DC Guest");
await d1.act({ action: "CUSTOM_ROOM_CREATE", modeId: "dynasty_8" });
const dcCode = lastMsg(d1, "CUSTOM_ROOM_STATE").room.code;
await d2.act({ action: "CUSTOM_ROOM_JOIN", code: dcCode });
d1.close();
await new Promise((r) => setImmediate(r));
assert.equal(lastMsg(d2, "CUSTOM_ROOM_STATE").room.hostUserId, "dc_2");

console.log("CUSTOM ROOM WEBSOCKET END-TO-END TESTS: PASS");
