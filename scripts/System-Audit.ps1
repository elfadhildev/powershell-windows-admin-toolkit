<#
 SYSTEM AUDIT SCRIPT
#>
$ErrorActionPreference = 'SilentlyContinue'
Clear-Host
Write-Host "===================================================" -ForegroundColor Cyan
Write-Host "             SISTEM AUDIT & HARDWARE               " -ForegroundColor Cyan
Write-Host "===================================================" -ForegroundColor Cyan

Write-Host "`n[+] INFORMASI SISTEM" -ForegroundColor Yellow
$os = Get-CimInstance Win32_OperatingSystem
$cpu = Get-CimInstance Win32_Processor
$ram = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)
Write-Host " OS     : $($os.Caption) ($($os.Version))"
Write-Host " CPU    : $($cpu.Name)"
Write-Host " RAM    : $ram GB"

Write-Host "`n[+] STATUS AKTIVASI WINDOWS" -ForegroundColor Yellow
$lic = Get-CimInstance SoftwareLicensingProduct | Where-Object { $_.PartialProductKey }
if ($lic.LicenseStatus -eq 1) { Write-Host " -> Windows Teraktivasi (Licensed)" -ForegroundColor Green } 
else { Write-Host " -> Windows Belum Teraktivasi" -ForegroundColor Red }

Write-Host "`n[+] KESEHATAN DISK & STORAGE" -ForegroundColor Yellow
Get-PhysicalDisk | Select-Object DeviceId, FriendlyName, MediaType, HealthStatus, @{N='Size(GB)';E={[math]::Round($_.Size/1GB,2)}} | Format-Table -AutoSize

Write-Host "`n[+] DRIVER BERMASALAH" -ForegroundColor Yellow
$badDrivers = Get-PnpDevice -PresentOnly | Where-Object { $_.Status -ne "OK" }
if ($badDrivers) { $badDrivers | Select-Object Class, FriendlyName, Status | Format-Table -AutoSize } 
else { Write-Host " -> Semua driver berstatus OK." -ForegroundColor Green }

Write-Host "===================================================" -ForegroundColor Cyan
