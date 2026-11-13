# ============================================================
# PowerShell Windows Admin Toolkit v6.0.0
# ============================================================
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -Command `"irm https://raw.githubusercontent.com/elfadhildev/powershell-windows-admin-toolkit/main/toolkit.ps1 | iex`"" -Verb RunAs
    exit
}

$Global:LogBox      = $null
$Global:LogDocument = $null
$Global:ActiveJob   = $null
$Global:ActiveTimer = $null
$Global:JobDoneMsg  = $null

function Add-Log {
    param([string]$Message, [string]$Color = "#DDDDDD")
    if (-not $Global:LogDocument) { return }
    $p = New-Object System.Windows.Documents.Paragraph
    $p.Margin = New-Object System.Windows.Thickness(0)
    $r = New-Object System.Windows.Documents.Run -ArgumentList $Message
    try { $r.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString($Color) }
    catch { $r.Foreground = [System.Windows.Media.Brushes]::White }
    $p.Inlines.Add($r)
    $Global:LogDocument.Blocks.Add($p)
    $Global:LogBox.ScrollToEnd()
}

function Get-LogColor {
    param([string]$Line)
    if ($Line -match '\[OK\]|\[SUCCESS\]|\[DONE\]') { return "#00FF7F" }
    if ($Line -match '\[ERROR\]|\[FAIL\]')            { return "#FF5555" }
    if ($Line -match '\[WARN\]|\[!\]')               { return "#FFA500" }
    if ($Line -match '\[INFO\]|\[\*\]')              { return "#00BFFF" }
    return "#DDDDDD"
}

function Invoke-GuiJob {
    param(
        [scriptblock]$ScriptBlock,
        [object[]]$ArgumentList,
        [string]$StartMessage,
        [string]$DoneMessage = "[OK] Job selesai."
    )
    if ($Global:ActiveJob -and $Global:ActiveJob.State -eq 'Running') {
        Add-Log "[!] Tunggu proses sebelumnya selesai dulu." "#FF5555"
        return
    }
    Add-Log "`n$StartMessage" "#00BFFF"
    $Global:ActiveJob  = Start-Job -ScriptBlock $ScriptBlock -ArgumentList $ArgumentList
    $Global:JobDoneMsg = $DoneMessage
    $Global:ActiveTimer = New-Object System.Windows.Threading.DispatcherTimer
    $Global:ActiveTimer.Interval = [TimeSpan]::FromMilliseconds(400)
    $Global:ActiveTimer.Add_Tick({
        if (-not $Global:ActiveJob) { $Global:ActiveTimer.Stop(); return }
        $output = Receive-Job -Job $Global:ActiveJob 2>&1
        foreach ($line in $output) { $s = "$line"; Add-Log $s (Get-LogColor $s) }
        if ($Global:ActiveJob.State -notin @('Running','NotStarted')) {
            $final = Receive-Job -Job $Global:ActiveJob 2>&1
            foreach ($line in $final) { $s = "$line"; Add-Log $s (Get-LogColor $s) }
            $state = $Global:ActiveJob.State
            if ($state -eq 'Completed') {
                if ($Global:JobDoneMsg) { Add-Log $Global:JobDoneMsg "#00FF7F" }
            } else {
                Add-Log "[ERROR] Job berakhir: $state" "#FF5555"
            }
            Remove-Job -Job $Global:ActiveJob -Force
            $Global:ActiveJob = $null
            $Global:ActiveTimer.Stop()
        }
    })
    $Global:ActiveTimer.Start()
}

function New-DarkWindow {
    param([string]$Title, [int]$Width = 620, [int]$Height = 540)
    $w = New-Object System.Windows.Window
    $w.Title = $Title
    $w.Width = $Width
    $w.Height = $Height
    $w.WindowStartupLocation = "CenterOwner"
    $w.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#1E1E1E")
    $w.Foreground = [System.Windows.Media.Brushes]::White
    return $w
}

function New-DarkButton {
    param([string]$Text, [int]$Width = 130, [string]$Bg = "#0078D7")
    $b = New-Object System.Windows.Controls.Button
    $b.Content = $Text
    $b.Width = $Width
    $b.Height = 34
    $b.Margin = "5,5,5,5"
    $b.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString($Bg)
    $b.Foreground = [System.Windows.Media.Brushes]::White
    $b.BorderThickness = 0
    return $b
}

function New-DarkCheckBox {
    param([string]$Text, [bool]$IsChecked = $false, [object]$Tag = $null)
    $cb = New-Object System.Windows.Controls.CheckBox
    $cb.Content = $Text
    $cb.IsChecked = $IsChecked
    if ($null -ne $Tag) { $cb.Tag = $Tag }
    $cb.Foreground = [System.Windows.Media.Brushes]::White
    $cb.Margin = "0,6,0,6"
    return $cb
}

