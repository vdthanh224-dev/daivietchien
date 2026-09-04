@echo off
title Dai Viet Chien - Local Game Server (Port 8080)
cd /d "%~dp0"
echo ============================================================
echo   DAI VIET CHIEN - MAY CHU CUC BO (PORT 8080)
echo   Dang chay tai: http://localhost:8080 va ws://localhost:8080
echo ============================================================
echo.
deno run --allow-net --allow-env --allow-read --allow-write deploy_deno/main.ts
pause
