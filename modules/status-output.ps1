# ============================================
# Status Output Module
# ============================================
# Colored status message rendering with granular color control

function Write-StatusMessage {
    <#
    .SYNOPSIS
    Write a status message with colored icon badge

    .DESCRIPTION
    Renders status message with proper colors:
    - Brackets: DarkGray
    - Icon: Role color (Green/Yellow/Red/Cyan/Blue/Magenta)
    - Text: White

    Supports both Nerd Font and Unicode modes.

    .PARAMETER Role
    Icon role: success, warning, error, info, tip, question

    .PARAMETER Message
    Status message text

    .PARAMETER NoIndent
    Skip the default 2-space indentation

    .EXAMPLE
    Write-StatusMessage -Role "success" -Message "Module loaded"
    # Unicode: [✓] Module loaded
    # NF:      󰄵 Module loaded

    .EXAMPLE
    Write-StatusMessage -Role "warning" -Message "Optional tool missing"
    # Unicode: [!] Optional tool missing

    .EXAMPLE
    Write-StatusMessage -Role "info" -Message "Configuration loaded" -NoIndent
    # [i] Configuration loaded (no indentation)
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('success', 'warning', 'error', 'info', 'tip', 'question')]
        [string]$Role,

        [Parameter(Mandatory)]
        [string]$Message,

        [switch]$NoIndent
    )

    $icon = Get-FallbackIcon -Role $Role  # Standalone icon
    $iconColor = Get-IconColor -Role $Role

    # Indent (2 spaces by default)
    $indent = if ($NoIndent) { "" } else { "  " }
    Write-Host $indent -NoNewline

    if (Test-NerdFontSupport) {
        # Nerd Font mode: icon + space (no brackets)
        Write-Host $icon -NoNewline -ForegroundColor $iconColor
        Write-Host " " -NoNewline
        Write-Host $Message -ForegroundColor White
    } else {
        # Unicode mode: [icon] + space
        Write-Host "[" -NoNewline -ForegroundColor DarkGray
        Write-Host $icon -NoNewline -ForegroundColor $iconColor
        Write-Host "] " -NoNewline -ForegroundColor DarkGray
        Write-Host $Message -ForegroundColor White
    }
}
