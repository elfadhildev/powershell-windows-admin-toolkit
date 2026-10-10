[CmdletBinding()]
param(
    [switch]$Detailed
)

<##
.SYNOPSIS
    Menampilkan ringkasan audit Windows untuk kebutuhan troubleshooting.
.DESCRIPTION
    Script read-only. Tidak mengubah konfigurasi sistem.
#>

$ErrorActionPreference = 'SilentlyContinue'

Write-Host '=== SYSTEM AUDIT ===' -ForegroundColor Cyan
Write-Host ''

Write-Host '[OS]' -ForegroundColor Yellow
Get-CimInstance -ClassName Win32_OperatingSystem |
    Select-Object Caption, Version, BuildNumber, OSArchitecture |
    Format-List

Write-Host '[COMPUTER]' -ForegroundColor Yellow
Get-CimInstance -ClassName Win32_ComputerSystem |
    Select-Object Manufacturer, Model, TotalPhysicalMemory |
    Format-List

Write-Host '[CPU]' -ForegroundColor Yellow
Get-CimInstance -ClassName Win32_Processor |
    Select-Object Name, NumberOfCores, NumberOfLogicalProcessors, MaxClockSpeed |
    Format-List

Write-Host '[DISK]' -ForegroundColor Yellow
Get-PhysicalDisk |
    Select-Object DeviceId, FriendlyName, OperationalStatus, HealthStatus, MediaType, Size |
    Format-Table -AutoSize

Write-Host '[DEVICES WITH NON-OK STATUS]' -ForegroundColor Yellow
Get-PnpDevice -PresentOnly |
    Where-Object Status -ne 'OK' |
    Select-Object Status, Class, FriendlyName, InstanceId |
    Format-Table -AutoSize

Write-Host '[RUNNING SERVICES]' -ForegroundColor Yellow
Get-Service |
    Where-Object Status -eq 'Running' |
    Select-Object Status, Name, DisplayName |
    Sort-Object Name |
    Format-Table -AutoSize

Write-Host '[WINDOWS LICENSE STATUS]' -ForegroundColor Yellow
Get-CimInstance -ClassName SoftwareLicensingProduct |
    Where-Object PartialProductKey |
    Select-Object Name, ApplicationId, LicenseStatus |
    Format-Table -AutoSize

Write-Host '[NOTEPAD SIGNATURE]' -ForegroundColor Yellow
Get-AuthenticodeSignature -FilePath "$env:WINDIR\System32\notepad.exe" |
    Select-Object Status, StatusMessage, Path, SignerCertificate |
    Format-List

if ($Detailed) {
    Write-Host '[STARTUP ITEMS]' -ForegroundColor Yellow
    Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' |
        Format-List
}

Write-Host ''
Write-Host 'Audit selesai. Script ini bersifat read-only.' -ForegroundColor Green
