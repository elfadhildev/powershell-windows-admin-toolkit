<#
.SYNOPSIS
  Panduan PowerShell - Control Panel Installer (v1.2.0 - Fully Fixed)
#>

$RepoUrl = "https://github.com/elfadhildev/powershell-windows-admin-toolkit.git"
$InstallDir = Join-Path -Path $env:USERPROFILE -ChildPath "Panduan-PowerShell"

# Deteksi otomatis: Apakah skrip berjalan dari folder proyek lokal (D:) atau folder instalasi (C:)?
$CurrentDir = Get-Location
if (Test-Path (Join-Path $CurrentDir "scripts\Maintenance.ps1")) {
    $WorkingDir = $CurrentDir
} elseif (Test-Path (Join-Path $InstallDir "scripts\Maintenance.ps1")) {
    $WorkingDir = $InstallDir
} else {
    $WorkingDir = $null
}

function Show-Menu {
    Clear-Host
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host "      PANDUAN POWERSHELL - CONTROL PANEL v1.2.0      " -ForegroundColor Cyan
    Write-Host "===================================================" -ForegroundColor Cyan
    if ($WorkingDir) {
        Write-Host " [i] Folder aktif: $WorkingDir" -ForegroundColor DarkGray
    } else {
        Write-Host " [!] Repositori belum terinstal di komputer ini." -ForegroundColor Yellow
    }
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host " 1. Update Repositori (Tarik pembaruan)" -ForegroundColor Yellow
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

# Fungsi Cerdas: Otomatis unduh jika folder belum ada
function Ensure-Repo {
    if (-not $script:WorkingDir) {
        Write-Host "`n[!] Folder repositori belum ditemukan." -ForegroundColor Yellow
        Write-Host "[+] Mengunduh repositori secara otomatis ke $InstallDir..." -ForegroundColor Cyan
        if (-not (Test-Path $InstallDir)) {
            git clone $RepoUrl $InstallDir
        }
        $script:WorkingDir = $InstallDir
    }
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
                $script:WorkingDir = $InstallDir
            } else {
                git clone $RepoUrl $InstallDir
                $script:WorkingDir = $InstallDir
            }
            Write-Host "[+] Selesai! Repositori siap digunakan." -ForegroundColor Green
            Read-Host "`nTekan Enter untuk kembali ke menu utama..."
        }
        '2' {
            Ensure-Repo
            $target = Join-Path $script:WorkingDir "Maintenance-1Klik.bat"
            if (Test-Path $target) { Start-Process $target -Verb RunAs }
        }
        '3' {
            Ensure-Repo
            $target = Join-Path $script:WorkingDir "Backup-1Klik.bat"
            if (Test-Path $target) { Start-Process $target }
        }
        '4' {
            Ensure-Repo
            $target = Join-Path $script:WorkingDir "Build-PDF-1Klik.bat"
            if (Test-Path $target) { Start-Process $target }
        }
        '5' {
            Ensure-Repo
            $target = Join-Path $script:WorkingDir "scripts\System-Audit.ps1"
            if (Test-Path $target) { 
                # -Wait: Menu utama akan "diam" menunggu sampai jendela baru ditutup
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