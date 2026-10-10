[CmdletBinding()]
param(
    [string]$TraceHost = '1.1.1.1'
)

<##
.SYNOPSIS
    Diagnosis dasar koneksi jaringan Windows.
.DESCRIPTION
    Menampilkan IP configuration, TCP connections, route trace,
    dan pemetaan koneksi established ke process ID.
#>

$ErrorActionPreference = 'SilentlyContinue'

Write-Host '=== NETWORK DIAGNOSTICS ===' -ForegroundColor Cyan
Write-Host ''

Write-Host '[IP CONFIGURATION]' -ForegroundColor Yellow
Get-NetIPConfiguration |
    Select-Object InterfaceAlias, IPv4Address, IPv4DefaultGateway, DNSServer |
    Format-List

Write-Host '[ACTIVE TCP CONNECTIONS]' -ForegroundColor Yellow
Get-NetTCPConnection |
    Select-Object LocalAddress, LocalPort, RemoteAddress, RemotePort, State, OwningProcess |
    Sort-Object State, LocalPort |
    Format-Table -AutoSize

Write-Host '[ESTABLISHED CONNECTION -> PROCESS]' -ForegroundColor Yellow
Get-NetTCPConnection -State Established | ForEach-Object {
    $Process = Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue

    [PSCustomObject]@{
        LocalPort  = $_.LocalPort
        RemoteAddr = $_.RemoteAddress
        RemotePort = $_.RemotePort
        Process    = if ($Process) { $Process.ProcessName } else { '<unknown>' }
        PID        = $_.OwningProcess
    }
} | Format-Table -AutoSize

Write-Host "[TRACE ROUTE: $TraceHost]" -ForegroundColor Yellow
Test-NetConnection -ComputerName $TraceHost -TraceRoute |
    Format-List

Write-Host ''
Write-Host 'Network diagnostics selesai. Script ini tidak mengubah konfigurasi jaringan.' -ForegroundColor Green
