const ws = new WebSocket("ws://localhost:8080");

ws.onopen = () => {
  console.log("✅ [Client] Connected to Deno Server!");
  const joinMsg = {
    action: "JOIN_ROOM",
    roomId: "room_2v2_test",
    seat: 1,
    players: [
      { userId: "human_1", heroId: "TRAN_HUNG_DAO", isAI: false },
      { userId: "ai_2", heroId: "LY_THUONG_KIET", isAI: true },
      { userId: "ai_3", heroId: "NGUYEN_HUE", isAI: true },
      { userId: "ai_4", heroId: "LE_LOI", isAI: true }
    ]
  };
  ws.send(JSON.stringify(joinMsg));
};

ws.onmessage = (event) => {
  const msg = JSON.parse(event.data);
  console.log("📩 [Client] Received: " + msg.type);
  
  if (msg.type === "STATE_SNAPSHOT" || msg.type === "STATE_UPDATE") {
    const state = msg.state;
    console.log("   ➡️ Phase: " + state.phase + " | Turn Seat: " + state.turnSeat + " | My Hand: " + state.players[0].hand.length + " cards");
    
    if (state.phase === "PLAY" && state.turnSeat === 1) {
      console.log("   🎮 My turn! Trying to play a card or end turn...");
      const slash = state.players[0].hand.find((c: any) => [0, 1, 2].includes(c.subType));
      if (slash && state.slashesUsedThisTurn === 0) {
        console.log("   ⚔️ Playing Slash: " + slash.name + " on Seat 2");
        ws.send(JSON.stringify({
          action: "PLAY_CARD",
          roomId: "room_2v2_test",
          seat: 1,
          cardId: slash.id,
          targetSeat: 2,
          expectedVersion: state.version
        }));
      } else {
        console.log("   ⏭️ Ending turn.");
        ws.send(JSON.stringify({
          action: "END_TURN",
          roomId: "room_2v2_test",
          seat: 1,
          expectedVersion: state.version
        }));
      }
    } else if (state.phase === "AWAIT_SLASH_DEFENSE" && state.waitingTargetSeat === 1) {
      console.log("   🛡️ Defending against Slash! Passing...");
      ws.send(JSON.stringify({
        action: "RESPOND_ACTION",
        roomId: "room_2v2_test",
        seat: 1,
        accepted: false,
        cardId: "",
        expectedVersion: state.version
      }));
    }
  }
};

ws.onerror = (err) => console.error("❌ [Client] Error:", err.message || err);
ws.onclose = () => console.log("🔌 [Client] Disconnected");

setTimeout(() => {
  console.log("⏱️ Test complete, closing client.");
  ws.close();
}, 6000);