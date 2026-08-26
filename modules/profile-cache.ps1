# ============================================
# Profile Cache Module
# ============================================
# Caches tool availability checks to speed up profile loading.
# Full check runs once per day (configurable), then silent loads from cache.
# Use `profile-status` command to force a fresh check anytime.

$script:CachePath = Join-Path $env:USERPROFILE ".oh-my-pwsh-cache.json"
$script:CacheLockPath = Join-Path $env:USERPROFILE ".oh-my-pwsh-cache.lock"
$script:RefreshScript = Join-Path (Split-Path -Parent $PSScriptRoot) "scripts\Update-ProfileCacheBackground.ps1"

# A refresh that started this long ago is presumed dead, and its lock is ignored.
$script:CacheLockStaleMinutes = 5

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

function ConvertTo-CacheTimestampDateTime {
    param(
        [Parameter(Mandatory = $false)]
        $Timestamp
    )

    if (-not $Timestamp) {
        return $null
    }

    if ($Timestamp -is [DateTime]) {
        return $Timestamp
    }

    if ($Timestamp -is [DateTimeOffset]) {
        return $Timestamp.LocalDateTime
    }

    $parsed = [DateTime]::MinValue
    if ([DateTime]::TryParseExact(
        [string]$Timestamp,
        "o",
        [System.Globalization.CultureInfo]::InvariantCulture,
        [System.Globalization.DateTimeStyles]::RoundtripKind,
        [ref]$parsed
    )) {
        return $parsed
    }

    if ([DateTime]::TryParse(
        [string]$Timestamp,
        [System.Globalization.CultureInfo]::InvariantCulture,
        [System.Globalization.DateTimeStyles]::AssumeLocal,
        [ref]$parsed
    )) {
        return $parsed
    }

    if ([DateTime]::TryParse(
        [string]$Timestamp,
        [System.Globalization.CultureInfo]::CurrentCulture,
        [System.Globalization.DateTimeStyles]::AssumeLocal,
        [ref]$parsed
    )) {
        return $parsed
    }

    return $null
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
    $timestamp = ConvertTo-CacheTimestampDateTime -Timestamp $cache.Timestamp
    if (-not $timestamp) {
        return $false
    }
    $age = (Get-Date) - $timestamp
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
        fnm    = [bool](Get-Command fnm -ErrorAction SilentlyContinue)
        'oh-my-posh' = [bool](Get-Command oh-my-posh -ErrorAction SilentlyContinue)
        scoop  = [bool](Get-Command scoop -ErrorAction SilentlyContinue)
    }

    $modules = @{
        'Terminal-Icons' = [bool](Get-Module -ListAvailable Terminal-Icons)
        'posh-git'       = [bool](Get-Module -ListAvailable posh-git)
        PSFzf            = [bool](Get-Module -ListAvailable PSFzf)
        PSReadLine       = [bool](Get-Module -ListAvailable PSReadLine)
    }

    # Enumerating the two font registry keys costs ~350ms, which is why the answer belongs
    # in the cache and not on the critical path of every shell start.
    $nerdFonts = @{ Installed = $false; Count = 0 }
    if (Get-Command Test-NerdFontInstalled -ErrorAction SilentlyContinue) {
        $nf = Test-NerdFontInstalled
        $nerdFonts = @{ Installed = [bool]$nf.Installed; Count = [int]$nf.Count }
    }

    $cache = @{
        Timestamp = (Get-Date).ToString("o")
        Tools     = $tools
        Modules   = $modules
        NerdFonts = $nerdFonts
    }

    # Write to a sibling file and move it into place: several terminals can be refreshing at
    # once, and a half-written JSON file reads back as "no cache" on every later start.
    $written = $false
    $temp = "$script:CachePath.$PID.tmp"
    try {
        $cache | ConvertTo-Json -Depth 3 | Set-Content $temp -Force -ErrorAction Stop
        Move-Item $temp $script:CachePath -Force -ErrorAction Stop
        $written = $true
    } catch {
        Remove-Item $temp -Force -ErrorAction SilentlyContinue
        if (-not $env:CODEX_CI) {
            Write-Warning "Could not write profile cache: $($_.Exception.Message)"
        }
    }

    $cache.Written = $written
    return $cache
}

