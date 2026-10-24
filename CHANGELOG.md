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
