Add-Type -AssemblyName PresentationFramework
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -Command `"irm https://raw.githubusercontent.com/elfadhildev/powershell-windows-admin-toolkit/main/toolkit.ps1 | iex`"" -Verb RunAs
    exit
}

# ==========================================
# DATA GLOBAL: TWEAKS
# ==========================================
$Global:TweakList = @(
    [PSCustomObject]@{ Id=1; Cat='Essential'; Name='Disable Telemetry'; Action='Telemetry' },
    [PSCustomObject]@{ Id=2; Cat='Essential'; Name='Disable Activity History'; Action='Activity' },
    [PSCustomObject]@{ Id=3; Cat='Essential'; Name='Disable Consumer Features'; Action='Consumer' },
    [PSCustomObject]@{ Id=4; Cat='Essential'; Name='Disable Location Tracking'; Action='Location' },
    [PSCustomObject]@{ Id=5; Cat='Essential'; Name='Disable Hibernation'; Action='Hibernation' },
    [PSCustomObject]@{ Id=6; Cat='Essential'; Name='Show File Extensions'; Action='FileExt' },
    [PSCustomObject]@{ Id=7; Cat='Essential'; Name='Enable Ultimate Performance'; Action='UltimatePerf' },
    [PSCustomObject]@{ Id=8; Cat='Advanced'; Name='Disable Background Apps'; Action='BgApps' },
    [PSCustomObject]@{ Id=9; Cat='Advanced'; Name='Disable Bing Search'; Action='Bing' },
    [PSCustomObject]@{ Id=10; Cat='Advanced'; Name='Disable Game Bar'; Action='GameBar' },
    [PSCustomObject]@{ Id=11; Cat='Advanced'; Name='Disable Storage Sense'; Action='StorageSense' },
    [PSCustomObject]@{ Id=12; Cat='Advanced'; Name='Disable OneDrive'; Action='OneDrive' },
    [PSCustomObject]@{ Id=13; Cat='Advanced'; Name='Disable IPv6'; Action='IPv6' },
    [PSCustomObject]@{ Id=14; Cat='Advanced'; Name='Disable Reserved Storage'; Action='Reserved' }
)

# ==========================================
# DATA GLOBAL: DEBLOATER
# ==========================================
$Global:DebloatList = @(
    [PSCustomObject]@{ Id=1; Cat='Microsoft Apps'; Name='Feedback Hub'; Pkg='Microsoft.WindowsFeedbackHub' }
    [PSCustomObject]@{ Id=2; Cat='Microsoft Apps'; Name='Get Help'; Pkg='Microsoft.GetHelp' }
    [PSCustomObject]@{ Id=3; Cat='Microsoft Apps'; Name='Cortana'; Pkg='Microsoft.549981C3F5F10' }
    [PSCustomObject]@{ Id=4; Cat='Bing & Web'; Name='Bing News'; Pkg='Microsoft.BingNews' }
    [PSCustomObject]@{ Id=5; Cat='Bing & Web'; Name='Bing Weather'; Pkg='Microsoft.BingWeather' }
    [PSCustomObject]@{ Id=6; Cat='Xbox & Gaming'; Name='Xbox App'; Pkg='Microsoft.XboxApp' }
    [PSCustomObject]@{ Id=7; Cat='Xbox & Gaming'; Name='Xbox Game Bar'; Pkg='Microsoft.XboxGamingOverlay' }
    [PSCustomObject]@{ Id=8; Cat='Utilities'; Name='Solitaire'; Pkg='Microsoft.MicrosoftSolitaireCollection' }
    [PSCustomObject]@{ Id=9; Cat='Utilities'; Name='Skype'; Pkg='Microsoft.SkypeApp' }
    [PSCustomObject]@{ Id=10; Cat='Utilities'; Name='Your Phone'; Pkg='Microsoft.YourPhone' }
    [PSCustomObject]@{ Id=11; Cat='Utilities'; Name='Media Player'; Pkg='Microsoft.ZuneMusic' }
    [PSCustomObject]@{ Id=12; Cat='Utilities'; Name='Movies & TV'; Pkg='Microsoft.ZuneVideo' }
)

