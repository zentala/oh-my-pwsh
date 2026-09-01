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
            # Fonts may legitimately be empty on a clean developer/CI host.
            $result.PSObject.Properties.Name | Should -Contain 'Fonts'
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
    # Force Windows-Terminal detection without depending on the real env, and never
    # let the function fall back to the real settings path - every test injects
    # -SettingsPath pointing at a temp file (see task #014).
    BeforeAll {
        $script:savedWtSession = $env:WT_SESSION
        $env:WT_SESSION = "test-session-id"
        Mock Get-TerminalType { return "WindowsTerminal" }
    }

    AfterAll {
        $env:WT_SESSION = $script:savedWtSession
    }

    Context "When not running in Windows Terminal" {
        BeforeAll {
            Mock Get-TerminalType { return "LegacyConsole" }
        }

        It "Returns false and shows warning" {
            $result = Set-WindowsTerminalFont -FontName "Test Font"

            $result | Should -Be $false
        }
    }

    Context "When settings file does not exist" {
        It "Returns false and shows error" {
            $missing = Join-Path ([System.IO.Path]::GetTempPath()) "nerdfont-missing-$([System.IO.Path]::GetRandomFileName()).json"

            $result = Set-WindowsTerminalFont -FontName "Test Font" -Silent -SettingsPath $missing

            $result | Should -Be $false
        }
    }

    Context "When successfully setting font" {
        BeforeEach {
            # Seed a realistic settings.json that already has a font.face - the common
            # real-world update path.
            $script:tempSettings = [System.IO.Path]::GetTempFileName()
            @{
                profiles = @{
                    defaults = @{ font = @{ face = "Consolas" } }
                    list = @()
                }
            } | ConvertTo-Json -Depth 10 | Out-File $script:tempSettings -Encoding UTF8
        }

        AfterEach {
            Remove-Item $script:tempSettings -Force -ErrorAction SilentlyContinue
            Remove-Item "$script:tempSettings.backup-*" -Force -ErrorAction SilentlyContinue
        }

        It "Returns true on success" {
            $result = Set-WindowsTerminalFont -FontName "CaskaydiaCove Nerd Font" -Silent -SettingsPath $script:tempSettings

            $result | Should -Be $true
        }

        It "Writes the font face into the settings file" {
            Set-WindowsTerminalFont -FontName "CaskaydiaCove Nerd Font" -Silent -SettingsPath $script:tempSettings | Out-Null

            $written = Get-Content $script:tempSettings -Raw | ConvertFrom-Json
            $written.profiles.defaults.font.face | Should -Be "CaskaydiaCove Nerd Font"
        }

        It "Creates a backup next to the settings file before modifying" {
            Set-WindowsTerminalFont -FontName "Test Font" -Silent -SettingsPath $script:tempSettings | Out-Null

            @(Get-ChildItem "$script:tempSettings.backup-*").Count | Should -BeGreaterThan 0
        }

        It "Does not touch the real Windows Terminal settings path" {
            $realPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
            $before = @(Get-ChildItem "$realPath.backup-*" -ErrorAction SilentlyContinue).Count

            Set-WindowsTerminalFont -FontName "Test Font" -Silent -SettingsPath $script:tempSettings | Out-Null

            $after = @(Get-ChildItem "$realPath.backup-*" -ErrorAction SilentlyContinue).Count
            $after | Should -Be $before
        }
    }

    Context "Error handling and rollback" {
        BeforeEach {
            # Seed invalid JSON so ConvertFrom-Json throws inside the function - no mocks.
            $script:tempSettings = [System.IO.Path]::GetTempFileName()
            "{ this is not valid json" | Out-File $script:tempSettings -Encoding UTF8
        }

        AfterEach {
            Remove-Item $script:tempSettings -Force -ErrorAction SilentlyContinue
            Remove-Item "$script:tempSettings.backup-*" -Force -ErrorAction SilentlyContinue
        }

        It "Returns false on error" {
            $result = Set-WindowsTerminalFont -FontName "Test Font" -Silent -SettingsPath $script:tempSettings

            $result | Should -Be $false
        }

        It "Restores the original settings from backup on error" {
            $original = Get-Content $script:tempSettings -Raw

            Set-WindowsTerminalFont -FontName "Test Font" -Silent -SettingsPath $script:tempSettings | Out-Null

            Get-Content $script:tempSettings -Raw | Should -Be $original
        }
    }
}

Describe "Install-NerdFonts Integration" {
    Context "When scoop is not available" {
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
