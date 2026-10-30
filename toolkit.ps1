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
    Write-Host "[2/3] Membersihkan File Sementara..." -ForegroundColor Yellow
    $TempFolders = @("$env:TEMP", "C:\Windows\Temp", "C:\Windows\Prefetch", "C:\Windows\SoftwareDistribution\Download")
    foreach ($Folder in $TempFolders) { if (Test-Path $Folder) { Get-ChildItem -Path $Folder -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue } }
    Start-Process cleanmgr.exe -ArgumentList "/sagerun:1" -NoNewWindow -Wait
    Write-Host "[3/3] Optimasi Drive C..." -ForegroundColor Yellow
    $DriveType = (Get-PhysicalDisk | Where-Object { $_.DeviceID -eq (Get-Partition -DriveLetter C).DiskNumber }).MediaType
    if ($DriveType -eq "SSD") { Optimize-Volume -DriveLetter C -ReTrim | Out-Null } else { Optimize-Volume -DriveLetter C -Defrag | Out-Null }
    Write-Host " -> Optimasi selesai." -ForegroundColor Green
    Read-Host "`nTekan Enter untuk kembali ke menu..."
}

function Invoke-SystemAudit {
    Clear-Host; Write-Host "========== SISTEM AUDIT ==========" -ForegroundColor Cyan
    $os = Get-CimInstance Win32_OperatingSystem; $cpu = Get-CimInstance Win32_Processor; $ram = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)
    $report = "OS: $($os.Caption) | CPU: $($cpu.Name) | RAM: $ram GB`n"
    Write-Host " OS: $($os.Caption) | CPU: $($cpu.Name) | RAM: $ram GB"
    $lic = Get-CimInstance SoftwareLicensingProduct | Where-Object { $_.PartialProductKey }
    if ($lic.LicenseStatus -eq 1) { $report += "Lisensi: Windows Teraktivasi`n"; Write-Host " Lisensi: Windows Teraktivasi" -ForegroundColor Green } else { $report += "Lisensi: Belum Teraktivasi`n"; Write-Host " Lisensi: Belum Teraktivasi" -ForegroundColor Red }
    Write-Host "`n[+] Storage:" -ForegroundColor Yellow
    $disks = Get-PhysicalDisk | Select-Object DeviceId, FriendlyName, MediaType, HealthStatus, @{N='Size(GB)';E={[math]::Round($_.Size/1GB,2)}}
    $disks | Format-Table -AutoSize
    $report += "`n[Storage]`n" + ($disks | Out-String)
    Write-Host "[+] Driver Bermasalah:" -ForegroundColor Yellow
    $badDrivers = Get-PnpDevice -PresentOnly | Where-Object { $_.Status -ne "OK" }
    if ($badDrivers) { $badDrivers | Select-Object Class, FriendlyName, Status | Format-Table -AutoSize; $report += "`n[Driver]`n" + ($badDrivers | Out-String) } else { Write-Host " -> Semua driver OK." -ForegroundColor Green; $report += "`n[Driver] Semua OK.`n" }
    $save = Read-Host "`nSimpan laporan ke Desktop? (y/n)"
    if ($save -eq 'y') { $file = "$env:USERPROFILE\Desktop\System_Audit_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"; $report | Out-File -FilePath $file -Encoding UTF8; Write-Host "[+] Laporan disimpan di: $file" -ForegroundColor Green }
    Read-Host "`nTekan Enter untuk kembali ke menu..."
}

function Invoke-NetworkDiagnostics {
    $ErrorActionPreference = 'SilentlyContinue'; Clear-Host
    Write-Host "========== DIAGNOSTIK JARINGAN ==========" -ForegroundColor Cyan
    Write-Host "`n[+] Konfigurasi IP & DNS:" -ForegroundColor Yellow
    Get-NetIPConfiguration | Where-Object { $_.IPv4Address } | Select-Object InterfaceAlias, IPv4Address, @{N='Gateway';E={$_.IPv4DefaultGateway.NextHop}}, @{N='DNS';E={$_.DNSServer.ServerAddresses -join ', '}} | Format-List
    Write-Host "[+] Koneksi Aktif (Established):" -ForegroundColor Yellow
    Get-NetTCPConnection -State Established | ForEach-Object { $Process = Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue; [PSCustomObject]@{ LocalPort=$_.LocalPort; RemoteAddr=$_.RemoteAddress; RemotePort=$_.RemotePort; Process=if($Process){$Process.ProcessName}else{'<unknown>'}; PID=$_.OwningProcess } } | Sort-Object Process | Format-Table -AutoSize
    Read-Host "`nTekan Enter untuk kembali ke menu..."
}

