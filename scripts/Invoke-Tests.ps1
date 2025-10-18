<#
.SYNOPSIS
    Run tests for oh-my-pwsh

.DESCRIPTION
    Orchestrates Pester test execution with support for different test types,
    coverage reporting, and various output formats.

.PARAMETER Type
    Type of tests to run: Unit, Integration, E2E, All (default: All)

.PARAMETER Coverage
    Generate code coverage report (HTML + XML)

.PARAMETER Fast
    Fast mode - parallel execution, no coverage (for git hooks)

.PARAMETER Watch
    Watch mode - re-run tests when files change

.PARAMETER Filter
    Run only tests matching this filter pattern

.EXAMPLE
    .\scripts\Invoke-Tests.ps1
    Run all tests

.EXAMPLE
    .\scripts\Invoke-Tests.ps1 -Type Unit -Coverage
    Run unit tests with coverage report

.EXAMPLE
    .\scripts\Invoke-Tests.ps1 -Type Unit -Fast
    Run unit tests in fast mode (for pre-commit hook)

.EXAMPLE
    .\scripts\Invoke-Tests.ps1 -Filter "Icon*"
    Run only tests matching "Icon*"

.NOTES
    Requires Pester 5.5.0+
    Run Install-TestDeps.ps1 first if Pester not installed
#>

[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet('Unit', 'Integration', 'E2E', 'All')]
    [string]$Type = 'All',

    [Parameter()]
    [switch]$Coverage,

    [Parameter()]
    [switch]$Fast,

    [Parameter()]
    [switch]$Watch,

    [Parameter()]
    [string]$Filter = "*"
)

$ErrorActionPreference = 'Stop'

# Check Pester installation
$pester = Get-Module -ListAvailable -Name Pester |
    Where-Object { $_.Version -ge [Version]"5.5.0" } |
    Sort-Object Version -Descending |
    Select-Object -First 1

if (-not $pester) {
    Write-Host "✗ Pester 5.5.0+ not found" -ForegroundColor Red
    Write-Host "  Run: ./scripts/Install-TestDeps.ps1" -ForegroundColor Yellow
    exit 1
}

# Import Pester
Import-Module Pester -MinimumVersion 5.5.0

# Project root
$projectRoot = Split-Path $PSScriptRoot -Parent

# Configure Pester
$config = [PesterConfiguration]::Default

# Set test path based on type
switch ($Type) {
    'Unit'        { $config.Run.Path = Join-Path $projectRoot "tests/Unit" }
    'Integration' { $config.Run.Path = Join-Path $projectRoot "tests/Integration" }
    'E2E'         { $config.Run.Path = Join-Path $projectRoot "tests/E2E" }
    'All'         { $config.Run.Path = Join-Path $projectRoot "tests" }
}

# Filter
if ($Filter -ne "*") {
    $config.Filter.FullName = "*$Filter*"
}

# Output configuration
$config.Output.Verbosity = 'Detailed'
$config.Run.Exit = $false
$config.Run.PassThru = $true

# Fast mode optimizations
if ($Fast) {
    Write-Host "⚡ Fast mode enabled (parallel, no coverage)" -ForegroundColor Cyan
    $config.Run.Parallel = $true
    $config.CodeCoverage.Enabled = $false
    $config.Output.Verbosity = 'Normal'
}

# Coverage configuration
if ($Coverage -and -not $Fast) {
    $config.CodeCoverage.Enabled = $true
    $config.CodeCoverage.Path = @(
        (Join-Path $projectRoot "settings/*.ps1"),
        (Join-Path $projectRoot "modules/*.ps1"),
        (Join-Path $projectRoot "profile.ps1")
    )

    $coverageDir = Join-Path $projectRoot "tests/Coverage"
    if (-not (Test-Path $coverageDir)) {
        New-Item -ItemType Directory -Path $coverageDir | Out-Null
    }

    $config.CodeCoverage.OutputPath = Join-Path $coverageDir "coverage.xml"
    $config.CodeCoverage.OutputFormat = 'JaCoCo'

    Write-Host "📊 Coverage report will be generated" -ForegroundColor Cyan
}