function Start-ProfileCacheRefresh {
    <#
    .SYNOPSIS
        Kicks off a detached refresh of the tool cache and returns immediately.
    .DESCRIPTION
        Returns $true when a refresh was started or is already running, $false when it could
        not be started - the caller must then say so rather than pretend the cache is fine.
    #>
    if (-not (Test-Path $script:RefreshScript)) { return $false }

    # Lock, so twenty terminals opened at once do not start twenty registry scans.
    if (Test-Path $script:CacheLockPath) {
        $lockAge = (Get-Date) - (Get-Item $script:CacheLockPath).LastWriteTime
        if ($lockAge.TotalMinutes -lt $script:CacheLockStaleMinutes) { return $true }
    }

    try {
        Set-Content $script:CacheLockPath -Value (Get-Date).ToString("o") -Force -ErrorAction Stop
        Start-Process -FilePath (Get-Process -Id $PID).Path `
            -ArgumentList '-NoProfile', '-NonInteractive', '-WindowStyle', 'Hidden', '-File', $script:RefreshScript `
            -WindowStyle Hidden -ErrorAction Stop | Out-Null
        return $true
    } catch {
        Remove-Item $script:CacheLockPath -Force -ErrorAction SilentlyContinue
        return $false
    }
}

function Get-ToolAvailability {
    <#
    .SYNOPSIS
        Returns tool/module availability without ever blocking the shell on a scan.
    .DESCRIPTION
        Three outcomes, and they must stay distinguishable - a cache that silently fails to
        write would otherwise look exactly like a cache that is working:

          State 'cached'     Fresh = $false  cache present and inside its TTL
          State 'refreshing' Fresh = $null   stale (or absent) values shown, refresh running
          State 'uncached'   Fresh = $true   nothing cached and no refresh could start, so
                                             the values below came from a live check
    .OUTPUTS
        Object with .Tools, .Modules, .NerdFonts, .Fresh, .State
    #>
    if (Test-ProfileCacheValid) {
        $cache = Get-ProfileCache
        $cache | Add-Member -NotePropertyName Fresh -NotePropertyValue $false -Force
        $cache | Add-Member -NotePropertyName State -NotePropertyValue 'cached' -Force
        return $cache
    }

    $started = Start-ProfileCacheRefresh
    $stale = Get-ProfileCache

    if ($started -and $stale) {
        # Stale values are still the best answer available, and they cost nothing.
        $stale | Add-Member -NotePropertyName Fresh -NotePropertyValue $null -Force
        $stale | Add-Member -NotePropertyName State -NotePropertyValue 'refreshing' -Force
        return $stale
    }

    if ($started) {
        # First run ever: nothing to show. Report unknown rather than a wall of false
        # negatives telling the user to install tools that are probably already there.
        return [pscustomobject]@{
            Timestamp = $null
            Tools     = [pscustomobject]@{}
            Modules   = [pscustomobject]@{}
            NerdFonts = [pscustomobject]@{ Installed = $true; Count = 0 }
            Fresh     = $null
            State     = 'refreshing'
        }
    }

    # No cache and no way to refresh in the background - pay for the scan here, visibly.
    $cache = Update-ProfileCache
    $cache | Add-Member -NotePropertyName Fresh -NotePropertyValue $true -Force
    $cache | Add-Member -NotePropertyName State -NotePropertyValue 'uncached' -Force
    return $cache
}

function Write-ProfileCacheNotice {
    <#
    .SYNOPSIS
        Says out loud when the tool list on screen is not a finished answer.
    #>
    param([Parameter(Mandatory)][AllowNull()]$Availability)

    switch ($Availability.State) {
        'refreshing' {
            Write-StatusMessage -Role "info" -Message @(
                @{Text = "tools: "; Color = "White" }
                @{Text = "checking in background"; Color = "Yellow" }
                @{Text = " - result applies from the next shell"; Color = "DarkGray" }
            )
        }
        'uncached' {
            Write-StatusMessage -Role "warning" -Message @(
                @{Text = "tools: "; Color = "White" }
                @{Text = "cache could not be written"; Color = "Yellow" }
                @{Text = " - every shell start pays for a full scan"; Color = "DarkGray" }
            )
        }
    }
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
        fnm    = @{ desc = "per-project Node version"; cmd = "winget install Schniz.fnm" }
        'oh-my-posh' = @{ desc = "prompt theme"; cmd = "winget install JanDeDobbeleer.OhMyPosh" }
        bat    = @{ desc = "enhanced cat"; pkg = "bat" }
        eza    = @{ desc = "enhanced ls"; pkg = "eza" }
        rg     = @{ desc = "enhanced grep"; pkg = "ripgrep" }
        fd     = @{ desc = "enhanced find"; pkg = "fd" }
        delta  = @{ desc = "enhanced git diff"; pkg = "delta" }
    }

    foreach ($tool in @('fzf', 'zoxide', 'fnm', 'oh-my-posh', 'bat', 'eza', 'rg', 'fd', 'delta')) {
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
    $cacheTimestamp = ConvertTo-CacheTimestampDateTime -Timestamp $cache.Timestamp
    if ($cacheTimestamp) {
        $cacheAge = (Get-Date) - $cacheTimestamp
    }
    Write-Host "  Cache refreshed just now. TTL: $(Get-CacheTTLHours)h" -ForegroundColor DarkGray
    Write-Host ""
}

