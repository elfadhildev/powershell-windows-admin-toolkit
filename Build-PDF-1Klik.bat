@echo off
title Build PDF Lokal
echo [+] Mengecek Pandoc...
pandoc --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] Pandoc tidak ditemukan. Menginstal via Winget...
    winget install --source winget --exact --id JohnMacFarlane.Pandoc
)
echo [+] Mem-build PDF...
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-ChildItem -Path docs -Filter *.md | Sort-Object Name | ForEach-Object { Get-Content $_.FullName; '' } | Set-Content _merged.md; pandoc _merged.md -o Panduan-PowerShell.pdf --metadata-file=metadata.yaml --pdf-engine=xelatex --toc --toc-depth=2 -V geometry:margin=2.5cm -V mainfont='DejaVu Sans'; Remove-Item _merged.md"
echo [+] Selesai! PDF tersimpan di Panduan-PowerShell.pdf
pause