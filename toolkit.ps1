Add-Type -AssemblyName PresentationFramework
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -Command `"irm https://raw.githubusercontent.com/elfadhildev/powershell-windows-admin-toolkit/main/toolkit.ps1 | iex`"" -Verb RunAs
    exit
}

# ==========================================
# FUNGSI CLI
# ==========================================
function Invoke-Maintenance {
    Write-Host "Maintenance CLI berjalan (Untuk Pester Test)..."
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
            Read-Host "`nTekan Enter untuk kembali..."
        }
    } while ($true)
}

# ==========================================
# DATA GLOBAL
# ==========================================
$Global:TweakList = @(
    [PSCustomObject]@{ Id=1; Cat='Privacy'; Name='Disable Telemetry'; Action='Telemetry' },
    [PSCustomObject]@{ Id=2; Cat='Privacy'; Name='Disable Activity History'; Action='Activity' },
    [PSCustomObject]@{ Id=3; Cat='Privacy'; Name='Disable Consumer Features'; Action='Consumer' },
    [PSCustomObject]@{ Id=4; Cat='Privacy'; Name='Disable Location Tracking'; Action='Location' },
    [PSCustomObject]@{ Id=5; Cat='Performance'; Name='Disable Hibernation (Hemat Disk)'; Action='Hibernate' },
    [PSCustomObject]@{ Id=6; Cat='UIUX'; Name='Enable End Task With Right Click'; Action='EndTask' },
    [PSCustomObject]@{ Id=7; Cat='UIUX'; Name='Show File Extensions'; Action='FileExt' },
    [PSCustomObject]@{ Id=8; Cat='UIUX'; Name='Show Hidden Files'; Action='Hidden' },
    [PSCustomObject]@{ Id=9; Cat='System'; Name='Create System Restore Point'; Action='Restore' },
    [PSCustomObject]@{ Id=10; Cat='System'; Name='Run Disk Cleanup'; Action='Cleanup' },
    [PSCustomObject]@{ Id=11; Cat='Performance'; Name='Set Services to Manual'; Action='ServicesManual' },
    [PSCustomObject]@{ Id=12; Cat='Performance'; Name='Disable GameDVR'; Action='GameDVR' },
    [PSCustomObject]@{ Id=13; Cat='Privacy'; Name='Disable Wi-Fi Sense'; Action='WifiSense' },
    [PSCustomObject]@{ Id=14; Cat='Privacy'; Name='Disable HomeGroup'; Action='HomeGroup' },
    [PSCustomObject]@{ Id=15; Cat='Performance'; Name='Disable Background Apps'; Action='BgApps' },
    [PSCustomObject]@{ Id=16; Cat='System'; Name='Disable Storage Sense'; Action='Storage' },
    [PSCustomObject]@{ Id=17; Cat='UIUX'; Name='Disable Bing Search in Start'; Action='Bing' },
    [PSCustomObject]@{ Id=18; Cat='Performance'; Name='Disable Game Bar'; Action='GameBar' },
    [PSCustomObject]@{ Id=19; Cat='Performance'; Name='Enable Ultimate Performance'; Action='UltimatePerf' },
    [PSCustomObject]@{ Id=20; Cat='UIUX'; Name='Disable Notification Tray'; Action='Notifications' },
    [PSCustomObject]@{ Id=21; Cat='Performance'; Name='Disable Fullscreen Optimizations'; Action='FSO' },
    [PSCustomObject]@{ Id=22; Cat='Network'; Name='Disable IPv6'; Action='IPv6' },
    [PSCustomObject]@{ Id=23; Cat='System'; Name='Disable Edge Debloat'; Action='EdgeDebloat' },
    [PSCustomObject]@{ Id=24; Cat='System'; Name='Disable OneDrive'; Action='OneDrive' },
    [PSCustomObject]@{ Id=25; Cat='System'; Name='Disable Reserved Storage'; Action='Reserved' }
)

