#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Generate a new test file from template

.DESCRIPTION
    Creates a new Pester test file for a module using a template.
    Automatically determines module name and sets up basic test structure.

.PARAMETER Path
    Path to the module file to create tests for (e.g., modules/logger.ps1)

.PARAMETER Type
    Type of test to create (Unit, Integration, E2E). Default: Unit

.PARAMETER Force
    Overwrite existing test file if it exists

.EXAMPLE
    ./scripts/New-TestFile.ps1 -Path modules/my-module.ps1

    Creates tests/Unit/MyModule.Tests.ps1

.EXAMPLE
    ./scripts/New-TestFile.ps1 -Path modules/git-helpers.ps1 -Type Integration

    Creates tests/Integration/GitHelpers.Tests.ps1

.NOTES
    Template files are in tests/Helpers/Templates/
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Path,

    [Parameter()]
    [ValidateSet('Unit', 'Integration', 'E2E')]
    [string]$Type = 'Unit',

    [Parameter()]
    [switch]$Force
)

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

# Validate module path exists
$modulePath = Join-Path $repoRoot $Path
if (-not (Test-Path $modulePath)) {
    Write-Error "❌ Module not found: $Path"
    exit 1
}

# Extract module name from path
$moduleFile = Split-Path $Path -Leaf
$moduleName = $moduleFile -replace '\.ps1$', ''

# Convert module name to PascalCase for test file
$testFileName = ($moduleName -split '-' | ForEach-Object {
    $_.Substring(0,1).ToUpper() + $_.Substring(1)
}) -join ''

# Determine test file path
$testDir = Join-Path $repoRoot "tests/$Type"
$testFile = Join-Path $testDir "$testFileName.Tests.ps1"

# Check if test file already exists
if ((Test-Path $testFile) -and -not $Force) {
    Write-Host "⚠️  Test file already exists: $testFile" -ForegroundColor Yellow
    $response = Read-Host "   Overwrite? (y/N)"
    if ($response -notmatch '^[Yy]') {
        Write-Host "   Skipping generation" -ForegroundColor DarkGray
        exit 0
    }
}

# Load template
$templateFile = Join-Path $repoRoot "tests/Helpers/Templates/$Type.Tests.ps1.template"
if (-not (Test-Path $templateFile)) {
    Write-Error "❌ Template not found: $templateFile"
    exit 1
}

$template = Get-Content $templateFile -Raw

# Replace placeholders
$testContent = $template `
    -replace '{{MODULE_NAME}}', $testFileName `
    -replace '{{MODULE_PATH}}', $Path

# Create test directory if it doesn't exist
if (-not (Test-Path $testDir)) {
    Write-Host "📁 Creating directory: tests/$Type" -ForegroundColor Cyan
    New-Item -ItemType Directory -Path $testDir -Force | Out-Null
}

# Write test file
try {
    Write-Host "📝 Generating test file..." -ForegroundColor Cyan
    Set-Content -Path $testFile -Value $testContent -Encoding UTF8

    Write-Host ""
    Write-Host "✅ Test file created successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "📄 File: $testFile" -ForegroundColor Cyan
    Write-Host "📦 Module: $Path" -ForegroundColor Cyan
    Write-Host "🧪 Type: $Type" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "📝 Next steps:" -ForegroundColor Cyan
    Write-Host "   1. Edit the test file and add your tests" -ForegroundColor White
    Write-Host "   2. Run tests: ./scripts/Invoke-Tests.ps1 -Filter ""$testFileName*""" -ForegroundColor White
    Write-Host ""

    exit 0
} catch {
    Write-Error "❌ Failed to create test file: $_"
    exit 1
}
