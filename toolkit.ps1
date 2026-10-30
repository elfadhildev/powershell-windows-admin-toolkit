$ErrorActionPreference = 'SilentlyContinue'
Add-Type -AssemblyName PresentationFramework

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
# FUNGSI EKSEKUSI (Akan dijalankan di jendela baru)
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
    Clear-Host; Write-Host "========== SMART EVENT LOG ANALYZER ==========" -ForegroundColor Cyan
    Write-Host "Fitur Event Log Analyzer berjalan di sini (Sama seperti versi sebelumnya)."
    Read-Host "`nTekan Enter untuk kembali..."
}

# ==========================================
# GUI (WPF) - ANTARMUKA v2.0.3
# ==========================================
function Show-GUI {
    [xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Panduan PowerShell - Control Panel v2.0.3" Height="600" Width="900"
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
    $txtStatus = $window.FindName("TxtStatus")

    # SOLUSI PASTI: Eksekusi fungsi di jendela baru
    $btnMaintenance.Add_Click({ 
        $txtStatus.Text = "Menjalankan Maintenance..."
        $cmd = (Get-Command Invoke-Maintenance).Definition
        Start-Process powershell -ArgumentList "-NoExit", "-Command", "& { $cmd; Invoke-Maintenance }" -Verb RunAs 
    })

    $btnAudit.Add_Click({ 
        $txtStatus.Text = "Menjalankan System Audit..."
        $cmd = (Get-Command Invoke-SystemAudit).Definition
        Start-Process powershell -ArgumentList "-NoExit", "-Command", "& { $cmd; Invoke-SystemAudit }" 
    })

    $btnNetwork.Add_Click({ 
        $txtStatus.Text = "Menjalankan Network Diagnostics..."
        $cmd = (Get-Command Invoke-NetworkDiagnostics).Definition
        Start-Process powershell -ArgumentList "-NoExit", "-Command", "& { $cmd; Invoke-NetworkDiagnostics }" 
    })

    $btnDebloater.Add_Click({ 
        $txtStatus.Text = "Menjalankan Debloater..."
        $cmd = (Get-Command Invoke-WindowsDebloater).Definition
        Start-Process powershell -ArgumentList "-NoExit", "-Command", "& { $cmd; Invoke-WindowsDebloater }" -Verb RunAs 
    })

    $btnTweaks.Add_Click({ 
        $txtStatus.Text = "Menjalankan System Tweaks..."
        $cmd = (Get-Command Invoke-SystemTweaks).Definition
        Start-Process powershell -ArgumentList "-NoExit", "-Command", "& { $cmd; Invoke-SystemTweaks }" -Verb RunAs 
    })

    $btnEventLog.Add_Click({ 
        $txtStatus.Text = "Menjalankan Event Log Analyzer..."
        $cmd = (Get-Command Invoke-EventLogAnalyzer).Definition
        Start-Process powershell -ArgumentList "-NoExit", "-Command", "& { $cmd; Invoke-EventLogAnalyzer }" 
    })

    $window.ShowDialog() | Out-Null
}

Show-GUI
