#Requires -RunAsAdministrator
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -Command `"irm https://raw.githubusercontent.com/elfadhildev/powershell-windows-admin-toolkit/main/toolkit.ps1 | iex`"" -Verb RunAs
    exit
}

function Invoke-BackupUserProfile {
[CmdletBinding()]
param(
    [string]$BackupTargetDrive = 'D:\Backup_PC'
)

<##
==================================================================
 AUTOMATED USER PROFILE & APPDATA BACKUP SCRIPT

 Fungsi:
 1. Membuat folder tujuan backup berbasis tanggal (YYYY-MM-DD)
 2. Backup Dokumen, Gambar, Desktop, Downloads, Musik, & Video
 3. Backup Pengaturan Aplikasi (AppData\Roaming & Local)
 4. Menyediakan file log eksekusi backup
==================================================================
#>

$SourceProfile = $env:USERPROFILE
$DateStamp = Get-Date -Format 'yyyy-MM-dd'
$DestinationFolder = Join-Path -Path $BackupTargetDrive -ChildPath "Backup_$DateStamp"

# 2. DAFTAR FOLDER PROFIL YANG AKAN DI-BACKUP
$FoldersToBackup = @(
    'Documents',
    'Pictures',
    'Desktop',
    'Downloads',
    'Music',
    'Videos',
    'AppData\Roaming', # Pengaturan aplikasi & kredensial lokal
    'AppData\Local\Packages' # Pengaturan beberapa aplikasi UWP/Windows Store
)

# Folder/File yang Dikecualikan dari AppData agar file temp/cache raksasa tidak ikut ter-backup
$ExcludeFolders = @(
    'Cache',
    'Temp',
    'CrashDumps',
    'GPUCache',
    'Microsoft\Windows\INetCache'
)

Write-Host '==========================================' -ForegroundColor Cyan
Write-Host ' MEMULAI PROSES BACKUP PROFIL USER ' -ForegroundColor Cyan
Write-Host '==========================================' -ForegroundColor Cyan
Write-Host "Sumber Profil : $SourceProfile" -ForegroundColor Gray
Write-Host "Tujuan Backup : $DestinationFolder" -ForegroundColor Gray
Write-Host ''

# Buat folder tujuan jika belum ada
if (-not (Test-Path $DestinationFolder)) {
    New-Item -Path $DestinationFolder -ItemType Directory -Force | Out-Null
}

$LogFile = Join-Path -Path $DestinationFolder -ChildPath 'Backup_Log.txt'

# 3. EKSEKUSI PROSES BACKUP MENGGUNAKAN ROBOCOPY
foreach ($Folder in $FoldersToBackup) {
    $SourcePath = Join-Path -Path $SourceProfile -ChildPath $Folder
    $TargetPath = Join-Path -Path $DestinationFolder -ChildPath $Folder

    if (Test-Path $SourcePath) {
        Write-Host "[+] Processing: $Folder ..." -ForegroundColor Yellow

        # Parameter Robocopy:
        # /MIR : Mirror direktori (dipertahankan dari source material)
        # /R:1 : Retry 1 kali jika file terkunci
        # /W:1 : Wait time 1 detik antar retry
        # /XD : Exclude Directory (folder cache/temp)
        # /LOG+ : Menambahkan output ke file log
        # /NP /NJH /NJS : Menyederhanakan tampilan log
        & robocopy $SourcePath $TargetPath /MIR /R:1 /W:1 /XD $ExcludeFolders /LOG+:$LogFile /NP /NJH /NJS

        if ($LASTEXITCODE -lt 8) {
            Write-Host " -> $Folder berhasil di-backup." -ForegroundColor Green
        }
        else {
            Write-Host " [!] $Folder selesai dengan status Robocopy $LASTEXITCODE." -ForegroundColor Red
        }
    }
    else {
        Write-Host "[-] Skipping: $Folder (Folder tidak ditemukan)." -ForegroundColor DarkGray
    }
}

Write-Host ''
Write-Host '==========================================' -ForegroundColor Cyan
Write-Host ' PROSES BACKUP PROFIL SELESAI! ' -ForegroundColor Green
Write-Host '==========================================' -ForegroundColor Cyan
Write-Host "Detail log tersimpan di: $LogFile" -ForegroundColor Gray

}