# Watch mode
if ($Watch) {
    Write-Host "👀 Watch mode enabled - watching for file changes..." -ForegroundColor Cyan
    Write-Host "   Press Ctrl+C to stop`n" -ForegroundColor DarkGray

    # Function to run tests
    $runTests = {
        Clear-Host
        Write-Host "🔄 Running tests... ($(Get-Date -Format 'HH:mm:ss'))`n" -ForegroundColor Cyan

        $result = Invoke-Pester -Configuration $config

        Write-Host "`n" -NoNewline
        if ($result.FailedCount -eq 0) {
            Write-Host "✅ All tests passed!" -ForegroundColor Green
        } else {
            Write-Host "❌ $($result.FailedCount) test(s) failed" -ForegroundColor Red
        }

        Write-Host "   Total: $($result.TotalCount) | " -NoNewline -ForegroundColor Gray
        Write-Host "Passed: $($result.PassedCount) | " -NoNewline -ForegroundColor Green
        if ($result.FailedCount -gt 0) {
            Write-Host "Failed: $($result.FailedCount) | " -NoNewline -ForegroundColor Red
        }
        Write-Host "Skipped: $($result.SkippedCount)`n" -ForegroundColor Yellow

        Write-Host "👀 Watching for changes... (Ctrl+C to stop)" -ForegroundColor Cyan
    }

    # Run tests initially
    & $runTests

    # Setup file watcher
    $watcher = New-Object System.IO.FileSystemWatcher
    $watcher.Path = $projectRoot
    $watcher.Filter = "*.ps1"
    $watcher.IncludeSubdirectories = $true
    $watcher.EnableRaisingEvents = $true

    # Debounce mechanism
    $lastRun = [DateTime]::MinValue
    $debounceMs = 2000

    $action = {
        $path = $Event.SourceEventArgs.FullPath
        $changeType = $Event.SourceEventArgs.ChangeType

        # Ignore coverage and .git files
        if ($path -like "*\tests\Coverage\*" -or $path -like "*\.git\*") {
            return
        }

        # Debounce - only run if enough time has passed
        $now = Get-Date
        if (($now - $script:lastRun).TotalMilliseconds -lt $script:debounceMs) {
            return
        }
        $script:lastRun = $now

        Write-Host "`n📝 File changed: $(Split-Path $path -Leaf)" -ForegroundColor Yellow
        Start-Sleep -Milliseconds 500  # Wait for file to be written
        & $script:runTests
    }

    # Register events
    Register-ObjectEvent -InputObject $watcher -EventName Changed -Action $action | Out-Null
    Register-ObjectEvent -InputObject $watcher -EventName Created -Action $action | Out-Null
    Register-ObjectEvent -InputObject $watcher -EventName Deleted -Action $action | Out-Null

    try {
        # Keep script running
        while ($true) {
            Start-Sleep -Seconds 1
        }
    } finally {
        # Cleanup
        $watcher.Dispose()
        Get-EventSubscriber | Unregister-Event
    }

    exit 0
}

# Run tests
Write-Host "`n🧪 Running $Type tests...`n" -ForegroundColor Cyan

$result = Invoke-Pester -Configuration $config

# Display results
Write-Host "`n" -NoNewline
if ($result.FailedCount -eq 0) {
    Write-Host "✅ All tests passed!" -ForegroundColor Green
} else {
    Write-Host "❌ $($result.FailedCount) test(s) failed" -ForegroundColor Red
}

Write-Host "   Total: $($result.TotalCount) | " -NoNewline -ForegroundColor Gray
Write-Host "Passed: $($result.PassedCount) | " -NoNewline -ForegroundColor Green
if ($result.FailedCount -gt 0) {
    Write-Host "Failed: $($result.FailedCount) | " -NoNewline -ForegroundColor Red
}
Write-Host "Skipped: $($result.SkippedCount)" -ForegroundColor Yellow

# Coverage summary
if ($Coverage -and -not $Fast) {
    if ($result.CodeCoverage) {
        $coverage = $result.CodeCoverage
        $coveredCommands = $coverage.CommandsExecutedCount
        $totalCommands = $coverage.CommandsAnalyzedCount

        if ($totalCommands -gt 0) {
            $coveragePercent = [math]::Round(($coveredCommands / $totalCommands) * 100, 2)

            Write-Host "`n📊 Code Coverage: " -NoNewline -ForegroundColor Cyan
            if ($coveragePercent -ge 75) {
                Write-Host "$coveragePercent%" -ForegroundColor Green
            } elseif ($coveragePercent -ge 50) {
                Write-Host "$coveragePercent%" -ForegroundColor Yellow
            } else {
                Write-Host "$coveragePercent%" -ForegroundColor Red
            }

            Write-Host "   Covered: $coveredCommands / $totalCommands commands" -ForegroundColor Gray
            Write-Host "   Report: tests/Coverage/coverage.xml" -ForegroundColor Gray
        }
    }
}

Write-Host ""

# Exit with appropriate code
if ($result.FailedCount -gt 0) {
    exit 1
}

exit 0
