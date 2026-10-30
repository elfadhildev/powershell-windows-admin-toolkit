if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -Command `"irm https://raw.githubusercontent.com/elfadhildev/powershell-windows-admin-toolkit/main/toolkit.ps1 | iex`"" -Verb RunAs
    exit
}

# ==========================================
# FUNGSI BANTUAN
# ==========================================
function Backup-RegistryTweaks {
    $backupDir = "$env:USERPROFILE\Desktop\ToolkitRegistryBackup"
    if (-not (Test-Path $backupDir)) { New-Item -Path $backupDir -ItemType Directory -Force | Out-Null }
    $time = Get-Date -Format "yyyyMMdd_HHmmss"
    $regFile = Join-Path $backupDir "Explorer_Advanced_$time.reg"
    Start-Process cmd -ArgumentList "/c reg export `"HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced`" `"$regFile`" /y" -Wait -NoNewWindow
}

# ==========================================
# FUNGSI 1-4: MAINTENANCE & DIAGNOSTICS
# ==========================================
function Invoke-Maintenance {
    Clear-Host
    Write-Host "========== MAINTENANCE PC ==========" -ForegroundColor Cyan
    Write-Host "[+] Memulai Maintenance..." -ForegroundColor Cyan
    
    Write-Host "[1/3] Membersihkan Cache DNS..." -ForegroundColor Yellow
    Clear-DnsClientCache; ipconfig /release | Out-Null; ipconfig /renew | Out-Null
    Write-Host " -> Cache DNS & IP berhasil diperbarui." -ForegroundColor Green

    Write-Host "[2/3] Membersihkan File Sementara..." -ForegroundColor Yellow
    $TempFolders = @("$env:TEMP", "C:\Windows\Temp", "C:\Windows\Prefetch", "C:\Windows\SoftwareDistribution\Download")
    foreach ($Folder in $TempFolders) { if (Test-Path $Folder) { Get-ChildItem -Path $Folder -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue } }
    Start-Process cleanmgr.exe -ArgumentList "/sagerun:1" -NoNewWindow -Wait
    Write-Host " -> File sementara dibersihkan." -ForegroundColor Green

    Write-Host "[3/3] Optimasi Drive C..." -ForegroundColor Yellow
    Write-Host " -> Mendeteksi jenis drive..." -ForegroundColor Gray
    $DriveType = (Get-PhysicalDisk | Where-Object { $_.DeviceID -eq (Get-Partition -DriveLetter C).DiskNumber }).MediaType
    if ($DriveType -eq "SSD") { 
        Write-Host " -> SSD Terdeteksi. Menjalankan ReTrim (Mohon tunggu)..." -ForegroundColor Gray
        Optimize-Volume -DriveLetter C -ReTrim | Out-Null 
    } else { 
        Write-Host " -> HDD Terdeteksi. Menjalankan Defrag (Mohon tunggu)..." -ForegroundColor Gray
        Optimize-Volume -DriveLetter C -Defrag | Out-Null
    }
    Write-Host " -> Optimasi selesai." -ForegroundColor Green
    Read-Host "`nTekan Enter untuk kembali ke menu..."
}

function Invoke-SystemAudit {
    Clear-Host; Write-Host "========== SISTEM AUDIT ==========" -ForegroundColor Cyan
    $os = Get-CimInstance Win32_OperatingSystem; $cpu = Get-CimInstance Win32_Processor; $ram = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)
    
    $report = "=== SYSTEM AUDIT ===`nOS: $($os.Caption) | CPU: $($cpu.Name) | RAM: $ram GB`n"
    Write-Host " OS: $($os.Caption) | CPU: $($cpu.Name) | RAM: $ram GB"

    $lic = Get-CimInstance SoftwareLicensingProduct | Where-Object { $_.PartialProductKey }
    if ($lic.LicenseStatus -eq 1) { $report += "Lisensi: Windows Teraktivasi`n"; Write-Host " Lisensi: Windows Teraktivasi" -ForegroundColor Green } else { $report += "Lisensi: Belum Teraktivasi`n"; Write-Host " Lisensi: Belum Teraktivasi" -ForegroundColor Red }
    
    Write-Host "`n[+] Storage:" -ForegroundColor Yellow
    $disks = Get-PhysicalDisk | Select-Object DeviceId, FriendlyName, MediaType, HealthStatus, @{N='Size(GB)';E={[math]::Round($_.Size/1GB,2)}}
    $disks | Format-Table -AutoSize
    $report += "`n[Storage]`n" + ($disks | Out-String)

    Write-Host "[+] Driver Bermasalah:" -ForegroundColor Yellow
    $badDrivers = Get-PnpDevice -PresentOnly | Where-Object { $_.Status -ne "OK" }
    if ($badDrivers) {
        $badDrivers | Select-Object Class, FriendlyName, Status | Format-Table -AutoSize
        $report += "`n[Driver Bermasalah]`n" + ($badDrivers | Select-Object Class, FriendlyName, Status | Out-String)
    } else {
        Write-Host " -> Semua driver berstatus OK." -ForegroundColor Green
        $report += "`n[Driver Bermasalah] Semua driver berstatus OK.`n"
    }

    Write-Host "`n[🛡️] Anda bisa menyimpan laporan ini ke dalam file teks." -ForegroundColor Yellow
    $save = Read-Host "Simpan laporan ke Desktop? (y/n)"
    if ($save -eq 'y') {
        $file = "$env:USERPROFILE\Desktop\System_Audit_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
        $report | Out-File -FilePath $file -Encoding UTF8
        Write-Host "[+] Laporan disimpan di: $file" -ForegroundColor Green
    }
    Read-Host "`nTekan Enter untuk kembali ke menu..."
}