function Execute-Maintenance {
    param([array]$Actions)
    $ErrorActionPreference = 'SilentlyContinue'

    if ($Actions -contains 'DnsCache') {
        Write-Output "[*] Membersihkan DNS Cache..."
        try { Clear-DnsClientCache -ErrorAction Stop; ipconfig /flushdns *>&1 | Out-Null; Write-Output "[OK] DNS Cache dibersihkan." }
        catch { Write-Output "[ERROR] Gagal clear DNS: $($_.Exception.Message)" }
    }
    if ($Actions -contains 'IpReset') {
        Write-Output "[*] Release + Renew IP Address..."
        try { ipconfig /release *>&1 | Out-Null; ipconfig /renew *>&1 | Out-Null; Write-Output "[OK] IP diperbarui." }
        catch { Write-Output "[ERROR] Gagal reset IP: $($_.Exception.Message)" }
    }

    $tempTargets = [ordered]@{
        'UserTemp'    = $env:TEMP
        'WindowsTemp' = "$env:SystemRoot\Temp"
        'Prefetch'    = "$env:SystemRoot\Prefetch"
        'UpdateCache' = "$env:SystemRoot\SoftwareDistribution\Download"
    }
    foreach ($key in $tempTargets.Keys) {
        if ($Actions -contains $key) {
            $path = $tempTargets[$key]
            if (Test-Path $path) {
                Write-Output "[*] Membersihkan: $path"
                try {
                    $before = (Get-ChildItem $path -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
                    Get-ChildItem $path -Recurse -Force -ErrorAction SilentlyContinue |
                        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
                    $after  = (Get-ChildItem $path -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
                    $freed  = [math]::Round((($before - $after) / 1MB), 2)
                    Write-Output "[OK] $path - dibebaskan ~${freed} MB."
                } catch { Write-Output "[WARN] Sebagian file tidak bisa dihapus: $($_.Exception.Message)" }
            } else { Write-Output "[INFO] Folder tidak ditemukan: $path" }
        }
    }

    if ($Actions -contains 'CleanMgr') {
        Write-Output "[*] Mengonfigurasi preset Disk Cleanup secara otomatis..."
        try {
            $volCaches = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches"
            Get-ChildItem $volCaches -ErrorAction SilentlyContinue | ForEach-Object {
                if ($_.PSChildName -ne 'DownloadsFolder') {
                    Set-ItemProperty -Path $_.PSPath -Name 'StateFlags0001' -Value 2 -Type DWord -ErrorAction SilentlyContinue
                }
            }
            Write-Output "[*] Menjalankan cleanmgr /sagerun:1 (Silent Mode)..."
            Start-Process cleanmgr.exe -ArgumentList '/sagerun:1 /d C:' -NoNewWindow -Wait -ErrorAction Stop
            Write-Output "[OK] Disk Cleanup selesai."
        } catch {
            Write-Output "[WARN] cleanmgr gagal: $($_.Exception.Message)"
        }
    }
    if ($Actions -contains 'DismCleanup') {
        Write-Output "[*] DISM Component Cleanup (5-10 menit)..."
        & dism.exe /Online /Cleanup-Image /StartComponentCleanup 2>&1 | ForEach-Object { Write-Output "   $_" }
        Write-Output "[OK] DISM Component Cleanup selesai."
    }
    if ($Actions -contains 'SFC') {
        Write-Output "[*] SFC /scannow dimulai (5-15 menit)..."
        & sfc.exe /scannow 2>&1 | ForEach-Object { Write-Output "   $_" }
        Write-Output "[OK] SFC selesai."
    }
    if ($Actions -contains 'DismRestore') {
        Write-Output "[*] DISM RestoreHealth (10-20 menit)..."
        & dism.exe /Online /Cleanup-Image /RestoreHealth 2>&1 | ForEach-Object { Write-Output "   $_" }
        Write-Output "[OK] DISM RestoreHealth selesai."
    }
    if ($Actions -contains 'OptimizeDisk') {
        Write-Output "[*] Deteksi tipe disk C:..."
        try {
            $part = Get-Partition -DriveLetter C -ErrorAction Stop
            $disk = Get-PhysicalDisk | Where-Object { $_.DeviceID -eq $part.DiskNumber }
            if ($disk.MediaType -eq 'SSD') {
                Write-Output "[*] SSD - menjalankan ReTrim..."
                Optimize-Volume -DriveLetter C -ReTrim -ErrorAction SilentlyContinue | Out-Null
                Write-Output "[OK] ReTrim selesai."
            } else {
                Write-Output "[*] HDD - menjalankan Defrag..."
                Optimize-Volume -DriveLetter C -Defrag -ErrorAction SilentlyContinue | Out-Null
                Write-Output "[OK] Defrag selesai."
            }
        } catch { Write-Output "[ERROR] Optimasi disk gagal: $($_.Exception.Message)" }
    }
    Write-Output "[DONE] Maintenance selesai."
}

function Execute-SystemAudit {
    $ErrorActionPreference = 'SilentlyContinue'
    Write-Output "[*] Mengumpulkan info sistem..."
    $os  = Get-CimInstance Win32_OperatingSystem
    $cpu = Get-CimInstance Win32_Processor
    $cs  = Get-CimInstance Win32_ComputerSystem
    $ram = [math]::Round($cs.TotalPhysicalMemory / 1GB, 2)
    Write-Output "OS   : $($os.Caption) ($($os.Version))"
    Write-Output "CPU  : $($cpu.Name.Trim())"
    Write-Output "RAM  : $ram GB"
    $lic = Get-CimInstance SoftwareLicensingProduct | Where-Object { $_.PartialProductKey } | Select-Object -First 1
    if ($lic -and $lic.LicenseStatus -eq 1) { Write-Output "[OK] Windows Teraktivasi." }
    else { Write-Output "[WARN] Windows Belum Teraktivasi." }

    Write-Output "`n[*] Kesehatan Disk:"
    Get-PhysicalDisk | ForEach-Object {
        Write-Output ("   {0} | {1} | {2} | {3} GB" -f $_.FriendlyName, $_.MediaType, $_.HealthStatus, [math]::Round($_.Size/1GB,1))
    }

    Write-Output "`n[*] Driver Bermasalah:"
    $bad = Get-PnpDevice -PresentOnly | Where-Object { $_.Status -ne 'OK' }
    if ($bad) {
        foreach ($d in $bad) { Write-Output ("   [{0}] {1} - {2}" -f $d.Class, $d.FriendlyName, $d.Status) }
    } else { Write-Output "   [OK] Semua driver berstatus OK." }

    $report = "=== SYSTEM AUDIT $(Get-Date) ==="
    $report += "`nOS: $($os.Caption) | CPU: $($cpu.Name) | RAM: $ram GB"
    $report += "`nLisensi: $(if ($lic -and $lic.LicenseStatus -eq 1) {'Aktif'} else {'Belum Aktif'})"
    $reportPath = Join-Path $env:USERPROFILE "Desktop\System_Audit_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
    $report | Out-File -FilePath $reportPath -Encoding UTF8
    Write-Output "[OK] Laporan disimpan di: $reportPath"
    Write-Output "[DONE] Audit selesai."
}

function Execute-NetworkDiagnostics {
    $ErrorActionPreference = 'SilentlyContinue'
    Write-Output "[*] Mengumpulkan konfigurasi jaringan..."
    Write-Output "`n[IP Configuration]"
    Get-NetIPConfiguration | Where-Object { $_.IPv4Address } | ForEach-Object {
        Write-Output "   Interface : $($_.InterfaceAlias)"
        Write-Output "   IPv4      : $($_.IPv4Address.IPAddress)"
        Write-Output "   Gateway   : $($_.IPv4DefaultGateway.NextHop)"
        Write-Output "   DNS       : $($_.DNSServer.ServerAddresses -join ', ')"
        Write-Output "   ---"
    }
    Write-Output "`n[Established TCP Connections]"
    Get-NetTCPConnection -State Established -ErrorAction SilentlyContinue | ForEach-Object {
        $p = Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue
        Write-Output ("   {0}:{1} -> {2}:{3} [{4}]" -f $_.LocalPort, '', $_.RemoteAddress, $_.RemotePort, $(if($p){$p.ProcessName}else{'?'}))
    }
    Write-Output "`n[DNS Resolution Test google.com]"
    $dns = Resolve-DnsName -Name 'google.com' -Type A -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($dns) { Write-Output "[OK] google.com -> $($dns.IPAddress)" } else { Write-Output "[ERROR] Resolusi DNS gagal!" }
    Write-Output "[DONE] Network diagnostics selesai."
}

function Execute-EventLogAnalyzer {
    $ErrorActionPreference = 'SilentlyContinue'
    Write-Output "[*] Memindai event log 7 hari terakhir (Level Error/Critical)..."
    $events = Get-WinEvent -FilterHashtable @{LogName='System','Application'; Level=1,2; StartTime=(Get-Date).AddDays(-7)} -ErrorAction SilentlyContinue
    if (-not $events) { Write-Output "[OK] Tidak ada error/critical dalam 7 hari terakhir."; Write-Output "[DONE] Selesai."; return }
    Write-Output "[WARN] Ditemukan $($events.Count) event error/critical."
    $summary = $events | Group-Object ProviderName | Sort-Object Count -Descending | Select-Object -First 10
    $i = 0
    foreach ($s in $summary) {
        $i++
        Write-Output ("   [$i] {0} ({1} kali)" -f $s.Name, $s.Count)
        $sample = $s.Group | Select-Object -First 1
        $msg = ($sample.Message -replace "`r?`n", ' ')
        if ($msg.Length -gt 160) { $msg = $msg.Substring(0,160) + '...' }
        Write-Output "        $msg"
    }
    Write-Output "`n[*] Saran otomatis per provider:"
    foreach ($s in $summary) {
        switch -Wildcard ($s.Name) {
            '*DistributedCOM*'         { Write-Output "   [OK] DCOM 10016 = normal Windows, abaikan." }
            '*Service Control Manager*' { Write-Output "   [!] SCM gagal start service - jalankan Repair System (SFC/DISM)." }
            '*VSS*'                    { Write-Output "   [!] VSS gagal - jalankan Repair System atau cek disk." }
            '*CAPI2*'                  { Write-Output "   [!] CAPI2 - reset Windows Update Cache." }
        }
    }
    Write-Output "[DONE] Analisa event log selesai."
}

function Execute-UserBackup {
    param([string]$TargetRoot, [array]$Folders)
    $ErrorActionPreference = 'SilentlyContinue'
    $dest = Join-Path $TargetRoot "Backup_$(Get-Date -Format 'yyyy-MM-dd')"
    if (-not (Test-Path $dest)) { New-Item -ItemType Directory -Path $dest -Force | Out-Null }
    $log = Join-Path $dest 'Backup_Log.txt'
    $exclude = @('Cache','Temp','CrashDumps','GPUCache','Microsoft\Windows\INetCache')
    Write-Output "[*] Target: $dest"
    foreach ($f in $Folders) {
        $src = Join-Path $env:USERPROFILE $f
        if (-not (Test-Path $src)) { Write-Output "[INFO] Skip: $f (tidak ada)."; continue }
        Write-Output "[*] Robocopy: $f ..."
        $tgt = Join-Path $dest $f
        & robocopy $src $tgt /MIR /R:1 /W:1 /XD $exclude /LOG+:$log /NP /NJH /NJS | Out-Null
        if ($LASTEXITCODE -lt 8) { Write-Output "[OK] $f selesai." }
        else { Write-Output "[WARN] $f exit code $LASTEXITCODE (file terkunci)." }
    }
    Write-Output "[OK] Backup selesai. Log: $log"
    Write-Output "[DONE]"
}

function Execute-InstallApps {
    param([array]$Ids)
    $ErrorActionPreference = 'SilentlyContinue'
    foreach ($id in $Ids) {
        Write-Output "[*] Installing: $id"
        $out = & winget install --id $id --exact --silent --accept-source-agreements --accept-package-agreements 2>&1 | Out-String
        if ($LASTEXITCODE -eq 0) { Write-Output "[OK] $id terinstal." }
        else { Write-Output "[WARN] $id gagal (exit $LASTEXITCODE)." }
    }
    Write-Output "[DONE] Install Apps selesai."
}

function Execute-Tweaks {
    param([array]$Actions)
    $results = @()
    foreach ($act in $Actions) {
        try {
            switch ($act) {
                'Telemetry'   { Set-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' 'AllowTelemetry' 0 -Type DWord -EA Stop; Set-Service DiagTrack -StartupType Disabled -EA SilentlyContinue; Stop-Service DiagTrack -Force -EA SilentlyContinue; $results += '[OK] Telemetry disabled.' }
                'Activity'    { Set-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' 'EnableActivityFeed' 0 -Type DWord -EA Stop; $results += '[OK] Activity History disabled.' }
                'Consumer'    { Set-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' 'DisableWindowsConsumerFeatures' 1 -Type DWord -EA Stop; $results += '[OK] Consumer Features disabled.' }
                'Location'    { Set-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors' 'DisableLocation' 1 -Type DWord -EA Stop; $results += '[OK] Location Tracking disabled.' }
                'Hibernation' { Set-ItemProperty 'HKLM:\System\CurrentControlSet\Control\Session Manager\Power' 'HibernateEnabled' 0 -Type DWord -EA Stop; powercfg -h off; $results += '[OK] Hibernation disabled.' }
                'FileExt'     { Set-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'HideFileExt' 0 -Type DWord -EA Stop; $results += '[OK] File Extensions shown.' }
                'UltimatePerf'{ powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61; $results += '[OK] Ultimate Performance plan added.' }
                'BgApps'      { Set-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications' 'GlobalUserDisabled' 1 -Type DWord -EA Stop; $results += '[OK] Background Apps disabled.' }
                'Bing'        { Set-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search' 'BingSearchEnabled' 0 -Type DWord -EA Stop; $results += '[OK] Bing Search disabled.' }
                'GameBar'     { Set-ItemProperty 'HKCU:\Software\Microsoft\GameBar' 'AutoGameModeEnabled' 0 -Type DWord -EA Stop; $results += '[OK] Game Bar disabled.' }
                'StorageSense'{ Set-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy' '01' 0 -Type DWord -EA Stop; $results += '[OK] Storage Sense disabled.' }
                'IPv6'        { Set-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters' 'DisabledComponents' 255 -Type DWord -EA Stop; $results += '[OK] IPv6 disabled.' }
            }
        } catch { $results += "[ERROR] $act : $($_.Exception.Message)" }
    }
    $results | ForEach-Object { Write-Output $_ }
    Write-Output "[DONE] Tweaks selesai."
}

function Execute-Debloat {
    param([array]$Packages)
    foreach ($pkgName in $Packages) {
        try {
            $appx = Get-AppxPackage -Name $pkgName -AllUsers -EA Stop
            if ($appx) { Remove-AppxPackage -Package $appx.PackageFullName -AllUsers -Force -EA Stop; Write-Output "[OK] Removed: $pkgName" }
            else { Write-Output "[SKIP] Not found: $pkgName" }
        } catch { Write-Output "[ERROR] Gagal remove ${pkgName}: $($_.Exception.Message)" }
    }
    Write-Output "[DONE] Debloat selesai."
}

function Execute-RestorePointCreate {
    $ErrorActionPreference = 'SilentlyContinue'
    Write-Output "[*] Memastikan System Restore aktif di C:..."
    Enable-ComputerRestore -Drive "C:\" -EA SilentlyContinue
    Write-Output "[*] Membuat restore point..."
    Checkpoint-Computer -Description "Toolkit-$(Get-Date -Format 'yyyy-MM-dd-HHmmss')" -RestorePointType 'MODIFY_SETTINGS' -EA Stop
    Write-Output "[OK] Restore point dibuat."
    Write-Output "[DONE]"
}

function Execute-RestorePointRestore {
    param([int]$SequenceNumber)
    $ErrorActionPreference = 'SilentlyContinue'
    Write-Output "[*] Restoring ke restore point #$SequenceNumber (sistem akan restart)..."
    Restore-Computer -RestorePoint $SequenceNumber -Confirm:$false
    Write-Output "[OK] Perintah restore dikirim - sistem akan restart."
    Write-Output "[DONE]"
}

function Execute-UpdateAction {
    param([string]$Action)
    $ErrorActionPreference = 'SilentlyContinue'
    $key = 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings'
    if (-not (Test-Path $key)) { New-Item -Path $key -Force | Out-Null }
    switch ($Action) {
        '35days' {
            Set-ItemProperty $key 'FlightSettingsMaxPauseDays' 35 -Type DWord
            Set-ItemProperty $key 'PauseUpdatesExpiryTime' (Get-Date).AddDays(35).ToString('yyyy-MM-ddTHH:mm:ssZ')
            Write-Output "[OK] Update paused 35 hari."
        }
        '1year' {
            Set-ItemProperty $key 'FlightSettingsMaxPauseDays' 365 -Type DWord
            Set-ItemProperty $key 'PauseUpdatesExpiryTime' (Get-Date).AddDays(365).ToString('yyyy-MM-ddTHH:mm:ssZ')
            Write-Output "[OK] Update paused 1 tahun."
        }
        '50years' {
            Set-ItemProperty $key 'FlightSettingsMaxPauseDays' 18250 -Type DWord
            Set-ItemProperty $key 'PauseUpdatesExpiryTime' (Get-Date).AddYears(50).ToString('yyyy-MM-ddTHH:mm:ssZ')
            Write-Output "[OK] Update paused 50 tahun."
        }
        'resume' {
            Remove-ItemProperty $key 'PauseUpdatesExpiryTime' -EA SilentlyContinue
            Remove-ItemProperty $key 'FlightSettingsMaxPauseDays' -EA SilentlyContinue
            Write-Output "[OK] Update resumed."
        }
        'security' {
            Set-ItemProperty $key 'DeferFeatureUpdates' 1 -Type DWord
            Set-ItemProperty $key 'DeferFeatureUpdatesPeriodInDays' 365 -Type DWord
            Write-Output "[OK] Security-only mode aktif."
        }
    }
    Write-Output "[DONE]"
}

function Execute-DnsSwitch {
    param([string]$Provider)
    $ErrorActionPreference = 'SilentlyContinue'
    $adapters = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }
    if (-not $adapters) { Write-Output "[ERROR] Tidak ada adapter Up."; Write-Output "[DONE]"; return }
    $map = @{
        'cloudflare'         = @('1.1.1.1','1.0.0.1')
        'google'             = @('8.8.8.8','8.8.4.4')
        'quad9'              = @('9.9.9.9','149.112.112.112')
        'adguard'            = @('94.140.14.14','94.140.15.15')
        'opendns'            = @('208.67.222.222','208.67.220.220')
        'cloudflare-malware' = @('1.1.1.2','1.0.0.2')
    }
    if ($Provider -eq 'dhcp') {
        foreach ($a in $adapters) { Set-DnsClientServerAddress -InterfaceIndex $a.ifIndex -ResetServerAddresses }
        Write-Output "[OK] DNS kembali ke DHCP (otomatis)."
    } elseif ($map.ContainsKey($Provider)) {
        $servers = $map[$Provider]
        foreach ($a in $adapters) { Set-DnsClientServerAddress -InterfaceIndex $a.ifIndex -ServerAddresses $servers }
        Write-Output "[OK] DNS diubah ke $Provider ($($servers -join ', '))."
    } else { Write-Output "[ERROR] Provider tidak dikenal: $Provider" }
    Clear-DnsClientCache -EA SilentlyContinue
    Write-Output "[OK] DNS Cache dibersihkan."
    Write-Output "[DONE]"
}

function Execute-OneClickFix {
    param([string]$Fix)
    $ErrorActionPreference = 'SilentlyContinue'
    switch ($Fix) {
        'network' {
            Write-Output "[*] Reset network stack..."
            netsh winsock reset | Out-Null
            netsh int ip reset | Out-Null
            ipconfig /flushdns | Out-Null
            Write-Output "[OK] Network reset - disarankan restart."
        }
        'update' {
            Write-Output "[*] Reset Windows Update cache..."
            Stop-Service wuauserv,cryptSvc,bits,msiserver -Force -EA SilentlyContinue
            Remove-Item 'C:\Windows\SoftwareDistribution\*' -Recurse -Force -EA SilentlyContinue
            Start-Service wuauserv,cryptSvc,bits,msiserver -EA SilentlyContinue
            Write-Output "[OK] Update cache reset."
        }
        'repair' {
            Write-Output "[*] SFC /scannow..."
            & sfc.exe /scannow 2>&1 | ForEach-Object { Write-Output "   $_" }
            Write-Output "[*] DISM /RestoreHealth..."
            & dism.exe /Online /Cleanup-Image /RestoreHealth 2>&1 | ForEach-Object { Write-Output "   $_" }
            Write-Output "[OK] Repair system selesai."
        }
    }
    Write-Output "[DONE]"
}

function Execute-StartupDisable {
    param([string]$Type, [string]$Name, [string]$Command, [string]$Location)
    $ErrorActionPreference = 'SilentlyContinue'
    switch ($Type) {
        'Registry' {
            Remove-ItemProperty -Path $Location -Name $Name -EA Stop
            Write-Output "[OK] Registry item '$Name' dihapus."
        }
        'Folder' {
            $safe = Join-Path $env:USERPROFILE "Desktop\DisabledStartup"
            if (-not (Test-Path $safe)) { New-Item -ItemType Directory -Path $safe -Force | Out-Null }
            Move-Item -Path $Command -Destination $safe -Force -EA Stop
            Write-Output "[OK] Shortcut '$Name' dipindah ke Desktop\DisabledStartup."
        }
        'Task' {
            Disable-ScheduledTask -TaskName $Name -EA Stop | Out-Null
            Write-Output "[OK] Task Scheduler '$Name' dinonaktifkan."
        }
    }
    Write-Output "[DONE]"
}

function Execute-StartupEnable {
    param([string]$Type, [string]$Name, [string]$Location)
    $ErrorActionPreference = 'SilentlyContinue'
    switch ($Type) {
        'Task' { Enable-ScheduledTask -TaskName $Name -EA Stop | Out-Null; Write-Output "[OK] Task '$Name' diaktifkan." }
        default { Write-Output "[INFO] Enable otomatis hanya untuk Task Scheduler. Item '$Name' perlu di-restore manual." }
    }
    Write-Output "[DONE]"
}

function Execute-Preset {
    param([string]$Name)
    $ErrorActionPreference = 'SilentlyContinue'
    $apps = @()
    switch ($Name) {
        'standard'  { $apps = @('Google.Chrome','7zip.7zip','VideoLAN.VLC','Notepad++.Notepad++'); Write-Output "[*] Preset: Standard" }
        'gamer'     { $apps = @('Valve.Steam','Discord.Discord','OBSProject.OBSStudio','EpicGames.EpicGamesLauncher'); Write-Output "[*] Preset: Gamer" }
        'developer' { $apps = @('Microsoft.VisualStudioCode','Git.Git','Python.Python.3.12','Microsoft.PowerToys','Microsoft.WindowsTerminal'); Write-Output "[*] Preset: Developer" }
        'minimalist'{ $apps = @(); Write-Output "[*] Preset: Minimalist (hanya tweaks)" }
    }
    if ($apps.Count -gt 0) {
        foreach ($id in $apps) {
            Write-Output "[*] Installing: $id"
            & winget install --id $id --exact --silent --accept-source-agreements --accept-package-agreements 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) { Write-Output "[OK] $id terinstal." } else { Write-Output "[WARN] $id gagal." }
        }
    }
    Write-Output "[DONE] Preset '$Name' selesai."
}

function Execute-AppBackupExport {
    $ErrorActionPreference = 'SilentlyContinue'
    $file = Join-Path $env:USERPROFILE 'Desktop\MyAppsBackup.json'
    Write-Output "[*] Export aplikasi ke $file ..."
    & winget export -o $file --accept-source-agreements 2>&1 | ForEach-Object { Write-Output "   $_" }
    if (Test-Path $file) { Write-Output "[OK] Backup tersimpan di: $file" } else { Write-Output "[ERROR] File tidak dibuat." }
    Write-Output "[DONE]"
}

function Execute-AppBackupImport {
    param([string]$Path)
    $ErrorActionPreference = 'SilentlyContinue'
    if (-not (Test-Path $Path)) { Write-Output "[ERROR] File tidak ditemukan: $Path"; Write-Output "[DONE]"; return }
    Write-Output "[*] Import dari $Path ..."
    & winget import -i $Path --accept-source-agreements --accept-package-agreements 2>&1 | ForEach-Object { Write-Output "   $_" }
    Write-Output "[OK] Import selesai."
    Write-Output "[DONE]"
}

function Show-MaintenanceDialog {
    $win = New-DarkWindow -Title 'Pure Clean - Maintenance' -Width 540 -Height 560
    $grid = New-Object System.Windows.Controls.Grid
    $grid.Margin = '15'
    for ($i=0; $i -lt 3; $i++) { $grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition)) }
    $grid.RowDefinitions[0].Height = 'Auto'
    $grid.RowDefinitions[1].Height = '*'
    $grid.RowDefinitions[2].Height = 'Auto'

    $title = New-Object System.Windows.Controls.TextBlock
    $title.Text = 'Pilih tindakan pembersihan yang ingin dijalankan:'
    $title.Foreground = [System.Windows.Media.Brushes]::White
    $title.Margin = '0,0,0,10'
    [System.Windows.Controls.Grid]::SetRow($title, 0)
    $grid.Children.Add($title) | Out-Null

    $scroll = New-Object System.Windows.Controls.ScrollViewer
    $scroll.VerticalScrollBarVisibility = 'Auto'
    $panel = New-Object System.Windows.Controls.StackPanel
    $panel.Margin = '0,5'

    $actions = @(
        @{Tag='DnsCache';     Label='Bersihkan DNS Cache'},
        @{Tag='IpReset';      Label='Release + Renew IP Address'},
        @{Tag='UserTemp';     Label='Bersihkan %TEMP% (user)'},
        @{Tag='WindowsTemp';  Label='Bersihkan C:\Windows\Temp'},
        @{Tag='Prefetch';     Label='Bersihkan Prefetch'},
        @{Tag='UpdateCache';  Label='Bersihkan Windows Update Cache'},
        @{Tag='CleanMgr';     Label='Jalankan Disk Cleanup (cleanmgr)'},
        @{Tag='DismCleanup';  Label='DISM Component Cleanup (5-10 menit)'},
        @{Tag='SFC';          Label='SFC /scannow (5-15 menit)'},
        @{Tag='DismRestore';  Label='DISM RestoreHealth (10-20 menit)'},
        @{Tag='OptimizeDisk'; Label='ReTrim / Defrag Drive C:'}
    )
    $checkboxes = @()
    foreach ($a in $actions) {
        $cb = New-DarkCheckBox -Text $a.Label -Tag $a.Tag
        $panel.Children.Add($cb) | Out-Null
        $checkboxes += $cb
    }
    $scroll.Content = $panel
    [System.Windows.Controls.Grid]::SetRow($scroll, 1)
    $grid.Children.Add($scroll) | Out-Null

    $btnPanel = New-Object System.Windows.Controls.StackPanel
    $btnPanel.Orientation = 'Horizontal'
    $btnPanel.HorizontalAlignment = 'Right'
    $btnAll = New-DarkButton -Text 'Pilih Semua' -Bg '#555555'
    $btnRun = New-DarkButton -Text 'Jalankan' -Bg '#0078D7'
    $btnCancel = New-DarkButton -Text 'Batal' -Bg '#555555'
    $btnAll.Add_Click({ foreach ($c in $checkboxes) { $c.IsChecked = $true } }.GetNewClosure())
    $btnCancel.Add_Click({ $win.Close() }.GetNewClosure())
    $btnRun.Add_Click({
        $selected = @()
        foreach ($c in $checkboxes) { if ($c.IsChecked -eq $true) { $selected += $c.Tag } }
        if ($selected.Count -eq 0) { [System.Windows.MessageBox]::Show('Pilih minimal satu tindakan.','Info'); return }
        $win.Close()
        Invoke-GuiJob -ScriptBlock ${function:Execute-Maintenance} -ArgumentList (,$selected) -StartMessage "[*] Maintenance dimulai (${($selected.Count)} tindakan)..." -DoneMessage "[OK] Maintenance selesai."
    }.GetNewClosure())
    $btnPanel.Children.Add($btnAll) | Out-Null
    $btnPanel.Children.Add($btnCancel) | Out-Null
    $btnPanel.Children.Add($btnRun) | Out-Null
    [System.Windows.Controls.Grid]::SetRow($btnPanel, 2)
    $grid.Children.Add($btnPanel) | Out-Null

    $win.Content = $grid
    $win.ShowDialog() | Out-Null
}

function Show-UserBackupDialog {
    $win = New-DarkWindow -Title 'User Backup' -Width 560 -Height 560
    $grid = New-Object System.Windows.Controls.Grid
    $grid.Margin = '15'
    for ($i=0; $i -lt 4; $i++) { $grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition)) }
    $grid.RowDefinitions[0].Height = 'Auto'
    $grid.RowDefinitions[1].Height = 'Auto'
    $grid.RowDefinitions[2].Height = '*'
    $grid.RowDefinitions[3].Height = 'Auto'

    $pathLabel = New-Object System.Windows.Controls.TextBlock
    $pathLabel.Text = 'Target folder:'
    $pathLabel.Foreground = [System.Windows.Media.Brushes]::White
    [System.Windows.Controls.Grid]::SetRow($pathLabel, 0)
    $grid.Children.Add($pathLabel) | Out-Null

    $pathPanel = New-Object System.Windows.Controls.StackPanel
    $pathPanel.Orientation = 'Horizontal'
    $txtPath = New-Object System.Windows.Controls.TextBox
    $txtPath.Text = 'D:\Backup_PC'
    $txtPath.Width = 380
    $txtPath.Height = 28
    $txtPath.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#2D2D30')
    $txtPath.Foreground = [System.Windows.Media.Brushes]::White
    $btnBrowse = New-DarkButton -Text '...' -Width 40 -Bg '#555555'
    $btnBrowse.Add_Click({
        $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
        if ($dlg.ShowDialog() -eq 'OK') { $txtPath.Text = $dlg.SelectedPath }
    }.GetNewClosure())
    $pathPanel.Children.Add($txtPath) | Out-Null
    $pathPanel.Children.Add($btnBrowse) | Out-Null
    [System.Windows.Controls.Grid]::SetRow($pathPanel, 1)
    $grid.Children.Add($pathPanel) | Out-Null

    $folderLabel = New-Object System.Windows.Controls.TextBlock
    $folderLabel.Text = 'Folder yang akan di-backup:'
    $folderLabel.Foreground = [System.Windows.Media.Brushes]::White
    $folderLabel.Margin = '0,15,0,5'
    $scroll = New-Object System.Windows.Controls.ScrollViewer
    $panel = New-Object System.Windows.Controls.StackPanel
    $folders = @('Documents','Pictures','Desktop','Downloads','Music','Videos','AppData\Roaming','AppData\Local\Packages')
    $cbs = @()
    foreach ($f in $folders) {
        $cb = New-DarkCheckBox -Text $f -IsChecked $true -Tag $f
        $panel.Children.Add($cb) | Out-Null
        $cbs += $cb
    }
    $scroll.Content = $panel
    $folderWrap = New-Object System.Windows.Controls.StackPanel
    $folderWrap.Children.Add($folderLabel) | Out-Null
    $folderWrap.Children.Add($scroll) | Out-Null
    [System.Windows.Controls.Grid]::SetRow($folderWrap, 2)
    $grid.Children.Add($folderWrap) | Out-Null

    $btnPanel = New-Object System.Windows.Controls.StackPanel
    $btnPanel.Orientation = 'Horizontal'
    $btnPanel.HorizontalAlignment = 'Right'
    $btnRun = New-DarkButton -Text 'Mulai Backup' -Bg '#0078D7'
    $btnCancel = New-DarkButton -Text 'Batal' -Bg '#555555'
    $btnCancel.Add_Click({ $win.Close() }.GetNewClosure())
    $btnRun.Add_Click({
        $selected = @()
        foreach ($c in $cbs) { if ($c.IsChecked -eq $true) { $selected += $c.Tag } }
        if ($selected.Count -eq 0) { [System.Windows.MessageBox]::Show('Pilih minimal satu folder.','Info'); return }
        if ([string]::IsNullOrWhiteSpace($txtPath.Text)) { [System.Windows.MessageBox]::Show('Isi target folder.','Info'); return }
        $target = $txtPath.Text
        $win.Close()
        Invoke-GuiJob -ScriptBlock ${function:Execute-UserBackup} -ArgumentList @($target, $selected) -StartMessage "[*] Backup user profile ke $target ..." -DoneMessage "[OK] User backup selesai."
    }.GetNewClosure())
    $btnPanel.Children.Add($btnCancel) | Out-Null
    $btnPanel.Children.Add($btnRun) | Out-Null
    [System.Windows.Controls.Grid]::SetRow($btnPanel, 3)
    $grid.Children.Add($btnPanel) | Out-Null

    $win.Content = $grid
    $win.ShowDialog() | Out-Null
}

function Show-AppBackupDialog {
    $win = New-DarkWindow -Title 'App Backup' -Width 480 -Height 300
    $grid = New-Object System.Windows.Controls.Grid
    $grid.Margin = '20'
    for ($i=0; $i -lt 3; $i++) { $grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition)) }
    $grid.RowDefinitions[0].Height = 'Auto'
    $grid.RowDefinitions[1].Height = 'Auto'
    $grid.RowDefinitions[2].Height = 'Auto'

    $info = New-Object System.Windows.Controls.TextBlock
    $info.Text = 'Export daftar aplikasi ke JSON, atau import dan install ulang dari file JSON.'
    $info.TextWrapping = 'Wrap'
    $info.Foreground = [System.Windows.Media.Brushes]::White
    [System.Windows.Controls.Grid]::SetRow($info, 0)
    $grid.Children.Add($info) | Out-Null

    $btnExport = New-DarkButton -Text 'Export ke Desktop' -Width 200 -Bg '#0078D7'
    $btnImport = New-DarkButton -Text 'Import dari File' -Width 200 -Bg '#107C10'
    $btnExport.Add_Click({
        $win.Close()
        Invoke-GuiJob -ScriptBlock ${function:Execute-AppBackupExport} -ArgumentList @() -StartMessage '[*] Export daftar aplikasi...' -DoneMessage '[OK] Export selesai.'
    }.GetNewClosure())
    $btnImport.Add_Click({
        $dlg = New-Object System.Windows.Forms.OpenFileDialog
        $dlg.Filter = 'JSON|*.json'
        if ($dlg.ShowDialog() -eq 'OK') {
            $p = $dlg.FileName
            $win.Close()
            Invoke-GuiJob -ScriptBlock ${function:Execute-AppBackupImport} -ArgumentList @($p) -StartMessage "[*] Import dari $p ..." -DoneMessage '[OK] Import selesai.'
        }
    }.GetNewClosure())

    $wrap = New-Object System.Windows.Controls.WrapPanel
    $wrap.HorizontalAlignment = 'Center'
    $wrap.Children.Add($btnExport) | Out-Null
    $wrap.Children.Add($btnImport) | Out-Null
    [System.Windows.Controls.Grid]::SetRow($wrap, 1)
    $grid.Children.Add($wrap) | Out-Null

    $btnClose = New-DarkButton -Text 'Tutup' -Bg '#555555'
    $btnClose.Add_Click({ $win.Close() }.GetNewClosure())
    $btnPanel = New-Object System.Windows.Controls.StackPanel
    $btnPanel.HorizontalAlignment = 'Right'
    $btnPanel.Children.Add($btnClose) | Out-Null
    [System.Windows.Controls.Grid]::SetRow($btnPanel, 2)
    $grid.Children.Add($btnPanel) | Out-Null

    $win.Content = $grid
    $win.ShowDialog() | Out-Null
}

function Show-RestorePointDialog {
    $win = New-DarkWindow -Title 'System Restore Point' -Width 700 -Height 520
    $grid = New-Object System.Windows.Controls.Grid
    $grid.Margin = '15'
    for ($i=0; $i -lt 3; $i++) { $grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition)) }
    $grid.RowDefinitions[0].Height = 'Auto'
    $grid.RowDefinitions[1].Height = '*'
    $grid.RowDefinitions[2].Height = 'Auto'

    $lbl = New-Object System.Windows.Controls.TextBlock
    $lbl.Text = 'Restore Point yang tersedia:'
    $lbl.Foreground = [System.Windows.Media.Brushes]::White
    [System.Windows.Controls.Grid]::SetRow($lbl, 0)
    $grid.Children.Add($lbl) | Out-Null

    $list = New-Object System.Windows.Controls.ListView
    $list.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#2D2D30')
    $list.Foreground = [System.Windows.Media.Brushes]::White
    $gv = New-Object System.Windows.Controls.GridView
    foreach ($col in @('SequenceNumber','Description','CreationTime')) {
        $gvc = New-Object System.Windows.Controls.GridViewColumn
        $gvc.Header = $col
        $gvc.DisplayMemberBinding = New-Object System.Windows.Data.Binding($col)
        $gvc.Width = 200
        $gv.Columns.Add($gvc) | Out-Null
    }
    $list.View = $gv
    [System.Windows.Controls.Grid]::SetRow($list, 1)
    $grid.Children.Add($list) | Out-Null

    $btnPanel = New-Object System.Windows.Controls.StackPanel
    $btnPanel.Orientation = 'Horizontal'
    $btnPanel.HorizontalAlignment = 'Right'
    $btnRefresh = New-DarkButton -Text 'Refresh' -Bg '#555555'
    $btnCreate  = New-DarkButton -Text 'Buat Baru' -Bg '#0078D7'
    $btnRestore = New-DarkButton -Text 'Restore Pilihan' -Bg '#D83B01'
    $btnClose   = New-DarkButton -Text 'Tutup' -Bg '#555555'

    $btnRefresh.Add_Click({
        $list.Items.Clear()
        Get-ComputerRestorePoint -EA SilentlyContinue | ForEach-Object {
            $list.Items.Add([PSCustomObject]@{SequenceNumber=$_.SequenceNumber; Description=$_.Description; CreationTime=$_.ConvertToDateTime($_.CreationTime)})
        } | Out-Null
    }.GetNewClosure())
    $btnCreate.Add_Click({
        $win.Close()
        Invoke-GuiJob -ScriptBlock ${function:Execute-RestorePointCreate} -ArgumentList @() -StartMessage '[*] Membuat restore point...' -DoneMessage '[OK] Restore point dibuat.'
    }.GetNewClosure())
    $btnRestore.Add_Click({
        if (-not $list.SelectedItem) { [System.Windows.MessageBox]::Show('Pilih restore point dulu.','Info'); return }
        $seq = $list.SelectedItem.SequenceNumber
        $ans = [System.Windows.MessageBox]::Show("Restore ke #$seq ? Sistem akan restart.", 'Konfirmasi', 'YesNo')
        if ($ans -eq 'Yes') {
            $win.Close()
            Invoke-GuiJob -ScriptBlock ${function:Execute-RestorePointRestore} -ArgumentList @($seq) -StartMessage "[*] Restore ke #$seq ..." -DoneMessage '[OK] Restore diproses.'
        }
    }.GetNewClosure())
    $btnClose.Add_Click({ $win.Close() }.GetNewClosure())
    $btnPanel.Children.Add($btnRefresh) | Out-Null
    $btnPanel.Children.Add($btnCreate)  | Out-Null
    $btnPanel.Children.Add($btnRestore) | Out-Null
    $btnPanel.Children.Add($btnClose)   | Out-Null
    [System.Windows.Controls.Grid]::SetRow($btnPanel, 2)
    $grid.Children.Add($btnPanel) | Out-Null

    $win.Content = $grid
    $win.ShowDialog() | Out-Null
}

