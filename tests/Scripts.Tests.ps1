Describe 'PowerShell Windows Administration Toolkit' {
    BeforeAll {
        $RepoRoot = Split-Path -Parent $PSScriptRoot
        $ScriptsPath = Join-Path $RepoRoot 'scripts'
    }

    It 'memiliki script inti repository' {
        Test-Path (Join-Path $ScriptsPath 'Maintenance.ps1') | Should -BeTrue
        Test-Path (Join-Path $ScriptsPath 'Backup-UserProfile.ps1') | Should -BeTrue
        Test-Path (Join-Path $ScriptsPath 'System-Audit.ps1') | Should -BeTrue
        Test-Path (Join-Path $ScriptsPath 'Network-Diagnostics.ps1') | Should -BeTrue
    }

    It 'Maintenance menerima DriveLetter' {
        $content = Get-Content (Join-Path $ScriptsPath 'Maintenance.ps1') -Raw
        $content | Should -Match '\$DriveLetter\s*=\s*\x27C\x27'
        $content | Should -Match 'Optimize-Volume.*-DriveLetter \$DriveLetter'
    }

    It 'Backup mempertahankan Robocopy dan logging' {
        $content = Get-Content (Join-Path $ScriptsPath 'Backup-UserProfile.ps1') -Raw
        $content | Should -Match '\& robocopy'
        $content | Should -Match '/MIR'
        $content | Should -Match '/LOG\+:\$LogFile'
    }

    It 'System Audit bersifat read-only pada source code' {
        $content = Get-Content (Join-Path $ScriptsPath 'System-Audit.ps1') -Raw
        $content | Should -Not -Match '\bSet-ItemProperty\b'
        $content | Should -Not -Match '\bRemove-Item\b'
        $content | Should -Not -Match '\bNew-Item\b'
    }

    It 'Network Diagnostics tidak memuat command konfigurasi jaringan' {
        $content = Get-Content (Join-Path $ScriptsPath 'Network-Diagnostics.ps1') -Raw
        $content | Should -Not -Match '\bSet-NetIPInterface\b'
        $content | Should -Not -Match '\bNew-NetFirewallRule\b'
        $content | Should -Not -Match '\bRemove-NetIPAddress\b'
    }
}
