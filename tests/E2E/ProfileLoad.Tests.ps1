#Requires -Modules Pester

BeforeAll {
    $script:projectRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:profileScript = Join-Path $projectRoot "profile.ps1"
}

Describe "Profile Loading - E2E Smoke Test" -Tag @('E2E', 'Smoke') {

    Context "When loading profile with all tools available" {
        It "Loads without throwing errors" {
            {
                # Create isolated session
                $output = & pwsh -NoProfile -Command {
                    param($profilePath)

                    # Suppress all output except errors
                    $WarningPreference = 'SilentlyContinue'
                    $InformationPreference = 'SilentlyContinue'
                    $VerbosePreference = 'SilentlyContinue'

                    try {
                        . $profilePath
                        Write-Output "SUCCESS"
                    } catch {
                        Write-Error $_
                        Write-Output "FAILED"
                    }
                } -args $script:profileScript 2>&1

                # Check for success marker
                $successMarker = $output | Where-Object { $_ -eq "SUCCESS" }
                $successMarker | Should -Not -BeNullOrEmpty -Because "Profile should load without throwing errors"

            } | Should -Not -Throw
        }

    }

    Context "When loading profile with NO enhanced tools (regression test)" {
        It "Loads without errors when enhanced tools are missing" {
            {
                $output = & pwsh -NoProfile -Command {
                    param($profilePath)

                    # Mock Get-Command to simulate missing tools
                    function Get-Command {
                        param($Name, $ErrorAction)

                        # Simulate all enhanced tools as missing
                        $enhancedTools = @('bat', 'eza', 'rg', 'fd', 'delta', 'fzf', 'zoxide')
                        if ($Name -in $enhancedTools) {
                            if ($ErrorAction -eq 'SilentlyContinue') {
                                return $null
                            }
                            throw "Command not found: $Name"
                        }

                        # Call real Get-Command for everything else
                        Microsoft.PowerShell.Core\Get-Command @PSBoundParameters
                    }

                    $WarningPreference = 'SilentlyContinue'
                    $InformationPreference = 'SilentlyContinue'

                    try {
                        . $profilePath
                        Write-Output "SUCCESS"
                    } catch {
                        Write-Error $_
                        Write-Output "FAILED: $($_.Exception.Message)"
                    }
                } -args $script:profileScript 2>&1

                $successMarker = $output | Where-Object { $_ -eq "SUCCESS" }
                $successMarker | Should -Not -BeNullOrEmpty -Because "Profile should gracefully handle missing tools"

            } | Should -Not -Throw
        }

    }

    Context "Zero-Error Philosophy" {
        It "Does not write to error stream during normal load" {
            $errors = & pwsh -NoProfile -Command {
                param($profilePath)

                $WarningPreference = 'SilentlyContinue'

                try {
                    . $profilePath 2>&1 | Where-Object { $_ -is [System.Management.Automation.ErrorRecord] }
                } catch {
                    # Catch but don't fail - we're testing error stream
                    $_
                }
            } -args $script:profileScript

            # Filter out warnings about missing tools (those are expected)
            $realErrors = $errors | Where-Object {
                $_ -is [System.Management.Automation.ErrorRecord] -and
                $_.Exception.Message -notmatch '(not found|not installed|command not found)'
            }

            $realErrors | Should -BeNullOrEmpty -Because "Profile should not throw errors during load"
        }
    }

    Context "Performance" {
        It "Loads in under 10 seconds" {
            $elapsed = Measure-Command {
                & pwsh -NoProfile -Command {
                    param($profilePath)
                    $WarningPreference = 'SilentlyContinue'
                    . $profilePath
                } -args $script:profileScript
            }

            $elapsed.TotalSeconds | Should -BeLessThan 10 -Because "Profile should load in reasonable time"
        }
    }
}
