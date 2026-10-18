<#
.SYNOPSIS
  Panduan PowerShell - Control Panel Installer (v1.1.0)
#>

$RepoUrl = "https://github.com/elfadhildev/powershell-windows-admin-toolkit.git"
$InstallDir = Join-Path -Path $env:USERPROFILE -ChildPath "Panduan-PowerShell"

function Show-Menu {
    Clear-Host
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host "      PANDUAN POWERSHELL - CONTROL PANEL v1.1.0      " -ForegroundColor Cyan
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host " 1. Install / Update Repositori" -ForegroundColor Yellow
    Write-Host " 2. Maintenance PC (Bersihkan & Optimasi)" -ForegroundColor Green
    Write-Host " 3. Backup Profil User" -ForegroundColor Green
    Write-Host " 4. Build PDF (Lokal)" -ForegroundColor Green
    Write-Host " 5. System Audit (Cek Hardware & OS)" -ForegroundColor Magenta
    Write-Host " 6. Network Diagnostics (Cek Jaringan)" -ForegroundColor Magenta
    Write-Host " 7. Buka Folder Instalasi"
    Write-Host " 8. Keluar" -ForegroundColor Red
    Write-Host "===================================================" -ForegroundColor Cyan
}

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "[!] Git belum terinstal. Menginstal via Winget..." -ForegroundColor Yellow
    winget install --source winget --exact --id Git.Git
}

do {
    Show-Menu
    $choice = Read-Host "Pilih opsi (1-8)"
    
    switch ($choice) {
        '1' {
            Write-Host "`n[+] Memproses repositori..." -ForegroundColor Cyan
            if (Test-Path $InstallDir) {
                Set-Location $InstallDir
                git pull origin main
            } else {
                git clone $RepoUrl $InstallDir
            }
            Write-Host "[+] Selesai! Repositori siap digunakan." -ForegroundColor Green
            Start-Sleep -Seconds 2
        }
        '2' {
            $target = Join-Path $InstallDir "Maintenance-1Klik.bat"
            if (Test-Path $target) { Start-Process $target -Verb RunAs } else { Write-Host "[!] Silakan pilih opsi 1 dulu." -ForegroundColor Red; Start-Sleep -Seconds 2 }
        }
        '3' {
            $target = Join-Path $InstallDir "Backup-1Klik.bat"
            if (Test-Path $target) { Start-Process $target } else { Write-Host "[!] Silakan pilih opsi 1 dulu." -ForegroundColor Red; Start-Sleep -Seconds 2 }
        }
        '4' {
            $target = Join-Path $InstallDir "Build-PDF-1Klik.bat"
            if (Test-Path $target) { Start-Process $target } else { Write-Host "[!] Silakan pilih opsi 1 dulu." -ForegroundColor Red; Start-Sleep -Seconds 2 }
        }
        '5' {
            $target = Join-Path $InstallDir "scripts\System-Audit.ps1"
            if (Test-Path $target) { & $target } else { Write-Host "[!] File System-Audit.ps1 belum ada. Jalankan opsi 1." -ForegroundColor Red; Start-Sleep -Seconds 2 }
        }
        '6' {
            $target = Join-Path $InstallDir "scripts\Network-Diagnostics.ps1"
            if (Test-Path $target) { & $target } else { Write-Host "[!] File Network-Diagnostics.ps1 belum ada. Jalankan opsi 1." -ForegroundColor Red; Start-Sleep -Seconds 2 }
        }
        '7' {
            if (Test-Path $InstallDir) { Start-Process explorer.exe $InstallDir } else { Write-Host "[!] Folder belum ada." -ForegroundColor Red; Start-Sleep -Seconds 2 }
        }
        '8' { Write-Host "Keluar..." -ForegroundColor Cyan }
        default { Write-Host "[!] Pilihan tidak valid." -ForegroundColor Red; Start-Sleep -Seconds 1 }
    }
} while ($choice -ne '8')