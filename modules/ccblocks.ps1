# ============================================
# ccblocks - Claude Code block scheduler
# Windows Task Scheduler port of github.com/designorant/ccblocks
# ============================================

$script:CcblocksConfigDir  = Join-Path $env:APPDATA 'ccblocks'
$script:CcblocksConfigFile = Join-Path $script:CcblocksConfigDir 'config.json'
$script:CcblocksLogFile    = Join-Path $script:CcblocksConfigDir 'ccblocks.log'
$script:CcblocksActivityFile = Join-Path $script:CcblocksConfigDir '.last-activity'
$script:CcblocksDaemonScript = Join-Path $PSScriptRoot '..\scripts\ccblocks-daemon.ps1'
$script:CcblocksTaskName   = 'ccblocks'
$script:CcblocksPlansDir   = Join-Path $script:CcblocksConfigDir 'plans'
$script:CcblocksPlanDaemonScript = Join-Path $PSScriptRoot '..\scripts\ccblocks-plan-daemon.ps1'
$script:CcblocksPlanTaskPrefix = 'ccblocks-plan-'

# ── Schedule presets ─────────────────────────────────────────────────────────
$script:CcblocksPresets = @{
    '247'  = @{ Hours = @(0, 6, 12, 18);  Label = '24/7 Max Coverage';  Description = '12 AM, 6 AM, 12 PM, 6 PM daily' }
    'work' = @{ Hours = @(9, 14);         Label = 'Work Hours';          Description = '9 AM, 2 PM Mon-Fri'; WeekdaysOnly = $true }
    'night' = @{ Hours = @(18, 23);       Label = 'Night Owl';           Description = '6 PM, 11 PM daily' }
    'zentala' = @{ Hours = @(5, 10, 15, 20); Label = 'Zentala Schedule'; Description = '5 AM, 10 AM, 3 PM, 8 PM — covers 9 AM to 1 AM' }
}

# ── Helpers ──────────────────────────────────────────────────────────────────
function _cc_ok    { param($msg) Write-Host "[OK]  $msg" -ForegroundColor Green }
function _cc_err   { param($msg) Write-Host "[ERR] $msg" -ForegroundColor Red }
function _cc_warn  { param($msg) Write-Host "[!]   $msg" -ForegroundColor Yellow }
function _cc_info  { param($msg) Write-Host "      $msg" -ForegroundColor Cyan }
function _cc_head  { param($msg) Write-Host "`n$msg" -ForegroundColor Blue }

function _cc_read_config {
    if (-not (Test-Path $script:CcblocksConfigFile)) { return $null }
    Get-Content $script:CcblocksConfigFile -Raw | ConvertFrom-Json
}

function _cc_write_config {
    param($Config)
    New-Item -ItemType Directory -Path $script:CcblocksConfigDir -Force | Out-Null
    $Config | ConvertTo-Json -Depth 5 | Set-Content $script:CcblocksConfigFile -Encoding UTF8
}

function _cc_task_exists {
    $null -ne (Get-ScheduledTask -TaskName $script:CcblocksTaskName -ErrorAction SilentlyContinue)
}

function _cc_make_triggers {
    param([int[]]$Hours, [bool]$WeekdaysOnly = $false)

    $triggers = @()
    foreach ($h in $Hours) {
        $time = '{0:D2}:00' -f $h
        if ($WeekdaysOnly) {
            $triggers += New-ScheduledTaskTrigger -Weekly `
                -DaysOfWeek Monday,Tuesday,Wednesday,Thursday,Friday `
                -At $time
        } else {
            $triggers += New-ScheduledTaskTrigger -Daily -At $time
        }
    }
    return $triggers
}

