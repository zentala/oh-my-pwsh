# ============================================
# cc blocks - Claude Code block scheduler subcommands
# Depends on: cc/main.ps1 (loaded first)
# ============================================

function _cc_blocks_dispatch {
    param(
        [string]$Command = 'help',
        [string]$Arg1 = '',
        [string]$Arg2 = '',
        [switch]$Force,
        [int]$Last = 50
    )

    switch ($Command) {
        'setup'     { _cc_blocks_setup }
        'status'    { _cc_blocks_status }
        'trigger'   { _cc_blocks_trigger }
        'schedule'  { _cc_blocks_schedule -Action $Arg1 -Arg1 $Arg2 }
        'pause'     { _cc_blocks_pause }
        'resume'    { _cc_blocks_resume }
        'uninstall' { _cc_blocks_uninstall -Force:$Force }
        'logs'      { _cc_blocks_logs -Last $Last }
        'help'      { _cc_blocks_help }
        ''          { _cc_blocks_help }
        default     { _cc_err "Unknown blocks command: $Command"; _cc_blocks_help }
    }
}

function _cc_blocks_setup {
    _cc_head 'cc blocks Setup'

    $claude = Get-Command claude -ErrorAction SilentlyContinue
    if (-not $claude) {
        _cc_err 'Claude CLI not found. Install Claude Code: https://claude.ai/code'
        return
    }
    _cc_ok "Claude CLI found: $($claude.Source)"

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

    if ($presetKey) {
        $preset = $script:CcPresets[$presetKey]
        $hours = $preset.Hours
        $weekdaysOnly = [bool]$preset.WeekdaysOnly
        $label = $preset.Label
    } else {
        if (-not (_cc_validate_hours $customHours)) { return }
        $hours = $customHours -split ',' | ForEach-Object { [int]$_.Trim() } | Sort-Object
        $weekdaysOnly = $false
        $label = "Custom ($customHours)"
    }

    Write-Host ''
    $confirm = Read-Host "Install '$label' schedule? [Y/n]"
    if ($confirm -match '^[Nn]$') { _cc_ok 'Setup cancelled'; return }

    _cc_register_task -Hours $hours -WeekdaysOnly $weekdaysOnly

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

    # Check sleep/hibernate config
    _cc_check_sleep_config

    _cc_info 'Check status:   cc blocks status'
    _cc_info 'Trigger now:    cc blocks trigger'
    _cc_info 'View logs:      cc blocks logs'
}

function _cc_blocks_status {
    _cc_head 'cc blocks Status'

    if (_cc_task_exists) {
        $task = Get-ScheduledTask -TaskName $script:CcTaskName
        $info = Get-ScheduledTaskInfo -TaskName $script:CcTaskName -ErrorAction SilentlyContinue

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
        _cc_info 'Run: cc blocks setup'
    }

    $cfg = _cc_read_config
    if ($cfg) {
        Write-Host ''
        _cc_head 'Schedule'
        if ($cfg.schedule.type -eq 'preset') {
            $preset = $script:CcPresets[$cfg.schedule.preset]
            _cc_info "Preset:    $($cfg.schedule.preset) — $($preset.Description)"
            _cc_info "Coverage:  $($cfg.schedule.custom_hours.Count * 5)h/day"
        } else {
            _cc_info "Custom hours: $($cfg.schedule.custom_hours -join ',')"
            _cc_info "Coverage:     $($cfg.schedule.coverage_hours)h/day"
        }
    }

    if (Test-Path $script:CcActivityFile) {
        $last = Get-Content $script:CcActivityFile -Raw
        Write-Host ''
        _cc_info "Last trigger: $($last.Trim())"
    }

    # Pending plans
    $plans = _cc_plan_read_all
    $pending = ($plans | Where-Object { $_.status -eq 'pending' }).Count
    if ($pending -gt 0) {
        Write-Host ''
        _cc_head 'Plans'
        _cc_info "$pending pending plan(s) — cc plan list"
    }

    Write-Host ''
    _cc_info "Logs: $script:CcLogFile"
    _cc_info 'View: cc blocks logs'
}

function _cc_blocks_trigger {
    _cc_info 'Triggering block now...'

    if (-not (Test-Path $script:CcDaemonScript)) {
        _cc_err "Daemon script not found: $script:CcDaemonScript"
        return
    }

    $daemonPath = (Resolve-Path $script:CcDaemonScript).Path
    & pwsh.exe -NonInteractive -File $daemonPath

    if ($LASTEXITCODE -eq 0) {
        _cc_ok 'Block triggered successfully'
    } else {
        _cc_err "Daemon exited with code $LASTEXITCODE"
    }
}

