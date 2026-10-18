<#
=========================================================
 UPGRADE PANDUAN POWERSHELL KE v1.1.0
=========================================================
#>
$ErrorActionPreference = "Stop"

function Write-Utf8 {
    param([string]$Path, [string]$Content)
    $dir = Split-Path -Parent $Path
    if ($dir -and -not (Test-Path $dir)) { New-Item -Path $dir -ItemType Directory -Force | Out-Null }
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Content, $utf8NoBom)
}

Write-Host "[+] Memulai upgrade ke v1.1.0..." -ForegroundColor Cyan

# 1. Buat folder baru
$newFolders = @("docs\advanced", ".github\ISSUE_TEMPLATE")
foreach ($f in $newFolders) {
    if (-not (Test-Path $f)) { New-Item -Path $f -ItemType Directory -Force | Out-Null }
}

# 2. Pindahkan file berisiko ke docs/advanced
$moveFiles = @("03-mas.md", "06-skrip-sistem-lisensi.md", "07-adobe.md")
foreach ($file in $moveFiles) {
    $oldPath = Join-Path "docs" $file
    $newPath = Join-Path "docs\advanced" $file
    if (Test-Path $oldPath) {
        Move-Item -Path $oldPath -Destination $newPath -Force
        Write-Host " -> Memindahkan $file ke docs/advanced/" -ForegroundColor Green
    }
}

# 3. Buat file standar open-source
$changelog = @'
# Changelog

## [1.1.0] - 2026-07-10
### Added
- Restrukturisasi folder `docs/advanced` untuk skrip berisiko.
- File `SECURITY.md`, `CODE_OF_CONDUCT.md`, dan `CHANGELOG.md`.
- Skrip `Build-PDF-1Klik.bat` dan `Publish-GitHub-1Klik.bat`.
- GitHub Issue Templates.

## [1.0.0] - 2026-07-01
- Rilis awal Panduan PowerShell.
'@
Write-Utf8 -Path "CHANGELOG.md" -Content $changelog

$security = @'
# Kebijakan Keamanan

Jika Anda menemukan celah keamanan pada skrip ini, **JANGAN** buka Issue publik.
Hubungi pembuat melalui email atau DM GitHub untuk pelaporan privat.
'@
Write-Utf8 -Path "SECURITY.md" -Content $security

$conduct = @'
# Code of Conduct

Kami berkomitmen menyediakan lingkungan yang ramah dan bebas pelecehan bagi semua kontributor.
Harap saling menghormati dan gunakan bahasa yang sopan dalam Issues maupun Pull Requests.
'@
Write-Utf8 -Path "CODE_OF_CONDUCT.md" -Content $conduct

$bugReport = @'
---
name: Bug report
about: Laporkan bug pada skrip
title: '[BUG] '
labels: bug
assignees: 'elfadhildev'
---

**Deskripsi Bug**
Jelaskan bug yang terjadi.

**Sistem Operasi**
- Windows 10 / Windows 11

**Pesan Error**
Tempelkan screenshot atau teks error dari PowerShell.
'@
Write-Utf8 -Path ".github\ISSUE_TEMPLATE\bug_report.md" -Content $bugReport

Write-Utf8 -Path "VERSION" -Content "1.1.0`n"

# 4. Buat Build-PDF-1Klik.bat
$buildPdfBat = @'
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
'@
Write-Utf8 -Path "Build-PDF-1Klik.bat" -Content $buildPdfBat

# 5. Buat Publish-GitHub-1Klik.bat
$publishBat = @'
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
git push origin main
echo.
echo ===================================================
echo   SELESAI! Cek repo GitHub Anda.
echo ===================================================
pause
'@
Write-Utf8 -Path "Publish-GitHub-1Klik.bat" -Content $publishBat

Write-Host "[+] Upgrade selesai! Jalankan .\Publish-GitHub-1Klik.bat untuk upload ke GitHub." -ForegroundColor Cyan