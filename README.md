# PowerShell Windows Administration Toolkit

![PowerShell](https://img.shields.io/badge/PowerShell-7%2B-5391FE?logo=powershell&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-Windows%2010%2F11-0078D4?logo=windows&logoColor=white)
![Version](https://img.shields.io/badge/Version-1.3.1-2ea44f)
![License](https://img.shields.io/badge/License-MIT-green)

Toolkit PowerShell untuk administrasi Windows, system audit, diagnosis jaringan, maintenance dasar, backup user profile, dan automation melalui Task Scheduler.

Repository ini disusun sebagai portfolio teknis. Fokusnya bukan sekadar mengumpulkan command, tetapi menunjukkan bagaimana command Windows dapat dikemas menjadi workflow yang terdokumentasi, dapat diulang, dan mudah dipelihara.

> Status: `v1.3.1` · Portfolio / Learning Project

## Tujuan

Project ini mendemonstrasikan kemampuan pada:

- PowerShell scripting dan object pipeline.
- Windows system administration.
- Package management dengan `winget`.
- System dan hardware audit menggunakan CIM/WMI.
- Network diagnostics menggunakan cmdlet Windows.
- Maintenance storage dan temporary files.
- Backup user profile menggunakan Robocopy.
- Automation dengan Task Scheduler.
- Dokumentasi dan struktur repository untuk workflow GitHub.

## Fitur

| Area | Implementasi |
|---|---|
| Package Management | Winget install, upgrade, export, import |
| System Audit | OS, service, disk, device, signature |
| Network Diagnostics | TCP connection, route, process mapping |
| Maintenance | DNS, DHCP renew, temp cleanup, storage optimization |
| Backup | User profile + AppData tertentu dengan Robocopy |
| Automation | Task Scheduler |
| Developer Tooling | PowerShell 7, Git, Windows Terminal, Fastfetch |

## Struktur Repository

```text
powershell-windows-admin-toolkit/
├── .github/
│   └── workflows/
│       └── powershell-lint.yml
├── config/
│   └── backup.example.json
├── docs/
│   ├── installation.md
│   ├── usage.md
│   ├── troubleshooting.md
│   └── source-notes.md
├── scripts/
│   ├── Backup-UserProfile.ps1
│   ├── Maintenance.ps1
│   ├── Network-Diagnostics.ps1
│   └── System-Audit.ps1
├── tests/
│   └── Scripts.Tests.ps1
├── .gitignore
├── CHANGELOG.md
├── CONTRIBUTING.md
├── LICENSE
└── README.md
```

## Prerequisites

- Windows 10 atau Windows 11.
- PowerShell 5.1 tersedia secara default pada Windows. PowerShell 7 direkomendasikan untuk development.
- Hak Administrator untuk operasi seperti DNS cache, DHCP renew, cleanup sistem, dan storage optimization.
- `winget` untuk bagian package management.
- Drive atau folder tujuan yang cukup untuk backup.

Periksa versi PowerShell:

```powershell
$PSVersionTable.PSVersion
```

Periksa Winget:

```powershell
winget --version
```

## Instalasi

Clone repository:

```powershell
irm https://raw.githubusercontent.com/elfadhildev/powershell-windows-admin-toolkit/main/install.ps1 | iex
```

Untuk development, gunakan PowerShell 7 bila tersedia:

```powershell
pwsh
```

## Quick Start

Audit sistem:

```powershell
.\scripts\System-Audit.ps1
```

Diagnosis jaringan:

```powershell
.\scripts\Network-Diagnostics.ps1
```

Maintenance:

```powershell
.\scripts\Maintenance.ps1
```

Backup user profile:

```powershell
.\scripts\Backup-UserProfile.ps1 -BackupTargetDrive "D:\Backup_PC"
```

> Jalankan PowerShell sebagai Administrator untuk script yang membutuhkan hak elevated.

## 1. Package Management dengan Winget

Contoh package yang digunakan dalam materi sumber:

```powershell
winget install LibreOffice.LibreOffice
winget install GIMP.GIMP
winget install SubhraDas.XtremeDownloadManager
winget install ONLYOFFICE.DesktopEditors
winget install KDE.Krita
winget install Inkscape.Inkscape
winget install agney.Motrix
winget install PDF24.PDF24Creator
```

Update aplikasi:

```powershell
winget upgrade --all --include-unknown
```

Export daftar aplikasi:

```powershell
winget export -o "$env:USERPROFILE\Desktop\AppsList.json"
```

Import daftar aplikasi:

```powershell
winget import -i "$env:USERPROFILE\Desktop\AppsList.json"
```

Untuk memastikan Package ID masih sesuai, gunakan `winget search <nama>` sebelum automation deployment.

## 2. System Audit

Script `System-Audit.ps1` mengelompokkan pemeriksaan sistem menjadi beberapa bagian:

```powershell
.\scripts\System-Audit.ps1
```

Contoh command yang menjadi dasar script:

```powershell
Get-CimInstance -ClassName Win32_OperatingSystem |
    Select-Object Caption, Version, BuildNumber, OSArchitecture

Get-PhysicalDisk |
    Select-Object DeviceId, FriendlyName, OperationalStatus, HealthStatus, MediaType, Size

Get-PnpDevice -PresentOnly |
    Where-Object Status -ne 'OK'

Get-Service |
    Where-Object Status -eq 'Running'
```

Pemeriksaan signature executable:

```powershell
Get-AuthenticodeSignature -FilePath "C:\Windows\System32\notepad.exe"
```

## 3. Network Diagnostics

Script `Network-Diagnostics.ps1` membantu melihat koneksi aktif, route, dan hubungan antara TCP connection dengan process ID.

```powershell
.\scripts\Network-Diagnostics.ps1
```

Command dasar:

```powershell
Get-NetTCPConnection |
    Select-Object LocalAddress, LocalPort, RemoteAddress, RemotePort, State, OwningProcess

Test-NetConnection -ComputerName 1.1.1.1 -TraceRoute
```

Tool tambahan yang tercantum dalam materi sumber:

```powershell
winget install Insecure.Nmap
winget install WiresharkFoundation.Wireshark
```

Gunakan network scanning hanya pada sistem atau jaringan yang Anda miliki atau yang memang memberi Anda izin pengujian.

## 4. Maintenance Script

`Maintenance.ps1` mempertahankan workflow utama dari script sumber:

1. Validasi Administrator.
2. Membersihkan DNS cache.
3. Release dan renew DHCP.
4. Membersihkan temporary files.
5. Menjalankan `cleanmgr.exe`.
6. Mendeteksi media drive C:.
7. Menjalankan ReTrim pada SSD atau Defrag pada HDD.

Jalankan:

```powershell
.\scripts\Maintenance.ps1
```

Drive dapat diubah melalui parameter:

```powershell
.\scripts\Maintenance.ps1 -DriveLetter C
```

> Maintenance ini ditujukan untuk maintenance dasar dan troubleshooting. Jangan menganggap setiap tweak sistem sebagai jaminan peningkatan performa.

## 5. Backup User Profile

`Backup-UserProfile.ps1` menggunakan Robocopy untuk menyalin beberapa folder profil user dan membuat log backup.

Jalankan dengan default:

```powershell
.\scripts\Backup-UserProfile.ps1
```

Atau tentukan lokasi tujuan:

```powershell
.\scripts\Backup-UserProfile.ps1 -BackupTargetDrive "D:\Backup_PC"
```

Folder yang dicadangkan:

- Documents
- Pictures
- Desktop
- Downloads
- Music
- Videos
- `AppData\Roaming`
- `AppData\Local\Packages`

Folder cache/temp tertentu dikecualikan sesuai daftar yang ada di script.

### Catatan tentang `/MIR`

Script mempertahankan parameter `/MIR` dari source material. `/MIR` membuat destination menjadi mirror dari source, sehingga penghapusan di source dapat berpengaruh pada destination mirror. Untuk backup arsip jangka panjang, pendekatan non-mirror perlu dipertimbangkan.

## 6. Task Scheduler

Backup dapat dijalankan otomatis menggunakan Windows Task Scheduler.

Program:

```text
powershell.exe
```

Arguments:

```text
-ExecutionPolicy Bypass -File "C:\Path\To\Your\Backup-UserProfile.ps1"
```

Trigger dapat menggunakan `Weekly`, `Daily`, atau `When I log on`, sesuai kebutuhan.

Panduan lengkap tersedia di:

```text
docs/usage.md
```

## 7. Developer Environment

Tool yang relevan untuk workflow:

```powershell
winget install Microsoft.PowerShell
winget install Microsoft.WindowsTerminal
winget install Git.Git
winget install fastfetch
winget install Microsoft.Sysinternals
```

## 8. Security dan Operational Notes

Repository ini mengutamakan command Windows dan script administrasi yang dapat dipahami dan diaudit.

Beberapa prinsip yang digunakan:

- Jangan pipe source internet langsung ke `iex` tanpa memeriksa source.
- Jalankan command Administrator hanya ketika memang diperlukan.
- Review perubahan Registry dan konfigurasi boot sebelum menerapkannya.
- Gunakan backup sebelum perubahan sistem besar.
- Uji script pada environment non-kritis terlebih dahulu.
- Jangan commit credential, token, password, API key, atau file backup ke repository publik.

Materi sumber juga memuat pembahasan tentang tool modifikasi lisensi dan software pihak ketiga. Bagian tersebut diperlakukan sebagai catatan referensi dan tidak dijadikan executable script dalam repository portfolio ini.

## Testing

Test dasar menggunakan Pester tersedia di `tests/Scripts.Tests.ps1`.

Install Pester bila belum ada:

```powershell
Install-Module Pester -Scope CurrentUser -Force
```

Jalankan:

```powershell
Invoke-Pester .\tests\Scripts.Tests.ps1
```

Test ini memeriksa keberadaan script, parameter utama, dan beberapa pola keamanan dasar. Test tidak menjalankan operasi destructive pada sistem host.

## CI

Workflow GitHub Actions di `.github/workflows/powershell-lint.yml` melakukan pemeriksaan syntax/static analysis menggunakan `PSScriptAnalyzer`.

CI tidak mengeksekusi maintenance atau backup pada runner.

## Roadmap

### v1.0.0

- Dokumentasi repository.
- Maintenance script.
- User profile backup.
- System audit.
- Network diagnostics.
- Basic tests.
- GitHub CI.

### v1.1.0

- Logging terstruktur JSON/CSV.
- Parameter untuk dry-run pada maintenance.
- Konfigurasi backup melalui JSON.
- Exit code dan error handling yang lebih konsisten.

### v2.0.0

- PowerShell module.
- Pester test coverage yang lebih luas.
- Scheduled automation installer.
- Report HTML untuk system audit.
- Packaging dan release workflow GitHub.

## Referensi Sumber

Repository ini dikembangkan dari materi PowerShell yang diberikan dalam percakapan. Struktur dan contoh command utamanya tetap mengikuti materi tersebut, kemudian dikemas ulang menjadi format repository yang lebih mudah dipelihara.

## License

MIT License. Lihat `LICENSE`.