function _cc_blocks_schedule {
    param([string]$Action = 'help', [string]$Arg1 = '')

    switch ($Action) {
        'list' {
            _cc_head 'Available Schedules'
            foreach ($key in $script:CcPresets.Keys) {
                $p = $script:CcPresets[$key]
                Write-Host "  $key — $($p.Label)" -ForegroundColor White
                Write-Host "       $($p.Description)" -ForegroundColor Gray
                Write-Host "       Coverage: $($p.Hours.Count * 5)h/day" -ForegroundColor DarkGray
                Write-Host ''
            }
            Write-Host "  custom — specify hours: cc blocks schedule apply custom 0,8,16" -ForegroundColor White
        }
        'apply' {
            if ([string]::IsNullOrEmpty($Arg1)) {
                _cc_err 'Usage: cc blocks schedule apply <247|work|night|custom> [hours]'
                return
            }
            if ($script:CcPresets.ContainsKey($Arg1)) {
                $preset = $script:CcPresets[$Arg1]
                _cc_register_task -Hours $preset.Hours -WeekdaysOnly ([bool]$preset.WeekdaysOnly)
                _cc_write_config @{ schedule = @{ type = 'preset'; preset = $Arg1; custom_hours = $preset.Hours; coverage_hours = $preset.Hours.Count * 5 } }
                _cc_ok "Applied '$Arg1' schedule"
            } elseif ($Arg1 -eq 'custom') {
                $hoursStr = Read-Host 'Enter hours (e.g. 0,8,16)'
                if (-not (_cc_validate_hours $hoursStr)) { return }
                $hours = $hoursStr -split ',' | ForEach-Object { [int]$_.Trim() } | Sort-Object
                _cc_register_task -Hours $hours
                _cc_write_config @{ schedule = @{ type = 'custom'; custom_hours = $hours; coverage_hours = $hours.Count * 5 } }
                _cc_ok "Applied custom schedule: $hoursStr"
            } else {
                _cc_err "Unknown schedule: $Arg1. Use: 247, work, night, custom"
            }
        }
        'pause'  { _cc_blocks_pause }
        'resume' { _cc_blocks_resume }
        'remove' {
            if (_cc_task_exists) {
                Unregister-ScheduledTask -TaskName $script:CcTaskName -Confirm:$false
                _cc_ok 'Task removed'
            } else {
                _cc_warn 'No task found'
            }
        }
        default {
            Write-Host 'Usage: cc blocks schedule <list|apply|pause|resume|remove>' -ForegroundColor Yellow
        }
    }
}

function _cc_blocks_pause {
    if (_cc_task_exists) {
        Disable-ScheduledTask -TaskName $script:CcTaskName | Out-Null
        _cc_ok 'Blocks paused'
        _cc_info 'Resume: cc blocks resume'
    } else {
        _cc_warn 'No task found. Run: cc blocks setup'
    }
}

function _cc_blocks_resume {
    if (_cc_task_exists) {
        Enable-ScheduledTask -TaskName $script:CcTaskName | Out-Null
        _cc_ok 'Blocks resumed'
    } else {
        _cc_warn 'No task found. Run: cc blocks setup'
    }
}

function _cc_blocks_uninstall {
    param([switch]$Force)

    _cc_head 'cc blocks Uninstall'

    if (-not $Force) {
        $confirm = Read-Host 'Remove cc blocks Task Scheduler task? [Y/n]'
        if ($confirm -match '^[Nn]$') { _cc_ok 'Cancelled'; return }
    }

    if (_cc_task_exists) {
        Unregister-ScheduledTask -TaskName $script:CcTaskName -Confirm:$false
        _cc_ok 'Task removed'
    } else {
        _cc_warn 'Task not found (already removed?)'
    }

    # Clean up plan tasks
    $planTasks = Get-ScheduledTask -TaskName "$($script:CcPlanTaskPrefix)*" -ErrorAction SilentlyContinue
    foreach ($pt in $planTasks) {
        Unregister-ScheduledTask -TaskName $pt.TaskName -Confirm:$false
    }
    if ($planTasks) { _cc_ok "Removed $($planTasks.Count) plan task(s)" }

    if (Test-Path $script:CcConfigDir) {
        if (-not $Force) {
            $confirm = Read-Host "Remove config dir ($script:CcConfigDir)? [Y/n]"
        }
        if ($Force -or $confirm -notmatch '^[Nn]$') {
            Remove-Item $script:CcConfigDir -Recurse -Force
            _cc_ok 'Config removed'
        } else {
            _cc_info "Config preserved: $script:CcConfigDir"
        }
    }

    _cc_ok 'Uninstall complete'
}

function _cc_blocks_logs {
    param([int]$Last = 50)
    if (Test-Path $script:CcLogFile) {
        Get-Content $script:CcLogFile -Tail $Last
    } else {
        _cc_warn "No log file yet: $script:CcLogFile"
    }
}

function _cc_blocks_help {
    Write-Host ''
    Write-Host '  cc blocks — Claude Code block scheduler' -ForegroundColor Cyan
    Write-Host ''
    Write-Host '  Commands:' -ForegroundColor White
    Write-Host '    cc blocks setup                       Install Task Scheduler job'
    Write-Host '    cc blocks status                      Show task + schedule status'
    Write-Host '    cc blocks trigger                     Trigger a new block now'
    Write-Host '    cc blocks schedule list               List preset schedules'
    Write-Host '    cc blocks schedule apply <preset>     Apply: 247 | work | night'
    Write-Host '    cc blocks schedule apply custom       Interactive custom hours'
    Write-Host '    cc blocks pause                       Disable task temporarily'
    Write-Host '    cc blocks resume                      Re-enable task'
    Write-Host '    cc blocks logs [-Last N]              Tail log file (default: 50)'
    Write-Host '    cc blocks uninstall [-Force]          Remove task + config'
    Write-Host ''
    Write-Host '  Wake from sleep:' -ForegroundColor White
    Write-Host '    Task is registered with WakeToRun=true.'
    Write-Host '    PC wakes from Sleep (S3), runs trigger, returns to sleep.'
    Write-Host '    Hibernation (S4) does NOT support wake timers.'
    Write-Host ''
}
