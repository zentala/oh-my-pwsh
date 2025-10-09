# =====================================================
# Install Dependencies for pwsh-profile
# =====================================================
# Checks and installs all required tools and modules
# Run with: pwsh -ExecutionPolicy Bypass -File install-dependencies.ps1

Write-Host "`n🚀 pwsh-profile - Dependency Installer`n" -ForegroundColor Cyan

# Helper function to check if command exists
function Test-CommandExists {
    param($command)
    $null -ne (Get-Command $command -ErrorAction SilentlyContinue)
}

# Helper function to check if module is installed
function Test-ModuleInstalled {
    param($moduleName)
    $null -ne (Get-Module -ListAvailable $moduleName)
}

# Track what was installed
$installed = @()
$alreadyInstalled = @()
$failed = @()

Write-Host "📦 Checking binary dependencies...`n" -ForegroundColor Yellow

# Check Oh My Posh
Write-Host "  Checking Oh My Posh... " -NoNewline
if (Test-CommandExists "oh-my-posh") {
    Write-Host "✓ Already installed" -ForegroundColor Green
    $alreadyInstalled += "Oh My Posh"
} else {
    Write-Host "Installing..." -ForegroundColor Yellow
    try {
        winget install JanDeDobbeleer.OhMyPosh --accept-source-agreements --accept-package-agreements
        $installed += "Oh My Posh"
        Write-Host "  ✓ Oh My Posh installed" -ForegroundColor Green
    } catch {
        Write-Host "  ✗ Failed to install Oh My Posh" -ForegroundColor Red
        $failed += "Oh My Posh"
    }
}

# Check fzf
Write-Host "  Checking fzf... " -NoNewline
if (Test-CommandExists "fzf") {
    Write-Host "✓ Already installed" -ForegroundColor Green
    $alreadyInstalled += "fzf"
} else {
    Write-Host "Installing..." -ForegroundColor Yellow
    try {
        winget install fzf --accept-source-agreements --accept-package-agreements
        $installed += "fzf"
        Write-Host "  ✓ fzf installed" -ForegroundColor Green
    } catch {
        Write-Host "  ✗ Failed to install fzf" -ForegroundColor Red
        $failed += "fzf"
    }
}

# Check zoxide
Write-Host "  Checking zoxide... " -NoNewline
if (Test-CommandExists "zoxide") {
    Write-Host "✓ Already installed" -ForegroundColor Green
    $alreadyInstalled += "zoxide"
} else {
    Write-Host "Installing..." -ForegroundColor Yellow
    try {
        winget install ajeetdsouza.zoxide --accept-source-agreements --accept-package-agreements
        $installed += "zoxide"
        Write-Host "  ✓ zoxide installed" -ForegroundColor Green
    } catch {
        Write-Host "  ✗ Failed to install zoxide" -ForegroundColor Red
        $failed += "zoxide"
    }
}

# Check gsudo
Write-Host "  Checking gsudo... " -NoNewline
if (Test-CommandExists "gsudo") {
    Write-Host "✓ Already installed" -ForegroundColor Green
    $alreadyInstalled += "gsudo"
} else {
    Write-Host "Installing..." -ForegroundColor Yellow
    try {
        winget install gerardog.gsudo --accept-source-agreements --accept-package-agreements
        $installed += "gsudo"
        Write-Host "  ✓ gsudo installed" -ForegroundColor Green
    } catch {
        Write-Host "  ✗ Failed to install gsudo" -ForegroundColor Red
        $failed += "gsudo"
    }
}

Write-Host "`n📚 Checking PowerShell modules...`n" -ForegroundColor Yellow

# Check PSReadLine
Write-Host "  Checking PSReadLine... " -NoNewline
if (Test-ModuleInstalled "PSReadLine") {
    Write-Host "✓ Already installed" -ForegroundColor Green
    $alreadyInstalled += "PSReadLine"
} else {
    Write-Host "Installing..." -ForegroundColor Yellow
    try {
        Install-Module -Name PSReadLine -Force -Scope CurrentUser -AllowClobber
        $installed += "PSReadLine"
        Write-Host "  ✓ PSReadLine installed" -ForegroundColor Green
    } catch {
        Write-Host "  ✗ Failed to install PSReadLine" -ForegroundColor Red
        $failed += "PSReadLine"
    }
}

