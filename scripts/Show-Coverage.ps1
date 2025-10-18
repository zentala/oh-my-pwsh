<#
.SYNOPSIS
    Display code coverage summary from tests

.DESCRIPTION
    Parses coverage.xml and displays coverage percentage

.EXAMPLE
    .\scripts\Show-Coverage.ps1
#>

$ErrorActionPreference = 'Stop'

$coverageFile = Join-Path (Split-Path $PSScriptRoot -Parent) "tests/Coverage/coverage.xml"

if (-not (Test-Path $coverageFile)) {
    Write-Host "❌ Coverage file not found: $coverageFile" -ForegroundColor Red
    Write-Host "   Run tests with -Coverage first:" -ForegroundColor Yellow
    Write-Host "   ./scripts/Invoke-Tests.ps1 -Coverage" -ForegroundColor White
    exit 1
}

try {
    [xml]$coverage = Get-Content $coverageFile

    $lineCoverage = $coverage.report.counter | Where-Object { $_.type -eq 'LINE' }
    $covered = [int]$lineCoverage.covered
    $missed = [int]$lineCoverage.missed
    $total = $covered + $missed
    $percent = if ($total -gt 0) { [math]::Round(($covered / $total) * 100, 2) } else { 0 }

    Write-Host "`n📊 Code Coverage Report`n" -ForegroundColor Cyan

    Write-Host "Coverage: " -NoNewline
    if ($percent -ge 75) {
        Write-Host "$percent%" -ForegroundColor Green
    } elseif ($percent -ge 50) {
        Write-Host "$percent%" -ForegroundColor Yellow
    } else {
        Write-Host "$percent%" -ForegroundColor Red
    }

    Write-Host "Covered:  $covered / $total lines" -ForegroundColor Gray
    Write-Host "Missed:   $missed lines" -ForegroundColor Gray

    Write-Host "`nReport location:" -ForegroundColor Cyan
    Write-Host "  $coverageFile" -ForegroundColor Gray

    Write-Host ""

} catch {
    Write-Host "❌ Error parsing coverage file: $_" -ForegroundColor Red
    exit 1
}
