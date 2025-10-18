# ============================================
# Icon System with Nerd Font Fallbacks
# ============================================
# Universal icon system for oh-my-pwsh
# Supports Nerd Fonts with Unicode fallbacks
#
# ⚠️ EXPERIMENTAL FEATURE - SUSPENDED
# Nerd Fonts rendering is currently unreliable and looks bad in most terminals.
# Default to Unicode fallback ($global:OhMyPwsh_UseNerdFonts = $false) for best results.
#
# Nerd Font codes are preserved in IconMap for future use when terminal support improves.
# DO NOT REMOVE NerdFont definitions - they are kept for future reactivation.
#
# To re-enable when terminals improve:
# 1. Set $global:OhMyPwsh_UseNerdFonts = $true in config.ps1
# 2. Test with .\test-icons.ps1
# 3. Verify icons render correctly in your terminal

# ============================================
# ICON DEFINITIONS
# ============================================
# All icons defined here with Nerd Font and Unicode fallback

$script:IconMap = @{
    success = @{
        NerdFont = "󰄵"  # U+F0135 - direct UTF-8
        Unicode  = "✓"
        Color    = "Green"
    }
    warning = @{
        NerdFont = "󰗖"  # U+F05D6 - direct UTF-8
        Unicode  = "!"
        Color    = "Yellow"
    }
    error = @{
        NerdFont = ""  # U+F052F - direct UTF-8
        Unicode  = "x"
        Color    = "Red"
    }
    info = @{
        NerdFont = ""  # U+F0449 - direct UTF-8
        Unicode  = "i"
        Color    = "Cyan"
    }
    tip = @{
        NerdFont = ""  # U+F0400 - direct UTF-8
        Unicode  = "※"
        Color    = "Blue"
    }
    question = @{
        NerdFont = ""  # U+F0420 - direct UTF-8
        Unicode  = "?"
        Color    = "Magenta"
    }
}

# ============================================
# NERD FONT DETECTION
# ============================================

function Test-NerdFontSupport {
    <#
    .SYNOPSIS
    Check if Nerd Fonts should be used for icons

    .DESCRIPTION
    Checks user configuration to determine if Nerd Fonts are available.
    Defaults to Unicode fallback for safety.

    .OUTPUTS
    Boolean - $true if Nerd Fonts enabled, $false for Unicode fallback

    .EXAMPLE
    if (Test-NerdFontSupport) {
        # Use Nerd Font icons
    }
    #>

    # Check user config (explicit opt-in required)
    if ($null -ne $global:OhMyPwsh_UseNerdFonts) {
        return $global:OhMyPwsh_UseNerdFonts
    }

    # Default: Use Unicode fallback (safe for all terminals)
    return $false
}

# ============================================
# GET ICON WITH FALLBACK
# ============================================

function Get-FallbackIcon {
    <#
    .SYNOPSIS
    Get icon character with automatic Nerd Font or Unicode fallback

    .DESCRIPTION
    Returns appropriate icon based on Nerd Font availability.
    Can return standalone icon or formatted status badge.

    .PARAMETER Role
    Icon role: success, warning, error, info, tip, question

    .PARAMETER AsStatusBadge
    If specified, returns formatted badge with icon:
    - Nerd Font mode: "icon " (no brackets, with trailing space)
    - Unicode mode: "[icon] " (with brackets and trailing space)
    If not specified, returns just the icon character.

    .OUTPUTS
    String - Icon character or formatted badge

    .EXAMPLE
    # Standalone icon
    $icon = Get-FallbackIcon -Role "success"
    Write-Host "Done $icon"  # "Done ✓" or "Done 󰄵"

    .EXAMPLE
    # Status badge
    $badge = Get-FallbackIcon -Role "success" -AsStatusBadge
    Write-Host "${badge}Operation completed"  # "[✓] Operation completed" or "󰄵 Operation completed"
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('success', 'warning', 'error', 'info', 'tip', 'question')]
        [string]$Role,

        [switch]$AsStatusBadge
    )

    # Check for custom icon override
    if ($global:OhMyPwsh_CustomIcons -and $global:OhMyPwsh_CustomIcons.ContainsKey($Role)) {
        $icon = $global:OhMyPwsh_CustomIcons[$Role]
    } else {
        # Get icon definition
        if (-not $script:IconMap.ContainsKey($Role)) {
            Write-Warning "Unknown icon role: $Role. Using default '?'"
            $icon = "?"
        } else {
            $iconDef = $script:IconMap[$Role]

            # Check Nerd Font support
            $useNerdFont = Test-NerdFontSupport

            # Get appropriate icon
            if ($useNerdFont) {
                $icon = $iconDef.NerdFont
            } else {
                $icon = $iconDef.Unicode
            }
        }
    }

    # Format as status badge if requested
    if ($AsStatusBadge) {
        if (Test-NerdFontSupport) {
            return "$icon "  # Nerd Font: "󰄵 " (icon + space, no brackets)
        } else {
            return "[$icon] "  # Unicode: "[✓] " (brackets + space)
        }
    } else {
        return $icon  # Standalone: just the icon
    }
}

# ============================================
# GET ICON COLOR
# ============================================

function Get-IconColor {
    <#
    .SYNOPSIS
    Get the color associated with an icon role

    .DESCRIPTION
    Returns the default color for a given icon role

    .PARAMETER Role
    Icon role: success, warning, error, info, tip

    .OUTPUTS
    String - PowerShell color name

    .EXAMPLE
    $color = Get-IconColor -Role "success"
    # Returns: "Green"
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('success', 'warning', 'error', 'info', 'tip', 'question')]
        [string]$Role
    )

    if (-not $script:IconMap.ContainsKey($Role)) {
        return "White"
    }

    return $script:IconMap[$Role].Color
}

# ============================================
# FUNCTIONS ARE DOT-SOURCED
# ============================================
# No Export-ModuleMember needed - functions are available when dot-sourced