function Show-UpdateManagerDialog {
    $win = New-DarkWindow -Title 'Windows Update Manager' -Width 500 -Height 380
    $stack = New-Object System.Windows.Controls.StackPanel
    $stack.Margin = '20'
    $lbl = New-Object System.Windows.Controls.TextBlock
    $lbl.Text = 'Pilih aksi untuk Windows Update:'
    $lbl.Foreground = [System.Windows.Media.Brushes]::White
    $lbl.Margin = '0,0,0,15'
    $stack.Children.Add($lbl) | Out-Null

    $rbGroup = New-Object System.Windows.Controls.StackPanel
    $opts = @(
        @{Tag='35days';  Label='Pause 35 hari'},
        @{Tag='1year';   Label='Pause 1 tahun'},
        @{Tag='50years'; Label='Pause 50 tahun (ekstrem)'},
        @{Tag='resume';  Label='Resume Updates (aktifkan kembali)'},
        @{Tag='security';Label='Security Updates Only (tunda fitur baru)'}
    )
    $rbs = @()
    $groupName = "UpdateGroup_$([guid]::NewGuid())"
    foreach ($o in $opts) {
        $rb = New-Object System.Windows.Controls.RadioButton
        $rb.Content = $o.Label
        $rb.Tag = $o.Tag
        $rb.GroupName = $groupName
        $rb.Foreground = [System.Windows.Media.Brushes]::White
        $rb.Margin = '0,5,0,5'
        $rbGroup.Children.Add($rb) | Out-Null
        $rbs += $rb
    }
    $stack.Children.Add($rbGroup) | Out-Null

    $btnPanel = New-Object System.Windows.Controls.StackPanel
    $btnPanel.Orientation = 'Horizontal'
    $btnPanel.HorizontalAlignment = 'Right'
    $btnApply = New-DarkButton -Text 'Terapkan' -Bg '#0078D7'
    $btnCancel = New-DarkButton -Text 'Batal' -Bg '#555555'
    $btnCancel.Add_Click({ $win.Close() }.GetNewClosure())
    $btnApply.Add_Click({
        $sel = $null
        foreach ($r in $rbs) { if ($r.IsChecked -eq $true) { $sel = $r.Tag; break } }
        if (-not $sel) { [System.Windows.MessageBox]::Show('Pilih satu opsi.','Info'); return }
        $win.Close()
        Invoke-GuiJob -ScriptBlock ${function:Execute-UpdateAction} -ArgumentList @($sel) -StartMessage "[*] Update Manager: $sel" -DoneMessage '[OK] Aksi diterapkan.'
    }.GetNewClosure())
    $btnPanel.Children.Add($btnCancel) | Out-Null
    $btnPanel.Children.Add($btnApply) | Out-Null
    $stack.Children.Add($btnPanel) | Out-Null

    $win.Content = $stack
    $win.ShowDialog() | Out-Null
}

