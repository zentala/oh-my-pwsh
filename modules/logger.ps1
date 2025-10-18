# ============================================
# Profile Status Logger
# ============================================
# Central logging function for oh-my-pwsh status messages
# Now uses Write-StatusMessage for proper color control

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

    # Build message
    $message = $Primary
    if ($Secondary) {
        $message += "  [ $ $Secondary ]"
    }

    # Use Write-StatusMessage for proper color control
    Write-StatusMessage -Role $Level -Message $message -NoIndent:$NoIndent
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

    # Build message: install `tool` for description: command
    $message = "install ``$Tool``"
    if ($Description) {
        $message += " for $Description"
    }
    $message += ": $InstallCommand"

    # Use Write-StatusMessage with warning level
    Write-StatusMessage -Role "warning" -Message $message
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