function Invoke-Maintenance {
<#
 FAST CLIENT MAINTENANCE SCRIPT (.ps1)
 Fungsi:
 1. Flush DNS & Reset Stack Jaringan
 2. Pembersihan Temporary Files (User Temp, System Temp, Prefetch)
 3. ReTrim SSD / Defrag HDD Otomatis
#>

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "[!] Harap jalankan skrip ini sebagai Administrator!" -ForegroundColor Red
    Read-Host "Tekan Enter untuk keluar..."
    Exit
}

Write-Host "===============================" -ForegroundColor Cyan
Write-Host "  MEMULAI PROSES MAINTENANCE PC KLIEN  " -ForegroundColor Cyan
Write-Host "===============================" -ForegroundColor Cyan
Write-Host ""

# 1. OPTIMASI JARINGAN
Write-Host "[1/3] Meringankan & Membersihkan Cache Jaringan..." -ForegroundColor Yellow
Clear-DnsClientCache
Write-Host " -> Cache DNS berhasil dibersihkan." -ForegroundColor Green
ipconfig /release | Out-Null
ipconfig /renew | Out-Null
Write-Host " -> Alokasi IP Address berhasil diperbarui." -ForegroundColor Green
Write-Host ""

# 2. PEMBERSIHAN TEMPORARY FILES & CACHE
Write-Host "[2/3] Membersihkan File Sementara (Temp & Prefetch)..." -ForegroundColor Yellow
$TempFolders = @(
    "$env:TEMP",
    "C:\Windows\Temp",
    "C:\Windows\Prefetch",
    "C:\Windows\SoftwareDistribution\Download"
)
foreach ($Folder in $TempFolders) {
    if (Test-Path $Folder) {
        Write-Host " -> Membersihkan: $Folder" -ForegroundColor Gray
        Get-ChildItem -Path $Folder -Recurse -Force -ErrorAction SilentlyContinue |
            Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    }
}
Start-Process cleanmgr.exe -ArgumentList "/sagerun:1" -NoNewWindow -Wait
Write-Host " -> Membersihkan File Temporary Selesai." -ForegroundColor Green
Write-Host ""

# 3. OPTIMASI MEDIA PENYIMPANAN
Write-Host "[3/3] Menjalankan Retrim SSD dan Optimasi Drive C:..." -ForegroundColor Yellow
$DriveType = (Get-PhysicalDisk | Where-Object {
    $_.DeviceID -eq (Get-Partition -DriveLetter C).DiskNumber
}).MediaType

if ($DriveType -eq "SSD") {
    Write-Host " -> SSD Terdeteksi. Menjalankan perintah ReTrim..." -ForegroundColor Gray
    Optimize-Volume -DriveLetter C -ReTrim -Verbose
    Write-Host " -> ReTrim SSD berhasil dilakukan." -ForegroundColor Green
} else {
    Write-Host " -> HDD Terdeteksi. Menjalankan proses Defragmentasi..." -ForegroundColor Gray
    Optimize-Volume -DriveLetter C -Defrag -Verbose
    Write-Host " -> Defragmentasi HDD selesai." -ForegroundColor Green
}

Write-Host ""
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host " MAINTENANCE SELESAI DENGAN SUKSES! " -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Cyan

# PERBAIKAN: Menahan jendela tetap terbuka
Read-Host " Tekan Enter untuk menutup jendela ini..."
}

function Invoke-SystemAudit {
<#
 SYSTEM AUDIT SCRIPT
#>
$ErrorActionPreference = 'SilentlyContinue'
Clear-Host
Write-Host "===================================================" -ForegroundColor Cyan
Write-Host "             SISTEM AUDIT & HARDWARE               " -ForegroundColor Cyan
Write-Host "===================================================" -ForegroundColor Cyan

Write-Host "`n[+] INFORMASI SISTEM" -ForegroundColor Yellow
$os = Get-CimInstance Win32_OperatingSystem
$cpu = Get-CimInstance Win32_Processor
$ram = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)
Write-Host " OS     : $($os.Caption) ($($os.Version))"
Write-Host " CPU    : $($cpu.Name)"
Write-Host " RAM    : $ram GB"

Write-Host "`n[+] STATUS AKTIVASI WINDOWS" -ForegroundColor Yellow
$lic = Get-CimInstance SoftwareLicensingProduct | Where-Object { $_.PartialProductKey }
if ($lic.LicenseStatus -eq 1) { Write-Host " -> Windows Teraktivasi (Licensed)" -ForegroundColor Green } 
else { Write-Host " -> Windows Belum Teraktivasi" -ForegroundColor Red }