function Show-DnsSwitcherDialog {
    $win = New-DarkWindow -Title 'DNS Switcher' -Width 480 -Height 280
    $stack = New-Object System.Windows.Controls.StackPanel
    $stack.Margin = '20'
    $lbl = New-Object System.Windows.Controls.TextBlock
    $lbl.Text = 'Pilih DNS provider:'
    $lbl.Foreground = [System.Windows.Media.Brushes]::White
    $lbl.Margin = '0,0,0,10'
    $stack.Children.Add($lbl) | Out-Null

    $combo = New-Object System.Windows.Controls.ComboBox
    $combo.Width = 400
    $combo.Height = 30
    $opts = @(
        @{Tag='cloudflare'; Label='Cloudflare (1.1.1.1) - cepat & privasi'},
        @{Tag='google';     Label='Google (8.8.8.8) - stabil'},
        @{Tag='quad9';      Label='Quad9 (9.9.9.9) - blokir malware'},
        @{Tag='adguard';    Label='AdGuard (94.140.14.14) - blokir iklan'},
        @{Tag='opendns';    Label='OpenDNS (208.67.222.222)'},
        @{Tag='cloudflare-malware'; Label='Cloudflare Malware (1.1.1.2)'},
        @{Tag='dhcp';       Label='Reset ke DHCP (otomatis)'}
    )
    foreach ($o in $opts) {
        $item = New-Object System.Windows.Controls.ComboBoxItem
        $item.Content = $o.Label
        $item.Tag = $o.Tag
        $combo.Items.Add($item) | Out-Null
    }
    $combo.SelectedIndex = 0
    $stack.Children.Add($combo) | Out-Null

    $btnPanel = New-Object System.Windows.Controls.StackPanel
    $btnPanel.Orientation = 'Horizontal'
    $btnPanel.HorizontalAlignment = 'Right'
    $btnPanel.Margin = '0,20,0,0'
    $btnApply = New-DarkButton -Text 'Terapkan' -Bg '#0078D7'
    $btnCancel = New-DarkButton -Text 'Batal' -Bg '#555555'
    $btnCancel.Add_Click({ $win.Close() }.GetNewClosure())
    $btnApply.Add_Click({
        $tag = $combo.SelectedItem.Tag
        if (-not $tag) { return }
        $win.Close()
        Invoke-GuiJob -ScriptBlock ${function:Execute-DnsSwitch} -ArgumentList @($tag) -StartMessage "[*] Ganti DNS ke $tag ..." -DoneMessage '[OK] DNS diubah.'
    }.GetNewClosure())
    $btnPanel.Children.Add($btnCancel) | Out-Null
    $btnPanel.Children.Add($btnApply) | Out-Null
    $stack.Children.Add($btnPanel) | Out-Null

    $win.Content = $stack
    $win.ShowDialog() | Out-Null
}

