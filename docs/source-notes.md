# Source Notes

Dokumen awal yang menjadi dasar repository membahas beberapa kelompok materi:

- Winget dan instalasi software.
- WinUtil dan utility Windows pihak ketiga.
- Script pihak ketiga terkait lisensi/modifikasi software.
- System internals dan Sysinternals.
- Networking dan network analysis.
- WMI/CIM.
- Registry dan boot configuration.
- Maintenance Windows.
- Backup user profile dengan Robocopy.
- Task Scheduler.

Repository portfolio ini mempertahankan dua script operasional utama dari materi, yaitu `Maintenance.ps1` dan `Backup-UserProfile.ps1`, kemudian menambahkan `System-Audit.ps1` dan `Network-Diagnostics.ps1` untuk menunjukkan pembagian tanggung jawab yang lebih jelas.

Bagian yang berkaitan dengan bypass lisensi, patching binary, atau modifikasi proteksi software tidak dijadikan executable script dalam repository ini. Materi tersebut tetap dikenali sebagai bagian dari sumber awal, tetapi dipisahkan dari toolkit administrasi Windows yang menjadi fokus portfolio.

Beberapa command dari source material juga perlu dibaca sebagai contoh, bukan jaminan performa universal. Contohnya network throttling tweak, BCDEDIT, registry tweak, dan pembersihan Prefetch.
