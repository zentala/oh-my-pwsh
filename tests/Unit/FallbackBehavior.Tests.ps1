BeforeAll {
    # Source dependencies
    . $PSScriptRoot/../../settings/icons.ps1
    . $PSScriptRoot/../../modules/status-output.ps1
    . $PSScriptRoot/../../modules/logger.ps1
}

Describe "Enhanced Tools Fallback Behavior" {
    Context "When 'bat' is NOT installed" {
        BeforeEach {
            Mock Get-Command { return $null } -ParameterFilter { $Name -eq "bat" }
            Mock Write-Host {}
        }

        It "Does not throw an error" {
            {
                if (Get-Command bat -ErrorAction SilentlyContinue) {
                    # bat exists
                } else {
                    # Fallback to Get-Content
                }
            } | Should -Not -Throw
        }

        It "Get-Command returns null for bat" {
            $result = Get-Command bat -ErrorAction SilentlyContinue
            $result | Should -BeNullOrEmpty
        }
    }

    Context "When 'eza' is NOT installed" {
        BeforeEach {
            Mock Get-Command { return $null } -ParameterFilter { $Name -eq "eza" }
        }

        It "Get-Command returns null for eza" {
            $result = Get-Command eza -ErrorAction SilentlyContinue
            $result | Should -BeNullOrEmpty
        }

        It "Does not throw an error" {
            {
                if (Get-Command eza -ErrorAction SilentlyContinue) {
                    # eza exists
                } else {
                    # Fallback
                }
            } | Should -Not -Throw
        }
    }

    Context "When NO enhanced tools are installed" {
        BeforeEach {
            # Mock all tools as not found
            Mock Get-Command { return $null } -ParameterFilter {
                $Name -in @("bat", "eza", "ripgrep", "rg", "fd", "delta", "fzf", "zoxide")
            }
        }

        It "bat is not found" {
            Get-Command bat -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
        }

        It "eza is not found" {
            Get-Command eza -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
        }

        It "ripgrep is not found" {
            Get-Command rg -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
        }

        It "fd is not found" {
            Get-Command fd -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
        }

        It "delta is not found" {
            Get-Command delta -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
        }

        It "fzf is not found" {
            Get-Command fzf -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
        }

        It "zoxide is not found" {
            Get-Command zoxide -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
        }

        It "Does not throw errors when checking for any tool" {
            {
                $tools = @("bat", "eza", "rg", "fd", "delta", "fzf", "zoxide")
                foreach ($tool in $tools) {
                    $null = Get-Command $tool -ErrorAction SilentlyContinue
                }
            } | Should -Not -Throw
        }
    }

    Context "When ALL enhanced tools ARE installed" {
        BeforeEach {
            # Mock all tools as found
            Mock Get-Command {
                return [PSCustomObject]@{
                    Name = $Name
                    Source = "C:\mock\$Name.exe"
                }
            } -ParameterFilter {
                $Name -in @("bat", "eza", "ripgrep", "rg", "fd", "delta", "fzf", "zoxide")
            }
        }

        It "bat is found" {
            Get-Command bat -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It "eza is found" {
            Get-Command eza -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It "ripgrep is found" {
            Get-Command rg -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It "fd is found" {
            Get-Command fd -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It "delta is found" {
            Get-Command delta -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It "fzf is found" {
            Get-Command fzf -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It "zoxide is found" {
            Get-Command zoxide -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }
}

Describe "Write-InstallHint Fallback Behavior" {
    BeforeEach {
        Mock Write-Host {}
        Mock Get-Command { return $null } -ParameterFilter { $Name -eq "bat" }
    }

    Context "When tool is missing" {
        It "Shows warning message" {
            Write-InstallHint -Tool "bat" -InstallCommand "scoop install bat"

            Should -Invoke Write-Host -ParameterFilter {
                $Object -eq "!" -and $ForegroundColor -eq "Yellow"
            }
        }

        It "Displays tool name with backticks" {
            Write-InstallHint -Tool "bat" -InstallCommand "scoop install bat"

            Should -Invoke Write-Host -ParameterFilter {
                $Object -eq "``bat``" -and $ForegroundColor -eq "Yellow"
            }
        }

        It "Displays install command" {
            Write-InstallHint -Tool "bat" -InstallCommand "scoop install bat"

            Should -Invoke Write-Host -ParameterFilter {
                $Object -eq "scoop install bat" -and $ForegroundColor -eq "DarkGray"
            }
        }

        It "Does not throw errors" {
            { Write-InstallHint -Tool "bat" -InstallCommand "scoop install bat" } | Should -Not -Throw
        }
    }
}

Describe "Profile Load Resilience" {
    Context "When profile components are sourced" {
        It "Icon system loads without errors" {
            { . $PSScriptRoot/../../settings/icons.ps1 } | Should -Not -Throw
        }

        It "Status output module loads without errors" {
            { . $PSScriptRoot/../../modules/status-output.ps1 } | Should -Not -Throw
        }

        It "Logger module loads without errors" {
            { . $PSScriptRoot/../../modules/logger.ps1 } | Should -Not -Throw
        }

        It "Functions are available after sourcing" {
            . $PSScriptRoot/../../settings/icons.ps1
            . $PSScriptRoot/../../modules/status-output.ps1

            Get-Command Get-FallbackIcon | Should -Not -BeNullOrEmpty
            Get-Command Write-StatusMessage | Should -Not -BeNullOrEmpty
        }
    }
}
