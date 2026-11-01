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
## [2.0.4] - 2026-10-25
### Fixed
- **irm|iex Compatibility:** Menggunakan `[scriptblock]::Create` untuk mencegah error `if is not recognized` saat skrip dijalankan dari URL.
- **WPF Assembly:** Memuat `PresentationFramework` dengan `-PassThru` agar kelas `XamlReader` selalu tersedia.
## [2.0.5] - 2026-10-25
### Fixed
- **String Escaping:** Menggunakan Base64 Encoding untuk mengirim isi fungsi ke jendela baru agar terhindar dari error `Missing expression after ','`.
- **IEX Comment Bug:** Menghapus komentar di baris pertama skrip agar `irm | iex` tidak memicu error `# is not recognized`.
## [2.1.0] - 2026-10-25
### Fixed
- **GUI Execution Ultimate:** Menggunakan `-EncodedCommand` dengan Base64 UTF-16LE untuk mengirim fungsi ke jendela baru secara utuh, bebas dari error tanda kutip.
- **Dependency Injection:** Menyertakan fungsi pendukung (seperti `Backup-RegistryTweaks`) ke dalam Base64 agar tidak error saat dipanggil di jendela baru.
- **Event Log Restore:** Mengembalikan isi fungsi `Invoke-EventLogAnalyzer` yang sempat kosong.
- **BOM Removal:** Menyimpan file tanpa BOM untuk mencegah error `$ErrorActionPreference` saat dijalankan via `irm | iex`.
## [2.2.0] - 2026-10-25
### Added
- **5 Opsi Baru di GUI:** Menambahkan tombol Install Apps, App Backup, Update Mgr, DNS Switcher, dan Presets.
### Fixed
- **Auto Close Window:** Menghapus parameter `-NoExit` pada `Start-Process` agar jendela anak otomatis tertutup saat fungsi selesai, sehingga pengguna langsung kembali ke menu utama GUI.
## [3.0.0] - 2026-10-25
### Added
- **Full GUI Experience:** Mengubah hampir semua fungsi menjadi GUI (Checkbox & MessageBox).
- **Deep Clean Maintenance:** Fitur pembersihan mendalam (Temp, DNS, Disk Cleanup, DISM WinSxS, SFC) di dalam GUI interaktif.
- **Install Apps GUI:** Menambahkan 40 aplikasi populer dengan sistem Checkbox.
## [3.1.0] - 2026-10-25
### Added
- **Tabbed GUI (CTT Style):** Tweaks dan Install Apps sekarang dikategorikan ke dalam Tab (Privasi, Performa, Browsers, Dev, dll) agar rapi dan tidak perlu scroll panjang.
- **Premium Dark UI:** Semua kotak dialog (DNS, Update, Backup) diganti dengan jendela WPF kustom yang mendukung Dark Mode, bukan lagi MessageBox putih kaku.
- **Fixed Pester & Debloater:** Mengembalikan fungsi CLI yang hilang agar test otomatis lulus dan Debloater tidak error.
## [3.1.1] - 2026-10-25
### Fixed
- **XAML Parsing Error:** Menghapus atribut `Name='Panel_UIUX'` (yang mengandung karakter `/`) pada TabItem yang menyebabkan GUI Tweaks gagal dimuat.
- **Debloater Missing Function:** Memperbaiki fungsi `Show-SimpleCLI` agar menggunakan Base64 Encoding, sehingga fungsi Debloater (dan CLI lainnya) berhasil dikirim ke jendela baru tanpa error.
- **Premium Dark UI:** Mengganti semua sisa `MessageBox` putih kaku (untuk notifikasi sukses/gagal DNS, Update, Backup) dengan jendela kustom Dark Mode.
## [3.1.2] - 2026-10-25
### Added
- **Debloater GUI:** Mengubah Debloater menjadi antarmuka kotak centang (Checkbox) yang mewah.
### Fixed
- **CLI Return Error:** Memperbaiki fungsi `Show-SimpleCLI` dengan menyuntikkan definisi fungsi yang benar ke dalam Base64, sehingga setelah menekan Enter (System Audit, Network, Event Log), jendela langsung tertutup tanpa error merah.
## [3.1.3] - 2026-10-25
### Fixed
- **XAML Escaping Error:** Memperbaiki karakter `&` yang tidak di-escape pada item "Movies & TV" di daftar Debloater, yang menyebabkan error `An error occurred while parsing EntityName`.
## [3.1.4] - 2026-10-25
### Fixed
- **Dialog Return Value:** Memperbaiki fungsi `Show-CustomDialog` agar mengembalikan nilai pilihan tombol dengan benar menggunakan `Hashtable` dan `GetNewClosure()`.
- **Update Manager, DNS, & Backup:** Memastikan perintah (Pause Update, Ganti DNS, Export/Import) benar-benar dieksekusi setelah pengguna memilih opsi di dialog.
## [3.2.0] - 2026-10-25
### Added
- **Mega DNS Switcher:** Menambahkan 8 pilihan DNS (Google, Cloudflare, Cloudflare Malware, OpenDNS, Quad9, AdGuard) ke dalam antarmuka ComboBox.
- **Security Updates Only:** Menambahkan opsi khusus di Update Manager untuk menunda fitur baru, namun tetap menerima pembaruan keamanan.
## [3.2.1] - 2026-10-25
### Added
- **Mega Tweaks & Categories:** Menambahkan 38 Tweak (Essential & Advanced) sesuai referensi CTT, mencakup optimasi privasi, performa, UI, AI, dan pembersihan mendalam.
## [3.2.2] - 2026-10-25
### Fixed
- **XAML Ampersand Escaping:** Memperbaiki karakter `&` pada nama Tweak ("Date & Time" dan "Notifications & Calendar") menjadi `&amp;`. Menambahkan fungsi replace otomatis di dalam loop GUI agar tidak akan pernah error lagi jika ada karakter `&`.
## [3.2.3] - 2026-10-25
### Fixed
- **Debloater List Kosong:** Mengisi `$Global:DebloatList` dengan 35 paket bloatware Windows 11 yang dikategorikan (Microsoft Apps, Bing & Web Services, Developer Tools, Xbox & Gaming, Utilities & Productivity).
- **Fitur Tambahan:** Menambahkan tombol "Select All" dan "Clear Selection" pada GUI Debloater untuk memudahkan pemilihan massal.
## [3.2.4] - 2026-10-25
### Fixed
- **XAML EntityName Error:** Meng-escape karakter `&` menjadi `&amp;` pada nama kategori Debloater (`Bing & Web Services`, `Xbox & Gaming`, `Utilities & Productivity`) dan nama item.
- **Tweaks Panel Kosong:** Memastikan `$Global:TweakList` terdefinisi dengan benar dan tersedia di dalam fungsi `Show-TweaksGUI` sebelum loop pembuatan CheckBox.
## [3.2.5] - 2026-11-01
### Fixed
- **Install Applications Kosong:** Mendefinisikan kembali variabel `$Global:AppList` yang sempat hilang pada v3.2.4. Variabel ini sekarang berisi 32 aplikasi populer dengan kategori lengkap (Browsers, Comms, Dev, Doc, Games, Media, Utils, Pro Tools).
- **Scope Variabel:** Memastikan `$Global:TweakList`, `$Global:AppList`, dan `$Global:DebloatList` berada pada scope global (`$Global:`) yang dapat dibaca oleh fungsi-fungsi GUI.
## [3.2.6] - 2026-11-01
### Fixed
- **App Backup Error:** Mengembalikan fungsi `Show-CustomDialog` yang tidak sengaja terhapus pada versi v3.2.5, sehingga tombol App Backup bisa berfungsi normal.
## [3.2.7] - 2026-11-01
### Fixed
- **Maintenance Job Error:** Memperbaiki error `Cannot bind argument to parameter 'Job' because it is null` pada Deep Clean Maintenance. Job dan Timer sekarang disimpan di scope `$script:` sehingga tidak hilang saat event handler WPF berjalan.
## [3.2.8] - 2026-11-01
### Fixed
- **Auto-Close Terminal:** Menghapus parameter `-NoExit` pada fungsi `Show-SimpleCLI`. Sekarang, jendela terminal System Audit, Network, dan Event Log akan otomatis tertutup saat pengguna menekan Enter, dan kembali ke menu GUI utama.
## [3.3.0] - 2026-11-01
### Added
- **Mega App List Expansion:** Menambahkan lebih dari 150 aplikasi baru dari referensi gambar (total 231 aplikasi) ke dalam menu Install Apps, dikelompokkan ke dalam 10 kategori (Browsers, Comms, Dev, Doc, Games, Microsoft Tools, Multimedia, Pro Tools, Selfhosted, Utilities).
## [3.4.0] - 2026-11-01
### Added
- **One-Click Fixes:** Menambahkan menu perbaikan darurat (Reset Network, Reset Update Cache, Repair System SFC/DISM).
- **Startup Manager:** GUI untuk melihat dan menghapus program yang berjalan otomatis saat startup.
- **Automation Presets:** Instalasi aplikasi secara massal dengan satu klik (Standard, Gamer, Developer).
## [3.4.1] - 2026-11-01
### Added
- **Deep Startup Manager:** Startup Manager kini mendeteksi aplikasi dari 3 sumber: Registry, Startup Folder, dan Task Scheduler. Item yang dinonaktifkan diberi label asal (contoh: [Registry], [Folder], [Task]).
### Fixed
- **Safe Disable:** Menonaktifkan item dari Folder akan memindahkannya ke folder aman di Desktop. Menonaktifkan Task akan menggunakan perintah `Disable-ScheduledTask` (tidak menghapus), sehingga sistem tetap aman.
