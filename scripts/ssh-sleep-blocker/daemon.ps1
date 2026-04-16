# ============================================
# SSH Sleep Blocker - daemon
# ============================================
# Prevents Windows from sleeping while SSH sessions are active.
# Polls every 30 s for established connections on port 22 and calls
# SetThreadExecutionState to keep the system awake.
#
# Run via Task Scheduler: pwsh -WindowStyle Hidden -File daemon.ps1

Add-Type @"
using System;
using System.Runtime.InteropServices;

public class SleepBlocker {
    [DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    public static extern uint SetThreadExecutionState(uint esFlags);

    public const uint ES_CONTINUOUS       = 0x80000000;
    public const uint ES_SYSTEM_REQUIRED  = 0x00000001;
    public const uint ES_DISPLAY_REQUIRED = 0x00000002;

    public static void PreventSleep() {
        SetThreadExecutionState(ES_CONTINUOUS | ES_SYSTEM_REQUIRED);
    }

    public static void AllowSleep() {
        SetThreadExecutionState(ES_CONTINUOUS);
    }
}
"@

$logDir       = Join-Path $env:APPDATA 'ssh-sleep-blocker'
$logFile      = Join-Path $logDir 'daemon.log'
$checkInterval = 30  # seconds

if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $Message" | Out-File -FilePath $logFile -Append
}

function Get-ActiveSSHConnections {
    try {
        $connections = Get-NetTCPConnection -LocalPort 22 -State Established -ErrorAction SilentlyContinue
        return @($connections).Count
    } catch {
        return 0
    }
}

Write-Log "SSH Sleep Blocker started"
$wasBlocking = $false

while ($true) {
    $sshCount = Get-ActiveSSHConnections

    if ($sshCount -gt 0) {
        if (-not $wasBlocking) {
            Write-Log "SSH connections detected ($sshCount). Blocking sleep."
            $wasBlocking = $true
        }
        [SleepBlocker]::PreventSleep()
    } else {
        if ($wasBlocking) {
            Write-Log "No SSH connections. Allowing sleep."
            [SleepBlocker]::AllowSleep()
            $wasBlocking = $false
        }
    }

    Start-Sleep -Seconds $checkInterval
}
