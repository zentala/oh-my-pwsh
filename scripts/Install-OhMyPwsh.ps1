# =====================================================
# Install oh-my-pwsh - One-Click Setup
# =====================================================
# Complete installation script for oh-my-pwsh
# Run with: pwsh -ExecutionPolicy Bypass -File Install-OhMyPwsh.ps1

param(
    [switch]$SkipDependencies,
    [switch]$SkipProfile,
    [switch]$InstallEnhancedTools
)

Write-Host "`n🚀 oh-my-pwsh - Complete Installation`n" -ForegroundColor Cyan

# UAC Warning
Write-Host "⚠️  NOTE: This installer may require administrator privileges (UAC prompt)" -ForegroundColor Yellow
Write-Host "   winget installs tools system-wide and may need elevation`n" -ForegroundColor Gray

$ErrorActionPreference = "Stop"
$ProfileRoot = Split-Path -Parent $PSScriptRoot

# ============================================
# 1. Clone oh-my-stats (if needed)
# ============================================
Write-Host "📦 Step 1: Checking oh-my-stats...`n" -ForegroundColor Yellow

# Clone oh-my-stats next to oh-my-pwsh (same parent directory)
$ParentDir = Split-Path -Parent $ProfileRoot
$OhMyStatsPath = Join-Path $ParentDir "oh-my-stats"

if (-not (Test-Path $OhMyStatsPath)) {
    Write-Host "  Cloning oh-my-stats to: $OhMyStatsPath" -ForegroundColor Cyan
    try {
        git clone https://github.com/zentala/oh-my-stats.git $OhMyStatsPath
        Write-Host "  ✓ oh-my-stats cloned successfully" -ForegroundColor Green
    } catch {
        Write-Host "  ⚠ Failed to clone oh-my-stats: $_" -ForegroundColor Yellow
        Write-Host "  You can clone it manually later:" -ForegroundColor Gray
        Write-Host "    git clone https://github.com/zentala/oh-my-stats.git $OhMyStatsPath" -ForegroundColor Gray
    }
} else {
    Write-Host "  ✓ oh-my-stats already exists at: $OhMyStatsPath" -ForegroundColor Green
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
# 5. Install Enhanced Tools (if requested)
# ============================================
if ($InstallEnhancedTools) {
    Write-Host "`n🎨 Step 5: Installing Enhanced Tools...`n" -ForegroundColor Yellow

    # Check if scoop is installed
    if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
        Write-Host "  Installing scoop package manager..." -ForegroundColor Cyan
        try {
            Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
            Invoke-RestMethod get.scoop.sh | Invoke-Expression
            Write-Host "  ✓ Scoop installed" -ForegroundColor Green
        } catch {
            Write-Host "  ✗ Failed to install scoop: $_" -ForegroundColor Red
            Write-Host "  You can install enhanced tools manually later" -ForegroundColor Gray
        }
    }

    # Install enhanced tools via scoop
    if (Get-Command scoop -ErrorAction SilentlyContinue) {
        $tools = @('bat', 'eza', 'ripgrep', 'fd', 'delta')
        foreach ($tool in $tools) {
            if (Get-Command $tool -ErrorAction SilentlyContinue) {
                Write-Host "  ✓ $tool already installed" -ForegroundColor Green
            } else {
                Write-Host "  Installing $tool..." -ForegroundColor Cyan
                try {
                    scoop install $tool
                    Write-Host "  ✓ $tool installed" -ForegroundColor Green
                } catch {
                    Write-Host "  ✗ Failed to install $tool" -ForegroundColor Red
                }
            }
        }
    }
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
if ($InstallEnhancedTools) {
    Write-Host "     • Enhanced tools (bat, eza, etc.) will be available" -ForegroundColor Gray
}
Write-Host ""

if (-not $InstallEnhancedTools) {
    Write-Host "  2. 🎨 (Optional) Install enhanced tools:" -ForegroundColor Cyan
    Write-Host "     • Run: pwsh -File scripts\Install-OhMyPwsh.ps1 -InstallEnhancedTools" -ForegroundColor Gray
    Write-Host "     • Or in profile: Install-EnhancedTools" -ForegroundColor Gray
    Write-Host "     • Or manually: scoop install bat eza ripgrep fd delta" -ForegroundColor Gray
    Write-Host ""
}

Write-Host "  $(if ($InstallEnhancedTools) { '2' } else { '3' }). 📚 Type 'help' to see available commands" -ForegroundColor Cyan
Write-Host ""
Write-Host "  $(if ($InstallEnhancedTools) { '3' } else { '4' }). ⚙️  Customize your config: code $ConfigPath" -ForegroundColor Cyan
Write-Host ""

Write-Host "="*60 -ForegroundColor Cyan
Write-Host ""
