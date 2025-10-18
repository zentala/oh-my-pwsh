BeforeAll {
    # Source dependencies
    . $PSScriptRoot/../../settings/icons.ps1
    . $PSScriptRoot/../../modules/status-output.ps1

    # Ensure Unicode mode for predictable testing
    $global:OhMyPwsh_UseNerdFonts = $false
}

Describe "Write-StatusMessage" {
    Context "When message is a simple string" {
        BeforeEach {
            Mock Write-Host {}
        }

        It "Outputs success message with green icon" {
            Write-StatusMessage -Role "success" -Message "Test message"

            Should -Invoke Write-Host -ParameterFilter {
                $Object -eq "✓" -and $ForegroundColor -eq "Green"
            }
        }

        It "Outputs warning message with yellow icon" {
            Write-StatusMessage -Role "warning" -Message "Test message"

            Should -Invoke Write-Host -ParameterFilter {
                $Object -eq "!" -and $ForegroundColor -eq "Yellow"
            }
        }

        It "Outputs error message with red icon" {
            Write-StatusMessage -Role "error" -Message "Test message"

            Should -Invoke Write-Host -ParameterFilter {
                $Object -eq "x" -and $ForegroundColor -eq "Red"
            }
        }

        It "Outputs info message with cyan icon" {
            Write-StatusMessage -Role "info" -Message "Test message"

            Should -Invoke Write-Host -ParameterFilter {
                $Object -eq "i" -and $ForegroundColor -eq "Cyan"
            }
        }

        It "Outputs message text in white" {
            Write-StatusMessage -Role "success" -Message "Test message"

            Should -Invoke Write-Host -ParameterFilter {
                $Object -eq "Test message" -and $ForegroundColor -eq "White"
            }
        }

        It "Outputs brackets in DarkGray (Unicode mode)" {
            Write-StatusMessage -Role "success" -Message "Test"

            Should -Invoke Write-Host -ParameterFilter {
                $Object -eq "[" -and $ForegroundColor -eq "DarkGray"
            }

            Should -Invoke Write-Host -ParameterFilter {
                $Object -eq "] " -and $ForegroundColor -eq "DarkGray"
            }
        }

        It "Includes indent by default" {
            Write-StatusMessage -Role "success" -Message "Test"

            Should -Invoke Write-Host -ParameterFilter {
                $Object -eq "  " -and $NoNewline -eq $true
            }
        }

        It "Skips indent when -NoIndent specified" {
            Write-StatusMessage -Role "success" -Message "Test" -NoIndent

            # In NoIndent mode, first call should NOT be "  " (2 spaces)
            Should -Not -Invoke Write-Host -ParameterFilter {
                $Object -eq "  " -and $NoNewline -eq $true
            }
        }
    }

    Context "When message is styled segments" {
        BeforeEach {
            Mock Write-Host {}
        }

        It "Outputs each segment with correct color" {
            $segments = @(
                @{Text = "install "; Color = "White"}
                @{Text = "bat"; Color = "Yellow"}
                @{Text = ": "; Color = "White"}
                @{Text = "scoop install bat"; Color = "DarkGray"}
            )

            Write-StatusMessage -Role "warning" -Message $segments

            Should -Invoke Write-Host -ParameterFilter {
                $Object -eq "install " -and $ForegroundColor -eq "White"
            }

            Should -Invoke Write-Host -ParameterFilter {
                $Object -eq "bat" -and $ForegroundColor -eq "Yellow"
            }

            Should -Invoke Write-Host -ParameterFilter {
                $Object -eq ": " -and $ForegroundColor -eq "White"
            }

            Should -Invoke Write-Host -ParameterFilter {
                $Object -eq "scoop install bat" -and $ForegroundColor -eq "DarkGray"
            }
        }

        It "Uses White as default color when Color not specified" {
            $segments = @(
                @{Text = "No color specified"}
            )

            Write-StatusMessage -Role "info" -Message $segments

            Should -Invoke Write-Host -ParameterFilter {
                $Object -eq "No color specified" -and $ForegroundColor -eq "White"
            }
        }

        It "Outputs final newline after segments" {
            $segments = @(
                @{Text = "Segment 1"; Color = "White"}
            )

            Write-StatusMessage -Role "info" -Message $segments

            # Should call Write-Host without -NoNewline at least once (the final newline)
            Should -Invoke Write-Host -ParameterFilter {
                $NoNewline -ne $true
            } -Times 1 -Exactly
        }
    }

    Context "When in Nerd Font mode" {
        BeforeAll {
            $global:OhMyPwsh_UseNerdFonts = $true
        }

        AfterAll {
            $global:OhMyPwsh_UseNerdFonts = $false
        }

        BeforeEach {
            Mock Write-Host {}
        }

        It "Outputs Nerd Font icon without brackets" {
            Write-StatusMessage -Role "success" -Message "Test"

            Should -Invoke Write-Host -ParameterFilter {
                $Object -eq "󰄵" -and $ForegroundColor -eq "Green"
            }

            # Should NOT invoke with brackets
            Should -Not -Invoke Write-Host -ParameterFilter {
                $Object -eq "[" -or $Object -eq "]"
            }
        }
    }

    Context "When message is unexpected type" {
        BeforeEach {
            Mock Write-Host {}
        }

        It "Falls back to default output" {
            Write-StatusMessage -Role "info" -Message 123

            Should -Invoke Write-Host -ParameterFilter {
                $Object -eq 123
            }
        }
    }
}
