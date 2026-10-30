Add-Type -AssemblyName PresentationFramework
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -Command `"irm https://raw.githubusercontent.com/elfadhildev/powershell-windows-admin-toolkit/main/toolkit.ps1 | iex`"" -Verb RunAs
    exit
}

# ==========================================
# DATA GLOBAL (Daftar Tweak & Aplikasi)
# ==========================================
$Global:TweakList = @(
    [PSCustomObject]@{ Id=1; Name='Disable Telemetry'; Action='Telemetry' },
    [PSCustomObject]@{ Id=2; Name='Disable Activity History'; Action='Activity' },
    [PSCustomObject]@{ Id=3; Name='Disable Consumer Features'; Action='Consumer' },
    [PSCustomObject]@{ Id=4; Name='Disable Location Tracking'; Action='Location' },
    [PSCustomObject]@{ Id=5; Name='Disable Hibernation (Hemat Disk)'; Action='Hibernate' },
    [PSCustomObject]@{ Id=6; Name='Enable End Task With Right Click'; Action='EndTask' },
    [PSCustomObject]@{ Id=7; Name='Show File Extensions'; Action='FileExt' },
    [PSCustomObject]@{ Id=8; Name='Show Hidden Files'; Action='Hidden' },
    [PSCustomObject]@{ Id=9; Name='Create System Restore Point'; Action='Restore' },
    [PSCustomObject]@{ Id=10; Name='Run Disk Cleanup'; Action='Cleanup' },
    [PSCustomObject]@{ Id=11; Name='Set Services to Manual'; Action='ServicesManual' },
    [PSCustomObject]@{ Id=12; Name='Disable GameDVR'; Action='GameDVR' },
    [PSCustomObject]@{ Id=13; Name='Disable Wi-Fi Sense'; Action='WifiSense' },
    [PSCustomObject]@{ Id=14; Name='Disable HomeGroup'; Action='HomeGroup' },
    [PSCustomObject]@{ Id=15; Name='Disable Background Apps'; Action='BgApps' },
    [PSCustomObject]@{ Id=16; Name='Disable Storage Sense'; Action='Storage' },
    [PSCustomObject]@{ Id=17; Name='Disable Bing Search in Start'; Action='Bing' },
    [PSCustomObject]@{ Id=18; Name='Disable Game Bar'; Action='GameBar' },
    [PSCustomObject]@{ Id=19; Name='Enable Ultimate Performance'; Action='UltimatePerf' },
    [PSCustomObject]@{ Id=20; Name='Disable Notification Tray'; Action='Notifications' },
    [PSCustomObject]@{ Id=21; Name='Disable Fullscreen Optimizations'; Action='FSO' },
    [PSCustomObject]@{ Id=22; Name='Disable IPv6'; Action='IPv6' },
    [PSCustomObject]@{ Id=23; Name='Disable Edge Debloat'; Action='EdgeDebloat' },
    [PSCustomObject]@{ Id=24; Name='Disable OneDrive'; Action='OneDrive' },
    [PSCustomObject]@{ Id=25; Name='Disable Reserved Storage'; Action='Reserved' },
    [PSCustomObject]@{ Id=26; Name='Set Time to UTC'; Action='UTC' },
    [PSCustomObject]@{ Id=27; Name='Enable Adobe URL Block List'; Action='AdobeBlock' }
)

