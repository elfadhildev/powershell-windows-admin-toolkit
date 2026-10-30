# Changelog

## [1.4.0] - 2026-07-10
### Added
- **Winget App Installer:** Menu interaktif untuk menginstal aplikasi populer.
- **Windows Debloater:** Skrip untuk menghapus aplikasi bawaan Windows.
- **System Restore Point:** Fitur pembuatan titik pemulihan otomatis.
### Changed
- Updated menu to support 8 options.
- Improved overall UX and error handling.

## [1.3.1] - 2026-07-08
### Fixed
- Resolve pause command bug and admin execution in toolkit menu.
- Detect remote execution for irm|iex.

## [1.0.0] - 2026-07-01
- Rilis awal Panduan PowerShell.
## [1.9.2] - 2026-07-15
### Added
- **Pester Testing:** Menambahkan file tes otomatis (`tests/Toolkit.Tests.ps1`) untuk mengecek kualitas kode.
- **GitHub Actions CI:** Menambahkan workflow `pester.yml` agar GitHub otomatis mengetes kode setiap kali ada Push/Pull Request.
## [1.9.4] - 2026-07-16
### Added
- **DNS Switcher:** Fitur untuk mengganti DNS ke Cloudflare/Google/Quad9 atau kembali ke Otomatis (DHCP).
- **Save Report to TXT:** Opsi untuk menyimpan hasil System Audit ke file teks di Desktop.
## [1.9.5] - 2026-07-17
### Fixed
- **System Audit:** Mengembalikan bagian "Driver Bermasalah" yang tidak sengaja terhapus di v1.9.4.
- **Network Diagnostics:** Memperbaiki tampilan IP dan DNS agar tidak terpotong (format list yang lebih rapi).
## [1.9.6] - 2026-07-17
### Fixed
- **Maintenance:** Menghapus parameter `-Verbose` pada proses Optimize-Volume agar tampilan tidak penuh dengan teks proses. Menambahkan indikator progress yang lebih ramah pengguna.
## [1.9.7] - 2026-07-18
### Fixed
- **UI/UX:** Menambahkan perintah `Clear-Host` pada fungsi Opsi 1 (Maintenance) dan Opsi 4 (Backup) agar layar menu sebelumnya bersih dan proses terlihat seperti berada di "halaman baru".
## [1.9.8] - 2026-10-25
### Added
- **Winget App Installer (CTT Style):** Merombak total menu instalasi (Opsi 5) menjadi berbasis kategori (Browsers, Communications, Development, dll) dan memperluas daftar aplikasi (50+ apps).
## [1.9.9] - 2026-10-25
### Added
- **Mega Winget List:** Menambahkan lebih dari 100 aplikasi populer (Browsers, Communications, Development, Document, Games, Microsoft, Multimedia, Pro Tools, Utilities) ke dalam menu instalasi (Opsi 5) agar setara dengan Chris Titus WinUtil.
## [1.10.0] - 2026-10-25
### Added
- **System Tweaks (CTT Style):** Merombak total Opsi 8. Sekarang mendukung multi-select (bisa pilih beberapa tweak sekaligus) dan dibagi menjadi kategori Essential dan Advanced Tweaks seperti di Chris Titus WinUtil.
## [1.10.1] - 2026-10-25
### Added
- **System Tweaks Mega Update:** Menambahkan lebih dari 15 tweak baru (Essential & Advanced) untuk menyaingi CTT WinUtil. Mencakup tweak privasi, performa, UI, dan pembersihan sistem.
## [2.0.0] - 2026-10-25
### Added
- **Major UI Update (GUI):** Mengubah antarmuka dari Command Line menjadi Graphical User Interface (WPF/XAML) berbasis Tile, terinspirasi dari Chris Titus WinUtil.
- Menambahkan tombol interaktif (Maintenance, Audit, Network, Debloater, Tweaks) yang dapat diklik dengan mouse.
- Menggunakan Dark Mode modern dengan border tipis.
## [2.0.1] - 2026-10-25
### Fixed
- **PowerShell Parser Error:** Memperbaiki sintaks pemanggilan fungsi menggunakan `${function:Nama-Fungsi}` agar tidak memicu `Unexpected token`.
- **Pester Test:** Mengembalikan fungsi `Invoke-EventLogAnalyzer` dan tombol Event Log pada GUI agar test otomatis GitHub Actions berhasil.
## [2.0.2] - 2026-10-25
### Fixed
- **GUI Parser Error:** Mengganti metode pemanggilan fungsi `.ToString()` dengan `(Get-Command ...).Definition` agar PowerShell tidak bingung saat membaca parameter fungsi yang memiliki tanda hubung.
## [2.0.3] - 2026-10-25
### Fixed
- **WPF Assembly:** Menambahkan `Add-Type -AssemblyName PresentationFramework` agar kelas GUI bisa dimuat oleh PowerShell.
- **Eksekusi Fungsi:** Memperbaiki pemanggilan fungsi di jendela baru menggunakan blok `& { $cmd; Invoke-Fungsi }`.
