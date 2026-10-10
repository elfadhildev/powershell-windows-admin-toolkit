# Changelog

## [1.0.0] - 2026-09-23

### Added

- Professional GitHub repository structure.
- `Maintenance.ps1` as the original maintenance workflow with a `DriveLetter` parameter.
- `Backup-UserProfile.ps1` as the original backup workflow with a configurable destination.
- `System-Audit.ps1` for read-only Windows audit.
- `Network-Diagnostics.ps1` for network troubleshooting.
- Pester-based static tests.
- GitHub Actions static analysis workflow.
- Installation, usage, and troubleshooting documentation.
- Example JSON configuration.

### Changed

- Reorganized source material into documentation, scripts, tests, and configuration.
- Clarified operational risks around Robocopy `/MIR` and system-level tweaks.
- Kept third-party license-modification material out of executable toolkit scripts.
