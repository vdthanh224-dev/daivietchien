import assert from "node:assert/strict";
import { readFile, writeFile } from "node:fs/promises";
import vm from "node:vm";

// Exercise the deployed server's socket handlers without opening ports or
// contacting Appwrite. Timers are advanced explicitly by the tests below.
const modules = [];
let source = await readFile(new URL("./server.js", import.meta.url), "utf8");
const imports = [...source.matchAll(/^import\s+\{([\s\S]*?)\}\s+from\s+"([^"]+)";/gm)];
for (const [statement, names, path] of imports) {
  const index = modules.push(await import(new URL(path, import.meta.url))) - 1;
  source = source.replace(statement, `const {${names}} = modules[${index}];`);
}
let handler;
const errors = [];
let randomSeed = 0x5da1;
const seededMath = Object.create(Math);
seededMath.random = () => {
  randomSeed = (Math.imul(1664525, randomSeed) + 1013904223) >>> 0;
  return randomSeed / 0x100000000;
};
const sandbox = {
  modules, URL, Response, TextEncoder, structuredClone, crypto, Math: seededMath,
  console: { log() {}, warn() {}, error: (...args) => errors.push(args.join(" ")) },
  WebSocket: { OPEN: 1, CLOSED: 3 },
  setInterval() {}, setTimeout() {}, clearInterval() {}, clearTimeout() {},
  async fetch() { return new Response(JSON.stringify({ documents: [] }), { status: 200 }); },
  Deno: {
    env: { get() { return undefined; } },
    serve(_options, callback) { handler = callback; },
    upgradeWebSocket(request) { return { socket: request.socket, response: {} }; },
  },
};
source += "\nglobalThis.draftTests = { rooms, makeDraftSlots, draftMessage, tickDraftRoom };";
vm.runInNewContext(source, sandbox, { filename: "server.js" });
const { rooms, makeDraftSlots, draftMessage, tickDraftRoom } = sandbox.draftTests;
const plain = (value) => JSON.parse(JSON.stringify(value));
const fixtures = [];
function recordFixtures(name, clients, modeId, type = "DRAFT_STATE_UPDATE") {
  for (const client of clients) fixtures.push({ name, modeId, seat: client.assignedSeat, message: latest(client, type) });
}

async function connect(payload) {
  const socket = {
    readyState: 1, messages: [],
    send(message) { this.messages.push(JSON.parse(message)); },
    close() { this.readyState = 3; },
  };
  await handler({ headers: new Headers({ upgrade: "websocket" }), socket });
  socket.sendAction = async (action) => {
    socket.onmessage({ data: JSON.stringify(action) });
    await new Promise((resolve) => setImmediate(resolve));
  };
  await socket.sendAction(payload);
  socket.assignedSeat = socket.messages.find((m) => m.type === "DRAFT_JOINED")?.assignedSeat;
  assert(socket.assignedSeat, JSON.stringify(socket.messages));
  return socket;
}

function latest(socket, type = "DRAFT_STATE_UPDATE") {
  const message = socket.messages.findLast((m) => m.type === type);
  assert(message, `Missing ${type}`);
  return message;
}

async function joinRoom(modeId, suffix) {
  const count = modeId === "dynasty_5" ? 5 : (modeId === "dynasty_8" ? 8 : 4);
  const roomId = `draft_privacy_${suffix}`;
  const slots = Array.from({ length: count }, (_, i) => ({
    seatNumber: i + 1, userId: `${suffix}-user-${i + 1}`, userName: `Người chơi ${i + 1}`, isAI: false,
  }));
  const clients = [];
  for (const slot of slots) {
    clients.push(await connect({ action: "JOIN_DRAFT", roomId, modeId, seat: slot.seatNumber,
      ...slot, slots, availableHeroIds: Array.from({ length: 40 }, (_, i) => i + 1) }));
  }
  return { roomId, slots, clients, room: rooms.get(roomId) };
}

