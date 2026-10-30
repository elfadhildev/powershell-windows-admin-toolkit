if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -Command `"irm https://raw.githubusercontent.com/elfadhildev/powershell-windows-admin-toolkit/main/toolkit.ps1 | iex`"" -Verb RunAs
    exit
}

# ==========================================
# FUNGSI BANTUAN (Terminal)
# ==========================================
function Backup-RegistryTweaks {
    $backupDir = "$env:USERPROFILE\Desktop\ToolkitRegistryBackup"
    if (-not (Test-Path $backupDir)) { New-Item -Path $backupDir -ItemType Directory -Force | Out-Null }
    $time = Get-Date -Format "yyyyMMdd_HHmmss"
    $regFile = Join-Path $backupDir "Explorer_Advanced_$time.reg"
    Start-Process cmd -ArgumentList "/c reg export `"HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced`" `"$regFile`" /y" -Wait -NoNewWindow
}

# ==========================================
# FUNGSI EKSEKUSI (Dijalankan di jendela baru)
# ==========================================
function Invoke-Maintenance {
    Clear-Host; Write-Host "========== MAINTENANCE PC ==========" -ForegroundColor Cyan
    Write-Host "[+] Membersihkan Cache DNS..." -ForegroundColor Yellow
    Clear-DnsClientCache; ipconfig /release | Out-Null; ipconfig /renew | Out-Null
    Write-Host "[+] Membersihkan File Sementara..." -ForegroundColor Yellow
    $TempFolders = @("$env:TEMP", "C:\Windows\Temp", "C:\Windows\Prefetch", "C:\Windows\SoftwareDistribution\Download")
    foreach ($Folder in $TempFolders) { if (Test-Path $Folder) { Get-ChildItem -Path $Folder -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue } }
    Start-Process cleanmgr.exe -ArgumentList "/sagerun:1" -NoNewWindow -Wait
    Write-Host " -> Optimasi selesai." -ForegroundColor Green
    Read-Host "`nTekan Enter untuk kembali..."
}

function Invoke-SystemAudit {
    Clear-Host; Write-Host "========== SISTEM AUDIT ==========" -ForegroundColor Cyan
    $os = Get-CimInstance Win32_OperatingSystem; $cpu = Get-CimInstance Win32_Processor; $ram = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)
    Write-Host " OS: $($os.Caption) | CPU: $($cpu.Name) | RAM: $ram GB"
    Write-Host "`n[+] Storage:" -ForegroundColor Yellow
    Get-PhysicalDisk | Select-Object DeviceId, FriendlyName, MediaType, HealthStatus, @{N='Size(GB)';E={[math]::Round($_.Size/1GB,2)}} | Format-Table -AutoSize
    Read-Host "`nTekan Enter untuk kembali..."
}

function Invoke-NetworkDiagnostics {
    Clear-Host; Write-Host "========== DIAGNOSTIK JARINGAN ==========" -ForegroundColor Cyan
    Get-NetIPConfiguration | Where-Object { $_.IPv4Address } | Select-Object InterfaceAlias, IPv4Address, @{N='DNS';E={$_.DNSServer.ServerAddresses -join ', '}} | Format-List
    Read-Host "`nTekan Enter untuk kembali..."
}

function Invoke-WindowsDebloater {
    Clear-Host; Write-Host "========== WINDOWS DEBLOATER ==========" -ForegroundColor Cyan
    Write-Host "Fitur Debloater Terminal (v1.10.1) berjalan di sini..."
    Read-Host "`nTekan Enter untuk kembali..."
}

function Invoke-SystemTweaks {
    Clear-Host; Write-Host "========== SYSTEM TWEAKS ==========" -ForegroundColor Cyan
    Write-Host "Fitur Tweaks Terminal (v1.10.1) berjalan di sini..."
    Read-Host "`nTekan Enter untuk kembali..."
}

