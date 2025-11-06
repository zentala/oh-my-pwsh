BeforeAll {
    $script:InstallScriptPath = "$PSScriptRoot/../../scripts/Install-OhMyPwsh.ps1"
}

Describe "Install-OhMyPwsh.ps1 Script" {
    Context "Script file validation" {
        It "Install script exists" {
            Test-Path $script:InstallScriptPath | Should -Be $true
        }

        It "Script is valid PowerShell" {
            { $null = [System.Management.Automation.PSParser]::Tokenize(
                (Get-Content $script:InstallScriptPath -Raw),
                [ref]$null
            ) } | Should -Not -Throw
        }

        It "Script has expected parameters" {
            $scriptContent = Get-Content $script:InstallScriptPath -Raw

            $scriptContent | Should -Match 'param\('
            $scriptContent | Should -Match '\[switch\]\$SkipDependencies'
            $scriptContent | Should -Match '\[switch\]\$SkipProfile'
            $scriptContent | Should -Match '\[switch\]\$SkipScoop'
            $scriptContent | Should -Match '\[switch\]\$SkipEnhancedTools'
            $scriptContent | Should -Match '\[switch\]\$SkipNerdFonts'
        }

        It "Maintains backward compatibility flags" {
            $scriptContent = Get-Content $script:InstallScriptPath -Raw

            $scriptContent | Should -Match '\[switch\]\$InstallEnhancedTools'
            $scriptContent | Should -Match '\[switch\]\$InstallNerdFonts'
        }
    }

    Context "Installation logic flags" {
        It "Default behavior installs Scoop, Enhanced Tools, and Nerd Fonts" {
            $scriptContent = Get-Content $script:InstallScriptPath -Raw

            # Check that default logic is correct
            $scriptContent | Should -Match '\$ShouldInstallScoop\s*=\s*-not\s+\$SkipScoop'
            $scriptContent | Should -Match '\$ShouldInstallEnhancedTools\s*=\s*\$InstallEnhancedTools\s+-or\s+\(-not\s+\$SkipEnhancedTools\)'
            $scriptContent | Should -Match '\$ShouldInstallNerdFonts\s*=\s*\$InstallNerdFonts\s+-or\s+\(-not\s+\$SkipNerdFonts\)'
        }

        It "Has Scoop installation step" {
            $scriptContent = Get-Content $script:InstallScriptPath -Raw

            $scriptContent | Should -Match 'Step 1\.5.*Scoop'
            $scriptContent | Should -Match 'Invoke-RestMethod get\.scoop\.sh'
        }

        It "Checks for Scoop before installing enhanced tools" {
            $scriptContent = Get-Content $script:InstallScriptPath -Raw

            # Enhanced tools section should check for scoop
            $scriptContent | Should -Match 'if.*\$ShouldInstallEnhancedTools'
            $scriptContent | Should -Match 'Get-Command scoop.*-ErrorAction SilentlyContinue'
        }

        It "Checks for Scoop before installing Nerd Fonts" {
            $scriptContent = Get-Content $script:InstallScriptPath -Raw

            # Nerd Fonts section should check for scoop
            $scriptContent | Should -Match 'if.*\$ShouldInstallNerdFonts'
        }
    }

    Context "Enhanced Tools installation" {
        It "Installs expected tools list" {
            $scriptContent = Get-Content $script:InstallScriptPath -Raw

            # Should have the tools array
            $scriptContent | Should -Match 'bat.*eza.*ripgrep.*fd.*delta'
        }

        It "Checks if tools are already installed before installing" {
            $scriptContent = Get-Content $script:InstallScriptPath -Raw

            # Should check before installing
            $scriptContent | Should -Match 'Get-Command \$tool -ErrorAction SilentlyContinue'
        }
    }

    Context "Nerd Fonts installation" {
        It "Loads nerd-fonts module" {
            $scriptContent = Get-Content $script:InstallScriptPath -Raw

            $scriptContent | Should -Match 'nerd-fonts\.ps1'
            $scriptContent | Should -Match 'Test-NerdFontInstalled'
        }

        It "Calls Install-NerdFonts with -Silent flag" {
            $scriptContent = Get-Content $script:InstallScriptPath -Raw

            $scriptContent | Should -Match 'Install-NerdFonts\s+-Silent'
        }
    }

    Context "Backup and safety" {
        It "Creates backup of existing profile" {
            $scriptContent = Get-Content $script:InstallScriptPath -Raw

            $scriptContent | Should -Match 'backup'
            $scriptContent | Should -Match 'Copy-Item.*\$PROFILE'
        }

        It "Creates config from example if missing" {
            $scriptContent = Get-Content $script:InstallScriptPath -Raw

            $scriptContent | Should -Match 'config\.example\.ps1'
            $scriptContent | Should -Match 'config\.ps1'
        }
    }

    Context "oh-my-stats integration" {
        It "Clones oh-my-stats to sibling directory" {
            $scriptContent = Get-Content $script:InstallScriptPath -Raw

            $scriptContent | Should -Match 'oh-my-stats'
            $scriptContent | Should -Match 'git clone'
            $scriptContent | Should -Match 'Split-Path -Parent'
        }

        It "Supports both relative and absolute paths" {
            $scriptContent = Get-Content $script:InstallScriptPath -Raw

            # Should use parent directory, not hardcoded path
            $scriptContent | Should -Match '\$ParentDir.*=.*Split-Path -Parent'
        }
    }

    Context "User feedback and instructions" {
        It "Shows summary at the end" {
            $scriptContent = Get-Content $script:InstallScriptPath -Raw

            $scriptContent | Should -Match 'Installation Complete'
            $scriptContent | Should -Match 'Next Steps'
        }

        It "Warns about terminal restart requirement" {
            $scriptContent = Get-Content $script:InstallScriptPath -Raw

            $scriptContent | Should -Match 'RESTART.*terminal'
        }

        It "Provides instructions for skipped components" {
            $scriptContent = Get-Content $script:InstallScriptPath -Raw

            # Should show help if components were skipped
            $scriptContent | Should -Match '-not.*\$ShouldInstall'
        }
    }

    Context "Error handling" {
        It "Uses try-catch for critical operations" {
            $scriptContent = Get-Content $script:InstallScriptPath -Raw

            $scriptContent | Should -Match 'try\s*\{'
            $scriptContent | Should -Match 'catch\s*\{'
        }

        It "Provides manual installation instructions on failure" {
            $scriptContent = Get-Content $script:InstallScriptPath -Raw

            $scriptContent | Should -Match 'manually'
            $scriptContent | Should -Match 'install it manually'
        }

        It "Uses -ErrorAction SilentlyContinue for optional checks" {
            $scriptContent = Get-Content $script:InstallScriptPath -Raw

            $scriptContent | Should -Match '-ErrorAction SilentlyContinue'
        }
    }
}

