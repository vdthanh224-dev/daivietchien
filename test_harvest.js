import { startNullifyChain } from './deno-server/gameEngine.js';

let state = {
  status: "PLAYING",
  phase: "AWAIT_HARVEST",
  waitingTargetSeat: 1,
  harvestPool: [{id: "2", name: "Card 2"}],
  harvestPickers: [2],
  activeCard: { cardId: "3", cardName: "Kho", casterSeat: 1 },
  _discard: [],
  _deck: [{id: "4", name: "Card 4"}],
  players: [
    {seat: 1, hp: 4, hand: [], generalName: "A", isAI: false},
    {seat: 2, hp: 4, hand: [], generalName: "B", isAI: true}
  ],
  actionHistory: []
};

let res = startNullifyChain(state, {id: "3", name: "Kho", subType: "HARVEST"}, 1, 2, {type: "CONTINUE_HARVEST"});
console.log("Phase:", res.state.phase);
console.log("Waiting Seat:", res.state.waitingTargetSeat);
