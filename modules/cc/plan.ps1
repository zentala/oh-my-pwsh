# ============================================
# cc plan - schedule Claude tasks with wake-from-sleep
# Depends on: cc/main.ps1 (loaded first, provides shared vars & helpers)
# ============================================

# ── Plan helpers ─────────────────────────────────────────────────────────────

function _cc_plan_generate_id {
    param([datetime]$ScheduledAt)
    $base = $ScheduledAt.ToString('yyyyMMdd-HHmm')
    $existing = Join-Path $script:CcPlansDir "plan-$base.json"
    if (-not (Test-Path $existing)) { return $base }
    for ($i = 2; $i -le 9; $i++) {
        $candidate = "$base-$i"
        $path = Join-Path $script:CcPlansDir "plan-$candidate.json"
        if (-not (Test-Path $path)) { return $candidate }
    }
    _cc_err 'Too many plans at the same time'; return $null
}

function _cc_plan_auto_time {
    # Try ccusage for block expiry
    $ccusage = Get-Command ccusage -ErrorAction SilentlyContinue
    if ($ccusage) {
        $usageOut = (& ccusage 2>$null) -join "`n"
        if ($usageOut -match '(\d+)h\s+(\d+)m') {
            $hours = [int]$Matches[1]
            $minutes = [int]$Matches[2]
            $expiry = (Get-Date).AddHours($hours).AddMinutes($minutes + 5)
            _cc_info "Current block expires in ${hours}h ${minutes}m"
            return $expiry
        }
    }

    # Fallback: next full hour (min 10 min from now)
    $now = Get-Date
    $nextHour = $now.Date.AddHours($now.Hour + 1)
    if (($nextHour - $now).TotalMinutes -lt 10) {
        $nextHour = $nextHour.AddHours(1)
    }
    return $nextHour
}