Describe "Install-OhMyPwsh.ps1 Parameter Logic" {
    Context "Flag priority and defaults" {
        BeforeAll {
            # Extract the logic block from the script
            $scriptContent = Get-Content "$PSScriptRoot/../../scripts/Install-OhMyPwsh.ps1" -Raw

            # Create a test function that mimics the script logic
            $testLogic = @'
function Test-InstallLogic {
    param(
        [switch]$SkipScoop,
        [switch]$SkipEnhancedTools,
        [switch]$SkipNerdFonts,
        [switch]$InstallEnhancedTools,
        [switch]$InstallNerdFonts
    )

    $ShouldInstallScoop = -not $SkipScoop
    $ShouldInstallEnhancedTools = $InstallEnhancedTools -or (-not $SkipEnhancedTools)
    $ShouldInstallNerdFonts = $InstallNerdFonts -or (-not $SkipNerdFonts)

    return @{
        Scoop = $ShouldInstallScoop
        EnhancedTools = $ShouldInstallEnhancedTools
        NerdFonts = $ShouldInstallNerdFonts
    }
}
'@
            Invoke-Expression $testLogic
        }

        It "Default (no flags): Installs everything" {
            $result = Test-InstallLogic

            $result.Scoop | Should -Be $true
            $result.EnhancedTools | Should -Be $true
            $result.NerdFonts | Should -Be $true
        }

        It "-SkipScoop: Skips only Scoop" {
            $result = Test-InstallLogic -SkipScoop

            $result.Scoop | Should -Be $false
            $result.EnhancedTools | Should -Be $true
            $result.NerdFonts | Should -Be $true
        }

        It "-SkipEnhancedTools: Skips only Enhanced Tools" {
            $result = Test-InstallLogic -SkipEnhancedTools

            $result.Scoop | Should -Be $true
            $result.EnhancedTools | Should -Be $false
            $result.NerdFonts | Should -Be $true
        }

        It "-SkipNerdFonts: Skips only Nerd Fonts" {
            $result = Test-InstallLogic -SkipNerdFonts

            $result.Scoop | Should -Be $true
            $result.EnhancedTools | Should -Be $true
            $result.NerdFonts | Should -Be $false
        }

        It "Legacy -InstallEnhancedTools overrides -SkipEnhancedTools" {
            $result = Test-InstallLogic -SkipEnhancedTools -InstallEnhancedTools

            $result.EnhancedTools | Should -Be $true
        }

        It "Legacy -InstallNerdFonts overrides -SkipNerdFonts" {
            $result = Test-InstallLogic -SkipNerdFonts -InstallNerdFonts

            $result.NerdFonts | Should -Be $true
        }

        It "All Skip flags: Skips everything optional" {
            $result = Test-InstallLogic -SkipScoop -SkipEnhancedTools -SkipNerdFonts

            $result.Scoop | Should -Be $false
            $result.EnhancedTools | Should -Be $false
            $result.NerdFonts | Should -Be $false
        }
    }
}
