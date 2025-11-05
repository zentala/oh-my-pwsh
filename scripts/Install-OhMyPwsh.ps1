# =====================================================
# Install oh-my-pwsh - One-Click Setup
# =====================================================
# Complete installation script for oh-my-pwsh
# Run with: pwsh -ExecutionPolicy Bypass -File Install-OhMyPwsh.ps1

param(
    [switch]$SkipDependencies,
    [switch]$SkipProfile
)

Write-Host "`n🚀 oh-my-pwsh - Complete Installation`n" -ForegroundColor Cyan

$ErrorActionPreference = "Stop"
$ProfileRoot = Split-Path -Parent $PSScriptRoot

# ============================================
# 1. Clone oh-my-stats (if needed)
# ============================================
Write-Host "📦 Step 1: Checking oh-my-stats...`n" -ForegroundColor Yellow

$OhMyStatsPath = "C:\code\oh-my-stats"
if (-not (Test-Path $OhMyStatsPath)) {
    Write-Host "  Cloning oh-my-stats..." -ForegroundColor Cyan
    try {
        New-Item -Path "C:\code" -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
        git clone https://github.com/zentala/oh-my-stats.git $OhMyStatsPath
        Write-Host "  ✓ oh-my-stats cloned successfully" -ForegroundColor Green
    } catch {
        Write-Host "  ⚠ Failed to clone oh-my-stats: $_" -ForegroundColor Yellow
        Write-Host "  You can clone it manually later:" -ForegroundColor Gray
        Write-Host "    git clone https://github.com/zentala/oh-my-stats.git C:\code\oh-my-stats" -ForegroundColor Gray
    }
} else {
    Write-Host "  ✓ oh-my-stats already cloned" -ForegroundColor Green
}

# ============================================
# 2. Install dependencies
# ============================================
if (-not $SkipDependencies) {
    Write-Host "`n📦 Step 2: Installing dependencies...`n" -ForegroundColor Yellow

    $InstallDepsScript = Join-Path $PSScriptRoot "install-dependencies.ps1"
    if (Test-Path $InstallDepsScript) {
        & $InstallDepsScript
    } else {
        Write-Host "  ⚠ install-dependencies.ps1 not found" -ForegroundColor Yellow
    }
} else {
    Write-Host "`n⏭  Step 2: Skipping dependencies (--SkipDependencies)" -ForegroundColor Gray
}

# ============================================
# 3. Configure PowerShell profile
# ============================================
if (-not $SkipProfile) {
    Write-Host "`n📝 Step 3: Configuring PowerShell profile...`n" -ForegroundColor Yellow

    # Backup existing profile
    if (Test-Path $PROFILE) {
        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $backupPath = "$PROFILE.backup-$timestamp"
        Copy-Item $PROFILE $backupPath
        Write-Host "  ✓ Backed up existing profile to: $backupPath" -ForegroundColor Green
    }

    # Create new profile content
    $profileContent = @"
# ============================================
# PowerShell Profile
# ============================================

# Load oh-my-pwsh profile from repo
`$OhMyPwshRepo = "$ProfileRoot\profile.ps1"
if (Test-Path `$OhMyPwshRepo) {
    . `$OhMyPwshRepo
}

# ============================================
# Chocolatey Profile (if exists)
# ============================================
`$ChocolateyProfile = "`$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path `$ChocolateyProfile) {
    Import-Module "`$ChocolateyProfile"
}
"@

    # Ensure profile directory exists
    $profileDir = Split-Path $PROFILE
    if (-not (Test-Path $profileDir)) {
        New-Item -Path $profileDir -ItemType Directory -Force | Out-Null
    }

    # Write profile
    $profileContent | Out-File $PROFILE -Encoding UTF8 -Force
    Write-Host "  ✓ PowerShell profile configured" -ForegroundColor Green
    Write-Host "    Profile location: $PROFILE" -ForegroundColor Gray

} else {
    Write-Host "`n⏭  Step 3: Skipping profile configuration (--SkipProfile)" -ForegroundColor Gray
}

# ============================================
# 4. Create config.ps1 (if needed)
# ============================================
Write-Host "`n⚙️  Step 4: Checking configuration...`n" -ForegroundColor Yellow

$ConfigPath = Join-Path $ProfileRoot "config.ps1"
$ConfigExample = Join-Path $ProfileRoot "config.example.ps1"

if (-not (Test-Path $ConfigPath)) {
    if (Test-Path $ConfigExample) {
        Copy-Item $ConfigExample $ConfigPath
        Write-Host "  ✓ Created config.ps1 from template" -ForegroundColor Green
        Write-Host "    Edit it to customize: code $ConfigPath" -ForegroundColor Gray
    } else {
        Write-Host "  ⚠ config.example.ps1 not found" -ForegroundColor Yellow
    }
} else {
    Write-Host "  ✓ config.ps1 already exists" -ForegroundColor Green
}

# ============================================
# Summary
# ============================================
Write-Host "`n" + "="*60 -ForegroundColor Cyan
Write-Host "🎉 Installation Complete!" -ForegroundColor Green
Write-Host "="*60 -ForegroundColor Cyan

Write-Host "`n📌 Next Steps:" -ForegroundColor Yellow
Write-Host "  1. ⚠️  RESTART your terminal (required for PATH updates)" -ForegroundColor Yellow
Write-Host "     • fzf and zoxide will only work after restart" -ForegroundColor Gray
Write-Host ""
Write-Host "  2. 🎨 (Optional) Install enhanced tools:" -ForegroundColor Cyan
Write-Host "     • Install scoop: Set-ExecutionPolicy RemoteSigned -Scope CurrentUser" -ForegroundColor Gray
Write-Host "                      irm get.scoop.sh | iex" -ForegroundColor Gray
Write-Host "     • Then run: Install-EnhancedTools" -ForegroundColor Gray
Write-Host "     • Or manually: scoop install bat eza ripgrep fd delta" -ForegroundColor Gray
Write-Host ""
Write-Host "  3. 📚 Type 'help' to see available commands" -ForegroundColor Cyan
Write-Host ""
Write-Host "  4. ⚙️  Customize your config: code $ConfigPath" -ForegroundColor Cyan
Write-Host ""

Write-Host "="*60 -ForegroundColor Cyan
Write-Host ""
