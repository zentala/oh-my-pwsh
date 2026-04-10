# ============================================
# POWER TOOLS - Unified power management
# ============================================
# Single command `power` to schedule sleep/hibernate/shutdown/restart
# via Windows Task Scheduler. Type `power` alone for an interactive menu.
#
# Usage:
#   power                       Interactive menu (status + actions)
#   power <action> <time>       Schedule action
#   power <action> now          Execute immediately (with confirm)
#   power status                List scheduled actions
#   power cancel                Cancel all scheduled actions
#   power cancel <id>           Cancel one (id from `power status`)
#   power help                  Show help
#
# Action aliases:
#   hibernate : hibe, hib, h
#   sleep     : slp, s, nap
#   shutdown  : off, shut, down
#   restart   : reboot, rb, r
#
# Time formats:
#   60          60 minutes
#   90m         90 minutes
#   1h          1 hour
#   2h30m       2.5 hours
#   23:30       at 23:30 today (or tomorrow if past)
#   now         immediately

$script:PowerTaskPrefix = "OhMyPwsh-Power"

# ============================================
# Helpers
# ============================================

function Resolve-PowerAction {
    param([string]$Token)
    if (-not $Token) { return $null }
    switch -Regex ($Token.ToLower()) {
        '^(hibernate|hibe|hib|h)$'    { return 'hibernate' }
        '^(sleep|slp|s|nap)$'         { return 'sleep' }
        '^(shutdown|off|shut|down)$'  { return 'shutdown' }
        '^(restart|reboot|rb|r)$'     { return 'restart' }
        '^(cancel|unpower|clear|abort)$' { return 'cancel' }
        '^(status|list|ls)$'          { return 'status' }
        '^(help|--help|-h|\?)$'       { return 'help' }
        '^(menu)$'                    { return 'menu' }
        default                       { return $null }
    }
}

function ConvertTo-PowerMinutes {
    <#
    .SYNOPSIS
    Parse "60", "90m", "1h", "2h30m", "23:30", "now" into integer minutes from now.
    Returns $null if input cannot be parsed.
    #>
    param([string]$Token)
    if (-not $Token) { return $null }
    $t = $Token.ToLower().Trim()

    if ($t -eq 'now') { return 0 }

    # HH:MM absolute time
    if ($t -match '^(\d{1,2}):(\d{2})$') {
        $hour = [int]$matches[1]
        $min  = [int]$matches[2]
        if ($hour -gt 23 -or $min -gt 59) { return $null }
        $target = (Get-Date).Date.AddHours($hour).AddMinutes($min)
        if ($target -le (Get-Date)) { $target = $target.AddDays(1) }
        return [int][math]::Ceiling(($target - (Get-Date)).TotalMinutes)
    }

    # 1h30m / 2h / 45m / 60
    if ($t -match '^(?:(\d+)h)?(?:(\d+)m)?$' -and ($matches[1] -or $matches[2])) {
        $h = if ($matches[1]) { [int]$matches[1] } else { 0 }
        $m = if ($matches[2]) { [int]$matches[2] } else { 0 }
        return ($h * 60) + $m
    }

    if ($t -match '^\d+$') { return [int]$t }

    return $null
}

function Get-PowerCommand {
    param([ValidateSet('hibernate','sleep','shutdown','restart')][string]$Action)
    switch ($Action) {
        'hibernate' { return 'shutdown.exe /h' }
        'shutdown'  { return 'shutdown.exe /s /t 0' }
        'restart'   { return 'shutdown.exe /r /t 0' }
        'sleep'     { return 'rundll32.exe powrprof.dll,SetSuspendState 0,1,0' }
    }
}

function Test-GsudoAvailable {
    return [bool](Get-Command gsudo -ErrorAction SilentlyContinue)
}