function assertPrivateSnapshot(client, modeId, kingHero = 0) {
  const message = latest(client);
  for (const slot of message.slots) {
    const own = slot.seat === client.assignedSeat;
    const publicKing = modeId.startsWith("dynasty_") && slot.role === "KING" && slot.isLocked;
    if (!own && !publicKing) {
      assert.equal(slot.heroId, 0, "Another player's locked hero must stay private");
      assert.equal(slot.heroName, "");
      assert.equal(slot.hoverHeroId, 0);
      assert.equal(slot.hoverHeroName, "");
      assert.deepEqual(slot.candidateHeroIds, []);
      assert(!slot.availableHeroIds?.length);
    }
    if (!own && slot.role !== "KING") assert(!slot.role, "Only one's own role and VUA are public");
  }
  const own = message.slots.find((slot) => slot.seat === client.assignedSeat);
  const allowedIds = new Set([kingHero, own?.heroId].filter(Boolean));
  assert(message.selectedHeroIds.every((id) => allowedIds.has(id)), "The selected-id list must not leak hidden picks");
}

// The five actual players are shuffled, rather than making the lobby host VUA.
const kingUsers = new Set();
for (let i = 0; i < 200; i++) {
  const raw = Array.from({ length: 5 }, (_, n) => ({ seatNumber: n + 1, userId: `person-${n}` }));
  const slots = makeDraftSlots(raw, 1, { modeId: "dynasty_5" });
  assert.deepEqual(plain(slots.map((s) => s.role).sort()), ["KING", "LOYALIST", "REBEL", "REBEL", "SPY"]);
  kingUsers.add(slots.find((s) => s.role === "KING").userId);
}
assert.equal(kingUsers.size, 5, "Every player can receive the VUA role");

