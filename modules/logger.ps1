# ============================================
# Profile Status Logger
# ============================================
# Central logging function for oh-my-pwsh status messages
#
# Levels: success, warning, error, info
# Primary: main message
# Secondary: optional install command or additional info

function Write-ProfileStatus {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('success', 'warning', 'error', 'info')]
        [string]$Level,

        [Parameter(Mandatory)]
        [string]$Primary,

        [string]$Secondary = "",

        [switch]$NoIndent
    )

    # Indent (2 spaces by default)
    $indent = if ($NoIndent) { "" } else { "  " }

    # Status icon and color based on level
    switch ($Level) {
        'success' {
            $icon = "✓"
            $iconColor = "Green"
        }
        'warning' {
            $icon = "!"
            $iconColor = "Yellow"
        }
        'error' {
            $icon = "" # Nerd Font icon (X/close)
            $iconColor = "Red"
        }
        'info' {
            $icon = "i"
            $iconColor = "Cyan"
        }
    }

    # Write status with gray brackets
    Write-Host "$indent" -NoNewline
    Write-Host "[" -NoNewline -ForegroundColor DarkGray
    Write-Host $icon -NoNewline -ForegroundColor $iconColor
    Write-Host "]" -NoNewline -ForegroundColor DarkGray
    Write-Host " $Primary" -NoNewline -ForegroundColor White

    # Write secondary (install command) if provided
    if ($Secondary) {
        Write-Host "  " -NoNewline
        Write-Host "[" -NoNewline -ForegroundColor DarkGray
        Write-Host " " -NoNewline
        Write-Host "$" -NoNewline -ForegroundColor Gray
        Write-Host " $Secondary " -NoNewline -ForegroundColor Gray
        Write-Host "]" -ForegroundColor DarkGray
    } else {
        Write-Host ""  # New line
    }
}

# ============================================
# Write Install Hint - Reusable function for missing tools
# ============================================
function Write-InstallHint {
    param(
        [Parameter(Mandatory)]
        [string]$Tool,

        [string]$Description = "",

        [Parameter(Mandatory)]
        [string]$InstallCommand
    )

    $indent = "  "
    Write-Host "$indent" -NoNewline
    Write-Host "[" -NoNewline -ForegroundColor DarkGray
    Write-Host "!" -NoNewline -ForegroundColor Yellow
    Write-Host "]" -NoNewline -ForegroundColor DarkGray
    Write-Host " install " -NoNewline -ForegroundColor White
    Write-Host "``$Tool``" -NoNewline -ForegroundColor White

    if ($Description) {
        Write-Host " for " -NoNewline -ForegroundColor White
        Write-Host $Description -NoNewline -ForegroundColor White
    }

    Write-Host ": " -NoNewline -ForegroundColor White
    Write-Host $InstallCommand -ForegroundColor DarkGray
}

# ============================================
# Convenience aliases for common patterns
# ============================================
function Write-ModuleStatus {
    param(
        [string]$Name,
        [bool]$Loaded,
        [string]$InstallCommand = "",
        [string]$Description = ""
    )

    $displayName = if ($Description) { "$Name ($Description)" } else { $Name }

    if ($Loaded) {
        Write-ProfileStatus -Level success -Primary $displayName
    } else {
        Write-ProfileStatus -Level warning -Primary $Name -Secondary $InstallCommand
    }
}

function Write-ToolStatus {
    param(
        [string]$Name,
        [bool]$Installed,
        [string]$Description = "",
        [string]$ScoopPackage = ""
    )

    if ($Installed) {
        $displayName = if ($Description) { "$Name ($Description)" } else { $Name }
        Write-ProfileStatus -Level success -Primary $displayName
    } else {
        # Use reusable Write-InstallHint function
        if ($ScoopPackage) {
            Write-InstallHint -Tool $Name -Description $Description -InstallCommand "scoop install $ScoopPackage"
        }
    }
}
