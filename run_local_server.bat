@echo off
chcp 65001 >nul
title Dai Viet Chien - Local Game Server (Port 8080)
cd /d "%~dp0deno-server"
echo ============================================================
echo   DAI VIET CHIEN - MAY CHU CUC BO (PORT 8080)
echo   Dang chay tai: http://localhost:8080 va ws://localhost:8080
echo ============================================================
echo.
echo [1/2] Kiem tra va giai phong port 8080 neu bi treo...
for /f "tokens=5" %%a in ('netstat -aon ^| findstr :8080 ^| findstr LISTENING') do (
    taskkill /F /PID %%a >nul 2>&1
)
echo [2/2] Dang khoi dong May chu Local Deno Server...
deno run --allow-net --allow-env --allow-read --allow-write main.js
pause
