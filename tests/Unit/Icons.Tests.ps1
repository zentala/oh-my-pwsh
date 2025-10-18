BeforeAll {
    # Source the icon system
    . $PSScriptRoot/../../settings/icons.ps1
}

Describe "Get-FallbackIcon" {
    Context "When Nerd Fonts are DISABLED (default)" {
        BeforeAll {
            $global:OhMyPwsh_UseNerdFonts = $false
        }

        It "Returns Unicode checkmark for success role" {
            $result = Get-FallbackIcon -Role "success"
            $result | Should -Be "✓"
        }

        It "Returns Unicode exclamation for warning role" {
            $result = Get-FallbackIcon -Role "warning"
            $result | Should -Be "!"
        }

        It "Returns Unicode x for error role" {
            $result = Get-FallbackIcon -Role "error"
            $result | Should -Be "x"
        }

        It "Returns Unicode i for info role" {
            $result = Get-FallbackIcon -Role "info"
            $result | Should -Be "i"
        }

        It "Returns Unicode symbol for tip role" {
            $result = Get-FallbackIcon -Role "tip"
            $result | Should -Be "※"
        }

        It "Returns Unicode question mark for question role" {
            $result = Get-FallbackIcon -Role "question"
            $result | Should -Be "?"
        }

        It "Returns status badge with brackets for Unicode mode" {
            $result = Get-FallbackIcon -Role "success" -AsStatusBadge
            $result | Should -Be "[✓] "
        }

        It "Status badge includes trailing space" {
            $result = Get-FallbackIcon -Role "success" -AsStatusBadge
            $result | Should -Match '\s$'
        }
    }

    Context "When Nerd Fonts are ENABLED" {
        BeforeAll {
            $global:OhMyPwsh_UseNerdFonts = $true
        }

        AfterAll {
            $global:OhMyPwsh_UseNerdFonts = $false
        }

        It "Returns Nerd Font icon for success role" {
            $result = Get-FallbackIcon -Role "success"
            $result | Should -Be "󰄵"
        }

        It "Returns Nerd Font icon for warning role" {
            $result = Get-FallbackIcon -Role "warning"
            $result | Should -Be "󰗖"
        }

        It "Returns status badge without brackets for Nerd Font mode" {
            $result = Get-FallbackIcon -Role "success" -AsStatusBadge
            $result | Should -Be "󰄵 "
            $result | Should -Not -Match '\['
        }
    }

    Context "When role is unknown" {
        It "ValidateSet prevents invalid roles" {
            # ValidateSet attribute should prevent invalid roles at parameter binding
            { Get-FallbackIcon -Role "unknown" } | Should -Throw
        }
    }

    Context "When custom icons are defined" {
        BeforeAll {
            $global:OhMyPwsh_CustomIcons = @{
                success = "✅"
            }
        }

        AfterAll {
            $global:OhMyPwsh_CustomIcons = $null
        }

        It "Uses custom icon when defined" {
            $result = Get-FallbackIcon -Role "success"
            $result | Should -Be "✅"
        }
    }
}

Describe "Get-IconColor" {
    It "Returns Green for success role" {
        $result = Get-IconColor -Role "success"
        $result | Should -Be "Green"
    }

    It "Returns Yellow for warning role" {
        $result = Get-IconColor -Role "warning"
        $result | Should -Be "Yellow"
    }

    It "Returns Red for error role" {
        $result = Get-IconColor -Role "error"
        $result | Should -Be "Red"
    }

    It "Returns Cyan for info role" {
        $result = Get-IconColor -Role "info"
        $result | Should -Be "Cyan"
    }

    It "Returns Blue for tip role" {
        $result = Get-IconColor -Role "tip"
        $result | Should -Be "Blue"
    }

    It "Returns Magenta for question role" {
        $result = Get-IconColor -Role "question"
        $result | Should -Be "Magenta"
    }
}

Describe "Test-NerdFontSupport" {
    Context "When $global:OhMyPwsh_UseNerdFonts is not set" {
        BeforeAll {
            $global:OhMyPwsh_UseNerdFonts = $null
        }

        It "Returns false (Unicode fallback by default)" {
            $result = Test-NerdFontSupport
            $result | Should -Be $false
        }
    }

    Context "When $global:OhMyPwsh_UseNerdFonts is explicitly true" {
        BeforeAll {
            $global:OhMyPwsh_UseNerdFonts = $true
        }

        AfterAll {
            $global:OhMyPwsh_UseNerdFonts = $false
        }

        It "Returns true" {
            $result = Test-NerdFontSupport
            $result | Should -Be $true
        }
    }

    Context "When $global:OhMyPwsh_UseNerdFonts is explicitly false" {
        BeforeAll {
            $global:OhMyPwsh_UseNerdFonts = $false
        }

        It "Returns false" {
            $result = Test-NerdFontSupport
            $result | Should -Be $false
        }
    }
}
