# ============================================
# Power Tools test doubles
# ============================================
# These helpers keep power-tool tests isolated from native power commands and
# Windows Task Scheduler. They intentionally expose command arguments so tests
# can assert the safety boundary and exact scheduler commands.

function New-PowerTaskDouble {
    param([Parameter(Mandatory)][string]$TaskName)

    [PSCustomObject]@{ TaskName = $TaskName }
}

function New-PowerTaskInfoDouble {
    param([AllowNull()][object]$NextRunTime)

    [PSCustomObject]@{ NextRunTime = $NextRunTime }
}

function New-PowerScheduleDouble {
    param(
        [Parameter(Mandatory)][int]$Id,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$Action,
        [Parameter(Mandatory)][datetime]$NextRun,
        [int]$MinutesLeft = 0
    )

    [PSCustomObject]@{
        Id          = $Id
        Name        = $Name
        Action      = $Action
        NextRun     = $NextRun
        MinutesLeft = $MinutesLeft
    }
}

function New-PowerCommandRecorder {
    [System.Collections.Generic.List[string]]::new()
}

function Assert-PowerCommandIsSafe {
    param([Parameter(Mandatory)][string]$Command)

    if ($Command -match '(?i)\b(cmd\.exe|shutdown\.exe|rundll32\.exe|schtasks)\b') {
        throw "Unexpected real power command invocation: $Command"
    }
}

function Initialize-PowerExternalSafetyDouble {
    <#
    .SYNOPSIS
    Replace the native process boundary with a fail-fast recorder.

    .DESCRIPTION
    A test that calls Invoke-WithElevation without replacing the higher-level
    function will fail immediately instead of touching the host. The returned
    recorder contains the process path and arguments that were requested.
    #>
    $script:PowerExternalCommandRecorder = [System.Collections.Generic.List[string]]::new()
    Mock Invoke-PowerProcess {
        param([string]$FilePath, [string[]]$ArgumentList)
        $command = "$FilePath $($ArgumentList -join ' ')"
        $script:PowerExternalCommandRecorder.Add($command)
        throw "Blocked external process in test: $command"
    }
    return $script:PowerExternalCommandRecorder
}