function Show-OneClickFixesDialog {
    $win = New-DarkWindow -Title 'One-Click Fixes' -Width 500 -Height 280
    $stack = New-Object System.Windows.Controls.StackPanel
    $stack.Margin = '20'
    $lbl = New-Object System.Windows.Controls.TextBlock
    $lbl.Text = 'Pilih perbaikan yang ingin dijalankan:'
    $lbl.Foreground = [System.Windows.Media.Brushes]::White
    $lbl.Margin = '0,0,0,10'
    $stack.Children.Add($lbl) | Out-Null

    $cbs = @()
    $opts = @(
        @{Tag='network'; Label='Reset Network Stack (Winsock + IP + DNS)'},
        @{Tag='update';  Label='Reset Windows Update Cache'},
        @{Tag='repair';  Label='Repair System (SFC + DISM) - 10-25 menit'}
    )
    foreach ($o in $opts) {
        $cb = New-DarkCheckBox -Text $o.Label -Tag $o.Tag
        $stack.Children.Add($cb) | Out-Null
        $cbs += $cb
    }

    $btnPanel = New-Object System.Windows.Controls.StackPanel
    $btnPanel.Orientation = 'Horizontal'
    $btnPanel.HorizontalAlignment = 'Right'
    $btnPanel.Margin = '0,15,0,0'
    $btnRun = New-DarkButton -Text 'Jalankan' -Bg '#0078D7'
    $btnCancel = New-DarkButton -Text 'Batal' -Bg '#555555'
    $btnCancel.Add_Click({ $win.Close() }.GetNewClosure())
    $btnRun.Add_Click({
        $selected = @()
        foreach ($c in $cbs) { if ($c.IsChecked -eq $true) { $selected += $c.Tag } }
        if ($selected.Count -eq 0) { [System.Windows.MessageBox]::Show('Pilih minimal satu perbaikan.','Info'); return }
        $win.Close()
        foreach ($fix in $selected) {
            Invoke-GuiJob -ScriptBlock ${function:Execute-OneClickFix} -ArgumentList @($fix) -StartMessage "[*] Menjalankan fix: $fix ..." -DoneMessage "[OK] Fix '$fix' selesai."
        }
    }.GetNewClosure())
    $btnPanel.Children.Add($btnCancel) | Out-Null
    $btnPanel.Children.Add($btnRun) | Out-Null
    $stack.Children.Add($btnPanel) | Out-Null

    $win.Content = $stack
    $win.ShowDialog() | Out-Null
}

