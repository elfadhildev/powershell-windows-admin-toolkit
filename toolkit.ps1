#Requires -RunAsAdministrator
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -Command `"irm https://raw.githubusercontent.com/elfadhildev/powershell-windows-admin-toolkit/main/toolkit.ps1 | iex`"" -Verb RunAs
    exit
}

# ==========================================
# 1. FUNGSI MAINTENANCE
# ==========================================
function Invoke-Maintenance {
    Write-Host "`n[+] Memulai Maintenance..." -ForegroundColor Cyan
    Write-Host "[1/3] Membersihkan Cache DNS..." -ForegroundColor Yellow
    Clear-DnsClientCache
    ipconfig /release | Out-Null
    ipconfig /renew | Out-Null
    Write-Host " -> Cache DNS & IP berhasil diperbarui." -ForegroundColor Green
    Write-Host "[2/3] Membersihkan File Sementara..." -ForegroundColor Yellow
    $TempFolders = @("$env:TEMP", "C:\Windows\Temp", "C:\Windows\Prefetch", "C:\Windows\SoftwareDistribution\Download")
    foreach ($Folder in $TempFolders) {
        if (Test-Path $Folder) {
            Get-ChildItem -Path $Folder -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
    Start-Process cleanmgr.exe -ArgumentList "/sagerun:1" -NoNewWindow -Wait
    Write-Host " -> File sementara dibersihkan." -ForegroundColor Green
    Write-Host "[3/3] Optimasi Drive C..." -ForegroundColor Yellow
    $DriveType = (Get-PhysicalDisk | Where-Object { $_.DeviceID -eq (Get-Partition -DriveLetter C).DiskNumber }).MediaType
    if ($DriveType -eq "SSD") { Optimize-Volume -DriveLetter C -ReTrim -Verbose } else { Optimize-Volume -DriveLetter C -Defrag -Verbose }
    Write-Host " -> Optimasi Drive C selesai." -ForegroundColor Green
    Read-Host "`nTekan Enter untuk kembali ke menu..."
}

# ==========================================
# 2. FUNGSI SYSTEM AUDIT
# ==========================================
function Invoke-SystemAudit {
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
    if ($lic.LicenseStatus -eq 1) { Write-Host " -> Windows Teraktivasi (Licensed)" -ForegroundColor Green } else { Write-Host " -> Windows Belum Teraktivasi" -ForegroundColor Red }
    Write-Host "`n[+] KESEHATAN DISK & STORAGE" -ForegroundColor Yellow
    Get-PhysicalDisk | Select-Object DeviceId, FriendlyName, MediaType, HealthStatus, @{N='Size(GB)';E={[math]::Round($_.Size/1GB,2)}} | Format-Table -AutoSize
    Write-Host "`n[+] DRIVER BERMASALAH" -ForegroundColor Yellow
    $badDrivers = Get-PnpDevice -PresentOnly | Where-Object { $_.Status -ne "OK" }
    if ($badDrivers) { $badDrivers | Select-Object Class, FriendlyName, Status | Format-Table -AutoSize } else { Write-Host " -> Semua driver berstatus OK." -ForegroundColor Green }
    Read-Host "`nTekan Enter untuk kembali ke menu..."
}

# ==========================================
# 3. FUNGSI NETWORK DIAGNOSTICS
# ==========================================
function Invoke-NetworkDiagnostics {
    $ErrorActionPreference = 'SilentlyContinue'
    Clear-Host
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host "               DIAGNOSTIK JARINGAN                 " -ForegroundColor Cyan
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host "`n[+] IP CONFIGURATION" -ForegroundColor Yellow
    Get-NetIPConfiguration | Where-Object { $_.IPv4Address } | Select-Object InterfaceAlias, IPv4Address, IPv4DefaultGateway, DNSServer | Format-List
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
    if ($dns) { Write-Host " -> Berhasil: google.com -> $($dns.IPAddress)" -ForegroundColor Green } else { Write-Host " -> Gagal melakukan resolusi DNS!" -ForegroundColor Red }
    Read-Host "`nTekan Enter untuk kembali ke menu..."
}

# ==========================================
# 4. FUNGSI BACKUP PROFILE
# ==========================================
function Invoke-BackupUserProfile {
    param([string]$BackupTargetDrive = 'D:\Backup_PC')
    $SourceProfile = $env:USERPROFILE
    $DateStamp = Get-Date -Format 'yyyy-MM-dd'
    $DestinationFolder = Join-Path -Path $BackupTargetDrive -ChildPath "Backup_$DateStamp"
    $FoldersToBackup = @('Documents', 'Pictures', 'Desktop', 'Downloads', 'Music', 'Videos', 'AppData\Roaming', 'AppData\Local\Packages')
    $ExcludeFolders = @('Cache', 'Temp', 'CrashDumps', 'GPUCache', 'Microsoft\Windows\INetCache')
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host " MEMULAI PROSES BACKUP PROFIL USER " -ForegroundColor Cyan
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "Sumber Profil : $SourceProfile" -ForegroundColor Gray
    Write-Host "Tujuan Backup : $DestinationFolder" -ForegroundColor Gray
    Write-Host ''
    if (-not (Test-Path $DestinationFolder)) { New-Item -Path $DestinationFolder -ItemType Directory -Force | Out-Null }
    $LogFile = Join-Path -Path $DestinationFolder -ChildPath 'Backup_Log.txt'
    foreach ($Folder in $FoldersToBackup) {
        $SourcePath = Join-Path -Path $SourceProfile -ChildPath $Folder
        $TargetPath = Join-Path -Path $DestinationFolder -ChildPath $Folder
        if (Test-Path $SourcePath) {
            Write-Host "[+] Processing: $Folder ..." -ForegroundColor Yellow
            robocopy $SourcePath $TargetPath /MIR /R:1 /W:1 /XD $ExcludeFolders /LOG+:$LogFile /NP /NJH /NJS
            if ($LASTEXITCODE -lt 8) { Write-Host " -> $Folder berhasil di-backup." -ForegroundColor Green } else { Write-Host " [!] $Folder selesai dengan beberapa peringatan." -ForegroundColor Red }
        } else {
            Write-Host "[~] Skipping: $Folder (Folder tidak ditemukan)." -ForegroundColor DarkGray
        }
    }
    Write-Host "`n===============================" -ForegroundColor Cyan
    Write-Host " PROSES BACKUP PROFIL SELESAI! " -ForegroundColor Green
    Write-Host "===============================" -ForegroundColor Cyan
    Write-Host "Detail log tersimpan di: $LogFile" -ForegroundColor Gray
    Read-Host "`nTekan Enter untuk kembali ke menu..."
}

# ==========================================
# 5. FUNGSI WINGET APP INSTALLER
# ==========================================
function Invoke-WingetAppInstaller {
    Clear-Host
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host "               WINGET APP INSTALLER                " -ForegroundColor Cyan
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host "Pilih aplikasi yang ingin diinstal (ketik nomor, pisahkan dengan koma):"
    Write-Host " 1. Google Chrome"
    Write-Host " 2. Mozilla Firefox"
    Write-Host " 3. VLC Media Player"
    Write-Host " 4. 7-Zip"
    Write-Host " 5. Notepad++"
    Write-Host " 6. Visual Studio Code"
    Write-Host " 7. Discord"
    Write-Host " 8. Spotify"
    Write-Host " 9. Steam"
    Write-Host " 10. Zoom"
    Write-Host "===================================================" -ForegroundColor Cyan
    $inputApps = Read-Host "Masukkan nomor (contoh: 1,3,5)"
    $apps = @{
        '1' = 'Google.Chrome'
        '2' = 'Mozilla.Firefox'
        '3' = 'VideoLAN.VLC'
        '4' = '7zip.7zip'
        '5' = 'Notepad++.Notepad++'
        '6' = 'Microsoft.VisualStudioCode'
        '7' = 'Discord.Discord'
        '8' = 'Spotify.Spotify'
        '9' = 'Valve.Steam'
        '10' = 'Zoom.Zoom'
    }
    $selected = $inputApps -split ',' | ForEach-Object { $_.Trim() }
    foreach ($s in $selected) {
        if ($apps.ContainsKey($s)) {
            $appId = $apps[$s]
            Write-Host "`n[+] Menginstal $appId..." -ForegroundColor Yellow
            winget install --id $appId --accept-source-agreements --accept-package-agreements --silent
        }
    }
    Read-Host "`n[+] Proses instalasi selesai. Tekan Enter untuk kembali..."
}

# ==========================================
# 6. FUNGSI WINDOWS DEBLOATER (INTERAKTIF)
# ==========================================
function Invoke-WindowsDebloater {
    Clear-Host
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host "               WINDOWS DEBLOATER                   " -ForegroundColor Cyan
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host "Pilih aplikasi bawaan (bloatware) yang ingin dihapus:"
    
    $debloatList = @(
        [PSCustomObject]@{ No='1';  App='Cortana';           Pkg='Microsoft.549981C3F5F10' },
        [PSCustomObject]@{ No='2';  App='Bing News';         Pkg='Microsoft.BingNews' },
        [PSCustomObject]@{ No='3';  App='Bing Weather';      Pkg='Microsoft.BingWeather' },
        [PSCustomObject]@{ No='4';  App='Get Help';          Pkg='Microsoft.GetHelp' },
        [PSCustomObject]@{ No='5';  App='Tips (Get Started)';Pkg='Microsoft.Getstarted' },
        [PSCustomObject]@{ No='6';  App='Office Hub';        Pkg='Microsoft.MicrosoftOfficeHub' },
        [PSCustomObject]@{ No='7';  App='Solitaire';         Pkg='Microsoft.MicrosoftSolitaireCollection' },
        [PSCustomObject]@{ No='8';  App='People';            Pkg='Microsoft.People' },
        [PSCustomObject]@{ No='9';  App='Skype';             Pkg='Microsoft.SkypeApp' },
        [PSCustomObject]@{ No='10'; App='Feedback Hub';      Pkg='Microsoft.WindowsFeedbackHub' },
        [PSCustomObject]@{ No='11'; App='Xbox App';          Pkg='Microsoft.XboxApp' },
        [PSCustomObject]@{ No='12'; App='Xbox Game Overlay'; Pkg='Microsoft.XboxGamingOverlay' },
        [PSCustomObject]@{ No='13'; App='Your Phone';        Pkg='Microsoft.YourPhone' },
        [PSCustomObject]@{ No='14'; App='Groove Music';      Pkg='Microsoft.ZuneMusic' },
        [PSCustomObject]@{ No='15'; App='Movies & TV';       Pkg='Microsoft.ZuneVideo' }
    )

    $debloatList | Format-Table -AutoSize
    
    Write-Host "Ketik nomor yang ingin dihapus (pisahkan dengan koma, contoh: 1,2,11)." -ForegroundColor Yellow
    Write-Host "Ketik 'all' untuk menghapus semuanya, atau 'x' untuk batal." -ForegroundColor Yellow
    $inputApps = Read-Host "`nPilihan Anda"

    if ($inputApps -eq 'x' -or $inputApps -eq '') {
        Write-Host "`n[!] Dibatalkan." -ForegroundColor Red
        Start-Sleep -Seconds 1
        return
    }

    if ($inputApps -eq 'all') {
        $toRemove = $debloatList
    } else {
        $selectedNums = $inputApps -split ',' | ForEach-Object { $_.Trim() }
        $toRemove = $debloatList | Where-Object { $selectedNums -contains $_.No }
    }

    if ($toRemove.Count -eq 0) {
        Write-Host "`n[!] Nomor tidak valid. Dibatalkan." -ForegroundColor Red
        Start-Sleep -Seconds 2
        return
    }

    foreach ($item in $toRemove) {
        $pkg = Get-AppxPackage -Name $item.Pkg -AllUsers -ErrorAction SilentlyContinue
        if ($pkg) {
            Write-Host " -> Menghapus $($item.App)..." -ForegroundColor Yellow
            Remove-AppxPackage -Package $pkg.PackageFullName -AllUsers -ErrorAction SilentlyContinue
        } else {
            Write-Host " -> $($item.App) tidak ditemukan (mungkin sudah terhapus)." -ForegroundColor DarkGray
        }
    }
    
    Write-Host "`n[+] Proses debloating selesai." -ForegroundColor Green
    Read-Host "`nTekan Enter untuk kembali ke menu..."
}

# ==========================================
# 7. FUNGSI SYSTEM RESTORE POINT
# ==========================================
function Invoke-CreateRestorePoint {
    Clear-Host
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host "               SYSTEM RESTORE POINT                " -ForegroundColor Cyan
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host "`n[+] Memeriksa status System Restore..." -ForegroundColor Yellow
    $srStatus = (Get-ComputerRestorePoint).Count
    if ($null -eq $srStatus) {
        Write-Host " -> System Restore belum diaktifkan di drive C:." -ForegroundColor Red
        Write-Host " -> Mengaktifkan System Restore..." -ForegroundColor Yellow
        Enable-ComputerRestore -Drive "C:\"
    }
    $desc = "Auto Restore Point - " + (Get-Date -Format "yyyy-MM-dd HH:mm")
    Write-Host "`n[+] Membuat Restore Point: $desc" -ForegroundColor Yellow
    Checkpoint-Computer -Description $desc -RestorePointType "MODIFY_SETTINGS"
    if ($?) { Write-Host " -> Restore Point berhasil dibuat!" -ForegroundColor Green } else { Write-Host " -> Gagal membuat Restore Point." -ForegroundColor Red }
    Read-Host "`nTekan Enter untuk kembali ke menu..."
}

# ==========================================
# 8. MENU UTAMA
# ==========================================
function Show-Menu {
    Clear-Host
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host "      PANDUAN POWERSHELL - CONTROL PANEL v1.4.0      " -ForegroundColor Cyan
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host " 1. Maintenance PC (Bersihkan & Optimasi)" -ForegroundColor Green
    Write-Host " 2. System Audit (Cek Hardware & OS)" -ForegroundColor Magenta
    Write-Host " 3. Network Diagnostics (Cek Jaringan)" -ForegroundColor Magenta
    Write-Host " 4. Backup Profil User" -ForegroundColor Green
    Write-Host " 5. Install Aplikasi Populer (Winget)" -ForegroundColor Yellow
    Write-Host " 6. Windows Debloater (Hapus Bloatware)" -ForegroundColor Yellow
    Write-Host " 7. Buat System Restore Point" -ForegroundColor Yellow
    Write-Host " 8. Keluar" -ForegroundColor Red
    Write-Host "===================================================" -ForegroundColor Cyan
}

do {
    Show-Menu
    $choice = Read-Host "Pilih opsi (1-8)"
    switch ($choice) {
        '1' { Invoke-Maintenance }
        '2' { Invoke-SystemAudit }
        '3' { Invoke-NetworkDiagnostics }
        '4' { Invoke-BackupUserProfile }
        '5' { Invoke-WingetAppInstaller }
        '6' { Invoke-WindowsDebloater }
        '7' { Invoke-CreateRestorePoint }
        '8' { Write-Host "Keluar..." -ForegroundColor Cyan }
        default { Write-Host "[!] Pilihan tidak valid." -ForegroundColor Red; Start-Sleep -Seconds 1 }
    }
} while ($choice -ne '8')