function _cc_register_task {
    param([int[]]$Hours, [bool]$WeekdaysOnly = $false)

    $daemonPath = (Resolve-Path $script:CcblocksDaemonScript).Path
    $action = New-ScheduledTaskAction `
        -Execute 'pwsh.exe' `
        -Argument "-NonInteractive -WindowStyle Hidden -File `"$daemonPath`""

    $triggers = _cc_make_triggers -Hours $Hours -WeekdaysOnly $WeekdaysOnly

    $settings = New-ScheduledTaskSettingsSet `
        -WakeToRun `
        -ExecutionTimeLimit (New-TimeSpan -Minutes 2) `
        -MultipleInstances IgnoreNew `
        -StartWhenAvailable

    # Remove existing task if present
    if (_cc_task_exists) {
        Unregister-ScheduledTask -TaskName $script:CcblocksTaskName -Confirm:$false
    }

    Register-ScheduledTask `
        -TaskName $script:CcblocksTaskName `
        -Action $action `
        -Trigger $triggers `
        -Settings $settings `
        -Description 'ccblocks: auto-trigger Claude Code 5-hour blocks' `
        -RunLevel Limited | Out-Null
}

# ── Subcommands ───────────────────────────────────────────────────────────────

function _ccblocks_setup {
    _cc_head 'ccblocks Setup'

    # Check claude
    $claude = Get-Command claude -ErrorAction SilentlyContinue
    if (-not $claude) {
        _cc_err 'Claude CLI not found. Install Claude Code: https://claude.ai/code'
        return
    }
    _cc_ok "Claude CLI found: $($claude.Source)"

    # Show presets
    Write-Host ''
    Write-Host '  Choose schedule:' -ForegroundColor White
    Write-Host '  1. 24/7 Max Coverage  — 12AM, 6AM, 12PM, 6PM daily (recommended)' -ForegroundColor Gray
    Write-Host '  2. Work Hours         — 9AM, 2PM Mon-Fri' -ForegroundColor Gray
    Write-Host '  3. Night Owl          — 6PM, 11PM daily' -ForegroundColor Gray
    Write-Host '  4. Custom hours       — specify your own (e.g. 0,8,16)' -ForegroundColor Gray
    Write-Host ''

    $choice = Read-Host 'Select [1-4] (default: 1)'
    if ([string]::IsNullOrEmpty($choice)) { $choice = '1' }

    $presetKey = $null
    $customHours = $null

    switch ($choice) {
        '1' { $presetKey = '247' }
        '2' { $presetKey = 'work' }
        '3' { $presetKey = 'night' }
        '4' {
            $input = Read-Host 'Enter hours (0-23, comma-separated, e.g. 0,8,16)'
            $customHours = $input
        }
        default {
            _cc_err "Invalid choice: $choice"
            return
        }
    }

    # Build hours array
    if ($presetKey) {
        $preset = $script:CcblocksPresets[$presetKey]
        $hours = $preset.Hours
        $weekdaysOnly = [bool]$preset.WeekdaysOnly
        $label = $preset.Label
    } else {
        if (-not (_ccblocks_validate_hours $customHours)) { return }
        $hours = $customHours -split ',' | ForEach-Object { [int]$_.Trim() } | Sort-Object
        $weekdaysOnly = $false
        $label = "Custom ($customHours)"
    }

    Write-Host ''
    $confirm = Read-Host "Install '$label' schedule? [Y/n]"
    if ($confirm -match '^[Nn]$') { _cc_ok 'Setup cancelled'; return }

    _cc_register_task -Hours $hours -WeekdaysOnly $weekdaysOnly

    # Save config
    $config = @{
        schedule = @{
            type = if ($presetKey) { 'preset' } else { 'custom' }
            preset = $presetKey
            custom_hours = $hours
            coverage_hours = $hours.Count * 5
        }
    }
    _cc_write_config $config

    Write-Host ''
    _cc_ok "Task Scheduler installed: '$label'"
    _cc_ok 'WakeToRun=true — PC will wake from sleep to trigger'
    _cc_info 'Check status:   ccblocks status'
    _cc_info 'Trigger now:    ccblocks trigger'
    _cc_info 'View logs:      ccblocks logs'
}

function _ccblocks_status {
    _cc_head 'ccblocks Status'

    if (_cc_task_exists) {
        $task = Get-ScheduledTask -TaskName $script:CcblocksTaskName
        $info = Get-ScheduledTaskInfo -TaskName $script:CcblocksTaskName -ErrorAction SilentlyContinue

        _cc_ok "Task Scheduler task: ACTIVE"
        _cc_info "State: $($task.State)"

        if ($info.NextRunTime) {
            _cc_info "Next trigger: $($info.NextRunTime.ToString('yyyy-MM-dd HH:mm'))"
        }
        if ($info.LastRunTime -and $info.LastRunTime.Year -gt 1) {
            _cc_info "Last run:     $($info.LastRunTime.ToString('yyyy-MM-dd HH:mm'))  [result: $($info.LastTaskResult)]"
        }
    } else {
        _cc_warn 'Task Scheduler task: NOT FOUND'
        _cc_info 'Run: ccblocks setup'
    }

    # Config
    $cfg = _cc_read_config
    if ($cfg) {
        Write-Host ''
        _cc_head 'Schedule'
        if ($cfg.schedule.type -eq 'preset') {
            $preset = $script:CcblocksPresets[$cfg.schedule.preset]
            _cc_info "Preset:    $($cfg.schedule.preset) — $($preset.Description)"
            _cc_info "Coverage:  $($cfg.schedule.custom_hours.Count * 5)h/day"
        } else {
            _cc_info "Custom hours: $($cfg.schedule.custom_hours -join ',')"
            _cc_info "Coverage:     $($cfg.schedule.coverage_hours)h/day"
        }
    }

    # Last activity
    if (Test-Path $script:CcblocksActivityFile) {
        $last = Get-Content $script:CcblocksActivityFile -Raw
        Write-Host ''
        _cc_info "Last trigger: $($last.Trim())"
    }

    # Pending plans
    $plans = _cc_plan_read_all
    $pending = ($plans | Where-Object { $_.status -eq 'pending' }).Count
    if ($pending -gt 0) {
        Write-Host ''
        _cc_head 'Plans'
        _cc_info "$pending pending plan(s) — ccblocks plan list"
    }

    Write-Host ''
    _cc_info "Logs: $script:CcblocksLogFile"
    _cc_info 'View: ccblocks logs'
}

function _ccblocks_trigger {
    _cc_info 'Triggering block now...'

    if (-not (Test-Path $script:CcblocksDaemonScript)) {
        _cc_err "Daemon script not found: $script:CcblocksDaemonScript"
        return
    }

    $daemonPath = (Resolve-Path $script:CcblocksDaemonScript).Path
    & pwsh.exe -NonInteractive -File $daemonPath

    if ($LASTEXITCODE -eq 0) {
        _cc_ok 'Block triggered successfully'
    } else {
        _cc_err "Daemon exited with code $LASTEXITCODE"
    }
}

function _ccblocks_schedule {
    param([string]$Action = 'help', [string]$Arg1 = '')

    switch ($Action) {
        'list' {
            _cc_head 'Available Schedules'
            foreach ($key in $script:CcblocksPresets.Keys) {
                $p = $script:CcblocksPresets[$key]
                Write-Host "  $key — $($p.Label)" -ForegroundColor White
                Write-Host "       $($p.Description)" -ForegroundColor Gray
                Write-Host "       Coverage: $($p.Hours.Count * 5)h/day" -ForegroundColor DarkGray
                Write-Host ''
            }
            Write-Host "  custom — specify hours: ccblocks schedule apply custom 0,8,16" -ForegroundColor White
        }
        'apply' {
            if ([string]::IsNullOrEmpty($Arg1)) {
                _cc_err 'Usage: ccblocks schedule apply <247|work|night|custom> [hours]'
                return
            }
            if ($script:CcblocksPresets.ContainsKey($Arg1)) {
                $preset = $script:CcblocksPresets[$Arg1]
                _cc_register_task -Hours $preset.Hours -WeekdaysOnly ([bool]$preset.WeekdaysOnly)
                _cc_write_config @{ schedule = @{ type = 'preset'; preset = $Arg1; custom_hours = $preset.Hours; coverage_hours = $preset.Hours.Count * 5 } }
                _cc_ok "Applied '$Arg1' schedule"
            } elseif ($Arg1 -eq 'custom') {
                $hoursStr = Read-Host 'Enter hours (e.g. 0,8,16)'
                if (-not (_ccblocks_validate_hours $hoursStr)) { return }
                $hours = $hoursStr -split ',' | ForEach-Object { [int]$_.Trim() } | Sort-Object
                _cc_register_task -Hours $hours
                _cc_write_config @{ schedule = @{ type = 'custom'; custom_hours = $hours; coverage_hours = $hours.Count * 5 } }
                _cc_ok "Applied custom schedule: $hoursStr"
            } else {
                _cc_err "Unknown schedule: $Arg1. Use: 247, work, night, custom"
            }
        }
        'pause'  { _ccblocks_pause }
        'resume' { _ccblocks_resume }
        'remove' {
            if (_cc_task_exists) {
                Unregister-ScheduledTask -TaskName $script:CcblocksTaskName -Confirm:$false
                _cc_ok 'Task removed'
            } else {
                _cc_warn 'No task found'
            }
        }
        default {
            Write-Host 'Usage: ccblocks schedule <list|apply|pause|resume|remove>' -ForegroundColor Yellow
        }
    }
}

function _ccblocks_pause {
    if (_cc_task_exists) {
        Disable-ScheduledTask -TaskName $script:CcblocksTaskName | Out-Null
        _cc_ok 'ccblocks paused'
        _cc_info 'Resume: ccblocks resume'
    } else {
        _cc_warn 'No task found. Run: ccblocks setup'
    }
}

function _ccblocks_resume {
    if (_cc_task_exists) {
        Enable-ScheduledTask -TaskName $script:CcblocksTaskName | Out-Null
        _cc_ok 'ccblocks resumed'
    } else {
        _cc_warn 'No task found. Run: ccblocks setup'
    }
}

function _ccblocks_uninstall {
    param([switch]$Force)

    _cc_head 'ccblocks Uninstall'

    if (-not $Force) {
        $confirm = Read-Host 'Remove ccblocks Task Scheduler task? [Y/n]'
        if ($confirm -match '^[Nn]$') { _cc_ok 'Cancelled'; return }
    }

    if (_cc_task_exists) {
        Unregister-ScheduledTask -TaskName $script:CcblocksTaskName -Confirm:$false
        _cc_ok 'Task removed'
    } else {
        _cc_warn 'Task not found (already removed?)'
    }

    # Clean up plan tasks
    $planTasks = Get-ScheduledTask -TaskName "$($script:CcblocksPlanTaskPrefix)*" -ErrorAction SilentlyContinue
    foreach ($pt in $planTasks) {
        Unregister-ScheduledTask -TaskName $pt.TaskName -Confirm:$false
    }
    if ($planTasks) { _cc_ok "Removed $($planTasks.Count) plan task(s)" }

    if (Test-Path $script:CcblocksConfigDir) {
        if (-not $Force) {
            $confirm = Read-Host "Remove config dir ($script:CcblocksConfigDir)? [Y/n]"
        }
        if ($Force -or $confirm -notmatch '^[Nn]$') {
            Remove-Item $script:CcblocksConfigDir -Recurse -Force
            _cc_ok 'Config removed'
        } else {
            _cc_info "Config preserved: $script:CcblocksConfigDir"
        }
    }

    _cc_ok 'Uninstall complete'
}

function _ccblocks_logs {
    param([int]$Last = 50)
    if (Test-Path $script:CcblocksLogFile) {
        Get-Content $script:CcblocksLogFile -Tail $Last
    } else {
        _cc_warn "No log file yet: $script:CcblocksLogFile"
    }
}

function _ccblocks_validate_hours {
    param([string]$HoursStr)
    try {
        $hours = $HoursStr -split ',' | ForEach-Object { [int]$_.Trim() }
    } catch {
        _cc_err "Invalid hours format: $HoursStr"
        return $false
    }
    foreach ($h in $hours) {
        if ($h -lt 0 -or $h -gt 23) { _cc_err "Hour out of range: $h (must be 0-23)"; return $false }
    }
    if ($hours.Count -lt 2) { _cc_err 'Minimum 2 trigger hours required'; return $false }
    if ($hours.Count -gt 4) { _cc_err 'Maximum 4 triggers (24h / 5h blocks = 4.8)'; return $false }

    $sorted = $hours | Sort-Object
    for ($i = 0; $i -lt $sorted.Count - 1; $i++) {
        $gap = $sorted[$i+1] - $sorted[$i]
        if ($gap -lt 5) {
            _cc_err "Hours too close: $($sorted[$i]) and $($sorted[$i+1]) — minimum 5h spacing"
            return $false
        }
    }
    # Wraparound check
    $wrapGap = 24 - $sorted[-1] + $sorted[0]
    if ($wrapGap -lt 5) {
        _cc_err "Wraparound gap too small: $($sorted[-1]) to $($sorted[0]) (next day) = $($wrapGap)h"
        return $false
    }

    return $true
}

function _ccblocks_help {
    Write-Host ''
    Write-Host '  ccblocks — Claude Code block scheduler for Windows' -ForegroundColor Cyan
    Write-Host ''
    Write-Host '  Commands:' -ForegroundColor White
    Write-Host '    ccblocks setup                      Install Task Scheduler job'
    Write-Host '    ccblocks status                     Show task + schedule status'
    Write-Host '    ccblocks trigger                    Trigger a new block now'
    Write-Host '    ccblocks plan "prompt" [--at HH:MM] Schedule Claude task (with wake)'
    Write-Host '    ccblocks plan list                  List scheduled plans'
    Write-Host '    ccblocks plan help                  Full plan usage'
    Write-Host '    ccblocks schedule list              List preset schedules'
    Write-Host '    ccblocks schedule apply <preset>    Apply: 247 | work | night'
    Write-Host '    ccblocks schedule apply custom      Interactive custom hours'
    Write-Host '    ccblocks schedule apply 247         Apply 24/7 preset directly'
    Write-Host '    ccblocks pause                      Disable task temporarily'
    Write-Host '    ccblocks resume                     Re-enable task'
    Write-Host '    ccblocks logs [-Last N]             Tail log file (default: 50)'
    Write-Host '    ccblocks uninstall [-Force]         Remove task + config'
    Write-Host ''
    Write-Host '  Wake from sleep:' -ForegroundColor White
    Write-Host '    Task is registered with WakeToRun=true.'
    Write-Host '    PC wakes from Sleep (S3), runs trigger, returns to sleep.'
    Write-Host '    Hibernation (S4) support depends on BIOS/drivers.'
    Write-Host ''
}

# ── Public entry point ────────────────────────────────────────────────────────
function ccblocks {
    [CmdletBinding()]
    param(
        [Parameter(Position=0)]
        [string]$Command = 'help',

        [Parameter(Position=1)]
        [string]$Arg1 = '',

        [Parameter(Position=2)]
        [string]$Arg2 = '',

        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Rest,

        [switch]$Force,
        [int]$Last = 50
    )

    switch ($Command) {
        'setup'     { _ccblocks_setup }
        'status'    { _ccblocks_status }
        'trigger'   { _ccblocks_trigger }
        'plan'      { _ccblocks_plan -SubArgs ((@($Arg1, $Arg2) + $Rest) | Where-Object { $_ -ne '' }) }
        'schedule'  { _ccblocks_schedule -Action $Arg1 -Arg1 $Arg2 }
        'pause'     { _ccblocks_pause }
        'resume'    { _ccblocks_resume }
        'uninstall' { _ccblocks_uninstall -Force:$Force }
        'logs'      { _ccblocks_logs -Last $Last }
        'help'      { _ccblocks_help }
        default     { _cc_err "Unknown command: $Command"; _ccblocks_help }
    }
}
