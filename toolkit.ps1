Add-Type -AssemblyName PresentationFramework
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -Command `"irm https://raw.githubusercontent.com/elfadhildev/powershell-windows-admin-toolkit/main/toolkit.ps1 | iex`"" -Verb RunAs
    exit
}

# ==========================================
# FUNGSI CLI
# ==========================================
function Invoke-Maintenance { Write-Host "Maintenance CLI berjalan..." }

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
# DATA DEBLOATER MEGA LIST (Kategori Lengkap)
# ==========================================
$Global:DebloatList = @(
    # Microsoft Apps
    [PSCustomObject]@{ Id=1; Cat='Microsoft Apps'; Name='Feedback Hub'; Pkg='Microsoft.WindowsFeedbackHub' }
    [PSCustomObject]@{ Id=2; Cat='Microsoft Apps'; Name='Get Help'; Pkg='Microsoft.GetHelp' }
    [PSCustomObject]@{ Id=3; Cat='Microsoft Apps'; Name='Microsoft 365'; Pkg='Microsoft.MicrosoftOfficeHub' }
    [PSCustomObject]@{ Id=4; Cat='Microsoft Apps'; Name='Microsoft Teams'; Pkg='Microsoft.Teams' }
    [PSCustomObject]@{ Id=5; Cat='Microsoft Apps'; Name='Outlook for Windows'; Pkg='Microsoft.OutlookForWindows' }
    [PSCustomObject]@{ Id=6; Cat='Microsoft Apps'; Name='Cortana'; Pkg='Microsoft.549981C3F5F10' }
    
    # Microsoft Ecosystem
    [PSCustomObject]@{ Id=7; Cat='Microsoft Ecosystem'; Name='Mobile Devices'; Pkg='MicrosoftWindows.CrossDevice' }
    [PSCustomObject]@{ Id=8; Cat='Microsoft Ecosystem'; Name='Phone Link'; Pkg='Microsoft.YourPhone' }

    # Bing & Web Services
    [PSCustomObject]@{ Id=9; Cat='Bing & Web Services'; Name='Bing Search'; Pkg='Microsoft.BingSearch' }
    [PSCustomObject]@{ Id=10; Cat='Bing & Web Services'; Name='Copilot'; Pkg='Microsoft.Copilot' }
    [PSCustomObject]@{ Id=11; Cat='Bing & Web Services'; Name='News'; Pkg='Microsoft.BingNews' }
    [PSCustomObject]@{ Id=12; Cat='Bing & Web Services'; Name='Start Experiences App'; Pkg='Microsoft.StartExperiencesApp' }
    [PSCustomObject]@{ Id=13; Cat='Bing & Web Services'; Name='Weather'; Pkg='Microsoft.BingWeather' }

    # Developer Tools
    [PSCustomObject]@{ Id=14; Cat='Developer Tools'; Name='Dev Home'; Pkg='Microsoft.Windows.DevHome' }
    [PSCustomObject]@{ Id=15; Cat='Developer Tools'; Name='Power Automate'; Pkg='Microsoft.PowerAutomateDesktop' }

    # Xbox & Gaming
    [PSCustomObject]@{ Id=16; Cat='Xbox & Gaming'; Name='Solitaire Collection'; Pkg='Microsoft.MicrosoftSolitaireCollection' }
    [PSCustomObject]@{ Id=17; Cat='Xbox & Gaming'; Name='Xbox App'; Pkg='Microsoft.XboxApp' }
    [PSCustomObject]@{ Id=18; Cat='Xbox & Gaming'; Name='Xbox Game Bar'; Pkg='Microsoft.XboxGamingOverlay' }
    [PSCustomObject]@{ Id=19; Cat='Xbox & Gaming'; Name='Xbox Identity Provider'; Pkg='Microsoft.XboxIdentityProvider' }
    [PSCustomObject]@{ Id=20; Cat='Xbox & Gaming'; Name='Xbox Speech To Text Overlay'; Pkg='Microsoft.XboxSpeechToTextOverlay' }
    [PSCustomObject]@{ Id=21; Cat='Xbox & Gaming'; Name='Xbox TCUI'; Pkg='Microsoft.Xbox.TCUI' }

    # Utilities & Productivity
    [PSCustomObject]@{ Id=22; Cat='Utilities & Productivity'; Name='Calculator'; Pkg='Microsoft.WindowsCalculator' }
    [PSCustomObject]@{ Id=23; Cat='Utilities & Productivity'; Name='Camera'; Pkg='Microsoft.WindowsCamera' }
    [PSCustomObject]@{ Id=24; Cat='Utilities & Productivity'; Name='Clipchamp'; Pkg='Clipchamp.Clipchamp' }
    [PSCustomObject]@{ Id=25; Cat='Utilities & Productivity'; Name='Clock'; Pkg='Microsoft.WindowsAlarms' }
    [PSCustomObject]@{ Id=26; Cat='Utilities & Productivity'; Name='Media Player'; Pkg='Microsoft.ZuneMusic' }
    [PSCustomObject]@{ Id=27; Cat='Utilities & Productivity'; Name='Movies & TV'; Pkg='Microsoft.ZuneVideo' }
    [PSCustomObject]@{ Id=28; Cat='Utilities & Productivity'; Name='Notepad'; Pkg='Microsoft.WindowsNotepad' }
    [PSCustomObject]@{ Id=29; Cat='Utilities & Productivity'; Name='Paint'; Pkg='Microsoft.Paint' }
    [PSCustomObject]@{ Id=30; Cat='Utilities & Productivity'; Name='Photos'; Pkg='Microsoft.Windows.Photos' }
    [PSCustomObject]@{ Id=31; Cat='Utilities & Productivity'; Name='Quick Assist'; Pkg='MicrosoftCorporationII.QuickAssist' }
    [PSCustomObject]@{ Id=32; Cat='Utilities & Productivity'; Name='Snipping Tool'; Pkg='Microsoft.ScreenSketch' }
    [PSCustomObject]@{ Id=33; Cat='Utilities & Productivity'; Name='Sound Recorder'; Pkg='Microsoft.WindowsSoundRecorder' }
    [PSCustomObject]@{ Id=34; Cat='Utilities & Productivity'; Name='Sticky Notes'; Pkg='Microsoft.MicrosoftStickyNotes' }
    [PSCustomObject]@{ Id=35; Cat='Utilities & Productivity'; Name='To Do'; Pkg='Microsoft.Todos' }
)

