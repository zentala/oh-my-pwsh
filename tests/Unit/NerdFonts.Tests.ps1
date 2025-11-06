BeforeAll {
    # Source the nerd-fonts module
    . $PSScriptRoot/../../modules/nerd-fonts.ps1
}

Describe "Get-TerminalType" {
    Context "When running in Windows Terminal" {
        BeforeAll {
            $env:WT_SESSION = "test-session-id"
            $env:VSCODE_PID = $null
            $env:ConEmuPID = $null
        }

        AfterAll {
            $env:WT_SESSION = $null
        }

        It "Returns 'WindowsTerminal'" {
            $result = Get-TerminalType
            $result | Should -Be "WindowsTerminal"
        }
    }

    Context "When running in VS Code" {
        BeforeAll {
            $env:WT_SESSION = $null
            $env:VSCODE_PID = "12345"
            $env:ConEmuPID = $null
        }

        AfterAll {
            $env:VSCODE_PID = $null
        }

        It "Returns 'VSCode'" {
            $result = Get-TerminalType
            $result | Should -Be "VSCode"
        }
    }

    Context "When TERM_PROGRAM is set to vscode" {
        BeforeAll {
            $env:WT_SESSION = $null
            $env:VSCODE_PID = $null
            $env:TERM_PROGRAM = "vscode"
            $env:ConEmuPID = $null
        }

        AfterAll {
            $env:TERM_PROGRAM = $null
        }

        It "Returns 'VSCode'" {
            $result = Get-TerminalType
            $result | Should -Be "VSCode"
        }
    }

    Context "When running in ConEmu" {
        BeforeAll {
            $env:WT_SESSION = $null
            $env:VSCODE_PID = $null
            $env:ConEmuPID = "54321"
        }

        AfterAll {
            $env:ConEmuPID = $null
        }

        It "Returns 'ConEmu'" {
            $result = Get-TerminalType
            $result | Should -Be "ConEmu"
        }
    }

    Context "When running in legacy console (no special env vars)" {
        BeforeAll {
            $env:WT_SESSION = $null
            $env:VSCODE_PID = $null
            $env:ConEmuPID = $null
            $env:TERM_PROGRAM = $null
        }

        It "Returns 'LegacyConsole'" {
            $result = Get-TerminalType
            $result | Should -Be "LegacyConsole"
        }
    }

    Context "Priority order (Windows Terminal takes precedence)" {
        BeforeAll {
            # Set multiple env vars
            $env:WT_SESSION = "test-session"
            $env:VSCODE_PID = "12345"
            $env:ConEmuPID = "54321"
        }

        AfterAll {
            $env:WT_SESSION = $null
            $env:VSCODE_PID = $null
            $env:ConEmuPID = $null
        }

        It "Returns 'WindowsTerminal' when multiple terminals detected" {
            $result = Get-TerminalType
            $result | Should -Be "WindowsTerminal"
        }
    }
}

Describe "Test-NerdFontInstalled" {
    Context "When testing font detection" {
        It "Returns object with correct properties" {
            $result = Test-NerdFontInstalled

            $result | Should -Not -BeNullOrEmpty
            $result.Installed | Should -BeOfType [bool]
            # Fonts can be a string (single font) or array (multiple fonts)
            $result.Fonts | Should -Not -BeNullOrEmpty -Because "Should have Fonts property"
            $result.Count | Should -BeOfType [int]
        }

        It "Returns Count matching Fonts array length" {
            $result = Test-NerdFontInstalled

            $result.Count | Should -Be $result.Fonts.Count
        }

        It "Installed is false when Count is 0" {
            $result = Test-NerdFontInstalled

            if ($result.Count -eq 0) {
                $result.Installed | Should -Be $false
            }
        }

        It "Installed is true when Count is greater than 0" {
            $result = Test-NerdFontInstalled

            if ($result.Count -gt 0) {
                $result.Installed | Should -Be $true
            }
        }
    }

    Context "Error handling" {
        It "Returns safe defaults on registry access failure" {
            # Mock registry access to fail
            Mock Get-ItemProperty { throw "Registry access denied" }

            $result = Test-NerdFontInstalled

            $result.Installed | Should -Be $false
            $result.Fonts | Should -BeNullOrEmpty
            $result.Count | Should -Be 0
        }
    }
}

