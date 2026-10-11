import assert from "node:assert/strict";

const url = process.env.TEST_WS_URL || "ws://127.0.0.1:18081";
const roomId = `admin_draft_${Date.now()}`;
const slots = [1, 2, 3, 4].map((seat) => ({
  seatNumber: seat, userId: `admin-test-${seat}`, userName: `Test ${seat}`, isAI: false,
}));
const clients = [];
function waitFor(client, predicate, timeout = 5000) {
  return new Promise((resolve, reject) => {
    const poll = setInterval(() => {
      const found = client.messages.find(predicate);
      if (found) { clearInterval(poll); clearTimeout(timer); resolve(found); }
    }, 10);
    const timer = setTimeout(() => { clearInterval(poll); reject(new Error("Draft timeout")); }, timeout);
  });
}
try {
  for (const seat of [1, 2, 3, 4]) {
    const client = { socket: new WebSocket(url), messages: [] };
    clients.push(client);
    client.socket.addEventListener("message", (event) => client.messages.push(JSON.parse(event.data)));
    await new Promise((resolve, reject) => {
      client.socket.addEventListener("open", resolve, { once: true });
      client.socket.addEventListener("error", reject, { once: true });
    });
    client.socket.send(JSON.stringify({
      action: "JOIN_DRAFT", roomId, seat, ...slots[seat - 1], slots,
      isAdmin: seat === 2, availableHeroIds: Array.from({ length: seat === 2 ? 100 : 40 }, (_, i) => i + 1),
    }));
    await waitFor(client, (message) => message.type === "DRAFT_JOINED");
  }
  const first = await waitFor(clients[0], (message) => message.type === "DRAFT_STATE_UPDATE" && message.slots[0].candidateHeroIds?.length === 8);
  const firstHero = first.slots[0].candidateHeroIds[0];
  clients[0].socket.send(JSON.stringify({ action: "PICK_HERO", roomId, seat: 1, heroId: firstHero }));
  const admin = await waitFor(clients[1], (message) => message.type === "DRAFT_STATE_UPDATE" && message.slots[0].isLocked && message.slots[1].candidateHeroIds?.length === 99);
  assert(!admin.slots[1].candidateHeroIds.includes(firstHero), "Admin cannot pick a locked hero");
  assert(admin.slots[1].candidateHeroIds.includes(100), "Admin can pick beyond hero 40");
  clients[1].socket.send(JSON.stringify({ action: "PICK_HERO", roomId, seat: 2, heroId: 100 }));
  await waitFor(clients[1], (message) => message.type === "DRAFT_STATE_UPDATE" && message.slots[1].isLocked && message.slots[1].heroId === 100);
  const third = await waitFor(clients[2], (message) => message.type === "DRAFT_STATE_UPDATE" && message.slots[1].isLocked && message.slots[2].candidateHeroIds?.length === 8);
  assert(third.slots[2].candidateHeroIds.every((id) => id <= 40 && id !== firstHero), "Normal accounts retain the 8-hero pool");
  console.log("Admin draft integration: PASS");
} finally {
  for (const client of clients) client.socket.close();
}