# ==========================================
# GUI (WPF) - ANTARMUKA v2.0.0
# ==========================================
function Show-GUI {
    # 1. Definisikan Desain GUI (XAML)
    [xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Panduan PowerShell - Control Panel v2.0.0" Height="600" Width="900"
        WindowStartupLocation="CenterScreen" Background="#1E1E1E" Foreground="White">
    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="60"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="40"/>
        </Grid.RowDefinitions>

        <!-- Header -->
        <Border Grid.Row="0" Background="#0078D7">
            <TextBlock Text="PANDUAN POWERSHELL - CONTROL PANEL" FontSize="20" FontWeight="Bold" VerticalAlignment="Center" HorizontalAlignment="Center" Foreground="White"/>
        </Border>

        <!-- Main Content (Tiles) -->
        <WrapPanel Grid.Row="1" Margin="20" HorizontalAlignment="Center" VerticalAlignment="Center">
            <!-- Tile 1: Maintenance -->
            <Button x:Name="BtnMaintenance" Width="200" Height="100" Margin="10" Background="#2D2D30" BorderBrush="#3F3F46" BorderThickness="2">
                <StackPanel>
                    <TextBlock Text="🛠️ Maintenance" FontSize="18" FontWeight="Bold" Foreground="White" HorizontalAlignment="Center"/>
                    <TextBlock Text="Bersihkan &amp; Optimasi" FontSize="12" Foreground="Gray" HorizontalAlignment="Center" Margin="0,5,0,0"/>
                </StackPanel>
            </Button>

            <!-- Tile 2: System Audit -->
            <Button x:Name="BtnAudit" Width="200" Height="100" Margin="10" Background="#2D2D30" BorderBrush="#3F3F46" BorderThickness="2">
                <StackPanel>
                    <TextBlock Text="📊 System Audit" FontSize="18" FontWeight="Bold" Foreground="White" HorizontalAlignment="Center"/>
                    <TextBlock Text="Cek Hardware &amp; OS" FontSize="12" Foreground="Gray" HorizontalAlignment="Center" Margin="0,5,0,0"/>
                </StackPanel>
            </Button>

            <!-- Tile 3: Network -->
            <Button x:Name="BtnNetwork" Width="200" Height="100" Margin="10" Background="#2D2D30" BorderBrush="#3F3F46" BorderThickness="2">
                <StackPanel>
                    <TextBlock Text="🌐 Network" FontSize="18" FontWeight="Bold" Foreground="White" HorizontalAlignment="Center"/>
                    <TextBlock Text="Cek Jaringan &amp; IP" FontSize="12" Foreground="Gray" HorizontalAlignment="Center" Margin="0,5,0,0"/>
                </StackPanel>
            </Button>

            <!-- Tile 4: Debloater -->
            <Button x:Name="BtnDebloater" Width="200" Height="100" Margin="10" Background="#2D2D30" BorderBrush="#3F3F46" BorderThickness="2">
                <StackPanel>
                    <TextBlock Text="🧹 Debloater" FontSize="18" FontWeight="Bold" Foreground="White" HorizontalAlignment="Center"/>
                    <TextBlock Text="Hapus Bloatware" FontSize="12" Foreground="Gray" HorizontalAlignment="Center" Margin="0,5,0,0"/>
                </StackPanel>
            </Button>

            <!-- Tile 5: Tweaks -->
            <Button x:Name="BtnTweaks" Width="200" Height="100" Margin="10" Background="#2D2D30" BorderBrush="#3F3F46" BorderThickness="2">
                <StackPanel>
                    <TextBlock Text="⚙️ Tweaks" FontSize="18" FontWeight="Bold" Foreground="White" HorizontalAlignment="Center"/>
                    <TextBlock Text="Privasi &amp; Performa" FontSize="12" Foreground="Gray" HorizontalAlignment="Center" Margin="0,5,0,0"/>
                </StackPanel>
            </Button>
        </WrapPanel>

        <!-- Footer -->
        <Border Grid.Row="2" Background="#2D2D30">
            <TextBlock x:Name="TxtStatus" Text="Ready." FontSize="12" VerticalAlignment="Center" HorizontalAlignment="Center" Foreground="Gray"/>
        </Border>
    </Grid>
</Window>
"@

    # 2. Load XAML
    $reader = (New-Object System.Xml.XmlNodeReader $xaml)
    $window = [Windows.Markup.XamlReader]::Load($reader)

    # 3. Ambil elemen dari XAML
    $btnMaintenance = $window.FindName("BtnMaintenance")
    $btnAudit = $window.FindName("BtnAudit")
    $btnNetwork = $window.FindName("BtnNetwork")
    $btnDebloater = $window.FindName("BtnDebloater")
    $btnTweaks = $window.FindName("BtnTweaks")
    $txtStatus = $window.FindName("TxtStatus")

    # 4. Tambahkan Aksi (Event Handler)
    # Setiap tombol membuka jendela terminal baru agar UI tidak freeze
    $btnMaintenance.Add_Click({
        $txtStatus.Text = "Menjalankan Maintenance..."
        Start-Process powershell -ArgumentList "-NoExit", "-Command", "& { $($function:Invoke-Maintenance.ToString()) }" -Verb RunAs
    })

    $btnAudit.Add_Click({
        $txtStatus.Text = "Menjalankan System Audit..."
        Start-Process powershell -ArgumentList "-NoExit", "-Command", "& { $($function:Invoke-SystemAudit.ToString()) }"
    })

    $btnNetwork.Add_Click({
        $txtStatus.Text = "Menjalankan Network Diagnostics..."
        Start-Process powershell -ArgumentList "-NoExit", "-Command", "& { $($function:Invoke-NetworkDiagnostics.ToString()) }"
    })

    $btnDebloater.Add_Click({
        $txtStatus.Text = "Menjalankan Debloater..."
        Start-Process powershell -ArgumentList "-NoExit", "-Command", "& { $($function:Invoke-WindowsDebloater.ToString()) }" -Verb RunAs
    })

    $btnTweaks.Add_Click({
        $txtStatus.Text = "Menjalankan System Tweaks..."
        Start-Process powershell -ArgumentList "-NoExit", "-Command", "& { $($function:Invoke-SystemTweaks.ToString()) }" -Verb RunAs
    })

    # 5. Tampilkan Window
    $window.ShowDialog() | Out-Null
}

# Panggil Fungsi GUI
Show-GUI
