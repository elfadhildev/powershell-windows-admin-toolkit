Describe "Toolkit.ps1 Quality Tests" {
    BeforeAll {
        $scriptPath = Join-Path $PSScriptRoot "..\toolkit.ps1"
        $scriptContent = Get-Content -Path $scriptPath -Raw
    }

    It "Harus bebas dari Syntax Error" {
        $tokens = $null
        $errors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseInput($scriptContent, [ref]$tokens, [ref]$errors)
        $errors.Count | Should -Be 0
    }

    It "Harus memiliki fungsi Execute-Tweaks" {
        $scriptContent | Should -Match "function Execute-Tweaks"
    }

    It "Harus memiliki fungsi Execute-Debloat" {
        $scriptContent | Should -Match "function Execute-Debloat"
    }

    It "Harus memiliki fungsi Show-GUI" {
        $scriptContent | Should -Match "function Show-GUI"
    }
}