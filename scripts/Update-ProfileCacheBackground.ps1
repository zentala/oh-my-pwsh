# =====================================================
# Background profile-cache refresh
# =====================================================
# Run by profile.ps1 in a detached, hidden pwsh so that no shell start ever waits on a
# tool scan. Everything here is deliberately independent of the profile: it dot-sources
# the few modules Update-ProfileCache needs and nothing else.
#
# Never call this in the foreground - use Start-ProfileCacheRefresh, which also takes the
# lock that keeps twenty terminals opening at once from starting twenty scans.

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

try {
    . "$root\settings\icons.ps1"
    . "$root\modules\status-output.ps1"
    . "$root\modules\logger.ps1"
    . "$root\modules
erd-fonts.ps1"
    . "$root\modules\profile-cache.ps1"

    $result = Update-ProfileCache
    if (-not $result.Written) { exit 1 }
    exit 0
} catch {
    # The caller cannot see this process, so leave a trace on disk instead of dying quietly.
    $log = Join-Path $env:USERPROFILE '.oh-my-pwsh-cache.error'
    "$(Get-Date -Format o)  $($_.Exception.Message)" | Set-Content $log -Force -ErrorAction SilentlyContinue
    exit 1
}