function Invoke-BackupUserProfile {
    Clear-Host; Write-Host "========== BACKUP PROFIL USER ==========" -ForegroundColor Cyan
    $DestinationFolder = Join-Path -Path 'D:\Backup_PC' -ChildPath "Backup_$(Get-Date -Format 'yyyy-MM-dd')"
    $FoldersToBackup = @('Documents', 'Pictures', 'Desktop', 'Downloads', 'Music', 'Videos', 'AppData\Roaming', 'AppData\Local\Packages')
    $ExcludeFolders = @('Cache', 'Temp', 'CrashDumps', 'GPUCache', 'Microsoft\Windows\INetCache')
    if (-not (Test-Path $DestinationFolder)) { New-Item -Path $DestinationFolder -ItemType Directory -Force | Out-Null }
    $LogFile = Join-Path -Path $DestinationFolder -ChildPath 'Backup_Log.txt'
    foreach ($Folder in $FoldersToBackup) { $SourcePath = Join-Path -Path $env:USERPROFILE -ChildPath $Folder; $TargetPath = Join-Path -Path $DestinationFolder -ChildPath $Folder; if (Test-Path $SourcePath) { robocopy $SourcePath $TargetPath /MIR /R:1 /W:1 /XD $ExcludeFolders /LOG+:$LogFile /NP /NJH /NJS } }
    Write-Host "`n[+] PROSES BACKUP SELESAI! Log: $LogFile" -ForegroundColor Green; Read-Host "`nTekan Enter untuk kembali..."
}

