import { initGame, handlePlayCard, handleRespondAction, handleEndTurn, handleDiscardCards, handleAIStep, handleAIReaction } from './functions/game-engine/src/gameEngine.js';
import { isSlash, isDodge, isPeach, isWine } from './functions/game-engine/src/deck.js';

let totalSteps = 0;
let stuckGames = 0;
const GAMES = 100;
const MAX_STEPS = 2000;

for (let g = 0; g < GAMES; g++) {
    const state = initGame('test-room-' + g, [
        {userId:'u1',generalName:'P1',maxHp:4,isAI:true},
        {userId:'u2',generalName:'P2',maxHp:4,isAI:true},
        {userId:'u3',generalName:'P3',maxHp:4,isAI:true},
        {userId:'u4',generalName:'P4',maxHp:4,isAI:true}
    ]);
    
    let steps = 0;
    
    function autoRespond(st) {
        if (st.status === 'FINISHED') return;
        
        if (st.phase === 'AWAIT_SLASH_DEFENSE') {
            const target = st.players.find(p => p.seat === st.waitingTargetSeat);
            if (!target || target.hp <= 0) { handleRespondAction(st, st.waitingTargetSeat, false, null); return; }
            const caster = st.players.find(p => p.seat === st.activeCard?.casterSeat);
            const hasHolyCannon = caster?.equipments?.some(c => c.name?.includes('Súng Thần Công'));
            const dodge = target.hand.find(c => isDodge(c)
                && (!hasHolyCannon || c.suit !== st.activeCard?.suit));
            handleRespondAction(st, target.seat, !!dodge, dodge ? dodge.id : null);
        } else if (st.phase === 'AWAIT_AOE') {
            const target = st.players.find(p => p.seat === st.waitingTargetSeat);
            if (!target || target.hp <= 0) { handleRespondAction(st, st.waitingTargetSeat, false, null); return; }
            const req = st.waitingReactionType;
            let card = null;
            if (req === 'DODGE') card = target.hand.find(c => isDodge(c));
            else if (req === 'SLASH') card = target.hand.find(c => isSlash(c));
            handleRespondAction(st, target.seat, !!card, card ? card.id : null);
        } else if (st.phase === 'AWAIT_DUEL') {
            const target = st.players.find(p => p.seat === st.waitingTargetSeat);
            if (!target || target.hp <= 0) { handleRespondAction(st, st.waitingTargetSeat, false, null); return; }
            const slash = target.hand.find(c => isSlash(c));
            handleRespondAction(st, target.seat, !!slash, slash ? slash.id : null);
        } else if (st.phase === 'AWAIT_NEAR_DEATH') {
            const victim = st.players.find(p => p.seat === st.nearDeathVictimSeat);
            const asker = st.players.find(p => p.seat === st.waitingTargetSeat);
            if (!asker || asker.hp <= 0) { handleRespondAction(st, st.waitingTargetSeat, false, null); return; }
            const isSelf = asker.seat === victim.seat;
            let saveCard = asker.hand.find(c => isPeach(c));
            if (!saveCard && isSelf) saveCard = asker.hand.find(c => isWine(c));
            const willSave = !!saveCard;
            handleRespondAction(st, asker.seat, willSave, willSave ? saveCard.id : null);
        } else if (st.phase === 'AWAIT_NULLIFY') {
            handleRespondAction(st, st.waitingTargetSeat, false, null);
        } else if (st.phase === 'AWAIT_TARGET_CARD') {
            handleAIReaction(st, st.waitingTargetSeat);
        } else if (st.phase === 'AWAIT_HARVEST') {
            const picker = st.players.find(p => p.seat === st.waitingTargetSeat);
            if (st.harvestPool && st.harvestPool.length > 0) {
                handleRespondAction(st, picker.seat, true, st.harvestPool[0].id);
            } else {
                handleRespondAction(st, picker.seat, false, null);
            }
        } else if (st.phase === 'AWAIT_NAM_SON_FOLLOW_UP') {
            const caster = st.players.find(p => p.seat === st.waitingTargetSeat);
            if (!caster || caster.hp <= 0) { handleRespondAction(st, st.waitingTargetSeat, false, null); return; }
            const slash = caster.hand.find(c => isSlash(c));
            handleRespondAction(st, caster.seat, !!slash, slash ? slash.id : null);
        } else if (st.phase === 'AWAIT_SONG_CUNG_FOLLOW_UP') {
            handleAIReaction(st, st.waitingTargetSeat);
        } else if (st.phase === 'DISCARD') {
            const p = st.players.find(pl => pl.seat === st.waitingTargetSeat);
            const excess = p.hand.length - p.hp;
            if (excess > 0) {
                const ids = p.hand.slice(0, excess).map(c => c.id);
                handleDiscardCards(st, p.seat, ids);
            } else {
                handleEndTurn(st, p.seat);
            }
        } else if (st.phase === 'PLAY') {
            const turnPlayer = st.players.find(p => p.seat === st.turnSeat);
            if (!turnPlayer || turnPlayer.hp <= 0) {
                handleEndTurn(st, st.turnSeat);
                return;
            }
            if (turnPlayer.isAI) {
                const res = handleAIStep(st, turnPlayer.seat);
                if (res && res.error) {
                    handleEndTurn(st, turnPlayer.seat);
                }
            }
        }
    }
    
    while (state.status !== 'FINISHED' && steps < MAX_STEPS) {
        steps++;
        autoRespond(state);
    }
    
    totalSteps += steps;
    if (steps >= MAX_STEPS) {
        stuckGames++;
        console.log(`Game ${g} STUCK at phase: ${state.phase}, wait: ${state.waitingTargetSeat}, turn: ${state.turnSeat}`);
    }
}

console.log(`Ran ${GAMES} games.`);
console.log(`Stuck games: ${stuckGames}`);
console.log(`Average steps per game: ${(totalSteps / GAMES).toFixed(1)}`);
