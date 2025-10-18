BeforeAll {
    # Source dependencies
    . $PSScriptRoot/../../settings/icons.ps1
    . $PSScriptRoot/../../modules/status-output.ps1
    . $PSScriptRoot/../../modules/logger.ps1

    # Ensure Unicode mode for predictable testing
    $global:OhMyPwsh_UseNerdFonts = $false
}

Describe "Write-ProfileStatus" {
    BeforeEach {
        Mock Write-Host {}
    }

    Context "When level is success" {
        It "Calls Write-StatusMessage with success role" {
            Mock Write-StatusMessage {}

            Write-ProfileStatus -Level "success" -Primary "Test"

            Should -Invoke Write-StatusMessage -ParameterFilter {
                $Role -eq "success"
            }
        }

        It "Passes primary message correctly" {
            Mock Write-StatusMessage {}

            Write-ProfileStatus -Level "success" -Primary "Module loaded"

            Should -Invoke Write-StatusMessage -ParameterFilter {
                $Message -eq "Module loaded"
            }
        }
    }

    Context "When level is warning" {
        It "Calls Write-StatusMessage with warning role" {
            Mock Write-StatusMessage {}

            Write-ProfileStatus -Level "warning" -Primary "Test"

            Should -Invoke Write-StatusMessage -ParameterFilter {
                $Role -eq "warning"
            }
        }
    }

    Context "When level is error" {
        It "Calls Write-StatusMessage with error role" {
            Mock Write-StatusMessage {}

            Write-ProfileStatus -Level "error" -Primary "Test"

            Should -Invoke Write-StatusMessage -ParameterFilter {
                $Role -eq "error"
            }
        }
    }

    Context "When level is info" {
        It "Calls Write-StatusMessage with info role" {
            Mock Write-StatusMessage {}

            Write-ProfileStatus -Level "info" -Primary "Test"

            Should -Invoke Write-StatusMessage -ParameterFilter {
                $Role -eq "info"
            }
        }
    }

    Context "When secondary message is provided" {
        It "Appends secondary message with brackets" {
            Mock Write-StatusMessage {}

            Write-ProfileStatus -Level "info" -Primary "Primary" -Secondary "Secondary"

            Should -Invoke Write-StatusMessage -ParameterFilter {
                $Message -like "*Primary*Secondary*"
            }
        }
    }

    Context "When NoIndent is specified" {
        It "Passes NoIndent flag to Write-StatusMessage" {
            Mock Write-StatusMessage {}

            Write-ProfileStatus -Level "success" -Primary "Test" -NoIndent

            Should -Invoke Write-StatusMessage -ParameterFilter {
                $NoIndent -eq $true
            }
        }
    }

    Context "When NoIndent is not specified" {
        It "Does not pass NoIndent flag" {
            Mock Write-StatusMessage {}

            Write-ProfileStatus -Level "success" -Primary "Test"

            Should -Invoke Write-StatusMessage -ParameterFilter {
                $NoIndent -ne $true
            }
        }
    }
}

Describe "Write-InstallHint" {
    BeforeEach {
        Mock Write-Host {}
    }

    Context "When tool and install command are provided" {
        It "Calls Write-StatusMessage with warning role" {
            Mock Write-StatusMessage {}

            Write-InstallHint -Tool "bat" -InstallCommand "scoop install bat"

            Should -Invoke Write-StatusMessage -ParameterFilter {
                $Role -eq "warning"
            }
        }

        It "Includes tool name in segments" {
            Mock Write-StatusMessage {}

            Write-InstallHint -Tool "bat" -InstallCommand "scoop install bat"

            Should -Invoke Write-StatusMessage -ParameterFilter {
                $Message.Text -contains "``bat``"
            }
        }

        It "Includes install command in segments" {
            Mock Write-StatusMessage {}

            Write-InstallHint -Tool "bat" -InstallCommand "scoop install bat"

            Should -Invoke Write-StatusMessage -ParameterFilter {
                $Message.Text -contains "scoop install bat"
            }
        }

        It "Colors tool name in Yellow" {
            Mock Write-StatusMessage {}

            Write-InstallHint -Tool "bat" -InstallCommand "scoop install bat"

            Should -Invoke Write-StatusMessage -ParameterFilter {
                ($Message | Where-Object { $_.Text -eq "``bat``" }).Color -eq "Yellow"
            }
        }

        It "Colors install command in DarkGray" {
            Mock Write-StatusMessage {}

            Write-InstallHint -Tool "bat" -InstallCommand "scoop install bat"

            Should -Invoke Write-StatusMessage -ParameterFilter {
                ($Message | Where-Object { $_.Text -eq "scoop install bat" }).Color -eq "DarkGray"
            }
        }
    }

    Context "When description is provided" {
        It "Includes description in segments" {
            Mock Write-StatusMessage {}

            Write-InstallHint -Tool "bat" -Description "improved cat" -InstallCommand "scoop install bat"

            Should -Invoke Write-StatusMessage -ParameterFilter {
                $Message.Text -contains "improved cat"
            }
        }

        It "Includes 'for' before description" {
            Mock Write-StatusMessage {}

            Write-InstallHint -Tool "bat" -Description "improved cat" -InstallCommand "scoop install bat"

            Should -Invoke Write-StatusMessage -ParameterFilter {
                $Message.Text -contains " for "
            }
        }
    }

    Context "When description is not provided" {
        It "Does not include 'for' text" {
            Mock Write-StatusMessage {}

            Write-InstallHint -Tool "bat" -InstallCommand "scoop install bat"

            Should -Invoke Write-StatusMessage -ParameterFilter {
                $Message.Text -notcontains " for "
            }
        }
    }
}

