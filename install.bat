@echo off
title Toolkit Installer - Elfadhidev
color 0A

:: 1. Cek Izin Administrator
net session >nul 2>&1
if %errorLevel% == 0 (
    goto :menu
) else (
    echo Meminta izin Administrator...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:menu
:: 2. Paksa masuk ke folder script
cd /d "%~dp0"

:: 3. Buka blokir file (hanya berjalan sekali di awal)
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-ChildItem -Path '%~dp0scripts' -Filter *.ps1 -Recurse | Unblock-File" >nul 2>&1

:MENU_UTAMA
cls
echo ====================================================
echo         WINDOWS ADMIN TOOLKIT - ELFADHIDEV
echo ====================================================
echo.
echo  [1] Maintenance (Perawatan Sistem)
echo  [2] Network Diagnostics (Cek Jaringan)
echo  [3] System Audit (Audit Keamanan)
echo  [4] Backup User Profile (Backup Data)
echo  [5] Keluar
echo.
echo ====================================================
set /p pilihan="Pilih menu (1-5) lalu tekan Enter: "

if "%pilihan%"=="1" set "SCRIPT_NAME=Maintenance.ps1"
if "%pilihan%"=="2" set "SCRIPT_NAME=Network-Diagnostics.ps1"
if "%pilihan%"=="3" set "SCRIPT_NAME=System-Audit.ps1"
if "%pilihan%"=="4" set "SCRIPT_NAME=Backup-UserProfile.ps1"
if "%pilihan%"=="5" exit

if not defined SCRIPT_NAME (
    echo.
    echo [ERROR] Pilihan tidak valid! Silakan coba lagi.
    timeout /t 2 >nul
    goto MENU_UTAMA
)

:: 4. Jalankan skrip yang dipilih
cls
echo ====================================================
echo   Menjalankan: %SCRIPT_NAME%
echo ====================================================
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\%SCRIPT_NAME%"

echo.
echo ====================================================
echo   Skrip Selesai Dijalankan.
echo ====================================================
pause
goto MENU_UTAMA