function _cc_plan_register_task {
    param([hashtable]$Plan)

    $daemonPath = (Resolve-Path $script:CcPlanDaemonScript).Path
    $planFile = Join-Path $script:CcPlansDir "plan-$($Plan.id).json"

    $action = New-ScheduledTaskAction `
        -Execute 'pwsh.exe' `
        -Argument "-NonInteractive -WindowStyle Hidden -File `"$daemonPath`" -PlanFile `"$planFile`""

    $trigger = New-ScheduledTaskTrigger -Once -At $Plan.scheduledAt

    $settings = New-ScheduledTaskSettingsSet `
        -WakeToRun `
        -ExecutionTimeLimit (New-TimeSpan -Minutes $Plan.timeoutMinutes) `
        -StartWhenAvailable

    $taskName = "$($script:CcPlanTaskPrefix)$($Plan.id)"

    # Remove if exists (re-schedule case)
    $existing = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    if ($existing) {
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
    }

    Register-ScheduledTask `
        -TaskName $taskName `
        -Action $action `
        -Trigger $trigger `
        -Settings $settings `
        -Description "cc plan: $($Plan.prompt.Substring(0, [Math]::Min(80, $Plan.prompt.Length)))" `
        -RunLevel Limited | Out-Null
}

function _cc_plan_read_all {
    New-Item -ItemType Directory -Path $script:CcPlansDir -Force | Out-Null
    $files = Get-ChildItem -Path $script:CcPlansDir -Filter 'plan-*.json' -ErrorAction SilentlyContinue
    $plans = @()
    foreach ($f in $files) {
        $plans += (Get-Content $f.FullName -Raw | ConvertFrom-Json)
    }
    return $plans
}

# ── Plan subcommands ─────────────────────────────────────────────────────────

function _cc_plan_dispatch {
    param([string[]]$SubArgs)

    if ($SubArgs.Count -eq 0 -or [string]::IsNullOrWhiteSpace($SubArgs[0])) {
        _cc_plan_help; return
    }

    switch ($SubArgs[0]) {
        'list'   { _cc_plan_list }
        'show'   { _cc_plan_show -Id $SubArgs[1] }
        'cancel' { _cc_plan_cancel -Id $SubArgs[1] }
        'clean'  { _cc_plan_clean }
        'help'   { _cc_plan_help }
        default  { _cc_plan_create -SubArgs $SubArgs }
    }
}

function _cc_plan_create {
    param([string[]]$SubArgs)

    # Parse arguments
    $prompt = $SubArgs[0]
    $atTime = $null
    $autoEdit = $false
    $timeout = 60
    $resumeSession = $null

    for ($i = 1; $i -lt $SubArgs.Count; $i++) {
        switch ($SubArgs[$i]) {
            '--at'        { $i++; $atTime = $SubArgs[$i] }
            '--auto-edit' { $autoEdit = $true }
            '--timeout'   { $i++; $timeout = [int]$SubArgs[$i] }
            '--resume'    { $i++; $resumeSession = $SubArgs[$i] }
        }
    }

    if ([string]::IsNullOrWhiteSpace($prompt)) {
        _cc_err 'Usage: cc plan "your prompt" [--at HH:MM] [--auto-edit] [--resume SESSION] [--timeout N]'
        return
    }

    # Check claude exists
    $claude = Get-Command claude -ErrorAction SilentlyContinue
    if (-not $claude) {
        _cc_err 'Claude CLI not found. Install Claude Code first.'
        return
    }

    # Determine schedule time
    if ($atTime) {
        # Parse HH:MM
        $parts = $atTime -split ':'
        if ($parts.Count -ne 2) {
            _cc_err "Invalid time format: $atTime (use HH:MM)"
            return
        }
        $h = [int]$parts[0]; $m = [int]$parts[1]
        $scheduledAt = (Get-Date).Date.AddHours($h).AddMinutes($m)
        # If time already passed today, schedule for tomorrow
        if ($scheduledAt -lt (Get-Date)) {
            $scheduledAt = $scheduledAt.AddDays(1)
        }
    } else {
        $scheduledAt = _cc_plan_auto_time
    }

    # Generate ID
    New-Item -ItemType Directory -Path $script:CcPlansDir -Force | Out-Null
    $id = _cc_plan_generate_id -ScheduledAt $scheduledAt
    if (-not $id) { return }

    # Build plan
    $plan = @{
        id               = $id
        prompt           = $prompt
        workingDirectory = (Get-Location).Path
        scheduledAt      = $scheduledAt.ToString('o')
        createdAt        = (Get-Date).ToString('o')
        status           = 'pending'
        autoEdit         = $autoEdit
        resumeSession    = $resumeSession
        timeoutMinutes   = $timeout
        taskName         = "$($script:CcPlanTaskPrefix)$id"
        completedAt      = $null
        exitCode         = $null
        logFile          = "plan-$id.log"
        outputFile       = "plan-$id.output.md"
    }

    # Save plan JSON
    $planFile = Join-Path $script:CcPlansDir "plan-$id.json"
    $plan | ConvertTo-Json -Depth 5 | Set-Content $planFile -Encoding UTF8

    # Register Task Scheduler (with WakeToRun)
    _cc_plan_register_task -Plan $plan

    # Confirm
    Write-Host ''
    _cc_ok "Plan scheduled: $id"
    _cc_info "Prompt:    $($prompt.Substring(0, [Math]::Min(60, $prompt.Length)))$(if($prompt.Length -gt 60){'...'})"
    _cc_info "Directory: $($plan.workingDirectory)"
    _cc_info "Run at:    $($scheduledAt.ToString('yyyy-MM-dd HH:mm'))"
    if ($resumeSession) {
        _cc_info "Resume:    session $resumeSession"
    }
    _cc_info "Mode:      $(if ($autoEdit) { 'auto-edit (file changes allowed)' } else { 'read-only' })"
    _cc_info "Timeout:   $timeout min"
    _cc_info "WakeToRun: yes (PC will wake from sleep)"
    Write-Host ''
    _cc_info "View plans:   cc plan list"
    _cc_info "Cancel:       cc plan cancel $id"
}

function _cc_plan_list {
    $plans = _cc_plan_read_all
    if ($plans.Count -eq 0) {
        _cc_info 'No plans scheduled. Create one: cc plan "your prompt" --at HH:MM'
        return
    }

    _cc_head 'Scheduled Plans'

    $statusColors = @{
        'pending'   = 'Yellow'
        'running'   = 'Cyan'
        'completed' = 'Green'
        'failed'    = 'Red'
        'cancelled' = 'DarkGray'
    }

    foreach ($p in ($plans | Sort-Object { $_.scheduledAt })) {
        $color = $statusColors[$p.status]
        if (-not $color) { $color = 'White' }
        $excerpt = $p.prompt.Substring(0, [Math]::Min(50, $p.prompt.Length))
        if ($p.prompt.Length -gt 50) { $excerpt += '...' }
        $time = ([datetime]$p.scheduledAt).ToString('MM-dd HH:mm')

        Write-Host "  [$($p.status.PadRight(9))]" -ForegroundColor $color -NoNewline
        Write-Host " $($p.id)" -ForegroundColor White -NoNewline
        Write-Host " $time" -ForegroundColor DarkGray -NoNewline
        Write-Host " $excerpt" -ForegroundColor Gray
    }
    Write-Host ''
}

function _cc_plan_show {
    param([string]$Id)
    if ([string]::IsNullOrWhiteSpace($Id)) {
        _cc_err 'Usage: cc plan show <id>'
        return
    }

    $planFile = Join-Path $script:CcPlansDir "plan-$Id.json"
    if (-not (Test-Path $planFile)) {
        _cc_err "Plan not found: $Id"
        return
    }

    $p = Get-Content $planFile -Raw | ConvertFrom-Json

    _cc_head "Plan: $($p.id)"
    _cc_info "Status:    $($p.status)"
    _cc_info "Prompt:    $($p.prompt)"
    _cc_info "Directory: $($p.workingDirectory)"
    _cc_info "Scheduled: $(([datetime]$p.scheduledAt).ToString('yyyy-MM-dd HH:mm'))"
    _cc_info "Created:   $(([datetime]$p.createdAt).ToString('yyyy-MM-dd HH:mm'))"
    if ($p.resumeSession) {
        _cc_info "Resume:    session $($p.resumeSession)"
    }
    _cc_info "Mode:      $(if ($p.autoEdit) { 'auto-edit' } else { 'read-only' })"
    _cc_info "Timeout:   $($p.timeoutMinutes) min"

    if ($p.completedAt) {
        _cc_info "Completed: $(([datetime]$p.completedAt).ToString('yyyy-MM-dd HH:mm'))"
        _cc_info "Exit code: $($p.exitCode)"
    }

    # Show output if exists
    $outputPath = Join-Path $script:CcPlansDir $p.outputFile
    if (Test-Path $outputPath) {
        Write-Host ''
        _cc_head 'Output (first 30 lines)'
        Get-Content $outputPath -TotalCount 30
        Write-Host ''
        _cc_info "Full output: $outputPath"
    }

    # Show log if exists
    $logPath = Join-Path $script:CcPlansDir $p.logFile
    if (Test-Path $logPath) {
        _cc_info "Log: $logPath"
    }
}

function _cc_plan_cancel {
    param([string]$Id)
    if ([string]::IsNullOrWhiteSpace($Id)) {
        _cc_err 'Usage: cc plan cancel <id>'
        return
    }

    $planFile = Join-Path $script:CcPlansDir "plan-$Id.json"
    if (-not (Test-Path $planFile)) {
        _cc_err "Plan not found: $Id"
        return
    }

    $p = Get-Content $planFile -Raw | ConvertFrom-Json

    if ($p.status -eq 'completed' -or $p.status -eq 'cancelled') {
        _cc_warn "Plan already $($p.status)"
        return
    }

    # Unregister Task Scheduler task
    $taskName = "$($script:CcPlanTaskPrefix)$Id"
    $task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    if ($task) {
        if ($task.State -eq 'Running') {
            Stop-ScheduledTask -TaskName $taskName
        }
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
    }

    # Update status
    $p.status = 'cancelled'
    $p.completedAt = (Get-Date).ToString('o')
    $p | ConvertTo-Json -Depth 5 | Set-Content $planFile -Encoding UTF8

    _cc_ok "Plan $Id cancelled"
}

function _cc_plan_clean {
    $plans = _cc_plan_read_all
    $cutoff = (Get-Date).AddDays(-7)
    $removed = 0

    foreach ($p in $plans) {
        if ($p.status -in @('completed', 'failed', 'cancelled') -and $p.completedAt) {
            if (([datetime]$p.completedAt) -lt $cutoff) {
                $planFile = Join-Path $script:CcPlansDir "plan-$($p.id).json"
                $outputFile = Join-Path $script:CcPlansDir $p.outputFile
                $logFile = Join-Path $script:CcPlansDir $p.logFile

                Remove-Item $planFile -Force -ErrorAction SilentlyContinue
                Remove-Item $outputFile -Force -ErrorAction SilentlyContinue
                Remove-Item $logFile -Force -ErrorAction SilentlyContinue

                # Clean up task if still registered
                $taskName = "$($script:CcPlanTaskPrefix)$($p.id)"
                $task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
                if ($task) { Unregister-ScheduledTask -TaskName $taskName -Confirm:$false }

                $removed++
            }
        }
    }

    if ($removed -gt 0) {
        _cc_ok "Cleaned $removed old plan(s)"
    } else {
        _cc_info 'No old plans to clean (keeping plans < 7 days old)'
    }
}

function _cc_plan_help {
    Write-Host ''
    Write-Host '  cc plan — schedule Claude tasks with wake-from-sleep' -ForegroundColor Cyan
    Write-Host ''
    Write-Host '  Create:' -ForegroundColor White
    Write-Host '    cc plan "your prompt"                  Auto-schedule (next block expiry or next hour)'
    Write-Host '    cc plan "your prompt" --at 1:00        Schedule for specific time'
    Write-Host '    cc plan "msg" --resume <id>              Resume existing session with message'
    Write-Host '    cc plan "your prompt" --auto-edit      Allow file changes (dangerous)'
    Write-Host '    cc plan "your prompt" --timeout 120    Set timeout in minutes (default: 60)'
    Write-Host ''
    Write-Host '  Manage:' -ForegroundColor White
    Write-Host '    cc plan list                           List all plans'
    Write-Host '    cc plan show <id>                      Show plan details + output'
    Write-Host '    cc plan cancel <id>                    Cancel a pending plan'
    Write-Host '    cc plan clean                          Remove old completed plans (>7 days)'
    Write-Host ''
    Write-Host '  Notes:' -ForegroundColor White
    Write-Host '    - Plans run in the directory where you created them'
    Write-Host '    - PC wakes from sleep (WakeToRun) to execute plans'
    Write-Host '    - Default mode: read-only (claude -p). Use --auto-edit for file changes'
    Write-Host '    - Output saved to: %APPDATA%\ccblocks\plans\'
    Write-Host ''
}
