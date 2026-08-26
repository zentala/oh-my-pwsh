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
        @{Text = "install "; Color = "White" }
        @{Text = "``$Tool``"; Color = "Yellow" }
    )

    if ($Description) {
        $segments += @{Text = " for "; Color = "White" }
        $segments += @{Text = $Description; Color = "White" }
    }

    $segments += @{Text = ": "; Color = "White" }
    $segments += @{Text = $InstallCommand; Color = "DarkGray" }

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

function Write-SkippedStatus {
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [string]$Reason
    )

    Write-ProfileStatus -Level info -Primary $Name -Secondary "skipped: $Reason"
}


# ============================================
# MISSING TOOLS - one line, not one per tool
# ============================================
# A separate "install X" hint per missing tool pushed the module list off screen on a
# fresh machine. Modules register what is missing while they load; the profile prints a
# single line at the end, ending in a paste-ready winget command.
#
# IDs verified with `winget show --id <id> --exact` on 2026-08-26 - do not guess them,
# `winget install fzf` happens to work as a query but `junegunn.fzf` is the actual ID.
# scoop is NOT installed on this machine, so winget is the only offer worth making.
$script:WingetIds = @{
    fzf          = 'junegunn.fzf'
    zoxide       = 'ajeetdsouza.zoxide'
    fnm          = 'Schniz.fnm'
    'oh-my-posh' = 'JanDeDobbeleer.OhMyPosh'
    bat          = 'sharkdp.bat'
    eza          = 'eza-community.eza'
    rg           = 'BurntSushi.ripgrep.MSVC'
    fd           = 'sharkdp.fd'
    delta        = 'dandavison.delta'
}

$global:_ProfileMissingTools = [System.Collections.Generic.List[string]]::new()

function Register-MissingTool {
    <#
    .SYNOPSIS
        Records a tool as missing, to be reported once at the end of profile load.
    #>
    param([Parameter(Mandatory)][string]$Tool)

    if (-not $global:_ProfileMissingTools.Contains($Tool)) {
        $global:_ProfileMissingTools.Add($Tool)
    }
}

function Write-MissingToolsHint {
    <#
    .SYNOPSIS
        Prints one line naming every missing tool plus a single winget command installing
        all of them. Prints nothing when everything is present.
    #>
    if ($global:_ProfileMissingTools.Count -eq 0) { return }

    $ids = foreach ($tool in $global:_ProfileMissingTools) {
        if ($script:WingetIds.ContainsKey($tool)) { $script:WingetIds[$tool] } else { $tool }
    }

    Write-StatusMessage -Role "warning" -Message @(
        @{Text = "missing: "; Color = "White" }
        @{Text = ($global:_ProfileMissingTools -join ', '); Color = "Yellow" }
        @{Text = "  ->  winget install "; Color = "DarkGray" }
        @{Text = ($ids -join ' '); Color = "DarkGray" }
    )
}
