#Requires -Version 7.0
<#
.SYNOPSIS
    cc blocks daemon - triggers a new Claude Code 5-hour block.
    Called by Windows Task Scheduler, not directly by the user.

.ENVIRONMENT
    CC_DEBUG=1              Keep claude stdout visible in logs
    CC_STRICT_VERIFY=1      Exit 1 if ccusage shows no active block
    CC_TEST_NO_CLAUDE=1     Skip claude lookup (for tests)
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ── Config paths ────────────────────────────────────────────────────────────
$ConfigDir  = Join-Path $env:APPDATA 'cc'
$LogFile    = Join-Path $ConfigDir 'cc.log'
$ActivityFile = Join-Path $ConfigDir '.last-activity'

# ── Helpers ─────────────────────────────────────────────────────────────────
function Write-Log {
    param([string]$Message, [string]$Level = 'INFO')
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $line = "[$timestamp] [$Level] $Message"
    Add-Content -Path $LogFile -Value $line -Encoding UTF8
    if ($env:CC_DEBUG -eq '1') { Write-Host $line }
}

function Find-ClaudeBin {
    # 1. PATH
    $bin = Get-Command claude -ErrorAction SilentlyContinue
    if ($bin) { return $bin.Source }

    # 2. Common Windows install locations
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

function Invoke-WithTimeout {
    param([scriptblock]$ScriptBlock, [int]$TimeoutSeconds = 15)

    $job = Start-Job -ScriptBlock $ScriptBlock
    $done = Wait-Job $job -Timeout $TimeoutSeconds

    if (-not $done) {
        Stop-Job $job
        Remove-Job $job -Force
        return @{ Success = $false; Output = ''; ExitCode = -1; Reason = 'timeout' }
    }

    $jobState = $job.State
    $output = Receive-Job $job -ErrorAction SilentlyContinue
    Remove-Job $job -Force

    return @{ Success = ($jobState -eq 'Completed'); Output = $output -join "`n"; ExitCode = 0; Reason = '' }
}

# ── Main ─────────────────────────────────────────────────────────────────────
try {
    New-Item -ItemType Directory -Path $ConfigDir -Force | Out-Null

    # Test mode
    if ($env:CC_TEST_NO_CLAUDE -eq '1') {
        Write-Log 'Test mode: skipping claude lookup'
        exit 0
    }

    # Find claude
    $claudeBin = Find-ClaudeBin
    if (-not $claudeBin) {
        Write-Log 'Claude CLI not found. Install Claude Code: https://claude.ai/code' 'ERROR'
        exit 1
    }
    Write-Log "Using claude: $claudeBin"

    # Trigger new block
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    Write-Log "Triggering new 5-hour block at $timestamp"

    $debug = $env:CC_DEBUG -eq '1'

    # Run claude with timeout — pipe "." as input to trigger a block
    $bin = $claudeBin
    $result = Invoke-WithTimeout -TimeoutSeconds 15 -ScriptBlock {
        $output = "." | & $using:bin 2>&1
        $output
    }

    if ($result.Reason -eq 'timeout') {
        Write-Log 'Claude CLI timed out after 15s' 'WARNING'
        # Timeout is not necessarily failure - claude may have triggered the block
    }
    elseif (-not $result.Success) {
        Write-Log "Claude CLI failed: $($result.Output)" 'ERROR'
    }

    # Optional verification via ccusage
    $verifyFail = $false
    $ccusage = Get-Command ccusage -ErrorAction SilentlyContinue
    if ($ccusage) {
        Start-Sleep -Seconds 1
        $usageOut = (& ccusage 2>$null) -join "`n"
        $usageOut = $usageOut.Trim()

        if ($debug) { Write-Log "[DEBUG] ccusage output: '$usageOut'" }

        if ([string]::IsNullOrEmpty($usageOut)) {
            Write-Log 'Trigger verification inconclusive (ccusage returned empty output)' 'WARNING'
        }
        elseif ($usageOut -match 'No active blocks|Session expired|No active session') {
            $verifyFail = $true
            Write-Log 'ccusage reports no active block after trigger' 'WARNING'
        }
        elseif ($usageOut -match 'Time remaining|Current session|Block \d+ \(Current\)|\d+h \d+m|Active block') {
            Write-Log 'Block verified active via ccusage'
        }
        else {
            Write-Log "ccusage verification inconclusive. Output: $($usageOut.Substring(0, [Math]::Min(100, $usageOut.Length)))" 'WARNING'
        }
    }
    else {
        Write-Log 'ccusage not found; skipping verification' 'WARNING'
    }

    if ($verifyFail -and $env:CC_STRICT_VERIFY -eq '1') {
        Write-Log 'Strict verify: no active block detected, exiting 1' 'ERROR'
        exit 1
    }

    # Save last activity
    Set-Content -Path $ActivityFile -Value $timestamp -Encoding UTF8
    Write-Log "Successfully triggered new 5-hour block at $timestamp"
    exit 0

} catch {
    Write-Log "Unhandled error: $_" 'ERROR'
    exit 1
}
