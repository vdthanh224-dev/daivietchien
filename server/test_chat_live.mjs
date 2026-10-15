import assert from "node:assert/strict";

const url = "wss://daivietchien.onrender.com";
const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));
const clients = [];
async function connect() {
  const socket = new WebSocket(url);
  const client = { socket, packets: [] };
  clients.push(client);
  socket.addEventListener("message", (event) => client.packets.push(JSON.parse(event.data)));
  await new Promise((resolve, reject) => {
    const timer = setTimeout(() => { socket.close(); reject(new Error("WebSocket connection timed out")); }, 15000);
    socket.addEventListener("open", () => { clearTimeout(timer); resolve(); }, { once: true });
    socket.addEventListener("error", () => { clearTimeout(timer); reject(new Error("WebSocket connection failed")); }, { once: true });
  });
  client.send = (data) => socket.send(JSON.stringify(data));
  client.wait = async (predicate, start = 0) => {
    const deadline = Date.now() + 10000;
    while (Date.now() < deadline) {
      const message = client.packets.slice(start).find(predicate);
      if (message) return message;
      await sleep(40);
    }
    throw new Error("Expected WebSocket response timed out");
  };
  return client;
}

async function probe() {
  const client = await connect();
  try {
    client.send({ action: "CHAT_SUBSCRIBE", channel: "battle", roomId: "__chat_protocol_probe__" });
    const reply = await client.wait((m) => m.type === "CHAT_ERROR" || m.type === "ERROR");
    return reply.type === "CHAT_ERROR";
  } finally { client.socket.close(); }
}

try {
  const deadline = Date.now() + 8 * 60 * 1000;
  let available = false;
  while (Date.now() < deadline) {
    try { available = await probe(); } catch {}
    if (available) break;
    console.log("Waiting for Render to activate chat...");
    await sleep(15000);
  }
  assert(available, "Render did not activate chat within eight minutes");
  console.log("PASS: Render recognizes the chat protocol");

  const suffix = Date.now().toString(36) + Math.random().toString(36).slice(2, 5);
  const roomId = `ct${suffix}`;
  const a = await connect();
  const b = await connect();
  const outsider = await connect();
  const slots = Array.from({ length: 4 }, (_, i) => ({
    seatNumber: i + 1, userId: `chat-smoke-${suffix}-${i + 1}`,
    userName: `Kiểm thử ${i + 1}`, isAI: i >= 2,
  }));
  for (const [index, client] of [a, b].entries()) {
    client.send({ action: "JOIN_DRAFT", roomId, seat: index + 1, modeId: "2v2", ...slots[index], slots });
    const joined = await client.wait((m) => m.type === "DRAFT_JOINED" || m.type === "ERROR");
    assert.equal(joined.type, "DRAFT_JOINED", joined.error);
  }
  outsider.send({ action: "JOIN_DRAFT", roomId: `${roomId}x`, seat: 1, modeId: "2v2",
    userId: `chat-outsider-${suffix}`, userName: "Kiểm thử ngoài phòng" });
  const otherJoined = await outsider.wait((m) => m.type === "DRAFT_JOINED" || m.type === "ERROR");
  assert.equal(otherJoined.type, "DRAFT_JOINED", otherJoined.error);
  for (const client of [a, b]) {
    client.send({ action: "CHAT_SUBSCRIBE", channel: "battle", roomId });
    const history = await client.wait((m) => m.type === "CHAT_HISTORY" && m.channel === "battle");
    assert.equal(history.roomId, roomId);
  }
  // Messages only enter this private fixture room; no lobby chat is published.
  const first = `Kiểm thử chat riêng ${suffix}`;
  a.send({ action: "CHAT_SEND", channel: "battle", roomId, text: first });
  const received = await b.wait((m) => m.type === "CHAT_MESSAGE" && m.text === first);
  assert.equal(received.seat, 1);
  assert.equal(received.roomId, roomId);
  const echo = await a.wait((m) => m.type === "CHAT_MESSAGE" && m.id === received.id);
  assert.equal(echo.text, first);
  b.send({ action: "CHAT_SEND", channel: "battle", roomId, text: "Đã nhận, gửi lại thành công." });
  await a.wait((m) => m.type === "CHAT_MESSAGE" && m.seat === 2);
  await sleep(250);
  assert(!outsider.packets.some((m) => m.type === "CHAT_MESSAGE"), "Chat leaked to another room");
  console.log("PASS: two-way live battle chat, sender acknowledgment and room isolation");

  const marker = b.packets.length;
  b.send({ action: "CHAT_SUBSCRIBE", channel: "battle", roomId });
  const history = await b.wait((m) => m.type === "CHAT_HISTORY", marker);
  assert.equal(history.messages.length, 2);
  console.log("PASS: live battle chat history");

  a.send({ action: "SOCIAL_REGISTER", userId: `chat-smoke-${suffix}`, userName: "Kiểm tra kết nối chat" });
  await a.wait((m) => m.type === "SOCIAL_REGISTERED");
  a.send({ action: "CHAT_SUBSCRIBE", channel: "lobby" });
  const lobby = await a.wait((m) => m.type === "CHAT_HISTORY" && m.channel === "lobby");
  assert(Array.isArray(lobby.messages));
  a.send({ action: "CHAT_UNSUBSCRIBE", channel: "lobby" });
  console.log("PASS: live lobby subscription/history (no public messages sent)");
  console.log("LIVE CHAT CHECK: PASS");
} finally {
  for (const client of clients) if (client.socket.readyState < WebSocket.CLOSING) client.socket.close();
}
