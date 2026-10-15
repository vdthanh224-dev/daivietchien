import assert from 'node:assert/strict';

// Create private eight-player fixtures through the normal WebSocket protocol.
// No cards/state are injected, and no existing user rooms are touched.
const url = process.env.TEST_WS_URL || 'ws://127.0.0.1:18081';
const targets = (process.env.TARGET_SEATS || '5,6,7,8').split(',').map(Number);
const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));
async function connect() {
  const socket = new WebSocket(url);
  const client = { socket, messages: [] };
  socket.addEventListener('message', (e) => client.messages.push(JSON.parse(e.data)));
  await new Promise((resolve, reject) => {
    const timer = setTimeout(() => { socket.close(); reject(new Error('Connection timed out')); }, 20000);
    socket.addEventListener('open', () => { clearTimeout(timer); resolve(); }, { once: true });
    socket.addEventListener('error', () => { clearTimeout(timer); reject(new Error('Connection failed')); }, { once: true });
  });
  client.send = async (payload) => {
    const start = client.messages.length;
    socket.send(JSON.stringify(payload));
    const deadline = Date.now() + 10000;
    while (Date.now() < deadline) {
      const reply = client.messages.slice(start).find((m) => ['STATE_SNAPSHOT', 'STATE_UPDATE', 'ACTION_REJECTED', 'ERROR', 'CONFLICT'].includes(m.type)
        && (m.type !== 'STATE_UPDATE' || m.action === payload.action));
      if (reply) {
        assert(!['ACTION_REJECTED', 'ERROR', 'CONFLICT'].includes(reply.type), `${payload.action} to seat ${payload.targetSeat || '-'} rejected: ${reply.error}`);
        return reply.state;
      }
      await sleep(20);
    }
    throw new Error(`No response to ${payload.action}`);
  };
  return client;
}

for (const targetSeat of targets) {
  let exercised = false;
  for (let attempt = 0; attempt < 6 && !exercised; attempt++) {
    const clients = [];
    const roomId = `seatprobe_${Date.now().toString(36)}_${targetSeat}_${attempt}`;
    try {
      for (let seat = 1; seat <= 8; seat++) clients.push(await connect());
      // Tế Giang lets a real slash reach any seat while nobody has a horse.
      const players = Array.from({ length: 8 }, (_, i) => ({ seat: i + 1, heroId: 'HERO_29',
        userId: `${roomId}_${i + 1}`, userName: `Seat probe ${i + 1}`, isAI: false }));
      let state = await clients[0].send({ action: 'JOIN_ROOM', roomId, seat: 1, modeId: 'ffa_8', players });
      for (let seat = 2; seat <= 8; seat++) await clients[seat - 1].send({ action: 'JOIN_ROOM', roomId, seat, modeId: 'ffa_8' });
      const caster = state.players.find((p) => p.seat === 1);
      const selected = caster.hand.find((c) => [0, 1, 2, 11, 14, 21, 22].includes(c.subType));
      if (!selected) continue;
      state = await clients[0].send({ action: 'PLAY_CARD', roomId, seat: 1, cardId: selected.id, targetSeat });
      for (let i = 0; i < 16 && state.phase === 'AWAIT_NULLIFY'; i++) {
        const seat = state.waitingTargetSeat;
        state = await clients[seat - 1].send({ action: 'RESPOND_ACTION', roomId, seat, accepted: false });
      }
      assert(!state.players.find((p) => p.seat === 1).hand.some((c) => c.id === selected.id), 'Played card must leave the caster hand');
      const target = state.players.find((p) => p.seat === targetSeat);
      if ([21, 22].includes(selected.subType)) assert(target.judgements.some((c) => c.id === selected.id));
      else if (selected.subType === 11) assert.equal(state.targetCardSelection?.targetSeat, targetSeat);
      else {
        assert.equal(state.waitingTargetSeat, targetSeat);
        assert.equal(state.activeCard?.targetSeat, targetSeat);
      }
      exercised = true;
      console.log(`PASS: live card subtype ${selected.subType} reaches seat ${targetSeat}`);
    } finally {
      for (const client of clients) if (client.socket.readyState < WebSocket.CLOSING) client.socket.close();
    }
  }
  assert(exercised, `Could not draw a suitable targeting card for seat ${targetSeat}`);
}
console.log('PASS: live targeting seats 5–8');
