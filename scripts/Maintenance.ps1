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