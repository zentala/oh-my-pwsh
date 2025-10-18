BeforeAll {
    # Source dependencies
    . $PSScriptRoot/../../settings/icons.ps1
    . $PSScriptRoot/../../modules/status-output.ps1
    . $PSScriptRoot/../../modules/logger.ps1

    # Enable enhanced tools
    $global:OhMyPwsh_UseEnhancedTools = $true
    $global:OhMyPwsh_ShowFeedback = $false
}

Describe "Enhanced Tools Module Loading" {
    Context "When all tools are installed" {
        It "Module loads without errors" {
            Mock Get-Command {
                param($Name)
                if ($Name -in @("bat", "eza", "rg", "fd", "delta")) {
                    return [PSCustomObject]@{ Name = $Name; Source = "C:\\$Name.exe" }
                }
                return $null
            }
            Mock Write-ToolStatus {}
            Mock Write-Host {}
            Mock git {}

            { . $PSScriptRoot/../../modules/enhanced-tools.ps1 } | Should -Not -Throw
        }
    }

    Context "When NO tools are installed" {
        It "Module loads without errors (fallbacks)" {
            Mock Get-Command { return $null } -ParameterFilter { $Name -in @("bat", "eza", "rg", "fd", "delta") }
            Mock Write-ToolStatus {}
            Mock Write-Host {}
            Mock Set-Alias {}

            { . $PSScriptRoot/../../modules/enhanced-tools.ps1 } | Should -Not -Throw
        }
    }

    Context "When module is disabled" {
        It "Returns early when OhMyPwsh_UseEnhancedTools is false" {
            $global:OhMyPwsh_UseEnhancedTools = $false

            { . $PSScriptRoot/../../modules/enhanced-tools.ps1 } | Should -Not -Throw

            # Reset
            $global:OhMyPwsh_UseEnhancedTools = $true
        }
    }
}

Describe "Enhanced Tools - Individual Tool Tests" {
    BeforeEach {
        Mock Write-ToolStatus {}
        Mock Write-Host {}
    }

    Context "bat fallback" {
        It "Does not throw when bat is missing" {
            Mock Get-Command { return $null } -ParameterFilter { $Name -eq "bat" }
            Mock Set-Alias {}

            { . $PSScriptRoot/../../modules/enhanced-tools.ps1 } | Should -Not -Throw
        }

        It "Does not throw when bat is present" {
            Mock Get-Command { return [PSCustomObject]@{ Name = "bat" } } -ParameterFilter { $Name -eq "bat" }

            { . $PSScriptRoot/../../modules/enhanced-tools.ps1 } | Should -Not -Throw
        }
    }

    Context "eza fallback" {
        It "Does not throw when eza is missing" {
            Mock Get-Command { return $null } -ParameterFilter { $Name -eq "eza" }

            { . $PSScriptRoot/../../modules/enhanced-tools.ps1 } | Should -Not -Throw
        }

        It "Does not throw when eza is present" {
            Mock Get-Command { return [PSCustomObject]@{ Name = "eza" } } -ParameterFilter { $Name -eq "eza" }

            { . $PSScriptRoot/../../modules/enhanced-tools.ps1 } | Should -Not -Throw
        }
    }

    Context "ripgrep fallback" {
        It "Does not throw when ripgrep is missing" {
            Mock Get-Command { return $null } -ParameterFilter { $Name -eq "rg" }

            { . $PSScriptRoot/../../modules/enhanced-tools.ps1 } | Should -Not -Throw
        }

        It "Does not throw when ripgrep is present" {
            Mock Get-Command { return [PSCustomObject]@{ Name = "rg" } } -ParameterFilter { $Name -eq "rg" }

            { . $PSScriptRoot/../../modules/enhanced-tools.ps1 } | Should -Not -Throw
        }
    }

    Context "fd fallback" {
        It "Does not throw when fd is missing" {
            Mock Get-Command { return $null } -ParameterFilter { $Name -eq "fd" }

            { . $PSScriptRoot/../../modules/enhanced-tools.ps1 } | Should -Not -Throw
        }

        It "Does not throw when fd is present" {
            Mock Get-Command { return [PSCustomObject]@{ Name = "fd" } } -ParameterFilter { $Name -eq "fd" }

            { . $PSScriptRoot/../../modules/enhanced-tools.ps1 } | Should -Not -Throw
        }
    }

    Context "delta fallback" {
        It "Does not throw when delta is missing" {
            Mock Get-Command { return $null } -ParameterFilter { $Name -eq "delta" }

            { . $PSScriptRoot/../../modules/enhanced-tools.ps1 } | Should -Not -Throw
        }

        It "Does not throw when delta is present" {
            Mock Get-Command { return [PSCustomObject]@{ Name = "delta" } } -ParameterFilter { $Name -eq "delta" }
            Mock git {}

            { . $PSScriptRoot/../../modules/enhanced-tools.ps1 } | Should -Not -Throw
        }
    }
}

Describe "Install-EnhancedTools function" {
    BeforeAll {
        Mock Write-Host {}
        Mock Get-Command { return [PSCustomObject]@{ Name = "scoop" } } -ParameterFilter { $Name -eq "scoop" }
        Mock Write-ToolStatus {}

        . $PSScriptRoot/../../modules/enhanced-tools.ps1
    }

    It "Function exists" {
        Get-Command Install-EnhancedTools -CommandType Function | Should -Not -BeNullOrEmpty
    }

    Context "When scoop is not installed" {
        It "Does not throw" {
            Mock Get-Command { return $null } -ParameterFilter { $Name -eq "scoop" }

            { Install-EnhancedTools } | Should -Not -Throw
        }
    }

    Context "When scoop is installed" {
        It "Does not throw" {
            Mock Get-Command {
                param($Name)
                if ($Name -eq "scoop") { return [PSCustomObject]@{ Name = "scoop" } }
                if ($Name -in @("bat", "eza")) { return [PSCustomObject]@{ Name = $Name } }
                return $null
            }
            # Create a dummy scoop function instead of mocking
            function global:scoop { param($args) }
            Mock Write-Host {}

            { Install-EnhancedTools } | Should -Not -Throw
        }
    }
}
