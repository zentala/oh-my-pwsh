#!/usr/bin/env pwsh
#
# oh-my-pwsh pre-commit hook
#
# This hook runs unit tests before allowing a commit.
# It helps catch breaking changes early.
#
# OPTIONAL: This hook is bypassable with --no-verify
#   git commit --no-verify -m "WIP: quick save"
#
# Installation:
#   ./scripts/Install-GitHooks.ps1
#

# Navigate to repository root
$repoRoot = git rev-parse --show-toplevel
if (-not $repoRoot) {
    Write-Error "Not in a git repository"
    exit 1
}

Set-Location $repoRoot

# Check if tests exist
$testScript = Join-Path $repoRoot "scripts/Invoke-Tests.ps1"
if (-not (Test-Path $testScript)) {
    Write-Host "⚠️  Test script not found, skipping tests" -ForegroundColor Yellow
    exit 0
}

# Display header
Write-Host ""
Write-Host "🧪 Running pre-commit tests..." -ForegroundColor Cyan
Write-Host "   (bypass with: git commit --no-verify)" -ForegroundColor DarkGray
Write-Host ""

# Run unit tests only (fast)
try {
    $startTime = Get-Date

    # Run tests with minimal output
    & $testScript -Type Unit -Fast

    $exitCode = $LASTEXITCODE
    $duration = (Get-Date) - $startTime

    if ($exitCode -eq 0) {
        Write-Host ""
        Write-Host "✅ All unit tests passed in $([math]::Round($duration.TotalSeconds, 1))s" -ForegroundColor Green
        Write-Host ""
        exit 0
    } else {
        Write-Host ""
        Write-Host "❌ Tests failed - commit blocked" -ForegroundColor Red
        Write-Host ""
        Write-Host "Fix the failing tests or bypass with:" -ForegroundColor Yellow
        Write-Host "  git commit --no-verify -m 'your message'" -ForegroundColor DarkGray
        Write-Host ""
        exit 1
    }
} catch {
    Write-Host ""
    Write-Host "⚠️  Error running tests: $_" -ForegroundColor Yellow
    Write-Host "   Allowing commit to proceed" -ForegroundColor DarkGray
    Write-Host ""
    exit 0
}