# Check posh-git
Write-Host "  Checking posh-git... " -NoNewline
if (Test-ModuleInstalled "posh-git") {
    Write-Host "✓ Already installed" -ForegroundColor Green
    $alreadyInstalled += "posh-git"
} else {
    Write-Host "Installing..." -ForegroundColor Yellow
    try {
        Install-Module -Name posh-git -Scope CurrentUser -Force
        $installed += "posh-git"
        Write-Host "  ✓ posh-git installed" -ForegroundColor Green
    } catch {
        Write-Host "  ✗ Failed to install posh-git" -ForegroundColor Red
        $failed += "posh-git"
    }
}

# Check Terminal-Icons
Write-Host "  Checking Terminal-Icons... " -NoNewline
if (Test-ModuleInstalled "Terminal-Icons") {
    Write-Host "✓ Already installed" -ForegroundColor Green
    $alreadyInstalled += "Terminal-Icons"
} else {
    Write-Host "Installing..." -ForegroundColor Yellow
    try {
        Install-Module -Name Terminal-Icons -Scope CurrentUser -Force
        $installed += "Terminal-Icons"
        Write-Host "  ✓ Terminal-Icons installed" -ForegroundColor Green
    } catch {
        Write-Host "  ✗ Failed to install Terminal-Icons" -ForegroundColor Red
        $failed += "Terminal-Icons"
    }
}

# Check PSFzf
Write-Host "  Checking PSFzf... " -NoNewline
if (Test-ModuleInstalled "PSFzf") {
    Write-Host "✓ Already installed" -ForegroundColor Green
    $alreadyInstalled += "PSFzf"
} else {
    Write-Host "Installing..." -ForegroundColor Yellow
    try {
        Install-Module -Name PSFzf -Scope CurrentUser -Force
        $installed += "PSFzf"
        Write-Host "  ✓ PSFzf installed" -ForegroundColor Green
    } catch {
        Write-Host "  ✗ Failed to install PSFzf" -ForegroundColor Red
        $failed += "PSFzf"
    }
}

# Summary
Write-Host "`n" + "="*60 -ForegroundColor Cyan
Write-Host "📊 Installation Summary" -ForegroundColor Cyan
Write-Host "="*60 -ForegroundColor Cyan

if ($installed.Count -gt 0) {
    Write-Host "`n✅ Newly installed ($($installed.Count)):" -ForegroundColor Green
    $installed | ForEach-Object { Write-Host "   - $_" -ForegroundColor Green }
}

if ($alreadyInstalled.Count -gt 0) {
    Write-Host "`n✓ Already installed ($($alreadyInstalled.Count)):" -ForegroundColor Gray
    $alreadyInstalled | ForEach-Object { Write-Host "   - $_" -ForegroundColor Gray }
}

if ($failed.Count -gt 0) {
    Write-Host "`n❌ Failed to install ($($failed.Count)):" -ForegroundColor Red
    $failed | ForEach-Object { Write-Host "   - $_" -ForegroundColor Red }
}

Write-Host "`n" + "="*60 -ForegroundColor Cyan

if ($installed.Count -gt 0) {
    Write-Host "`n⚠️  Please restart PowerShell to use newly installed tools!" -ForegroundColor Yellow
    Write-Host "   Some tools may need PATH refresh.`n" -ForegroundColor Yellow
}

if ($failed.Count -eq 0) {
    Write-Host "🎉 All dependencies are ready!" -ForegroundColor Green
    Write-Host "   You can now use the pwsh-profile.`n" -ForegroundColor Green
} else {
    Write-Host "⚠️  Some dependencies failed to install." -ForegroundColor Yellow
    Write-Host "   Try installing them manually or check your internet connection.`n" -ForegroundColor Yellow
}

# Optional: Oh My Stats
Write-Host "📌 Optional: Oh My Stats" -ForegroundColor Cyan
Write-Host "   Clone: git clone https://github.com/zentala/oh-my-stats.git C:\code\oh-my-stats" -ForegroundColor Gray
Write-Host "   Already configured in profile.ps1`n" -ForegroundColor Gray