for (const modeId of ["dynasty_5", "dynasty_8"]) {
{
  const { roomId, room, clients, slots } = await joinRoom(modeId, modeId);
  const king = clients.find((client) => client.assignedSeat === 1);
  const others = clients.filter((client) => client !== king);
  const roles = clients.map((client) => latest(client).slots.find((s) => s.seat === client.assignedSeat).role);
  assert.deepEqual(roles.sort(), (modeId === "dynasty_5" ? ["KING", "LOYALIST", "REBEL", "REBEL", "SPY"] : ["KING", "LOYALIST", "LOYALIST", "REBEL", "REBEL", "REBEL", "REBEL", "SPY"]));
  for (const client of clients) assert.deepEqual(latest(client).activeSeats, [1]);
  recordFixtures("king_picking", clients, modeId);
  await others[0].sendAction({ action: "PICK_HERO", roomId, heroId: 2 });
  assert.equal(room.draft.slots.filter((slot) => slot.isLocked).length, 0, "Only VUA may pick first");
  await king.sendAction({ action: "HOVER_HERO", roomId, heroId: 1, heroName: "Bí mật xem trước" });
  for (const other of others) assert(!other.messages.some((m) => m.type === "DRAFT_HOVER_UPDATE"));
  await king.sendAction({ action: "PICK_HERO", roomId, heroId: 1 });
  for (const client of clients) {
    assert.deepEqual(latest(client).activeSeats, (modeId === "dynasty_5" ? [2, 3, 4, 5] : [2, 3, 4, 5, 6, 7, 8]), "The remaining four pick simultaneously");
    assert.equal(latest(client).slots.find((s) => s.role === "KING").heroId, 1);
    assertPrivateSnapshot(client, modeId, 1);
  }
  recordFixtures("others_picking", clients, modeId);
  const previous = others[0];
  const previousRole = latest(previous).slots.find((slot) => slot.seat === previous.assignedSeat).role;
  const identity = room.draft.slots.find((slot) => slot.seat === previous.assignedSeat);
  previous.close();
  const resumed = await connect({ action: "JOIN_DRAFT", roomId, modeId: modeId, seat: previous.assignedSeat,
    userId: identity.userId, userName: identity.userName, slots });
  assert.equal(resumed.assignedSeat, previous.assignedSeat, "Reconnect preserves the randomized seat");
  assert.equal(latest(resumed).slots.find((slot) => slot.seat === resumed.assignedSeat).role, previousRole);
  clients[clients.indexOf(previous)] = resumed;
  others[0] = resumed;
  for (const [index, client] of others.entries()) {
    await client.sendAction({ action: "PICK_HERO", roomId, heroId: index + 2 });
    if (index < others.length - 1) {
      for (const viewer of clients) assertPrivateSnapshot(viewer, modeId, 1);
      recordFixtures(`hidden_pick_${index + 1}`, clients, modeId);
    }
  }
  assert(room.state, "A battle starts when all five picks are locked");
  for (const client of clients) {
    const completed = latest(client, "DRAFT_COMPLETED");
    assert(completed.slots.every((slot) => slot.heroId > 0), "All heroes are available on entry into battle");
    for (const player of completed.battlePlayers) {
      if (player.seat !== client.assignedSeat && player.role !== "KING") assert(!player.role, "Battle handoff must keep other roles secret");
    }
  }
  recordFixtures("battle_handoff", clients, modeId, "DRAFT_COMPLETED");
  const stateBeforeReconnect = room.state;
  const identityAfterDraft = room.draft.slots.find((slot) => slot.seat === king.assignedSeat);
  const late = await connect({ action: "JOIN_DRAFT", roomId, modeId: modeId, seat: king.assignedSeat,
    userId: identityAfterDraft.userId, userName: identityAfterDraft.userName, slots });
  assert.equal(rooms.get(roomId).state, stateBeforeReconnect, "A late draft reconnect must not restart the battle or reroll roles");
  assert.equal(latest(late, "DRAFT_COMPLETED").slots.find((slot) => slot.seat === late.assignedSeat).role, "KING");
}

{
  const { roomId, room, clients } = await joinRoom(modeId, `timeout_${modeId}`);
  room.draft.timerStartAt = Date.now() - 41000;
  await tickDraftRoom(roomId, room);
  assert(room.draft.slots[0].isLocked, "An expired VUA turn picks automatically");
  assert.deepEqual(plain(draftMessage(roomId, room.draft).activeSeats), (modeId === "dynasty_5" ? [2, 3, 4, 5] : [2, 3, 4, 5, 6, 7, 8]));
  assert.equal(room.draft.timer, 40, "The four other players receive a fresh timer");
  for (const client of clients) assertPrivateSnapshot(client, modeId, room.draft.slots[0].heroId);
}

}

{
  const { roomId, clients } = await joinRoom("2v2", "teams");
  recordFixtures("team_initial", clients, "2v2");
  for (let seat = 1; seat <= 3; seat++) {
    const picker = clients.find((client) => client.assignedSeat === seat);
    const own = latest(picker).slots.find((slot) => slot.seat === seat);
    const heroId = own.candidateHeroIds[0];
    await picker.sendAction({ action: "HOVER_HERO", roomId, heroId });
    for (const other of clients.filter((c) => c !== picker)) {
      assert(!other.messages.some((m) => m.type === "DRAFT_HOVER_UPDATE" && m.seat === seat), "2v2 previews are private even to teammates");
    }
    await picker.sendAction({ action: "PICK_HERO", roomId, heroId });
    for (const client of clients) assertPrivateSnapshot(client, "2v2");
    recordFixtures(`team_hidden_pick_${seat}`, clients, "2v2");
  }
}

assert.deepEqual(errors, [], "Server handlers must not throw");
if (process.env.DRAFT_FIXTURE_PATH) await writeFile(process.env.DRAFT_FIXTURE_PATH, JSON.stringify(fixtures, null, 2));
console.log("Draft roles, king-first/simultaneous picks, timeouts and hero privacy: PASS");
