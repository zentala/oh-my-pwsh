# ============================================
# Profile Cache Module
# ============================================
# Caches tool availability checks to speed up profile loading.
# Full check runs once per day (configurable), then silent loads from cache.
# Use `profile-status` command to force a fresh check anytime.

$script:CachePath = Join-Path $env:USERPROFILE ".oh-my-pwsh-cache.json"

# Default cache TTL: 24 hours (configurable via $global:OhMyPwsh_StatusCacheHours)
function Get-CacheTTLHours {
    if ($global:OhMyPwsh_StatusCacheHours) {
        return $global:OhMyPwsh_StatusCacheHours
    }
    return 24
}

function Get-ProfileCache {
    <#
    .SYNOPSIS
        Reads the cached tool availability data.
    .OUTPUTS
        Hashtable with tool availability or $null if no cache.
    #>
    if (-not (Test-Path $script:CachePath)) {
        return $null
    }
    try {
        $json = Get-Content $script:CachePath -Raw | ConvertFrom-Json
        return $json
    } catch {
        return $null
    }
}

function Test-ProfileCacheValid {
    <#
    .SYNOPSIS
        Returns $true if the cache exists and is younger than the TTL.
    #>
    $cache = Get-ProfileCache
    if (-not $cache -or -not $cache.Timestamp) {
        return $false
    }
    $age = (Get-Date) - [DateTime]::Parse($cache.Timestamp)
    return $age.TotalHours -lt (Get-CacheTTLHours)
}

function Update-ProfileCache {
    <#
    .SYNOPSIS
        Runs all tool availability checks and writes results to cache file.
    .OUTPUTS
        Hashtable with check results.
    #>
    $tools = @{
        bat    = [bool](Get-Command bat -ErrorAction SilentlyContinue)
        eza    = [bool](Get-Command eza -ErrorAction SilentlyContinue)
        rg     = [bool](Get-Command rg -ErrorAction SilentlyContinue)
        fd     = [bool](Get-Command fd -ErrorAction SilentlyContinue)
        delta  = [bool](Get-Command delta -ErrorAction SilentlyContinue)
        fzf    = [bool](Get-Command fzf -ErrorAction SilentlyContinue)
        zoxide = [bool](Get-Command zoxide -ErrorAction SilentlyContinue)
        'oh-my-posh' = [bool](Get-Command oh-my-posh -ErrorAction SilentlyContinue)
        scoop  = [bool](Get-Command scoop -ErrorAction SilentlyContinue)
    }

    $modules = @{
        'Terminal-Icons' = [bool](Get-Module -ListAvailable Terminal-Icons)
        'posh-git'       = [bool](Get-Module -ListAvailable posh-git)
        PSFzf            = [bool](Get-Module -ListAvailable PSFzf)
        PSReadLine       = [bool](Get-Module -ListAvailable PSReadLine)
    }

    $cache = @{
        Timestamp = (Get-Date).ToString("o")
        Tools     = $tools
        Modules   = $modules
    }

    $cache | ConvertTo-Json -Depth 3 | Set-Content $script:CachePath -Force
    return $cache
}

function Get-ToolAvailability {
    <#
    .SYNOPSIS
        Returns tool/module availability from cache (fast) or live check (first run / stale).
    .OUTPUTS
        Object with .Tools, .Modules, .Fresh (bool - true if just refreshed)
    #>
    if (Test-ProfileCacheValid) {
        $cache = Get-ProfileCache
        $cache | Add-Member -NotePropertyName Fresh -NotePropertyValue $false -Force
        return $cache
    }
    $cache = Update-ProfileCache
    $cache | Add-Member -NotePropertyName Fresh -NotePropertyValue $true -Force
    return $cache
}

function Show-ProfileStatus {
    <#
    .SYNOPSIS
        On-demand command to display full profile status (forces fresh check).
    .DESCRIPTION
        Use this anytime to see what tools/modules are loaded.
        Run: profile-status
    #>
    $cache = Update-ProfileCache

    Write-Host ""
    Write-Host "  oh-my-pwsh status" -ForegroundColor Cyan
    Write-Host "  ─────────────────" -ForegroundColor DarkGray

    # Modules
    foreach ($mod in @('Terminal-Icons', 'posh-git', 'PSFzf', 'PSReadLine')) {
        $loaded = $cache.Modules.$mod
        if ($loaded) {
            Write-ModuleStatus -Name $mod -Loaded $true
        } else {
            Write-ModuleStatus -Name $mod -Loaded $false
        }
    }

    # Tools
    $toolDescriptions = @{
        fzf    = @{ desc = "fuzzy finder"; cmd = "winget install fzf" }
        zoxide = @{ desc = "smart directory jumping"; cmd = "winget install ajeetdsouza.zoxide" }
        'oh-my-posh' = @{ desc = "prompt theme"; cmd = "winget install JanDeDobbeleer.OhMyPosh" }
        bat    = @{ desc = "enhanced cat"; pkg = "bat" }
        eza    = @{ desc = "enhanced ls"; pkg = "eza" }
        rg     = @{ desc = "enhanced grep"; pkg = "ripgrep" }
        fd     = @{ desc = "enhanced find"; pkg = "fd" }
        delta  = @{ desc = "enhanced git diff"; pkg = "delta" }
    }

    foreach ($tool in @('fzf', 'zoxide', 'oh-my-posh', 'bat', 'eza', 'rg', 'fd', 'delta')) {
        $available = $cache.Tools.$tool
        $info = $toolDescriptions[$tool]
        if ($available) {
            Write-ToolStatus -Name $tool -Installed $true -Description $info.desc
        } else {
            if ($info.pkg) {
                Write-ToolStatus -Name $tool -Installed $false -Description $info.desc -ScoopPackage $info.pkg
            } else {
                Write-InstallHint -Tool $tool -Description $info.desc -InstallCommand $info.cmd
            }
        }
    }

    # Nerd Fonts
    $nfCheck = Test-NerdFontInstalled
    if ($nfCheck.Installed) {
        Write-ModuleStatus -Name "Nerd Fonts" -Loaded $true
    } else {
        Write-InstallHint -Tool "Nerd Fonts" -Description "better terminal icons" -InstallCommand "Install-NerdFonts"
    }

    Write-Host ""
    $cacheAge = (Get-Date) - [DateTime]::Parse($cache.Timestamp)
    Write-Host "  Cache refreshed just now. TTL: $(Get-CacheTTLHours)h" -ForegroundColor DarkGray
    Write-Host ""
}

Set-Alias -Name profile-status -Value Show-ProfileStatus