$Global:AppList = @(
    [PSCustomObject]@{ Id=1; Name='Brave'; Pkg='Brave.Brave' }, [PSCustomObject]@{ Id=2; Name='Chrome'; Pkg='Google.Chrome' },
    [PSCustomObject]@{ Id=3; Name='Chromium'; Pkg='Hibbiki.Chromium' }, [PSCustomObject]@{ Id=4; Name='Edge'; Pkg='Microsoft.Edge' },
    [PSCustomObject]@{ Id=5; Name='Firefox'; Pkg='Mozilla.Firefox' }, [PSCustomObject]@{ Id=6; Name='Tor Browser'; Pkg='TorProject.TorBrowser' },
    [PSCustomObject]@{ Id=7; Name='Vivaldi'; Pkg='Vivaldi.Vivaldi' }, [PSCustomObject]@{ Id=8; Name='Discord'; Pkg='Discord.Discord' },
    [PSCustomObject]@{ Id=9; Name='Zoom'; Pkg='Zoom.Zoom' }, [PSCustomObject]@{ Id=10; Name='Telegram'; Pkg='Telegram.TelegramDesktop' },
    [PSCustomObject]@{ Id=11; Name='WhatsApp'; Pkg='WhatsApp.WhatsApp' }, [PSCustomObject]@{ Id=12; Name='Slack'; Pkg='SlackTechnologies.Slack' },
    [PSCustomObject]@{ Id=13; Name='Teams'; Pkg='Microsoft.Teams' }, [PSCustomObject]@{ Id=14; Name='Signal'; Pkg='OpenWhisperSystems.Signal' },
    [PSCustomObject]@{ Id=15; Name='VS Code'; Pkg='Microsoft.VisualStudioCode' }, [PSCustomObject]@{ Id=16; Name='Git'; Pkg='Git.Git' },
    [PSCustomObject]@{ Id=17; Name='Python 3'; Pkg='Python.Python.3.12' }, [PSCustomObject]@{ Id=18; Name='Node.js'; Pkg='OpenJS.NodeJS' },
    [PSCustomObject]@{ Id=19; Name='Docker Desktop'; Pkg='Docker.DockerDesktop' }, [PSCustomObject]@{ Id=20; Name='Postman'; Pkg='Postman.Postman' },
    [PSCustomObject]@{ Id=21; Name='GitHub Desktop'; Pkg='GitHub.GitHubDesktop' }, [PSCustomObject]@{ Id=22; Name='Neovim'; Pkg='Neovim.Neovim' },
    [PSCustomObject]@{ Id=23; Name='LibreOffice'; Pkg='TheDocumentFoundation.LibreOffice' }, [PSCustomObject]@{ Id=24; Name='ONLYOFFICE'; Pkg='ONLYOFFICE.DesktopEditors' },
    [PSCustomObject]@{ Id=25; Name='Adobe Acrobat'; Pkg='Adobe.Acrobat.Reader.64-bit' }, [PSCustomObject]@{ Id=26; Name='Sumatra PDF'; Pkg='SumatraPDF.SumatraPDF' },
    [PSCustomObject]@{ Id=27; Name='Steam'; Pkg='Valve.Steam' }, [PSCustomObject]@{ Id=28; Name='Epic Games'; Pkg='EpicGames.EpicGamesLauncher' },
    [PSCustomObject]@{ Id=29; Name='Battle.net'; Pkg='Blizzard.BattleNet' }, [PSCustomObject]@{ Id=30; Name='PowerToys'; Pkg='Microsoft.PowerToys' },
    [PSCustomObject]@{ Id=31; Name='VLC'; Pkg='VideoLAN.VLC' }, [PSCustomObject]@{ Id=32; Name='Spotify'; Pkg='Spotify.Spotify' },
    [PSCustomObject]@{ Id=33; Name='OBS Studio'; Pkg='OBSProject.OBSStudio' }, [PSCustomObject]@{ Id=34; Name='GIMP'; Pkg='GIMP.GIMP' },
    [PSCustomObject]@{ Id=35; Name='Wireshark'; Pkg='WiresharkFoundation.Wireshark' }, [PSCustomObject]@{ Id=36; Name='Nmap'; Pkg='Insecure.Nmap' },
    [PSCustomObject]@{ Id=37; Name='7-Zip'; Pkg='7zip.7zip' }, [PSCustomObject]@{ Id=38; Name='WinRAR'; Pkg='RARLab.WinRAR' },
    [PSCustomObject]@{ Id=39; Name='Everything'; Pkg='voidtools.Everything' }, [PSCustomObject]@{ Id=40; Name='Rufus'; Pkg='Rufus.Rufus' }
)