function Invoke-NetworkDiagnostics {
    $ErrorActionPreference = 'SilentlyContinue'; Clear-Host
    Write-Host "========== DIAGNOSTIK JARINGAN ==========" -ForegroundColor Cyan
    
    Write-Host "`n[+] Konfigurasi IP & DNS:" -ForegroundColor Yellow
    Get-NetIPConfiguration | Where-Object { $_.IPv4Address } | Select-Object InterfaceAlias, IPv4Address, @{N='Gateway';E={$_.IPv4DefaultGateway.NextHop}}, @{N='DNS';E={$_.DNSServer.ServerAddresses -join ', '}} | Format-List

    Write-Host "[+] Koneksi Internet Aktif (Established):" -ForegroundColor Yellow
    Get-NetTCPConnection -State Established | ForEach-Object {
        $Process = Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue
        [PSCustomObject]@{
            LocalPort  = $_.LocalPort
            RemoteAddr = $_.RemoteAddress
            RemotePort = $_.RemotePort
            Process    = if($Process){$Process.ProcessName}else{'<unknown>'}
            PID        = $_.OwningProcess
        }
    } | Sort-Object Process | Format-Table -AutoSize

    Write-Host "[+] Tes Resolusi DNS (google.com):" -ForegroundColor Yellow
    $dns = Resolve-DnsName -Name "google.com" -Type A -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($dns) { Write-Host " -> Berhasil: google.com -> $($dns.IPAddress)" -ForegroundColor Green } else { Write-Host " -> Gagal melakukan resolusi DNS!" -ForegroundColor Red }

    Read-Host "`nTekan Enter untuk kembali ke menu..."
}

function Invoke-BackupUserProfile {
    Clear-Host
    Write-Host "========== BACKUP PROFIL USER ==========" -ForegroundColor Cyan
    $DestinationFolder = Join-Path -Path 'D:\Backup_PC' -ChildPath "Backup_$(Get-Date -Format 'yyyy-MM-dd')"
    $FoldersToBackup = @('Documents', 'Pictures', 'Desktop', 'Downloads', 'Music', 'Videos', 'AppData\Roaming', 'AppData\Local\Packages')
    $ExcludeFolders = @('Cache', 'Temp', 'CrashDumps', 'GPUCache', 'Microsoft\Windows\INetCache')
    if (-not (Test-Path $DestinationFolder)) { New-Item -Path $DestinationFolder -ItemType Directory -Force | Out-Null }
    $LogFile = Join-Path -Path $DestinationFolder -ChildPath 'Backup_Log.txt'
    foreach ($Folder in $FoldersToBackup) { $SourcePath = Join-Path -Path $env:USERPROFILE -ChildPath $Folder; $TargetPath = Join-Path -Path $DestinationFolder -ChildPath $Folder; if (Test-Path $SourcePath) { robocopy $SourcePath $TargetPath /MIR /R:1 /W:1 /XD $ExcludeFolders /LOG+:$LogFile /NP /NJH /NJS } }
    Write-Host "`n[+] PROSES BACKUP SELESAI! Log: $LogFile" -ForegroundColor Green; Read-Host "`nTekan Enter untuk kembali..."
}

