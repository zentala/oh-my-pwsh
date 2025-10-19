#Requires -Modules Pester

BeforeAll {
    $script:demoScript = Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) "demos/tui-demo.ps1"
}

Describe "TUI Demo Script" -Tag @('Unit', 'Demo') {

    Context "Script syntax and structure" {
        It "Demo script exists" {
            $script:demoScript | Should -Exist
        }

        It "Has valid PowerShell syntax" {
            $errors = $null
            $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $script:demoScript -Raw), [ref]$errors)
            $errors.Count | Should -Be 0
        }

        It "Requires PwshSpectreConsole module" {
            $content = Get-Content $script:demoScript -Raw
            $content | Should -Match '#Requires -Modules PwshSpectreConsole'
        }

        It "Has Quick mode parameter" {
            $content = Get-Content $script:demoScript -Raw
            $content | Should -Match '\[switch\]\$Quick'
        }
    }

    Context "Read-SpectreConfirm usage" {
        It "Uses valid DefaultAnswer values" {
            $content = Get-Content $script:demoScript -Raw

            # Extract all Read-SpectreConfirm calls
            $confirmCalls = [regex]::Matches($content, 'Read-SpectreConfirm[^)]+\)')

            foreach ($call in $confirmCalls) {
                # Check if it has DefaultAnswer parameter
                if ($call.Value -match '-DefaultAnswer\s+([^\s)]+)') {
                    $value = $matches[1]
                    # Should be one of: "y", "n", "none", or variable (allowed)
                    if ($value -notmatch '^\$') {
                        $value | Should -BeIn @('"y"', '"n"', '"none"', "'y'", "'n'", "'none'")
                    }
                }
            }
        }
    }

    Context "Quick mode execution" {
        It "Runs without errors in Quick mode" {
            # Quick mode should not require interactive prompts
            {
                $output = & pwsh -NoProfile -Command {
                    param($scriptPath)
                    $env:IgnoreSpectreEncoding = $true
                    & $scriptPath -Quick
                } -args $script:demoScript 2>&1

                # Should not throw errors about interactive mode
                $errors = $output | Where-Object { $_ -is [System.Management.Automation.ErrorRecord] }
                if ($errors) {
                    throw "Quick mode produced errors: $($errors -join '; ')"
                }
            } | Should -Not -Throw
        }
    }
}
