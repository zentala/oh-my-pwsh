BeforeAll {
    # Source all dependencies for integration testing
    . $PSScriptRoot/../../settings/icons.ps1
    . $PSScriptRoot/../../modules/status-output.ps1
    . $PSScriptRoot/../../modules/logger.ps1

    # Ensure Unicode mode
    $global:OhMyPwsh_UseNerdFonts = $false
    $global:OhMyPwsh_ShowFeedback = $false
}

Describe "Logging Flow Integration" {
    Context "Complete message composition flow" {
        BeforeEach {
            Mock Write-Host {}
        }

        It "Write-InstallHint uses Write-StatusMessage which uses Get-FallbackIcon" {
            Write-InstallHint -Tool "bat" -InstallCommand "scoop install bat"

            # Should call Write-Host for icon
            Should -Invoke Write-Host -ParameterFilter {
                $Object -eq "!" -and $ForegroundColor -eq "Yellow"
            }

            # Should call Write-Host for tool name
            Should -Invoke Write-Host -ParameterFilter {
                $Object -eq "``bat``" -and $ForegroundColor -eq "Yellow"
            }

            # Should call Write-Host for install command
            Should -Invoke Write-Host -ParameterFilter {
                $Object -eq "scoop install bat" -and $ForegroundColor -eq "DarkGray"
            }
        }

        It "Write-ModuleStatus integrates with Write-ProfileStatus and Write-StatusMessage" {
            Write-ModuleStatus -Name "TestModule" -Loaded $true -Description "test"

            # Should show success icon
            Should -Invoke Write-Host -ParameterFilter {
                $Object -eq "✓" -and $ForegroundColor -eq "Green"
            }

            # Should show module name
            Should -Invoke Write-Host -ParameterFilter {
                $Object -like "*TestModule*test*"
            }
        }

        It "Write-ToolStatus with Scoop integrates with Write-InstallHint" {
            Write-ToolStatus -Name "bat" -Installed $false -ScoopPackage "bat" -Description "improved cat"

            # Should show warning icon
            Should -Invoke Write-Host -ParameterFilter {
                $Object -eq "!" -and $ForegroundColor -eq "Yellow"
            }

            # Should include description
            Should -Invoke Write-Host -ParameterFilter {
                $Object -eq "improved cat"
            }

            # Should show scoop install command
            Should -Invoke Write-Host -ParameterFilter {
                $Object -eq "scoop install bat"
            }
        }
    }

    Context "Message segment composition" {
        BeforeEach {
            Mock Write-Host {}
        }

        It "Segments flow correctly through Write-StatusMessage" {
            $segments = @(
                @{Text = "Part 1"; Color = "White"}
                @{Text = "Part 2"; Color = "Yellow"}
                @{Text = "Part 3"; Color = "DarkGray"}
            )

            Write-StatusMessage -Role "info" -Message $segments

            Should -Invoke Write-Host -ParameterFilter {
                $Object -eq "Part 1" -and $ForegroundColor -eq "White"
            }

            Should -Invoke Write-Host -ParameterFilter {
                $Object -eq "Part 2" -and $ForegroundColor -eq "Yellow"
            }

            Should -Invoke Write-Host -ParameterFilter {
                $Object -eq "Part 3" -and $ForegroundColor -eq "DarkGray"
            }
        }

        It "Write-InstallHint creates properly colored segments" {
            Write-InstallHint -Tool "eza" -Description "modern ls" -InstallCommand "scoop install eza"

            # Verify segment colors
            Should -Invoke Write-Host -ParameterFilter {
                $Object -eq "install " -and $ForegroundColor -eq "White"
            }

            Should -Invoke Write-Host -ParameterFilter {
                $Object -eq "``eza``" -and $ForegroundColor -eq "Yellow"
            }

            Should -Invoke Write-Host -ParameterFilter {
                $Object -eq " for " -and $ForegroundColor -eq "White"
            }

            Should -Invoke Write-Host -ParameterFilter {
                $Object -eq "modern ls" -and $ForegroundColor -eq "White"
            }

            Should -Invoke Write-Host -ParameterFilter {
                $Object -eq "scoop install eza" -and $ForegroundColor -eq "DarkGray"
            }
        }
    }

    Context "Icon system integration" {
        BeforeEach {
            Mock Write-Host {}
        }

        It "Different roles produce different colored icons" {
            Write-StatusMessage -Role "success" -Message "Test"
            Write-StatusMessage -Role "warning" -Message "Test"
            Write-StatusMessage -Role "error" -Message "Test"
            Write-StatusMessage -Role "info" -Message "Test"

            # Success = Green checkmark
            Should -Invoke Write-Host -ParameterFilter {
                $Object -eq "✓" -and $ForegroundColor -eq "Green"
            }

            # Warning = Yellow exclamation
            Should -Invoke Write-Host -ParameterFilter {
                $Object -eq "!" -and $ForegroundColor -eq "Yellow"
            }

            # Error = Red x
            Should -Invoke Write-Host -ParameterFilter {
                $Object -eq "x" -and $ForegroundColor -eq "Red"
            }

            # Info = Cyan i
            Should -Invoke Write-Host -ParameterFilter {
                $Object -eq "i" -and $ForegroundColor -eq "Cyan"
            }
        }

        It "Icons work consistently across all logger functions" {
            Mock Write-Host {}

            Write-ProfileStatus -Level "success" -Primary "Test1"
            Write-ModuleStatus -Name "Test2" -Loaded $true
            Write-ToolStatus -Name "Test3" -Installed $true

            # All should use green checkmark
            Should -Invoke Write-Host -ParameterFilter {
                $Object -eq "✓" -and $ForegroundColor -eq "Green"
            } -Times 3 -Exactly
        }
    }

    Context "Error-free operation" {
        It "All logging functions work without errors" {
            Mock Write-Host {}

            { Write-ProfileStatus -Level "success" -Primary "Test" } | Should -Not -Throw
            { Write-ProfileStatus -Level "warning" -Primary "Test" } | Should -Not -Throw
            { Write-ProfileStatus -Level "error" -Primary "Test" } | Should -Not -Throw
            { Write-ProfileStatus -Level "info" -Primary "Test" } | Should -Not -Throw

            { Write-ModuleStatus -Name "Test" -Loaded $true } | Should -Not -Throw
            { Write-ModuleStatus -Name "Test" -Loaded $false } | Should -Not -Throw

            { Write-ToolStatus -Name "Test" -Installed $true } | Should -Not -Throw
            { Write-ToolStatus -Name "Test" -Installed $false } | Should -Not -Throw

            { Write-InstallHint -Tool "test" -InstallCommand "test" } | Should -Not -Throw
        }
    }
}

