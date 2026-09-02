const state = {};
const caster = { hand: [{ id: "c1", name: "Slash", suit: "Spade", rank: 1, subType: "ATTACK_NORMAL", category: "BASIC", desc: "", range: 1, distMod: 0 }] };
const cardIndex = 0;
const selectedCard = caster.hand[cardIndex];

const realCard = caster.hand.splice(cardIndex, 1)[0];
let card = { ...selectedCard }; 
card.originalCard = { id: realCard.id, name: realCard.name, suit: realCard.suit, rank: realCard.rank, subType: realCard.subType, category: realCard.category, desc: realCard.desc, range: realCard.range, distMod: realCard.distMod };

state.activeCard = card;

try {
  JSON.stringify(state);
  console.log("No circular reference");
} catch (e) {
  console.log(e.message);
}
