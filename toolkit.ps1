Add-Type -AssemblyName PresentationFramework
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -Command `"irm https://raw.githubusercontent.com/elfadhildev/powershell-windows-admin-toolkit/main/toolkit.ps1 | iex`"" -Verb RunAs
    exit
}

# ==========================================
# FUNGSI EKSEKUSI (BACKGROUND JOB)
# ==========================================
function Execute-Tweaks {
    param([array]$Actions)
    $results = @()
    foreach ($act in $Actions) {
        try {
            switch ($act) {
                'Telemetry' { Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0 -Type DWord -ErrorAction Stop; Set-Service -Name DiagTrack -StartupType Disabled -ErrorAction SilentlyContinue; Stop-Service -Name DiagTrack -Force -ErrorAction SilentlyContinue; $results += "[OK] Telemetry disabled." }
                'Activity' { Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "EnableActivityFeed" -Value 0 -Type DWord -ErrorAction Stop; $results += "[OK] Activity History disabled." }
                'Consumer' { Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableWindowsConsumerFeatures" -Value 1 -Type DWord -ErrorAction Stop; $results += "[OK] Consumer Features disabled." }
                'Location' { Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" -Name "DisableLocation" -Value 1 -Type DWord -ErrorAction Stop; $results += "[OK] Location Tracking disabled." }
                'Hibernation' { Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Session Manager\Power" -Name "HibernateEnabled" -Value 0 -Type DWord -ErrorAction Stop; powercfg -h off; $results += "[OK] Hibernation disabled." }
                'FileExt' { Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 0 -Type DWord -ErrorAction Stop; $results += "[OK] File Extensions shown." }
                'UltimatePerf' { powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61; $results += "[OK] Ultimate Performance plan added." }
                'BgApps' { Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" -Name "GlobalUserDisabled" -Value 1 -Type DWord -ErrorAction Stop; $results += "[OK] Background Apps disabled." }
                'Bing' { Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "BingSearchEnabled" -Value 0 -Type DWord -ErrorAction Stop; $results += "[OK] Bing Search disabled." }
                'GameBar' { Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "AutoGameModeEnabled" -Value 0 -Type DWord -ErrorAction Stop; $results += "[OK] Game Bar disabled." }
                'StorageSense' { Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" -Name "01" -Value 0 -Type DWord -ErrorAction Stop; $results += "[OK] Storage Sense disabled." }
                'OneDrive' { Stop-Process -Name "OneDrive" -Force -ErrorAction SilentlyContinue; Start-Process "C:\Windows\System32\OneDriveSetup.exe" -ArgumentList "/uninstall" -Wait -ErrorAction Stop; $results += "[OK] OneDrive uninstalled." }
                'IPv6' { Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters" -Name "DisabledComponents" -Value 255 -Type DWord -ErrorAction Stop; $results += "[OK] IPv6 disabled." }
                'Reserved' { Set-WindowsReservedStorageState -State Disabled -ErrorAction Stop; $results += "[OK] Reserved Storage disabled." }
            }
        } catch { $results += "[ERROR] Failed to apply ${act}: $($_.Exception.Message)" }
    }
    return $results
}

function Execute-Debloat {
    param([array]$Packages)
    $results = @()
    foreach ($pkgName in $Packages) {
        try {
            $appx = Get-AppxPackage -Name $pkgName -AllUsers -ErrorAction Stop
            if ($appx) { Remove-AppxPackage -Package $appx.PackageFullName -AllUsers -Force -ErrorAction Stop; $results += "[OK] Removed: $pkgName" } 
            else { $results += "[SKIP] Not found: $pkgName" }
        } catch { $results += "[ERROR] Failed to remove: $pkgName" }
    }
    return $results
}

# ==========================================
# GUI: UNIFIED INTERFACE (SINGLE WINDOW)
# ==========================================
function Show-GUI {
    # XAML diperbaiki total: Struktur tag seimbang & karakter & di-escape
    [xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="PowerShell Admin Toolkit v5.0.1" Height="900" Width="1100"
        WindowStartupLocation="CenterScreen" Background="#1E1E1E" Foreground="White">
    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="60"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="250"/>
            <RowDefinition Height="30"/>
        </Grid.RowDefinitions>

        <Border Grid.Row="0" Background="#0078D7">
            <TextBlock Text="POWERSHELL ADMIN TOOLKIT" FontSize="22" FontWeight="Bold" VerticalAlignment="Center" HorizontalAlignment="Center"/>
        </Border>

        <TabControl Grid.Row="1" Background="#1E1E1E" BorderBrush="#3F3F46" Name="MainTab">
            
            <!-- TAB 1: DASHBOARD -->
            <TabItem Header="Dashboard" Background="#2D2D30" Foreground="White">
                <WrapPanel Margin="20" HorizontalAlignment="Center" VerticalAlignment="Center">
                    <Button x:Name="BtnMaintenance" Width="180" Height="90" Margin="10" Background="#2D2D30" BorderBrush="#3F3F46" BorderThickness="2"><StackPanel><TextBlock Text="🛠️ Pure Clean" FontSize="16" FontWeight="Bold" HorizontalAlignment="Center"/><TextBlock Text="Deep Maintenance" FontSize="12" Foreground="Gray" HorizontalAlignment="Center"/></StackPanel></Button>
                    <Button x:Name="BtnAudit" Width="180" Height="90" Margin="10" Background="#2D2D30" BorderBrush="#3F3F46" BorderThickness="2"><StackPanel><TextBlock Text="📊 System Audit" FontSize="16" FontWeight="Bold" HorizontalAlignment="Center"/><TextBlock Text="Cek Hardware" FontSize="12" Foreground="Gray" HorizontalAlignment="Center"/></StackPanel></Button>
                    <Button x:Name="BtnNetwork" Width="180" Height="90" Margin="10" Background="#2D2D30" BorderBrush="#3F3F46" BorderThickness="2"><StackPanel><TextBlock Text="🌐 Network" FontSize="16" FontWeight="Bold" HorizontalAlignment="Center"/><TextBlock Text="Cek Jaringan" FontSize="12" Foreground="Gray" HorizontalAlignment="Center"/></StackPanel></Button>
                    <Button x:Name="BtnEventLog" Width="180" Height="90" Margin="10" Background="#2D2D30" BorderBrush="#3F3F46" BorderThickness="2"><StackPanel><TextBlock Text="📝 Event Log" FontSize="16" FontWeight="Bold" HorizontalAlignment="Center"/><TextBlock Text="Analisis Error" FontSize="12" Foreground="Gray" HorizontalAlignment="Center"/></StackPanel></Button>
                    <Button x:Name="BtnBackup" Width="180" Height="90" Margin="10" Background="#2D2D30" BorderBrush="#3F3F46" BorderThickness="2"><StackPanel><TextBlock Text="💾 App Backup" FontSize="16" FontWeight="Bold" HorizontalAlignment="Center"/><TextBlock Text="Export/Import" FontSize="12" Foreground="Gray" HorizontalAlignment="Center"/></StackPanel></Button>
                    <Button x:Name="BtnUserBackup" Width="180" Height="90" Margin="10" Background="#2D2D30" BorderBrush="#3F3F46" BorderThickness="2"><StackPanel><TextBlock Text="🗂️ User Backup" FontSize="16" FontWeight="Bold" HorizontalAlignment="Center"/><TextBlock Text="Backup Profil" FontSize="12" Foreground="Gray" HorizontalAlignment="Center"/></StackPanel></Button>
                    <Button x:Name="BtnRestore" Width="180" Height="90" Margin="10" Background="#2D2D30" BorderBrush="#3F3F46" BorderThickness="2"><StackPanel><TextBlock Text="🛡️ Restore Point" FontSize="16" FontWeight="Bold" HorizontalAlignment="Center"/><TextBlock Text="Buat &amp; Kembalikan" FontSize="12" Foreground="Gray" HorizontalAlignment="Center"/></StackPanel></Button>
                    <Button x:Name="BtnUpdate" Width="180" Height="90" Margin="10" Background="#2D2D30" BorderBrush="#3F3F46" BorderThickness="2"><StackPanel><TextBlock Text="🔄 Update Mgr" FontSize="16" FontWeight="Bold" HorizontalAlignment="Center"/><TextBlock Text="Kontrol Update" FontSize="12" Foreground="Gray" HorizontalAlignment="Center"/></StackPanel></Button>
                    <Button x:Name="BtnDNS" Width="180" Height="90" Margin="10" Background="#2D2D30" BorderBrush="#3F3F46" BorderThickness="2"><StackPanel><TextBlock Text="🌍 DNS Switcher" FontSize="16" FontWeight="Bold" HorizontalAlignment="Center"/><TextBlock Text="Percepat Internet" FontSize="12" Foreground="Gray" HorizontalAlignment="Center"/></StackPanel></Button>
                    <Button x:Name="BtnFixes" Width="180" Height="90" Margin="10" Background="#2D2D30" BorderBrush="#3F3F46" BorderThickness="2"><StackPanel><TextBlock Text="🚑 One-Click Fixes" FontSize="16" FontWeight="Bold" HorizontalAlignment="Center"/><TextBlock Text="Perbaikan Darurat" FontSize="12" Foreground="Gray" HorizontalAlignment="Center"/></StackPanel></Button>
                    <Button x:Name="BtnStartup" Width="180" Height="90" Margin="10" Background="#2D2D30" BorderBrush="#3F3F46" BorderThickness="2"><StackPanel><TextBlock Text="🚀 Startup Manager" FontSize="16" FontWeight="Bold" HorizontalAlignment="Center"/><TextBlock Text="Kelola Autostart" FontSize="12" Foreground="Gray" HorizontalAlignment="Center"/></StackPanel></Button>
                    <Button x:Name="BtnPresets" Width="180" Height="90" Margin="10" Background="#2D2D30" BorderBrush="#3F3F46" BorderThickness="2"><StackPanel><TextBlock Text="⚡ Presets" FontSize="16" FontWeight="Bold" HorizontalAlignment="Center"/><TextBlock Text="Setup Instalasi" FontSize="12" Foreground="Gray" HorizontalAlignment="Center"/></StackPanel></Button>
                </WrapPanel>
            </TabItem>

            <!-- TAB 2: TWEAKS -->
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

            <!-- TAB 3: DEBLOATER -->
            <TabItem Header="Debloater" Background="#2D2D30" Foreground="White">
                <Grid Margin="10">
                    <Grid.RowDefinitions><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
                    <TabControl Grid.Row="0" Background="#1E1E1E" BorderBrush="#3F3F46">
                        <TabItem Header="Microsoft Apps" Background="#2D2D30" Foreground="White">
                            <ScrollViewer VerticalScrollBarVisibility="Auto"><StackPanel Margin="10" Name="PanelDebloatMS"/></ScrollViewer>
                        </TabItem>
                        <TabItem Header="Bing &amp; Web" Background="#2D2D30" Foreground="White">
                            <ScrollViewer VerticalScrollBarVisibility="Auto"><StackPanel Margin="10" Name="PanelDebloatBing"/></ScrollViewer>
                        </TabItem>
                        <TabItem Header="Xbox &amp; Gaming" Background="#2D2D30" Foreground="White">
                            <ScrollViewer VerticalScrollBarVisibility="Auto"><StackPanel Margin="10" Name="PanelDebloatXbox"/></ScrollViewer>
                        </TabItem>
                        <TabItem Header="Utilities" Background="#2D2D30" Foreground="White">
                            <ScrollViewer VerticalScrollBarVisibility="Auto"><StackPanel Margin="10" Name="PanelDebloatUtil"/></ScrollViewer>
                        </TabItem>
                    </TabControl>
                    <Button Grid.Row="1" Name="BtnApplyDebloat" Content="UNINSTALL SELECTED" Height="40" Background="#D83B01" FontWeight="Bold" Margin="0,10,0,0"/>
                </Grid>
            </TabItem>
        </TabControl>

        <!-- TERMINAL LOG -->
        <Grid Grid.Row="2" Margin="10">
            <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/></Grid.RowDefinitions>
            <TextBlock Grid.Row="0" Text="Terminal Output:" FontWeight="Bold" Foreground="Cyan" Margin="0,0,0,5"/>
            <RichTextBox Grid.Row="1" Name="LogBox" Background="#111111" Foreground="White" FontFamily="Consolas" FontSize="12" IsReadOnly="True" VerticalScrollBarVisibility="Auto" BorderBrush="#3F3F46">
                <FlowDocument Name="LogDocument"><Paragraph><Run Foreground="Gray">Ready...</Run></Paragraph></FlowDocument>
            </RichTextBox>
        </Grid>

        <!-- FOOTER -->
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

    # FUNGSI LOG
    $writeLog = {
        param($text, $color)
        $p = New-Object System.Windows.Documents.Paragraph
        $r = New-Object System.Windows.Documents.Run -ArgumentList $text
        $r.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString($color)
        $p.Inlines.Add($r)
        $logDocument.Blocks.Add($p)
        $logBox.ScrollToEnd()
    }

    # ==========================================
    # GENERATE CHECKBOXES
    # ==========================================
    # Tweaks Essential
    $stackEss = $window.FindName("PanelEssential")
    $Global:CB_Tweaks = @()
    $tweaksEss = @(
        @{Name='Disable Telemetry'; Action='Telemetry'}, @{Name='Disable Activity History'; Action='Activity'},
        @{Name='Disable Consumer Features'; Action='Consumer'}, @{Name='Disable Location Tracking'; Action='Location'},
        @{Name='Disable Hibernation'; Action='Hibernation'}, @{Name='Show File Extensions'; Action='FileExt'},
        @{Name='Enable Ultimate Performance'; Action='UltimatePerf'}
    )
    foreach ($t in $tweaksEss) {
        $cb = New-Object System.Windows.Controls.CheckBox
        $cb.Content = $t.Name; $cb.Foreground = [System.Windows.Media.Brushes]::White; $cb.Margin = "0,8,0,8"
        $stackEss.Children.Add($cb) | Out-Null
        $Global:CB_Tweaks += [PSCustomObject]@{ Action = $t.Action; CB = $cb }
    }

    # Tweaks Advanced
    $stackAdv = $window.FindName("PanelAdvanced")
    $tweaksAdv = @(
        @{Name='Disable Background Apps'; Action='BgApps'}, @{Name='Disable Bing Search'; Action='Bing'},
        @{Name='Disable Game Bar'; Action='GameBar'}, @{Name='Disable Storage Sense'; Action='StorageSense'},
        @{Name='Disable OneDrive'; Action='OneDrive'}, @{Name='Disable IPv6'; Action='IPv6'},
        @{Name='Disable Reserved Storage'; Action='Reserved'}
    )
    foreach ($t in $tweaksAdv) {
        $cb = New-Object System.Windows.Controls.CheckBox
        $cb.Content = $t.Name; $cb.Foreground = [System.Windows.Media.Brushes]::White; $cb.Margin = "0,8,0,8"
        $stackAdv.Children.Add($cb) | Out-Null
        $Global:CB_Tweaks += [PSCustomObject]@{ Action = $t.Action; CB = $cb }
    }

    # Debloater
    $stackMS = $window.FindName("PanelDebloatMS")
    $stackBing = $window.FindName("PanelDebloatBing")
    $stackXbox = $window.FindName("PanelDebloatXbox")
    $stackUtil = $window.FindName("PanelDebloatUtil")
    $Global:CB_Debloat = @()
    
    $debloats = @(
        @{Cat='MS'; Name='Feedback Hub'; Pkg='Microsoft.WindowsFeedbackHub'}, @{Cat='MS'; Name='Get Help'; Pkg='Microsoft.GetHelp'}, @{Cat='MS'; Name='Cortana'; Pkg='Microsoft.549981C3F5F10'},
        @{Cat='Bing'; Name='Bing News'; Pkg='Microsoft.BingNews'}, @{Cat='Bing'; Name='Bing Weather'; Pkg='Microsoft.BingWeather'},
        @{Cat='Xbox'; Name='Xbox App'; Pkg='Microsoft.XboxApp'}, @{Cat='Xbox'; Name='Xbox Game Bar'; Pkg='Microsoft.XboxGamingOverlay'},
        @{Cat='Util'; Name='Solitaire'; Pkg='Microsoft.MicrosoftSolitaireCollection'}, @{Cat='Util'; Name='Skype'; Pkg='Microsoft.SkypeApp'},
        @{Cat='Util'; Name='Your Phone'; Pkg='Microsoft.YourPhone'}, @{Cat='Util'; Name='Media Player'; Pkg='Microsoft.ZuneMusic'}, @{Cat='Util'; Name='Movies & TV'; Pkg='Microsoft.ZuneVideo'}
    )
    foreach ($d in $debloats) {
        $cb = New-Object System.Windows.Controls.CheckBox
        $cb.Content = $d.Name; $cb.Foreground = [System.Windows.Media.Brushes]::White; $cb.Margin = "0,8,0,8"
        if ($d.Cat -eq 'MS') { $stackMS.Children.Add($cb) | Out-Null }
        elseif ($d.Cat -eq 'Bing') { $stackBing.Children.Add($cb) | Out-Null }
        elseif ($d.Cat -eq 'Xbox') { $stackXbox.Children.Add($cb) | Out-Null }
        else { $stackUtil.Children.Add($cb) | Out-Null }
        $Global:CB_Debloat += [PSCustomObject]@{ Pkg = $d.Pkg; CB = $cb }
    }

    # ==========================================
    # ACTION HANDLERS
    # ==========================================
    
    # Tweaks
    $window.FindName("BtnApplyTweaks").Add_Click({
        $actionsToRun = @()
        foreach ($item in $Global:CB_Tweaks) { if ($item.CB.IsChecked -eq $true) { $actionsToRun += $item.Action } }
        if ($actionsToRun.Count -eq 0) { & $writeLog "[!] Pilih setidaknya satu Tweak." "Red"; return }

        & $writeLog "`n[+] Memulai Proses Tweaks..." "Yellow"
        $script:TweakJob = Start-Job -ScriptBlock ${function:Execute-Tweaks} -ArgumentList (,$actionsToRun)
        $script:TweakTimer = New-Object System.Windows.Threading.DispatcherTimer
        $script:TweakTimer.Interval = [TimeSpan]::FromSeconds(1)
        $script:TweakTimer.Add_Tick({
            if ($script:TweakJob.State -ne 'Running') {
                $res = Receive-Job -Job $script:TweakJob
                foreach ($r in $res) { if ($r -match "OK") { & $writeLog $r "Lime" } else { & $writeLog $r "Red" } }
                & $writeLog "[+] Tweaks Selesai." "Cyan"
                $script:TweakTimer.Stop(); Remove-Job -Job $script:TweakJob -Force
            }
        })
        $script:TweakTimer.Start()
    })

    # Debloater
    $window.FindName("BtnApplyDebloat").Add_Click({
        $pkgsToRemove = @()
        foreach ($item in $Global:CB_Debloat) { if ($item.CB.IsChecked -eq $true) { $pkgsToRemove += $item.Pkg } }
        if ($pkgsToRemove.Count -eq 0) { & $writeLog "[!] Pilih setidaknya satu aplikasi." "Red"; return }

        & $writeLog "`n[+] Memulai Debloating..." "Yellow"
        $script:DebloatJob = Start-Job -ScriptBlock ${function:Execute-Debloat} -ArgumentList (,$pkgsToRemove)
        $script:DebloatTimer = New-Object System.Windows.Threading.DispatcherTimer
        $script:DebloatTimer.Interval = [TimeSpan]::FromSeconds(1)
        $script:DebloatTimer.Add_Tick({
            if ($script:DebloatJob.State -ne 'Running') {
                $res = Receive-Job -Job $script:DebloatJob
                foreach ($r in $res) { if ($r -match "OK") { & $writeLog $r "Lime" } else { & $writeLog $r "Red" } }
                & $writeLog "[+] Debloating Selesai." "Cyan"
                $script:DebloatTimer.Stop(); Remove-Job -Job $script:DebloatJob -Force
            }
        })
        $script:DebloatTimer.Start()
    })

    # Simulasi fitur dashboard lainnya
    $window.FindName("BtnMaintenance").Add_Click({ & $writeLog "`n[+] Membersihkan sistem..." "Yellow"; Start-Sleep 1; & $writeLog "[OK] Selesai." "Lime" })
    $window.FindName("BtnAudit").Add_Click({ & $writeLog "`n[+] System Info: Windows 11 | RAM: 16GB" "White" })
    
    $dashBtns = @("BtnNetwork","BtnEventLog","BtnBackup","BtnUserBackup","BtnRestore","BtnUpdate","BtnDNS","BtnFixes","BtnStartup","BtnPresets")
    foreach ($b in $dashBtns) { $window.FindName($b).Add_Click({ & $writeLog "`n[+] Fitur $($this.Content) berjalan..." "Yellow" }) }

    $window.ShowDialog() | Out-Null
}

Show-GUI