Describe "Fallback Integration" {
    BeforeEach {
        Mock Write-Host {}
    }

    Context "Tool detection with Write-ToolStatus" {
        It "Installed tool shows success" {
            Write-ToolStatus -Name "bat" -Installed $true

            Should -Invoke Write-Host -ParameterFilter {
                $Object -eq "✓" -and $ForegroundColor -eq "Green"
            }
        }

        It "Missing tool with scoop shows warning with install hint" {
            Write-ToolStatus -Name "bat" -Installed $false -ScoopPackage "bat"

            Should -Invoke Write-Host -ParameterFilter {
                $Object -eq "!" -and $ForegroundColor -eq "Yellow"
            }

            Should -Invoke Write-Host -ParameterFilter {
                $Object -eq "scoop install bat"
            }
        }
    }

    Context "Module loading feedback" {
        It "Loaded module shows success" {
            Write-ModuleStatus -Name "Pester" -Loaded $true

            Should -Invoke Write-Host -ParameterFilter {
                $Object -eq "✓"
            }
        }

        It "Missing module shows warning" {
            Write-ModuleStatus -Name "MissingModule" -Loaded $false -InstallCommand "Install-Module MissingModule"

            Should -Invoke Write-Host -ParameterFilter {
                $Object -eq "!"
            }

            Should -Invoke Write-Host -ParameterFilter {
                $Object -like "*Install-Module MissingModule*"
            }
        }
    }
}
