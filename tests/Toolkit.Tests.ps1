# tests/Toolkit.Tests.ps1
Describe "Toolkit.ps1 Quality Tests" {
    BeforeAll {
        $scriptPath = Join-Path $PSScriptRoot "..\toolkit.ps1"
        $scriptContent = Get-Content -Path $scriptPath -Raw
    }

    It "Harus bebas dari Syntax Error" {
        $errors = $null
        [System.Management.Automation.PSParser]::Tokenize($scriptContent, [ref]$errors) | Out-Null
        $errors.Count | Should -Be 0
    }

    It "Harus memiliki fungsi Invoke-Maintenance" {
        $scriptContent | Should -Match "function Invoke-Maintenance"
    }

    It "Harus memiliki fungsi Invoke-SystemAudit" {
        $scriptContent | Should -Match "function Invoke-SystemAudit"
    }

    It "Harus memiliki fungsi Invoke-EventLogAnalyzer" {
        $scriptContent | Should -Match "function Invoke-EventLogAnalyzer"
    }
}