# ==========================================
# FUNGSI GUI: DEEP CLEAN MAINTENANCE (PURE CLEAN)
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
        <Button Grid.Row="2" Name="BtnRun" Content="MULAI PEMBERSIHAN (RUN)" Width="200" Height="40" Background="#0078D7" Foreground="White" FontWeight="Bold" FontSize="14"/>
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
        
        # ScriptBlock yang akan dijalankan di background
        $script = {
            param($t, $d, $c, $di, $s)
            if ($t) {
                Write-Output "[+] Menghapus File Sementara..."
                $folders = @("$env:TEMP", "C:\Windows\Temp", "C:\Windows\Prefetch", "C:\Windows\SoftwareDistribution\Download")
                foreach ($f in $folders) { if (Test-Path $f) { Get-ChildItem -Path $f -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue } }
                Write-Output "    -> Selesai."
            }
            if ($d) {
                Write-Output "[+] Membersihkan Cache DNS & IP..."
                Clear-DnsClientCache; ipconfig /release | Out-Null; ipconfig /renew | Out-Null
                Write-Output "    -> Selesai."
            }
            if ($c) {
                Write-Output "[+] Menjalankan Disk Cleanup (cleanmgr)..."
                Start-Process cleanmgr.exe -ArgumentList "/sagerun:1" -Wait -NoNewWindow
                Write-Output "    -> Selesai."
            }
            if ($di) {
                Write-Output "[+] Menjalankan DISM Component Cleanup (Mohon Tunggu)..."
                Start-Process "Dism.exe" -ArgumentList "/online /Cleanup-Image /StartComponentCleanup" -Wait -NoNewWindow
                Write-Output "    -> Selesai."
            }
            if ($s) {
                Write-Output "[+] Menjalankan SFC Scannow (Mohon Tunggu)..."
                Start-Process "sfc" -ArgumentList "/scannow" -Wait -NoNewWindow
                Write-Output "    -> Selesai."
            }
            Write-Output "`n[V] SEMUA PROSES PEMBERSIHAN SELESAI!"
        }

        $job = Start-Job -ScriptBlock $script -ArgumentList $chkTemp.IsChecked, $chkDNS.IsChecked, $chkCleanmgr.IsChecked, $chkDISM.IsChecked, $chkSFC.IsChecked

        # Timer untuk update UI tanpa freeze
        $timer = New-Object System.Windows.Threading.DispatcherTimer
        $timer.Interval = [TimeSpan]::FromSeconds(1)
        $timer.Add_Tick({
            $out = Receive-Job -Job $job -Keep
            if ($out) { $txtLog.Text = $out -join "`r`n"; $txtLog.ScrollToEnd() }
            if ($job.State -ne 'Running') {
                $timer.Stop()
                $btnRun.IsEnabled = $true
                Remove-Job -Job $job -Force
            }
        })
        $timer.Start()
    })

    $window.ShowDialog() | Out-Null
}

