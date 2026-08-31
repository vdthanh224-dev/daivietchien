const fs = require('fs');
let code = fs.readFileSync('deno-server/gameEngine.js', 'utf8');
code = code.replace(/if \(canAIReact && elapsed >= 2 && elapsed < 40\) \{\s*handleAIReaction\(state, waitingSeat\);\s*important = true;\s*state.timerStartAt = Date\.now\(\);\s*return \{ changed: true, important \};\s*\}/g,
  "if (canAIReact && elapsed >= 2 && elapsed < 40) {\n        const res = handleAIReaction(state, waitingSeat);\n        if (res && res.error) {\n            console.log(\"[AI ERROR]\", res.error, state.phase, waitingSeat);\n            return { changed: false, important: false };\n        }\n        important = true;\n        state.timerStartAt = Date.now();\n        return { changed: true, important };\n      }");
fs.writeFileSync('deno-server/gameEngine.js', code);