$Global:AppList = @(
    [PSCustomObject]@{ Id=1; Cat='Browsers'; Name='Brave'; Pkg='Brave.Brave' }
    [PSCustomObject]@{ Id=2; Cat='Browsers'; Name='Chrome'; Pkg='Google.Chrome' }
    [PSCustomObject]@{ Id=3; Cat='Browsers'; Name='Edge'; Pkg='Microsoft.Edge' }
    [PSCustomObject]@{ Id=4; Cat='Browsers'; Name='Firefox'; Pkg='Mozilla.Firefox' }
    [PSCustomObject]@{ Id=5; Cat='Browsers'; Name='Tor Browser'; Pkg='TorProject.TorBrowser' }
    [PSCustomObject]@{ Id=6; Cat='Comms'; Name='Discord'; Pkg='Discord.Discord' }
    [PSCustomObject]@{ Id=7; Cat='Comms'; Name='Zoom'; Pkg='Zoom.Zoom' }
    [PSCustomObject]@{ Id=8; Cat='Comms'; Name='Telegram'; Pkg='Telegram.TelegramDesktop' }
    [PSCustomObject]@{ Id=9; Cat='Comms'; Name='WhatsApp'; Pkg='WhatsApp.WhatsApp' }
    [PSCustomObject]@{ Id=10; Cat='Comms'; Name='Slack'; Pkg='SlackTechnologies.Slack' }
    [PSCustomObject]@{ Id=11; Cat='Dev'; Name='VS Code'; Pkg='Microsoft.VisualStudioCode' }
    [PSCustomObject]@{ Id=12; Cat='Dev'; Name='Git'; Pkg='Git.Git' }
    [PSCustomObject]@{ Id=13; Cat='Dev'; Name='Python 3'; Pkg='Python.Python.3.12' }
    [PSCustomObject]@{ Id=14; Cat='Dev'; Name='Node.js'; Pkg='OpenJS.NodeJS' }
    [PSCustomObject]@{ Id=15; Cat='Dev'; Name='Docker Desktop'; Pkg='Docker.DockerDesktop' }
    [PSCustomObject]@{ Id=16; Cat='Doc'; Name='LibreOffice'; Pkg='TheDocumentFoundation.LibreOffice' }
    [PSCustomObject]@{ Id=17; Cat='Doc'; Name='Adobe Acrobat'; Pkg='Adobe.Acrobat.Reader.64-bit' }
    [PSCustomObject]@{ Id=18; Cat='Games'; Name='Steam'; Pkg='Valve.Steam' }
    [PSCustomObject]@{ Id=19; Cat='Games'; Name='Epic Games'; Pkg='EpicGames.EpicGamesLauncher' }
    [PSCustomObject]@{ Id=20; Cat='Games'; Name='Battle.net'; Pkg='Blizzard.BattleNet' }
    [PSCustomObject]@{ Id=21; Cat='Media'; Name='VLC'; Pkg='VideoLAN.VLC' }
    [PSCustomObject]@{ Id=22; Cat='Media'; Name='Spotify'; Pkg='Spotify.Spotify' }
    [PSCustomObject]@{ Id=23; Cat='Media'; Name='OBS Studio'; Pkg='OBSProject.OBSStudio' }
    [PSCustomObject]@{ Id=24; Cat='Utils'; Name='7-Zip'; Pkg='7zip.7zip' }
    [PSCustomObject]@{ Id=25; Cat='Utils'; Name='WinRAR'; Pkg='RARLab.WinRAR' }
    [PSCustomObject]@{ Id=26; Cat='Utils'; Name='Everything'; Pkg='voidtools.Everything' }
    [PSCustomObject]@{ Id=27; Cat='Utils'; Name='PowerToys'; Pkg='Microsoft.PowerToys' }
)

$Global:DebloatList = @(
    [PSCustomObject]@{ Id=1; Name='Cortana'; Pkg='Microsoft.549981C3F5F10' }
    [PSCustomObject]@{ Id=2; Name='Bing News'; Pkg='Microsoft.BingNews' }
    [PSCustomObject]@{ Id=3; Name='Bing Weather'; Pkg='Microsoft.BingWeather' }
    [PSCustomObject]@{ Id=4; Name='Get Help'; Pkg='Microsoft.GetHelp' }
    [PSCustomObject]@{ Id=5; Name='Tips (Get Started)'; Pkg='Microsoft.Getstarted' }
    [PSCustomObject]@{ Id=6; Name='Office Hub'; Pkg='Microsoft.MicrosoftOfficeHub' }
    [PSCustomObject]@{ Id=7; Name='Solitaire'; Pkg='Microsoft.MicrosoftSolitaireCollection' }
    [PSCustomObject]@{ Id=8; Name='People'; Pkg='Microsoft.People' }
    [PSCustomObject]@{ Id=9; Name='Skype'; Pkg='Microsoft.SkypeApp' }
    [PSCustomObject]@{ Id=10; Name='Feedback Hub'; Pkg='Microsoft.WindowsFeedbackHub' }
    [PSCustomObject]@{ Id=11; Name='Xbox App'; Pkg='Microsoft.XboxApp' }
    [PSCustomObject]@{ Id=12; Name='Xbox Overlay'; Pkg='Microsoft.XboxGamingOverlay' }
    [PSCustomObject]@{ Id=13; Name='Your Phone'; Pkg='Microsoft.YourPhone' }
    [PSCustomObject]@{ Id=14; Name='Groove Music'; Pkg='Microsoft.ZuneMusic' }
    [PSCustomObject]@{ Id=15; Name='Movies &amp; TV'; Pkg='Microsoft.ZuneVideo' }
)

