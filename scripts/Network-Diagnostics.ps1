<#
 NETWORK DIAGNOSTICS SCRIPT
#>
$ErrorActionPreference = 'SilentlyContinue'
Clear-Host
Write-Host "===================================================" -ForegroundColor Cyan
Write-Host "               DIAGNOSTIK JARINGAN                 " -ForegroundColor Cyan
Write-Host "===================================================" -ForegroundColor Cyan

Write-Host "`n[+] IP CONFIGURATION" -ForegroundColor Yellow
Get-NetIPConfiguration | Where-Object { $_.IPv4Address } |
    Select-Object InterfaceAlias, IPv4Address, IPv4DefaultGateway, DNSServer | Format-List

Write-Host "`n[+] ACTIVE TCP CONNECTIONS" -ForegroundColor Yellow
Get-NetTCPConnection | Select-Object LocalAddress, LocalPort, RemoteAddress, RemotePort, State, OwningProcess | Sort-Object State, LocalPort | Format-Table -AutoSize

Write-Host "`n[+] ESTABLISHED CONNECTION -> PROCESS" -ForegroundColor Yellow
Get-NetTCPConnection -State Established | ForEach-Object {
    $Process = Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue
    [PSCustomObject]@{
        LocalPort  = $_.LocalPort
        RemoteAddr = $_.RemoteAddress
        RemotePort = $_.RemotePort
        Process    = if ($Process) { $Process.ProcessName } else { '<unknown>' }
        PID        = $_.OwningProcess
    }
} | Sort-Object Process | Format-Table -AutoSize

Write-Host "`n[+] TES RESOLUSI DNS (google.com)" -ForegroundColor Yellow
$dns = Resolve-DnsName -Name "google.com" -Type A -ErrorAction SilentlyContinue | Select-Object -First 1
if ($dns) { Write-Host " -> Berhasil: google.com -> $($dns.IPAddress)" -ForegroundColor Green } 
else { Write-Host " -> Gagal melakukan resolusi DNS!" -ForegroundColor Red }

Write-Host "===================================================" -ForegroundColor Cyan
# PERBAIKAN: Gunakan Read-Host
Read-Host " Diagnostik selesai. Tekan Enter untuk menutup jendela ini..."