# ==========================================
# FUNGSI EKSEKUSI (Berjalan di Background Job)
# ==========================================
function Execute-Tweaks {
    param([array]$Actions)
    $results = @()
    foreach ($act in $Actions) {
        try {
            switch ($act) {
                'Telemetry' { 
                    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0 -Type DWord -ErrorAction Stop
                    Set-Service -Name DiagTrack -StartupType Disabled -ErrorAction SilentlyContinue
                    Stop-Service -Name DiagTrack -Force -ErrorAction SilentlyContinue
                    $results += "[OK] Telemetry disabled."
                }
                'Activity' { 
                    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "EnableActivityFeed" -Value 0 -Type DWord -ErrorAction Stop
                    $results += "[OK] Activity History disabled."
                }
                'Consumer' { 
                    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableWindowsConsumerFeatures" -Value 1 -Type DWord -ErrorAction Stop
                    $results += "[OK] Consumer Features disabled."
                }
                'Location' { 
                    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" -Name "DisableLocation" -Value 1 -Type DWord -ErrorAction Stop
                    $results += "[OK] Location Tracking disabled."
                }
                'Hibernation' { 
                    Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Session Manager\Power" -Name "HibernateEnabled" -Value 0 -Type DWord -ErrorAction Stop
                    powercfg -h off
                    $results += "[OK] Hibernation disabled."
                }
                'FileExt' { 
                    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 0 -Type DWord -ErrorAction Stop
                    $results += "[OK] File Extensions shown."
                }
                'UltimatePerf' { 
                    powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61
                    $results += "[OK] Ultimate Performance plan added."
                }
                'BgApps' { 
                    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" -Name "GlobalUserDisabled" -Value 1 -Type DWord -ErrorAction Stop
                    $results += "[OK] Background Apps disabled."
                }
                'Bing' { 
                    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "BingSearchEnabled" -Value 0 -Type DWord -ErrorAction Stop
                    $results += "[OK] Bing Search disabled."
                }
                'GameBar' { 
                    Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "AutoGameModeEnabled" -Value 0 -Type DWord -ErrorAction Stop
                    $results += "[OK] Game Bar disabled."
                }
                'StorageSense' { 
                    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" -Name "01" -Value 0 -Type DWord -ErrorAction Stop
                    $results += "[OK] Storage Sense disabled."
                }
                'OneDrive' { 
                    Stop-Process -Name "OneDrive" -Force -ErrorAction SilentlyContinue
                    Start-Process "C:\Windows\System32\OneDriveSetup.exe" -ArgumentList "/uninstall" -Wait -ErrorAction Stop
                    $results += "[OK] OneDrive uninstalled."
                }
                'IPv6' { 
                    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters" -Name "DisabledComponents" -Value 255 -Type DWord -ErrorAction Stop
                    $results += "[OK] IPv6 disabled."
                }
                'Reserved' { 
                    Set-WindowsReservedStorageState -State Disabled -ErrorAction Stop
                    $results += "[OK] Reserved Storage disabled."
                }
            }
        } catch {
            $results += "[ERROR] Failed to apply ${act}: $($_.Exception.Message)"
        }
    }
    return $results
}

function Execute-Debloat {
    param([array]$Packages)
    $results = @()
    foreach ($pkgName in $Packages) {
        try {
            $appx = Get-AppxPackage -Name $pkgName -AllUsers -ErrorAction Stop
            if ($appx) {
                Remove-AppxPackage -Package $appx.PackageFullName -AllUsers -Force -ErrorAction Stop
                $results += "[OK] Successfully removed: $pkgName"
            } else {
                $results += "[SKIP] Not found (already removed): $pkgName"
            }
        } catch {
            $results += "[ERROR] Failed to remove $pkgName : $($_.Exception.Message)"
        }
    }
    return $results
}