function Invoke-WithElevation {
    <#
    .SYNOPSIS
    Run a command, retry through gsudo if it fails (when gsudo is available).
    Returns $true on success.
    #>
    param([string]$Command)

    $null = cmd.exe /c "$Command" 2>&1
    if ($LASTEXITCODE -eq 0) { return $true }

    if (Test-GsudoAvailable) {
        Write-StatusMessage -Role "info" -Message "Elevation required - retrying via gsudo"
        $null = gsudo cmd.exe /c "$Command" 2>&1
        return ($LASTEXITCODE -eq 0)
    }

    Write-StatusMessage -Role "error" -Message "Command failed and gsudo not available - install with: scoop install gsudo"
    return $false
}

# ============================================
# Schedule queries
# ============================================

function Get-PowerSchedule {
    <#
    .SYNOPSIS
    Returns scheduled power actions as objects: Id, Name, Action, NextRun, MinutesLeft.
    Automatically cleans up stale tasks (already executed or missing NextRunTime).
    #>
    $tasks = @(Get-ScheduledTask -TaskName "$($script:PowerTaskPrefix)-*" -ErrorAction SilentlyContinue)
    if (-not $tasks -or $tasks.Count -eq 0) { return @() }

    $now = Get-Date
    $results = @()
    $i = 0

    $sorted = $tasks | ForEach-Object {
        $info = Get-ScheduledTaskInfo $_
        [PSCustomObject]@{ Task = $_; Info = $info }
    } | Sort-Object { $_.Info.NextRunTime }

    foreach ($entry in $sorted) {
        $task = $entry.Task
        $info = $entry.Info
        $action = ($task.TaskName -split '-')[2]  # OhMyPwsh-Power-<action>-<id>

        # Auto-cleanup: remove stale tasks (no NextRunTime or already past)
        if (-not $info.NextRunTime -or $info.NextRunTime -lt $now) {
            $deleteCmd = "schtasks /delete /tn `"$($task.TaskName)`" /f"
            Invoke-WithElevation -Command $deleteCmd | Out-Null
            continue
        }

        $i++
        $minutesLeft = [int][math]::Ceiling(($info.NextRunTime - $now).TotalMinutes)

        $results += [PSCustomObject]@{
            Id          = $i
            Name        = $task.TaskName
            Action      = $action
            NextRun     = $info.NextRunTime
            MinutesLeft = $minutesLeft
        }
    }

    return $results
}

# ============================================
# Schedule create / delete
# ============================================

function New-PowerSchedule {
    param(
        [Parameter(Mandatory)][ValidateSet('hibernate','sleep','shutdown','restart')]
        [string]$Action,
        [Parameter(Mandatory)][int]$Minutes
    )

    if ($Minutes -lt 0) {
        Write-StatusMessage -Role "error" -Message "Time must be >= 0"
        return
    }

    if ($Minutes -eq 0) {
        Invoke-PowerNow -Action $Action
        return
    }

    $when     = (Get-Date).AddMinutes($Minutes)
    $time     = $when.ToString("HH:mm")
    $sameDay  = $when.Date -eq (Get-Date).Date
    $dateArg  = if ($sameDay) { "" } else { "/sd $($when.ToString('MM/dd/yyyy'))" }
    $taskId   = [guid]::NewGuid().ToString('N').Substring(0,8)
    $taskName = "$($script:PowerTaskPrefix)-$Action-$taskId"
    $cmd      = Get-PowerCommand -Action $Action

    $createCmd = "schtasks /create /sc once /st $time $dateArg /tn `"$taskName`" /tr `"$cmd`" /f"
    if (-not (Invoke-WithElevation -Command $createCmd)) {
        Write-StatusMessage -Role "error" -Message "Failed to schedule $Action"
        return
    }

    $whenLabel = if ($sameDay) { "at $time" } else { "at $time on $($when.ToString('MM/dd'))" }
    $segments = @(
        @{ Text = "Scheduled "; Color = "White" }
        @{ Text = $Action;       Color = "Yellow" }
        @{ Text = " in ";        Color = "White" }
        @{ Text = (Format-PowerDuration $Minutes); Color = "Cyan" }
        @{ Text = " ($whenLabel)"; Color = "DarkGray" }
    )
    Write-StatusMessage -Role "success" -Message $segments
}

function Remove-PowerSchedule {
    param(
        [string]$Target  # task name, numeric id, or 'all' / $null
    )

    $schedule = Get-PowerSchedule
    if ($schedule.Count -eq 0) {
        Write-StatusMessage -Role "info" -Message "No scheduled power actions"
        return
    }

    $toRemove = @()
    if (-not $Target -or $Target -eq 'all') {
        # Confirm if more than one
        if ($schedule.Count -gt 1) {
            if (-not (Confirm-PowerAction -Message "Cancel all $($schedule.Count) scheduled actions?")) {
                Write-StatusMessage -Role "info" -Message "Cancelled"
                return
            }
        }
        $toRemove = $schedule
    }
    elseif ($Target -match '^\d+$') {
        $id = [int]$Target
        $toRemove = @($schedule | Where-Object { $_.Id -eq $id })
        if ($toRemove.Count -eq 0) {
            Write-StatusMessage -Role "warning" -Message "No scheduled action with id $id"
            return
        }
    }
    else {
        $toRemove = @($schedule | Where-Object { $_.Name -eq $Target })
        if ($toRemove.Count -eq 0) {
            Write-StatusMessage -Role "warning" -Message "No task named $Target"
            return
        }
    }

    foreach ($task in $toRemove) {
        $deleteCmd = "schtasks /delete /tn `"$($task.Name)`" /f"
        if (Invoke-WithElevation -Command $deleteCmd) {
            $segments = @(
                @{ Text = "Cancelled "; Color = "White" }
                @{ Text = $task.Action; Color = "Yellow" }
                @{ Text = " (was at $($task.NextRun.ToString('HH:mm')))"; Color = "DarkGray" }
            )
            Write-StatusMessage -Role "warning" -Message $segments
        }
    }
}

function Invoke-PowerNow {
    param([Parameter(Mandatory)][string]$Action)

    if (-not (Confirm-PowerAction -Message "Execute $Action NOW?")) {
        Write-StatusMessage -Role "info" -Message "Cancelled"
        return
    }

    $cmd = Get-PowerCommand -Action $Action
    Write-StatusMessage -Role "warning" -Message "Executing $Action..."
    if (-not (Invoke-WithElevation -Command $cmd)) {
        Write-StatusMessage -Role "error" -Message "Failed to execute $Action"
    }
}

# ============================================
# UI - status / menu / confirm / help
# ============================================

function Format-PowerDuration {
    param([int]$Minutes)
    if ($Minutes -lt 60) { return "$Minutes min" }
    $h = [math]::Floor($Minutes / 60)
    $m = $Minutes % 60
    if ($m -eq 0) { return "${h}h" }
    return "${h}h ${m}m"
}

function Show-PowerStatus {
    $schedule = Get-PowerSchedule
    if ($schedule.Count -eq 0) {
        Write-StatusMessage -Role "info" -Message "No scheduled power actions"
        return
    }

    Write-Host ""
    Write-Host "  Scheduled power actions:" -ForegroundColor White
    foreach ($s in $schedule) {
        $left = if ($null -ne $s.MinutesLeft) { Format-PowerDuration $s.MinutesLeft } else { "?" }
        $when = if ($s.NextRun) { $s.NextRun.ToString("HH:mm") } else { "?" }
        Write-Host ("    [{0}] {1,-10} in {2,-10} (at {3})" -f $s.Id, $s.Action, $left, $when) -ForegroundColor Gray
    }
    Write-Host ""
}

function Show-PowerHelp {
    Write-Host ""
    Write-Host "  power - Schedule sleep / hibernate / shutdown / restart" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  USAGE" -ForegroundColor White
    Write-Host "    power                        Interactive menu" -ForegroundColor Gray
    Write-Host "    power <action> <time>        Schedule" -ForegroundColor Gray
    Write-Host "    power <action> now           Execute immediately" -ForegroundColor Gray
    Write-Host "    power status                 List scheduled" -ForegroundColor Gray
    Write-Host "    power cancel [id|all]        Cancel scheduled" -ForegroundColor Gray
    Write-Host "    power help                   This help" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  ACTIONS" -ForegroundColor White
    Write-Host "    hibernate   aliases: hibe, hib, h" -ForegroundColor Gray
    Write-Host "    sleep       aliases: slp, s, nap" -ForegroundColor Gray
    Write-Host "    shutdown    aliases: off, shut, down" -ForegroundColor Gray
    Write-Host "    restart     aliases: reboot, rb, r" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  TIME FORMATS" -ForegroundColor White
    Write-Host "    60        60 minutes" -ForegroundColor Gray
    Write-Host "    90m       90 minutes" -ForegroundColor Gray
    Write-Host "    1h        1 hour" -ForegroundColor Gray
    Write-Host "    2h30m     2.5 hours" -ForegroundColor Gray
    Write-Host "    23:30     at 23:30 today/tomorrow" -ForegroundColor Gray
    Write-Host "    now       immediately (with confirm)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  EXAMPLES" -ForegroundColor White
    Write-Host "    power hibe 60                hibernate in 60 minutes" -ForegroundColor DarkGray
    Write-Host "    power off 23:30              shutdown at 23:30" -ForegroundColor DarkGray
    Write-Host "    power slp 1h30m              sleep in 1h30m" -ForegroundColor DarkGray
    Write-Host "    power cancel 2               cancel scheduled action #2" -ForegroundColor DarkGray
    Write-Host ""
}

function Test-SpectreAvailable {
    return [bool](Get-Module -ListAvailable -Name PwshSpectreConsole -ErrorAction SilentlyContinue)
}

function Confirm-PowerAction {
    param([string]$Message)
    if (Test-SpectreAvailable) {
        if (-not (Get-Module PwshSpectreConsole)) { Import-Module PwshSpectreConsole -ErrorAction SilentlyContinue }
        return (Read-SpectreConfirm -Prompt $Message)
    }
    $reply = Read-Host "$Message [y/N]"
    return ($reply -match '^(y|yes)$')
}

function Show-PowerMenu {
    Show-PowerStatus

    $hasSpectre = Test-SpectreAvailable
    if ($hasSpectre -and -not (Get-Module PwshSpectreConsole)) {
        Import-Module PwshSpectreConsole -ErrorAction SilentlyContinue
    }

    $choices = @(
        "Schedule hibernate"
        "Schedule sleep"
        "Schedule shutdown"
        "Schedule restart"
        "Cancel a scheduled action"
        "Cancel all"
        "Show help"
        "Exit"
    )

    $choice = if ($hasSpectre) {
        Read-SpectreSelection -Title "What do you want to do?" -Choices $choices
    } else {
        Write-Host "  What do you want to do?" -ForegroundColor White
        for ($i = 0; $i -lt $choices.Count; $i++) {
            Write-Host ("    {0}. {1}" -f ($i+1), $choices[$i]) -ForegroundColor Gray
        }
        $reply = Read-Host "  Choice [1-$($choices.Count)]"
        if ($reply -match '^\d+$' -and [int]$reply -ge 1 -and [int]$reply -le $choices.Count) {
            $choices[[int]$reply - 1]
        } else { "Exit" }
    }

    switch ($choice) {
        "Exit"          { return }
        "Show help"     { Show-PowerHelp; return }
        "Cancel all"    { Remove-PowerSchedule -Target 'all'; return }
        "Cancel a scheduled action" {
            $schedule = Get-PowerSchedule
            if ($schedule.Count -eq 0) {
                Write-StatusMessage -Role "info" -Message "Nothing to cancel"
                return
            }
            $items = $schedule | ForEach-Object { "[$($_.Id)] $($_.Action) at $($_.NextRun.ToString('HH:mm'))" }
            $pick = if ($hasSpectre) {
                Read-SpectreSelection -Title "Which one to cancel?" -Choices $items
            } else {
                Write-Host ""
                for ($i = 0; $i -lt $items.Count; $i++) {
                    Write-Host ("    {0}. {1}" -f ($i+1), $items[$i]) -ForegroundColor Gray
                }
                $r = Read-Host "  Choice"
                if ($r -match '^\d+$') { $items[[int]$r - 1] } else { return }
            }
            if ($pick -match '^\[(\d+)\]') { Remove-PowerSchedule -Target $matches[1] }
            return
        }
        default {
            $action = ($choice -replace 'Schedule ', '').Trim()
            $timeInput = if ($hasSpectre) {
                Read-SpectreText -Prompt "In how much time? (e.g. 60, 1h30m, 23:30, now)" -DefaultAnswer "60"
            } else {
                $r = Read-Host "  In how much time? (e.g. 60, 1h30m, 23:30, now) [60]"
                if (-not $r) { "60" } else { $r }
            }
            $minutes = ConvertTo-PowerMinutes $timeInput
            if ($null -eq $minutes) {
                Write-StatusMessage -Role "error" -Message "Could not parse time: $timeInput"
                return
            }
            New-PowerSchedule -Action $action -Minutes $minutes
        }
    }
}

# ============================================
# Main dispatcher
# ============================================

function Invoke-Power {
    [CmdletBinding()]
    param([Parameter(ValueFromRemainingArguments = $true)]$Args)

    # No args -> interactive menu
    if (-not $Args -or $Args.Count -eq 0) {
        Show-PowerMenu
        return
    }

    # Normalize tokens
    $tokens = @($Args | ForEach-Object { "$_" })

    # Single arg: status / help / cancel / action-without-time
    if ($tokens.Count -eq 1) {
        $resolved = Resolve-PowerAction $tokens[0]
        switch ($resolved) {
            'help'   { Show-PowerHelp; return }
            'status' { Show-PowerStatus; return }
            'menu'   { Show-PowerMenu; return }
            'cancel' { Remove-PowerSchedule; return }
            $null    {
                Write-StatusMessage -Role "error" -Message "Unknown command: $($tokens[0]) - try 'power help'"
                return
            }
            default {
                Write-StatusMessage -Role "warning" -Message "Missing time - try 'power $resolved 60'"
                return
            }
        }
    }

    # cancel <id>
    if ((Resolve-PowerAction $tokens[0]) -eq 'cancel') {
        Remove-PowerSchedule -Target $tokens[1]
        return
    }

    # Two args: <action> <time> OR <time> <action>
    if ($tokens.Count -eq 2) {
        $a = Resolve-PowerAction $tokens[0]
        $b = Resolve-PowerAction $tokens[1]

        if ($a -and $a -notin @('cancel','status','help','menu')) {
            $minutes = ConvertTo-PowerMinutes $tokens[1]
            if ($null -eq $minutes) {
                Write-StatusMessage -Role "error" -Message "Could not parse time: $($tokens[1])"
                return
            }
            New-PowerSchedule -Action $a -Minutes $minutes
            return
        }

        if ($b -and $b -notin @('cancel','status','help','menu')) {
            $minutes = ConvertTo-PowerMinutes $tokens[0]
            if ($null -eq $minutes) {
                Write-StatusMessage -Role "error" -Message "Could not parse time: $($tokens[0])"
                return
            }
            New-PowerSchedule -Action $b -Minutes $minutes
            return
        }

        Write-StatusMessage -Role "error" -Message "Could not parse: $($tokens -join ' ') - try 'power help'"
        return
    }

    Write-StatusMessage -Role "error" -Message "Too many arguments - try 'power help'"
}

Set-Alias -Name power -Value Invoke-Power -Scope Global -Force
