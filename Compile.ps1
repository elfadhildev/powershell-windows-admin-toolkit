# Compile.ps1
$root = $PSScriptRoot
$output = Join-Path $root "toolkit.ps1"

# 1. Header: cek admin & elevation 
$header = @'
#Requires -RunAsAdministrator
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -Command `"irm https://raw.githubusercontent.com/elfadhildev/powershell-windows-admin-toolkit/main/toolkit.ps1 | iex`"" -Verb RunAs
    exit
}
'@

# 2. Bungkus setiap file di scripts/ menjadi fungsi
$functions = @()
$scriptMap = @{
    "Maintenance.ps1"         = "Invoke-Maintenance"
    "System-Audit.ps1"        = "Invoke-SystemAudit"
    "Network-Diagnostics.ps1" = "Invoke-NetworkDiagnostics"
    "Backup-UserProfile.ps1"  = "Invoke-BackupUserProfile"
}

foreach ($file in $scriptMap.Keys) {
    $path = Join-Path $root "scripts\$file"
    if (Test-Path $path) {
        $body = Get-Content $path -Raw
        $funcName = $scriptMap[$file]
        $functions += "`nfunction $funcName {`n$body`n}"
    }
}

# 3. Menu utama (mengadaptasi install.ps1 lama)
$menu = @'

function Show-Menu {
    Clear-Host
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host " PANDUAN POWERSHELL - CONTROL PANEL (Single File) " -ForegroundColor Cyan
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host " 1. Maintenance PC" -ForegroundColor Green
    Write-Host " 2. System Audit" -ForegroundColor Magenta
    Write-Host " 3. Network Diagnostics" -ForegroundColor Magenta
    Write-Host " 4. Backup Profil User" -ForegroundColor Green
    Write-Host " 5. Keluar" -ForegroundColor Red
    Write-Host "===================================================" -ForegroundColor Cyan
}

do {
    Show-Menu
    $choice = Read-Host "Pilih opsi (1-5)"
    switch ($choice) {
        '1' { Invoke-Maintenance }
        '2' { Invoke-SystemAudit }
        '3' { Invoke-NetworkDiagnostics }
        '4' { Invoke-BackupUserProfile }
        '5' { Write-Host "Keluar..." -ForegroundColor Cyan }
        default { Write-Host "[!] Pilihan tidak valid." -ForegroundColor Red; Start-Sleep -Seconds 1 }
    }
    if ($choice -ne '5') { Read-Host "`nTekan Enter untuk kembali ke menu..." }
} while ($choice -ne '5')
'@

# 4. Gabungkan semuanya
$final = $header + "`n" + ($functions -join "`n") + $menu
$final | Out-File -FilePath $output -Encoding UTF8

Write-Host "[+] Berhasil membuat $output" -ForegroundColor Green
Write-Host "    Commit dan push file toolkit.ps1 ke GitHub." -ForegroundColor Yellow
