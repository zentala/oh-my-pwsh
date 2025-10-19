#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Install git hooks for oh-my-pwsh development

.DESCRIPTION
    Copies pre-commit hook from .github/hooks/ to .git/hooks/
    The pre-commit hook runs unit tests before allowing commits.

    Hook is OPTIONAL and can be bypassed with: git commit --no-verify

.EXAMPLE
    ./scripts/Install-GitHooks.ps1

.NOTES
    See ADR-004: Git Hooks Optional for rationale
#>

[CmdletBinding()]
param()

# Get repository root
$repoRoot = git rev-parse --show-toplevel 2>$null
if (-not $repoRoot) {
    Write-Error "❌ Not in a git repository"
    exit 1
}

# Convert to Windows path if needed
if ($IsWindows -or $PSVersionTable.PSVersion.Major -le 5) {
    $repoRoot = $repoRoot -replace '/', '\'
}

Set-Location $repoRoot

# Paths
$sourceHookWrapper = Join-Path $repoRoot ".github/hooks/pre-commit"
$sourceHookPs1 = Join-Path $repoRoot ".github/hooks/pre-commit.ps1"
$gitHooksDir = Join-Path $repoRoot ".git/hooks"
$targetHookWrapper = Join-Path $gitHooksDir "pre-commit"
$targetHookPs1 = Join-Path $gitHooksDir "pre-commit.ps1"

# Verify source hooks exist
if (-not (Test-Path $sourceHookWrapper)) {
    Write-Error "❌ Source hook wrapper not found: $sourceHookWrapper"
    exit 1
}
if (-not (Test-Path $sourceHookPs1)) {
    Write-Error "❌ Source hook script not found: $sourceHookPs1"
    exit 1
}

# Create .git/hooks directory if it doesn't exist
if (-not (Test-Path $gitHooksDir)) {
    Write-Host "📁 Creating .git/hooks directory..." -ForegroundColor Cyan
    New-Item -ItemType Directory -Path $gitHooksDir -Force | Out-Null
}

# Check if hook already exists
if ((Test-Path $targetHookWrapper) -or (Test-Path $targetHookPs1)) {
    Write-Host "⚠️  Pre-commit hook already exists" -ForegroundColor Yellow
    $response = Read-Host "   Overwrite? (y/N)"
    if ($response -notmatch '^[Yy]') {
        Write-Host "   Skipping installation" -ForegroundColor DarkGray
        exit 0
    }
}

# Copy hooks (both wrapper and PowerShell script)
try {
    Write-Host "📋 Installing pre-commit hook..." -ForegroundColor Cyan
    Copy-Item -Path $sourceHookWrapper -Destination $targetHookWrapper -Force
    Copy-Item -Path $sourceHookPs1 -Destination $targetHookPs1 -Force

    # Make executable (Unix-like systems)
    if (-not $IsWindows -and $PSVersionTable.PSVersion.Major -gt 5) {
        chmod +x $targetHookWrapper 2>$null
    }

    Write-Host ""
    Write-Host "✅ Git hooks installed successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "📝 What happens now:" -ForegroundColor Cyan
    Write-Host "   • Unit tests run automatically before each commit" -ForegroundColor White
    Write-Host "   • Commit is blocked if tests fail" -ForegroundColor White
    Write-Host "   • Takes ~10-20 seconds" -ForegroundColor White
    Write-Host ""
    Write-Host "🔓 Bypass hook when needed:" -ForegroundColor Cyan
    Write-Host "   git commit --no-verify -m ""WIP: quick save""" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "🗑️  Uninstall anytime:" -ForegroundColor Cyan
    Write-Host "   Remove-Item .git/hooks/pre-commit*" -ForegroundColor DarkGray
    Write-Host ""

    exit 0
} catch {
    Write-Error "❌ Failed to install hooks: $_"
    exit 1
}
