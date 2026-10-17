# setup.ps1
Write-Host "Memulai Instalasi Toolkit..." -ForegroundColor Cyan

$repoUrl = "https://github.com/elfadhildev/powershell-windows-admin-toolkit.git"
$installPath = "$env:USERPROFILE\powershell-windows-admin-toolkit"

# Cek jika folder sudah ada, tarik update. Jika belum, clone.
if (Test-Path $installPath) {
    Write-Host "Folder sudah ada. Memperbarui..." -ForegroundColor Yellow
    Set-Location $installPath
    git pull origin main
} else {
    Write-Host "Mengunduh repositori..." -ForegroundColor Yellow
    git clone $repoUrl $installPath
    Set-Location $installPath
}

# Buka blokir file .ps1 secara senyap
Get-ChildItem -Path ".\scripts\*.ps1" | Unblock-File

# Jalankan menu interaktif (panggil install.bat Anda)
Write-Host "Membuka Menu..." -ForegroundColor Green
.\install.bat