Set-Alias -Name profile-status -Value Show-ProfileStatus

# =====================================================
# OH MY POSH INIT SCRIPT CACHE
# =====================================================
# `oh-my-posh init pwsh` spawns a process and costs ~350ms of the ~1.4s profile load, and
# its output only changes when the theme or the binary changes. Cache the script it prints
# and dot-source that instead; the stamp line at the top records what the cache was built
# from, so a theme edit or an oh-my-posh upgrade invalidates it by itself.

$script:OmpInitCachePath = Join-Path $env:USERPROFILE ".oh-my-pwsh-omp-init.ps1"

function Set-OhMyPoshSessionId {
    <#
    .SYNOPSIS
        Replaces the session id baked into a cached oh-my-posh init script with a fresh one.
    .DESCRIPTION
        oh-my-posh stamps a new POSH_SESSION_ID into every init script it prints, and keys
        its per-shell state on it. Replaying a cached script verbatim would hand the same id
        to every terminal on the machine, so they would share that state.
    #>
    param([Parameter(Mandatory)][string]$Init)

    [regex]::Replace(
        $Init,
        '(?<=\$env:POSH_SESSION_ID = ")[^"]*(?=")',
        [guid]::NewGuid().ToString())
}

function Get-OhMyPoshInitScript {
    <#
    .SYNOPSIS
        Returns the text of `oh-my-posh init pwsh`, from cache when the cache still matches.
    .DESCRIPTION
        Returns $null only when oh-my-posh itself cannot be run or printed nothing. A cache
        that cannot be written is not an error - the caller still gets a working init script,
        it just paid for the process spawn to get it.
    #>
    param([string]$ConfigPath)

    $ompCmd = Get-Command oh-my-posh -ErrorAction SilentlyContinue
    if (-not $ompCmd) { return $null }

    $hasConfig = $ConfigPath -and (Test-Path $ConfigPath)
    # The binary's own timestamp is part of the key: an upgrade rewrites the versioned
    # init script this one calls into, and the old path stops existing.
    $stampParts = @($ompCmd.Source)
    $stampParts += (Get-Item $ompCmd.Source -ErrorAction SilentlyContinue).LastWriteTimeUtc.Ticks
    if ($hasConfig) {
        $stampParts += $ConfigPath
        $stampParts += (Get-Item $ConfigPath).LastWriteTimeUtc.Ticks
    }
    $stamp = "# stamp: " + ($stampParts -join "|")

    if (Test-Path $script:OmpInitCachePath) {
        $cached = Get-Content $script:OmpInitCachePath -Raw -ErrorAction SilentlyContinue
        if ($cached -and $cached.StartsWith($stamp)) {
            $body = $cached.Substring($stamp.Length)
            # A cached script that calls a file oh-my-posh has since deleted would leave the
            # shell with the plain default prompt and no error. Check before trusting it.
            $referenced = [regex]::Match($body, "'(?<path>[^']+\.ps1)'")
            if (-not $referenced.Success -or (Test-Path $referenced.Groups['path'].Value)) {
                return (Set-OhMyPoshSessionId $body)
            }
        }
    }

    $init = if ($hasConfig) {
        oh-my-posh init pwsh --config $ConfigPath 2>$null | Out-String
    } else {
        oh-my-posh init pwsh 2>$null | Out-String
    }
    if ([string]::IsNullOrWhiteSpace($init)) { return $null }

    $temp = "$script:OmpInitCachePath.$PID.tmp"
    try {
        Set-Content $temp -Value ($stamp + $init) -NoNewline -Force -ErrorAction Stop
        Move-Item $temp $script:OmpInitCachePath -Force -ErrorAction Stop
    } catch {
        Remove-Item $temp -Force -ErrorAction SilentlyContinue
    }
    return $init
}