Write-Host "`n[+] KESEHATAN DISK & STORAGE" -ForegroundColor Yellow
Get-PhysicalDisk | Select-Object DeviceId, FriendlyName, MediaType, HealthStatus, @{N='Size(GB)';E={[math]::Round($_.Size/1GB,2)}} | Format-Table -AutoSize

Write-Host "`n[+] DRIVER BERMASALAH" -ForegroundColor Yellow
$badDrivers = Get-PnpDevice -PresentOnly | Where-Object { $_.Status -ne "OK" }
if ($badDrivers) { $badDrivers | Select-Object Class, FriendlyName, Status | Format-Table -AutoSize } 
else { Write-Host " -> Semua driver berstatus OK." -ForegroundColor Green }

Write-Host "===================================================" -ForegroundColor Cyan

}

function Invoke-NetworkDiagnostics {
<#
 NETWORK DIAGNOSTICS SCRIPT
#>
$ErrorActionPreference = 'SilentlyContinue'
Clear-Host
Write-Host "===================================================" -ForegroundColor Cyan
Write-Host "               DIAGNOSTIK JARINGAN                 " -ForegroundColor Cyan
Write-Host "===================================================" -ForegroundColor Cyan

Write-Host "`n[+] IP CONFIGURATION" -ForegroundColor Yellow
Get-NetIPConfiguration | Where-Object { $_.IPv4Address } |
    Select-Object InterfaceAlias, IPv4Address, IPv4DefaultGateway, DNSServer | Format-List

Write-Host "`n[+] ACTIVE TCP CONNECTIONS" -ForegroundColor Yellow
Get-NetTCPConnection | Select-Object LocalAddress, LocalPort, RemoteAddress, RemotePort, State, OwningProcess | Sort-Object State, LocalPort | Format-Table -AutoSize

Write-Host "`n[+] ESTABLISHED CONNECTION -> PROCESS" -ForegroundColor Yellow
Get-NetTCPConnection -State Established | ForEach-Object {
    $Process = Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue
    [PSCustomObject]@{
        LocalPort  = $_.LocalPort
        RemoteAddr = $_.RemoteAddress
        RemotePort = $_.RemotePort
        Process    = if ($Process) { $Process.ProcessName } else { '<unknown>' }
        PID        = $_.OwningProcess
    }
} | Sort-Object Process | Format-Table -AutoSize

Write-Host "`n[+] TES RESOLUSI DNS (google.com)" -ForegroundColor Yellow
$dns = Resolve-DnsName -Name "google.com" -Type A -ErrorAction SilentlyContinue | Select-Object -First 1
if ($dns) { Write-Host " -> Berhasil: google.com -> $($dns.IPAddress)" -ForegroundColor Green } 
else { Write-Host " -> Gagal melakukan resolusi DNS!" -ForegroundColor Red }

Write-Host "===================================================" -ForegroundColor Cyan

}
function Show-Menu {
    Clear-Host
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host " PANDUAN POWERSHELL - CONTROL PANEL (Single File) " -ForegroundColor Cyan
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host " 1. Maintenance PC (Butuh Admin)" -ForegroundColor Green
    Write-Host " 2. System Audit (Cek Hardware & OS)" -ForegroundColor Magenta
    Write-Host " 3. Network Diagnostics (Cek Jaringan)" -ForegroundColor Magenta
    Write-Host " 4. Backup Profil User" -ForegroundColor Green
    Write-Host " 5. Keluar" -ForegroundColor Red
    Write-Host "===================================================" -ForegroundColor Cyan
}

do {
    Show-Menu
    $choice = Read-Host "Pilih opsi (1-5)"
    switch ($choice) {
        '1' { Invoke-Maintenance }
        '2' { Invoke-SystemAudit }
        '3' { Invoke-NetworkDiagnostics }
        '4' { Invoke-BackupUserProfile }
        '5' { Write-Host "Keluar..." -ForegroundColor Cyan }
        default { Write-Host "[!] Pilihan tidak valid." -ForegroundColor Red; Start-Sleep -Seconds 1 }
    }
    if ($choice -ne '5') { Read-Host "`nTekan Enter untuk kembali ke menu..." }
} while ($choice -ne '5')
