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
    Status message text (string) OR array of styled segments (hashtables with Text and Color keys)

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

    .EXAMPLE
    # Styled segments for complex messages
    $segments = @(
        @{Text = "install "; Color = "White"}
        @{Text = "bat"; Color = "Yellow"}
        @{Text = ": "; Color = "White"}
        @{Text = "scoop install bat"; Color = "DarkGray"}
    )
    Write-StatusMessage -Role "warning" -Message $segments
    # [!] install bat: scoop install bat (with colored parts)
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('success', 'warning', 'error', 'info', 'tip', 'question')]
        [string]$Role,

        [Parameter(Mandatory)]
        $Message,  # String or array of hashtables

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
    } else {
        # Unicode mode: [icon] + space
        Write-Host "[" -NoNewline -ForegroundColor DarkGray
        Write-Host $icon -NoNewline -ForegroundColor $iconColor
        Write-Host "] " -NoNewline -ForegroundColor DarkGray
    }

    # Handle string or styled segments
    if ($Message -is [string]) {
        # Simple string message
        Write-Host $Message -ForegroundColor White
    } elseif ($Message -is [array]) {
        # Array of styled segments: @{Text="..."; Color="..."}
        foreach ($segment in $Message) {
            $text = $segment.Text
            $color = if ($segment.Color) { $segment.Color } else { "White" }
            Write-Host $text -NoNewline -ForegroundColor $color
        }
        Write-Host ""  # Newline
    } else {
        # Fallback for unexpected types
        Write-Host $Message -ForegroundColor White
    }
}
