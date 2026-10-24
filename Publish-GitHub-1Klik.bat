@echo off
title Auto Publish GitHub
echo ===================================================
echo   AUTO PUBLISH GITHUB (FORCE MODE)
echo ===================================================
echo.
set /p commit_msg="Masukkan pesan commit (default: Update kode terbaru): "
if "%commit_msg%"=="" set commit_msg=Update kode terbaru

echo.
git add .
git commit -m "%commit_msg%"

echo [+] Mengirim paksa ke GitHub...
git push -f origin main

echo.
echo ===================================================
echo   SELESAI! Cek repo GitHub Anda.
echo ===================================================
pause