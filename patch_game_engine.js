const fs = require('fs');
let content = fs.readFileSync('deno-server/gameEngine.js', 'utf8');

const oldTick = 'const newTimer = Math.max(0, 40 - elapsed);\n    \n    if (state.waitingTargetSeat > 0) {';
const newTick = 'let timeLimit = 40;\n    if (state.phase === "AWAIT_JUDGEMENT") timeLimit = 3;\n    const newTimer = Math.max(0, timeLimit - elapsed);\n\n    if (state.phase === "AWAIT_JUDGEMENT") {\n       if (state.waitingTimer !== newTimer) {\n         state.waitingTimer = newTimer;\n         changed = true;\n       }\n       if (elapsed >= timeLimit) {\n         applyPendingJudgement(state);\n         important = true;\n         state.timerStartAt = Date.now();\n         return { changed: true, important };\n       }\n       return { changed, important };\n    }\n\n    if (state.waitingTargetSeat > 0) {';
content = content.replace(oldTick, newTick);

const oldHydrate = 'if (state.targetCardSelection && typeof state.targetCardSelection === "object") {';
const newHydrate = 'if (state.pendingJudgement && typeof state.pendingJudgement === "object") {\n    state.pendingJudgement = { ...state.pendingJudgement };\n  } else {\n    state.pendingJudgement = null;\n  }\n  ' + oldHydrate;
content = content.replace(oldHydrate, newHydrate);

const oldSanitize = 'targetCardSelection: sanitizeTargetCardSelection(state.targetCardSelection, requestingSeat),';
const newSanitize = 'pendingJudgement: state.pendingJudgement || null,\n      targetCardSelection: sanitizeTargetCardSelection(state.targetCardSelection, requestingSeat),';
content = content.replace(oldSanitize, newSanitize);

fs.writeFileSync('deno-server/gameEngine.js', content);