# ==========================================
# GUI: MAIN WINDOW & FUNGSI PENDUKUNG
# ==========================================
function Show-GUI {
    [xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="PowerShell Admin Toolkit v4.1.0" Height="850" Width="1050"
        WindowStartupLocation="CenterScreen" Background="#1E1E1E" Foreground="White">
    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="60"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="250"/> <!-- Area Log -->
            <RowDefinition Height="30"/>
        </Grid.RowDefinitions>
        
        <!-- Header -->
        <Border Grid.Row="0" Background="#0078D7">
            <TextBlock Text="POWERSHELL ADMIN TOOLKIT" FontSize="20" FontWeight="Bold" VerticalAlignment="Center" HorizontalAlignment="Center"/>
        </Border>

        <!-- Main Content (Tiles) -->
        <TabControl Grid.Row="1" Background="#1E1E1E" BorderBrush="#3F3F46" Name="MainTab">
            <TabItem Header="Main Dashboard" Background="#2D2D30" Foreground="White">
                <WrapPanel Margin="20" HorizontalAlignment="Center" VerticalAlignment="Center">
                    <Button x:Name="BtnMaintenance" Width="180" Height="90" Margin="10" Background="#2D2D30" BorderBrush="#3F3F46" BorderThickness="2"><StackPanel><TextBlock Text="🛠️ Pure Clean" FontSize="16" FontWeight="Bold" HorizontalAlignment="Center"/><TextBlock Text="Deep Maintenance" FontSize="12" Foreground="Gray" HorizontalAlignment="Center"/></StackPanel></Button>
                    <Button x:Name="BtnDebloater" Width="180" Height="90" Margin="10" Background="#2D2D30" BorderBrush="#3F3F46" BorderThickness="2"><StackPanel><TextBlock Text="🧹 Debloater" FontSize="16" FontWeight="Bold" HorizontalAlignment="Center"/><TextBlock Text="Hapus Bloatware" FontSize="12" Foreground="Gray" HorizontalAlignment="Center"/></StackPanel></Button>
                    <Button x:Name="BtnTweaks" Width="180" Height="90" Margin="10" Background="#2D2D30" BorderBrush="#3F3F46" BorderThickness="2"><StackPanel><TextBlock Text="⚙️ Tweaks" FontSize="16" FontWeight="Bold" HorizontalAlignment="Center"/><TextBlock Text="Privasi &amp; Performa" FontSize="12" Foreground="Gray" HorizontalAlignment="Center"/></StackPanel></Button>
                    <Button x:Name="BtnInstall" Width="180" Height="90" Margin="10" Background="#2D2D30" BorderBrush="#3F3F46" BorderThickness="2"><StackPanel><TextBlock Text="📦 Install Apps" FontSize="16" FontWeight="Bold" HorizontalAlignment="Center"/><TextBlock Text="Winget Mega List" FontSize="12" Foreground="Gray" HorizontalAlignment="Center"/></StackPanel></Button>
                    <Button x:Name="BtnAudit" Width="180" Height="90" Margin="10" Background="#2D2D30" BorderBrush="#3F3F46" BorderThickness="2"><StackPanel><TextBlock Text="📊 Audit" FontSize="16" FontWeight="Bold" HorizontalAlignment="Center"/><TextBlock Text="Cek Hardware" FontSize="12" Foreground="Gray" HorizontalAlignment="Center"/></StackPanel></Button>
                    <Button x:Name="BtnNetwork" Width="180" Height="90" Margin="10" Background="#2D2D30" BorderBrush="#3F3F46" BorderThickness="2"><StackPanel><TextBlock Text="🌐 Network" FontSize="16" FontWeight="Bold" HorizontalAlignment="Center"/><TextBlock Text="Cek Jaringan" FontSize="12" Foreground="Gray" HorizontalAlignment="Center"/></StackPanel></Button>
                    
                    <Button x:Name="BtnEventLog" Width="180" Height="90" Margin="10" Background="#2D2D30" BorderBrush="#3F3F46" BorderThickness="2"><StackPanel><TextBlock Text="📝 Event Log" FontSize="16" FontWeight="Bold" HorizontalAlignment="Center"/><TextBlock Text="Analisis Error" FontSize="12" Foreground="Gray" HorizontalAlignment="Center"/></StackPanel></Button>
                    <Button x:Name="BtnBackup" Width="180" Height="90" Margin="10" Background="#2D2D30" BorderBrush="#3F3F46" BorderThickness="2"><StackPanel><TextBlock Text="💾 App Backup" FontSize="16" FontWeight="Bold" HorizontalAlignment="Center"/><TextBlock Text="Export/Import" FontSize="12" Foreground="Gray" HorizontalAlignment="Center"/></StackPanel></Button>
                    <Button x:Name="BtnUserBackup" Width="180" Height="90" Margin="10" Background="#2D2D30" BorderBrush="#3F3F46" BorderThickness="2"><StackPanel><TextBlock Text="🗂️ User Backup" FontSize="16" FontWeight="Bold" HorizontalAlignment="Center"/><TextBlock Text="Backup Data Profil" FontSize="12" Foreground="Gray" HorizontalAlignment="Center"/></StackPanel></Button>
                    <Button x:Name="BtnRestore" Width="180" Height="90" Margin="10" Background="#2D2D30" BorderBrush="#3F3F46" BorderThickness="2"><StackPanel><TextBlock Text="🛡️ Restore Point" FontSize="16" FontWeight="Bold" HorizontalAlignment="Center"/><TextBlock Text="Buat &amp; Kembalikan" FontSize="12" Foreground="Gray" HorizontalAlignment="Center"/></StackPanel></Button>
                    <Button x:Name="BtnUpdate" Width="180" Height="90" Margin="10" Background="#2D2D30" BorderBrush="#3F3F46" BorderThickness="2"><StackPanel><TextBlock Text="🔄 Update Mgr" FontSize="16" FontWeight="Bold" HorizontalAlignment="Center"/><TextBlock Text="Kontrol Windows Update" FontSize="12" Foreground="Gray" HorizontalAlignment="Center"/></StackPanel></Button>
                    <Button x:Name="BtnDNS" Width="180" Height="90" Margin="10" Background="#2D2D30" BorderBrush="#3F3F46" BorderThickness="2"><StackPanel><TextBlock Text="🌍 DNS Switcher" FontSize="16" FontWeight="Bold" HorizontalAlignment="Center"/><TextBlock Text="Percepat Internet" FontSize="12" Foreground="Gray" HorizontalAlignment="Center"/></StackPanel></Button>
                    <Button x:Name="BtnFixes" Width="180" Height="90" Margin="10" Background="#2D2D30" BorderBrush="#3F3F46" BorderThickness="2"><StackPanel><TextBlock Text="🚑 One-Click Fixes" FontSize="16" FontWeight="Bold" HorizontalAlignment="Center"/><TextBlock Text="Perbaikan Darurat" FontSize="12" Foreground="Gray" HorizontalAlignment="Center"/></StackPanel></Button>
                    <Button x:Name="BtnStartup" Width="180" Height="90" Margin="10" Background="#2D2D30" BorderBrush="#3F3F46" BorderThickness="2"><StackPanel><TextBlock Text="🚀 Startup Manager" FontSize="16" FontWeight="Bold" HorizontalAlignment="Center"/><TextBlock Text="Kelola Autostart" FontSize="12" Foreground="Gray" HorizontalAlignment="Center"/></StackPanel></Button>
                    <Button x:Name="BtnPresets" Width="180" Height="90" Margin="10" Background="#2D2D30" BorderBrush="#3F3F46" BorderThickness="2"><StackPanel><TextBlock Text="⚡ Automation Presets" FontSize="16" FontWeight="Bold" HorizontalAlignment="Center"/><TextBlock Text="Setup Instalasi Cepat" FontSize="12" Foreground="Gray" HorizontalAlignment="Center"/></StackPanel></Button>
                </WrapPanel>
            </TabItem>
        </TabControl>

        <!-- Area Log Terminal -->
        <Grid Grid.Row="2" Margin="10">
            <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/></Grid.RowDefinitions>
            <TextBlock Grid.Row="0" Text="System Log and Output:" FontWeight="Bold" Foreground="Cyan" Margin="0,0,0,5"/>
            <RichTextBox Grid.Row="1" Name="LogBox" Background="#111111" Foreground="White" FontFamily="Consolas" FontSize="12" IsReadOnly="True" VerticalScrollBarVisibility="Auto" BorderBrush="#3F3F46">
                <FlowDocument Name="LogDocument">
                    <Paragraph><Run Foreground="Gray">Ready...</Run></Paragraph>
                </FlowDocument>
            </RichTextBox>
        </Grid>

        <!-- Footer -->
        <Border Grid.Row="3" Background="#2D2D30">
            <TextBlock x:Name="TxtStatus" Text="Ready." FontSize="12" VerticalAlignment="Center" HorizontalAlignment="Center" Foreground="Gray"/>
        </Border>
    </Grid>
</Window>
"@
    $reader = (New-Object System.Xml.XmlNodeReader ([xml]$xaml))
    $window = [Windows.Markup.XamlReader]::Load($reader)
    
    $logBox = $window.FindName("LogBox")
    $logDocument = $window.FindName("LogDocument")

    # Fungsi pembantu untuk menulis ke log (SUDAH DIPERBAIKI)
    $writeLog = {
        param($text, $color)
        $p = New-Object System.Windows.Documents.Paragraph
        $r = New-Object System.Windows.Documents.Run -ArgumentList $text
        $r.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString($color)
        $p.Inlines.Add($r)
        $logDocument.Blocks.Add($p)
        $logBox.ScrollToEnd()
    }

    # Action: Maintenance
    $window.FindName("BtnMaintenance").Add_Click({
        & $writeLog "`n[+] Memulai Deep Maintenance..." "Yellow"
        & $writeLog "[OK] Proses disimulasikan selesai." "Lime"
    })

    # Action: Tweaks (Membuka Dialog)
    $window.FindName("BtnTweaks").Add_Click({
        $tweaksWindow = New-Object System.Windows.Window
        $tweaksWindow.Title = "Select Tweaks"
        $tweaksWindow.Width = 500
        $tweaksWindow.Height = 600
        $tweaksWindow.Background = [System.Windows.Media.Brushes]::DarkGray
        
        $grid = New-Object System.Windows.Controls.Grid
        $grid.Margin = "10"
        
        $row1 = New-Object System.Windows.Controls.RowDefinition
        $row1.Height = "Auto"
        $row2 = New-Object System.Windows.Controls.RowDefinition
        $row2.Height = "*"
        $row3 = New-Object System.Windows.Controls.RowDefinition
        $row3.Height = "Auto"
        $grid.RowDefinitions.Add($row1)
        $grid.RowDefinitions.Add($row2)
        $grid.RowDefinitions.Add($row3)
        
        $scroll = New-Object System.Windows.Controls.ScrollViewer
        $scroll.VerticalScrollBarVisibility = "Auto"
        
        $stack = New-Object System.Windows.Controls.StackPanel
        
        $checkboxes = @()
        foreach ($t in $Global:TweakList) {
            $cb = New-Object System.Windows.Controls.CheckBox
            $cb.Content = $t.Name
            $cb.Foreground = [System.Windows.Media.Brushes]::White
            $cb.Margin = "0,5,0,5"
            $stack.Children.Add($cb) | Out-Null
            $checkboxes += [PSCustomObject]@{ Action = $t.Action; CheckBox = $cb }
        }
        $scroll.Content = $stack
        [System.Windows.Controls.Grid]::SetRow($scroll, 1)
        $grid.Children.Add($scroll) | Out-Null
        
        $btnApply = New-Object System.Windows.Controls.Button
        $btnApply.Content = "APPLY SELECTED TWEAKS"
        $btnApply.Height = 40
        $btnApply.Background = [System.Windows.Media.Brushes]::DodgerBlue
        $btnApply.Foreground = [System.Windows.Media.Brushes]::White
        $btnApply.FontWeight = "Bold"
        $btnApply.Margin = "0,10,0,0"
        [System.Windows.Controls.Grid]::SetRow($btnApply, 2)
        $grid.Children.Add($btnApply) | Out-Null
        
        $btnApply.Add_Click({
            $actionsToRun = @()
            foreach ($item in $checkboxes) {
                if ($item.CheckBox.IsChecked -eq $true) { $actionsToRun += $item.Action }
            }
            if ($actionsToRun.Count -eq 0) { return }
            
            $tweaksWindow.Close()
            & $writeLog "`n[+] Memulai Proses Tweaks..." "Yellow"
            
            $script:TweakJob = Start-Job -ScriptBlock ${function:Execute-Tweaks} -ArgumentList (,$actionsToRun)
            $script:TweakTimer = New-Object System.Windows.Threading.DispatcherTimer
            $script:TweakTimer.Interval = [TimeSpan]::FromSeconds(1)
            $script:TweakTimer.Add_Tick({
                if ($script:TweakJob.State -ne 'Running') {
                    $results = Receive-Job -Job $script:TweakJob
                    foreach ($res in $results) {
                        if ($res -match "^\[OK\]") { & $writeLog $res "Lime" }
                        elseif ($res -match "^\[ERROR\]") { & $writeLog $res "Red" }
                        else { & $writeLog $res "White" }
                    }
                    & $writeLog "[+] Tweaks Selesai." "Cyan"
                    $script:TweakTimer.Stop()
                    Remove-Job -Job $script:TweakJob -Force
                }
            })
            $script:TweakTimer.Start()
        })
        
        $tweaksWindow.Content = $grid
        $tweaksWindow.ShowDialog() | Out-Null
    })

    # Action: Debloater (Membuka Dialog)
    $window.FindName("BtnDebloater").Add_Click({
        $debloatWindow = New-Object System.Windows.Window
        $debloatWindow.Title = "Select Bloatware"
        $debloatWindow.Width = 500
        $debloatWindow.Height = 600
        $debloatWindow.Background = [System.Windows.Media.Brushes]::DarkGray
        
        $grid = New-Object System.Windows.Controls.Grid
        $grid.Margin = "10"
        
        $row1 = New-Object System.Windows.Controls.RowDefinition
        $row1.Height = "Auto"
        $row2 = New-Object System.Windows.Controls.RowDefinition
        $row2.Height = "*"
        $row3 = New-Object System.Windows.Controls.RowDefinition
        $row3.Height = "Auto"
        $grid.RowDefinitions.Add($row1)
        $grid.RowDefinitions.Add($row2)
        $grid.RowDefinitions.Add($row3)
        
        $scroll = New-Object System.Windows.Controls.ScrollViewer
        $scroll.VerticalScrollBarVisibility = "Auto"
        
        $stack = New-Object System.Windows.Controls.StackPanel
        
        $checkboxes = @()
        foreach ($d in $Global:DebloatList) {
            $cb = New-Object System.Windows.Controls.CheckBox
            $cb.Content = $d.Name
            $cb.Foreground = [System.Windows.Media.Brushes]::White
            $cb.Margin = "0,5,0,5"
            $stack.Children.Add($cb) | Out-Null
            $checkboxes += [PSCustomObject]@{ Pkg = $d.Pkg; CheckBox = $cb }
        }
        $scroll.Content = $stack
        [System.Windows.Controls.Grid]::SetRow($scroll, 1)
        $grid.Children.Add($scroll) | Out-Null
        
        $btnApply = New-Object System.Windows.Controls.Button
        $btnApply.Content = "UNINSTALL SELECTED"
        $btnApply.Height = 40
        $btnApply.Background = [System.Windows.Media.Brushes]::Crimson
        $btnApply.Foreground = [System.Windows.Media.Brushes]::White
        $btnApply.FontWeight = "Bold"
        $btnApply.Margin = "0,10,0,0"
        [System.Windows.Controls.Grid]::SetRow($btnApply, 2)
        $grid.Children.Add($btnApply) | Out-Null
        
        $btnApply.Add_Click({
            $pkgsToRemove = @()
            foreach ($item in $checkboxes) {
                if ($item.CheckBox.IsChecked -eq $true) { $pkgsToRemove += $item.Pkg }
            }
            if ($pkgsToRemove.Count -eq 0) { return }
            
            $debloatWindow.Close()
            & $writeLog "`n[+] Memulai Debloating..." "Yellow"
            
            $script:DebloatJob = Start-Job -ScriptBlock ${function:Execute-Debloat} -ArgumentList (,$pkgsToRemove)
            $script:DebloatTimer = New-Object System.Windows.Threading.DispatcherTimer
            $script:DebloatTimer.Interval = [TimeSpan]::FromSeconds(1)
            $script:DebloatTimer.Add_Tick({
                if ($script:DebloatJob.State -ne 'Running') {
                    $results = Receive-Job -Job $script:DebloatJob
                    foreach ($res in $results) {
                        if ($res -match "^\[OK\]") { & $writeLog $res "Lime" }
                        elseif ($res -match "^\[ERROR\]") { & $writeLog $res "Red" }
                        else { & $writeLog $res "Gray" }
                    }
                    & $writeLog "[+] Debloating Selesai." "Cyan"
                    $script:DebloatTimer.Stop()
                    Remove-Job -Job $script:DebloatJob -Force
                }
            })
            $script:DebloatTimer.Start()
        })
        
        $debloatWindow.Content = $grid
        $debloatWindow.ShowDialog() | Out-Null
    })

    # Action: Audit
    $window.FindName("BtnAudit").Add_Click({
        & $writeLog "`n[+] Memulai System Audit..." "Yellow"
        $os = Get-CimInstance Win32_OperatingSystem; $cpu = Get-CimInstance Win32_Processor; $ram = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)
        & $writeLog " OS: $($os.Caption) | CPU: $($cpu.Name) | RAM: $ram GB" "White"
        & $writeLog "[+] Audit Selesai." "Cyan"
    })

    # Action: Network (Placeholder)
    $window.FindName("BtnNetwork").Add_Click({ & $writeLog "`n[+] Fitur Network segera hadir." "Yellow" })
    $window.FindName("BtnInstall").Add_Click({ & $writeLog "`n[+] Fitur Install Apps segera hadir." "Yellow" })
    $window.FindName("BtnEventLog").Add_Click({ & $writeLog "`n[+] Fitur Event Log segera hadir." "Yellow" })
    $window.FindName("BtnBackup").Add_Click({ & $writeLog "`n[+] Fitur App Backup segera hadir." "Yellow" })
    $window.FindName("BtnUserBackup").Add_Click({ & $writeLog "`n[+] Fitur User Backup segera hadir." "Yellow" })
    $window.FindName("BtnRestore").Add_Click({ & $writeLog "`n[+] Fitur Restore Point segera hadir." "Yellow" })
    $window.FindName("BtnUpdate").Add_Click({ & $writeLog "`n[+] Fitur Update Manager segera hadir." "Yellow" })
    $window.FindName("BtnDNS").Add_Click({ & $writeLog "`n[+] Fitur DNS Switcher segera hadir." "Yellow" })
    $window.FindName("BtnFixes").Add_Click({ & $writeLog "`n[+] Fitur One-Click Fixes segera hadir." "Yellow" })
    $window.FindName("BtnStartup").Add_Click({ & $writeLog "`n[+] Fitur Startup Manager segera hadir." "Yellow" })
    $window.FindName("BtnPresets").Add_Click({ & $writeLog "`n[+] Fitur Automation Presets segera hadir." "Yellow" })

    $window.ShowDialog() | Out-Null
}

Show-GUI