# ==========================================
# 5. WINGET APP INSTALLER (KATEGORI - CTT STYLE)
# ==========================================
function Invoke-WingetAppInstaller {
    $apps = @(
        # Browsers
        [PSCustomObject]@{ Cat='Browsers'; Name='Google Chrome'; Id='Google.Chrome' },
        [PSCustomObject]@{ Cat='Browsers'; Name='Mozilla Firefox'; Id='Mozilla.Firefox' },
        [PSCustomObject]@{ Cat='Browsers'; Name='Brave'; Id='Brave.Brave' },
        [PSCustomObject]@{ Cat='Browsers'; Name='Microsoft Edge'; Id='Microsoft.Edge' },
        [PSCustomObject]@{ Cat='Browsers'; Name='Opera GX'; Id='Opera.OperaGX' },
        [PSCustomObject]@{ Cat='Browsers'; Name='Tor Browser'; Id='TorProject.TorBrowser' },
        [PSCustomObject]@{ Cat='Browsers'; Name='Vivaldi'; Id='Vivaldi.Vivaldi' },
        [PSCustomObject]@{ Cat='Browsers'; Name='LibreWolf'; Id='LibreWolf.LibreWolf' },

        # Communications
        [PSCustomObject]@{ Cat='Communications'; Name='Discord'; Id='Discord.Discord' },
        [PSCustomObject]@{ Cat='Communications'; Name='Zoom'; Id='Zoom.Zoom' },
        [PSCustomObject]@{ Cat='Communications'; Name='Telegram Desktop'; Id='Telegram.TelegramDesktop' },
        [PSCustomObject]@{ Cat='Communications'; Name='WhatsApp'; Id='WhatsApp.WhatsApp' },
        [PSCustomObject]@{ Cat='Communications'; Name='Slack'; Id='SlackTechnologies.Slack' },
        [PSCustomObject]@{ Cat='Communications'; Name='Microsoft Teams'; Id='Microsoft.Teams' },
        [PSCustomObject]@{ Cat='Communications'; Name='Signal'; Id='OpenWhisperSystems.Signal' },

        # Development
        [PSCustomObject]@{ Cat='Development'; Name='Visual Studio Code'; Id='Microsoft.VisualStudioCode' },
        [PSCustomObject]@{ Cat='Development'; Name='Git'; Id='Git.Git' },
        [PSCustomObject]@{ Cat='Development'; Name='Python 3'; Id='Python.Python.3.12' },
        [PSCustomObject]@{ Cat='Development'; Name='Node.js'; Id='OpenJS.NodeJS' },
        [PSCustomObject]@{ Cat='Development'; Name='Docker Desktop'; Id='Docker.DockerDesktop' },
        [PSCustomObject]@{ Cat='Development'; Name='Postman'; Id='Postman.Postman' },
        [PSCustomObject]@{ Cat='Development'; Name='GitHub Desktop'; Id='GitHub.GitHubDesktop' },
        [PSCustomObject]@{ Cat='Development'; Name='Neovim'; Id='Neovim.Neovim' },

        # Document & Office
        [PSCustomObject]@{ Cat='Document'; Name='LibreOffice'; Id='TheDocumentFoundation.LibreOffice' },
        [PSCustomObject]@{ Cat='Document'; Name='ONLYOFFICE'; Id='ONLYOFFICE.DesktopEditors' },
        [PSCustomObject]@{ Cat='Document'; Name='Adobe Acrobat Reader'; Id='Adobe.Acrobat.Reader.64-bit' },
        [PSCustomObject]@{ Cat='Document'; Name='Sumatra PDF'; Id='SumatraPDF.SumatraPDF' },
        [PSCustomObject]@{ Cat='Document'; Name='Obsidian'; Id='Obsidian.Obsidian' },
        [PSCustomObject]@{ Cat='Document'; Name='PDF24 Creator'; Id='PDF24.PDF24Creator' },

        # Games
        [PSCustomObject]@{ Cat='Games'; Name='Steam'; Id='Valve.Steam' },
        [PSCustomObject]@{ Cat='Games'; Name='Epic Games Launcher'; Id='EpicGames.EpicGamesLauncher' },
        [PSCustomObject]@{ Cat='Games'; Name='Battle.net'; Id='Blizzard.BattleNet' },
        [PSCustomObject]@{ Cat='Games'; Name='GOG Galaxy'; Id='GOG.Galaxy' },
        [PSCustomObject]@{ Cat='Games'; Name='Playnite'; Id='Playnite.Playnite' },

        # Microsoft Tools
        [PSCustomObject]@{ Cat='Microsoft'; Name='PowerToys'; Id='Microsoft.PowerToys' },
        [PSCustomObject]@{ Cat='Microsoft'; Name='Windows Terminal'; Id='Microsoft.WindowsTerminal' },
        [PSCustomObject]@{ Cat='Microsoft'; Name='Sysinternals Suite'; Id='Microsoft.Sysinternals' },
        [PSCustomObject]@{ Cat='Microsoft'; Name='.NET Desktop Runtime 8'; Id='Microsoft.DotNet.DesktopRuntime.8' },

        # Multimedia
        [PSCustomObject]@{ Cat='Multimedia'; Name='VLC Media Player'; Id='VideoLAN.VLC' },
        [PSCustomObject]@{ Cat='Multimedia'; Name='Spotify'; Id='Spotify.Spotify' },
        [PSCustomObject]@{ Cat='Multimedia'; Name='OBS Studio'; Id='OBSProject.OBSStudio' },
        [PSCustomObject]@{ Cat='Multimedia'; Name='GIMP'; Id='GIMP.GIMP' },
        [PSCustomObject]@{ Cat='Multimedia'; Name='Audacity'; Id='Audacity.Audacity' },
        [PSCustomObject]@{ Cat='Multimedia'; Name='HandBrake'; Id='HandBrake.HandBrake' },
        [PSCustomObject]@{ Cat='Multimedia'; Name='K-Lite Codec Standard'; Id='CodecGuide.K-LiteCodecPack.Standard' },

        # Pro Tools
        [PSCustomObject]@{ Cat='Pro Tools'; Name='Wireshark'; Id='WiresharkFoundation.Wireshark' },
        [PSCustomObject]@{ Cat='Pro Tools'; Name='Nmap'; Id='Insecure.Nmap' },
        [PSCustomObject]@{ Cat='Pro Tools'; Name='PuTTY'; Id='PuTTY.PuTTY' },
        [PSCustomObject]@{ Cat='Pro Tools'; Name='WinSCP'; Id='WinSCP.WinSCP' },
        [PSCustomObject]@{ Cat='Pro Tools'; Name='CPU-Z'; Id='CPUID.CPU-Z' },
        [PSCustomObject]@{ Cat='Pro Tools'; Name='GPU-Z'; Id='TechPowerUp.GPU-Z' },
        [PSCustomObject]@{ Cat='Pro Tools'; Name='Ventoy'; Id='Ventoy.Ventoy' },

        # Utilities
        [PSCustomObject]@{ Cat='Utilities'; Name='7-Zip'; Id='7zip.7zip' },
        [PSCustomObject]@{ Cat='Utilities'; Name='WinRAR'; Id='RARLab.WinRAR' },
        [PSCustomObject]@{ Cat='Utilities'; Name='Everything'; Id='voidtools.Everything' },
        [PSCustomObject]@{ Cat='Utilities'; Name='Rufus'; Id='Rufus.Rufus' },
        [PSCustomObject]@{ Cat='Utilities'; Name='TeamViewer'; Id='TeamViewer.TeamViewer' },
        [PSCustomObject]@{ Cat='Utilities'; Name='AnyDesk'; Id='AnyDeskSoftwareGmbH.AnyDesk' },
        [PSCustomObject]@{ Cat='Utilities'; Name='Bitwarden'; Id='Bitwarden.Bitwarden' },
        [PSCustomObject]@{ Cat='Utilities'; Name='KeePassXC'; Id='KeePassXCTeam.KeePassXC' }
    )

    $categories = $apps.Cat | Sort-Object -Unique

    do {
        Clear-Host
        Write-Host "========== WINGET APP INSTALLER (KATEGORI) ==========" -ForegroundColor Cyan
        Write-Host "Pilih Kategori Aplikasi:" -ForegroundColor Yellow
        for ($i = 0; $i -lt $categories.Count; $i++) {
            Write-Host " $($i + 1). $($categories[$i])"
        }
        Write-Host " 0. Kembali ke Menu Utama" -ForegroundColor Red
        
        $catChoice = Read-Host "`nMasukkan nomor kategori"
        
        if ($catChoice -eq '0') { return }
        
        $selectedCatIndex = [int]$catChoice - 1
        if ($selectedCatIndex -ge 0 -and $selectedCatIndex -lt $categories.Count) {
            $selectedCat = $categories[$selectedCatIndex]
            $filteredApps = $apps | Where-Object { $_.Cat -eq $selectedCat }
            
            Clear-Host
            Write-Host "========== $($selectedCat.ToUpper()) ==========" -ForegroundColor Cyan
            Write-Host "Pilih aplikasi yang ingin diinstal (pisahkan dengan koma, misal: 1,2):" -ForegroundColor Yellow
            for ($j = 0; $j -lt $filteredApps.Count; $j++) {
                Write-Host " $($j + 1). $($filteredApps[$j].Name)"
            }
            Write-Host " 0. Batal"
            
            $appChoice = Read-Host "`nMasukkan nomor aplikasi"
            
            if ($appChoice -ne '0' -and $appChoice -ne '') {
                $selectedIndices = $appChoice -split ',' | ForEach-Object { $_.Trim() }
                foreach ($idx in $selectedIndices) {
                    $appIndex = [int]$idx - 1
                    if ($appIndex -ge 0 -and $appIndex -lt $filteredApps.Count) {
                        $appId = $filteredApps[$appIndex].Id
                        $appName = $filteredApps[$appIndex].Name
                        Write-Host "`n[+] Menginstal $appName..." -ForegroundColor Green
                        winget install --id $appId --accept-source-agreements --accept-package-agreements --silent
                    }
                }
                Read-Host "`n[+] Proses instalasi selesai. Tekan Enter untuk kembali..."
            }
        }
    } while ($true)
}

