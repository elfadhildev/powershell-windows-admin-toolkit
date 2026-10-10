# Troubleshooting

## Script tidak bisa dijalankan

Periksa execution policy:

```powershell
Get-ExecutionPolicy -List
```

Pastikan file benar-benar berupa `.ps1` dan jalankan dari folder repository.

## Maintenance meminta Administrator

Itu memang diharapkan. Script memanggil operasi sistem seperti DNS cache, DHCP renew, cleanup sistem, dan Optimize-Volume.

## File backup dilewati

Beberapa file AppData sedang dibuka aplikasi. Tutup aplikasi terkait lalu ulangi backup jika diperlukan.

Robocopy menggunakan `/R:1 /W:1` sehingga retry dibatasi agar proses tidak menunggu terlalu lama.

## Backup destination terkena efek mirror

Script mempertahankan `/MIR` dari source material. Periksa isi destination sebelum menggunakannya sebagai arsip permanen.

## Optimize-Volume gagal

Pastikan drive letter valid:

```powershell
Get-Partition
```

Lalu periksa media:

```powershell
Get-PhysicalDisk | Select-Object FriendlyName, MediaType, OperationalStatus, HealthStatus
```

## Network trace tidak menghasilkan route lengkap

`Test-NetConnection -TraceRoute` bergantung pada respons jaringan dan kebijakan perangkat perantara. Tidak semua hop harus terlihat.
