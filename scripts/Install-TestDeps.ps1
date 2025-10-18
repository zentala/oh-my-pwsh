<#
.SYNOPSIS
    Install testing dependencies for oh-my-pwsh

.DESCRIPTION
    Installs Pester 5.5.0+ and verifies PowerShell version compatibility.
    This script is safe to run multiple times - it will skip if already installed.

.EXAMPLE
    .\scripts\Install-TestDeps.ps1

.NOTES
    Requires PowerShell 7.0+
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

Write-Host "`n🔧 Installing Testing Dependencies`n" -ForegroundColor Cyan

# Check PowerShell version
Write-Host "Checking PowerShell version... " -NoNewline
$requiredVersion = [Version]"7.0"
if ($PSVersionTable.PSVersion -lt $requiredVersion) {
    Write-Host "✗" -ForegroundColor Red
    Write-Error "PowerShell 7.0+ required. Current version: $($PSVersionTable.PSVersion)"
    exit 1
}
Write-Host "✓ $($PSVersionTable.PSVersion)" -ForegroundColor Green

# Check if Pester is already installed
Write-Host "Checking for Pester... " -NoNewline
$pester = Get-Module -ListAvailable -Name Pester |
    Where-Object { $_.Version -ge [Version]"5.5.0" } |
    Sort-Object Version -Descending |
    Select-Object -First 1

if ($pester) {
    Write-Host "✓ v$($pester.Version) already installed" -ForegroundColor Green
} else {
    Write-Host "not found" -ForegroundColor Yellow

    # Install Pester
    Write-Host "Installing Pester 5.5.0+... " -NoNewline
    try {
        Install-Module -Name Pester -MinimumVersion 5.5.0 -Force -SkipPublisherCheck -Scope CurrentUser
        Write-Host "✓" -ForegroundColor Green

        # Verify installation
        $pester = Get-Module -ListAvailable -Name Pester |
            Where-Object { $_.Version -ge [Version]"5.5.0" } |
            Sort-Object Version -Descending |
            Select-Object -First 1

        if ($pester) {
            Write-Host "  Installed version: $($pester.Version)" -ForegroundColor Gray
        } else {
            Write-Host "✗ Installation verification failed" -ForegroundColor Red
            exit 1
        }
    } catch {
        Write-Host "✗" -ForegroundColor Red
        Write-Error "Failed to install Pester: $_"
        exit 1
    }
}

# Summary
Write-Host "`n✅ Testing dependencies installed successfully`n" -ForegroundColor Green
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Run tests: " -NoNewline -ForegroundColor Gray
Write-Host "./scripts/Invoke-Tests.ps1" -ForegroundColor White
Write-Host "  2. With coverage: " -NoNewline -ForegroundColor Gray
Write-Host "./scripts/Invoke-Tests.ps1 -Coverage" -ForegroundColor White
Write-Host ""
