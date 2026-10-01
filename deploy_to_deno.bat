@echo off
title Trien khai Server len Deno Deploy - Dai Viet Chien
cd /d "%~dp0"
echo ============================================================
echo   DAI VIET CHIEN - TRIEN KHAI SERVER LEN DENO CLOUD
echo   Du an: dai-viet-chien-server
echo   To chuc: vdthanh
echo ============================================================
echo.
"%USERPROFILE%\.deno\bin\deployctl.cmd" deploy --project=dai-viet-chien-server --org=vdthanh --entrypoint=main.js --prod %*
echo.
pause
