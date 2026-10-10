[CmdletBinding()]
param(
    [ValidatePattern('^[A-Za-z]$')]
    [string]$DriveLetter = 'C'
)

<##
==================================================================
 FAST CLIENT MAINTENANCE SCRIPT (.ps1)

 Fungsi:
 1. Flush DNS & Reset Stack Jaringan
 2. Pembersihan Temporary Files (User Temp, System Temp, Prefetch)
 3. ReTrim SSD / Defrag HDD Otomatis
==================================================================
#>

$ErrorActionPreference = 'Continue'

# Pastikan skrip berjalan dengan hak akses Administrator
$CurrentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
$Principal = [Security.Principal.WindowsPrincipal]::new($CurrentIdentity)

if (-not $Principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host '[!] Harap jalankan skrip ini sebagai Administrator!' -ForegroundColor Red
    exit 1
}

Write-Host '==========================================' -ForegroundColor Cyan
Write-Host ' MEMULAI PROSES MAINTENANCE PC KLIEN ' -ForegroundColor Cyan
Write-Host '==========================================' -ForegroundColor Cyan
Write-Host "Target Drive : $DriveLetter`:" -ForegroundColor Gray
Write-Host ''

# ------------------------------------------------------------------
# 1. OPTIMASI JARINGAN (FLUSH DNS & RESET)
# ------------------------------------------------------------------
Write-Host '[1/3] Meringankan & Membersihkan Cache Jaringan...' -ForegroundColor Yellow

# Flush DNS Cache
Clear-DnsClientCache
Write-Host ' -> Cache DNS berhasil dibersihkan.' -ForegroundColor Green

# Release & Renew IP (Opsional untuk menyegarkan IP DHCP)
ipconfig /release | Out-Null
ipconfig /renew | Out-Null
Write-Host ' -> Alokasi IP Address berhasil diperbarui.' -ForegroundColor Green
Write-Host ''

# ------------------------------------------------------------------
# 2. PEMBERSIHAN TEMPORARY FILES & CACHE
# ------------------------------------------------------------------
Write-Host '[2/3] Membersihkan File Sementara (Temp & Prefetch)...' -ForegroundColor Yellow

$TempFolders = @(
    "$env:TEMP", # User Temp Folder
    'C:\Windows\Temp', # System Temp Folder
    'C:\Windows\Prefetch', # Prefetch Folder
    'C:\Windows\SoftwareDistribution\Download' # Windows Update Download Cache
)

foreach ($Folder in $TempFolders) {
    if (Test-Path $Folder) {
        Write-Host " -> Membersihkan: $Folder" -ForegroundColor Gray
        Get-ChildItem -Path $Folder -Recurse -Force -ErrorAction SilentlyContinue |
            Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# Jalankan Windows Component Cleanup (Cleanmgr) secara cepat
Start-Process cleanmgr.exe -ArgumentList '/autoclean' -NoNewWindow -Wait
Write-Host ' -> Pembersihan File Temporary Selesai.' -ForegroundColor Green
Write-Host ''

# ------------------------------------------------------------------
# 3. OPTIMASI MEDIA PENYIMPANAN (RETRIM SSD / DEFRAG HDD)
# ------------------------------------------------------------------
Write-Host "[3/3] Menjalankan Retrim SSD dan Optimasi Drive $DriveLetter`:..." -ForegroundColor Yellow

try {
    # Memeriksa jenis drive target (SSD atau HDD)
    $Partition = Get-Partition -DriveLetter $DriveLetter -ErrorAction Stop
    $PhysicalDisk = Get-PhysicalDisk -ErrorAction Stop |
        Where-Object { $_.DeviceID -eq $Partition.DiskNumber } |
        Select-Object -First 1

    $DriveType = $PhysicalDisk.MediaType

    if ($DriveType -eq 'SSD') {
        Write-Host ' -> SSD Terdeteksi. Menjalankan perintah ReTrim...' -ForegroundColor Gray
        Optimize-Volume -DriveLetter $DriveLetter -ReTrim -Verbose
        Write-Host ' -> ReTrim SSD berhasil dilakukan.' -ForegroundColor Green
    }
    else {
        Write-Host ' -> HDD/Media non-SSD terdeteksi. Menjalankan proses Defragmentasi...' -ForegroundColor Gray
        Optimize-Volume -DriveLetter $DriveLetter -Defrag -Verbose
        Write-Host ' -> Defragmentasi drive selesai.' -ForegroundColor Green
    }
}
catch {
    Write-Host " [!] Optimasi drive gagal: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ''
Write-Host '==========================================' -ForegroundColor Cyan
Write-Host ' MAINTENANCE SELESAI DENGAN SUKSES! ' -ForegroundColor Green
Write-Host '==========================================' -ForegroundColor Cyan
