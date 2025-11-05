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
        Write-Host "`n✓ Created config.ps1 from template" -ForegroundColor Green
        Write-Host "  Edit it to customize: code $ConfigPath" -ForegroundColor Cyan
        Write-Host "  Then reload profile: . `$PROFILE`n" -ForegroundColor DarkGray
    } else {
        Write-Host "`n⚠ config.example.ps1 not found!" -ForegroundColor Yellow
    }
}

# Load user config
if (Test-Path $ConfigPath) {
    . $ConfigPath
}

# ============================================
# LOAD ICON SYSTEM - Must load BEFORE logger
# ============================================
. "$ProfileRoot\settings\icons.ps1"

# ============================================
# LOAD STATUS OUTPUT - Must load AFTER icons
# ============================================
. "$ProfileRoot\modules\status-output.ps1"

# ============================================
# LOAD LOGGER - Must load AFTER icons and status-output
# ============================================
. "$ProfileRoot\modules\logger.ps1"

# ============================================
# OH-MY-STATS - Display FIRST
# ============================================
# Show stats at the TOP, so any errors/warnings during
# profile loading appear BELOW and stay visible
Import-Module C:\code\oh-my-stats\pwsh\oh-my-stats.psd1 -Force -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
if (Get-Module oh-my-stats) {
    Show-SystemStats
}

# ============================================
# LOAD POWERSHELL MODULES
# ============================================

# Terminal-Icons
Import-Module Terminal-Icons -ErrorAction SilentlyContinue
Write-ModuleStatus -Name "Terminal Icons" -Loaded ([bool](Get-Module Terminal-Icons))

# posh-git
Import-Module posh-git -ErrorAction SilentlyContinue
Write-ModuleStatus -Name "posh-git" -Loaded ([bool](Get-Module posh-git))

# PSFzf
if (Get-Command fzf -ErrorAction SilentlyContinue) {
    Import-Module PSFzf -ErrorAction SilentlyContinue
    if (Get-Module PSFzf) {
        Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
        Set-PsFzfOption -EnableAliasFuzzyGitStatus
        Write-ModuleStatus -Name "PSFzf" -Loaded $true -Description "Ctrl+R, Ctrl+T"
    } else {
        Write-ModuleStatus -Name "PSFzf" -Loaded $false
    }
} else {
    # Warning (not error) - fzf is optional enhancement
    Write-InstallHint -Tool "fzf" -Description "fuzzy finder" -InstallCommand "winget install fzf"
}

# zoxide
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    Invoke-Expression (& { (zoxide init powershell | Out-String) })
    Write-ModuleStatus -Name "zoxide" -Loaded $true -Description "z command"
} else {
    # Warning (not error) - zoxide is optional enhancement
    Write-InstallHint -Tool "zoxide" -Description "smart directory jumping" -InstallCommand "winget install ajeetdsouza.zoxide"
}

# ============================================
# LOAD CORE MODULES
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
# OH MY POSH - Theme Engine
# ============================================
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    # Try user's custom theme first, then fallback to standard theme
    $omp_config = "$ProfileRoot\themes\quick-term.omp.json"
    if (-not (Test-Path $omp_config)) {
        # Use standard paradox theme from Oh My Posh
        $omp_config = "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/paradox.omp.json"
    }

    oh-my-posh init pwsh --config $omp_config 2>$null | Invoke-Expression
    Write-ModuleStatus -Name "Oh My Posh" -Loaded $true
} else {
    Write-ProfileStatus -Level warning -Primary "Oh My Posh" -Secondary "winget install JanDeDobbeleer.OhMyPosh"
}

# PSReadLine
Write-ModuleStatus -Name "PSReadLine" -Loaded ([bool](Get-Module PSReadLine))

Write-Host ""  # Empty line after all modules

# ============================================
# WELCOME MESSAGE
# ============================================
# Show welcome by default if not configured
if (-not (Get-Variable -Name OhMyPwsh_ShowWelcome -Scope Global -ErrorAction SilentlyContinue)) {
    $global:OhMyPwsh_ShowWelcome = $true
}

if ($global:OhMyPwsh_ShowWelcome) {
    Write-Host ""
    Write-Host "  💡 Type " -NoNewline -ForegroundColor Cyan
    Write-Host "help" -NoNewline -ForegroundColor Yellow
    Write-Host " to see available commands" -ForegroundColor Cyan
    Write-Host ""
}
