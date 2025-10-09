# =====================================================
# PowerShell Profile - Paweł Żentała
# =====================================================
# Modularny profil załadowany z C:\code\pwsh-profile
# Repo: https://github.com/zentala/pwsh-profile

# Timer do mierzenia czasu ładowania profilu
$global:PSProfileLoadStart = Get-Date

# Wyłącz fastfetch - ustaw na $false aby włączyć
$DisableFastfetch = $true

# Import Terminal-Icons - adds icons to ls/dir output
Import-Module Terminal-Icons -ErrorAction SilentlyContinue

# Import posh-git - Git integration for prompt
Import-Module posh-git -ErrorAction SilentlyContinue

# Import PSFzf - Fuzzy finder for files, history, git (Ctrl+R, Ctrl+T)
Import-Module PSFzf -ErrorAction SilentlyContinue
if (Get-Module PSFzf) {
    # Ctrl+R - Command history search
    Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
    # Enable git integration
    Set-PsFzfOption -EnableAliasFuzzyGitStatus
}

# zoxide - Smart directory jumping (z command)
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    Invoke-Expression (& { (zoxide init powershell | Out-String) })
}

# ============================================
# ŁADOWANIE MODUŁÓW
# ============================================
$ProfileRoot = Split-Path -Parent $PSCommandPath

# Moduły podstawowe
. "$ProfileRoot\modules\environment.ps1"
. "$ProfileRoot\modules\psreadline.ps1"
. "$ProfileRoot\modules\aliases.ps1"
. "$ProfileRoot\modules\functions.ps1"
. "$ProfileRoot\modules\git-helpers.ps1"

# ============================================
# OH MY POSH - Inicjalizacja
# ============================================
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    $omp_config = "$env:POSH_THEMES_PATH\quick-term.omp.json"
    if (Test-Path $omp_config) {
        oh-my-posh init pwsh --config $omp_config 2>$null | Invoke-Expression
    }
}

# ============================================
# OH-MY-STATS - System Statistics Display
# ============================================
Import-Module C:\code\oh-my-stats\pwsh\oh-my-stats.psd1 -Force -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
if (Get-Module oh-my-stats) {
    Show-SystemStats
} else {
    Write-Host "⚠ oh-my-stats module not loaded - check C:\code\oh-my-stats\" -ForegroundColor Yellow
}
