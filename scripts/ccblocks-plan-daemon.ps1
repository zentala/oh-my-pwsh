#Requires -Version 7.0
<#
.SYNOPSIS
    ccblocks plan daemon - runs Claude Code with a saved prompt in a saved directory.
    Called by Windows Task Scheduler (one-shot), not directly by the user.

.PARAMETER PlanFile
    Path to the plan JSON file in %APPDATA%\ccblocks\plans\

.ENVIRONMENT
    CCBLOCKS_DEBUG=1  Show verbose output
#>

param(
    [Parameter(Mandatory)]
    [string]$PlanFile
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ── Config ─────────────────────────────────────────────────────────────────
$ConfigDir = Join-Path $env:APPDATA 'ccblocks'
$PlansDir  = Join-Path $ConfigDir 'plans'

# ── Helpers ────────────────────────────────────────────────────────────────
function Write-PlanLog {
    param([string]$Message, [string]$Level = 'INFO')
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $line = "[$timestamp] [$Level] $Message"
    if ($script:PlanLogFile) {
        Add-Content -Path $script:PlanLogFile -Value $line -Encoding UTF8
    }
    if ($env:CCBLOCKS_DEBUG -eq '1') { Write-Host $line }
}

function Find-ClaudeBin {
    $bin = Get-Command claude -ErrorAction SilentlyContinue
    if ($bin) { return $bin.Source }

    $candidates = @(
        "$env:LOCALAPPDATA\Programs\claude\claude.exe",
        "$env:LOCALAPPDATA\Claude\claude.exe",
        "$env:APPDATA\npm\claude.cmd",
        "$env:APPDATA\npm\claude",
        "$env:ProgramFiles\claude\claude.exe"
    )
    foreach ($c in $candidates) {
        if (Test-Path $c) { return $c }
    }
    return $null
}

function Update-PlanStatus {
    param([PSCustomObject]$Plan, [string]$Status, [int]$ExitCode = -1)
    $Plan.status = $Status
    $Plan.completedAt = (Get-Date).ToString('o')
    $Plan.exitCode = $ExitCode
    $Plan | ConvertTo-Json -Depth 5 | Set-Content $PlanFile -Encoding UTF8
}

# ── Main ───────────────────────────────────────────────────────────────────
try {
    # Read plan
    if (-not (Test-Path $PlanFile)) {
        Write-Error "Plan file not found: $PlanFile"
        exit 1
    }

    $plan = Get-Content $PlanFile -Raw | ConvertFrom-Json
    $script:PlanLogFile = Join-Path $PlansDir $plan.logFile

    Write-PlanLog "Starting plan $($plan.id): $($plan.prompt.Substring(0, [Math]::Min(80, $plan.prompt.Length)))"

    # Validate status
    if ($plan.status -ne 'pending') {
        Write-PlanLog "Plan status is '$($plan.status)', skipping" 'WARNING'
        exit 0
    }

    # Mark running
    $plan.status = 'running'
    $plan | ConvertTo-Json -Depth 5 | Set-Content $PlanFile -Encoding UTF8

    # Find claude
    $claudeBin = Find-ClaudeBin
    if (-not $claudeBin) {
        Write-PlanLog 'Claude CLI not found' 'ERROR'
        Update-PlanStatus $plan 'failed'
        exit 1
    }
    Write-PlanLog "Using claude: $claudeBin"

    # Validate working directory
    if (-not (Test-Path $plan.workingDirectory)) {
        Write-PlanLog "Working directory not found: $($plan.workingDirectory)" 'ERROR'
        Update-PlanStatus $plan 'failed'
        exit 1
    }

    # Build claude arguments
    $claudeArgs = @('-p', $plan.prompt, '--output-format', 'text')

    if ($plan.resumeSession) {
        $claudeArgs += '--resume', $plan.resumeSession
    }

    if ($plan.autoEdit) {
        $claudeArgs += '--dangerously-skip-permissions'
    }

    # Run claude in the saved working directory
    $outputPath = Join-Path $PlansDir $plan.outputFile
    Write-PlanLog "Running claude in: $($plan.workingDirectory)"
    Write-PlanLog "Args: $($claudeArgs -join ' ')"

    Push-Location $plan.workingDirectory
    try {
        $output = & $claudeBin @claudeArgs 2>&1
        $runExitCode = $LASTEXITCODE
    } finally {
        Pop-Location
    }

    # Save output
    $output | Set-Content $outputPath -Encoding UTF8
    Write-PlanLog "Output saved to: $outputPath"

    # Update status
    if ($runExitCode -eq 0) {
        Update-PlanStatus $plan 'completed' $runExitCode
        Write-PlanLog "Plan $($plan.id) completed successfully"
    } else {
        Update-PlanStatus $plan 'failed' $runExitCode
        Write-PlanLog "Plan $($plan.id) failed with exit code $runExitCode" 'ERROR'
    }

    exit $runExitCode

} catch {
    Write-PlanLog "Unhandled error: $_" 'ERROR'
    if ($plan) {
        Update-PlanStatus $plan 'failed'
    }
    exit 1
}