# ==========================================
# FUNGSI 6-7: DEBLOATER & RESTORE
# ==========================================
function Invoke-WindowsDebloater {
    Clear-Host; Write-Host "========== WINDOWS DEBLOATER ==========" -ForegroundColor Cyan
    $debloatList = @([PSCustomObject]@{No='1';App='Cortana';Pkg='Microsoft.549981C3F5F10'},[PSCustomObject]@{No='2';App='Bing News';Pkg='Microsoft.BingNews'},[PSCustomObject]@{No='3';App='Bing Weather';Pkg='Microsoft.BingWeather'},[PSCustomObject]@{No='4';App='Get Help';Pkg='Microsoft.GetHelp'},[PSCustomObject]@{No='5';App='Tips';Pkg='Microsoft.Getstarted'},[PSCustomObject]@{No='6';App='Office Hub';Pkg='Microsoft.MicrosoftOfficeHub'},[PSCustomObject]@{No='7';App='Solitaire';Pkg='Microsoft.MicrosoftSolitaireCollection'},[PSCustomObject]@{No='8';App='People';Pkg='Microsoft.People'},[PSCustomObject]@{No='9';App='Skype';Pkg='Microsoft.SkypeApp'},[PSCustomObject]@{No='10';App='Feedback Hub';Pkg='Microsoft.WindowsFeedbackHub'},[PSCustomObject]@{No='11';App='Xbox App';Pkg='Microsoft.XboxApp'},[PSCustomObject]@{No='12';App='Xbox Overlay';Pkg='Microsoft.XboxGamingOverlay'},[PSCustomObject]@{No='13';App='Your Phone';Pkg='Microsoft.YourPhone'},[PSCustomObject]@{No='14';App='Groove Music';Pkg='Microsoft.ZuneMusic'},[PSCustomObject]@{No='15';App='Movies & TV';Pkg='Microsoft.ZuneVideo'})
    $debloatList | Format-Table -AutoSize
    $inputApps = Read-Host "Ketik nomor (misal: 1,2), 'all' untuk semua, atau 'x' batal"
    if ($inputApps -eq 'x' -or $inputApps -eq '') { return }
    if ($inputApps -eq 'all') { $toRemove = $debloatList } else { $selectedNums = $inputApps -split ',' | ForEach-Object { $_.Trim() }; $toRemove = $debloatList | Where-Object { $selectedNums -contains $_.No } }
    foreach ($item in $toRemove) { $pkg = Get-AppxPackage -Name $item.Pkg -AllUsers -ErrorAction SilentlyContinue; if ($pkg) { Remove-AppxPackage -Package $pkg.PackageFullName -AllUsers -ErrorAction SilentlyContinue } }
    Write-Host "`n[+] Selesai." -ForegroundColor Green; Read-Host "Tekan Enter..."
}

