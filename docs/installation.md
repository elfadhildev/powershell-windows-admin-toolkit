# Installation

## Requirements

Windows 10/11 direkomendasikan. PowerShell 7 disarankan untuk development, tetapi sebagian command menggunakan Windows PowerShell dan cmdlet Windows yang tersedia pada sistem.

Periksa PowerShell:

```powershell
$PSVersionTable.PSVersion
```

Periksa Winget:

```powershell
winget --version
```


## Execution Policy

Jangan mengubah Execution Policy global hanya agar satu script dapat dijalankan. Untuk penggunaan lokal, ikuti kebijakan perangkat Anda dan gunakan scope yang paling sempit sesuai kebutuhan.

Contoh pemeriksaan:

```powershell
Get-ExecutionPolicy -List
```

## Pester

Untuk menjalankan test:

```powershell
Install-Module Pester -Scope CurrentUser -Force
Invoke-Pester .\tests\Scripts.Tests.ps1
```
