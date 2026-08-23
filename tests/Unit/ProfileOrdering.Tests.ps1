#Requires -Modules Pester

Describe "Profile prompt-hook ordering (zoxide / oh-my-posh)" -Tag @('Unit', 'Profile', 'Regression') {

    BeforeAll {
        $script:projectRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
        $script:profilePath = Join-Path $projectRoot "profile.ps1"
        $script:profileContent = Get-Content $script:profilePath -Raw
        $script:profileLines = Get-Content $script:profilePath

        # Helper to find first line number for a pattern (1-based), $null if not found
        function Get-LineNumber {
            param([string]$Pattern)
            for ($i = 0; $i -lt $script:profileLines.Count; $i++) {
                if ($script:profileLines[$i] -match $Pattern) { return $i + 1 }
            }
            return $null
        }
    }

    Context "When profile file exists" {
        It "profile.ps1 exists" {
            Test-Path $script:profilePath | Should -BeTrue
        }

        It "profile.ps1 is valid PowerShell" {
            $errs = $null; $toks = $null
            $null = [System.Management.Automation.Language.Parser]::ParseFile($script:profilePath, [ref]$toks, [ref]$errs)
            $errs.Count | Should -Be 0
        }
    }

    Context "Static file ordering - zoxide must wrap oh-my-posh" {
        It "places zoxide init after oh-my-posh init" {
            $omp = Get-LineNumber 'oh-my-posh init pwsh'
            $zoxide = Get-LineNumber 'zoxide init powershell'

            $omp | Should -Not -BeNullOrEmpty -Because "profile should contain 'oh-my-posh init pwsh'"
            $zoxide | Should -Not -BeNullOrEmpty -Because "profile should contain 'zoxide init powershell'"
            $zoxide | Should -BeGreaterThan $omp -Because "zoxide must be after oh-my-posh or its prompt hook is overwritten"
        }

        It "places fnm init after oh-my-posh init" {
            $omp = Get-LineNumber 'oh-my-posh init pwsh'
            $fnm = Get-LineNumber 'fnm env --use-on-cd'

            $omp | Should -Not -BeNullOrEmpty
            $fnm | Should -Not -BeNullOrEmpty -Because "profile should contain 'fnm env --use-on-cd'"
            $fnm | Should -BeGreaterThan $omp -Because "fnm also hooks prompt and must be after oh-my-posh"
        }

        It "documents the ordering requirement with a comment" {
            $script:profileContent | Should -Match 'zoxide.*MUST load AFTER oh-my-posh'
        }

        It "does not leave stale zoxide block before core modules" {
            # The LOAD CORE MODULES header should appear before oh-my-posh, not between zoxide and fnm.
            $core = Get-LineNumber 'LOAD CORE MODULES'
            $omp  = Get-LineNumber 'OH MY POSH'
            $zoxide = Get-LineNumber 'zoxide init powershell'

            $core | Should -BeGreaterThan 0
            $omp | Should -BeGreaterThan $core
            $zoxide | Should -BeGreaterThan $omp
        }
    }

    Context "Functional prompt wrapping - why ordering matters" {
        # These tests simulate the actual hook mechanism without needing the
        # real binaries. They document the bug and prove the fix ordering.

        BeforeEach {
            # Start each test with a clean prompt
            if (Test-Path Function:\prompt) { Remove-Item Function:\prompt -Force }
            function global:prompt { "P0" }
            $global:__zoxide_hookCalled = $false
            $global:__zoxide_hook = { $global:__zoxide_hookCalled = $true }
        }
        AfterEach {
            if (Test-Path Function:\prompt) { Remove-Item Function:\prompt -Force }
            Remove-Variable -Name __zoxide_hookCalled -Scope Global -ErrorAction SilentlyContinue
            Remove-Variable -Name __zoxide_hook -Scope Global -ErrorAction SilentlyContinue
            Remove-Variable -Name __zoxide_prompt_old -Scope Global -ErrorAction SilentlyContinue
        }

        It "zoxide before oh-my-posh loses its hook (the bug)" {
            # Simulate zoxide wrapping P0
            $global:__zoxide_prompt_old = $function:prompt
            function global:prompt { & $global:__zoxide_prompt_old; & $global:__zoxide_hook }

            $wrapped = $function:prompt.ToString()
            $wrapped | Should -Match '__zoxide_hook' -Because "zoxide wrapper should call hook"

            # Simulate oh-my-posh REPLACING prompt (does NOT call old)
            $script:ompPrompt = { "OMP" }
            $function:prompt = $script:ompPrompt

            $global:__zoxide_hookCalled = $false
            & $function:prompt | Out-Null
            $global:__zoxide_hookCalled | Should -BeFalse -Because "oh-my-posh overwrote zoxide's wrapper"
            $function:prompt.ToString() | Should -Not -Match '__zoxide_hook'
        }

        It "zoxide after oh-my-posh preserves its hook (the fix)" {
            # Simulate oh-my-posh first (replaces P0)
            $script:ompPrompt = { "OMP" }
            $function:prompt = $script:ompPrompt

            # Simulate zoxide wrapping the OMP prompt
            $global:__zoxide_prompt_old = $function:prompt
            function global:prompt { & $global:__zoxide_prompt_old; & $global:__zoxide_hook }

            $global:__zoxide_hookCalled = $false
            & $function:prompt | Out-Null
            $global:__zoxide_hookCalled | Should -BeTrue -Because "zoxide outer wrapper should still run"
            $function:prompt.ToString() | Should -Match '__zoxide_hook'
        }
    }
}