# ==========================================
# 5. WINGET APP INSTALLER
# ==========================================
function Invoke-WingetAppInstaller {
    $apps = @(
        [PSCustomObject]@{ Cat='Browsers'; Name='Brave'; Id='Brave.Brave' },
        [PSCustomObject]@{ Cat='Browsers'; Name='Chrome'; Id='Google.Chrome' },
        [PSCustomObject]@{ Cat='Browsers'; Name='Edge'; Id='Microsoft.Edge' },
        [PSCustomObject]@{ Cat='Browsers'; Name='Firefox'; Id='Mozilla.Firefox' },
        [PSCustomObject]@{ Cat='Browsers'; Name='Tor Browser'; Id='TorProject.TorBrowser' },
        [PSCustomObject]@{ Cat='Browsers'; Name='Vivaldi'; Id='Vivaldi.Vivaldi' },
        [PSCustomObject]@{ Cat='Communications'; Name='Discord'; Id='Discord.Discord' },
        [PSCustomObject]@{ Cat='Communications'; Name='Zoom'; Id='Zoom.Zoom' },
        [PSCustomObject]@{ Cat='Communications'; Name='Telegram'; Id='Telegram.TelegramDesktop' },
        [PSCustomObject]@{ Cat='Communications'; Name='WhatsApp'; Id='WhatsApp.WhatsApp' },
        [PSCustomObject]@{ Cat='Development'; Name='VS Code'; Id='Microsoft.VisualStudioCode' },
        [PSCustomObject]@{ Cat='Development'; Name='Git'; Id='Git.Git' },
        [PSCustomObject]@{ Cat='Development'; Name='Python 3'; Id='Python.Python.3.12' },
        [PSCustomObject]@{ Cat='Development'; Name='Node.js'; Id='OpenJS.NodeJS' },
        [PSCustomObject]@{ Cat='Document'; Name='LibreOffice'; Id='TheDocumentFoundation.LibreOffice' },
        [PSCustomObject]@{ Cat='Document'; Name='ONLYOFFICE'; Id='ONLYOFFICE.DesktopEditors' },
        [PSCustomObject]@{ Cat='Document'; Name='Adobe Acrobat Reader'; Id='Adobe.Acrobat.Reader.64-bit' },
        [PSCustomObject]@{ Cat='Games'; Name='Steam'; Id='Valve.Steam' },
        [PSCustomObject]@{ Cat='Games'; Name='Epic Games'; Id='EpicGames.EpicGamesLauncher' },
        [PSCustomObject]@{ Cat='Microsoft'; Name='PowerToys'; Id='Microsoft.PowerToys' },
        [PSCustomObject]@{ Cat='Microsoft'; Name='Windows Terminal'; Id='Microsoft.WindowsTerminal' },
        [PSCustomObject]@{ Cat='Multimedia'; Name='VLC'; Id='VideoLAN.VLC' },
        [PSCustomObject]@{ Cat='Multimedia'; Name='Spotify'; Id='Spotify.Spotify' },
        [PSCustomObject]@{ Cat='Multimedia'; Name='OBS Studio'; Id='OBSProject.OBSStudio' },
        [PSCustomObject]@{ Cat='Pro Tools'; Name='Wireshark'; Id='WiresharkFoundation.Wireshark' },
        [PSCustomObject]@{ Cat='Pro Tools'; Name='Nmap'; Id='Insecure.Nmap' },
        [PSCustomObject]@{ Cat='Utilities'; Name='7-Zip'; Id='7zip.7zip' },
        [PSCustomObject]@{ Cat='Utilities'; Name='WinRAR'; Id='RARLab.WinRAR' },
        [PSCustomObject]@{ Cat='Utilities'; Name='Everything'; Id='voidtools.Everything' },
        [PSCustomObject]@{ Cat='Utilities'; Name='Rufus'; Id='Rufus.Rufus' }
    )

    $categories = $apps.Cat | Sort-Object -Unique

    do {
        Clear-Host
        Write-Host "========== WINGET APP INSTALLER ==========" -ForegroundColor Cyan
        Write-Host "Pilih Kategori Aplikasi:" -ForegroundColor Yellow
        for ($i = 0; $i -lt $categories.Count; $i++) { Write-Host " $($i + 1). $($categories[$i])" }
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
            for ($j = 0; $j -lt $filteredApps.Count; $j++) { Write-Host " $($j + 1). $($filteredApps[$j].Name)" }
            Write-Host " 0. Batal"
            
            $appChoice = Read-Host "`nMasukkan nomor aplikasi"
            if ($appChoice -ne '0' -and $appChoice -ne '') {
                $selectedIndices = $appChoice -split ',' | ForEach-Object { $_.Trim() }
                foreach ($idx in $selectedIndices) {
                    $appIndex = [int]$idx - 1
                    if ($appIndex -ge 0 -and $appIndex -lt $filteredApps.Count) {
                        $appId = $filteredApps[$appIndex].Id; $appName = $filteredApps[$appIndex].Name
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
# 6-7. DEBLOATER & RESTORE
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
# 8. SYSTEM TWEAKS (CTT MEGA UPDATE)
# ==========================================
function Invoke-SystemTweaks {
    Clear-Host
    Write-Host "========== SYSTEM TWEAKS (CTT MEGA UPDATE) ==========" -ForegroundColor Cyan
    Backup-RegistryTweaks

    $tweaks = @(
        [PSCustomObject]@{ Id=1; Cat='Essential'; Name='Disable Telemetry'; Action='Telemetry' },
        [PSCustomObject]@{ Id=2; Cat='Essential'; Name='Disable Activity History'; Action='Activity' },
        [PSCustomObject]@{ Id=3; Cat='Essential'; Name='Disable Consumer Features (Tips/Suggestions)'; Action='Consumer' },
        [PSCustomObject]@{ Id=4; Cat='Essential'; Name='Disable Location Tracking'; Action='Location' },
        [PSCustomObject]@{ Id=5; Cat='Essential'; Name='Disable Hibernation (Hemat Disk)'; Action='Hibernate' },
        [PSCustomObject]@{ Id=6; Cat='Essential'; Name='Enable End Task With Right Click'; Action='EndTask' },
        [PSCustomObject]@{ Id=7; Cat='Essential'; Name='Show File Extensions'; Action='FileExt' },
        [PSCustomObject]@{ Id=8; Cat='Essential'; Name='Show Hidden Files'; Action='Hidden' },
        [PSCustomObject]@{ Id=9; Cat='Essential'; Name='Create System Restore Point'; Action='Restore' },
        [PSCustomObject]@{ Id=10; Cat='Essential'; Name='Run Disk Cleanup'; Action='Cleanup' },
        [PSCustomObject]@{ Id=11; Cat='Essential'; Name='Set Services to Manual'; Action='ServicesManual' },
        [PSCustomObject]@{ Id=12; Cat='Essential'; Name='Disable GameDVR'; Action='GameDVR' },
        [PSCustomObject]@{ Id=13; Cat='Essential'; Name='Disable Wi-Fi Sense'; Action='WifiSense' },
        [PSCustomObject]@{ Id=14; Cat='Essential'; Name='Disable HomeGroup'; Action='HomeGroup' },

        [PSCustomObject]@{ Id=15; Cat='Advanced'; Name='Disable Background Apps'; Action='BgApps' },
        [PSCustomObject]@{ Id=16; Cat='Advanced'; Name='Disable Storage Sense'; Action='Storage' },
        [PSCustomObject]@{ Id=17; Cat='Advanced'; Name='Disable Bing Search in Start Menu'; Action='Bing' },
        [PSCustomObject]@{ Id=18; Cat='Advanced'; Name='Disable Game Bar'; Action='GameBar' },
        [PSCustomObject]@{ Id=19; Cat='Advanced'; Name='Enable Ultimate Performance Power Plan'; Action='UltimatePerf' },
        [PSCustomObject]@{ Id=20; Cat='Advanced'; Name='Disable Notification Tray/Calendar'; Action='Notifications' },
        [PSCustomObject]@{ Id=21; Cat='Advanced'; Name='Disable Fullscreen Optimizations'; Action='FSO' },
        [PSCustomObject]@{ Id=22; Cat='Advanced'; Name='Disable IPv6'; Action='IPv6' },
        [PSCustomObject]@{ Id=23; Cat='Advanced'; Name='Disable Microsoft Edge Debloat'; Action='EdgeDebloat' },
        [PSCustomObject]@{ Id=24; Cat='Advanced'; Name='Disable OneDrive'; Action='OneDrive' },
        [PSCustomObject]@{ Id=25; Cat='Advanced'; Name='Disable Reserved Storage'; Action='Reserved' },
        [PSCustomObject]@{ Id=26; Cat='Advanced'; Name='Set Time to UTC'; Action='UTC' },
        [PSCustomObject]@{ Id=27; Cat='Advanced'; Name='Enable Adobe URL Block List'; Action='AdobeBlock' }
    )

    $essential = $tweaks | Where-Object { $_.Cat -eq 'Essential' }
    $advanced = $tweaks | Where-Object { $_.Cat -eq 'Advanced' }

    Write-Host "`n[ Essential Tweaks ]" -ForegroundColor Green
    foreach ($t in $essential) { Write-Host " $($t.Id). $($t.Name)" }

    Write-Host "`n[ Advanced Tweaks - CAUTION ]" -ForegroundColor Red
    foreach ($t in $advanced) { Write-Host " $($t.Id). $($t.Name)" }

    Write-Host "`n===================================================" -ForegroundColor Cyan
    Write-Host "Pilih nomor tweak (pisahkan dengan koma, misal: 1,5,15), atau 'x' batal." -ForegroundColor Yellow
    $inputTweaks = Read-Host "Pilihan Anda"

    if ($inputTweaks -eq 'x' -or $inputTweaks -eq '') { return }

    $selected = $inputTweaks -split ',' | ForEach-Object { $_.Trim() }

    foreach ($num in $selected) {
        $t = $tweaks | Where-Object { $_.Id -eq $num }
        if ($t) {
            Write-Host " -> Menerapkan: $($t.Name)..." -ForegroundColor Yellow
            switch ($t.Action) {
                'Telemetry' { 
                    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0 -Type DWord -ErrorAction SilentlyContinue
                    Set-Service -Name DiagTrack -StartupType Disabled -ErrorAction SilentlyContinue
                    Stop-Service -Name DiagTrack -Force -ErrorAction SilentlyContinue
                }
                'Activity' { 
                    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "EnableActivityFeed" -Value 0 -Type DWord -ErrorAction SilentlyContinue
                    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "PublishUserActivities" -Value 0 -Type DWord -ErrorAction SilentlyContinue
                    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "UploadUserActivities" -Value 0 -Type DWord -ErrorAction SilentlyContinue
                }
                'Consumer' { Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableWindowsConsumerFeatures" -Value 1 -Type DWord -ErrorAction SilentlyContinue }
                'Location' { 
                    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" -Name "DisableLocation" -Value 1 -Type DWord -ErrorAction SilentlyContinue
                    Set-Service -Name lfsvc -StartupType Disabled -ErrorAction SilentlyContinue
                }
                'Hibernate' { 
                    Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Session Manager\Power" -Name "HibernateEnabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue
                    powercfg -h off 
                }
                'EndTask' { Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings" -Name "TaskbarEndTask" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue }
                'FileExt' { Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 0 -Type DWord }
                'Hidden' { Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Hidden" -Value 1 -Type DWord }
                'Restore' { Invoke-CreateRestorePoint }
                'Cleanup' { Start-Process cleanmgr.exe -ArgumentList "/sagerun:1" -NoNewWindow -Wait }
                'ServicesManual' {
                    $services = @("DiagTrack", "dmwappushservice", "MapsBroker", "RetailDemo", "WSearch")
                    foreach ($svc in $services) { Set-Service -Name $svc -StartupType Manual -ErrorAction SilentlyContinue }
                }
                'GameDVR' { Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue }
                'WifiSense' { Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WcmSvc\wifinetworkmanager\config" -Name "AutoConnectAllowedOEM" -Value 0 -Type DWord -ErrorAction SilentlyContinue }
                'HomeGroup' { Set-Service -Name HomeGroupListener -StartupType Manual -ErrorAction SilentlyContinue; Set-Service -Name HomeGroupProvider -StartupType Manual -ErrorAction SilentlyContinue }
                
                'BgApps' { Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" -Name "GlobalUserDisabled" -Value 1 -Type DWord -ErrorAction SilentlyContinue }
                'Storage' { Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" -Name "01" -Value 0 -Type DWord -ErrorAction SilentlyContinue }
                'Bing' { Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "BingSearchEnabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue }
                'GameBar' { Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "AutoGameModeEnabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue }
                'UltimatePerf' { powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 }
                'Notifications' { 
                    Set-ItemProperty -Path "HKCU:\Software\Policies\Microsoft\Windows\Explorer" -Name "DisableNotificationCenter" -Value 1 -Type DWord -ErrorAction SilentlyContinue
                    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\PushNotifications" -Name "ToastEnabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue
                }
                'FSO' { 
                    Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_FSEBehaviorMode" -Value 2 -Type DWord -ErrorAction SilentlyContinue
                    Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_HonorUserFSEBehaviorMode" -Value 1 -Type DWord -ErrorAction SilentlyContinue
                }
                'IPv6' { Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\TCPIP6\Parameters" -Name "DisabledComponents" -Value 0xFF -Type DWord -ErrorAction SilentlyContinue }
                'EdgeDebloat' { 
                    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "EdgeShoppingAssistantEnabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue
                    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "ShowRecommendationsEnabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue
                }
                'OneDrive' { 
                    Stop-Process -Name "OneDrive" -Force -ErrorAction SilentlyContinue
                    Start-Process "C:\Windows\System32\OneDriveSetup.exe" -ArgumentList "/uninstall" -Wait -ErrorAction SilentlyContinue
                }
                'Reserved' { Set-WindowsReservedStorageState -State Disabled -ErrorAction SilentlyContinue }
                'UTC' { Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\TimeZoneInformation" -Name "RealTimeIsUniversal" -Value 1 -Type DWord -ErrorAction SilentlyContinue }
                'AdobeBlock' { 
                    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown" -Name "bEnableAcrobatDocumentCloud" -Value 0 -Type DWord -ErrorAction SilentlyContinue
                }
            }
            Write-Host "    Berhasil." -ForegroundColor Green
        }
    }

    Write-Host "`n[+] Selesai menerapkan tweaks. Beberapa perubahan mungkin butuh restart." -ForegroundColor Cyan
    Read-Host "Tekan Enter untuk kembali ke menu..."
}

# ==========================================
# 9-10. FIXES & UPDATES
# ==========================================
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
# 11-12. PRESETS & APP BACKUP
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
        
        if (-not $events) { Write-Host "`n[+] Luar biasa! Tidak ada Error/Critical di log sistem minggu ini." -ForegroundColor Green; Read-Host "`nTekan Enter untuk kembali..."; return }

        $summary = $events | Group-Object ProviderName | Sort-Object Count -Descending | Select-Object -First 10
        Write-Host "`n[!] Ditemukan $($events.Count) error. Berikut Top 10 Penyebab:" -ForegroundColor Red
        
        $i = 0
        $summary | ForEach-Object { $i++; Write-Host "[$i] $($_.Name) ($($_.Count) kali)" -ForegroundColor Gray }
        
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

        if ($startupItems.Count -eq 0) { Write-Host " -> Tidak ada item startup yang terdeteksi." -ForegroundColor Yellow; Read-Host "`nTekan Enter untuk kembali..."; return }

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
                    try { Remove-ItemProperty -Path $selectedItem.Location -Name $selectedItem.Name -ErrorAction Stop; Write-Host "`n[+] Berhasil menghapus '$($selectedItem.Name)' dari startup." -ForegroundColor Green } 
                    catch { Write-Host "`n[!] Gagal menghapus. Anda mungkin butuh hak Admin." -ForegroundColor Red }
                    Read-Host "`nTekan Enter..."
                }
                '2' {
                    $exePath = $selectedItem.Command
                    if ($exePath -match '^"([^"]+)"') { $exePath = $matches[1] } elseif ($exePath -match '^(\S+\.exe)') { $exePath = $matches[1] }
                    if (Test-Path $exePath) {
                        $sig = Get-AuthenticodeSignature -FilePath $exePath
                        Write-Host "`n[+] Status Signature: $($sig.Status)" -ForegroundColor $(if ($sig.Status -eq 'Valid') { 'Green' } else { 'Red' })
                        if ($sig.SignerCertificate) { Write-Host "    Publisher: $($sig.SignerCertificate.Subject)" -ForegroundColor Gray } else { Write-Host "    Publisher: Tidak ada signature (Tidak Dikenal)" -ForegroundColor Red }
                    } else { Write-Host "`n[!] File .exe tidak ditemukan." -ForegroundColor Red }
                    Read-Host "`nTekan Enter..."
                }
                '3' {
                    $exePath = $selectedItem.Command
                    if ($exePath -match '^"([^"]+)"') { $exePath = $matches[1] } elseif ($exePath -match '^(\S+\.exe)') { $exePath = $matches[1] }
                    if (Test-Path $exePath) { Start-Process explorer.exe -ArgumentList "/select,`"$exePath`"" } else { Write-Host "`n[!] File tidak ditemukan." -ForegroundColor Red; Read-Host "Tekan Enter..." }
                }
                '4' { }
            }
        } else { Write-Host "`n[!] Nomor tidak valid." -ForegroundColor Red; Start-Sleep -Seconds 1 }
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
    if (-not $adapters) { Write-Host "`n[!] Tidak ada koneksi internet aktif." -ForegroundColor Red; Read-Host "Tekan Enter..."; return }
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
# MENU UTAMA (v1.10.1)
# ==========================================
function Show-Menu {
    Clear-Host
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host "      PANDUAN POWERSHELL - CONTROL PANEL v1.10.1     " -ForegroundColor Cyan
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host " 1. Maintenance PC (Bersihkan & Optimasi)" -ForegroundColor Green
    Write-Host " 2. System Audit (Cek Hardware & OS)" -ForegroundColor Magenta
    Write-Host " 3. Network Diagnostics (Cek Jaringan)" -ForegroundColor Magenta
    Write-Host " 4. Backup Profil User" -ForegroundColor Green
    Write-Host " 5. Install Aplikasi Populer (Winget - MEGA LIST)" -ForegroundColor Yellow
    Write-Host " 6. Windows Debloater (Hapus Bloatware)" -ForegroundColor Yellow
    Write-Host " 7. Buat System Restore Point" -ForegroundColor Yellow
    Write-Host " 8. System Tweaks (CTT STYLE - Mega List)" -ForegroundColor Cyan
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
