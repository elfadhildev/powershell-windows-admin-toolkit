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
