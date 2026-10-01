import assert from "node:assert/strict";

const url = process.env.TEST_WS_URL || "ws://127.0.0.1:8080";
const roomId = `draft_4_clients_${Date.now()}`;
const clients = [1, 2, 3, 4].map((seat) => ({
  requestedSeat: 1,
  userId: `debug-user-${seat}`,
  userName: `Debug ${seat}`,
  socket: new WebSocket(url),
  assignedSeat: 0,
  messages: [],
}));

const slots = [1, 2, 3, 4].map((seat) => ({
  seatNumber: seat,
  userId: `debug-user-${seat}`,
  userName: `Debug ${seat}`,
  isAI: false,
  isDragon: seat === 1 || seat === 4,
  isEmpty: false,
}));

function waitForOpen(client) {
  return new Promise((resolve, reject) => {
    client.socket.addEventListener("open", resolve, { once: true });
    client.socket.addEventListener("error", reject, { once: true });
  });
}

function waitFor(client, predicate, timeoutMs = 5000) {
  const existing = client.messages.find(predicate);
  if (existing) return Promise.resolve(existing);
  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => reject(new Error(`Timeout waiting for client ${client.userId}`)), timeoutMs);
    const onMessage = (event) => {
      const message = JSON.parse(event.data);
      client.messages.push(message);
      if (predicate(message)) {
        clearTimeout(timer);
        client.socket.removeEventListener("message", onMessage);
        resolve(message);
      }
    };
    client.socket.addEventListener("message", onMessage);
  });
}

for (const client of clients) {
  client.socket.addEventListener("message", (event) => {
    client.messages.push(JSON.parse(event.data));
  });
}

await Promise.all(clients.map(waitForOpen));
for (const client of clients) {
  client.socket.send(JSON.stringify({
    action: "JOIN_DRAFT",
    roomId,
    seat: client.requestedSeat,
    userId: client.userId,
    userName: client.userName,
    slots,
  }));
}

await Promise.all(clients.map(async (client) => {
  const joined = await waitFor(client, (message) => message.type === "DRAFT_JOINED");
  client.assignedSeat = Number(joined.assignedSeat);
}));

assert.deepEqual(clients.map((client) => client.assignedSeat).sort((a, b) => a - b), [1, 2, 3, 4]);
assert.deepEqual(
  clients.map((client) => [client.userId, client.assignedSeat]).sort(),
  [["debug-user-1", 1], ["debug-user-2", 2], ["debug-user-3", 3], ["debug-user-4", 4]],
);

let pickerSeat = 1;
for (const heroId of [1, 2, 3, 4]) {
  const picker = clients.find((client) => client.assignedSeat === pickerSeat);
  assert.ok(picker, `Missing client for seat ${pickerSeat}`);
  picker.socket.send(JSON.stringify({
    action: "PICK_HERO",
    roomId,
    seat: picker.assignedSeat,
    heroId,
    heroName: `Tướng ${heroId}`,
  }));
  pickerSeat += 1;
}

const completed = await Promise.all(clients.map((client) => waitFor(client, (message) => message.type === "DRAFT_COMPLETED")));
for (const message of completed) {
  assert.deepEqual(message.battlePlayers.map((player) => player.seat), [1, 2, 3, 4]);
  assert.equal(message.battlePlayers.filter((player) => player.isAlly).length, 2);
  assert.deepEqual(message.battlePlayers.map((player) => player.userId), [
    "debug-user-1",
    "debug-user-2",
    "debug-user-3",
    "debug-user-4",
  ]);
}

for (const client of clients) client.socket.close();
console.log("4 WebSocket clients draft seats: PASS");

const duplicateRoomId = `draft_4_duplicate_identity_${Date.now()}`;
const duplicateClients = [1, 2, 3, 4].map((seat) => ({
  requestedSeat: seat,
  userId: "shared-debug-user",
  userName: "Shared Debug",
  socket: new WebSocket(url),
  assignedSeat: 0,
  messages: [],
}));

for (const client of duplicateClients) {
  client.socket.addEventListener("message", (event) => {
    client.messages.push(JSON.parse(event.data));
  });
}
await Promise.all(duplicateClients.map(waitForOpen));
for (const client of duplicateClients) {
  client.socket.send(JSON.stringify({
    action: "JOIN_DRAFT",
    roomId: duplicateRoomId,
    seat: client.requestedSeat,
    debugSeat: client.requestedSeat,
    userId: client.userId,
    userName: client.userName,
    slots: [1, 2, 3, 4].map((seat) => ({
      seatNumber: seat,
      userId: "shared-debug-user",
      userName: "Shared Debug",
      isAI: false,
      isDragon: false,
    })),
  }));
}
await Promise.all(duplicateClients.map(async (client) => {
  const joined = await waitFor(client, (message) => message.type === "DRAFT_JOINED");
  client.assignedSeat = Number(joined.assignedSeat);
}));
assert.deepEqual(duplicateClients.map((client) => client.assignedSeat).sort((a, b) => a - b), [1, 2, 3, 4]);
for (const client of duplicateClients) client.socket.close();
console.log("4 duplicate-identity debug clients draft seats: PASS");
