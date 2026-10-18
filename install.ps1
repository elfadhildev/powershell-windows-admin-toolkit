<#
.SYNOPSIS
  Installer 1-Klik Panduan PowerShell (v1.1.0)
.DESCRIPTION
  Memasang repo secara lokal dan mempersiapkan lingkungan.
.EXAMPLE
  irm https://raw.githubusercontent.com/elfadhildev/powershell-windows-admin-toolkit/main/install.ps1 | iex
#>

$ErrorActionPreference = "Stop"
$RepoUrl = "https://github.com/elfadhildev/powershell-windows-admin-toolkit.git"
$InstallDir = Join-Path -Path $env:USERPROFILE -ChildPath "Panduan-PowerShell"

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "   INSTALLER PANDUAN POWERSHELL (v1.1.0)    " -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

# 1. Cek Git
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "[!] Git belum terinstal. Menginstal via Winget..." -ForegroundColor Yellow
    winget install --source winget --exact --id Git.Git
}

# 2. Clone Repo
if (Test-Path $InstallDir) {
    Write-Host "[!] Folder $InstallDir sudah ada. Menarik pembaruan (git pull)..." -ForegroundColor Yellow
    Set-Location $InstallDir
    git pull origin main
} else {
    Write-Host "[+] Mengunduh repositori ke $InstallDir..." -ForegroundColor Green
    git clone $RepoUrl $InstallDir
    Set-Location $InstallDir
}

Write-Host ""
Write-Host "=============================================" -ForegroundColor Green
Write-Host "   INSTALASI SELESAI!                       " -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green
Write-Host "Folder Anda: $InstallDir"
Write-Host ""
Write-Host "Anda bisa menjalankan skrip berikut dari folder tersebut:"
Write-Host " - .\Maintenance-1Klik.bat"
Write-Host " - .\Build-PDF-1Klik.bat"
Write-Host ""
Start-Process explorer.exe $InstallDir