Describe "Write-ModuleStatus" {
    BeforeEach {
        Mock Write-Host {}
        Mock Write-ProfileStatus {}
    }

    Context "When module is loaded" {
        It "Calls Write-ProfileStatus with success level" {
            Write-ModuleStatus -Name "TestModule" -Loaded $true

            Should -Invoke Write-ProfileStatus -ParameterFilter {
                $Level -eq "success"
            }
        }

        It "Uses module name as primary message" {
            Write-ModuleStatus -Name "TestModule" -Loaded $true

            Should -Invoke Write-ProfileStatus -ParameterFilter {
                $Primary -eq "TestModule"
            }
        }

        It "Includes description when provided" {
            Write-ModuleStatus -Name "TestModule" -Loaded $true -Description "Test Description"

            Should -Invoke Write-ProfileStatus -ParameterFilter {
                $Primary -like "*Test Description*"
            }
        }
    }

    Context "When module is not loaded" {
        It "Calls Write-ProfileStatus with warning level" {
            Write-ModuleStatus -Name "TestModule" -Loaded $false

            Should -Invoke Write-ProfileStatus -ParameterFilter {
                $Level -eq "warning"
            }
        }

        It "Uses module name as primary message" {
            Write-ModuleStatus -Name "TestModule" -Loaded $false

            Should -Invoke Write-ProfileStatus -ParameterFilter {
                $Primary -eq "TestModule"
            }
        }

        It "Passes install command as secondary when provided" {
            Write-ModuleStatus -Name "TestModule" -Loaded $false -InstallCommand "Install-Module TestModule"

            Should -Invoke Write-ProfileStatus -ParameterFilter {
                $Secondary -eq "Install-Module TestModule"
            }
        }
    }
}

Describe "Write-ToolStatus" {
    BeforeEach {
        Mock Write-Host {}
        Mock Write-ProfileStatus {}
        Mock Write-InstallHint {}
    }

    Context "When tool is installed" {
        It "Calls Write-ProfileStatus with success level" {
            Write-ToolStatus -Name "bat" -Installed $true

            Should -Invoke Write-ProfileStatus -ParameterFilter {
                $Level -eq "success"
            }
        }

        It "Uses tool name as primary message" {
            Write-ToolStatus -Name "bat" -Installed $true

            Should -Invoke Write-ProfileStatus -ParameterFilter {
                $Primary -eq "bat"
            }
        }

        It "Includes description in display name when provided" {
            Write-ToolStatus -Name "bat" -Installed $true -Description "improved cat"

            Should -Invoke Write-ProfileStatus -ParameterFilter {
                $Primary -like "*improved cat*"
            }
        }
    }

    Context "When tool is not installed and scoop package provided" {
        It "Calls Write-InstallHint" {
            Write-ToolStatus -Name "bat" -Installed $false -ScoopPackage "bat"

            Should -Invoke Write-InstallHint
        }

        It "Passes tool name to Write-InstallHint" {
            Write-ToolStatus -Name "bat" -Installed $false -ScoopPackage "bat"

            Should -Invoke Write-InstallHint -ParameterFilter {
                $Tool -eq "bat"
            }
        }

        It "Passes description to Write-InstallHint when provided" {
            Write-ToolStatus -Name "bat" -Installed $false -ScoopPackage "bat" -Description "improved cat"

            Should -Invoke Write-InstallHint -ParameterFilter {
                $Description -eq "improved cat"
            }
        }

        It "Generates scoop install command" {
            Write-ToolStatus -Name "bat" -Installed $false -ScoopPackage "bat"

            Should -Invoke Write-InstallHint -ParameterFilter {
                $InstallCommand -eq "scoop install bat"
            }
        }
    }

    Context "When tool is not installed and no scoop package" {
        It "Does not call Write-ProfileStatus" {
            Write-ToolStatus -Name "CustomTool" -Installed $false

            Should -Not -Invoke Write-ProfileStatus
        }

        It "Does not call Write-InstallHint" {
            Write-ToolStatus -Name "CustomTool" -Installed $false

            Should -Not -Invoke Write-InstallHint
        }

        It "Does nothing silently (no output)" {
            { Write-ToolStatus -Name "CustomTool" -Installed $false } | Should -Not -Throw
        }
    }
}
