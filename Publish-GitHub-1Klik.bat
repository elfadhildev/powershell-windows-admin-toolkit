@echo off
title Auto Publish GitHub
echo ===================================================
echo   AUTO PUBLISH GITHUB (v1.1.0)
echo ===================================================
echo.
set /p commit_msg="Masukkan pesan commit (default: Update v1.1.0): "
if "%commit_msg%"=="" set commit_msg=Update v1.1.0

echo.
git add .
git commit -m "%commit_msg%"

echo [+] Menarik pembaruan dari GitHub...
git pull origin main --rebase

echo [+] Mengirim ke GitHub...
git push origin main
echo.
echo ===================================================
echo   SELESAI! Cek repo GitHub Anda.
echo ===================================================
pause