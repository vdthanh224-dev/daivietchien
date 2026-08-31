import { executeCardEffect } from './deno-server/gameEngine.js';

let state = {
  status: "PLAYING",
  phase: "AWAIT_NULLIFY",
  turnSeat: 1,
  _discard: [],
  players: [
    {seat: 1, hp: 4, hand: [], generalName: "A"},
    {seat: 2, hp: 4, hand: [{id: "5"}], generalName: "B"}
  ],
  actionHistory: []
};

let res = executeCardEffect(state, {id: "3", subType: "DISMANTLE", name: "Dismantle"}, 1, 2);
console.log("Result:", res.success);
console.log("Error:", res.error);
console.log("Phase:", state.phase);
console.log("Waiting:", state.waitingTargetSeat);
