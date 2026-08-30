 = Get-Content -Raw "deploy_deno/functions/game-engine/src/gameEngine.js"
 =  -replace '(?s)if \(accepted\) return \{ error: "Cần chọn một lá Diệu Kế Phá Mưu hợp lệ" \};', 'if (accepted && !cardId) return { error: "Cần chọn một lá Diệu Kế Phá Mưu hợp lệ" };'
 =  -replace '(?s)if \(accepted\) return \{ error: "Cần chọn một lá Đỡ hợp lệ" \};', 'if (accepted && !cardId) return { error: "Cần chọn một lá Đỡ hợp lệ" };'
 =  -replace '(?s)if \(accepted\) return \{ error: "Cần chọn một lá Trảm truy kích hợp lệ" \};', 'if (accepted && !cardId) return { error: "Cần chọn một lá Trảm truy kích hợp lệ" };'
 =  -replace '(?s)if \(accepted\) return \{ error: "Cần chọn một lá Trảm hợp lệ để đáp trả" \};', 'if (accepted && !cardId) return { error: "Cần chọn một lá Trảm hợp lệ để đáp trả" };'

Set-Content -Path "deploy_deno/functions/game-engine/src/gameEngine.js" -Value  -NoNewline
