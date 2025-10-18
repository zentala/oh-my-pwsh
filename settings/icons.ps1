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
        NerdFont = "$([char]0xF00C)"  # nf-fa-check
        Unicode  = "✓"
        Color    = "Green"
    }
    warning = @{
        NerdFont = "$([char]0xF071)"  # nf-fa-exclamation_triangle
        Unicode  = "!"
        Color    = "Yellow"
    }
    error = @{
        NerdFont = "$([char]0xF467)"  # nf-mdi-close_circle_outline
        Unicode  = "x"
        Color    = "Red"
    }
    info = @{
        NerdFont = "$([char]0xF129)"  # nf-fa-info_circle
        Unicode  = "i"
        Color    = "Cyan"
    }
    tip = @{
        NerdFont = "$([char]0xF0EB)"  # nf-fa-lightbulb_o
        Unicode  = "※"
        Color    = "Blue"
    }
    question = @{
        NerdFont = "$([char]0xF128)"  # nf-fa-question
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
    All icons in oh-my-pwsh should use this function.

    .PARAMETER Role
    Icon role: success, warning, error, info, tip, question

    .OUTPUTS
    String - Icon character

    .EXAMPLE
    $icon = Get-FallbackIcon -Role "success"
    Write-Host "[$icon] Operation completed"

    .EXAMPLE
    $icon = Get-FallbackIcon -Role "warning"
    Write-Host "[$icon] Optional feature missing" -ForegroundColor Yellow
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('success', 'warning', 'error', 'info', 'tip', 'question')]
        [string]$Role
    )

    # Check for custom icon override
    if ($global:OhMyPwsh_CustomIcons -and $global:OhMyPwsh_CustomIcons.ContainsKey($Role)) {
        return $global:OhMyPwsh_CustomIcons[$Role]
    }

    # Get icon definition
    if (-not $script:IconMap.ContainsKey($Role)) {
        Write-Warning "Unknown icon role: $Role. Using default '?'"
        return "?"
    }

    $iconDef = $script:IconMap[$Role]

    # Check Nerd Font support
    $useNerdFont = Test-NerdFontSupport

    # Return appropriate icon
    if ($useNerdFont) {
        return $iconDef.NerdFont
    } else {
        return $iconDef.Unicode
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
