Add-Type -AssemblyName PresentationFramework
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
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
# FUNGSI EKSEKUSI
# ==========================================
function Invoke-Maintenance {
    Clear-Host; Write-Host "========== MAINTENANCE PC ==========" -ForegroundColor Cyan
    Write-Host "[+] Membersihkan Cache DNS..." -ForegroundColor Yellow
    Clear-DnsClientCache; ipconfig /release | Out-Null; ipconfig /renew | Out-Null
    Write-Host "[+] Membersihkan File Sementara..." -ForegroundColor Yellow
    $TempFolders = @("$env:TEMP", "C:\Windows\Temp", "C:\Windows\Prefetch", "C:\Windows\SoftwareDistribution\Download")
    foreach ($Folder in $TempFolders) { if (Test-Path $Folder) { Get-ChildItem -Path $Folder -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue } }
    Start-Process cleanmgr.exe -ArgumentList "/sagerun:1" -NoNewWindow -Wait
    $DriveType = (Get-PhysicalDisk | Where-Object { $_.DeviceID -eq (Get-Partition -DriveLetter C).DiskNumber }).MediaType
    if ($DriveType -eq "SSD") { Optimize-Volume -DriveLetter C -ReTrim | Out-Null } else { Optimize-Volume -DriveLetter C -Defrag | Out-Null }
    Write-Host " -> Optimasi selesai." -ForegroundColor Green
    Read-Host "`nTekan Enter untuk kembali..."
}

function Invoke-SystemAudit {
    Clear-Host; Write-Host "========== SISTEM AUDIT ==========" -ForegroundColor Cyan
    $os = Get-CimInstance Win32_OperatingSystem; $cpu = Get-CimInstance Win32_Processor; $ram = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)
    Write-Host " OS: $($os.Caption) | CPU: $($cpu.Name) | RAM: $ram GB"
    $lic = Get-CimInstance SoftwareLicensingProduct | Where-Object { $_.PartialProductKey }
    if ($lic.LicenseStatus -eq 1) { Write-Host " Lisensi: Windows Teraktivasi" -ForegroundColor Green } else { Write-Host " Lisensi: Belum Teraktivasi" -ForegroundColor Red }
    Write-Host "`n[+] Storage:" -ForegroundColor Yellow
    Get-PhysicalDisk | Select-Object DeviceId, FriendlyName, MediaType, HealthStatus, @{N='Size(GB)';E={[math]::Round($_.Size/1GB,2)}} | Format-Table -AutoSize
    $badDrivers = Get-PnpDevice -PresentOnly | Where-Object { $_.Status -ne "OK" }
    if ($badDrivers) { Write-Host "[+] Driver Bermasalah:" -ForegroundColor Yellow; $badDrivers | Select-Object Class, FriendlyName, Status | Format-Table -AutoSize } else { Write-Host " -> Semua driver OK." -ForegroundColor Green }
    Read-Host "`nTekan Enter untuk kembali..."
}

function Invoke-NetworkDiagnostics {
    Clear-Host; Write-Host "========== DIAGNOSTIK JARINGAN ==========" -ForegroundColor Cyan
    Get-NetIPConfiguration | Where-Object { $_.IPv4Address } | Select-Object InterfaceAlias, IPv4Address, @{N='Gateway';E={$_.IPv4DefaultGateway.NextHop}}, @{N='DNS';E={$_.DNSServer.ServerAddresses -join ', '}} | Format-List
    Write-Host "[+] Koneksi Aktif (Established):" -ForegroundColor Yellow
    Get-NetTCPConnection -State Established | ForEach-Object { $Process = Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue; [PSCustomObject]@{ LocalPort=$_.LocalPort; RemoteAddr=$_.RemoteAddress; RemotePort=$_.RemotePort; Process=if($Process){$Process.ProcessName}else{'<unknown>'}; PID=$_.OwningProcess } } | Sort-Object Process | Format-Table -AutoSize
    Read-Host "`nTekan Enter untuk kembali..."
}

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

