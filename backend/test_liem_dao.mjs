import assert from "node:assert/strict";
import { initGame, handlePlayCard, handleRespondAction } from "./functions/game-engine/src/gameEngine.js";
import { CARD_SUBTYPES } from "./functions/game-engine/src/deck.js";

const state = initGame("liem-dao", [1, 2, 3, 4].map((seat) => ({ seat, generalName: `P${seat}`, maxHp: 4 })));
const caster = state.players[0];
caster.equipments = [{ id: "liem-dao", name: "Liêm Đao Đống Đa", subType: CARD_SUBTYPES.WEAPON }];
caster.hand = [
  { id: "slash-1", name: "Trảm Thường", subType: CARD_SUBTYPES.ATTACK_NORMAL, suit: "Spade" },
  { id: "slash-2", name: "Trảm Thường", subType: CARD_SUBTYPES.ATTACK_NORMAL, suit: "Club" },
];

handlePlayCard(state, 1, "slash-1", 2);
const beforeDraw = caster.hand.length;
handleRespondAction(state, 2, false, null);
assert.equal(caster.hand.length, beforeDraw + 1);

state.phase = "PLAY";
state.slashesUsedThisTurn = 0;
handlePlayCard(state, 1, "slash-2", 2);
const afterFirstDraw = caster.hand.length;
handleRespondAction(state, 2, false, null);
assert.equal(caster.hand.length, afterFirstDraw);

console.log("Liêm Đao: PASS");