# ==========================================
# FUNGSI GUI: WINGET APP INSTALLER
# ==========================================
function Show-AppsGUI {
    [xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Install Applications" Height="700" Width="600"
        WindowStartupLocation="CenterScreen" Background="#1E1E1E" Foreground="White">
    <Grid Margin="15">
        <Grid.RowDefinitions><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
        <ScrollViewer Grid.Row="0" VerticalScrollBarVisibility="Auto">
            <StackPanel Name="PanelApps"></StackPanel>
        </ScrollViewer>
        <Button Grid.Row="1" Name="BtnInstall" Content="INSTALL SELECTED APPS" Width="250" Height="40" Background="#0078D7" Foreground="White" FontWeight="Bold" FontSize="14" Margin="0,10,0,0"/>
    </Grid>
</Window>
"@
    $reader = (New-Object System.Xml.XmlNodeReader ([xml]$xaml))
    $window = [Windows.Markup.XamlReader]::Load($reader)
    $panel = $window.FindName("PanelApps")
    $btnInstall = $window.FindName("BtnInstall")

    foreach ($app in $Global:AppList) {
        $cb = New-Object System.Windows.Controls.CheckBox
        $cb.Name = "Chk_$($app.Id)"
        $cb.Content = $app.Name
        $cb.Foreground = [System.Windows.Media.Brushes]::White
        $cb.Margin = "0,5,0,5"
        $panel.Children.Add($cb) | Out-Null
    }

    $btnInstall.Add_Click({
        $btnInstall.Content = "INSTALLING... (Silakan Tutup Jendela Jika Selesai)"
        $btnInstall.IsEnabled = $false
        $selected = @()
        foreach ($app in $Global:AppList) {
            $chk = $window.FindName("Chk_$($app.Id)")
            if ($chk.IsChecked -eq $true) { $selected += $app.Pkg }
        }
        if ($selected.Count -gt 0) {
            # Jalankan winget secara langsung (tampil di terminal utama atau background)
            foreach ($pkg in $selected) {
                Start-Process powershell -ArgumentList "-NoExit", "-Command", "winget install --id $pkg --accept-source-agreements --accept-package-agreements"
            }
        }
        $window.Close()
    })
    $window.ShowDialog() | Out-Null
}

# ==========================================
# FUNGSI GUI: TWEAKS
# ==========================================
function Show-TweaksGUI {
    [xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="System Tweaks" Height="700" Width="600"
        WindowStartupLocation="CenterScreen" Background="#1E1E1E" Foreground="White">
    <Grid Margin="15">
        <Grid.RowDefinitions><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
        <ScrollViewer Grid.Row="0" VerticalScrollBarVisibility="Auto">
            <StackPanel Name="PanelTweaks"></StackPanel>
        </ScrollViewer>
        <Button Grid.Row="1" Name="BtnRunTweaks" Content="APPLY SELECTED TWEAKS" Width="250" Height="40" Background="#0078D7" Foreground="White" FontWeight="Bold" FontSize="14" Margin="0,10,0,0"/>
    </Grid>
</Window>
"@
    $reader = (New-Object System.Xml.XmlNodeReader ([xml]$xaml))
    $window = [Windows.Markup.XamlReader]::Load($reader)
    $panel = $window.FindName("PanelTweaks")
    $btnRunTweaks = $window.FindName("BtnRunTweaks")

    foreach ($t in $Global:TweakList) {
        $cb = New-Object System.Windows.Controls.CheckBox
        $cb.Name = "Chk_$($t.Id)"
        $cb.Content = $t.Name
        $cb.Foreground = [System.Windows.Media.Brushes]::White
        $cb.Margin = "0,5,0,5"
        $panel.Children.Add($cb) | Out-Null
    }

    $btnRunTweaks.Add_Click({
        $btnRunTweaks.Content = "APPLYING..."
        $btnRunTweaks.IsEnabled = $false
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
        $btnRunTweaks.Content = "SELESAI DITERAPKAN!"
        Start-Sleep -Seconds 1
        $window.Close()
    })
    $window.ShowDialog() | Out-Null
}

# ==========================================
# FUNGSI GUI: SEDERHANA (DNS, UPDATE, BACKUP)
# ==========================================
function Show-DnsGUI {
    $choice = [System.Windows.MessageBox]::Show("Pilih DNS:`nYes = Cloudflare (1.1.1.1)`nNo = Google (8.8.8.8)`nCancel = Reset ke DHCP", "DNS Switcher", "YesNoCancel")
    $adapters = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }
    if ($choice -eq 'Yes') { foreach ($a in $adapters) { Set-DnsClientServerAddress -InterfaceIndex $a.ifIndex -ServerAddresses ("1.1.1.1","1.0.0.1") }; Clear-DnsClientCache; [System.Windows.MessageBox]::Show("DNS diubah ke Cloudflare.") }
    elseif ($choice -eq 'No') { foreach ($a in $adapters) { Set-DnsClientServerAddress -InterfaceIndex $a.ifIndex -ServerAddresses ("8.8.8.8","8.8.4.4") }; Clear-DnsClientCache; [System.Windows.MessageBox]::Show("DNS diubah ke Google.") }
    elseif ($choice -eq 'Cancel') { foreach ($a in $adapters) { Set-DnsClientServerAddress -InterfaceIndex $a.ifIndex -ResetServerAddresses }; Clear-DnsClientCache; [System.Windows.MessageBox]::Show("DNS direset ke DHCP.") }
}

function Show-UpdateGUI {
    $choice = [System.Windows.MessageBox]::Show("Pilih aksi Update:`nYes = Pause 1 Tahun`nNo = Pause 50 Tahun`nCancel = Resume Update", "Update Manager", "YesNoCancel")
    $UpdateKey = "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings"; if (-not (Test-Path $UpdateKey)) { New-Item -Path $UpdateKey -Force | Out-Null }
    if ($choice -eq 'Yes') { Set-ItemProperty -Path $UpdateKey -Name "FlightSettingsMaxPauseDays" -Value 365 -Type DWord; Set-ItemProperty -Path $UpdateKey -Name "PauseUpdatesExpiryTime" -Value (Get-Date).AddDays(365).ToString("yyyy-MM-ddTHH:mm:ssZ"); [System.Windows.MessageBox]::Show("Update dijeda 1 tahun.") }
    elseif ($choice -eq 'No') { Set-ItemProperty -Path $UpdateKey -Name "FlightSettingsMaxPauseDays" -Value 18250 -Type DWord; Set-ItemProperty -Path $UpdateKey -Name "PauseUpdatesExpiryTime" -Value (Get-Date).AddYears(50).ToString("yyyy-MM-ddTHH:mm:ssZ"); [System.Windows.MessageBox]::Show("Update dijeda 50 tahun.") }
    elseif ($choice -eq 'Cancel') { Remove-ItemProperty -Path $UpdateKey -Name "PauseUpdatesExpiryTime" -ErrorAction SilentlyContinue; Remove-ItemProperty -Path $UpdateKey -Name "FlightSettingsMaxPauseDays" -ErrorAction SilentlyContinue; [System.Windows.MessageBox]::Show("Update dilanjutkan.") }
}

function Show-BackupGUI {
    $choice = [System.Windows.MessageBox]::Show("Yes = Export Daftar App`nNo = Import Daftar App", "App Backup", "YesNo")
    $backupFile = "$env:USERPROFILE\Desktop\MyAppsBackup.json"
    if ($choice -eq 'Yes') { winget export -o $backupFile --accept-source-agreements; [System.Windows.MessageBox]::Show("Backup berhasil disimpan di Desktop.") }
    elseif ($choice -eq 'No') { if (Test-Path $backupFile) { Start-Process powershell -ArgumentList "-NoExit", "-Command", "winget import -i '$backupFile' --accept-source-agreements --accept-package-agreements" } else { [System.Windows.MessageBox]::Show("File backup tidak ditemukan di Desktop.") } }
}

function Show-SimpleCLI($title, $cmd) {
    Start-Process powershell -ArgumentList "-NoExit", "-Command", $cmd
}

# ==========================================
# MENU UTAMA GUI (Tiles)
# ==========================================
function Show-GUI {
    [xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Panduan PowerShell - Control Panel v3.0.0" Height="700" Width="950"
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
    $txtStatus = $window.FindName("TxtStatus")

    $btnMaintenance.Add_Click({ Show-MaintenanceGUI })
    $btnTweaks.Add_Click({ Show-TweaksGUI })
    $btnInstall.Add_Click({ Show-AppsGUI })
    $btnBackup.Add_Click({ Show-BackupGUI })
    $btnUpdate.Add_Click({ Show-UpdateGUI })
    $btnDNS.Add_Click({ Show-DnsGUI })
    
    # Fungsi CLI yang dilempar ke jendela terminal
    $btnAudit.Add_Click({ Show-SimpleCLI "System Audit" "Invoke-SystemAudit" })
    $btnNetwork.Add_Click({ Show-SimpleCLI "Network Diagnostics" "Invoke-NetworkDiagnostics" })
    $btnDebloater.Add_Click({ Show-SimpleCLI "Windows Debloater" "Invoke-WindowsDebloater" })
    $btnEventLog.Add_Click({ Show-SimpleCLI "Event Log Analyzer" "Invoke-EventLogAnalyzer" })

    $window.ShowDialog() | Out-Null
}

# ==========================================
# FUNGSI CLI BACKUP (Untuk jendela hitam)
# ==========================================
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

# ==========================================
# MULAI APLIKASI
# ==========================================
Show-GUI