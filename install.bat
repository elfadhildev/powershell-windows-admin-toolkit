@echo off
title Toolkit Installer - Elfadhidev
color 0A

:: 1. Minta izin Administrator
net session >nul 2>&1
if %errorLevel% == 0 (
    goto :run_script
) else (
    echo Meminta izin Administrator...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:run_script
:: 2. Pindah ke direktori tempat file .bat berada
cd /d "%~dp0"

echo ====================================================
echo   Memulai Proses Persiapan Toolkit
echo ====================================================
echo.

:: 3. Buka blokir HANYA untuk file .ps1 di dalam folder scripts
echo [1/2] Menyiapkan izin akses untuk modul PowerShell...
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-ChildItem -Path '%~dp0scripts' -Filter *.ps1 -Recurse | Unblock-File"
echo       Selesai!
echo.

:: 4. Buka PowerShell di folder scripts agar user bisa memilih script
echo [2/2] Membuka Terminal Toolkit...
echo.
echo Silakan ketik nama script yang ingin dijalankan. Contoh:
echo   .\Maintenance.ps1
echo   .\Network-Diagnostics.ps1
echo.
powershell -NoExit -ExecutionPolicy Bypass -Command "cd '%~dp0scripts'; Write-Host 'Toolkit Siap Digunakan!' -ForegroundColor Green"

pause