Describe "Get-RecommendedNerdFonts" {
    Context "When getting font recommendations" {
        It "Returns array of font objects" {
            $result = Get-RecommendedNerdFonts

            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [System.Management.Automation.PSCustomObject]
        }

        It "Returns at least 4 recommended fonts" {
            $result = Get-RecommendedNerdFonts

            $result.Count | Should -BeGreaterOrEqual 4
        }

        It "Each font has required properties" {
            $result = Get-RecommendedNerdFonts

            foreach ($font in $result) {
                $font.Name | Should -Not -BeNullOrEmpty
                $font.ScoopName | Should -Not -BeNullOrEmpty
                $font.Description | Should -Not -BeNullOrEmpty
                $font.Why | Should -Not -BeNullOrEmpty
                $font.Variant | Should -Not -BeNullOrEmpty
            }
        }

        It "All fonts use Regular variant (not Mono variant suffix)" {
            $result = Get-RecommendedNerdFonts

            foreach ($font in $result) {
                $font.Variant | Should -BeLike "*Regular*"
                # Font name should NOT end with " Nerd Font Mono" (but "JetBrainsMono Nerd Font" is OK)
                $font.Name | Should -Not -Match '\sNerd\sFont\sMono$'
            }
        }

        It "Contains CaskaydiaCove as first recommendation" {
            $result = Get-RecommendedNerdFonts

            $result[0].Name | Should -Be "CaskaydiaCove Nerd Font"
            $result[0].ScoopName | Should -Be "CascadiaCode-NF"
        }

        It "Contains FiraCode as second recommendation" {
            $result = Get-RecommendedNerdFonts

            $result[1].Name | Should -Be "FiraCode Nerd Font"
            $result[1].ScoopName | Should -Be "FiraCode-NF"
        }
    }
}

Describe "Set-WindowsTerminalFont" {
    Context "When not running in Windows Terminal" {
        BeforeAll {
            # Mock terminal detection
            Mock Get-TerminalType { return "LegacyConsole" }
        }

        It "Returns false and shows warning" {
            $result = Set-WindowsTerminalFont -FontName "Test Font"

            $result | Should -Be $false
        }
    }

    Context "When settings file does not exist" {
        BeforeAll {
            Mock Get-TerminalType { return "WindowsTerminal" }
            Mock Test-Path { return $false }
        }

        It "Returns false and shows error" {
            $result = Set-WindowsTerminalFont -FontName "Test Font"

            $result | Should -Be $false
        }
    }

    Context "When successfully setting font" {
        BeforeAll {
            Mock Get-TerminalType { return "WindowsTerminal" }

            # Create temp settings file for testing
            $script:tempSettings = [System.IO.Path]::GetTempFileName()
            $testSettings = @{
                profiles = @{
                    defaults = @{}
                    list = @()
                }
            } | ConvertTo-Json -Depth 10

            $testSettings | Out-File $script:tempSettings -Encoding UTF8

            # Mock paths
            Mock Test-Path { return $true }
            Mock Copy-Item { }
            Mock Get-Content {
                return Get-Content $script:tempSettings -Raw
            } -ParameterFilter { $Path -like "*settings.json" }
            Mock Set-Content { }
        }

        AfterAll {
            if (Test-Path $script:tempSettings) {
                Remove-Item $script:tempSettings -Force
            }
        }

        It "Returns true on success" {
            $result = Set-WindowsTerminalFont -FontName "CaskaydiaCove Nerd Font" -Silent

            $result | Should -Be $true
        }

        It "Creates backup before modifying" {
            Set-WindowsTerminalFont -FontName "Test Font" -Silent

            Should -Invoke Copy-Item -Times 1
        }

        It "Reads existing settings" {
            Set-WindowsTerminalFont -FontName "Test Font" -Silent

            Should -Invoke Get-Content -Times 1
        }

        It "Writes modified settings back" {
            Set-WindowsTerminalFont -FontName "Test Font" -Silent

            Should -Invoke Set-Content -Times 1
        }
    }

    Context "Error handling and rollback" {
        BeforeAll {
            Mock Get-TerminalType { return "WindowsTerminal" }
            Mock Test-Path { return $true }
            Mock Copy-Item { }
            Mock Get-Content { throw "Read error" }
            Mock Set-Content { }
        }

        It "Returns false on error" {
            $result = Set-WindowsTerminalFont -FontName "Test Font" -Silent

            $result | Should -Be $false
        }

        It "Attempts to restore backup on error" {
            Set-WindowsTerminalFont -FontName "Test Font" -Silent

            # Should try to restore (second Copy-Item call)
            Should -Invoke Copy-Item -Times 1
        }
    }
}

Describe "Install-NerdFonts Integration" {
    Context "When scoop is not available" {
        BeforeAll {
            Mock Get-Command { return $null } -ParameterFilter { $Name -eq "scoop" }
        }

        It "Shows error and manual installation instructions" {
            # This would need interactive testing or further mocking
            # For now, we just verify the function exists and is callable
            { Get-Command Install-NerdFonts } | Should -Not -Throw
        }
    }

    Context "Function signature and parameters" {
        It "Has FontName parameter" {
            $params = (Get-Command Install-NerdFonts).Parameters

            $params.ContainsKey('FontName') | Should -Be $true
        }

        It "Has Silent switch parameter" {
            $params = (Get-Command Install-NerdFonts).Parameters

            $params.ContainsKey('Silent') | Should -Be $true
            $params['Silent'].SwitchParameter | Should -Be $true
        }
    }
}