function Invoke-SystemTweaks {
    Clear-Host; Write-Host "========== SYSTEM TWEAKS ==========" -ForegroundColor Cyan
    Backup-RegistryTweaks
    $tweaks = @(
        [PSCustomObject]@{ Id=1; Cat='Essential'; Name='Disable Telemetry'; Action='Telemetry' },
        [PSCustomObject]@{ Id=2; Cat='Essential'; Name='Disable Activity History'; Action='Activity' },
        [PSCustomObject]@{ Id=3; Cat='Essential'; Name='Disable Consumer Features'; Action='Consumer' },
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
        [PSCustomObject]@{ Id=19; Cat='Advanced'; Name='Enable Ultimate Performance'; Action='UltimatePerf' },
        [PSCustomObject]@{ Id=20; Cat='Advanced'; Name='Disable Notification Tray'; Action='Notifications' },
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
                'Telemetry' { Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0 -Type DWord -ErrorAction SilentlyContinue; Set-Service -Name DiagTrack -StartupType Disabled -ErrorAction SilentlyContinue; Stop-Service -Name DiagTrack -Force -ErrorAction SilentlyContinue }
                'Activity' { Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "EnableActivityFeed" -Value 0 -Type DWord -ErrorAction SilentlyContinue }
                'Consumer' { Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableWindowsConsumerFeatures" -Value 1 -Type DWord -ErrorAction SilentlyContinue }
                'Location' { Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" -Name "DisableLocation" -Value 1 -Type DWord -ErrorAction SilentlyContinue; Set-Service -Name lfsvc -StartupType Disabled -ErrorAction SilentlyContinue }
                'Hibernate' { Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Session Manager\Power" -Name "HibernateEnabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue; powercfg -h off }
                'EndTask' { Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings" -Name "TaskbarEndTask" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue }
                'FileExt' { Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 0 -Type DWord }
                'Hidden' { Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Hidden" -Value 1 -Type DWord }
                'Restore' { if ((Get-ComputerRestorePoint).Count -eq $null) { Enable-ComputerRestore -Drive "C:\" }; Checkpoint-Computer -Description "Auto Restore" -RestorePointType "MODIFY_SETTINGS" }
                'Cleanup' { Start-Process cleanmgr.exe -ArgumentList "/sagerun:1" -NoNewWindow -Wait }
                'ServicesManual' { $services = @("DiagTrack", "dmwappushservice", "MapsBroker", "RetailDemo", "WSearch"); foreach ($svc in $services) { Set-Service -Name $svc -StartupType Manual -ErrorAction SilentlyContinue } }
                'GameDVR' { Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue }
                'WifiSense' { Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WcmSvc\wifinetworkmanager\config" -Name "AutoConnectAllowedOEM" -Value 0 -Type DWord -ErrorAction SilentlyContinue }
                'HomeGroup' { Set-Service -Name HomeGroupListener -StartupType Manual -ErrorAction SilentlyContinue; Set-Service -Name HomeGroupProvider -StartupType Manual -ErrorAction SilentlyContinue }
                'BgApps' { Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" -Name "GlobalUserDisabled" -Value 1 -Type DWord -ErrorAction SilentlyContinue }
                'Storage' { Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" -Name "01" -Value 0 -Type DWord -ErrorAction SilentlyContinue }
                'Bing' { Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "BingSearchEnabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue }
                'GameBar' { Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "AutoGameModeEnabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue }
                'UltimatePerf' { powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 }
                'Notifications' { Set-ItemProperty -Path "HKCU:\Software\Policies\Microsoft\Windows\Explorer" -Name "DisableNotificationCenter" -Value 1 -Type DWord -ErrorAction SilentlyContinue; Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\PushNotifications" -Name "ToastEnabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue }
                'FSO' { Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_FSEBehaviorMode" -Value 2 -Type DWord -ErrorAction SilentlyContinue; Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_HonorUserFSEBehaviorMode" -Value 1 -Type DWord -ErrorAction SilentlyContinue }
                'IPv6' { Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\TCPIP6\Parameters" -Name "DisabledComponents" -Value 0xFF -Type DWord -ErrorAction SilentlyContinue }
                'EdgeDebloat' { Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "EdgeShoppingAssistantEnabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue; Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "ShowRecommendationsEnabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue }
                'OneDrive' { Stop-Process -Name "OneDrive" -Force -ErrorAction SilentlyContinue; Start-Process "C:\Windows\System32\OneDriveSetup.exe" -ArgumentList "/uninstall" -Wait -ErrorAction SilentlyContinue }
                'Reserved' { Set-WindowsReservedStorageState -State Disabled -ErrorAction SilentlyContinue }
                'UTC' { Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\TimeZoneInformation" -Name "RealTimeIsUniversal" -Value 1 -Type DWord -ErrorAction SilentlyContinue }
                'AdobeBlock' { Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown" -Name "bEnableAcrobatDocumentCloud" -Value 0 -Type DWord -ErrorAction SilentlyContinue }
            }
            Write-Host "    Berhasil." -ForegroundColor Green
        }
    }
    Read-Host "`nTekan Enter untuk kembali..."
}

function Invoke-EventLogAnalyzer {
    do {
        Clear-Host; Write-Host "========== SMART EVENT LOG ANALYZER ==========" -ForegroundColor Cyan
        Write-Host "[+] Memindai Event Log (7 Hari Terakhir)..." -ForegroundColor Yellow
        $events = Get-WinEvent -FilterHashtable @{LogName='System','Application'; Level=1,2; StartTime=(Get-Date).AddDays(-7)} -ErrorAction SilentlyContinue
        
        if (-not $events) { Write-Host "`n[+] Luar biasa! Tidak ada Error/Critical." -ForegroundColor Green; Read-Host "`nTekan Enter..."; return }
        $summary = $events | Group-Object ProviderName | Sort-Object Count -Descending | Select-Object -First 10
        Write-Host "`n[!] Ditemukan $($events.Count) error. Berikut Top 10 Penyebab:" -ForegroundColor Red
        $i = 0; $summary | ForEach-Object { $i++; Write-Host "[$i] $($_.Name) ($($_.Count) kali)" -ForegroundColor Gray }
        
        Write-Host "===================================================" -ForegroundColor Cyan
        Write-Host "Ketik nomor untuk melihat detail, atau 'x' kembali." -ForegroundColor Yellow
        $choice = Read-Host "Pilih"
        if ($choice -eq 'x' -or $choice -eq '') { return }

        $selectedItem = $summary[$choice - 1]
        if ($selectedItem) {
            $provider = $selectedItem.Name
            Clear-Host; Write-Host "========== DETAIL ERROR: $provider ==========" -ForegroundColor Cyan
            $details = $events | Where-Object { $_.ProviderName -eq $provider } | Select-Object -First 3
            foreach ($d in $details) { Write-Host "Waktu  : $($d.TimeCreated)" -ForegroundColor DarkGray; Write-Host "ID     : $($d.Id)"; Write-Host "Pesan  : $($d.Message -replace "`r`n", ' ')" -ForegroundColor White; Write-Host "---------------------------------------------------" }
            Write-Host "`n[💡] SARAN PERBAIKAN:" -ForegroundColor Yellow
            $fixAction = $null
            switch -Wildcard ($provider) {
                "*DistributedCOM*" { Write-Host "Error 10016 SANGAT UMUM dan biasanya aman diabaikan." -ForegroundColor Green }
                "*Service Control Manager*" { Write-Host "Service gagal berjalan. Disarankan: Repair System (SFC)." -ForegroundColor Red; $fixAction = "SFC" }
                "*VSS*" { Write-Host "VSS gagal buat Restore Point. Disarankan: Repair System (SFC)." -ForegroundColor Red; $fixAction = "SFC" }
                "*CAPI2*" { Write-Host "CAPI2 gagal validasi update. Disarankan: Reset Update Cache." -ForegroundColor Red; $fixAction = "Update" }
                Default { Write-Host "Error spesifik tidak diketahui. Abaikan jika PC normal." -ForegroundColor Gray }
            }
            Write-Host "`n===================================================" -ForegroundColor Cyan
            if ($fixAction -eq "SFC") {
                Write-Host "1. Jalankan Repair System (SFC & DISM) sekarang`n2. Kembali"
                $action = Read-Host "`nPilih (1-2)"
                if ($action -eq '1') { Start-Process cmd -ArgumentList "/c sfc /scannow" -Wait -NoNewWindow; Start-Process cmd -ArgumentList "/c DISM /Online /Cleanup-Image /RestoreHealth" -Wait -NoNewWindow }
            } elseif ($fixAction -eq "Update") {
                Write-Host "1. Reset Update Cache sekarang`n2. Kembali"
                $action = Read-Host "`nPilih (1-2)"
                if ($action -eq '1') { Stop-Service -Name wuauserv, cryptSvc, bits, msiserver -Force -ErrorAction SilentlyContinue; Remove-Item -Path "C:\Windows\SoftwareDistribution\*" -Recurse -Force -ErrorAction SilentlyContinue; Start-Service -Name wuauserv, cryptSvc, bits, msiserver -ErrorAction SilentlyContinue }
            } else { Read-Host "`nTekan Enter untuk kembali..." }
        }
    } while ($true)
}

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
        if ($catChoice -eq '0' -or $catChoice -eq '') { return }
        
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
    Read-Host "`nTekan Enter untuk kembali..."
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
    Read-Host "`nTekan Enter untuk kembali..."
}

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

function Invoke-Presets {
    Clear-Host; Write-Host "========== AUTOMATION PRESETS ==========" -ForegroundColor Cyan
    Write-Host "1. Standard Setup`n2. Gamer Setup`n3. Developer Setup`n4. Minimalist Setup`n5. Kembali" -ForegroundColor Green
    $choice = Read-Host "`nPilih Preset (1-5)"
    if ($choice -eq '5' -or $choice -eq '') { return }
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

function Show-GUI {
    [xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Panduan PowerShell - Control Panel v2.2.0" Height="700" Width="950"
        WindowStartupLocation="CenterScreen" Background="#1E1E1E" Foreground="White">
    <Grid>
        <Grid.RowDefinitions><RowDefinition Height="60"/><RowDefinition Height="*"/><RowDefinition Height="40"/></Grid.RowDefinitions>
        <Border Grid.Row="0" Background="#0078D7"><TextBlock Text="PANDUAN POWERSHELL - CONTROL PANEL" FontSize="20" FontWeight="Bold" VerticalAlignment="Center" HorizontalAlignment="Center" Foreground="White"/></Border>
        <WrapPanel Grid.Row="1" Margin="20" HorizontalAlignment="Center" VerticalAlignment="Center">
            <Button x:Name="BtnMaintenance" Width="200" Height="100" Margin="10" Background="#2D2D30" BorderBrush="#3F3F46" BorderThickness="2"><StackPanel><TextBlock Text="🛠️ Maintenance" FontSize="18" FontWeight="Bold" Foreground="White" HorizontalAlignment="Center"/><TextBlock Text="Bersihkan &amp; Optimasi" FontSize="12" Foreground="Gray" HorizontalAlignment="Center" Margin="0,5,0,0"/></StackPanel></Button>
            <Button x:Name="BtnAudit" Width="200" Height="100" Margin="10" Background="#2D2D30" BorderBrush="#3F3F46" BorderThickness="2"><StackPanel><TextBlock Text="📊 System Audit" FontSize="18" FontWeight="Bold" Foreground="White" HorizontalAlignment="Center"/><TextBlock Text="Cek Hardware &amp; OS" FontSize="12" Foreground="Gray" HorizontalAlignment="Center" Margin="0,5,0,0"/></StackPanel></Button>
            <Button x:Name="BtnNetwork" Width="200" Height="100" Margin="10" Background="#2D2D30" BorderBrush="#3F3F46" BorderThickness="2"><StackPanel><TextBlock Text="🌐 Network" FontSize="18" FontWeight="Bold" Foreground="White" HorizontalAlignment="Center"/><TextBlock Text="Cek Jaringan &amp; IP" FontSize="12" Foreground="Gray" HorizontalAlignment="Center" Margin="0,5,0,0"/></StackPanel></Button>
            <Button x:Name="BtnDebloater" Width="200" Height="100" Margin="10" Background="#2D2D30" BorderBrush="#3F3F46" BorderThickness="2"><StackPanel><TextBlock Text="🧹 Debloater" FontSize="18" FontWeight="Bold" Foreground="White" HorizontalAlignment="Center"/><TextBlock Text="Hapus Bloatware" FontSize="12" Foreground="Gray" HorizontalAlignment="Center" Margin="0,5,0,0"/></StackPanel></Button>
            <Button x:Name="BtnTweaks" Width="200" Height="100" Margin="10" Background="#2D2D30" BorderBrush="#3F3F46" BorderThickness="2"><StackPanel><TextBlock Text="⚙️ Tweaks" FontSize="18" FontWeight="Bold" Foreground="White" HorizontalAlignment="Center"/><TextBlock Text="Privasi &amp; Performa" FontSize="12" Foreground="Gray" HorizontalAlignment="Center" Margin="0,5,0,0"/></StackPanel></Button>
            <Button x:Name="BtnEventLog" Width="200" Height="100" Margin="10" Background="#2D2D30" BorderBrush="#3F3F46" BorderThickness="2"><StackPanel><TextBlock Text="📝 Event Log" FontSize="18" FontWeight="Bold" Foreground="White" HorizontalAlignment="Center"/><TextBlock Text="Analisis Error Sistem" FontSize="12" Foreground="Gray" HorizontalAlignment="Center" Margin="0,5,0,0"/></StackPanel></Button>
            <Button x:Name="BtnInstall" Width="200" Height="100" Margin="10" Background="#2D2D30" BorderBrush="#3F3F46" BorderThickness="2"><StackPanel><TextBlock Text="📦 Install Apps" FontSize="18" FontWeight="Bold" Foreground="White" HorizontalAlignment="Center"/><TextBlock Text="Winget Mega List" FontSize="12" Foreground="Gray" HorizontalAlignment="Center" Margin="0,5,0,0"/></StackPanel></Button>
            <Button x:Name="BtnBackup" Width="200" Height="100" Margin="10" Background="#2D2D30" BorderBrush="#3F3F46" BorderThickness="2"><StackPanel><TextBlock Text="💾 App Backup" FontSize="18" FontWeight="Bold" Foreground="White" HorizontalAlignment="Center"/><TextBlock Text="Export/Import Apps" FontSize="12" Foreground="Gray" HorizontalAlignment="Center" Margin="0,5,0,0"/></StackPanel></Button>
            <Button x:Name="BtnUpdate" Width="200" Height="100" Margin="10" Background="#2D2D30" BorderBrush="#3F3F46" BorderThickness="2"><StackPanel><TextBlock Text="🔄 Update Mgr" FontSize="18" FontWeight="Bold" Foreground="White" HorizontalAlignment="Center"/><TextBlock Text="Kontrol Windows Update" FontSize="12" Foreground="Gray" HorizontalAlignment="Center" Margin="0,5,0,0"/></StackPanel></Button>
            <Button x:Name="BtnDNS" Width="200" Height="100" Margin="10" Background="#2D2D30" BorderBrush="#3F3F46" BorderThickness="2"><StackPanel><TextBlock Text="🌍 DNS Switcher" FontSize="18" FontWeight="Bold" Foreground="White" HorizontalAlignment="Center"/><TextBlock Text="Percepat Internet" FontSize="12" Foreground="Gray" HorizontalAlignment="Center" Margin="0,5,0,0"/></StackPanel></Button>
            <Button x:Name="BtnPresets" Width="200" Height="100" Margin="10" Background="#2D2D30" BorderBrush="#3F3F46" BorderThickness="2"><StackPanel><TextBlock Text="⚡ Presets" FontSize="18" FontWeight="Bold" Foreground="White" HorizontalAlignment="Center"/><TextBlock Text="Setup Cepat" FontSize="12" Foreground="Gray" HorizontalAlignment="Center" Margin="0,5,0,0"/></StackPanel></Button>
        </WrapPanel>
        <Border Grid.Row="2" Background="#2D2D30"><TextBlock x:Name="TxtStatus" Text="Ready." FontSize="12" VerticalAlignment="Center" HorizontalAlignment="Center" Foreground="Gray"/></Border>
    </Grid>
</Window>
"@

    $reader = (New-Object System.Xml.XmlNodeReader $xaml)
    $window = [Windows.Markup.XamlReader]::Load($reader)

    $btnMaintenance = $window.FindName("BtnMaintenance")
    $btnAudit = $window.FindName("BtnAudit")
    $btnNetwork = $window.FindName("BtnNetwork")
    $btnDebloater = $window.FindName("BtnDebloater")
    $btnTweaks = $window.FindName("BtnTweaks")
    $btnEventLog = $window.FindName("BtnEventLog")
    $btnInstall = $window.FindName("BtnInstall")
    $btnBackup = $window.FindName("BtnBackup")
    $btnUpdate = $window.FindName("BtnUpdate")
    $btnDNS = $window.FindName("BtnDNS")
    $btnPresets = $window.FindName("BtnPresets")
    $txtStatus = $window.FindName("TxtStatus")

    function Start-FunctionWindow($funcName, $isAdmin = $false) {
        $s = (Get-Command $funcName).ScriptBlock.ToString()
        $b64 = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes("& { $s ; $funcName }"))
        $args = @("-ExecutionPolicy", "Bypass", "-EncodedCommand", $b64)
        if ($isAdmin) { Start-Process powershell -ArgumentList $args -Verb RunAs } else { Start-Process powershell -ArgumentList $args }
    }

    $btnMaintenance.Add_Click({ $txtStatus.Text = "Menjalankan Maintenance..."; Start-FunctionWindow "Invoke-Maintenance" $true })
    $btnAudit.Add_Click({ $txtStatus.Text = "Menjalankan System Audit..."; Start-FunctionWindow "Invoke-SystemAudit" $false })
    $btnNetwork.Add_Click({ $txtStatus.Text = "Menjalankan Network Diagnostics..."; Start-FunctionWindow "Invoke-NetworkDiagnostics" $false })
    $btnDebloater.Add_Click({ $txtStatus.Text = "Menjalankan Debloater..."; Start-FunctionWindow "Invoke-WindowsDebloater" $true })
    $btnTweaks.Add_Click({ $txtStatus.Text = "Menjalankan System Tweaks..."; 
        $s1 = (Get-Command Backup-RegistryTweaks).ScriptBlock.ToString()
        $s2 = (Get-Command Invoke-SystemTweaks).ScriptBlock.ToString()
        $b64 = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes("& { $s1 ; $s2 ; Invoke-SystemTweaks }"))
        Start-Process powershell -ArgumentList "-ExecutionPolicy", "Bypass", "-EncodedCommand", $b64 -Verb RunAs 
    })
    $btnEventLog.Add_Click({ $txtStatus.Text = "Menjalankan Event Log Analyzer..."; Start-FunctionWindow "Invoke-EventLogAnalyzer" $false })
    $btnInstall.Add_Click({ $txtStatus.Text = "Menjalankan App Installer..."; Start-FunctionWindow "Invoke-WingetAppInstaller" $false })
    $btnBackup.Add_Click({ $txtStatus.Text = "Menjalankan App Backup..."; Start-FunctionWindow "Invoke-AppBackup" $false })
    $btnUpdate.Add_Click({ $txtStatus.Text = "Menjalankan Update Manager..."; Start-FunctionWindow "Invoke-UpdateManager" $true })
    $btnDNS.Add_Click({ $txtStatus.Text = "Menjalankan DNS Switcher..."; Start-FunctionWindow "Invoke-DnsSwitcher" $true })
    $btnPresets.Add_Click({ $txtStatus.Text = "Menjalankan Presets..."; 
        $s1 = (Get-Command Backup-RegistryTweaks).ScriptBlock.ToString()
        $s2 = (Get-Command Invoke-Presets).ScriptBlock.ToString()
        $b64 = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes("& { $s1 ; $s2 ; Invoke-Presets }"))
        Start-Process powershell -ArgumentList "-ExecutionPolicy", "Bypass", "-EncodedCommand", $b64 -Verb RunAs 
    })

    $window.ShowDialog() | Out-Null
}

Show-GUI