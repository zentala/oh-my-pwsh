# =====================================================
# oh-my-pwsh - PowerShell Profile Enhanced
# =====================================================
# Created by: Paweł Żentała
# Repo: https://github.com/zentala/pwsh-profile
# Docs: Type 'help' to see available commands

# Timer for profile loading
$global:PSProfileLoadStart = Get-Date

# ============================================
# LOAD USER CONFIGURATION
# ============================================
$ProfileRoot = Split-Path -Parent $PSCommandPath
$ConfigPath = Join-Path $ProfileRoot "config.ps1"

# Check if config exists, if not copy from example
if (-not (Test-Path $ConfigPath)) {
    $ExampleConfig = Join-Path $ProfileRoot "config.example.ps1"
    if (Test-Path $ExampleConfig) {
        Copy-Item $ExampleConfig $ConfigPath
        Write-Host "✓ Created config.ps1from template" -ForegroundColor Green
        Write-Host "  Edit it: code config.ps1`n" -ForegroundColor Cyan
    } else {
        Write-Host "⚠ config.example.ps1 not found!" -ForegroundColor Yellow
    }
}

# Load user config
if (Test-Path $ConfigPath) {
    . $ConfigPath
}

# Import Terminal-Icons - adds icons to ls/dir output
Import-Module Terminal-Icons -ErrorAction SilentlyContinue

# Import posh-git - Git integration for prompt
Import-Module posh-git -ErrorAction SilentlyContinue

# Import PSFzf - Fuzzy finder for files, history, git (Ctrl+R, Ctrl+T)
# Check if fzf binary exists before importing PSFzf
if (Get-Command fzf -ErrorAction SilentlyContinue) {
    Import-Module PSFzf -ErrorAction SilentlyContinue
    if (Get-Module PSFzf) {
        # Ctrl+R - Command history search
        Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
        # Enable git integration
        Set-PsFzfOption -EnableAliasFuzzyGitStatus
    }
}

# zoxide - Smart directory jumping (z command)
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    Invoke-Expression (& { (zoxide init powershell | Out-String) })
}

# ============================================
# LOAD MODULES
# ============================================

# Core modules
. "$ProfileRoot\modules\environment.ps1"
. "$ProfileRoot\modules\psreadline.ps1"
. "$ProfileRoot\modules\functions.ps1"
. "$ProfileRoot\modules\git-helpers.ps1"

# oh-my-pwsh modules (can be toggled in config.ps1)
. "$ProfileRoot\modules\linux-compat.ps1"      # Linux-style aliases
. "$ProfileRoot\modules\enhanced-tools.ps1"    # bat, eza, ripgrep, fd, delta
. "$ProfileRoot\modules\help-system.ps1"       # Custom help command

# Legacy aliases (deprecated - use linux-compat.ps1 instead)
# . "$ProfileRoot\modules\aliases.ps1"

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
# Display stats at the END so errors/warnings are visible above
Write-Host ""  # Empty line to separate errors from stats
Import-Module C:\code\oh-my-stats\pwsh\oh-my-stats.psd1 -Force -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
if (Get-Module oh-my-stats) {
    Show-SystemStats
} else {
    Write-Host "⚠ oh-my-stats module not loaded - check C:\code\oh-my-stats\" -ForegroundColor Yellow
}

# ============================================
# WELCOME MESSAGE
# ============================================
if ($global:OhMyPwsh_ShowTips) {
    Write-Host ""
    Write-Host "💡 Type " -NoNewline -ForegroundColor Cyan
    Write-Host "help" -NoNewline -ForegroundColor Yellow
    Write-Host " to see available commands" -ForegroundColor Cyan
    Write-Host ""
}
