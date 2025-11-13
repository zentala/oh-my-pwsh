<#
.SYNOPSIS
    Run PSScriptAnalyzer on oh-my-pwsh codebase

.DESCRIPTION
    Performs static code analysis using PSScriptAnalyzer.
    Checks all PowerShell files for code quality issues.

.PARAMETER Fix
    Attempt to auto-fix issues where possible

.PARAMETER Severity
    Minimum severity to report (Error, Warning, Information)
    Default: Warning (shows Errors and Warnings)

.PARAMETER Path
    Specific path to analyze (default: all PowerShell files)

.PARAMETER ExcludeRule
    Additional rules to exclude

.EXAMPLE
    .\scripts\Invoke-Linter.ps1
    Run linter on all files

.EXAMPLE
    .\scripts\Invoke-Linter.ps1 -Fix
    Run linter and auto-fix issues

.EXAMPLE
    .\scripts\Invoke-Linter.ps1 -Severity Error
    Show only errors

.EXAMPLE
    .\scripts\Invoke-Linter.ps1 -Path "modules/logger.ps1"
    Analyze specific file

.NOTES
    Requires PSScriptAnalyzer module
    Run Install-PSScriptAnalyzer.ps1 if not installed
#>

[CmdletBinding()]
param(
    [Parameter()]
    [switch]$Fix,

    [Parameter()]
    [ValidateSet('Error', 'Warning', 'Information')]
    [string]$Severity = 'Warning',

    [Parameter()]
    [string]$Path,

    [Parameter()]
    [string[]]$ExcludeRule
)

$ErrorActionPreference = 'Stop'

# Check PSScriptAnalyzer installation
$analyzer = Get-Module -ListAvailable -Name PSScriptAnalyzer

if (-not $analyzer) {
    Write-Host "✗ PSScriptAnalyzer not found" -ForegroundColor Red
    Write-Host "  Run: ./scripts/Install-PSScriptAnalyzer.ps1" -ForegroundColor Yellow
    exit 1
}

# Import PSScriptAnalyzer
Import-Module PSScriptAnalyzer

# Project root
$projectRoot = Split-Path $PSScriptRoot -Parent

# Settings file
$settingsFile = Join-Path $projectRoot ".PSScriptAnalyzerSettings.psd1"

# Determine paths to analyze
$analyzePaths = @()
if ($Path) {
    $analyzePath = $Path
    if (-not [System.IO.Path]::IsPathRooted($Path)) {
        $analyzePath = Join-Path $projectRoot $Path
    }
    $analyzePaths += $analyzePath
} else {
    # Analyze specific directories (exclude tests, .git, etc.)
    $analyzePaths += @(
        (Join-Path $projectRoot "profile.ps1"),
        (Join-Path $projectRoot "settings"),
        (Join-Path $projectRoot "modules"),
        (Join-Path $projectRoot "scripts")
    )
}

Write-Host "`n🔍 PSScriptAnalyzer" -ForegroundColor Cyan
Write-Host "==================`n" -ForegroundColor Cyan

if ($Fix) {
    Write-Host "⚡ Auto-fix mode enabled" -ForegroundColor Yellow
}

Write-Host "Severity: $Severity" -ForegroundColor Gray
Write-Host "Settings: .PSScriptAnalyzerSettings.psd1`n" -ForegroundColor Gray

# Analyze each path and collect results
$results = @()
foreach ($path in $analyzePaths) {
    if (-not (Test-Path $path)) {
        Write-Host "⚠️  Skipping non-existent path: $path" -ForegroundColor Yellow
        continue
    }

    $params = @{
        Path     = $path
        Settings = $settingsFile
        Recurse  = $true
        Severity = $Severity
    }

    if ($ExcludeRule) {
        $params['ExcludeRule'] = $ExcludeRule
    }

    if ($Fix) {
        $params['Fix'] = $true
    }

    $pathResults = Invoke-ScriptAnalyzer @params
    if ($pathResults) {
        $results += $pathResults
    }
}

# Display results
if (-not $results) {
    Write-Host "✅ No issues found!" -ForegroundColor Green
    Write-Host ""
    exit 0
}

# Group by severity
$errorResults = $results | Where-Object { $_.Severity -eq 'Error' }
$warningResults = $results | Where-Object { $_.Severity -eq 'Warning' }
$infoResults = $results | Where-Object { $_.Severity -eq 'Information' }

# Display grouped results
if ($errorResults) {
    Write-Host "❌ Errors ($($errorResults.Count)):" -ForegroundColor Red
    foreach ($err in $errorResults) {
        Write-Host "  $($err.ScriptName):$($err.Line)" -ForegroundColor Gray
        Write-Host "    [$($err.RuleName)] $($err.Message)" -ForegroundColor Red
    }
    Write-Host ""
}

if ($warningResults) {
    Write-Host "⚠️  Warnings ($($warningResults.Count)):" -ForegroundColor Yellow
    foreach ($warn in $warningResults) {
        Write-Host "  $($warn.ScriptName):$($warn.Line)" -ForegroundColor Gray
        Write-Host "    [$($warn.RuleName)] $($warn.Message)" -ForegroundColor Yellow
    }
    Write-Host ""
}

if ($infoResults) {
    Write-Host "ℹ️  Information ($($infoResults.Count)):" -ForegroundColor Cyan
    foreach ($info in $infoResults) {
        Write-Host "  $($info.ScriptName):$($info.Line)" -ForegroundColor Gray
        Write-Host "    [$($info.RuleName)] $($info.Message)" -ForegroundColor Cyan
    }
    Write-Host ""
}

# Summary
$totalIssues = $results.Count
Write-Host "Total issues: $totalIssues" -ForegroundColor $(if ($errorResults) { 'Red' } elseif ($warningResults) { 'Yellow' } else { 'Cyan' })
Write-Host "  Errors: $($errorResults.Count)" -ForegroundColor Red
Write-Host "  Warnings: $($warningResults.Count)" -ForegroundColor Yellow
Write-Host "  Information: $($infoResults.Count)" -ForegroundColor Cyan
Write-Host ""

if ($Fix) {
    Write-Host "✓ Auto-fix applied where possible" -ForegroundColor Green
    Write-Host "  Re-run to check remaining issues" -ForegroundColor Gray
    Write-Host ""
}

# Exit code
# Only errors fail CI - warnings are informational for profile code
if ($errorResults) {
    exit 1
}

exit 0