function Show-StartupManagerDialog {
    $win = New-DarkWindow -Title 'Startup Manager' -Width 800 -Height 560
    $grid = New-Object System.Windows.Controls.Grid
    $grid.Margin = '15'
    for ($i=0; $i -lt 3; $i++) { $grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition)) }
    $grid.RowDefinitions[0].Height = 'Auto'
    $grid.RowDefinitions[1].Height = '*'
    $grid.RowDefinitions[2].Height = 'Auto'

    $lbl = New-Object System.Windows.Controls.TextBlock
    $lbl.Text = 'Startup items (Registry + Folder + Task Scheduler):'
    $lbl.Foreground = [System.Windows.Media.Brushes]::White
    [System.Windows.Controls.Grid]::SetRow($lbl, 0)
    $grid.Children.Add($lbl) | Out-Null

    $list = New-Object System.Windows.Controls.ListView
    $list.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#2D2D30')
    $list.Foreground = [System.Windows.Media.Brushes]::White
    $gv = New-Object System.Windows.Controls.GridView
    foreach ($col in @('Name','Type','Status','Command')) {
        $gvc = New-Object System.Windows.Controls.GridViewColumn
        $gvc.Header = $col
        $gvc.DisplayMemberBinding = New-Object System.Windows.Data.Binding($col)
        $gvc.Width = if ($col -eq 'Command') { 300 } else { 120 }
        $gv.Columns.Add($gvc) | Out-Null
    }
    $list.View = $gv
    [System.Windows.Controls.Grid]::SetRow($list, 1)
    $grid.Children.Add($list) | Out-Null

    $btnPanel = New-Object System.Windows.Controls.StackPanel
    $btnPanel.Orientation = 'Horizontal'
    $btnPanel.HorizontalAlignment = 'Right'
    $btnRefresh = New-DarkButton -Text 'Refresh' -Bg '#555555'
    $btnDisable = New-DarkButton -Text 'Disable' -Bg '#D83B01'
    $btnEnable  = New-DarkButton -Text 'Enable (Task)' -Bg '#107C10'
    $btnClose   = New-DarkButton -Text 'Tutup' -Bg '#555555'

    $loadItems = {
        $list.Items.Clear()
        @('HKCU:\Software\Microsoft\Windows\CurrentVersion\Run','HKLM:\Software\Microsoft\Windows\CurrentVersion\Run') | ForEach-Object {
            if (Test-Path $_) {
                $props = Get-ItemProperty -Path $_
                $props.PSObject.Properties | Where-Object { $_.Name -notmatch '^PS' } | ForEach-Object {
                    $list.Items.Add([PSCustomObject]@{Name=$_.Name; Type='Registry'; Status='Enabled'; Command=$_.Value; Location=$_}) | Out-Null
                }
            }
        }
        $startupFolder = [Environment]::GetFolderPath('Startup')
        if (Test-Path $startupFolder) {
            Get-ChildItem $startupFolder -File -EA SilentlyContinue | ForEach-Object {
                $list.Items.Add([PSCustomObject]@{Name=$_.Name; Type='Folder'; Status='Enabled'; Command=$_.FullName; Location=$startupFolder}) | Out-Null
            }
        }
        Get-ScheduledTask -EA SilentlyContinue | Where-Object { $_.State -ne 'Disabled' -and $_.TaskPath -like '\*' -and $_.TaskName -notlike 'Microsoft*' } | Select-Object -First 30 | ForEach-Object {
            $list.Items.Add([PSCustomObject]@{Name=$_.TaskName; Type='Task'; Status=$_.State.ToString(); Command=''; Location=$_.TaskPath}) | Out-Null
        }
    }.GetNewClosure()
    & $loadItems

    $btnRefresh.Add_Click($loadItems)
    $btnDisable.Add_Click({
        if (-not $list.SelectedItem) { return }
        $item = $list.SelectedItem
        if ($item.Type -eq 'Registry') {
            Invoke-GuiJob -ScriptBlock ${function:Execute-StartupDisable} -ArgumentList @($item.Type, $item.Name, $item.Command, "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run") -StartMessage "[*] Disable $($item.Name) ..." -DoneMessage '[OK] Disabled.'
        } elseif ($item.Type -eq 'Folder') {
            Invoke-GuiJob -ScriptBlock ${function:Execute-StartupDisable} -ArgumentList @($item.Type, $item.Name, $item.Command, $item.Location) -StartMessage "[*] Disable $($item.Name) ..." -DoneMessage '[OK] Disabled.'
        } else {
            Invoke-GuiJob -ScriptBlock ${function:Execute-StartupDisable} -ArgumentList @($item.Type, $item.Name, '', $item.Location) -StartMessage "[*] Disable task $($item.Name) ..." -DoneMessage '[OK] Disabled.'
        }
    }.GetNewClosure())
    $btnEnable.Add_Click({
        if (-not $list.SelectedItem) { return }
        $item = $list.SelectedItem
        if ($item.Type -ne 'Task') { [System.Windows.MessageBox]::Show('Enable otomatis hanya untuk Task Scheduler.','Info'); return }
        Invoke-GuiJob -ScriptBlock ${function:Execute-StartupEnable} -ArgumentList @($item.Type, $item.Name, $item.Location) -StartMessage "[*] Enable $($item.Name) ..." -DoneMessage '[OK] Enabled.'
    }.GetNewClosure())
    $btnClose.Add_Click({ $win.Close() }.GetNewClosure())

    $btnPanel.Children.Add($btnRefresh) | Out-Null
    $btnPanel.Children.Add($btnDisable) | Out-Null
    $btnPanel.Children.Add($btnEnable)  | Out-Null
    $btnPanel.Children.Add($btnClose)   | Out-Null
    [System.Windows.Controls.Grid]::SetRow($btnPanel, 2)
    $grid.Children.Add($btnPanel) | Out-Null

    $win.Content = $grid
    $win.ShowDialog() | Out-Null
}

function Show-PresetsDialog {
    $win = New-DarkWindow -Title 'Automation Presets' -Width 500 -Height 340
    $stack = New-Object System.Windows.Controls.StackPanel
    $stack.Margin = '20'
    $lbl = New-Object System.Windows.Controls.TextBlock
    $lbl.Text = 'Pilih preset otomatisasi:'
    $lbl.Foreground = [System.Windows.Media.Brushes]::White
    $lbl.Margin = '0,0,0,10'
    $stack.Children.Add($lbl) | Out-Null

    $desc = New-Object System.Windows.Controls.TextBlock
    $desc.Text = "Standard : Chrome, 7-Zip, VLC, Notepad++`nGamer    : Steam, Discord, OBS, Epic`nDeveloper: VS Code, Git, Python, PowerToys, Terminal`nMinimalist: tanpa install app (hanya tweaks)"
    $desc.Foreground = [System.Windows.Media.Brushes]::LightGray
    $desc.Margin = '0,0,0,15'
    $stack.Children.Add($desc) | Out-Null

    $btnPanel = New-Object System.Windows.Controls.WrapPanel
    $btnPanel.HorizontalAlignment = 'Center'
    $presets = @(
        @{Tag='standard';   Label='Standard'},
        @{Tag='gamer';      Label='Gamer'},
        @{Tag='developer';  Label='Developer'},
        @{Tag='minimalist'; Label='Minimalist'}
    )
    foreach ($p in $presets) {
        $btn = New-DarkButton -Text $p.Label -Bg '#0078D7'
        $btn.Tag = $p.Tag
        $btn.Add_Click({
            $tag = $this.Tag
            $win.Close()
            Invoke-GuiJob -ScriptBlock ${function:Execute-Preset} -ArgumentList @($tag) -StartMessage "[*] Preset $tag ..." -DoneMessage "[OK] Preset '$tag' selesai."
        }.GetNewClosure())
        $btnPanel.Children.Add($btn) | Out-Null
    }
    $stack.Children.Add($btnPanel) | Out-Null

    $btnCancel = New-DarkButton -Text 'Batal' -Bg '#555555'
    $btnCancel.HorizontalAlignment = 'Right'
    $btnCancel.Margin = '0,15,0,0'
    $btnCancel.Add_Click({ $win.Close() }.GetNewClosure())
    $stack.Children.Add($btnCancel) | Out-Null

    $win.Content = $stack
    $win.ShowDialog() | Out-Null
}