function Invoke-CreateRestorePoint {
    Clear-Host; Write-Host "========== SYSTEM RESTORE POINT ==========" -ForegroundColor Cyan
    if ((Get-ComputerRestorePoint).Count -eq $null) { Enable-ComputerRestore -Drive "C:\" }
    Checkpoint-Computer -Description "Auto Restore - $(Get-Date -Format 'yyyy-MM-dd HH:mm')" -RestorePointType "MODIFY_SETTINGS"
    Write-Host "`n[+] Restore Point berhasil dibuat!" -ForegroundColor Green; Read-Host "Tekan Enter..."
}

# ==========================================
# FUNGSI 8-10: TWEAKS, FIXES, UPDATES
# ==========================================
function Invoke-SystemTweaks {
    Clear-Host; Write-Host "========== SYSTEM TWEAKS ==========" -ForegroundColor Cyan
    Backup-RegistryTweaks
    Write-Host "`n1. Disable Telemetry`n2. Optimize Visual Effects`n3. Show File Extensions`n4. Disable Game Bar`n5. Apply ALL`n6. Kembali" -ForegroundColor Yellow
    $choice = Read-Host "`nPilih (1-6)"
    switch ($choice) {
        '1' { Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0 -Type DWord -ErrorAction SilentlyContinue; Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Start_TrackDocs" -Value 0 -Type DWord; Write-Host "[+] Telemetry off." -ForegroundColor Green }
        '2' { Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value 2 -Type DWord; Write-Host "[+] Visual Effects optimized." -ForegroundColor Green }
        '3' { Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 0 -Type DWord; Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Hidden" -Value 1 -Type DWord; Write-Host "[+] Extensions shown." -ForegroundColor Green }
        '4' { Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "AutoGameModeEnabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue; Write-Host "[+] Game Bar off." -ForegroundColor Green }
        '5' { Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0 -Type DWord -ErrorAction SilentlyContinue; Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Start_TrackDocs" -Value 0 -Type DWord; Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value 2 -Type DWord; Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 0 -Type DWord; Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Hidden" -Value 1 -Type DWord; Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "AutoGameModeEnabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue; Write-Host "[+] All tweaks applied." -ForegroundColor Green }
        '6' { return }
    }
    Read-Host "`nTekan Enter..."
}

function Invoke-OneClickFixes {
    Clear-Host; Write-Host "========== ONE-CLICK FIXES ==========" -ForegroundColor Cyan
    Write-Host "1. Reset Network`n2. Reset Update Cache`n3. Repair System (SFC/DISM)`n4. Kembali" -ForegroundColor Yellow
    $choice = Read-Host "`nPilih (1-4)"
    switch ($choice) {
        '1' { netsh winsock reset | Out-Null; netsh int ip reset | Out-Null; ipconfig /flushdns | Out-Null; Write-Host "[+] Network reset. Silakan restart." -ForegroundColor Green }
        '2' { Stop-Service -Name wuauserv, cryptSvc, bits, msiserver -Force -ErrorAction SilentlyContinue; Remove-Item -Path "C:\Windows\SoftwareDistribution\*" -Recurse -Force -ErrorAction SilentlyContinue; Start-Service -Name wuauserv, cryptSvc, bits, msiserver -ErrorAction SilentlyContinue; Write-Host "[+] Update cache reset." -ForegroundColor Green }
        '3' { Write-Host "[+] Running SFC & DISM (Please wait)..." -ForegroundColor Yellow; Start-Process cmd -ArgumentList "/c sfc /scannow" -Wait -NoNewWindow; Start-Process cmd -ArgumentList "/c DISM /Online /Cleanup-Image /RestoreHealth" -Wait -NoNewWindow; Write-Host "[+] Repair complete." -ForegroundColor Green }
        '4' { return }
    }
    Read-Host "`nTekan Enter..."
}

function Invoke-UpdateManager {
    Clear-Host; Write-Host "========== UPDATE MANAGER ==========" -ForegroundColor Cyan
    Write-Host "1. Pause 35 hari`n2. Pause 1 Tahun`n3. Pause 50 Tahun (Ekstrem)`n4. Resume Updates`n5. Security Only`n6. Kembali" -ForegroundColor Yellow
    $choice = Read-Host "`nPilih (1-6)"
    $UpdateKey = "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings"; if (-not (Test-Path $UpdateKey)) { New-Item -Path $UpdateKey -Force | Out-Null }
    switch ($choice) {
        '1' { Set-ItemProperty -Path $UpdateKey -Name "FlightSettingsMaxPauseDays" -Value 35 -Type DWord; Set-ItemProperty -Path $UpdateKey -Name "PauseUpdatesExpiryTime" -Value (Get-Date).AddDays(35).ToString("yyyy-MM-ddTHH:mm:ssZ"); Write-Host "[+] Paused 35 days." -ForegroundColor Green }
        '2' { Set-ItemProperty -Path $UpdateKey -Name "FlightSettingsMaxPauseDays" -Value 365 -Type DWord; Set-ItemProperty -Path $UpdateKey -Name "PauseUpdatesExpiryTime" -Value (Get-Date).AddDays(365).ToString("yyyy-MM-ddTHH:mm:ssZ"); Write-Host "[+] Paused 1 year." -ForegroundColor Green }
        '3' { Set-ItemProperty -Path $UpdateKey -Name "FlightSettingsMaxPauseDays" -Value 18250 -Type DWord; Set-ItemProperty -Path $UpdateKey -Name "PauseUpdatesExpiryTime" -Value (Get-Date).AddYears(50).ToString("yyyy-MM-ddTHH:mm:ssZ"); Write-Host "[+] Paused 50 years." -ForegroundColor Green }
        '4' { Remove-ItemProperty -Path $UpdateKey -Name "PauseUpdatesExpiryTime" -ErrorAction SilentlyContinue; Remove-ItemProperty -Path $UpdateKey -Name "FlightSettingsMaxPauseDays" -ErrorAction SilentlyContinue; Write-Host "[+] Resumed." -ForegroundColor Green }
        '5' { Set-ItemProperty -Path $UpdateKey -Name "DeferFeatureUpdates" -Value 1 -Type DWord; Set-ItemProperty -Path $UpdateKey -Name "DeferFeatureUpdatesPeriodInDays" -Value 365 -Type DWord; Write-Host "[+] Security updates only." -ForegroundColor Green }
        '6' { return }
    }
    Read-Host "`nTekan Enter..."
}

# ==========================================
# 11-12. FUNGSI LAMA: PRESETS & APP BACKUP
# ==========================================
function Invoke-Presets {
    Clear-Host; Write-Host "========== AUTOMATION PRESETS ==========" -ForegroundColor Cyan
    Write-Host "1. Standard Setup`n2. Gamer Setup`n3. Developer Setup`n4. Minimalist Setup`n5. Kembali" -ForegroundColor Green
    $choice = Read-Host "`nPilih Preset (1-5)"
    if ($choice -eq '5') { return }
    Write-Host "`n[+] Memulai proses otomatisasi..." -ForegroundColor Yellow
    Start-Sleep -Seconds 1
    switch ($choice) {
        '1' { $apps = @('Google.Chrome', '7zip.7zip', 'VideoLAN.VLC'); $tweaks = $true }
        '2' { $apps = @('Valve.Steam', 'Discord.Discord', 'OBSProject.OBSStudio'); $tweaks = $true; Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "AutoGameModeEnabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue }
        '3' { $apps = @('Microsoft.VisualStudioCode', 'Git.Git', 'Python.Python.3.12', 'Microsoft.PowerToys'); $tweaks = $false }
        '4' { $apps = @(); $tweaks = $true }
    }
    if ($tweaks) { Backup-RegistryTweaks; Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0 -Type DWord -ErrorAction SilentlyContinue; Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value 2 -Type DWord; Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 0 -Type DWord }
    if ($apps.Count -gt 0) {
        $i = 0
        foreach ($app in $apps) { $i++; $percent = [math]::Round(($i / $apps.Count) * 100); Write-Progress -Activity "Menginstal Aplikasi" -Status "Installing $app" -PercentComplete $percent; winget install --id $app --accept-source-agreements --accept-package-agreements --silent | Out-Null }
        Write-Progress -Activity "Menginstal Aplikasi" -Completed
    }
    Write-Host "`n[+] PRESET BERHASIL DITERAPKAN!" -ForegroundColor Green; Read-Host "`nTekan Enter..."
}

function Invoke-AppBackup {
    Clear-Host; Write-Host "========== APP BACKUP MANAGER ==========" -ForegroundColor Cyan
    Write-Host "1. Export Daftar Aplikasi`n2. Import & Install Daftar Aplikasi`n3. Kembali" -ForegroundColor Green
    $choice = Read-Host "`nPilih (1-3)"
    $backupFile = "$env:USERPROFILE\Desktop\MyAppsBackup.json"
    switch ($choice) {
        '1' { winget export -o $backupFile --accept-source-agreements; Write-Host "[+] SUKSES! File backup ada di Desktop." -ForegroundColor Green }
        '2' { if (Test-Path $backupFile) { winget import -i $backupFile --accept-source-agreements --accept-package-agreements; Write-Host "`n[+] Selesai." -ForegroundColor Green } else { Write-Host "[!] File tidak ditemukan di Desktop." -ForegroundColor Red } }
        '3' { return }
    }
    Read-Host "`nTekan Enter..."
}

# ==========================================
# 13. SMART EVENT LOG ANALYZER
# ==========================================
function Invoke-EventLogAnalyzer {
    do {
        Clear-Host
        Write-Host "========== SMART EVENT LOG ANALYZER ==========" -ForegroundColor Cyan
        Write-Host "[+] Memindai Event Log (7 Hari Terakhir)..." -ForegroundColor Yellow
        $events = Get-WinEvent -FilterHashtable @{LogName='System','Application'; Level=1,2; StartTime=(Get-Date).AddDays(-7)} -ErrorAction SilentlyContinue
        
        if (-not $events) { 
            Write-Host "`n[+] Luar biasa! Tidak ada Error/Critical di log sistem minggu ini." -ForegroundColor Green 
            Read-Host "`nTekan Enter untuk kembali..."
            return
        }

        $summary = $events | Group-Object ProviderName | Sort-Object Count -Descending | Select-Object -First 10
        Write-Host "`n[!] Ditemukan $($events.Count) error. Berikut Top 10 Penyebab:" -ForegroundColor Red
        
        $i = 0
        $summary | ForEach-Object {
            $i++
            Write-Host "[$i] $($_.Name) ($($_.Count) kali)" -ForegroundColor Gray
        }
        
        Write-Host "===================================================" -ForegroundColor Cyan
        Write-Host "Ketik nomor untuk melihat detail & saran perbaikan, atau 'x' untuk kembali." -ForegroundColor Yellow
        $choice = Read-Host "Pilih"
        
        if ($choice -eq 'x' -or $choice -eq '') { return }

        $selectedItem = $summary[$choice - 1]
        if ($selectedItem) {
            $provider = $selectedItem.Name
            Clear-Host
            Write-Host "========== DETAIL ERROR: $provider ==========" -ForegroundColor Cyan
            
            $details = $events | Where-Object { $_.ProviderName -eq $provider } | Select-Object -First 3
            foreach ($d in $details) {
                Write-Host "Waktu  : $($d.TimeCreated)" -ForegroundColor DarkGray
                Write-Host "ID     : $($d.Id)"
                Write-Host "Pesan  : $($d.Message -replace "`r`n", ' ')" -ForegroundColor White
                Write-Host "---------------------------------------------------"
            }
            
            Write-Host "`n[💡] SARAN PERBAIKAN:" -ForegroundColor Yellow
            
            $fixAction = $null
            switch -Wildcard ($provider) {
                "*DistributedCOM*" { Write-Host "Error ini (Event ID 10016) SANGAT UMUM di Windows dan biasanya aman untuk diabaikan." -ForegroundColor Green }
                "*Service Control Manager*" { Write-Host "Ada layanan (Service) yang gagal berjalan. Ini bisa disebabkan oleh file sistem yang korup." -ForegroundColor Red; Write-Host "Disarankan: Jalankan Repair System (SFC & DISM)." -ForegroundColor Yellow; $fixAction = "SFC" }
                "*VSS*" { Write-Host "Volume Shadow Copy (VSS) gagal membuat Restore Point. Bisa karena disk penuh atau layanan VSS mati." -ForegroundColor Red; Write-Host "Disarankan: Reset layanan VSS atau Repair System." -ForegroundColor Yellow; $fixAction = "SFC" }
                "*CAPI2*" { Write-Host "Cryptographic API (CAPI2) gagal memvalidasi pembaruan. Biasanya karena koneksi internet terputus saat update." -ForegroundColor Red; Write-Host "Disarankan: Reset Windows Update Cache." -ForegroundColor Yellow; $fixAction = "Update" }
                Default { Write-Host "Error ini belum memiliki panduan spesifik. Jika PC berjalan normal, Anda bisa mengabaikannya." -ForegroundColor Gray }
            }

            Write-Host "`n===================================================" -ForegroundColor Cyan
            if ($fixAction -eq "SFC") {
                Write-Host "1. Jalankan Repair System (SFC & DISM) sekarang" -ForegroundColor Green
                Write-Host "2. Kembali ke daftar error"
                $action = Read-Host "`nPilih (1-2)"
                if ($action -eq '1') {
                    Write-Host "`n[+] Menjalankan SFC & DISM (Mohon tunggu)..." -ForegroundColor Yellow
                    Start-Process cmd -ArgumentList "/c sfc /scannow" -Wait -NoNewWindow
                    Start-Process cmd -ArgumentList "/c DISM /Online /Cleanup-Image /RestoreHealth" -Wait -NoNewWindow
                    Write-Host "`n[+] Proses selesai." -ForegroundColor Green
                }
            } elseif ($fixAction -eq "Update") {
                Write-Host "1. Reset Update Cache sekarang" -ForegroundColor Green
                Write-Host "2. Kembali ke daftar error"
                $action = Read-Host "`nPilih (1-2)"
                if ($action -eq '1') {
                    Write-Host "`n[+] Mereset Windows Update..." -ForegroundColor Yellow
                    Stop-Service -Name wuauserv, cryptSvc, bits, msiserver -Force -ErrorAction SilentlyContinue
                    Remove-Item -Path "C:\Windows\SoftwareDistribution\*" -Recurse -Force -ErrorAction SilentlyContinue
                    Start-Service -Name wuauserv, cryptSvc, bits, msiserver -ErrorAction SilentlyContinue
                    Write-Host "[+] Cache Update berhasil di-reset." -ForegroundColor Green
                }
            } else {
                Read-Host "`nTekan Enter untuk kembali ke daftar..."
            }
        }
    } while ($true)
}

# ==========================================
# 14. INTERACTIVE STARTUP MANAGER
# ==========================================
function Invoke-StartupManager {
    do {
        Clear-Host
        Write-Host "========== STARTUP MANAGER (INTERAKTIF) ==========" -ForegroundColor Cyan
        Write-Host "[+] Mendeteksi aplikasi startup..." -ForegroundColor Yellow

        $startupItems = @()
        $regPaths = @("HKCU:\Software\Microsoft\Windows\CurrentVersion\Run", "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run")
        foreach ($path in $regPaths) {
            if (Test-Path $path) {
                $props = Get-ItemProperty -Path $path
                $props.PSObject.Properties | Where-Object { $_.Name -notmatch '^PS' } | ForEach-Object {
                    $startupItems += [PSCustomObject]@{ Name = $_.Name; Command = $_.Value; Location = $path }
                }
            }
        }

        $i = 0
        $startupItems | ForEach-Object {
            $i++
            Write-Host "[$i] $($_.Name)" -ForegroundColor Green
            Write-Host "    Path : $($_.Command)" -ForegroundColor Gray
            Write-Host "    Loc  : $($_.Location)" -ForegroundColor DarkGray
        }

        if ($startupItems.Count -eq 0) {
            Write-Host " -> Tidak ada item startup yang terdeteksi." -ForegroundColor Yellow
            Read-Host "`nTekan Enter untuk kembali..."
            return
        }

        Write-Host "===================================================" -ForegroundColor Cyan
        Write-Host "Ketik nomor untuk mengelola, atau 'x' untuk kembali." -ForegroundColor Yellow
        $choice = Read-Host "Pilih"

        if ($choice -eq 'x' -or $choice -eq '') { return }

        $selectedItem = $startupItems[$choice - 1]
        if ($selectedItem) {
            Clear-Host
            Write-Host "========== MENGELOLA: $($selectedItem.Name) ==========" -ForegroundColor Cyan
            Write-Host "Path: $($selectedItem.Command)" -ForegroundColor Gray
            Write-Host "`nOpsi:" -ForegroundColor Yellow
            Write-Host "1. Hapus dari Startup (Disable)"
            Write-Host "2. Cek Digital Signature File .exe"
            Write-Host "3. Buka lokasi file (jika ada)"
            Write-Host "4. Batal"
            $action = Read-Host "`nPilih aksi (1-4)"

            switch ($action) {
                '1' {
                    try {
                        Remove-ItemProperty -Path $selectedItem.Location -Name $selectedItem.Name -ErrorAction Stop
                        Write-Host "`n[+] Berhasil menghapus '$($selectedItem.Name)' dari startup." -ForegroundColor Green
                    } catch {
                        Write-Host "`n[!] Gagal menghapus. Anda mungkin butuh hak Admin." -ForegroundColor Red
                    }
                    Read-Host "`nTekan Enter..."
                }
                '2' {
                    $exePath = $selectedItem.Command
                    if ($exePath -match '^"([^"]+)"') { $exePath = $matches[1] }
                    elseif ($exePath -match '^(\S+\.exe)') { $exePath = $matches[1] }
                    
                    if (Test-Path $exePath) {
                        $sig = Get-AuthenticodeSignature -FilePath $exePath
                        Write-Host "`n[+] Status Signature: $($sig.Status)" -ForegroundColor $(if ($sig.Status -eq 'Valid') { 'Green' } else { 'Red' })
                        if ($sig.SignerCertificate) { Write-Host "    Publisher: $($sig.SignerCertificate.Subject)" -ForegroundColor Gray } else { Write-Host "    Publisher: Tidak ada signature (Tidak Dikenal)" -ForegroundColor Red }
                    } else { Write-Host "`n[!] File .exe tidak ditemukan." -ForegroundColor Red }
                    Read-Host "`nTekan Enter..."
                }
                '3' {
                    $exePath = $selectedItem.Command
                    if ($exePath -match '^"([^"]+)"') { $exePath = $matches[1] }
                    elseif ($exePath -match '^(\S+\.exe)') { $exePath = $matches[1] }
                    
                    if (Test-Path $exePath) { Start-Process explorer.exe -ArgumentList "/select,`"$exePath`"" } else { Write-Host "`n[!] File tidak ditemukan." -ForegroundColor Red; Read-Host "Tekan Enter..." }
                }
                '4' { }
            }
        } else {
            Write-Host "`n[!] Nomor tidak valid." -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    } while ($true)
}

# ==========================================
# 15. DNS SWITCHER
# ==========================================
function Invoke-DnsSwitcher {
    Clear-Host
    Write-Host "========== DNS & NETWORK SWITCHER ==========" -ForegroundColor Cyan
    Write-Host "Mengubah DNS dapat mempercepat internet dan memblokir iklan." -ForegroundColor Gray
    Write-Host "`nPilih DNS yang ingin digunakan:" -ForegroundColor Yellow
    Write-Host "1. Cloudflare (1.1.1.1) - Tercepat & Privasi"
    Write-Host "2. Google (8.8.8.8) - Paling Stabil"
    Write-Host "3. Quad9 (9.9.9.9) - Blokir Malware"
    Write-Host "4. Reset ke Otomatis (DHCP)"
    Write-Host "5. Batal"
    $choice = Read-Host "`nPilih (1-5)"

    $adapters = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }
    if (-not $adapters) {
        Write-Host "`n[!] Tidak ada koneksi internet aktif." -ForegroundColor Red
        Read-Host "Tekan Enter..."; return
    }

    switch ($choice) {
        '1' { foreach ($a in $adapters) { Set-DnsClientServerAddress -InterfaceIndex $a.ifIndex -ServerAddresses ("1.1.1.1","1.0.0.1") }; Write-Host "`n[+] DNS diubah ke Cloudflare." -ForegroundColor Green }
        '2' { foreach ($a in $adapters) { Set-DnsClientServerAddress -InterfaceIndex $a.ifIndex -ServerAddresses ("8.8.8.8","8.8.4.4") }; Write-Host "`n[+] DNS diubah ke Google." -ForegroundColor Green }
        '3' { foreach ($a in $adapters) { Set-DnsClientServerAddress -InterfaceIndex $a.ifIndex -ServerAddresses ("9.9.9.9","149.112.112.112") }; Write-Host "`n[+] DNS diubah ke Quad9." -ForegroundColor Green }
        '4' { foreach ($a in $adapters) { Set-DnsClientServerAddress -InterfaceIndex $a.ifIndex -ResetServerAddresses }; Write-Host "`n[+] DNS dikembalikan ke Otomatis (DHCP)." -ForegroundColor Green }
        '5' { return }
    }
    Clear-DnsClientCache
    Write-Host "[+] Cache DNS berhasil dibersihkan." -ForegroundColor Green
    Read-Host "`nTekan Enter untuk kembali..."
}

# ==========================================
# MENU UTAMA (v1.9.8)
# ==========================================
function Show-Menu {
    Clear-Host
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host "      PANDUAN POWERSHELL - CONTROL PANEL v1.9.8      " -ForegroundColor Cyan
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host " 1. Maintenance PC (Bersihkan & Optimasi)" -ForegroundColor Green
    Write-Host " 2. System Audit (Cek Hardware & OS)" -ForegroundColor Magenta
    Write-Host " 3. Network Diagnostics (Cek Jaringan)" -ForegroundColor Magenta
    Write-Host " 4. Backup Profil User" -ForegroundColor Green
    Write-Host " 5. Install Aplikasi Populer (Winget - CTT Style)" -ForegroundColor Yellow
    Write-Host " 6. Windows Debloater (Hapus Bloatware)" -ForegroundColor Yellow
    Write-Host " 7. Buat System Restore Point" -ForegroundColor Yellow
    Write-Host " 8. System Tweaks (Privasi & Performa)" -ForegroundColor Cyan
    Write-Host " 9. One-Click Fixes (Perbaikan Sistem)" -ForegroundColor Cyan
    Write-Host "10. Windows Update Manager" -ForegroundColor Cyan
    Write-Host "11. AUTOMATION PRESETS (Setup Cepat)" -ForegroundColor Magenta
    Write-Host "12. App Backup Manager (Export/Import)" -ForegroundColor Yellow
    Write-Host "13. SMART EVENT ANALYZER (Deteksi & Fix)" -ForegroundColor Red
    Write-Host "14. Startup Manager (Kelola Autostart)" -ForegroundColor Red
    Write-Host "15. DNS Switcher (Percepat Internet)" -ForegroundColor Blue
    Write-Host "16. Keluar" -ForegroundColor Red
    Write-Host "===================================================" -ForegroundColor Cyan
}

do {
    Show-Menu
    $choice = Read-Host "Pilih opsi (1-16)"
    switch ($choice) {
        '1' { Invoke-Maintenance }
        '2' { Invoke-SystemAudit }
        '3' { Invoke-NetworkDiagnostics }
        '4' { Invoke-BackupUserProfile }
        '5' { Invoke-WingetAppInstaller }
        '6' { Invoke-WindowsDebloater }
        '7' { Invoke-CreateRestorePoint }
        '8' { Invoke-SystemTweaks }
        '9' { Invoke-OneClickFixes }
        '10' { Invoke-UpdateManager }
        '11' { Invoke-Presets }
        '12' { Invoke-AppBackup }
        '13' { Invoke-EventLogAnalyzer }
        '14' { Invoke-StartupManager }
        '15' { Invoke-DnsSwitcher }
        '16' { Write-Host "Keluar..." -ForegroundColor Cyan }
        default { Write-Host "[!] Pilihan tidak valid." -ForegroundColor Red; Start-Sleep -Seconds 1 }
    }
} while ($choice -ne '16')
