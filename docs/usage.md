# Usage

## System Audit

```powershell
.\scripts\System-Audit.ps1
```

Mode detail:

```powershell
.\scripts\System-Audit.ps1 -Detailed
```

Script audit tidak mengubah konfigurasi sistem.

## Network Diagnostics

Default trace target:

```powershell
.\scripts\Network-Diagnostics.ps1
```

Custom target:

```powershell
.\scripts\Network-Diagnostics.ps1 -TraceHost '8.8.8.8'
```

## Maintenance

Default:

```powershell
.\scripts\Maintenance.ps1
```

Target drive lain:

```powershell
.\scripts\Maintenance.ps1 -DriveLetter 'D'
```

Jalankan terminal sebagai Administrator.

## Backup

Default:

```powershell
.\scripts\Backup-UserProfile.ps1
```

Custom destination:

```powershell
.\scripts\Backup-UserProfile.ps1 -BackupTargetDrive 'E:\Backups'
```

### Task Scheduler

Buat Basic Task di Windows Task Scheduler.

Program:

```text
powershell.exe
```

Arguments:

```text
-ExecutionPolicy Bypass -File "C:\Path\To\Your\Backup-UserProfile.ps1" -BackupTargetDrive "E:\Backups"
```

Untuk konfigurasi yang lebih kuat, pertimbangkan menjalankan script dengan command wrapper `.ps1` yang menyimpan parameter dan validasi secara eksplisit. Hindari menaruh credential di command line.