function Show-GUI {
    [xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="PowerShell Admin Toolkit v6.0.0" Height="900" Width="1180"
        WindowStartupLocation="CenterScreen" Background="#1E1E1E" Foreground="White">
  <Grid>
    <Grid.RowDefinitions>
      <RowDefinition Height="60"/>
      <RowDefinition Height="*"/>
      <RowDefinition Height="260"/>
      <RowDefinition Height="30"/>
    </Grid.RowDefinitions>
    <Border Grid.Row="0" Background="#0078D7">
      <TextBlock Text="POWERSHELL ADMIN TOOLKIT v6.0.0" FontSize="22" FontWeight="Bold" VerticalAlignment="Center" HorizontalAlignment="Center"/>
    </Border>
    <TabControl Grid.Row="1" Background="#1E1E1E" BorderBrush="#3F3F46" Name="MainTab">
      <TabItem Header="Dashboard" Background="#2D2D30" Foreground="White">
        <ScrollViewer VerticalScrollBarVisibility="Auto">
          <WrapPanel Margin="20">
            <Button x:Name="BtnMaintenance" Width="180" Height="90" Margin="8" Background="#2D2D30" BorderBrush="#3F3F46" BorderThickness="2">
              <StackPanel><TextBlock Text="Pure Clean" FontSize="15" FontWeight="Bold" HorizontalAlignment="Center"/><TextBlock Text="Deep Maintenance" FontSize="11" Foreground="Gray" HorizontalAlignment="Center"/></StackPanel>
            </Button>
            <Button x:Name="BtnAudit" Width="180" Height="90" Margin="8" Background="#2D2D30" BorderBrush="#3F3F46" BorderThickness="2">
              <StackPanel><TextBlock Text="System Audit" FontSize="15" FontWeight="Bold" HorizontalAlignment="Center"/><TextBlock Text="Cek Hardware and OS" FontSize="11" Foreground="Gray" HorizontalAlignment="Center"/></StackPanel>
            </Button>
            <Button x:Name="BtnNetwork" Width="180" Height="90" Margin="8" Background="#2D2D30" BorderBrush="#3F3F46" BorderThickness="2">
              <StackPanel><TextBlock Text="Network" FontSize="15" FontWeight="Bold" HorizontalAlignment="Center"/><TextBlock Text="Diagnostics" FontSize="11" Foreground="Gray" HorizontalAlignment="Center"/></StackPanel>
            </Button>
            <Button x:Name="BtnEventLog" Width="180" Height="90" Margin="8" Background="#2D2D30" BorderBrush="#3F3F46" BorderThickness="2">
              <StackPanel><TextBlock Text="Event Log" FontSize="15" FontWeight="Bold" HorizontalAlignment="Center"/><TextBlock Text="Analisis Error" FontSize="11" Foreground="Gray" HorizontalAlignment="Center"/></StackPanel>
            </Button>
            <Button x:Name="BtnBackup" Width="180" Height="90" Margin="8" Background="#2D2D30" BorderBrush="#3F3F46" BorderThickness="2">
              <StackPanel><TextBlock Text="App Backup" FontSize="15" FontWeight="Bold" HorizontalAlignment="Center"/><TextBlock Text="Export/Import" FontSize="11" Foreground="Gray" HorizontalAlignment="Center"/></StackPanel>
            </Button>
            <Button x:Name="BtnUserBackup" Width="180" Height="90" Margin="8" Background="#2D2D30" BorderBrush="#3F3F46" BorderThickness="2">
              <StackPanel><TextBlock Text="User Backup" FontSize="15" FontWeight="Bold" HorizontalAlignment="Center"/><TextBlock Text="Backup Profil" FontSize="11" Foreground="Gray" HorizontalAlignment="Center"/></StackPanel>
            </Button>
            <Button x:Name="BtnRestore" Width="180" Height="90" Margin="8" Background="#2D2D30" BorderBrush="#3F3F46" BorderThickness="2">
              <StackPanel><TextBlock Text="Restore Point" FontSize="15" FontWeight="Bold" HorizontalAlignment="Center"/><TextBlock Text="Create and Revert" FontSize="11" Foreground="Gray" HorizontalAlignment="Center"/></StackPanel>
            </Button>
            <Button x:Name="BtnUpdate" Width="180" Height="90" Margin="8" Background="#2D2D30" BorderBrush="#3F3F46" BorderThickness="2">
              <StackPanel><TextBlock Text="Update Mgr" FontSize="15" FontWeight="Bold" HorizontalAlignment="Center"/><TextBlock Text="Kontrol Update" FontSize="11" Foreground="Gray" HorizontalAlignment="Center"/></StackPanel>
            </Button>
            <Button x:Name="BtnDNS" Width="180" Height="90" Margin="8" Background="#2D2D30" BorderBrush="#3F3F46" BorderThickness="2">
              <StackPanel><TextBlock Text="DNS Switcher" FontSize="15" FontWeight="Bold" HorizontalAlignment="Center"/><TextBlock Text="Percepat Internet" FontSize="11" Foreground="Gray" HorizontalAlignment="Center"/></StackPanel>
            </Button>
            <Button x:Name="BtnFixes" Width="180" Height="90" Margin="8" Background="#2D2D30" BorderBrush="#3F3F46" BorderThickness="2">
              <StackPanel><TextBlock Text="One-Click Fixes" FontSize="15" FontWeight="Bold" HorizontalAlignment="Center"/><TextBlock Text="Perbaikan Darurat" FontSize="11" Foreground="Gray" HorizontalAlignment="Center"/></StackPanel>
            </Button>
            <Button x:Name="BtnStartup" Width="180" Height="90" Margin="8" Background="#2D2D30" BorderBrush="#3F3F46" BorderThickness="2">
              <StackPanel><TextBlock Text="Startup Mgr" FontSize="15" FontWeight="Bold" HorizontalAlignment="Center"/><TextBlock Text="Kelola Autostart" FontSize="11" Foreground="Gray" HorizontalAlignment="Center"/></StackPanel>
            </Button>
            <Button x:Name="BtnPresets" Width="180" Height="90" Margin="8" Background="#2D2D30" BorderBrush="#3F3F46" BorderThickness="2">
              <StackPanel><TextBlock Text="Presets" FontSize="15" FontWeight="Bold" HorizontalAlignment="Center"/><TextBlock Text="Setup Instalasi" FontSize="11" Foreground="Gray" HorizontalAlignment="Center"/></StackPanel>
            </Button>
          </WrapPanel>
        </ScrollViewer>
      </TabItem>
      <TabItem Header="Tweaks" Background="#2D2D30" Foreground="White">
        <Grid Margin="10">
          <Grid.RowDefinitions><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
          <TabControl Grid.Row="0" Background="#1E1E1E" BorderBrush="#3F3F46">
            <TabItem Header="Essential" Background="#2D2D30" Foreground="White">
              <ScrollViewer VerticalScrollBarVisibility="Auto"><StackPanel Margin="10" Name="PanelEssential"/></ScrollViewer>
            </TabItem>
            <TabItem Header="Advanced" Background="#2D2D30" Foreground="White">
              <ScrollViewer VerticalScrollBarVisibility="Auto"><StackPanel Margin="10" Name="PanelAdvanced"/></ScrollViewer>
            </TabItem>
          </TabControl>
          <Button Grid.Row="1" Name="BtnApplyTweaks" Content="APPLY SELECTED TWEAKS" Height="40" Background="#0078D7" FontWeight="Bold" Margin="0,10,0,0"/>
        </Grid>
      </TabItem>
      <TabItem Header="Debloater" Background="#2D2D30" Foreground="White">
        <Grid Margin="10">
          <Grid.RowDefinitions><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
          <TabControl Grid.Row="0" Background="#1E1E1E" BorderBrush="#3F3F46">
            <TabItem Header="Microsoft Apps" Background="#2D2D30" Foreground="White">
              <ScrollViewer VerticalScrollBarVisibility="Auto"><StackPanel Margin="10" Name="PanelDebloatMS"/></ScrollViewer>
            </TabItem>
            <TabItem Header="Bing and Web" Background="#2D2D30" Foreground="White">
              <ScrollViewer VerticalScrollBarVisibility="Auto"><StackPanel Margin="10" Name="PanelDebloatBing"/></ScrollViewer>
            </TabItem>
            <TabItem Header="Xbox and Gaming" Background="#2D2D30" Foreground="White">
              <ScrollViewer VerticalScrollBarVisibility="Auto"><StackPanel Margin="10" Name="PanelDebloatXbox"/></ScrollViewer>
            </TabItem>
            <TabItem Header="Utilities" Background="#2D2D30" Foreground="White">
              <ScrollViewer VerticalScrollBarVisibility="Auto"><StackPanel Margin="10" Name="PanelDebloatUtil"/></ScrollViewer>
            </TabItem>
          </TabControl>
          <Button Grid.Row="1" Name="BtnApplyDebloat" Content="UNINSTALL SELECTED" Height="40" Background="#D83B01" FontWeight="Bold" Margin="0,10,0,0"/>
        </Grid>
      </TabItem>
      <TabItem Header="Install Apps" Background="#2D2D30" Foreground="White">
        <Grid Margin="10">
          <Grid.RowDefinitions><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
          <TabControl Grid.Row="0" Name="AppsCategoryTabs" Background="#1E1E1E" BorderBrush="#3F3F46"/>
          <Button Grid.Row="1" Name="BtnInstallApps" Content="INSTALL SELECTED APPS" Height="40" Background="#107C10" FontWeight="Bold" Margin="0,10,0,0"/>
        </Grid>
      </TabItem>
    </TabControl>
    <Grid Grid.Row="2" Margin="10">
      <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/></Grid.RowDefinitions>
      <TextBlock Grid.Row="0" Text="Terminal Output (real-time):" FontWeight="Bold" Foreground="Cyan" Margin="0,0,0,5"/>
      <RichTextBox Grid.Row="1" Name="LogBox" Background="#111111" Foreground="White" FontFamily="Consolas" FontSize="12" IsReadOnly="True" VerticalScrollBarVisibility="Auto" BorderBrush="#3F3F46">
        <FlowDocument Name="LogDocument"><Paragraph><Run Foreground="Gray">Ready.</Run></Paragraph></FlowDocument>
      </RichTextBox>
    </Grid>
    <Border Grid.Row="3" Background="#2D2D30">
      <TextBlock x:Name="TxtStatus" Text="Ready." FontSize="12" VerticalAlignment="Center" HorizontalAlignment="Center" Foreground="Gray"/>
    </Border>
  </Grid>
</Window>
"@
    $reader = New-Object System.Xml.XmlNodeReader $xaml
    $window = [Windows.Markup.XamlReader]::Load($reader)
    $Global:LogBox = $window.FindName('LogBox')
    $Global:LogDocument = $window.FindName('LogDocument')
    Add-Log "[*] Toolkit v6.0.0 loaded. Semua fitur aktif - pilih dari Dashboard." "#00FF7F"

    $Global:CB_Tweaks = @()
    $tweaksEss = @(
        @{Name='Disable Telemetry'; Action='Telemetry'}, @{Name='Disable Activity History'; Action='Activity'},
        @{Name='Disable Consumer Features'; Action='Consumer'}, @{Name='Disable Location Tracking'; Action='Location'},
        @{Name='Disable Hibernation'; Action='Hibernation'}, @{Name='Show File Extensions'; Action='FileExt'},
        @{Name='Enable Ultimate Performance'; Action='UltimatePerf'}
    )
    $tweaksAdv = @(
        @{Name='Disable Background Apps'; Action='BgApps'}, @{Name='Disable Bing Search'; Action='Bing'},
        @{Name='Disable Game Bar'; Action='GameBar'}, @{Name='Disable Storage Sense'; Action='StorageSense'},
        @{Name='Disable IPv6'; Action='IPv6'}
    )
    $stackEss = $window.FindName('PanelEssential')
    foreach ($t in $tweaksEss) {
        $cb = New-DarkCheckBox -Text $t.Name -Tag $t.Action
        $stackEss.Children.Add($cb) | Out-Null
        $Global:CB_Tweaks += $cb
    }
    $stackAdv = $window.FindName('PanelAdvanced')
    foreach ($t in $tweaksAdv) {
        $cb = New-DarkCheckBox -Text $t.Name -Tag $t.Action
        $stackAdv.Children.Add($cb) | Out-Null
        $Global:CB_Tweaks += $cb
    }

    $Global:CB_Debloat = @()
    $debloats = @(
        @{Cat='MS';   Name='Feedback Hub'; Pkg='Microsoft.WindowsFeedbackHub'},
        @{Cat='MS';   Name='Get Help'; Pkg='Microsoft.GetHelp'},
        @{Cat='MS';   Name='Cortana'; Pkg='Microsoft.549981C3F5F10'},
        @{Cat='Bing'; Name='Bing News'; Pkg='Microsoft.BingNews'},
        @{Cat='Bing'; Name='Bing Weather'; Pkg='Microsoft.BingWeather'},
        @{Cat='Xbox'; Name='Xbox App'; Pkg='Microsoft.XboxApp'},
        @{Cat='Xbox'; Name='Xbox Game Bar'; Pkg='Microsoft.XboxGamingOverlay'},
        @{Cat='Util'; Name='Solitaire'; Pkg='Microsoft.MicrosoftSolitaireCollection'},
        @{Cat='Util'; Name='Skype'; Pkg='Microsoft.SkypeApp'},
        @{Cat='Util'; Name='Your Phone'; Pkg='Microsoft.YourPhone'},
        @{Cat='Util'; Name='Media Player'; Pkg='Microsoft.ZuneMusic'},
        @{Cat='Util'; Name='Movies and TV'; Pkg='Microsoft.ZuneVideo'}
    )
    $stacks = @{
        'MS'   = $window.FindName('PanelDebloatMS')
        'Bing' = $window.FindName('PanelDebloatBing')
        'Xbox' = $window.FindName('PanelDebloatXbox')
        'Util' = $window.FindName('PanelDebloatUtil')
    }
    foreach ($d in $debloats) {
        $cb = New-DarkCheckBox -Text $d.Name -Tag $d.Pkg
        $stacks[$d.Cat].Children.Add($cb) | Out-Null
        $Global:CB_Debloat += $cb
    }

    $Global:CB_Apps = @()
    $appsTabControl = $window.FindName('AppsCategoryTabs')
    $AppCategories = [ordered]@{
        'Browsers' = @(
            @{N='Google Chrome'; Id='Google.Chrome'}, @{N='Mozilla Firefox'; Id='Mozilla.Firefox'},
            @{N='Brave'; Id='Brave.Brave'}, @{N='Opera GX'; Id='Opera.OperaGX'},
            @{N='Vivaldi'; Id='VivaldiTechnologies.Vivaldi'}, @{N='LibreWolf'; Id='LibreWolf.LibreWolf'},
            @{N='Chromium'; Id='Hibbiki.Chromium'}, @{N='Microsoft Edge'; Id='Microsoft.Edge'}
        )
        'Communication' = @(
            @{N='Discord'; Id='Discord.Discord'}, @{N='Slack'; Id='SlackTechnologies.Slack'},
            @{N='Zoom'; Id='Zoom.Zoom'}, @{N='Telegram'; Id='Telegram.TelegramDesktop'},
            @{N='WhatsApp'; Id='WhatsApp.WhatsApp'}, @{N='Microsoft Teams'; Id='Microsoft.Teams'},
            @{N='Signal'; Id='OpenWhisperSystems.Signal'}, @{N='Skype'; Id='Microsoft.Skype'},
            @{N='Element'; Id='Element.Element'}, @{N='Thunderbird'; Id='Mozilla.Thunderbird'}
        )
        'Development' = @(
            @{N='VS Code'; Id='Microsoft.VisualStudioCode'}, @{N='Visual Studio 2022'; Id='Microsoft.VisualStudio.2022.Community'},
            @{N='Git'; Id='Git.Git'}, @{N='Python 3.12'; Id='Python.Python.3.12'},
            @{N='Node.js LTS'; Id='OpenJS.NodeJS.LTS'}, @{N='Notepad++'; Id='Notepad++.Notepad++'},
            @{N='Sublime Text 4'; Id='SublimeHQ.SublimeText.4'}, @{N='Postman'; Id='Postman.Postman'},
            @{N='Docker Desktop'; Id='Docker.DockerDesktop'}, @{N='GitHub Desktop'; Id='GitHub.GitHubDesktop'},
            @{N='Windows Terminal'; Id='Microsoft.WindowsTerminal'}, @{N='PowerShell 7'; Id='Microsoft.PowerShell'},
            @{N='IntelliJ CE'; Id='JetBrains.IntelliJIDEA.Community'}, @{N='PyCharm CE'; Id='JetBrains.PyCharm.Community'}
        )
        'Documents' = @(
            @{N='LibreOffice'; Id='TheDocumentFoundation.LibreOffice'}, @{N='OnlyOffice'; Id='ONLYOFFICE.DesktopEditors'},
            @{N='Adobe Reader'; Id='Adobe.Acrobat.Reader.64-bit'}, @{N='SumatraPDF'; Id='SumatraPDF.SumatraPDF'},
            @{N='Obsidian'; Id='Obsidian.Obsidian'}, @{N='Notion'; Id='Notion.Notion'},
            @{N='Typora'; Id='Typora.Typora'}, @{N='Joplin'; Id='Joplin.Joplin'},
            @{N='Calibre'; Id='Calibre.Calibre'}
        )
        'Multimedia' = @(
            @{N='VLC'; Id='VideoLAN.VLC'}, @{N='Spotify'; Id='Spotify.Spotify'},
            @{N='OBS Studio'; Id='OBSProject.OBSStudio'}, @{N='HandBrake'; Id='HandBrake.HandBrake'},
            @{N='Audacity'; Id='Audacity.Audacity'}, @{N='GIMP'; Id='GIMP.GIMP'},
            @{N='Inkscape'; Id='Inkscape.Inkscape'}, @{N='Blender'; Id='BlenderFoundation.Blender'},
            @{N='Krita'; Id='KDE.Krita'}, @{N='iTunes'; Id='Apple.iTunes'}
        )
        'Games' = @(
            @{N='Steam'; Id='Valve.Steam'}, @{N='Epic Games'; Id='EpicGames.EpicGamesLauncher'},
            @{N='GOG Galaxy'; Id='GOG.Galaxy'}, @{N='Playnite'; Id='Playnite.Playnite'},
            @{N='Xbox App'; Id='Microsoft.XboxApp'}, @{N='EA App'; Id='ElectronicArts.EADesktop'}
        )
        'Utilities' = @(
            @{N='7-Zip'; Id='7zip.7zip'}, @{N='WinRAR'; Id='RARLab.WinRAR'},
            @{N='PowerToys'; Id='Microsoft.PowerToys'}, @{N='Everything'; Id='voidtools.Everything'},
            @{N='ShareX'; Id='ShareX.ShareX'}, @{N='Rufus'; Id='Rufus.Rufus'},
            @{N='WizTree'; Id='AntibodySoftware.WizTree'}, @{N='CrystalDiskInfo'; Id='CrystalDewWorld.CrystalDiskInfo'},
            @{N='HWiNFO'; Id='REALiX.HWiNFO'}, @{N='CPU-Z'; Id='CPUID.CPU-Z'},
            @{N='GPU-Z'; Id='TechPowerUp.GPU-Z'}, @{N='TreeSize Free'; Id='JAMSoftware.TreeSize.Free'},
            @{N='Revo Uninstaller'; Id='RevoUninstaller.RevoUninstaller'}, @{N='Bitwarden'; Id='Bitwarden.Bitwarden'},
            @{N='KeePassXC'; Id='KeePassXCTeam.KeePassXC'}, @{N='WinDirStat'; Id='WinDirStat.WinDirStat'}
        )
        'Pro Tools' = @(
            @{N='Wireshark'; Id='WiresharkFoundation.Wireshark'}, @{N='PuTTY'; Id='PuTTY.PuTTY'},
            @{N='MobaXterm'; Id='Mobatek.MobaXterm'}, @{N='Advanced IP Scanner'; Id='Famatech.AdvancedIPScanner'},
            @{N='Nmap'; Id='Insecure.Nmap'}, @{N='Angry IP Scanner'; Id='angryziber.AngryIPScanner'},
            @{N='FileZilla'; Id='TimKosse.FileZilla.Client'}, @{N='WinSCP'; Id='WinSCP.WinSCP'}
        )
    }
    foreach ($cat in $AppCategories.Keys) {
        $tab = New-Object System.Windows.Controls.TabItem
        $tab.Header = $cat
        $tab.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#2D2D30')
        $tab.Foreground = [System.Windows.Media.Brushes]::White
        $scroll = New-Object System.Windows.Controls.ScrollViewer
        $scroll.VerticalScrollBarVisibility = 'Auto'
        $panel = New-Object System.Windows.Controls.StackPanel
        $panel.Margin = '10'
        foreach ($app in $AppCategories[$cat]) {
            $cb = New-DarkCheckBox -Text $app.N -Tag $app.Id
            $panel.Children.Add($cb) | Out-Null
            $Global:CB_Apps += $cb
        }
        $scroll.Content = $panel
        $tab.Content = $scroll
        $appsTabControl.Items.Add($tab) | Out-Null
    }

    $window.FindName('BtnMaintenance').Add_Click({ Show-MaintenanceDialog })
    $window.FindName('BtnAudit').Add_Click({
        Invoke-GuiJob -ScriptBlock ${function:Execute-SystemAudit} -ArgumentList @() -StartMessage '[*] System Audit...' -DoneMessage '[OK] Audit selesai.'
    })
    $window.FindName('BtnNetwork').Add_Click({
        Invoke-GuiJob -ScriptBlock ${function:Execute-NetworkDiagnostics} -ArgumentList @() -StartMessage '[*] Network Diagnostics...' -DoneMessage '[OK] Selesai.'
    })
    $window.FindName('BtnEventLog').Add_Click({
        Invoke-GuiJob -ScriptBlock ${function:Execute-EventLogAnalyzer} -ArgumentList @() -StartMessage '[*] Event Log Analyzer...' -DoneMessage '[OK] Selesai.'
    })
    $window.FindName('BtnBackup').Add_Click({ Show-AppBackupDialog })
    $window.FindName('BtnUserBackup').Add_Click({ Show-UserBackupDialog })
    $window.FindName('BtnRestore').Add_Click({ Show-RestorePointDialog })
    $window.FindName('BtnUpdate').Add_Click({ Show-UpdateManagerDialog })
    $window.FindName('BtnDNS').Add_Click({ Show-DnsSwitcherDialog })
    $window.FindName('BtnFixes').Add_Click({ Show-OneClickFixesDialog })
    $window.FindName('BtnStartup').Add_Click({ Show-StartupManagerDialog })
    $window.FindName('BtnPresets').Add_Click({ Show-PresetsDialog })

    $window.FindName('BtnApplyTweaks').Add_Click({
        $sel = @()
        foreach ($cb in $Global:CB_Tweaks) { if ($cb.IsChecked -eq $true) { $sel += $cb.Tag } }
        if ($sel.Count -eq 0) { Add-Log '[!] Pilih minimal satu tweak.' '#FF5555'; return }
        Invoke-GuiJob -ScriptBlock ${function:Execute-Tweaks} -ArgumentList (,$sel) -StartMessage "[*] Apply $($sel.Count) tweak(s)..." -DoneMessage '[OK] Tweaks selesai.'
    })

    $window.FindName('BtnApplyDebloat').Add_Click({
        $sel = @()
        foreach ($cb in $Global:CB_Debloat) { if ($cb.IsChecked -eq $true) { $sel += $cb.Tag } }
        if ($sel.Count -eq 0) { Add-Log '[!] Pilih minimal satu aplikasi.' '#FF5555'; return }
        Invoke-GuiJob -ScriptBlock ${function:Execute-Debloat} -ArgumentList (,$sel) -StartMessage "[*] Debloat $($sel.Count) app(s)..." -DoneMessage '[OK] Debloat selesai.'
    })

    $window.FindName('BtnInstallApps').Add_Click({
        $sel = @()
        foreach ($cb in $Global:CB_Apps) { if ($cb.IsChecked -eq $true) { $sel += $cb.Tag } }
        if ($sel.Count -eq 0) { Add-Log '[!] Pilih minimal satu aplikasi.' '#FF5555'; return }
        Invoke-GuiJob -ScriptBlock ${function:Execute-InstallApps} -ArgumentList (,$sel) -StartMessage "[*] Install $($sel.Count) aplikasi via Winget..." -DoneMessage '[OK] Install selesai.'
    })

    $window.ShowDialog() | Out-Null
}

Show-GUI