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
# DATA GLOBAL: TWEAKS
# ==========================================
$Global:TweakList = @(
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
# DATA GLOBAL: APPS
# ==========================================
$Global:AppList = @(
    [PSCustomObject]@{ Id=1; Cat='Browsers'; Name='Brave'; Pkg='Brave.Brave' }
    [PSCustomObject]@{ Id=2; Cat='Browsers'; Name='Chrome'; Pkg='Google.Chrome' }
    [PSCustomObject]@{ Id=3; Cat='Browsers'; Name='Chromium'; Pkg='Hibbiki.Chromium' }
    [PSCustomObject]@{ Id=4; Cat='Browsers'; Name='Edge'; Pkg='Microsoft.Edge' }
    [PSCustomObject]@{ Id=5; Cat='Browsers'; Name='Firefox'; Pkg='Mozilla.Firefox' }
    [PSCustomObject]@{ Id=6; Cat='Browsers'; Name='Firefox ESR'; Pkg='Mozilla.Firefox.ESR' }
    [PSCustomObject]@{ Id=7; Cat='Browsers'; Name='Floorp'; Pkg='Ablaze.Floorp' }
    [PSCustomObject]@{ Id=8; Cat='Browsers'; Name='Helium'; Pkg='imputnet.Helium' }
    [PSCustomObject]@{ Id=9; Cat='Browsers'; Name='LibreWolf'; Pkg='LibreWolf.LibreWolf' }
    [PSCustomObject]@{ Id=10; Cat='Browsers'; Name='Mullvad Browser'; Pkg='Mullvad.MullvadBrowser' }
    [PSCustomObject]@{ Id=11; Cat='Browsers'; Name='Tor Browser'; Pkg='TorProject.TorBrowser' }
    [PSCustomObject]@{ Id=12; Cat='Browsers'; Name='Ungoogled Chromium'; Pkg='eloston.ungoogled-chromium' }
    [PSCustomObject]@{ Id=13; Cat='Browsers'; Name='Vivaldi'; Pkg='Vivaldi.Vivaldi' }
    [PSCustomObject]@{ Id=14; Cat='Browsers'; Name='Waterfox'; Pkg='Waterfox.Waterfox' }
    [PSCustomObject]@{ Id=15; Cat='Browsers'; Name='Zen Browser'; Pkg='Zen-Team.Zen-Browser' }

    [PSCustomObject]@{ Id=16; Cat='Comms'; Name='Betterbird'; Pkg='Betterbird.Betterbird' }
    [PSCustomObject]@{ Id=17; Cat='Comms'; Name='Chatterino'; Pkg='Chatterino.Chatterino' }
    [PSCustomObject]@{ Id=18; Cat='Comms'; Name='Discord'; Pkg='Discord.Discord' }
    [PSCustomObject]@{ Id=19; Cat='Comms'; Name='Dorion'; Pkg='Dorion.Dorion' }
    [PSCustomObject]@{ Id=20; Cat='Comms'; Name='Element'; Pkg='Element.Element' }
    [PSCustomObject]@{ Id=21; Cat='Comms'; Name='Proton Mail'; Pkg='Proton.ProtonMail' }
    [PSCustomObject]@{ Id=22; Cat='Comms'; Name='QTox'; Pkg='Tox.QTox' }
    [PSCustomObject]@{ Id=23; Cat='Comms'; Name='Signal'; Pkg='OpenWhisperSystems.Signal' }
    [PSCustomObject]@{ Id=24; Cat='Comms'; Name='Slack'; Pkg='SlackTechnologies.Slack' }
    [PSCustomObject]@{ Id=25; Cat='Comms'; Name='Teams'; Pkg='Microsoft.Teams' }
    [PSCustomObject]@{ Id=26; Cat='Comms'; Name='TeamSpeak 3'; Pkg='TeamSpeak.TeamSpeak3' }
    [PSCustomObject]@{ Id=27; Cat='Comms'; Name='Thunderbird'; Pkg='Mozilla.Thunderbird' }
    [PSCustomObject]@{ Id=28; Cat='Comms'; Name='Veskop'; Pkg='Veskop.Veskop' }
    [PSCustomObject]@{ Id=29; Cat='Comms'; Name='Viber'; Pkg='Viber.Viber' }
    [PSCustomObject]@{ Id=30; Cat='Comms'; Name='WhatsApp Desktop'; Pkg='WhatsApp.WhatsApp' }
    [PSCustomObject]@{ Id=31; Cat='Comms'; Name='Zoom'; Pkg='Zoom.Zoom' }

    [PSCustomObject]@{ Id=32; Cat='Dev'; Name='Bruno'; Pkg='Bruno.Bruno' }
    [PSCustomObject]@{ Id=33; Cat='Dev'; Name='ChatGPT Desktop'; Pkg='lencx.ChatGPT' }
    [PSCustomObject]@{ Id=34; Cat='Dev'; Name='Claude Desktop'; Pkg='Anthropic.Claude' }
    [PSCustomObject]@{ Id=35; Cat='Dev'; Name='Claude Code'; Pkg='Anthropic.ClaudeCode' }
    [PSCustomObject]@{ Id=36; Cat='Dev'; Name='CMake'; Pkg='Kitware.CMake' }
    [PSCustomObject]@{ Id=37; Cat='Dev'; Name='Codex'; Pkg='Codex.Codex' }
    [PSCustomObject]@{ Id=38; Cat='Dev'; Name='Cursor'; Pkg='Cursor.Cursor' }
    [PSCustomObject]@{ Id=39; Cat='Dev'; Name='Docker Desktop'; Pkg='Docker.DockerDesktop' }
    [PSCustomObject]@{ Id=40; Cat='Dev'; Name='Fast Node Manager'; Pkg='Schniz.fnm' }
    [PSCustomObject]@{ Id=41; Cat='Dev'; Name='Git'; Pkg='Git.Git' }
    [PSCustomObject]@{ Id=42; Cat='Dev'; Name='Git Extensions'; Pkg='GitExtensionsTeam.GitExtensions' }
    [PSCustomObject]@{ Id=43; Cat='Dev'; Name='GitHub CLI'; Pkg='GitHub.cli' }
    [PSCustomObject]@{ Id=44; Cat='Dev'; Name='GitHub Desktop'; Pkg='GitHub.GitHubDesktop' }
    [PSCustomObject]@{ Id=45; Cat='Dev'; Name='Go'; Pkg='GoLang.Go' }
    [PSCustomObject]@{ Id=46; Cat='Dev'; Name='Amazon Corretto 21'; Pkg='Amazon.Corretto.21' }
    [PSCustomObject]@{ Id=47; Cat='Dev'; Name='Amazon Corretto 17'; Pkg='Amazon.Corretto.17' }
    [PSCustomObject]@{ Id=48; Cat='Dev'; Name='Amazon Corretto 8'; Pkg='Amazon.Corretto.8' }
    [PSCustomObject]@{ Id=49; Cat='Dev'; Name='Jetbrains Toolbox'; Pkg='JetBrains.Toolbox' }
    [PSCustomObject]@{ Id=50; Cat='Dev'; Name='Lazygit'; Pkg='JesseDuffield.lazygit' }
    [PSCustomObject]@{ Id=51; Cat='Dev'; Name='Lua'; Pkg='Lua.Lua' }
    [PSCustomObject]@{ Id=52; Cat='Dev'; Name='Neovim'; Pkg='Neovim.Neovim' }
    [PSCustomObject]@{ Id=53; Cat='Dev'; Name='NodeJS'; Pkg='OpenJS.NodeJS' }
    [PSCustomObject]@{ Id=54; Cat='Dev'; Name='NodeJS LTS'; Pkg='OpenJS.NodeJS.LTS' }
    [PSCustomObject]@{ Id=55; Cat='Dev'; Name='pnpm'; Pkg='pnpm.pnpm' }
    [PSCustomObject]@{ Id=56; Cat='Dev'; Name='Oh My Posh'; Pkg='JanDeDobbeleer.OhMyPosh' }
    [PSCustomObject]@{ Id=57; Cat='Dev'; Name='Postman'; Pkg='Postman.Postman' }
    [PSCustomObject]@{ Id=58; Cat='Dev'; Name='Python3'; Pkg='Python.Python.3.12' }
    [PSCustomObject]@{ Id=59; Cat='Dev'; Name='Ruby'; Pkg='RubyInstallerTeam.Ruby' }
    [PSCustomObject]@{ Id=60; Cat='Dev'; Name='Rust'; Pkg='Rustlang.Rustup' }
    [PSCustomObject]@{ Id=61; Cat='Dev'; Name='Starship'; Pkg='Starship.Starship' }
    [PSCustomObject]@{ Id=62; Cat='Dev'; Name='Sublime Text'; Pkg='SublimeHQ.SublimeText.4' }
    [PSCustomObject]@{ Id=63; Cat='Dev'; Name='System Informer'; Pkg='WinsiderSS.SystemInformer' }
    [PSCustomObject]@{ Id=64; Cat='Dev'; Name='Unity Game Engine'; Pkg='Unity.UnityHub' }
    [PSCustomObject]@{ Id=65; Cat='Dev'; Name='uv'; Pkg='astral-sh.uv' }
    [PSCustomObject]@{ Id=66; Cat='Dev'; Name='Vagrant'; Pkg='HashiCorp.Vagrant' }
    [PSCustomObject]@{ Id=67; Cat='Dev'; Name='Visual Studio 2022'; Pkg='Microsoft.VisualStudio.2022.Community' }
    [PSCustomObject]@{ Id=68; Cat='Dev'; Name='VS Code'; Pkg='Microsoft.VisualStudioCode' }
    [PSCustomObject]@{ Id=69; Cat='Dev'; Name='VS Codium'; Pkg='VSCodium.VSCodium' }
    [PSCustomObject]@{ Id=70; Cat='Dev'; Name='Yarn'; Pkg='Yarn.Yarn' }
    [PSCustomObject]@{ Id=71; Cat='Dev'; Name='Zed'; Pkg='ZedIndustries.Zed' }

    [PSCustomObject]@{ Id=72; Cat='Doc'; Name='Adobe Acrobat'; Pkg='Adobe.Acrobat.Reader.64-bit' }
    [PSCustomObject]@{ Id=73; Cat='Doc'; Name='Foxit PDF Reader'; Pkg='Foxit.FoxitReader' }
    [PSCustomObject]@{ Id=74; Cat='Doc'; Name='Joplin'; Pkg='Joplin.Joplin' }
    [PSCustomObject]@{ Id=75; Cat='Doc'; Name='LibreOffice'; Pkg='TheDocumentFoundation.LibreOffice' }
    [PSCustomObject]@{ Id=76; Cat='Doc'; Name='NAPS2'; Pkg='Cyanfish.NAPS2' }
    [PSCustomObject]@{ Id=77; Cat='Doc'; Name='Obsidian'; Pkg='Obsidian.Obsidian' }
    [PSCustomObject]@{ Id=78; Cat='Doc'; Name='Okular'; Pkg='KDE.Okular' }
    [PSCustomObject]@{ Id=79; Cat='Doc'; Name='ONLYOFFICE Desktop'; Pkg='ONLYOFFICE.DesktopEditors' }
    [PSCustomObject]@{ Id=80; Cat='Doc'; Name='PDF24 Creator'; Pkg='PDF24.PDF24Creator' }
    [PSCustomObject]@{ Id=81; Cat='Doc'; Name='PDFgear'; Pkg='PDFgear.PDFgear' }
    [PSCustomObject]@{ Id=82; Cat='Doc'; Name='PDFsam Basic'; Pkg='PDFsam.PDFsam' }
    [PSCustomObject]@{ Id=83; Cat='Doc'; Name='PDF-XChange Editor'; Pkg='TrackerSoftware.PDF-XChangeEditor' }
    [PSCustomObject]@{ Id=84; Cat='Doc'; Name='QOwnNotes'; Pkg='QOwnNotes.QOwnNotes' }
    [PSCustomObject]@{ Id=85; Cat='Doc'; Name='Simplenote'; Pkg='Automattic.Simplenote' }
    [PSCustomObject]@{ Id=86; Cat='Doc'; Name='Sumatra PDF'; Pkg='SumatraPDF.SumatraPDF' }
    [PSCustomObject]@{ Id=87; Cat='Doc'; Name='Xournal++'; Pkg='Xournal++.Xournal++' }
    [PSCustomObject]@{ Id=88; Cat='Doc'; Name='Zotero'; Pkg='DigitalScholar.Zotero' }

    [PSCustomObject]@{ Id=89; Cat='Games'; Name='Battle.net'; Pkg='Blizzard.BattleNet' }
    [PSCustomObject]@{ Id=90; Cat='Games'; Name='Cemu'; Pkg='Cemu.Cemu' }
    [PSCustomObject]@{ Id=91; Cat='Games'; Name='EA App'; Pkg='ElectronicArts.EADesktop' }
    [PSCustomObject]@{ Id=92; Cat='Games'; Name='Epic Games Launcher'; Pkg='EpicGames.EpicGamesLauncher' }
    [PSCustomObject]@{ Id=93; Cat='Games'; Name='EmulationStation Desktop'; Pkg='EmulationStation.EmulationStation' }
    [PSCustomObject]@{ Id=94; Cat='Games'; Name='GeForce NOW'; Pkg='Nvidia.GeForceNow' }
    [PSCustomObject]@{ Id=95; Cat='Games'; Name='GOG Galaxy'; Pkg='GOG.Galaxy' }
    [PSCustomObject]@{ Id=96; Cat='Games'; Name='Heroic Games Launcher'; Pkg='HeroicGamesLauncher.HeroicGamesLauncher' }
    [PSCustomObject]@{ Id=97; Cat='Games'; Name='Itch.io'; Pkg='ItchIo.Itch' }
    [PSCustomObject]@{ Id=98; Cat='Games'; Name='Modrinth App'; Pkg='Modrinth.ModrinthApp' }
    [PSCustomObject]@{ Id=99; Cat='Games'; Name='CurseForge'; Pkg='Overwolf.CurseForge' }
    [PSCustomObject]@{ Id=100; Cat='Games'; Name='Playnite'; Pkg='Playnite.Playnite' }
    [PSCustomObject]@{ Id=101; Cat='Games'; Name='Prism Launcher'; Pkg='PrismLauncher.PrismLauncher' }
    [PSCustomObject]@{ Id=102; Cat='Games'; Name='Roblox'; Pkg='Roblox.Roblox' }
    [PSCustomObject]@{ Id=103; Cat='Games'; Name='Steam'; Pkg='Valve.Steam' }
    [PSCustomObject]@{ Id=104; Cat='Games'; Name='Ubisoft Connect'; Pkg='Ubisoft.Connect' }
    [PSCustomObject]@{ Id=105; Cat='Games'; Name='Virtual Desktop'; Pkg='VirtualDesktop.VirtualDesktop' }

    [PSCustomObject]@{ Id=106; Cat='Microsoft Tools'; Name='Autoruns'; Pkg='Microsoft.Sysinternals.Autoruns' }
    [PSCustomObject]@{ Id=107; Cat='Microsoft Tools'; Name='DISMTools'; Pkg='CodingWonders.DISMTools' }
    [PSCustomObject]@{ Id=108; Cat='Microsoft Tools'; Name='.NET Desktop Runtime 6'; Pkg='Microsoft.DotNet.DesktopRuntime.6' }
    [PSCustomObject]@{ Id=109; Cat='Microsoft Tools'; Name='.NET Desktop Runtime 8'; Pkg='Microsoft.DotNet.DesktopRuntime.8' }
    [PSCustomObject]@{ Id=110; Cat='Microsoft Tools'; Name='.NET Desktop Runtime 9'; Pkg='Microsoft.DotNet.DesktopRuntime.9' }
    [PSCustomObject]@{ Id=111; Cat='Microsoft Tools'; Name='NTLite'; Pkg='Nlitesoft.NTLite' }
    [PSCustomObject]@{ Id=112; Cat='Microsoft Tools'; Name='NuGet'; Pkg='Microsoft.NuGet' }
    [PSCustomObject]@{ Id=113; Cat='Microsoft Tools'; Name='OneDrive'; Pkg='Microsoft.OneDrive' }
    [PSCustomObject]@{ Id=114; Cat='Microsoft Tools'; Name='PowerShell'; Pkg='Microsoft.PowerShell' }
    [PSCustomObject]@{ Id=115; Cat='Microsoft Tools'; Name='PowerToys'; Pkg='Microsoft.PowerToys' }
    [PSCustomObject]@{ Id=116; Cat='Microsoft Tools'; Name='Process Explorer'; Pkg='Microsoft.Sysinternals.ProcessExplorer' }
    [PSCustomObject]@{ Id=117; Cat='Microsoft Tools'; Name='Process Monitor'; Pkg='Microsoft.Sysinternals.ProcessMonitor' }
    [PSCustomObject]@{ Id=118; Cat='Microsoft Tools'; Name='RDCMan'; Pkg='Microsoft.Sysinternals.RDCMan' }
    [PSCustomObject]@{ Id=119; Cat='Microsoft Tools'; Name='TCPView'; Pkg='Microsoft.Sysinternals.TCPView' }
    [PSCustomObject]@{ Id=120; Cat='Microsoft Tools'; Name='Windows Terminal'; Pkg='Microsoft.WindowsTerminal' }
    [PSCustomObject]@{ Id=121; Cat='Microsoft Tools'; Name='Visual C++ 2015-2022 (x86)'; Pkg='Microsoft.VCRedist.2015+.x86' }
    [PSCustomObject]@{ Id=122; Cat='Microsoft Tools'; Name='Visual C++ 2015-2022 (x64)'; Pkg='Microsoft.VCRedist.2015+.x64' }

    [PSCustomObject]@{ Id=123; Cat='Multimedia'; Name='AIMP'; Pkg='AIMP.AIMP' }
    [PSCustomObject]@{ Id=124; Cat='Multimedia'; Name='Audacity'; Pkg='Audacity.Audacity' }
    [PSCustomObject]@{ Id=125; Cat='Multimedia'; Name='Blender'; Pkg='BlenderFoundation.Blender' }
    [PSCustomObject]@{ Id=126; Cat='Multimedia'; Name='Calibre'; Pkg='calibre.calibre' }
    [PSCustomObject]@{ Id=127; Cat='Multimedia'; Name='EarTrumpet'; Pkg='File-New-Project.EarTrumpet' }
    [PSCustomObject]@{ Id=128; Cat='Multimedia'; Name='File Converter'; Pkg='Tichau.File-Converter' }
    [PSCustomObject]@{ Id=129; Cat='Multimedia'; Name='foobar2000'; Pkg='PeterPawlowski.foobar2000' }
    [PSCustomObject]@{ Id=130; Cat='Multimedia'; Name='GIMP'; Pkg='GIMP.GIMP' }
    [PSCustomObject]@{ Id=131; Cat='Multimedia'; Name='HandBrake'; Pkg='HandBrake.HandBrake' }
    [PSCustomObject]@{ Id=132; Cat='Multimedia'; Name='ImageGlass'; Pkg='DuongDieuPhap.ImageGlass' }
    [PSCustomObject]@{ Id=133; Cat='Multimedia'; Name='IrfanView'; Pkg='IrfanSkiljan.IrfanView' }
    [PSCustomObject]@{ Id=134; Cat='Multimedia'; Name='iTunes'; Pkg='Apple.iTunes' }
    [PSCustomObject]@{ Id=135; Cat='Multimedia'; Name='K-Lite Codec Standard'; Pkg='CodecGuide.K-LiteCodecPack.Standard' }
    [PSCustomObject]@{ Id=136; Cat='Multimedia'; Name='Media Player Classic'; Pkg='clsid2.mpc-hc' }
    [PSCustomObject]@{ Id=137; Cat='Multimedia'; Name='mpv'; Pkg='mpv.net' }
    [PSCustomObject]@{ Id=138; Cat='Multimedia'; Name='nomacs'; Pkg='nomacs.nomacs' }
    [PSCustomObject]@{ Id=139; Cat='Multimedia'; Name='Notepad++'; Pkg='Notepad++.Notepad++' }
    [PSCustomObject]@{ Id=140; Cat='Multimedia'; Name='OBS Studio'; Pkg='OBSProject.OBSStudio' }
    [PSCustomObject]@{ Id=141; Cat='Multimedia'; Name='Paint.NET'; Pkg='dotPDN.PaintDotNet' }
    [PSCustomObject]@{ Id=142; Cat='Multimedia'; Name='ShareX'; Pkg='ShareX.ShareX' }
    [PSCustomObject]@{ Id=143; Cat='Multimedia'; Name='VLC'; Pkg='VideoLAN.VLC' }

    [PSCustomObject]@{ Id=144; Cat='Pro Tools'; Name='Advanced IP Scanner'; Pkg='Famatech.AdvancedIPScanner' }
    [PSCustomObject]@{ Id=145; Cat='Pro Tools'; Name='Angry IP Scanner'; Pkg='angryip.angryipscanner' }
    [PSCustomObject]@{ Id=146; Cat='Pro Tools'; Name='Cinebench R23'; Pkg='Maxon.CinebenchR23' }
    [PSCustomObject]@{ Id=147; Cat='Pro Tools'; Name='CPU-Z'; Pkg='CPUID.CPU-Z' }
    [PSCustomObject]@{ Id=148; Cat='Pro Tools'; Name='Display Driver Uninstaller'; Pkg='Wagnardsoft.DisplayDriverUninstaller' }
    [PSCustomObject]@{ Id=149; Cat='Pro Tools'; Name='GPU-Z'; Pkg='TechPowerUp.GPU-Z' }
    [PSCustomObject]@{ Id=150; Cat='Pro Tools'; Name='gsudo'; Pkg='gerardog.gsudo' }
    [PSCustomObject]@{ Id=151; Cat='Pro Tools'; Name='HWiNFO'; Pkg='REALiX.HWiNFO' }
    [PSCustomObject]@{ Id=152; Cat='Pro Tools'; Name='HWMonitor'; Pkg='CPUID.HWMonitor' }
    [PSCustomObject]@{ Id=153; Cat='Pro Tools'; Name='Mullvad VPN'; Pkg='Mullvad.MullvadVPN' }
    [PSCustomObject]@{ Id=154; Cat='Pro Tools'; Name='Nmap'; Pkg='Insecure.Nmap' }
    [PSCustomObject]@{ Id=155; Cat='Pro Tools'; Name='OpenVPN Connect'; Pkg='OpenVPNTechnologies.OpenVPNConnect' }
    [PSCustomObject]@{ Id=156; Cat='Pro Tools'; Name='Proton VPN'; Pkg='Proton.ProtonVPN' }
    [PSCustomObject]@{ Id=157; Cat='Pro Tools'; Name='PuTTY'; Pkg='PuTTY.PuTTY' }
    [PSCustomObject]@{ Id=158; Cat='Pro Tools'; Name='Simplewall'; Pkg='Henry++.simplewall' }
    [PSCustomObject]@{ Id=159; Cat='Pro Tools'; Name='Ventoy'; Pkg='Ventoy.Ventoy' }
    [PSCustomObject]@{ Id=160; Cat='Pro Tools'; Name='WinSCP'; Pkg='WinSCP.WinSCP' }
    [PSCustomObject]@{ Id=161; Cat='Pro Tools'; Name='WireGuard'; Pkg='WireGuard.WireGuard' }
    [PSCustomObject]@{ Id=162; Cat='Pro Tools'; Name='Wireshark'; Pkg='WiresharkFoundation.Wireshark' }

    [PSCustomObject]@{ Id=163; Cat='Selfhosted'; Name='Jellyfin Media Player'; Pkg='Jellyfin.JellyfinMediaPlayer' }
    [PSCustomObject]@{ Id=164; Cat='Selfhosted'; Name='Jellyfin Server'; Pkg='Jellyfin.Server' }
    [PSCustomObject]@{ Id=165; Cat='Selfhosted'; Name='Kodi Media Center'; Pkg='XBMCFoundation.Kodi' }
    [PSCustomObject]@{ Id=166; Cat='Selfhosted'; Name='LocalSend'; Pkg='LocalSend.LocalSend' }
    [PSCustomObject]@{ Id=167; Cat='Selfhosted'; Name='Moonlight'; Pkg='MoonlightGameStreaming.Moonlight' }
    [PSCustomObject]@{ Id=168; Cat='Selfhosted'; Name='NetBird'; Pkg='NetBird.NetBird' }
    [PSCustomObject]@{ Id=169; Cat='Selfhosted'; Name='Nextcloud Desktop'; Pkg='Nextcloud.NextcloudDesktop' }
    [PSCustomObject]@{ Id=170; Cat='Selfhosted'; Name='Plex Media Server'; Pkg='Plex.PlexMediaServer' }
    [PSCustomObject]@{ Id=171; Cat='Selfhosted'; Name='Plex Desktop'; Pkg='Plex.PlexDesktop' }
    [PSCustomObject]@{ Id=172; Cat='Selfhosted'; Name='Sunshine'; Pkg='LizardByte.Sunshine' }
    [PSCustomObject]@{ Id=173; Cat='Selfhosted'; Name='Syncthing'; Pkg='Syncthing.Syncthing' }
    [PSCustomObject]@{ Id=174; Cat='Selfhosted'; Name='SyncTrayzor'; Pkg='SyncTrayzor.SyncTrayzor' }

    [PSCustomObject]@{ Id=175; Cat='Utilities'; Name='1Password'; Pkg='AgileBits.1Password' }
    [PSCustomObject]@{ Id=176; Cat='Utilities'; Name='7-Zip'; Pkg='7zip.7zip' }
    [PSCustomObject]@{ Id=177; Cat='Utilities'; Name='AB Download Manager'; Pkg='AmirHosseinAbdolmotallebi.ABDownloadManager' }
    [PSCustomObject]@{ Id=178; Cat='Utilities'; Name='AnyDesk'; Pkg='AnyDeskSoftwareGmbH.AnyDesk' }
    [PSCustomObject]@{ Id=179; Cat='Utilities'; Name='AutoHotkey'; Pkg='AutoHotkey.AutoHotkey' }
    [PSCustomObject]@{ Id=180; Cat='Utilities'; Name='Bitwarden'; Pkg='Bitwarden.Bitwarden' }
    [PSCustomObject]@{ Id=181; Cat='Utilities'; Name='BlurAutoClicker'; Pkg='BlurAutoClicker.BlurAutoClicker' }
    [PSCustomObject]@{ Id=182; Cat='Utilities'; Name='Bulk Crap Uninstaller'; Pkg='Klocman.BulkCrapUninstaller' }
    [PSCustomObject]@{ Id=183; Cat='Utilities'; Name='Cloudflare WARP'; Pkg='Cloudflare.Warp' }
    [PSCustomObject]@{ Id=184; Cat='Utilities'; Name='Crystal Disk Info'; Pkg='CrystalDewWorld.CrystalDiskInfo' }
    [PSCustomObject]@{ Id=185; Cat='Utilities'; Name='Crystal Disk Mark'; Pkg='CrystalDewWorld.CrystalDiskMark' }
    [PSCustomObject]@{ Id=186; Cat='Utilities'; Name='Deskflow'; Pkg='Deskflow.Deskflow' }
    [PSCustomObject]@{ Id=187; Cat='Utilities'; Name='Dropbox'; Pkg='Dropbox.Dropbox' }
    [PSCustomObject]@{ Id=188; Cat='Utilities'; Name='Ente Auth'; Pkg='ente-io.auth' }
    [PSCustomObject]@{ Id=189; Cat='Utilities'; Name='Everything'; Pkg='voidtools.Everything' }
    [PSCustomObject]@{ Id=190; Cat='Utilities'; Name='Files'; Pkg='FilesCommunity.Files' }
    [PSCustomObject]@{ Id=191; Cat='Utilities'; Name='F.lux'; Pkg='flux.flux' }
    [PSCustomObject]@{ Id=192; Cat='Utilities'; Name='GlazeWM'; Pkg='glzr-io.glazewm' }
    [PSCustomObject]@{ Id=193; Cat='Utilities'; Name='Google Drive'; Pkg='Google.Drive' }
    [PSCustomObject]@{ Id=194; Cat='Utilities'; Name='Hugo'; Pkg='Gohugoio.Hugo' }
    [PSCustomObject]@{ Id=195; Cat='Utilities'; Name='Internet Download Manager'; Pkg='Tonec.InternetDownloadManager' }
    [PSCustomObject]@{ Id=196; Cat='Utilities'; Name='JPEG View'; Pkg='oschwartz10612.jpegview' }
    [PSCustomObject]@{ Id=197; Cat='Utilities'; Name='KeePassXC'; Pkg='KeePassXCTeam.KeePassXC' }
    [PSCustomObject]@{ Id=198; Cat='Utilities'; Name='MiniTool Partition Wizard'; Pkg='MiniTool.PartitionWizard.Free' }
    [PSCustomObject]@{ Id=199; Cat='Utilities'; Name='MSEdgeRedirect'; Pkg='rcmaehl.MSEdgeRedirect' }
    [PSCustomObject]@{ Id=200; Cat='Utilities'; Name='MSI Afterburner'; Pkg='Guru3D.Afterburner' }
    [PSCustomObject]@{ Id=201; Cat='Utilities'; Name='NanaZip'; Pkg='M2Team.NanaZip' }
    [PSCustomObject]@{ Id=202; Cat='Utilities'; Name='Nilesoft Shell'; Pkg='Nilesoft.Shell' }
    [PSCustomObject]@{ Id=203; Cat='Utilities'; Name='NVCleanstall'; Pkg='TechPowerUp.NVCleanstall' }
    [PSCustomObject]@{ Id=204; Cat='Utilities'; Name='O&amp;O ShutUp10++'; Pkg='OO-Software.ShutUp10' }
    [PSCustomObject]@{ Id=205; Cat='Utilities'; Name='OPAutoClicker'; Pkg='OPAutoClicker.OPAutoClicker' }
    [PSCustomObject]@{ Id=206; Cat='Utilities'; Name='OpenRGB'; Pkg='OpenRGB.OpenRGB' }
    [PSCustomObject]@{ Id=207; Cat='Utilities'; Name='Oracle VirtualBox'; Pkg='Oracle.VirtualBox' }
    [PSCustomObject]@{ Id=208; Cat='Utilities'; Name='Parsec'; Pkg='Parsec.Parsec' }
    [PSCustomObject]@{ Id=209; Cat='Utilities'; Name='PeaZip'; Pkg='GiorgioTani.PeaZip' }
    [PSCustomObject]@{ Id=210; Cat='Utilities'; Name='Policy Plus'; Pkg='Fleex255.PolicyPlus' }
    [PSCustomObject]@{ Id=211; Cat='Utilities'; Name='Process Lasso'; Pkg='Bitsum.ProcessLasso' }
    [PSCustomObject]@{ Id=212; Cat='Utilities'; Name='Proton Authenticator'; Pkg='Proton.ProtonAuthenticator' }
    [PSCustomObject]@{ Id=213; Cat='Utilities'; Name='Proton Drive'; Pkg='Proton.ProtonDrive' }
    [PSCustomObject]@{ Id=214; Cat='Utilities'; Name='Proton Pass'; Pkg='Proton.ProtonPass' }
    [PSCustomObject]@{ Id=215; Cat='Utilities'; Name='qBittorrent'; Pkg='qBittorrent.qBittorrent' }
    [PSCustomObject]@{ Id=216; Cat='Utilities'; Name='Revo Uninstaller'; Pkg='RevoUninstaller.RevoUninstaller' }
    [PSCustomObject]@{ Id=217; Cat='Utilities'; Name='Rufus'; Pkg='Rufus.Rufus' }
    [PSCustomObject]@{ Id=218; Cat='Utilities'; Name='Snappy Driver Installer'; Pkg='GlennDelahoy.SnappyDriverInstallerOrigin' }
    [PSCustomObject]@{ Id=219; Cat='Utilities'; Name='SignalRGB'; Pkg='WhirlwindFX.SignalRGB' }
    [PSCustomObject]@{ Id=220; Cat='Utilities'; Name='StartAllBack'; Pkg='StartAllBack.StartAllBack' }
    [PSCustomObject]@{ Id=221; Cat='Utilities'; Name='Tailscale'; Pkg='tailscale.tailscale' }
    [PSCustomObject]@{ Id=222; Cat='Utilities'; Name='TeamViewer'; Pkg='TeamViewer.TeamViewer' }
    [PSCustomObject]@{ Id=223; Cat='Utilities'; Name='TightVNC'; Pkg='GlavSoft.TightVNC' }
    [PSCustomObject]@{ Id=224; Cat='Utilities'; Name='Total Commander'; Pkg='Ghisler.TotalCommander' }
    [PSCustomObject]@{ Id=225; Cat='Utilities'; Name='TreeSize Free'; Pkg='JAMSoftware.TreeSize.Free' }
    [PSCustomObject]@{ Id=226; Cat='Utilities'; Name='TranslucentTB'; Pkg='TranslucentTB.TranslucentTB' }
    [PSCustomObject]@{ Id=227; Cat='Utilities'; Name='UniGetUI'; Pkg='MartiCliment.UniGetUI' }
    [PSCustomObject]@{ Id=228; Cat='Utilities'; Name='WinRAR'; Pkg='RARLab.WinRAR' }
    [PSCustomObject]@{ Id=229; Cat='Utilities'; Name='Wise Program Uninstaller'; Pkg='WiseCleaner.WiseProgramUninstaller' }
    [PSCustomObject]@{ Id=230; Cat='Utilities'; Name='WizTree'; Pkg='AntibodySoftware.WizTree' }
    [PSCustomObject]@{ Id=231; Cat='Utilities'; Name='HxD Hex Editor'; Pkg='MaëlHörz.HxD' }
)

# ==========================================
# DATA GLOBAL: DEBLOATER
# ==========================================
$Global:DebloatList = @(
    [PSCustomObject]@{ Id=1; Cat='Microsoft Apps'; Name='Feedback Hub'; Pkg='Microsoft.WindowsFeedbackHub' }
    [PSCustomObject]@{ Id=2; Cat='Microsoft Apps'; Name='Get Help'; Pkg='Microsoft.GetHelp' }
    [PSCustomObject]@{ Id=3; Cat='Microsoft Apps'; Name='Microsoft 365'; Pkg='Microsoft.MicrosoftOfficeHub' }
    [PSCustomObject]@{ Id=4; Cat='Microsoft Apps'; Name='Microsoft Teams'; Pkg='Microsoft.Teams' }
    [PSCustomObject]@{ Id=5; Cat='Microsoft Apps'; Name='Outlook for Windows'; Pkg='Microsoft.OutlookForWindows' }
    [PSCustomObject]@{ Id=6; Cat='Microsoft Apps'; Name='Cortana'; Pkg='Microsoft.549981C3F5F10' }
    [PSCustomObject]@{ Id=7; Cat='Microsoft Ecosystem'; Name='Mobile Devices'; Pkg='MicrosoftWindows.CrossDevice' }
    [PSCustomObject]@{ Id=8; Cat='Microsoft Ecosystem'; Name='Phone Link'; Pkg='Microsoft.YourPhone' }
    [PSCustomObject]@{ Id=9; Cat='Bing & Web Services'; Name='Bing Search'; Pkg='Microsoft.BingSearch' }
    [PSCustomObject]@{ Id=10; Cat='Bing & Web Services'; Name='Copilot'; Pkg='Microsoft.Copilot' }
    [PSCustomObject]@{ Id=11; Cat='Bing & Web Services'; Name='News'; Pkg='Microsoft.BingNews' }
    [PSCustomObject]@{ Id=12; Cat='Bing & Web Services'; Name='Start Experiences App'; Pkg='Microsoft.StartExperiencesApp' }
    [PSCustomObject]@{ Id=13; Cat='Bing & Web Services'; Name='Weather'; Pkg='Microsoft.BingWeather' }
    [PSCustomObject]@{ Id=14; Cat='Developer Tools'; Name='Dev Home'; Pkg='Microsoft.Windows.DevHome' }
    [PSCustomObject]@{ Id=15; Cat='Developer Tools'; Name='Power Automate'; Pkg='Microsoft.PowerAutomateDesktop' }
    [PSCustomObject]@{ Id=16; Cat='Xbox & Gaming'; Name='Solitaire Collection'; Pkg='Microsoft.MicrosoftSolitaireCollection' }
    [PSCustomObject]@{ Id=17; Cat='Xbox & Gaming'; Name='Xbox App'; Pkg='Microsoft.XboxApp' }
    [PSCustomObject]@{ Id=18; Cat='Xbox & Gaming'; Name='Xbox Game Bar'; Pkg='Microsoft.XboxGamingOverlay' }
    [PSCustomObject]@{ Id=19; Cat='Xbox & Gaming'; Name='Xbox Identity Provider'; Pkg='Microsoft.XboxIdentityProvider' }
    [PSCustomObject]@{ Id=20; Cat='Xbox & Gaming'; Name='Xbox Speech To Text Overlay'; Pkg='Microsoft.XboxSpeechToTextOverlay' }
    [PSCustomObject]@{ Id=21; Cat='Xbox & Gaming'; Name='Xbox TCUI'; Pkg='Microsoft.Xbox.TCUI' }
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

        $script:MaintJob = Start-Job -ScriptBlock $script -ArgumentList $chkTemp.IsChecked, $chkDNS.IsChecked, $chkCleanmgr.IsChecked, $chkDISM.IsChecked, $chkSFC.IsChecked

        $script:MaintTimer = New-Object System.Windows.Threading.DispatcherTimer
        $script:MaintTimer.Interval = [TimeSpan]::FromSeconds(1)
        
        $script:MaintTimer.Add_Tick({
            if ($null -ne $script:MaintJob) {
                $out = Receive-Job -Job $script:MaintJob -Keep
                if ($out) { 
                    $txtLog.Text = $out -join "`r`n"
                    $txtLog.ScrollToEnd() 
                }
                if ($script:MaintJob.State -ne 'Running') {
                    $script:MaintTimer.Stop()
                    $btnRun.IsEnabled = $true
                    Remove-Job -Job $script:MaintJob -Force
                    $script:MaintJob = $null
                }
            }
        })
        
        $script:MaintTimer.Start()
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
                'Activity' { Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "EnableActivityFeed" -Value 0 -Type DWord -ErrorAction SilentlyContinue; Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "PublishUserActivities" -Value 0 -Type DWord -ErrorAction SilentlyContinue; Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "UploadUserActivities" -Value 0 -Type DWord -ErrorAction SilentlyContinue }
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
# FUNGSI GUI: TABBED APPS
# ==========================================
function Show-AppsGUI {
    $categories = $Global:AppList.Cat | Sort-Object -Unique
    $xamlStr = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Install Applications" Height="700" Width="700"
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
# FUNGSI GUI: DEBLOATER
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
        
        <StackPanel Grid.Row="0" Orientation="Horizontal" HorizontalAlignment="Left" Margin="0,0,0,10">
            <Button Name="BtnSelectAll" Content="Select All" Width="100" Height="30" Background="#0078D7" Foreground="White" FontWeight="Bold" Margin="0,0,10,0"/>
            <Button Name="BtnClearSel" Content="Clear Selection" Width="100" Height="30" Background="#2D2D30" Foreground="White" FontWeight="Bold"/>
        </StackPanel>

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
        
        <Button Grid.Row="2" Name="BtnRemove" Content="UNINSTALL SELECTED" Width="250" Height="40" Background="#D83B01" Foreground="White" FontWeight="Bold" FontSize="14" Margin="0,15,0,0" HorizontalAlignment="Center"/>
    </Grid>
</Window>
"@
    $reader = (New-Object System.Xml.XmlNodeReader ([xml]$xamlStr))
    $window = [Windows.Markup.XamlReader]::Load($reader)
    $btnRemove = $window.FindName("BtnRemove")
    $btnSelectAll = $window.FindName("BtnSelectAll")
    $btnClearSel = $window.FindName("BtnClearSel")

    $btnSelectAll.Add_Click({ foreach ($item in $Global:DebloatList) { $chk = $window.FindName("Chk_$($item.Id)"); if ($chk) { $chk.IsChecked = $true } } })
    $btnClearSel.Add_Click({ foreach ($item in $Global:DebloatList) { $chk = $window.FindName("Chk_$($item.Id)"); if ($chk) { $chk.IsChecked = $false } } })

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
# FUNGSI GUI: DNS SWITCHER
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
# FUNGSI GUI: UPDATE MANAGER
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

# ==========================================
# FUNGSI GUI: CUSTOM DIALOG
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
    
    $resultBag = @{ Value = $null }

    foreach ($b in $buttons) {
        $btn = $window.FindName("Btn_$($b.Value)")
        $val = $b.Value
        $btn.Add_Click({ 
            $resultBag.Value = $val
            $window.Close() 
        }.GetNewClosure())
    }
    
    $window.ShowDialog() | Out-Null
    return $resultBag.Value
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
    Start-Process powershell -ArgumentList "-ExecutionPolicy", "Bypass", "-EncodedCommand", $b64
}

# ==========================================
# FUNGSI GUI: ONE-CLICK FIXES
# ==========================================
function Show-FixesGUI {
    $xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="One-Click Fixes" Height="400" Width="500"
        WindowStartupLocation="CenterScreen" Background="#1E1E1E" Foreground="White">
    <Grid Margin="20">
        <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/></Grid.RowDefinitions>
        <TextBlock Grid.Row="0" Text="Pilih Perbaikan Darurat (Troubleshooting):" FontSize="16" FontWeight="Bold" Margin="0,0,0,15" Foreground="LightCoral"/>
        <StackPanel Grid.Row="1">
            <Button Name="BtnFixNet" Content="Reset Network Stack (Winsock &amp; TCP/IP)" Height="45" Margin="0,5" Background="#2D2D30" Foreground="White" FontWeight="Bold" HorizontalAlignment="Stretch"/>
            <Button Name="BtnFixUpd" Content="Reset Windows Update Cache" Height="45" Margin="0,5" Background="#2D2D30" Foreground="White" FontWeight="Bold" HorizontalAlignment="Stretch"/>
            <Button Name="BtnFixSfc" Content="Repair System Files (SFC &amp; DISM) - *Lama*" Height="45" Margin="0,5" Background="#107C10" Foreground="White" FontWeight="Bold" HorizontalAlignment="Stretch"/>
            <Button Name="BtnCancel" Content="Batal" Height="35" Margin="0,20,0,0" Background="#D83B01" Foreground="White" HorizontalAlignment="Right" Width="100"/>
        </StackPanel>
    </Grid>
</Window>
"@
    $reader = (New-Object System.Xml.XmlNodeReader ([xml]$xaml))
    $window = [Windows.Markup.XamlReader]::Load($reader)
    $btnFixNet = $window.FindName("BtnFixNet")
    $btnFixUpd = $window.FindName("BtnFixUpd")
    $btnFixSfc = $window.FindName("BtnFixSfc")
    $btnCancel = $window.FindName("BtnCancel")

    $btnFixNet.Add_Click({
        $window.Close()
        Start-Process powershell -ArgumentList "-NoExit", "-Command", "Write-Host 'Resetting Network Stack...' -ForegroundColor Cyan; netsh winsock reset; netsh int ip reset; ipconfig /flushdns; Write-Host 'Selesai. Silakan restart PC.' -ForegroundColor Green; Read-Host 'Tekan Enter...'" -Verb RunAs
    })
    $btnFixUpd.Add_Click({
        $window.Close()
        Start-Process powershell -ArgumentList "-NoExit", "-Command", "Write-Host 'Resetting Windows Update Cache...' -ForegroundColor Cyan; Stop-Service -Name wuauserv, cryptSvc, bits, msiserver -Force -ErrorAction SilentlyContinue; Remove-Item -Path 'C:\Windows\SoftwareDistribution\*' -Recurse -Force -ErrorAction SilentlyContinue; Start-Service -Name wuauserv, cryptSvc, bits, msiserver -ErrorAction SilentlyContinue; Write-Host 'Selesai.' -ForegroundColor Green; Read-Host 'Tekan Enter...'" -Verb RunAs
    })
    $btnFixSfc.Add_Click({
        $window.Close()
        Start-Process powershell -ArgumentList "-NoExit", "-Command", "Write-Host 'Menjalankan SFC Scannow...' -ForegroundColor Cyan; Start-Process cmd -ArgumentList '/c sfc /scannow' -Wait -NoNewWindow; Write-Host 'Menjalankan DISM...' -ForegroundColor Cyan; Start-Process cmd -ArgumentList '/c DISM /Online /Cleanup-Image /RestoreHealth' -Wait -NoNewWindow; Write-Host 'Selesai.' -ForegroundColor Green; Read-Host 'Tekan Enter...'" -Verb RunAs
    })
    $btnCancel.Add_Click({ $window.Close() })
    $window.ShowDialog() | Out-Null
}

# ==========================================
# FUNGSI GUI: STARTUP MANAGER
# ==========================================
function Show-StartupGUI {
    $startupItems = @()
    
    # 1. Registry
    $regPaths = @("HKCU:\Software\Microsoft\Windows\CurrentVersion\Run", "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run")
    foreach ($path in $regPaths) {
        if (Test-Path $path) {
            $props = Get-ItemProperty -Path $path
            $props.PSObject.Properties | Where-Object { $_.Name -notmatch '^PS' } | ForEach-Object {
                $startupItems += [PSCustomObject]@{ Id = [guid]::NewGuid().ToString("N"); Name = $_.Name; Type = "Registry"; Value = $_.Value; Location = $path; State = "Enabled"; DisplayName = "[Registry] $($_.Name)" }
            }
        }
    }

    # 2. Folders
    $folders = @("$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup", "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Startup")
    foreach ($folder in $folders) {
        if (Test-Path $folder) {
            $files = Get-ChildItem -Path $folder -File -ErrorAction SilentlyContinue
            foreach ($file in $files) {
                $startupItems += [PSCustomObject]@{ Id = [guid]::NewGuid().ToString("N"); Name = $file.Name; Type = "Folder"; Value = $file.FullName; Location = $folder; State = "Enabled"; DisplayName = "[Folder] $($file.Name)" }
            }
        }
    }

    # 3. Task Scheduler (Logon/Boot, non-Microsoft, ALL STATES)
    $tasks = Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object { 
        $_.TaskPath -notmatch "^\\Microsoft\\" -and
        $_.Triggers -ne $null -and
        ($_.Triggers | Where-Object { $_.CimClass.CimClassName -match "Logon|Boot" })
    }
    foreach ($task in $tasks) {
        $stateStr = if ($task.State -eq 'Disabled') { ' (Disabled)' } else { '' }
        $startupItems += [PSCustomObject]@{ Id = [guid]::NewGuid().ToString("N"); Name = $task.TaskName; Type = "Task"; Value = $task.TaskPath; Location = "Task Scheduler"; State = $task.State; DisplayName = "[Task] $($task.TaskName)$stateStr" }
    }

    $xamlStr = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Startup Manager (Deep Scan)" Height="700" Width="750"
        WindowStartupLocation="CenterScreen" Background="#1E1E1E" Foreground="White">
    <Grid Margin="15">
        <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
        <TextBlock Grid.Row="0" Text="Centang item yang ingin di-Enable/Disable:" FontSize="14" Margin="0,0,0,10" Foreground="Gray"/>
        <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto">
            <StackPanel Margin="10">
"@
    foreach ($item in $startupItems) {
        $safeName = $item.DisplayName -replace '&', '&amp;'
        $xamlStr += "<CheckBox Name='Chk_$($item.Id)' Content='$safeName' Foreground='White' Margin='0,8,0,8'/>"
    }
    $xamlStr += @"
            </StackPanel>
        </ScrollViewer>
        <StackPanel Grid.Row="2" Orientation="Horizontal" HorizontalAlignment="Center" Margin="0,15,0,0">
            <Button Name="BtnDisable" Content="DISABLE SELECTED" Width="200" Height="40" Background="#D83B01" Foreground="White" FontWeight="Bold" FontSize="14" Margin="0,0,10,0"/>
            <Button Name="BtnEnable" Content="ENABLE SELECTED" Width="200" Height="40" Background="#107C10" Foreground="White" FontWeight="Bold" FontSize="14"/>
        </StackPanel>
    </Grid>
</Window>
"@
    $reader = (New-Object System.Xml.XmlNodeReader ([xml]$xamlStr))
    $window = [Windows.Markup.XamlReader]::Load($reader)
    $btnDisable = $window.FindName("BtnDisable")
    $btnEnable = $window.FindName("BtnEnable")

    $btnDisable.Add_Click({
        $btnDisable.Content = "DISABLING..."
        $btnDisable.IsEnabled = $false
        
        $disabledDir = "$env:USERPROFILE\Desktop\Toolkit_Disabled_Startup"
        if (-not (Test-Path $disabledDir)) { New-Item -Path $disabledDir -ItemType Directory -Force | Out-Null }

        foreach ($item in $startupItems) {
            $chk = $window.FindName("Chk_$($item.Id)")
            if ($chk.IsChecked -eq $true) {
                try {
                    if ($item.Type -eq "Registry") {
                        Remove-ItemProperty -Path $item.Location -Name $item.Name -ErrorAction Stop
                    } elseif ($item.Type -eq "Folder") {
                        Move-Item -Path $item.Value -Destination $disabledDir -Force -ErrorAction Stop
                    } elseif ($item.Type -eq "Task" -and $item.State -ne 'Disabled') {
                        Disable-ScheduledTask -TaskName $item.Name -TaskPath $item.Value -ErrorAction Stop | Out-Null
                    }
                } catch { }
            }
        }
        $btnDisable.Content = "SELESAI!"
        Start-Sleep -Seconds 1
        $window.Close()
    })

    $btnEnable.Add_Click({
        $btnEnable.Content = "ENABLING..."
        $btnEnable.IsEnabled = $false

        foreach ($item in $startupItems) {
            $chk = $window.FindName("Chk_$($item.Id)")
            if ($chk.IsChecked -eq $true) {
                try {
                    if ($item.Type -eq "Task" -and $item.State -eq 'Disabled') {
                        Enable-ScheduledTask -TaskName $item.Name -TaskPath $item.Value -ErrorAction Stop | Out-Null
                    }
                } catch { }
            }
        }
        $btnEnable.Content = "SELESAI!"
        Start-Sleep -Seconds 1
        $window.Close()
    })

    $window.ShowDialog() | Out-Null
}

# ==========================================
# FUNGSI GUI: AUTOMATION PRESETS
# ==========================================
function Show-PresetsGUI {
    $xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Automation Presets" Height="400" Width="500"
        WindowStartupLocation="CenterScreen" Background="#1E1E1E" Foreground="White">
    <Grid Margin="20">
        <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/></Grid.RowDefinitions>
        <TextBlock Grid.Row="0" Text="Pilih Preset Instalasi Otomatis:" FontSize="16" FontWeight="Bold" Margin="0,0,0,15" Foreground="LightGreen"/>
        <StackPanel Grid.Row="1">
            <Button Name="BtnStandard" Content="Standard Setup (Chrome, 7-Zip, VLC)" Height="45" Margin="0,5" Background="#2D2D30" Foreground="White" FontWeight="Bold" HorizontalAlignment="Stretch"/>
            <Button Name="BtnGamer" Content="Gamer Setup (Steam, Discord, OBS Studio)" Height="45" Margin="0,5" Background="#2D2D30" Foreground="White" FontWeight="Bold" HorizontalAlignment="Stretch"/>
            <Button Name="BtnDeveloper" Content="Developer Setup (VS Code, Git, Python, Docker)" Height="45" Margin="0,5" Background="#2D2D30" Foreground="White" FontWeight="Bold" HorizontalAlignment="Stretch"/>
            <Button Name="BtnCancel" Content="Batal" Height="35" Margin="0,20,0,0" Background="#D83B01" Foreground="White" HorizontalAlignment="Right" Width="100"/>
        </StackPanel>
    </Grid>
</Window>
"@
    $reader = (New-Object System.Xml.XmlNodeReader ([xml]$xaml))
    $window = [Windows.Markup.XamlReader]::Load($reader)
    $btnStandard = $window.FindName("BtnStandard")
    $btnGamer = $window.FindName("BtnGamer")
    $btnDeveloper = $window.FindName("BtnDeveloper")
    $btnCancel = $window.FindName("BtnCancel")

    $installApps = {
        param($apps)
        foreach ($app in $apps) {
            Start-Process powershell -ArgumentList "-NoExit", "-Command", "winget install --id $app --accept-source-agreements --accept-package-agreements"
        }
    }

    $btnStandard.Add_Click({ $window.Close(); & $installApps @("Google.Chrome", "7zip.7zip", "VideoLAN.VLC") })
    $btnGamer.Add_Click({ $window.Close(); & $installApps @("Valve.Steam", "Discord.Discord", "OBSProject.OBSStudio") })
    $btnDeveloper.Add_Click({ $window.Close(); & $installApps @("Microsoft.VisualStudioCode", "Git.Git", "Python.Python.3.12", "Docker.DockerDesktop") })
    $btnCancel.Add_Click({ $window.Close() })
    $window.ShowDialog() | Out-Null
}

# ==========================================
# FUNGSI GUI BARU: USER PROFILE BACKUP
# ==========================================
function Show-UserBackupGUI {
    $xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="User Profile Backup" Height="550" Width="600"
        WindowStartupLocation="CenterScreen" Background="#1E1E1E" Foreground="White">
    <Grid Margin="15">
        <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
        
        <StackPanel Grid.Row="0">
            <TextBlock Text="Tentukan Folder Tujuan Backup:" FontSize="14" FontWeight="Bold" Margin="0,0,0,5"/>
            <TextBox Name="TxtPath" Text="D:\Backup_PC" Background="#2D2D30" Foreground="White" Height="30" Margin="0,0,0,15"/>
        </StackPanel>

        <StackPanel Grid.Row="1" Margin="0,0,0,10">
            <TextBlock Text="Folder yang akan di-backup:" FontSize="12" Foreground="Gray" Margin="0,0,0,5"/>
            <TextBlock Text="Documents, Pictures, Desktop, Downloads, Music, Videos, AppData\Roaming, AppData\Local\Packages" FontSize="12" Foreground="LightGray" TextWrapping="Wrap"/>
        </StackPanel>

        <TextBox Grid.Row="2" Name="TxtLog" Background="#111111" Foreground="Lime" FontFamily="Consolas" Margin="0,10" IsReadOnly="True" VerticalScrollBarVisibility="Auto" Text="Siap melakukan backup..."/>
        
        <Button Grid.Row="3" Name="BtnStart" Content="MULAI BACKUP PROFIL" Width="250" Height="40" Background="#0078D7" Foreground="White" FontWeight="Bold" FontSize="14" HorizontalAlignment="Center"/>
    </Grid>
</Window>
"@
    $reader = (New-Object System.Xml.XmlNodeReader ([xml]$xaml))
    $window = [Windows.Markup.XamlReader]::Load($reader)
    $btnStart = $window.FindName("BtnStart")
    $txtLog = $window.FindName("TxtLog")
    $txtPath = $window.FindName("TxtPath")

    $btnStart.Add_Click({
        $btnStart.IsEnabled = $false
        $txtLog.Clear()
        $targetDrive = $txtPath.Text
        $dateStamp = Get-Date -Format "yyyy-MM-dd_HHmmss"
        $destinationFolder = Join-Path -Path $targetDrive -ChildPath "Backup_$dateStamp"
        
        $script = {
            param($dest, $profile)
            if (-not (Test-Path $dest)) { New-Item -Path $dest -ItemType Directory -Force | Out-Null }
            $logFile = Join-Path -Path $dest -ChildPath "Backup_Log.txt"
            $folders = @("Documents", "Pictures", "Desktop", "Downloads", "Music", "Videos", "AppData\Roaming", "AppData\Local\Packages")
            $exclude = @("Cache", "Temp", "CrashDumps", "GPUCache", "Microsoft\Windows\INetCache")

            foreach ($folder in $folders) {
                $src = Join-Path -Path $profile -ChildPath $folder
                $dst = Join-Path -Path $dest -ChildPath $folder
                if (Test-Path $src) {
                    Write-Output "[+] Backup: $folder ..."
                    robocopy $src $dst /MIR /R:1 /W:1 /XD $exclude /LOG+:$logFile /NP /NJH /NJS | Out-Null
                    Write-Output "    -> Selesai."
                } else {
                    Write-Output "[~] Skip: $folder (Tidak ditemukan)"
                }
            }
            Write-Output "`n[V] BACKUP SELESAI! Log: $logFile"
        }

        $script:BackupJob = Start-Job -ScriptBlock $script -ArgumentList $destinationFolder, $env:USERPROFILE

        $script:BackupTimer = New-Object System.Windows.Threading.DispatcherTimer
        $script:BackupTimer.Interval = [TimeSpan]::FromSeconds(1)
        
        $script:BackupTimer.Add_Tick({
            if ($null -ne $script:BackupJob) {
                $out = Receive-Job -Job $script:BackupJob -Keep
                if ($out) { 
                    $txtLog.Text = $out -join "`r`n"
                    $txtLog.ScrollToEnd() 
                }
                if ($script:BackupJob.State -ne 'Running') {
                    $script:BackupTimer.Stop()
                    $btnStart.IsEnabled = $true
                    Remove-Job -Job $script:BackupJob -Force
                    $script:BackupJob = $null
                }
            }
        })
        
        $script:BackupTimer.Start()
    })

    $window.ShowDialog() | Out-Null
}

# ==========================================
# FUNGSI GUI BARU: SYSTEM RESTORE POINT (CREATE & REVERT)
# ==========================================
function Show-RestorePointGUI {
    $xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="System Restore Point" Height="600" Width="700"
        WindowStartupLocation="CenterScreen" Background="#1E1E1E" Foreground="White">
    <Grid Margin="15">
        <TabControl Name="TabMain" Background="#1E1E1E" BorderBrush="#3F3F46">
            
            <!-- TAB CREATE -->
            <TabItem Header="Buat Restore Point" Background="#2D2D30" Foreground="White">
                <Grid Margin="20">
                    <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
                    <TextBlock Grid.Row="0" Text="Buat System Restore Point sebelum melakukan Tweaks." FontSize="14" Foreground="Gray" Margin="0,0,0,15"/>
                    <StackPanel Grid.Row="1">
                        <TextBlock Text="Fitur ini sangat disarankan agar Anda bisa mengembalikan PC ke kondisi ini jika terjadi masalah." TextWrapping="Wrap" Foreground="LightGray"/>
                    </StackPanel>
                    <Button Grid.Row="2" Name="BtnCreate" Content="BUAT RESTORE POINT SEKARANG" Width="250" Height="45" Background="#107C10" Foreground="White" FontWeight="Bold" FontSize="14" HorizontalAlignment="Center"/>
                </Grid>
            </TabItem>

            <!-- TAB RESTORE -->
            <TabItem Header="Kembalikan (Restore)" Background="#2D2D30" Foreground="White">
                <Grid Margin="20">
                    <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
                    <TextBlock Grid.Row="0" Text="Pilih Restore Point yang ingin dikembalikan:" FontSize="14" Foreground="Gray" Margin="0,0,0,10"/>
                    
                    <ListBox Grid.Row="1" Name="LstRestorePoints" Background="#111111" Foreground="White" BorderBrush="#3F3F46" Margin="0,0,0,15">
                        <ListBox.ItemTemplate>
                            <DataTemplate>
                                <StackPanel>
                                    <TextBlock Text="{Binding Description}" FontWeight="Bold" />
                                    <TextBlock Text="{Binding CreationTime}" FontSize="12" Foreground="Gray" />
                                </StackPanel>
                            </DataTemplate>
                        </ListBox.ItemTemplate>
                    </ListBox>

                    <StackPanel Grid.Row="2" Orientation="Horizontal" HorizontalAlignment="Center">
                        <Button Name="BtnRevert" Content="KEMBALIKAN SISTEM" Width="200" Height="45" Background="#D83B01" Foreground="White" FontWeight="Bold" FontSize="14" Margin="0,0,10,0"/>
                        <Button Name="BtnOpenNative" Content="Buka System Restore Windows" Width="200" Height="45" Background="#2D2D30" Foreground="White" FontWeight="Bold" FontSize="14"/>
                    </StackPanel>
                </Grid>
            </TabItem>

        </TabControl>
    </Grid>
</Window>
"@
    $reader = (New-Object System.Xml.XmlNodeReader ([xml]$xaml))
    $window = [Windows.Markup.XamlReader]::Load($reader)
    
    $btnCreate = $window.FindName("BtnCreate")
    $lstRestorePoints = $window.FindName("LstRestorePoints")
    $btnRevert = $window.FindName("BtnRevert")
    $btnOpenNative = $window.FindName("BtnOpenNative")

    # Refresh List Restore Points
    $refreshList = {
        $points = Get-ComputerRestorePoint -ErrorAction SilentlyContinue | Sort-Object CreationTime -Descending
        $lstRestorePoints.ItemsSource = $points
    }
    & $refreshList

    # Action: Create
    $btnCreate.Add_Click({
        $btnCreate.Content = "Membuat Restore Point..."
        $btnCreate.IsEnabled = $false
        
        try {
            if ((Get-ComputerRestorePoint).Count -eq $null) { 
                Enable-ComputerRestore -Drive "C:\" -ErrorAction Stop 
            }
            Checkpoint-Computer -Description "Toolkit Restore Point - $(Get-Date -Format 'yyyy-MM-dd HH:mm')" -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
            [System.Windows.MessageBox]::Show("Restore Point berhasil dibuat!", "Sukses", "OK", "Information") | Out-Null
            & $refreshList # Refresh daftar setelah dibuat
        } catch {
            [System.Windows.MessageBox]::Show("Gagal membuat Restore Point: `n$($_.Exception.Message)", "Error", "OK", "Error") | Out-Null
        }
        
        $btnCreate.Content = "BUAT RESTORE POINT SEKARANG"
        $btnCreate.IsEnabled = $true
    })

    # Action: Revert
    $btnRevert.Add_Click({
        if ($null -eq $lstRestorePoints.SelectedItem) {
            [System.Windows.MessageBox]::Show("Pilih Restore Point terlebih dahulu dari daftar!", "Peringatan", "OK", "Warning") | Out-Null
            return
        }

        $seqNum = $lstRestorePoints.SelectedItem.SequenceNumber
        $desc = $lstRestorePoints.SelectedItem.Description
        
        $confirm = [System.Windows.MessageBox]::Show("Anda akan mengembalikan sistem ke: `n'$desc'`n`nPC akan di-restart secara otomatis.`nLanjutkan?", "Konfirmasi Restore", "YesNo", "Warning")
        
        if ($confirm -eq 'Yes') {
            try {
                Restore-Computer -RestorePoint $seqNum -Confirm:$false -ErrorAction Stop
                [System.Windows.MessageBox]::Show("Perintah restore berhasil dijalankan. PC akan restart dalam beberapa detik.", "Restoring System", "OK", "Information") | Out-Null
            } catch {
                [System.Windows.MessageBox]::Show("Gagal me-restore: `n$($_.Exception.Message)", "Error", "OK", "Error") | Out-Null
            }
        }
    })

    # Action: Open Native UI
    $btnOpenNative.Add_Click({
        Start-Process "rstrui.exe"
        $window.Close()
    })

    $window.ShowDialog() | Out-Null
}

# ==========================================
# MENU UTAMA GUI (Tiles)
# ==========================================
function Show-GUI {
    [xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Panduan PowerShell - Control Panel v3.5.1" Height="850" Width="1000"
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
            <Button x:Name="BtnUserBackup" Width="200" Height="100" Margin="10" Background="#2D2D30" BorderBrush="#3F3F46" BorderThickness="2"><StackPanel><TextBlock Text="🗂️ User Backup" FontSize="18" FontWeight="Bold" Foreground="White" HorizontalAlignment="Center"/><TextBlock Text="Backup Data Profil" FontSize="12" Foreground="Gray" HorizontalAlignment="Center" Margin="0,5,0,0"/></StackPanel></Button>
            <Button x:Name="BtnRestore" Width="200" Height="100" Margin="10" Background="#2D2D30" BorderBrush="#3F3F46" BorderThickness="2"><StackPanel><TextBlock Text="🛡️ Restore Point" FontSize="18" FontWeight="Bold" Foreground="White" HorizontalAlignment="Center"/><TextBlock Text="Buat &amp; Kembalikan" FontSize="12" Foreground="Gray" HorizontalAlignment="Center" Margin="0,5,0,0"/></StackPanel></Button>
            <Button x:Name="BtnUpdate" Width="200" Height="100" Margin="10" Background="#2D2D30" BorderBrush="#3F3F46" BorderThickness="2"><StackPanel><TextBlock Text="🔄 Update Mgr" FontSize="18" FontWeight="Bold" Foreground="White" HorizontalAlignment="Center"/><TextBlock Text="Kontrol Windows Update" FontSize="12" Foreground="Gray" HorizontalAlignment="Center" Margin="0,5,0,0"/></StackPanel></Button>
            <Button x:Name="BtnDNS" Width="200" Height="100" Margin="10" Background="#2D2D30" BorderBrush="#3F3F46" BorderThickness="2"><StackPanel><TextBlock Text="🌍 DNS Switcher" FontSize="18" FontWeight="Bold" Foreground="White" HorizontalAlignment="Center"/><TextBlock Text="Percepat Internet" FontSize="12" Foreground="Gray" HorizontalAlignment="Center" Margin="0,5,0,0"/></StackPanel></Button>
            <Button x:Name="BtnFixes" Width="200" Height="100" Margin="10" Background="#2D2D30" BorderBrush="#3F3F46" BorderThickness="2"><StackPanel><TextBlock Text="🚑 One-Click Fixes" FontSize="18" FontWeight="Bold" Foreground="White" HorizontalAlignment="Center"/><TextBlock Text="Perbaikan Darurat" FontSize="12" Foreground="Gray" HorizontalAlignment="Center" Margin="0,5,0,0"/></StackPanel></Button>
            <Button x:Name="BtnStartup" Width="200" Height="100" Margin="10" Background="#2D2D30" BorderBrush="#3F3F46" BorderThickness="2"><StackPanel><TextBlock Text="🚀 Startup Manager" FontSize="18" FontWeight="Bold" Foreground="White" HorizontalAlignment="Center"/><TextBlock Text="Kelola Autostart" FontSize="12" Foreground="Gray" HorizontalAlignment="Center" Margin="0,5,0,0"/></StackPanel></Button>
            <Button x:Name="BtnPresets" Width="200" Height="100" Margin="10" Background="#2D2D30" BorderBrush="#3F3F46" BorderThickness="2"><StackPanel><TextBlock Text="⚡ Automation Presets" FontSize="18" FontWeight="Bold" Foreground="White" HorizontalAlignment="Center"/><TextBlock Text="Setup Instalasi Cepat" FontSize="12" Foreground="Gray" HorizontalAlignment="Center" Margin="0,5,0,0"/></StackPanel></Button>
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
    $btnUserBackup = $window.FindName("BtnUserBackup")
    $btnRestore = $window.FindName("BtnRestore")
    $btnUpdate = $window.FindName("BtnUpdate")
    $btnDNS = $window.FindName("BtnDNS")
    $btnFixes = $window.FindName("BtnFixes")
    $btnStartup = $window.FindName("BtnStartup")
    $btnPresets = $window.FindName("BtnPresets")

    $btnMaintenance.Add_Click({ Show-MaintenanceGUI })
    $btnTweaks.Add_Click({ Show-TweaksGUI })
    $btnInstall.Add_Click({ Show-AppsGUI })
    $btnDebloater.Add_Click({ Show-DebloaterGUI })
    $btnBackup.Add_Click({ Show-BackupGUI })
    $btnUserBackup.Add_Click({ Show-UserBackupGUI })
    $btnRestore.Add_Click({ Show-RestorePointGUI })
    $btnUpdate.Add_Click({ Show-UpdateGUI })
    $btnDNS.Add_Click({ Show-DnsGUI })
    $btnFixes.Add_Click({ Show-FixesGUI })
    $btnStartup.Add_Click({ Show-StartupGUI })
    $btnPresets.Add_Click({ Show-PresetsGUI })
    
    $btnAudit.Add_Click({ Show-SimpleCLI "System Audit" "Invoke-SystemAudit" })
    $btnNetwork.Add_Click({ Show-SimpleCLI "Network Diagnostics" "Invoke-NetworkDiagnostics" })
    $btnEventLog.Add_Click({ Show-SimpleCLI "Event Log Analyzer" "Invoke-EventLogAnalyzer" })

    $window.ShowDialog() | Out-Null
}

Show-GUI