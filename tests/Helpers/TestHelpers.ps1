# ============================================
# Test Helpers for oh-my-pwsh
# ============================================
# Reusable helper functions for Pester tests

<#
.SYNOPSIS
    Mock all console output functions

.DESCRIPTION
    Mocks Write-Host, Write-Output, Write-Error, Write-Warning for clean test output

.EXAMPLE
    BeforeEach {
        Mock-ConsoleOutput
    }
#>
function Mock-ConsoleOutput {
    Mock Write-Host {}
    Mock Write-Output {}
    Mock Write-Error {}
    Mock Write-Warning {}
}

<#
.SYNOPSIS
    Assert that Write-Host was called with text containing expected string

.PARAMETER Expected
    The text that should appear in Write-Host output

.EXAMPLE
    Assert-OutputContains "Module loaded"
#>
function Assert-OutputContains {
    param([string]$Expected)

    Should -Invoke Write-Host -ParameterFilter {
        $Object -like "*$Expected*"
    }
}

<#
.SYNOPSIS
    Assert that Write-Host was called with specific color

.PARAMETER Color
    The expected foreground color

.EXAMPLE
    Assert-OutputColor "Green"
#>
function Assert-OutputColor {
    param([string]$Color)

    Should -Invoke Write-Host -ParameterFilter {
        $ForegroundColor -eq $Color
    }
}

<#
.SYNOPSIS
    Create a temporary config file for testing

.PARAMETER Settings
    Hashtable of settings to include in config

.OUTPUTS
    String - Path to temporary config file

.EXAMPLE
    $config = New-TempConfig -Settings @{
        OhMyPwsh_UseNerdFonts = $true
        OhMyPwsh_ShowFeedback = $false
    }
#>
function New-TempConfig {
    param([hashtable]$Settings)

    $tempConfig = Join-Path $TestDrive "test-config.ps1"

    $Settings.GetEnumerator() | ForEach-Object {
        "`$$($_.Key) = `$$($_.Value)" | Out-File $tempConfig -Append
    }

    return $tempConfig
}

<#
.SYNOPSIS
    Mock Get-Command to simulate tool availability

.PARAMETER ToolsInstalled
    Array of tool names that should be "installed" (return command object)

.PARAMETER ToolsMissing
    Array of tool names that should be "missing" (return null)

.EXAMPLE
    Mock-ToolAvailability -ToolsInstalled @("bat", "eza") -ToolsMissing @("ripgrep", "fd")
#>
function Mock-ToolAvailability {
    param(
        [string[]]$ToolsInstalled = @(),
        [string[]]$ToolsMissing = @()
    )

    # Mock installed tools
    if ($ToolsInstalled.Count -gt 0) {
        Mock Get-Command {
            if ($Name -in $ToolsInstalled) {
                return [PSCustomObject]@{
                    Name = $Name
                    Source = "C:\mock\$Name.exe"
                    CommandType = "Application"
                }
            }
            return $null
        }
    }

    # Mock missing tools
    if ($ToolsMissing.Count -gt 0) {
        Mock Get-Command {
            if ($Name -in $ToolsMissing) {
                return $null
            }
            # Default behavior for other commands
            return & (Get-Command Get-Command -CommandType Cmdlet) -Name $Name -ErrorAction SilentlyContinue
        }
    }
}

<#
.SYNOPSIS
    Create test config using builder pattern

.DESCRIPTION
    Returns a config hashtable that can be extended with builder methods

.OUTPUTS
    Hashtable - Base config object

.EXAMPLE
    $config = New-TestConfig
    $config = Add-NerdFonts $config
    $config = Add-Tools $config @("bat", "eza")
#>
function New-TestConfig {
    return @{
        UseNerdFonts = $false
        Tools = @{}
        ShowFeedback = $false
        EnableLinuxCompat = $true
    }
}

<#
.SYNOPSIS
    Add Nerd Fonts support to test config

.PARAMETER Config
    Config hashtable to modify

.OUTPUTS
    Hashtable - Modified config

.EXAMPLE
    $config = New-TestConfig | Add-NerdFonts
#>
function Add-NerdFonts {
    param([hashtable]$Config)

    $Config.UseNerdFonts = $true
    return $Config
}

<#
.SYNOPSIS
    Add tools to test config

.PARAMETER Config
    Config hashtable to modify

.PARAMETER ToolNames
    Array of tool names to mark as available

.OUTPUTS
    Hashtable - Modified config

.EXAMPLE
    $config = New-TestConfig | Add-Tools -ToolNames @("bat", "eza")
#>
function Add-Tools {
    param(
        [hashtable]$Config,
        [string[]]$ToolNames
    )

    foreach ($tool in $ToolNames) {
        $Config.Tools[$tool] = $true
    }

    return $Config
}

<#
.SYNOPSIS
    Apply test config to global scope

.PARAMETER Config
    Config hashtable to apply

.EXAMPLE
    $config = New-TestConfig | Add-NerdFonts | Add-Tools @("bat")
    Apply-TestConfig $config
#>
function Apply-TestConfig {
    param([hashtable]$Config)

    $global:OhMyPwsh_UseNerdFonts = $Config.UseNerdFonts
    $global:OhMyPwsh_ShowFeedback = $Config.ShowFeedback
    $global:OhMyPwsh_EnableLinuxCompat = $Config.EnableLinuxCompat

    # Mock tool availability based on config
    if ($Config.Tools.Count -gt 0) {
        $installedTools = $Config.Tools.Keys | Where-Object { $Config.Tools[$_] -eq $true }
        Mock-ToolAvailability -ToolsInstalled $installedTools
    }
}
