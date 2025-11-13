<#
.SYNOPSIS
    Install PSScriptAnalyzer for code quality checks

.DESCRIPTION
    Installs PSScriptAnalyzer module for static code analysis.
    Can be run standalone or as part of development setup.

.PARAMETER Force
    Force reinstall even if already installed

.EXAMPLE
    .\scripts\Install-PSScriptAnalyzer.ps1
    Install PSScriptAnalyzer

.EXAMPLE
    .\scripts\Install-PSScriptAnalyzer.ps1 -Force
    Force reinstall PSScriptAnalyzer

.NOTES
    Part of oh-my-pwsh development tooling
#>

[CmdletBinding()]
param(
    [Parameter()]
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

Write-Host "`n🔍 PSScriptAnalyzer Installation" -ForegroundColor Cyan
Write-Host "================================`n" -ForegroundColor Cyan

# Check if already installed
$analyzer = Get-Module -ListAvailable -Name PSScriptAnalyzer |
    Sort-Object Version -Descending |
    Select-Object -First 1

if ($analyzer -and -not $Force) {
    Write-Host "✓ PSScriptAnalyzer already installed: v$($analyzer.Version)" -ForegroundColor Green
    exit 0
}

if ($analyzer -and $Force) {
    Write-Host "! Force reinstall requested" -ForegroundColor Yellow
    Write-Host "  Current version: v$($analyzer.Version)" -ForegroundColor Gray
}

# Install PSScriptAnalyzer
try {
    Write-Host "📦 Installing PSScriptAnalyzer..." -ForegroundColor Cyan

    $installParams = @{
        Name               = 'PSScriptAnalyzer'
        Repository         = 'PSGallery'
        Scope              = 'CurrentUser'
        Force              = $true
        AllowClobber       = $true
        SkipPublisherCheck = $true
    }

    Install-Module @installParams | Out-Null

    # Verify installation
    $installed = Get-Module -ListAvailable -Name PSScriptAnalyzer |
        Sort-Object Version -Descending |
        Select-Object -First 1

    if ($installed) {
        Write-Host "✓ PSScriptAnalyzer installed successfully: v$($installed.Version)" -ForegroundColor Green
    } else {
        Write-Host "✗ Installation verification failed" -ForegroundColor Red
        exit 1
    }
}
catch {
    Write-Host "✗ Installation failed: $_" -ForegroundColor Red
    exit 1
}

Write-Host "`n✓ Ready to use! Run:" -ForegroundColor Green
Write-Host "  ./scripts/Invoke-Linter.ps1" -ForegroundColor Yellow
Write-Host ""

exit 0
