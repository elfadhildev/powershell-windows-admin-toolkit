<#
.SYNOPSIS
  Panduan PowerShell - Control Panel Installer (v1.3.1 - Final Ultimate)
#>

$RepoUrl = "https://github.com/elfadhildev/powershell-windows-admin-toolkit.git"
$InstallDir = Join-Path -Path $env:USERPROFILE -ChildPath "Panduan-PowerShell"

# --- DETEKSI LOKASI (LOKAL VS REMOTE) ---
# Jika $PSScriptRoot kosong (dijalankan via irm|iex), maka unduh ke folder default
if (-not $PSScriptRoot) {
    if (-not (Test-Path (Join-Path $InstallDir "scripts\Maintenance.ps1"))) {
        Write-Host "[+] Mengunduh repositori secara otomatis ke $InstallDir..." -ForegroundColor Cyan
        git clone $RepoUrl $InstallDir
    }
    $script:WorkingDir = $InstallDir
} else {
    # Jika dijalankan lokal, deteksi folder aktif
    if (Test-Path (Join-Path $PSScriptRoot "scripts\Maintenance.ps1")) {
        $script:WorkingDir = $PSScriptRoot
    } else {
        $script:WorkingDir = $null
    }
}

function Show-Menu {
    Clear-Host
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host "      PANDUAN POWERSHELL - CONTROL PANEL v1.3.1      " -ForegroundColor Cyan
    Write-Host "===================================================" -ForegroundColor Cyan
    if ($script:WorkingDir) {
        Write-Host " [i] Folder aktif: $script:WorkingDir" -ForegroundColor DarkGray
    } else {
        Write-Host " [!] Repositori belum terinstal di komputer ini." -ForegroundColor Yellow
    }
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host " 1. Update Repositori (Tarik pembaruan)" -ForegroundColor Yellow
    Write-Host " 2. Maintenance PC (Butuh Admin)" -ForegroundColor Green
    Write-Host " 3. Backup Profil User" -ForegroundColor Green
    Write-Host " 4. Build PDF (Lokal)" -ForegroundColor Green
    Write-Host " 5. System Audit (Cek Hardware & OS)" -ForegroundColor Magenta
    Write-Host " 6. Network Diagnostics (Cek Jaringan)" -ForegroundColor Magenta
    Write-Host " 7. Buka Folder Instalasi"
    Write-Host " 8. Keluar" -ForegroundColor Red
    Write-Host "===================================================" -ForegroundColor Cyan
}

# Pastikan Git terinstal
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    winget install --source winget --exact --id Git.Git
}

function Ensure-Repo {
    if (-not $script:WorkingDir) {
        Write-Host "`n[+] Mengunduh repositori..." -ForegroundColor Cyan
        git clone $RepoUrl $InstallDir
        $script:WorkingDir = $InstallDir
    }
}

do {
    Show-Menu
    $choice = Read-Host "Pilih opsi (1-8)"
    
    switch ($choice) {
        '1' {
            Ensure-Repo
            Set-Location $script:WorkingDir
            git pull origin main
            Read-Host "`n[+] Selesai! Tekan Enter untuk kembali..."
        }
        '2' {
            Ensure-Repo
            $target = Join-Path $script:WorkingDir "scripts\Maintenance.ps1"
            if (Test-Path $target) { 
                Start-Process powershell -ArgumentList "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "`"$target`"" -Verb RunAs -Wait
            }
        }
        '3' {
            Ensure-Repo
            $target = Join-Path $script:WorkingDir "Backup-1Klik.bat"
            if (Test-Path $target) { Start-Process $target -Wait }
        }
        '4' {
            Ensure-Repo
            $target = Join-Path $script:WorkingDir "Build-PDF-1Klik.bat"
            if (Test-Path $target) { Start-Process $target -Wait }
        }
        '5' {
            Ensure-Repo
            $target = Join-Path $script:WorkingDir "scripts\System-Audit.ps1"
            if (Test-Path $target) { 
                Start-Process powershell -ArgumentList "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "`"$target`"" -Wait
            }
        }
        '6' {
            Ensure-Repo
            $target = Join-Path $script:WorkingDir "scripts\Network-Diagnostics.ps1"
            if (Test-Path $target) { 
                Start-Process powershell -ArgumentList "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "`"$target`"" -Wait
            }
        }
        '7' {
            Ensure-Repo
            Start-Process explorer.exe $script:WorkingDir
        }
        '8' { Write-Host "Keluar..." -ForegroundColor Cyan }
        default { Write-Host "[!] Pilihan tidak valid." -ForegroundColor Red; Start-Sleep -Seconds 1 }
    }
} while ($choice -ne '8')