# ==========================================
# DATA TWEAKS MEGA LIST (Escaped Ampersands)
# ==========================================
$Global:TweakList = @(
    # Essential Tweaks (18)
    [PSCustomObject]@{ Id=1; Cat='Essential'; Name='Activity History - Disable'; Action='Activity' },
    [PSCustomObject]@{ Id=2; Cat='Essential'; Name='BitLocker - Disable'; Action='BitLocker' },
    [PSCustomObject]@{ Id=3; Cat='Essential'; Name='ConsumerFeatures - Disable'; Action='Consumer' },
    [PSCustomObject]@{ Id=4; Cat='Essential'; Name='Delivery Optimization - Disable'; Action='DeliveryOpt' },
    [PSCustomObject]@{ Id=5; Cat='Essential'; Name='Disk Cleanup - Run'; Action='DiskCleanup' },
    [PSCustomObject]@{ Id=6; Cat='Essential'; Name='End Task With Right Click - Enable'; Action='EndTask' },
    [PSCustomObject]@{ Id=7; Cat='Essential'; Name='File Explorer Automatic Folder Discovery - Disable'; Action='AutoFolder' },
    [PSCustomObject]@{ Id=8; Cat='Essential'; Name='Hibernation - Disable'; Action='Hibernation' },
    [PSCustomObject]@{ Id=9; Cat='Essential'; Name='Location Tracking - Disable'; Action='Location' },
    [PSCustomObject]@{ Id=10; Cat='Essential'; Name='Microsoft Store Recommended Search Results - Disable'; Action='StoreSearch' },
    [PSCustomObject]@{ Id=11; Cat='Essential'; Name='Prevent Device Companion Apps'; Action='PreventCompanion' },
    [PSCustomObject]@{ Id=12; Cat='Essential'; Name='Restore Point - Create'; Action='RestorePoint' },
    [PSCustomObject]@{ Id=13; Cat='Essential'; Name='Services - Set to Manual'; Action='ServicesManual' },
    [PSCustomObject]@{ Id=14; Cat='Essential'; Name='Start Menu Previous Layout - Enable'; Action='StartMenuLayout' },
    [PSCustomObject]@{ Id=15; Cat='Essential'; Name='Telemetry - Disable'; Action='Telemetry' },
    [PSCustomObject]@{ Id=16; Cat='Essential'; Name='Temporary Files - Remove'; Action='TempFiles' },
    [PSCustomObject]@{ Id=17; Cat='Essential'; Name='Widgets - Remove'; Action='Widgets' },
    [PSCustomObject]@{ Id=18; Cat='Essential'; Name='Windows Platform Binary Table (WPBT) - Disable'; Action='WPBT' },

    # Advanced Tweaks - CAUTION (20) - Ampersands Escaped!
    [PSCustomObject]@{ Id=19; Cat='Advanced'; Name='Adobe URL Block List - Enable'; Action='AdobeBlock' },
    [PSCustomObject]@{ Id=20; Cat='Advanced'; Name='Background Apps - Disable'; Action='BgApps' },
    [PSCustomObject]@{ Id=21; Cat='Advanced'; Name='Brave Browser - Debloat'; Action='BraveDebloat' },
    [PSCustomObject]@{ Id=22; Cat='Advanced'; Name='Date &amp; Time - Set Time to UTC'; Action='UTC' },
    [PSCustomObject]@{ Id=23; Cat='Advanced'; Name='Disable Reserved Storage'; Action='Reserved' },
    [PSCustomObject]@{ Id=24; Cat='Advanced'; Name='File Explorer Home and Gallery - Disable'; Action='FileExplorerHome' },
    [PSCustomObject]@{ Id=25; Cat='Advanced'; Name='IPv6 - Disable'; Action='IPv6' },
    [PSCustomObject]@{ Id=26; Cat='Advanced'; Name='IPv6 - Set IPv4 as Preferred'; Action='IPv4Pref' },
    [PSCustomObject]@{ Id=27; Cat='Advanced'; Name='Logitech Download Assistant Auto-Install - Disable'; Action='Logitech' },
    [PSCustomObject]@{ Id=28; Cat='Advanced'; Name='Microsoft Edge - Debloat'; Action='EdgeDebloat' },
    [PSCustomObject]@{ Id=29; Cat='Advanced'; Name='Microsoft Edge - Remove'; Action='EdgeRemove' },
    [PSCustomObject]@{ Id=30; Cat='Advanced'; Name='Microsoft OneDrive - Remove'; Action='OneDrive' },
    [PSCustomObject]@{ Id=31; Cat='Advanced'; Name='Razer Software Auto-Install - Disable'; Action='Razer' },
    [PSCustomObject]@{ Id=32; Cat='Advanced'; Name='RDP Unsigned File Warnings - Disable'; Action='RDPWarn' },
    [PSCustomObject]@{ Id=33; Cat='Advanced'; Name='Right-Click Menu Previous Layout - Enable'; Action='RightClickMenu' },
    [PSCustomObject]@{ Id=34; Cat='Advanced'; Name='Storage Sense - Disable'; Action='StorageSense' },
    [PSCustomObject]@{ Id=35; Cat='Advanced'; Name='System Tray Notifications &amp; Calendar - Disable'; Action='Notifications' },
    [PSCustomObject]@{ Id=36; Cat='Advanced'; Name='Teredo - Disable'; Action='Teredo' },
    [PSCustomObject]@{ Id=37; Cat='Advanced'; Name='Visual Effects - Set to Best Performance'; Action='VisualFX' },
    [PSCustomObject]@{ Id=38; Cat='Advanced'; Name='Windows AI - Disable And Remove'; Action='WindowsAI' }
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
        $safeCat = $cat -replace '&', '&amp;'
        $xamlStr += "<TabItem Header='$safeCat' Background='#2D2D30' Foreground='White'><ScrollViewer VerticalScrollBarVisibility='Auto'><StackPanel Margin='10'>"
        $items = $Global:TweakList | Where-Object { $_.Cat -eq $cat }
        foreach ($item in $items) {
            $safeName = $item.Name -replace '&', '&amp;'
            $xamlStr += "<CheckBox Name='Chk_$($item.Id)' Content='$safeName' Foreground='White' Margin='0,8,0,8'/>"
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
                'Activity' { 
                    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "EnableActivityFeed" -Value 0 -Type DWord -ErrorAction SilentlyContinue
                    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "PublishUserActivities" -Value 0 -Type DWord -ErrorAction SilentlyContinue
                    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "UploadUserActivities" -Value 0 -Type DWord -ErrorAction SilentlyContinue
                }
                'BitLocker' { Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\BitLocker" -Name "PreventDeviceEncryption" -Value 1 -Type DWord -ErrorAction SilentlyContinue }
                'Consumer' { Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableWindowsConsumerFeatures" -Value 1 -Type DWord -ErrorAction SilentlyContinue }
                'DeliveryOpt' { Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" -Name "DODownloadMode" -Value 0 -Type DWord -ErrorAction SilentlyContinue }
                'DiskCleanup' { Start-Process cleanmgr.exe -ArgumentList "/sagerun:1" -Wait -NoNewWindow }
                'EndTask' { Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings" -Name "TaskbarEndTask" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue }
                'AutoFolder' { Set-ItemProperty -Path "HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\Bags\AllFolders\Shell" -Name "FolderType" -Value "NotSpecified" -Force -ErrorAction SilentlyContinue }
                'Hibernation' { Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Session Manager\Power" -Name "HibernateEnabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue; powercfg -h off }
                'Location' { Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" -Name "DisableLocation" -Value 1 -Type DWord -ErrorAction SilentlyContinue; Set-Service -Name lfsvc -StartupType Disabled -ErrorAction SilentlyContinue; Stop-Service -Name lfsvc -Force -ErrorAction SilentlyContinue }
                'StoreSearch' { Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338388Enabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue }
                'PreventCompanion' { Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Device Metadata" -Name "PreventDeviceMetadataFromNetwork" -Value 1 -Type DWord -ErrorAction SilentlyContinue }
                'RestorePoint' { if ((Get-ComputerRestorePoint).Count -eq $null) { Enable-ComputerRestore -Drive "C:\" }; Checkpoint-Computer -Description "Toolkit Restore" -RestorePointType "MODIFY_SETTINGS" }
                'ServicesManual' { $services = @("DiagTrack", "dmwappushservice", "MapsBroker", "RetailDemo", "WSearch"); foreach ($svc in $services) { Set-Service -Name $svc -StartupType Manual -ErrorAction SilentlyContinue } }
                'StartMenuLayout' { Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\Shell\Bags\1\Desktop" -Name "FFlags" -Value 1075839525 -Type DWord -ErrorAction SilentlyContinue }
                'Telemetry' { Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0 -Type DWord -ErrorAction SilentlyContinue; Set-Service -Name DiagTrack -StartupType Disabled -ErrorAction SilentlyContinue; Stop-Service -Name DiagTrack -Force -ErrorAction SilentlyContinue }
                'TempFiles' { $folders = @("$env:TEMP", "C:\Windows\Temp", "C:\Windows\Prefetch", "C:\Windows\SoftwareDistribution\Download"); foreach ($f in $folders) { if (Test-Path $f) { Get-ChildItem -Path $f -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue } } }
                'Widgets' { Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarDa" -Value 0 -Type DWord -ErrorAction SilentlyContinue }
                'WPBT' { $file = "C:\Windows\System32\wpbbin.exe"; if (Test-Path $file) { takeown /f $file | Out-Null; icacls $file /deny "Everyone:(X)" | Out-Null } }
                'AdobeBlock' { Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown" -Name "bEnableAcrobatDocumentCloud" -Value 0 -Type DWord -ErrorAction SilentlyContinue }
                'BgApps' { Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" -Name "GlobalUserDisabled" -Value 1 -Type DWord -ErrorAction SilentlyContinue }
                'BraveDebloat' { Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\BraveSoftware\Brave" -Name "MetricsReportingEnabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue; Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\BraveSoftware\Brave" -Name "PromotionsEnabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue }
                'UTC' { Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\TimeZoneInformation" -Name "RealTimeIsUniversal" -Value 1 -Type DWord -ErrorAction SilentlyContinue }
                'Reserved' { Set-WindowsReservedStorageState -State Disabled -ErrorAction SilentlyContinue }
                'FileExplorerHome' { Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowRecent" -Value 0 -Type DWord -ErrorAction SilentlyContinue; Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowFrequent" -Value 0 -Type DWord -ErrorAction SilentlyContinue }
                'IPv6' { Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters" -Name "DisabledComponents" -Value 255 -Type DWord -ErrorAction SilentlyContinue }
                'IPv4Pref' { Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters" -Name "DisabledComponents" -Value 32 -Type DWord -ErrorAction SilentlyContinue }
                'Logitech' { Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Device Metadata" -Name "PreventDeviceMetadataFromNetwork" -Value 1 -Type DWord -ErrorAction SilentlyContinue }
                'EdgeDebloat' { Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "EdgeShoppingAssistantEnabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue; Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "ShowRecommendationsEnabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue }
                'EdgeRemove' { Get-AppxPackage -Name "Microsoft.MicrosoftEdge.Stable" -AllUsers | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue }
                'OneDrive' { Stop-Process -Name "OneDrive" -Force -ErrorAction SilentlyContinue; Start-Process "C:\Windows\System32\OneDriveSetup.exe" -ArgumentList "/uninstall" -Wait -ErrorAction SilentlyContinue }
                'Razer' { Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Device Metadata" -Name "PreventDeviceMetadataFromNetwork" -Value 1 -Type DWord -ErrorAction SilentlyContinue }
                'RDPWarn' { Set-ItemProperty -Path "HKCU:\Software\Microsoft\Terminal Server Client" -Name "AuthenticationLevelOverride" -Value 0 -Type DWord -ErrorAction SilentlyContinue }
                'RightClickMenu' { New-Item -Path "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" -Force | Out-Null; Set-ItemProperty -Path "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" -Name "(Default)" -Value "" }
                'StorageSense' { Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" -Name "01" -Value 0 -Type DWord -ErrorAction SilentlyContinue }
                'Notifications' { Set-ItemProperty -Path "HKCU:\Software\Policies\Microsoft\Windows\Explorer" -Name "DisableNotificationCenter" -Value 1 -Type DWord -ErrorAction SilentlyContinue; Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\PushNotifications" -Name "ToastEnabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue }
                'Teredo' { netsh interface teredo set state disabled }
                'VisualFX' { Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value 2 -Type DWord -ErrorAction SilentlyContinue }
                'WindowsAI' { Set-ItemProperty -Path "HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot" -Name "TurnOffWindowsCopilot" -Value 1 -Type DWord -ErrorAction SilentlyContinue; Get-AppxPackage -Name "Microsoft.Copilot" -AllUsers | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue }
            }
        }
        $btnApply.Content = "SELESAI DITERAPKAN!"
        Start-Sleep -Seconds 1
        $window.Close()
    })
    $window.ShowDialog() | Out-Null
}

# ==========================================
# FUNGSI GUI: DEBLOATER (KATEGORI & TOMBOL SELECT)
# ==========================================
function Show-DebloaterGUI {
    $categories = $Global:DebloatList.Cat | Sort-Object -Unique
    $xamlStr = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Windows Debloater" Height="700" Width="650"
        WindowStartupLocation="CenterScreen" Background="#1E1E1E" Foreground="White">
    <Grid Margin="15">
        <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
        
        <!-- Tombol Aksi Atas -->
        <StackPanel Grid.Row="0" Orientation="Horizontal" HorizontalAlignment="Left" Margin="0,0,0,10">
            <Button Name="BtnSelectAll" Content="Select All" Width="100" Height="30" Background="#0078D7" Foreground="White" FontWeight="Bold" Margin="0,0,10,0"/>
            <Button Name="BtnClearSel" Content="Clear Selection" Width="100" Height="30" Background="#2D2D30" Foreground="White" FontWeight="Bold"/>
        </StackPanel>

        <!-- Tab Kategori -->
        <TabControl Grid.Row="1" Name="TabMain" Background="#1E1E1E" BorderBrush="#3F3F46">
"@
    foreach ($cat in $categories) {
        $safeCat = $cat -replace '&', '&amp;'
        $xamlStr += "<TabItem Header='$safeCat' Background='#2D2D30' Foreground='White'><ScrollViewer VerticalScrollBarVisibility='Auto'><StackPanel Margin='10'>"
        $items = $Global:DebloatList | Where-Object { $_.Cat -eq $cat }
        foreach ($item in $items) {
            $safeName = $item.Name -replace '&', '&amp;'
            $xamlStr += "<CheckBox Name='Chk_$($item.Id)' Content='$safeName' Foreground='White' Margin='0,8,0,8'/>"
        }
        $xamlStr += "</StackPanel></ScrollViewer></TabItem>"
    }
    $xamlStr += @"
        </TabControl>
        
        <!-- Tombol Uninstall -->
        <Button Grid.Row="2" Name="BtnRemove" Content="UNINSTALL SELECTED" Width="250" Height="40" Background="#D83B01" Foreground="White" FontWeight="Bold" FontSize="14" Margin="0,15,0,0" HorizontalAlignment="Center"/>
    </Grid>
</Window>
"@
    $reader = (New-Object System.Xml.XmlNodeReader ([xml]$xamlStr))
    $window = [Windows.Markup.XamlReader]::Load($reader)
    $btnRemove = $window.FindName("BtnRemove")
    $btnSelectAll = $window.FindName("BtnSelectAll")
    $btnClearSel = $window.FindName("BtnClearSel")

    # Event Handler: Select All
    $btnSelectAll.Add_Click({
        foreach ($item in $Global:DebloatList) {
            $chk = $window.FindName("Chk_$($item.Id)")
            if ($chk) { $chk.IsChecked = $true }
        }
    })

    # Event Handler: Clear Selection
    $btnClearSel.Add_Click({
        foreach ($item in $Global:DebloatList) {
            $chk = $window.FindName("Chk_$($item.Id)")
            if ($chk) { $chk.IsChecked = $false }
        }
    })

    # Event Handler: Uninstall
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
        $safeCat = $cat -replace '&', '&amp;'
        $xamlStr += "<TabItem Header='$safeCat' Background='#2D2D30' Foreground='White'><ScrollViewer VerticalScrollBarVisibility='Auto'><StackPanel Margin='10'>"
        $items = $Global:AppList | Where-Object { $_.Cat -eq $cat }
        foreach ($item in $items) {
            $safeName = $item.Name -replace '&', '&amp;'
            $xamlStr += "<CheckBox Name='Chk_$($item.Id)' Content='$safeName' Foreground='White' Margin='0,8,0,8'/>"
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
# FUNGSI GUI: DNS SWITCHER (MEGA UPDATE)
# ==========================================
function Show-DnsGUI {
    $xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="DNS Switcher" Height="350" Width="500"
        WindowStartupLocation="CenterScreen" Background="#1E1E1E" Foreground="White" WindowStyle="ToolWindow">
    <Grid Margin="20">
        <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
        <TextBlock Grid.Row="0" Text="Pilih Penyedia DNS:" FontSize="16" FontWeight="Bold" Margin="0,0,0,10"/>
        <ComboBox Grid.Row="1" Name="CmbDns" Background="#2D2D30" Foreground="Black" Height="35" FontSize="14" Margin="0,0,0,15">
            <ComboBoxItem Content="Default (DHCP)" IsSelected="True"/>
            <ComboBoxItem Content="Google (8.8.8.8)"/>
            <ComboBoxItem Content="Cloudflare (1.1.1.1)"/>
            <ComboBoxItem Content="Cloudflare Malware (1.1.1.2)"/>
            <ComboBoxItem Content="Cloudflare Malware+Adult (1.1.1.3)"/>
            <ComboBoxItem Content="OpenDNS (208.67.222.222)"/>
            <ComboBoxItem Content="Quad9 (9.9.9.9)"/>
            <ComboBoxItem Content="AdGuard Ads+Trackers (94.140.14.14)"/>
            <ComboBoxItem Content="AdGuard Ads+Malware+Adult (94.140.14.15)"/>
        </ComboBox>
        <TextBlock Grid.Row="2" Text="Catatan: Mengubah DNS dapat mempercepat internet dan memblokir iklan/malware." FontSize="12" Foreground="Gray" TextWrapping="Wrap"/>
        <Button Grid.Row="3" Name="BtnApplyDns" Content="APPLY DNS" Width="150" Height="40" Background="#0078D7" Foreground="White" FontWeight="Bold" FontSize="14" HorizontalAlignment="Center"/>
    </Grid>
</Window>
"@
    $reader = (New-Object System.Xml.XmlNodeReader ([xml]$xaml))
    $window = [Windows.Markup.XamlReader]::Load($reader)
    $cmb = $window.FindName("CmbDns")
    $btn = $window.FindName("BtnApplyDns")

    $btn.Add_Click({
        $selection = $cmb.SelectedItem.Content.ToString()
        $dns1 = ""; $dns2 = ""
        
        switch -Wildcard ($selection) {
            "*Google*" { $dns1 = "8.8.8.8"; $dns2 = "8.8.4.4" }
            "*Cloudflare (1.1.1.1)*" { $dns1 = "1.1.1.1"; $dns2 = "1.0.0.1" }
            "*Cloudflare Malware (1.1.1.2)*" { $dns1 = "1.1.1.2"; $dns2 = "1.0.0.2" }
            "*Cloudflare Malware+Adult*" { $dns1 = "1.1.1.3"; $dns2 = "1.0.0.3" }
            "*OpenDNS*" { $dns1 = "208.67.222.222"; $dns2 = "208.67.220.220" }
            "*Quad9*" { $dns1 = "9.9.9.9"; $dns2 = "149.112.112.112" }
            "*AdGuard Ads+Trackers*" { $dns1 = "94.140.14.14"; $dns2 = "94.140.15.15" }
            "*AdGuard Ads+Malware+Adult*" { $dns1 = "94.140.14.15"; $dns2 = "94.140.15.16" }
        }

        $adapters = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }
        if ($selection -match "Default") { 
            foreach ($a in $adapters) { Set-DnsClientServerAddress -InterfaceIndex $a.ifIndex -ResetServerAddresses } 
        } else {
            foreach ($a in $adapters) { Set-DnsClientServerAddress -InterfaceIndex $a.ifIndex -ServerAddresses ($dns1, $dns2) }
        }
        Clear-DnsClientCache
        
        [System.Windows.MessageBox]::Show("DNS berhasil diubah ke: $selection", "Sukses", "OK", "Information") | Out-Null
        $window.Close()
    })
    $window.ShowDialog() | Out-Null
}

# ==========================================
# FUNGSI GUI: UPDATE MANAGER (SECURITY ONLY)
# ==========================================
function Show-UpdateGUI {
    $xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Update Manager" Height="350" Width="500"
        WindowStartupLocation="CenterScreen" Background="#1E1E1E" Foreground="White" WindowStyle="ToolWindow">
    <Grid Margin="20">
        <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
        <TextBlock Grid.Row="0" Text="Pilih Aksi Pembaruan Windows:" FontSize="16" FontWeight="Bold" Margin="0,0,0,15"/>
        <StackPanel Grid.Row="1">
            <Button Name="BtnPause1" Content="Pause 1 Tahun (Aman)" Height="40" Margin="0,5" Background="#2D2D30" Foreground="White"/>
            <Button Name="BtnPause50" Content="Pause 50 Tahun (Ekstrem)" Height="40" Margin="0,5" Background="#2D2D30" Foreground="White"/>
            <Button Name="BtnSecurity" Content="Security Updates Only (Hanya Keamanan)" Height="40" Margin="0,5" Background="#107C10" Foreground="White" FontWeight="Bold"/>
            <Button Name="BtnResume" Content="Resume Normal Updates" Height="40" Margin="0,5" Background="#2D2D30" Foreground="White"/>
        </StackPanel>
        <Button Grid.Row="2" Name="BtnCancel" Content="Batal" Width="100" Height="30" Background="#D83B01" Foreground="White" Margin="0,15,0,0" HorizontalAlignment="Right"/>
    </Grid>
</Window>
"@
    $reader = (New-Object System.Xml.XmlNodeReader ([xml]$xaml))
    $window = [Windows.Markup.XamlReader]::Load($reader)
    $btnPause1 = $window.FindName("BtnPause1")
    $btnPause50 = $window.FindName("BtnPause50")
    $btnSecurity = $window.FindName("BtnSecurity")
    $btnResume = $window.FindName("BtnResume")
    $btnCancel = $window.FindName("BtnCancel")

    $UpdateKey = "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings"; if (-not (Test-Path $UpdateKey)) { New-Item -Path $UpdateKey -Force | Out-Null }

    $btnPause1.Add_Click({ 
        Set-ItemProperty -Path $UpdateKey -Name "FlightSettingsMaxPauseDays" -Value 365 -Type DWord
        Set-ItemProperty -Path $UpdateKey -Name "PauseUpdatesExpiryTime" -Value (Get-Date).AddDays(365).ToString("yyyy-MM-ddTHH:mm:ssZ")
        [System.Windows.MessageBox]::Show("Update dijeda 1 tahun.", "Sukses") | Out-Null
        $window.Close() 
    })
    $btnPause50.Add_Click({ 
        Set-ItemProperty -Path $UpdateKey -Name "FlightSettingsMaxPauseDays" -Value 18250 -Type DWord
        Set-ItemProperty -Path $UpdateKey -Name "PauseUpdatesExpiryTime" -Value (Get-Date).AddYears(50).ToString("yyyy-MM-ddTHH:mm:ssZ")
        [System.Windows.MessageBox]::Show("Update dijeda 50 tahun.", "Sukses") | Out-Null
        $window.Close() 
    })
    $btnSecurity.Add_Click({ 
        Set-ItemProperty -Path $UpdateKey -Name "DeferFeatureUpdates" -Value 1 -Type DWord
        Set-ItemProperty -Path $UpdateKey -Name "DeferFeatureUpdatesPeriodInDays" -Value 365 -Type DWord
        [System.Windows.MessageBox]::Show("Hanya update keamanan yang akan diinstal (Feature update ditunda 1 tahun).", "Sukses") | Out-Null
        $window.Close() 
    })
    $btnResume.Add_Click({ 
        Remove-ItemProperty -Path $UpdateKey -Name "PauseUpdatesExpiryTime" -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path $UpdateKey -Name "FlightSettingsMaxPauseDays" -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path $UpdateKey -Name "DeferFeatureUpdates" -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path $UpdateKey -Name "DeferFeatureUpdatesPeriodInDays" -ErrorAction SilentlyContinue
        [System.Windows.MessageBox]::Show("Update dilanjutkan seperti normal.", "Sukses") | Out-Null
        $window.Close() 
    })
    $btnCancel.Add_Click({ $window.Close() })

    $window.ShowDialog() | Out-Null
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
        Title="Panduan PowerShell - Control Panel v3.2.4" Height="700" Width="950"
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