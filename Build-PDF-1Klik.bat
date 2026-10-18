@echo off
title Build PDF Lokal
echo ===================================================
echo   MEMBUAT PDF DARI DOKUMENTASI MARKDOWN
echo ===================================================
echo.
echo [+] Mengecek Pandoc...
where pandoc >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] Pandoc tidak ditemukan. Menginstal via Winget...
    winget install --source winget --exact --id JohnMacFarlane.Pandoc --accept-package-agreements --accept-source-agreements
    set "NEED_RESTART=1"
)

echo [+] Mengecek MiKTeX (xelatex)...
where xelatex >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] MiKTeX tidak ditemukan. Menginstal via Winget (Ukuran ~200MB)...
    winget install --source winget --exact --id MiKTeX.MiKTeX --accept-package-agreements --accept-source-agreements
    set "NEED_RESTART=1"
)

if defined NEED_RESTART (
    echo.
    echo =======================================================
    echo [!] Komponen baru saja diinstal.
    echo [i] Agar sistem mengenali Pandoc/MiKTeX, silakan TUTUP 
    echo     jendela ini, lalu jalankan kembali Build-PDF-1Klik.bat.
    echo =======================================================
    pause
    exit /b
)

echo.
echo [+] Mem-build PDF...
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-ChildItem -Path docs -Filter *.md | Sort-Object Name | ForEach-Object { Get-Content $_.FullName; '' } | Set-Content _merged.md; pandoc _merged.md -o Panduan-PowerShell.pdf --metadata-file=metadata.yaml --pdf-engine=xelatex --toc --toc-depth=2 -V geometry:margin=2.5cm -V mainfont='DejaVu Sans'; Remove-Item _merged.md"

if exist Panduan-PowerShell.pdf (
    echo.
    echo =======================================================
    echo [+] SUKSES! PDF tersimpan di Panduan-PowerShell.pdf
    echo =======================================================
) else (
    echo.
    echo [!] GAGAL membuat PDF. Periksa pesan error di atas.
)
echo.
pause