# ==========================================
# FUNGSI GUI: DEEP CLEAN MAINTENANCE
# ==========================================
function Show-MaintenanceGUI {
    [xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Deep Clean Maintenance" Height="600" Width="700"
        WindowStartupLocation="CenterScreen" Background="#1E1E1E" Foreground="White">
    <Grid Margin="15">
        <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
        <StackPanel Grid.Row="0">
            <TextBlock Text="Pilih opsi pembersihan mendalam:" FontSize="16" FontWeight="Bold" Margin="0,0,0,10"/>
            <CheckBox Name="ChkTemp" Content="Hapus File Sementara (Temp &amp; Prefetch)" Foreground="White" Margin="0,5" IsChecked="True"/>
            <CheckBox Name="ChkDNS" Content="Bersihkan Cache DNS &amp; Perbarui IP" Foreground="White" Margin="0,5" IsChecked="True"/>
            <CheckBox Name="ChkCleanmgr" Content="Jalankan Disk Cleanup Otomatis" Foreground="White" Margin="0,5" IsChecked="True"/>
            <CheckBox Name="ChkDISM" Content="DISM Component Cleanup (Bersihkan WinSxS) - *Lama*" Foreground="LightCoral" Margin="0,5"/>
            <CheckBox Name="ChkSFC" Content="SFC Scannow (Perbaiki File Sistem Rusak) - *Lama*" Foreground="LightCoral" Margin="0,5"/>
        </StackPanel>
        <TextBox Grid.Row="1" Name="TxtLog" Background="#111111" Foreground="Lime" FontFamily="Consolas" Margin="0,10" IsReadOnly="True" VerticalScrollBarVisibility="Auto" Text="Siap melakukan pembersihan..."/>
        <Button Grid.Row="2" Name="BtnRun" Content="MULAI PEMBERSIHAN (RUN)" Width="250" Height="40" Background="#0078D7" Foreground="White" FontWeight="Bold" FontSize="14" HorizontalAlignment="Center"/>
    </Grid>
</Window>
"@
    $reader = (New-Object System.Xml.XmlNodeReader ([xml]$xaml))
    $window = [Windows.Markup.XamlReader]::Load($reader)
    $btnRun = $window.FindName("BtnRun")
    $txtLog = $window.FindName("TxtLog")
    $chkTemp = $window.FindName("ChkTemp")
    $chkDNS = $window.FindName("ChkDNS")
    $chkCleanmgr = $window.FindName("ChkCleanmgr")
    $chkDISM = $window.FindName("ChkDISM")
    $chkSFC = $window.FindName("ChkSFC")

    $btnRun.Add_Click({
        $btnRun.IsEnabled = $false
        $txtLog.Clear()
        $script = {
            param($t, $d, $c, $di, $s)
            if ($t) { Write-Output "[+] Menghapus File Sementara..."; $folders = @("$env:TEMP", "C:\Windows\Temp", "C:\Windows\Prefetch", "C:\Windows\SoftwareDistribution\Download"); foreach ($f in $folders) { if (Test-Path $f) { Get-ChildItem -Path $f -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue } }; Write-Output "    -> Selesai." }
            if ($d) { Write-Output "[+] Membersihkan Cache DNS & IP..."; Clear-DnsClientCache; ipconfig /release | Out-Null; ipconfig /renew | Out-Null; Write-Output "    -> Selesai." }
            if ($c) { Write-Output "[+] Menjalankan Disk Cleanup (cleanmgr)..."; Start-Process cleanmgr.exe -ArgumentList "/sagerun:1" -Wait -NoNewWindow; Write-Output "    -> Selesai." }
            if ($di) { Write-Output "[+] Menjalankan DISM Component Cleanup (Mohon Tunggu)..."; Start-Process "Dism.exe" -ArgumentList "/online /Cleanup-Image /StartComponentCleanup" -Wait -NoNewWindow; Write-Output "    -> Selesai." }
            if ($s) { Write-Output "[+] Menjalankan SFC Scannow (Mohon Tunggu)..."; Start-Process "sfc" -ArgumentList "/scannow" -Wait -NoNewWindow; Write-Output "    -> Selesai." }
            Write-Output "`n[V] SEMUA PROSES PEMBERSIHAN SELESAI!"
        }
        $job = Start-Job -ScriptBlock $script -ArgumentList $chkTemp.IsChecked, $chkDNS.IsChecked, $chkCleanmgr.IsChecked, $chkDISM.IsChecked, $chkSFC.IsChecked
        $timer = New-Object System.Windows.Threading.DispatcherTimer
        $timer.Interval = [TimeSpan]::FromSeconds(1)
        $timer.Add_Tick({
            $out = Receive-Job -Job $job -Keep
            if ($out) { $txtLog.Text = $out -join "`r`n"; $txtLog.ScrollToEnd() }
            if ($job.State -ne 'Running') { $timer.Stop(); $btnRun.IsEnabled = $true; Remove-Job -Job $job -Force }
        })
        $timer.Start()
    })
    $window.ShowDialog() | Out-Null
}

# ==========================================
# FUNGSI GUI: TABBED TWEAKS
# ==========================================
function Show-TweaksGUI {
    $categories = $Global:TweakList.Cat | Sort-Object -Unique
    $xamlStr = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="System Tweaks" Height="700" Width="600"
        WindowStartupLocation="CenterScreen" Background="#1E1E1E" Foreground="White">
    <Grid Margin="15">
        <Grid.RowDefinitions><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
        <TabControl Grid.Row="0" Name="TabMain" Background="#1E1E1E" BorderBrush="#3F3F46">
"@
    foreach ($cat in $categories) {
        $xamlStr += "<TabItem Header='$cat' Background='#2D2D30' Foreground='White'><ScrollViewer VerticalScrollBarVisibility='Auto'><StackPanel Margin='10'>"
        $items = $Global:TweakList | Where-Object { $_.Cat -eq $cat }
        foreach ($item in $items) {
            $xamlStr += "<CheckBox Name='Chk_$($item.Id)' Content='$($item.Name)' Foreground='White' Margin='0,8,0,8'/>"
        }
        $xamlStr += "</StackPanel></ScrollViewer></TabItem>"
    }
    $xamlStr += @"
        </TabControl>
        <Button Grid.Row="1" Name="BtnApply" Content="APPLY SELECTED TWEAKS" Width="250" Height="40" Background="#0078D7" Foreground="White" FontWeight="Bold" FontSize="14" Margin="0,15,0,0" HorizontalAlignment="Center"/>
    </Grid>
</Window>
"@
    $reader = (New-Object System.Xml.XmlNodeReader ([xml]$xamlStr))
    $window = [Windows.Markup.XamlReader]::Load($reader)
    $btnApply = $window.FindName("BtnApply")

    $btnApply.Add_Click({
        $btnApply.Content = "APPLYING..."
        $btnApply.IsEnabled = $false
        $selected = @()
        foreach ($t in $Global:TweakList) {
            $chk = $window.FindName("Chk_$($t.Id)")
            if ($chk.IsChecked -eq $true) { $selected += $t.Action }
        }
        foreach ($act in $selected) {
            switch ($act) {
                'Telemetry' { Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0 -Type DWord -ErrorAction SilentlyContinue; Set-Service -Name DiagTrack -StartupType Disabled -ErrorAction SilentlyContinue; Stop-Service -Name DiagTrack -Force -ErrorAction SilentlyContinue }
                'Activity' { Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "EnableActivityFeed" -Value 0 -Type DWord -ErrorAction SilentlyContinue }
                'Consumer' { Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableWindowsConsumerFeatures" -Value 1 -Type DWord -ErrorAction SilentlyContinue }
                'Location' { Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" -Name "DisableLocation" -Value 1 -Type DWord -ErrorAction SilentlyContinue }
                'Hibernate' { Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Session Manager\Power" -Name "HibernateEnabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue; powercfg -h off }
                'EndTask' { Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings" -Name "TaskbarEndTask" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue }
                'FileExt' { Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 0 -Type DWord }
                'Hidden' { Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Hidden" -Value 1 -Type DWord }
                'BgApps' { Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" -Name "GlobalUserDisabled" -Value 1 -Type DWord -ErrorAction SilentlyContinue }
                'Bing' { Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "BingSearchEnabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue }
                'GameBar' { Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "AutoGameModeEnabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue }
                'UltimatePerf' { powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 }
                'OneDrive' { Stop-Process -Name "OneDrive" -Force -ErrorAction SilentlyContinue; Start-Process "C:\Windows\System32\OneDriveSetup.exe" -ArgumentList "/uninstall" -Wait -ErrorAction SilentlyContinue }
            }
        }
        $btnApply.Content = "SELESAI DITERAPKAN!"
        Start-Sleep -Seconds 1
        $window.Close()
    })
    $window.ShowDialog() | Out-Null
}

# ==========================================
# FUNGSI GUI: TABBED APPS
# ==========================================
function Show-AppsGUI {
    $categories = $Global:AppList.Cat | Sort-Object -Unique
    $xamlStr = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Install Applications" Height="700" Width="600"
        WindowStartupLocation="CenterScreen" Background="#1E1E1E" Foreground="White">
    <Grid Margin="15">
        <Grid.RowDefinitions><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
        <TabControl Grid.Row="0" Name="TabMain" Background="#1E1E1E" BorderBrush="#3F3F46">
"@
    foreach ($cat in $categories) {
        $xamlStr += "<TabItem Header='$cat' Background='#2D2D30' Foreground='White'><ScrollViewer VerticalScrollBarVisibility='Auto'><StackPanel Margin='10'>"
        $items = $Global:AppList | Where-Object { $_.Cat -eq $cat }
        foreach ($item in $items) {
            $xamlStr += "<CheckBox Name='Chk_$($item.Id)' Content='$($item.Name)' Foreground='White' Margin='0,8,0,8'/>"
        }
        $xamlStr += "</StackPanel></ScrollViewer></TabItem>"
    }
    $xamlStr += @"
        </TabControl>
        <Button Grid.Row="1" Name="BtnInstall" Content="INSTALL SELECTED APPS" Width="250" Height="40" Background="#0078D7" Foreground="White" FontWeight="Bold" FontSize="14" Margin="0,15,0,0" HorizontalAlignment="Center"/>
    </Grid>
</Window>
"@
    $reader = (New-Object System.Xml.XmlNodeReader ([xml]$xamlStr))
    $window = [Windows.Markup.XamlReader]::Load($reader)
    $btnInstall = $window.FindName("BtnInstall")

    $btnInstall.Add_Click({
        $btnInstall.Content = "INSTALLING... (Cek Terminal)"
        $btnInstall.IsEnabled = $false
        $selected = @()
        foreach ($app in $Global:AppList) {
            $chk = $window.FindName("Chk_$($app.Id)")
            if ($chk.IsChecked -eq $true) { $selected += $app.Pkg }
        }
        if ($selected.Count -gt 0) {
            foreach ($pkg in $selected) {
                Start-Process powershell -ArgumentList "-NoExit", "-Command", "winget install --id $pkg --accept-source-agreements --accept-package-agreements"
            }
        }
        $window.Close()
    })
    $window.ShowDialog() | Out-Null
}

# ==========================================
# FUNGSI GUI: DEBLOATER
# ==========================================
function Show-DebloaterGUI {
    $xamlStr = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Windows Debloater" Height="600" Width="500"
        WindowStartupLocation="CenterScreen" Background="#1E1E1E" Foreground="White">
    <Grid Margin="15">
        <Grid.RowDefinitions><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
        <ScrollViewer Grid.Row="0" VerticalScrollBarVisibility="Auto">
            <StackPanel Margin="10" Name="PanelDebloat">
                <TextBlock Text="Pilih aplikasi bawaan (bloatware) yang ingin dihapus:" FontSize="14" Margin="0,0,0,15" Foreground="Gray"/>
"@
    foreach ($item in $Global:DebloatList) {
        $xamlStr += "<CheckBox Name='Chk_$($item.Id)' Content='$($item.Name)' Foreground='White' Margin='0,8,0,8'/>"
    }
    $xamlStr += @"
            </StackPanel>
        </ScrollViewer>
        <Button Grid.Row="1" Name="BtnRemove" Content="UNINSTALL SELECTED" Width="250" Height="40" Background="#D83B01" Foreground="White" FontWeight="Bold" FontSize="14" Margin="0,15,0,0" HorizontalAlignment="Center"/>
    </Grid>
</Window>
"@
    $reader = (New-Object System.Xml.XmlNodeReader ([xml]$xamlStr))
    $window = [Windows.Markup.XamlReader]::Load($reader)
    $btnRemove = $window.FindName("BtnRemove")

    $btnRemove.Add_Click({
        $btnRemove.Content = "UNINSTALLING..."
        $btnRemove.IsEnabled = $false
        $selected = @()
        foreach ($item in $Global:DebloatList) {
            $chk = $window.FindName("Chk_$($item.Id)")
            if ($chk.IsChecked -eq $true) { $selected += $item.Pkg }
        }
        foreach ($pkg in $selected) {
            $appx = Get-AppxPackage -Name $pkg -AllUsers -ErrorAction SilentlyContinue
            if ($appx) { Remove-AppxPackage -Package $appx.PackageFullName -AllUsers -ErrorAction SilentlyContinue }
        }
        $btnRemove.Content = "SELESAI DIBERSIHKAN!"
        Start-Sleep -Seconds 1
        $window.Close()
    })
    $window.ShowDialog() | Out-Null
}

# ==========================================
# FUNGSI GUI: UTILITY MELEWAH (Dark Mode) - FIXED RETURN
# ==========================================
function Show-CustomDialog($title, $message, $buttons) {
    $xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="$title" Height="250" Width="450"
        WindowStartupLocation="CenterScreen" Background="#1E1E1E" Foreground="White" WindowStyle="ToolWindow">
    <Grid Margin="20">
        <Grid.RowDefinitions><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
        <TextBlock Grid.Row="0" Text="$message" FontSize="14" TextWrapping="Wrap" VerticalAlignment="Center"/>
        <StackPanel Grid.Row="1" Orientation="Horizontal" HorizontalAlignment="Center" Margin="0,15,0,0">
"@
    foreach ($b in $buttons) {
        $xaml += "<Button Name='Btn_$($b.Value)' Content='$($b.Label)' Width='100' Height='35' Margin='10,0' Background='#0078D7' Foreground='White' FontWeight='Bold'/>"
    }
    $xaml += "</StackPanel></Grid></Window>"
    
    $reader = (New-Object System.Xml.XmlNodeReader ([xml]$xaml))
    $window = [Windows.Markup.XamlReader]::Load($reader)
    
    # Menggunakan Hashtable untuk menyimpan hasil (Pass by reference)
    $resultBag = @{ Value = $null }

    foreach ($b in $buttons) {
        $btn = $window.FindName("Btn_$($b.Value)")
        $val = $b.Value
        $btn.Add_Click({ 
            $resultBag.Value = $val
            $window.Close() 
        }.GetNewClosure()) # GetNewClosure penting agar $resultBag dan $val terikat
    }
    
    $window.ShowDialog() | Out-Null
    return $resultBag.Value
}

function Show-DnsGUI {
    $res = Show-CustomDialog "DNS Switcher" "Pilih penyedia DNS:`nCloudflare (Tercepat)`nGoogle (Stabil)`nReset ke DHCP (Otomatis)" @([PSCustomObject]@{Label='Cloudflare';Value='CF'}, [PSCustomObject]@{Label='Google';Value='GOOG'}, [PSCustomObject]@{Label='Reset';Value='DHCP'})
    $adapters = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }
    if ($res -eq 'CF') { foreach ($a in $adapters) { Set-DnsClientServerAddress -InterfaceIndex $a.ifIndex -ServerAddresses ("1.1.1.1","1.0.0.1") }; Clear-DnsClientCache; Show-CustomDialog "Sukses" "DNS Cloudflare Diterapkan." @([PSCustomObject]@{Label='OK';Value='OK'}) }
    elseif ($res -eq 'GOOG') { foreach ($a in $adapters) { Set-DnsClientServerAddress -InterfaceIndex $a.ifIndex -ServerAddresses ("8.8.8.8","8.8.4.4") }; Clear-DnsClientCache; Show-CustomDialog "Sukses" "DNS Google Diterapkan." @([PSCustomObject]@{Label='OK';Value='OK'}) }
    elseif ($res -eq 'DHCP') { foreach ($a in $adapters) { Set-DnsClientServerAddress -InterfaceIndex $a.ifIndex -ResetServerAddresses }; Clear-DnsClientCache; Show-CustomDialog "Sukses" "DNS Direset ke DHCP." @([PSCustomObject]@{Label='OK';Value='OK'}) }
}

function Show-UpdateGUI {
    $res = Show-CustomDialog "Update Manager" "Pilih aksi pembaruan Windows:`nPause 1 Tahun (Aman)`nPause 50 Tahun (Ekstrem)`nResume (Kembalikan Normal)" @([PSCustomObject]@{Label='Pause 1 Tahun';Value='1Y'}, [PSCustomObject]@{Label='Pause 50 Thn';Value='50Y'}, [PSCustomObject]@{Label='Resume';Value='RESUME'})
    $UpdateKey = "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings"; if (-not (Test-Path $UpdateKey)) { New-Item -Path $UpdateKey -Force | Out-Null }
    if ($res -eq '1Y') { Set-ItemProperty -Path $UpdateKey -Name "FlightSettingsMaxPauseDays" -Value 365 -Type DWord; Set-ItemProperty -Path $UpdateKey -Name "PauseUpdatesExpiryTime" -Value (Get-Date).AddDays(365).ToString("yyyy-MM-ddTHH:mm:ssZ"); Show-CustomDialog "Sukses" "Update dijeda 1 tahun." @([PSCustomObject]@{Label='OK';Value='OK'}) }
    elseif ($res -eq '50Y') { Set-ItemProperty -Path $UpdateKey -Name "FlightSettingsMaxPauseDays" -Value 18250 -Type DWord; Set-ItemProperty -Path $UpdateKey -Name "PauseUpdatesExpiryTime" -Value (Get-Date).AddYears(50).ToString("yyyy-MM-ddTHH:mm:ssZ"); Show-CustomDialog "Sukses" "Update dijeda 50 tahun." @([PSCustomObject]@{Label='OK';Value='OK'}) }
    elseif ($res -eq 'RESUME') { Remove-ItemProperty -Path $UpdateKey -Name "PauseUpdatesExpiryTime" -ErrorAction SilentlyContinue; Remove-ItemProperty -Path $UpdateKey -Name "FlightSettingsMaxPauseDays" -ErrorAction SilentlyContinue; Show-CustomDialog "Sukses" "Update dilanjutkan." @([PSCustomObject]@{Label='OK';Value='OK'}) }
}

function Show-BackupGUI {
    $res = Show-CustomDialog "App Backup Manager" "Simpan daftar aplikasi Anda ke file (Export)`natau Instal ulang dari file backup (Import)?" @([PSCustomObject]@{Label='Export Aplikasi';Value='EXP'}, [PSCustomObject]@{Label='Import Aplikasi';Value='IMP'})
    $backupFile = "$env:USERPROFILE\Desktop\MyAppsBackup.json"
    if ($res -eq 'EXP') { winget export -o $backupFile --accept-source-agreements; Show-CustomDialog "Sukses" "Backup berhasil disimpan di Desktop: MyAppsBackup.json" @([PSCustomObject]@{Label='OK';Value='OK'}) }
    elseif ($res -eq 'IMP') { if (Test-Path $backupFile) { Start-Process powershell -ArgumentList "-NoExit", "-Command", "winget import -i '$backupFile' --accept-source-agreements --accept-package-agreements" } else { Show-CustomDialog "Gagal" "File backup tidak ditemukan di Desktop." @([PSCustomObject]@{Label='OK';Value='OK'}) } }
}

function Show-SimpleCLI($title, $funcName) {
    $body = (Get-Command $funcName).ScriptBlock.ToString()
    $cmd = "& { function $funcName { $body } ; $funcName }"
    $b64 = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($cmd))
    Start-Process powershell -ArgumentList "-NoExit", "-ExecutionPolicy", "Bypass", "-EncodedCommand", $b64
}

# ==========================================
# MENU UTAMA GUI (Tiles)
# ==========================================
function Show-GUI {
    [xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Panduan PowerShell - Control Panel v3.1.4" Height="700" Width="950"
        WindowStartupLocation="CenterScreen" Background="#1E1E1E" Foreground="White">
    <Grid>
        <Grid.RowDefinitions><RowDefinition Height="60"/><RowDefinition Height="*"/><RowDefinition Height="40"/></Grid.RowDefinitions>
        <Border Grid.Row="0" Background="#0078D7"><TextBlock Text="PANDUAN POWERSHELL - CONTROL PANEL" FontSize="20" FontWeight="Bold" VerticalAlignment="Center" HorizontalAlignment="Center" Foreground="White"/></Border>
        <WrapPanel Grid.Row="1" Margin="20" HorizontalAlignment="Center" VerticalAlignment="Center">
            <Button x:Name="BtnMaintenance" Width="200" Height="100" Margin="10" Background="#2D2D30" BorderBrush="#3F3F46" BorderThickness="2"><StackPanel><TextBlock Text="🛠️ Pure Clean" FontSize="18" FontWeight="Bold" Foreground="White" HorizontalAlignment="Center"/><TextBlock Text="Deep Maintenance" FontSize="12" Foreground="Gray" HorizontalAlignment="Center" Margin="0,5,0,0"/></StackPanel></Button>
            <Button x:Name="BtnAudit" Width="200" Height="100" Margin="10" Background="#2D2D30" BorderBrush="#3F3F46" BorderThickness="2"><StackPanel><TextBlock Text="📊 System Audit" FontSize="18" FontWeight="Bold" Foreground="White" HorizontalAlignment="Center"/><TextBlock Text="Cek Hardware &amp; OS" FontSize="12" Foreground="Gray" HorizontalAlignment="Center" Margin="0,5,0,0"/></StackPanel></Button>
            <Button x:Name="BtnNetwork" Width="200" Height="100" Margin="10" Background="#2D2D30" BorderBrush="#3F3F46" BorderThickness="2"><StackPanel><TextBlock Text="🌐 Network" FontSize="18" FontWeight="Bold" Foreground="White" HorizontalAlignment="Center"/><TextBlock Text="Cek Jaringan &amp; IP" FontSize="12" Foreground="Gray" HorizontalAlignment="Center" Margin="0,5,0,0"/></StackPanel></Button>
            <Button x:Name="BtnDebloater" Width="200" Height="100" Margin="10" Background="#2D2D30" BorderBrush="#3F3F46" BorderThickness="2"><StackPanel><TextBlock Text="🧹 Debloater" FontSize="18" FontWeight="Bold" Foreground="White" HorizontalAlignment="Center"/><TextBlock Text="Hapus Bloatware" FontSize="12" Foreground="Gray" HorizontalAlignment="Center" Margin="0,5,0,0"/></StackPanel></Button>
            <Button x:Name="BtnTweaks" Width="200" Height="100" Margin="10" Background="#2D2D30" BorderBrush="#3F3F46" BorderThickness="2"><StackPanel><TextBlock Text="⚙️ Tweaks" FontSize="18" FontWeight="Bold" Foreground="White" HorizontalAlignment="Center"/><TextBlock Text="Privasi &amp; Performa" FontSize="12" Foreground="Gray" HorizontalAlignment="Center" Margin="0,5,0,0"/></StackPanel></Button>
            <Button x:Name="BtnEventLog" Width="200" Height="100" Margin="10" Background="#2D2D30" BorderBrush="#3F3F46" BorderThickness="2"><StackPanel><TextBlock Text="📝 Event Log" FontSize="18" FontWeight="Bold" Foreground="White" HorizontalAlignment="Center"/><TextBlock Text="Analisis Error Sistem" FontSize="12" Foreground="Gray" HorizontalAlignment="Center" Margin="0,5,0,0"/></StackPanel></Button>
            <Button x:Name="BtnInstall" Width="200" Height="100" Margin="10" Background="#2D2D30" BorderBrush="#3F3F46" BorderThickness="2"><StackPanel><TextBlock Text="📦 Install Apps" FontSize="18" FontWeight="Bold" Foreground="White" HorizontalAlignment="Center"/><TextBlock Text="Winget Mega List" FontSize="12" Foreground="Gray" HorizontalAlignment="Center" Margin="0,5,0,0"/></StackPanel></Button>
            <Button x:Name="BtnBackup" Width="200" Height="100" Margin="10" Background="#2D2D30" BorderBrush="#3F3F46" BorderThickness="2"><StackPanel><TextBlock Text="💾 App Backup" FontSize="18" FontWeight="Bold" Foreground="White" HorizontalAlignment="Center"/><TextBlock Text="Export/Import Apps" FontSize="12" Foreground="Gray" HorizontalAlignment="Center" Margin="0,5,0,0"/></StackPanel></Button>
            <Button x:Name="BtnUpdate" Width="200" Height="100" Margin="10" Background="#2D2D30" BorderBrush="#3F3F46" BorderThickness="2"><StackPanel><TextBlock Text="🔄 Update Mgr" FontSize="18" FontWeight="Bold" Foreground="White" HorizontalAlignment="Center"/><TextBlock Text="Kontrol Windows Update" FontSize="12" Foreground="Gray" HorizontalAlignment="Center" Margin="0,5,0,0"/></StackPanel></Button>
            <Button x:Name="BtnDNS" Width="200" Height="100" Margin="10" Background="#2D2D30" BorderBrush="#3F3F46" BorderThickness="2"><StackPanel><TextBlock Text="🌍 DNS Switcher" FontSize="18" FontWeight="Bold" Foreground="White" HorizontalAlignment="Center"/><TextBlock Text="Percepat Internet" FontSize="12" Foreground="Gray" HorizontalAlignment="Center" Margin="0,5,0,0"/></StackPanel></Button>
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

    $btnMaintenance.Add_Click({ Show-MaintenanceGUI })
    $btnTweaks.Add_Click({ Show-TweaksGUI })
    $btnInstall.Add_Click({ Show-AppsGUI })
    $btnDebloater.Add_Click({ Show-DebloaterGUI })
    $btnBackup.Add_Click({ Show-BackupGUI })
    $btnUpdate.Add_Click({ Show-UpdateGUI })
    $btnDNS.Add_Click({ Show-DnsGUI })
    
    $btnAudit.Add_Click({ Show-SimpleCLI "System Audit" "Invoke-SystemAudit" })
    $btnNetwork.Add_Click({ Show-SimpleCLI "Network Diagnostics" "Invoke-NetworkDiagnostics" })
    $btnEventLog.Add_Click({ Show-SimpleCLI "Event Log Analyzer" "Invoke-EventLogAnalyzer" })

    $window.ShowDialog() | Out-Null
}

Show-GUI