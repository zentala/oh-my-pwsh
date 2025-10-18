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

    # Build styled message segments for better visual clarity
    $segments = @(
        @{Text = "install "; Color = "White"}
        @{Text = "``$Tool``"; Color = "Yellow"}
    )

    if ($Description) {
        $segments += @{Text = " for "; Color = "White"}
        $segments += @{Text = $Description; Color = "White"}
    }

    $segments += @{Text = ": "; Color = "White"}
    $segments += @{Text = $InstallCommand; Color = "DarkGray"}

    # Use Write-StatusMessage with styled segments
    Write-StatusMessage -Role "warning" -Message $segments
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
