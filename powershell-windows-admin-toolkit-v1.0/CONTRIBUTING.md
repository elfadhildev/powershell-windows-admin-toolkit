# Contributing

## Development Rules

- Gunakan PowerShell style yang konsisten.
- Tambahkan comment hanya ketika menjelaskan alasan atau perilaku yang tidak obvious.
- Hindari credential hardcoded.
- Jangan menambahkan command destructive tanpa dokumentasi dan parameter yang jelas.
- Untuk perubahan script, tambahkan atau update test terkait.

## Pull Request Checklist

- Script dapat dipahami dari nama dan help block.
- Parameter memiliki default yang aman.
- Error handling tidak menyembunyikan kegagalan penting.
- Dokumentasi sudah diperbarui.
- Test Pester lolos.
- Tidak ada secret di repository.
