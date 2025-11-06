# =====================================================
# Install oh-my-pwsh - One-Click Setup
# =====================================================
# Complete installation script for oh-my-pwsh
# Run with: pwsh -ExecutionPolicy Bypass -File Install-OhMyPwsh.ps1

param(
    [switch]$SkipDependencies,
    [switch]$SkipProfile,

    # New default behavior: Install by default, skip if specified
    [switch]$SkipScoop,
    [switch]$SkipEnhancedTools,
    [switch]$SkipNerdFonts,

    # Legacy flags (backward compatibility) - override Skip flags
    [switch]$InstallEnhancedTools,
    [switch]$InstallNerdFonts
)

# ============================================
# Determine what to install
# ============================================
# Legacy flags override Skip flags for backward compatibility
$ShouldInstallScoop = -not $SkipScoop
$ShouldInstallEnhancedTools = $InstallEnhancedTools -or (-not $SkipEnhancedTools)
$ShouldInstallNerdFonts = $InstallNerdFonts -or (-not $SkipNerdFonts)

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
# 1.5. Install Scoop (if needed)
# ============================================
if ($ShouldInstallScoop) {
    Write-Host "`n📦 Step 1.5: Checking Scoop package manager...`n" -ForegroundColor Yellow

    if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
        Write-Host "  Installing Scoop package manager..." -ForegroundColor Cyan
        Write-Host "  (Required for enhanced tools and Nerd Fonts)" -ForegroundColor Gray
        Write-Host ""

        try {
            # Set execution policy for current user
            Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force -ErrorAction Stop

            # Install scoop
            Invoke-RestMethod get.scoop.sh -ErrorAction Stop | Invoke-Expression

            Write-Host ""
            Write-Host "  ✓ Scoop installed successfully" -ForegroundColor Green
        } catch {
            Write-Host ""
            Write-Host "  ✗ Failed to install Scoop: $_" -ForegroundColor Red
            Write-Host "  You can install it manually later:" -ForegroundColor Gray
            Write-Host "    Set-ExecutionPolicy RemoteSigned -Scope CurrentUser" -ForegroundColor DarkGray
            Write-Host "    irm get.scoop.sh | iex" -ForegroundColor DarkGray
            Write-Host ""
        }
    } else {
        Write-Host "  ✓ Scoop already installed" -ForegroundColor Green
    }
} else {
    Write-Host "`n⏭  Step 1.5: Skipping Scoop installation (-SkipScoop)" -ForegroundColor Gray
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
# 5. Install Enhanced Tools
# ============================================
if ($ShouldInstallEnhancedTools) {
    Write-Host "`n🎨 Step 5: Installing Enhanced Tools...`n" -ForegroundColor Yellow

    # Check if scoop is installed (should be from Step 1.5, but double-check)
    if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
        Write-Host "  ⚠ Scoop not found - cannot install enhanced tools" -ForegroundColor Yellow
        Write-Host "  Run the installer again without -SkipScoop" -ForegroundColor Gray
    } else {
        # Install enhanced tools via scoop
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
} else {
    Write-Host "`n⏭  Step 5: Skipping Enhanced Tools (-SkipEnhancedTools)" -ForegroundColor Gray
}

# ============================================
# 6. Install Nerd Fonts
# ============================================
if ($ShouldInstallNerdFonts) {
    Write-Host "`n🔤 Step 6: Installing Nerd Fonts...`n" -ForegroundColor Yellow

    # Check if scoop is installed (should be from Step 1.5, but double-check)
    if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
        Write-Host "  ⚠ Scoop not found - cannot install Nerd Fonts" -ForegroundColor Yellow
        Write-Host "  Run the installer again without -SkipScoop" -ForegroundColor Gray
    } else {
        # Load the nerd-fonts module
        $NerdFontsModule = Join-Path $ProfileRoot "modules\nerd-fonts.ps1"
        if (Test-Path $NerdFontsModule) {
            . $NerdFontsModule

            # Check if already installed
            $nfCheck = Test-NerdFontInstalled
            if ($nfCheck.Installed) {
                Write-Host "  ✓ Nerd Fonts already installed:" -ForegroundColor Green
                foreach ($font in $nfCheck.Fonts) {
                    Write-Host "    • $font" -ForegroundColor Gray
                }
            } else {
                # Install recommended font (CascadiaCode-NF) in silent mode
                Install-NerdFonts -Silent
            }
        } else {
            Write-Host "  ⚠ Nerd Fonts module not found" -ForegroundColor Yellow
        }
    }
} else {
    Write-Host "`n⏭  Step 6: Skipping Nerd Fonts (-SkipNerdFonts)" -ForegroundColor Gray
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
if ($ShouldInstallEnhancedTools) {
    Write-Host "     • Enhanced tools (bat, eza, etc.) will be available" -ForegroundColor Gray
}
if ($ShouldInstallNerdFonts) {
    Write-Host "     • After restart, configure terminal to use the installed Nerd Font" -ForegroundColor Gray
}
Write-Host ""

$step = 2

if (-not $ShouldInstallEnhancedTools) {
    Write-Host "  $step. 🎨 (Optional) Install enhanced tools later:" -ForegroundColor Cyan
    Write-Host "     • Run: pwsh -File scripts\Install-OhMyPwsh.ps1" -ForegroundColor Gray
    Write-Host "       (enhanced tools are installed by default now)" -ForegroundColor DarkGray
    Write-Host "     • Or in profile: Install-EnhancedTools" -ForegroundColor Gray
    Write-Host ""
    $step++
}

if (-not $ShouldInstallNerdFonts) {
    Write-Host "  $step. 🔤 (Optional) Install Nerd Fonts for better icons:" -ForegroundColor Cyan
    Write-Host "     • Run: pwsh -File scripts\Install-OhMyPwsh.ps1" -ForegroundColor Gray
    Write-Host "       (Nerd Fonts are installed by default now)" -ForegroundColor DarkGray
    Write-Host "     • Or in profile: Install-NerdFonts" -ForegroundColor Gray
    Write-Host "     • Then enable in config.ps1: `$global:OhMyPwsh_UseNerdFonts = `$true" -ForegroundColor Gray
    Write-Host ""
    $step++
}

Write-Host "  $step. 📚 Type 'help' to see available commands" -ForegroundColor Cyan
Write-Host ""
$step++
Write-Host "  $step. ⚙️  Customize your config: code $ConfigPath" -ForegroundColor Cyan
Write-Host ""

Write-Host "="*60 -ForegroundColor Cyan
Write-Host ""
