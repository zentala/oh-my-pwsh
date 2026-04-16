# ============================================
# ssh-sleep-blocker - Keep Windows awake during SSH sessions
# Provides: ssh-sleep-blocker setup|status|logs|start|stop|disable|enable|uninstall
# ============================================

# ── Paths & task metadata ────────────────────────────────────────────────────
$script:SshBlockerTaskName  = 'SSHSleepBlocker'
$script:SshBlockerLogDir    = Join-Path $env:ProgramData 'ssh-sleep-blocker'
$script:SshBlockerLogFile   = Join-Path $script:SshBlockerLogDir 'daemon.log'
$script:SshBlockerDaemonPs1 = Join-Path $PSScriptRoot '..\..\scripts\ssh-sleep-blocker\daemon.ps1'
$script:SshBlockerDaemonCmd = Join-Path $PSScriptRoot '..\..\scripts\ssh-sleep-blocker\daemon.cmd'

# ── Output helpers ───────────────────────────────────────────────────────────
function _ssb_ok    { param($msg) Write-Host "[OK]  $msg" -ForegroundColor Green }
function _ssb_err   { param($msg) Write-Host "[ERR] $msg" -ForegroundColor Red }
function _ssb_warn  { param($msg) Write-Host "[!]   $msg" -ForegroundColor Yellow }
function _ssb_info  { param($msg) Write-Host "      $msg" -ForegroundColor Cyan }
function _ssb_head  { param($msg) Write-Host "`n$msg" -ForegroundColor Blue }

# ── Task Scheduler helpers ───────────────────────────────────────────────────
function _ssb_task_exists {
    $null -ne (Get-ScheduledTask -TaskName $script:SshBlockerTaskName -ErrorAction SilentlyContinue)
}

function _ssb_task_state {
    $task = Get-ScheduledTask -TaskName $script:SshBlockerTaskName -ErrorAction SilentlyContinue
    if (-not $task) { return 'not-installed' }
    return $task.State.ToString()
}

function _ssb_is_admin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    (New-Object Security.Principal.WindowsPrincipal($id)).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator)
}

# ── Commands ─────────────────────────────────────────────────────────────────
function _ssb_setup {
    _ssb_head 'SSH Sleep Blocker Setup'

    if (-not (Test-Path $script:SshBlockerDaemonPs1)) {
        _ssb_err "Daemon not found: $script:SshBlockerDaemonPs1"
        return
    }

    if (-not (_ssb_is_admin)) {
        _ssb_err 'Setup requires administrator rights (Task Scheduler registration).'
        _ssb_info 'Run from elevated shell: gsudo pwsh -c "ssh-sleep-blocker setup"'
        return
    }

    if (-not (Test-Path $script:SshBlockerLogDir)) {
        New-Item -ItemType Directory -Path $script:SshBlockerLogDir -Force | Out-Null
    }

    $daemonPath = (Resolve-Path $script:SshBlockerDaemonPs1).Path
    $action = New-ScheduledTaskAction `
        -Execute 'pwsh.exe' `
        -Argument "-NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$daemonPath`""

    $trigger = New-ScheduledTaskTrigger -AtStartup

    $settings = New-ScheduledTaskSettingsSet `
        -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries `
        -StartWhenAvailable `
        -MultipleInstances IgnoreNew `
        -ExecutionTimeLimit ([TimeSpan]::Zero)

    if (_ssb_task_exists) {
        Unregister-ScheduledTask -TaskName $script:SshBlockerTaskName -Confirm:$false
    }

    Register-ScheduledTask `
        -TaskName $script:SshBlockerTaskName `
        -Action $action `
        -Trigger $trigger `
        -Settings $settings `
        -Description 'Prevent Windows sleep while SSH connections are active (port 22)' `
        -RunLevel Highest `
        -User 'SYSTEM' | Out-Null

    _ssb_ok "Task registered: $script:SshBlockerTaskName"
    _ssb_info "Daemon: $daemonPath"
    _ssb_info "Log:    $script:SshBlockerLogFile"
    _ssb_info 'Start now: ssh-sleep-blocker start'
}

function _ssb_status {
    _ssb_head 'SSH Sleep Blocker Status'
    $state = _ssb_task_state
    if ($state -eq 'not-installed') {
        _ssb_warn 'Task not installed. Run: ssh-sleep-blocker setup'
        return
    }
    _ssb_info "Task state: $state"

    $task = Get-ScheduledTask -TaskName $script:SshBlockerTaskName
    $info = $task | Get-ScheduledTaskInfo
    _ssb_info "Last run:  $($info.LastRunTime)"
    _ssb_info "Last code: $($info.LastTaskResult)"
    _ssb_info "Next run:  $($info.NextRunTime)"

    $active = @(Get-NetTCPConnection -LocalPort 22 -State Established -ErrorAction SilentlyContinue).Count
    if ($active -gt 0) {
        _ssb_ok "Active SSH connections: $active (sleep should be blocked)"
    } else {
        _ssb_info 'No active SSH connections (sleep allowed)'
    }
}

function _ssb_logs {
    param([int]$Last = 50)
    if (-not (Test-Path $script:SshBlockerLogFile)) {
        _ssb_warn "No log file yet: $script:SshBlockerLogFile"
        return
    }
    Get-Content $script:SshBlockerLogFile -Tail $Last
}

function _ssb_start {
    if (-not (_ssb_task_exists)) { _ssb_err 'Task not installed. Run: ssh-sleep-blocker setup'; return }
    if (-not (_ssb_is_admin))    { _ssb_err 'Start requires admin. Use: gsudo pwsh -c "ssh-sleep-blocker start"'; return }
    Start-ScheduledTask -TaskName $script:SshBlockerTaskName
    _ssb_ok 'Task started'
}

function _ssb_stop {
    if (-not (_ssb_task_exists)) { _ssb_err 'Task not installed'; return }
    if (-not (_ssb_is_admin))    { _ssb_err 'Stop requires admin. Use: gsudo pwsh -c "ssh-sleep-blocker stop"'; return }
    Stop-ScheduledTask -TaskName $script:SshBlockerTaskName
    _ssb_ok 'Task stopped'
}

function _ssb_disable {
    if (-not (_ssb_is_admin)) { _ssb_err 'Disable requires admin'; return }
    Disable-ScheduledTask -TaskName $script:SshBlockerTaskName | Out-Null
    _ssb_ok 'Task disabled (will not run at startup)'
}

function _ssb_enable {
    if (-not (_ssb_is_admin)) { _ssb_err 'Enable requires admin'; return }
    Enable-ScheduledTask -TaskName $script:SshBlockerTaskName | Out-Null
    _ssb_ok 'Task enabled'
}

function _ssb_uninstall {
    param([switch]$Force)
    if (-not (_ssb_task_exists)) { _ssb_warn 'Task not installed'; return }
    if (-not (_ssb_is_admin))    { _ssb_err 'Uninstall requires admin'; return }

    if (-not $Force) {
        $confirm = Read-Host 'Unregister scheduled task? [y/N]'
        if ($confirm -ne 'y') { _ssb_info 'Cancelled'; return }
    }
    Stop-ScheduledTask -TaskName $script:SshBlockerTaskName -ErrorAction SilentlyContinue
    Unregister-ScheduledTask -TaskName $script:SshBlockerTaskName -Confirm:$false
    _ssb_ok 'Task unregistered'
}

function _ssb_help {
    Write-Host ''
    Write-Host '  ssh-sleep-blocker — Keep Windows awake during SSH sessions' -ForegroundColor Cyan
    Write-Host ''
    Write-Host '  Commands:' -ForegroundColor White
    Write-Host '    setup        Install scheduled task (requires admin)'
    Write-Host '    status       Show task + connection state'
    Write-Host '    logs [N]     Show last N log lines (default 50)'
    Write-Host '    start        Start daemon now (admin)'
    Write-Host '    stop         Stop daemon (admin)'
    Write-Host '    disable      Disable autostart (admin)'
    Write-Host '    enable       Enable autostart (admin)'
    Write-Host '    uninstall    Unregister task (admin)'
    Write-Host '    help         Show this help'
    Write-Host ''
    Write-Host "  Log: $script:SshBlockerLogFile" -ForegroundColor DarkGray
    Write-Host ''
}

# ── Public entry point ───────────────────────────────────────────────────────
function ssh-sleep-blocker {
    [CmdletBinding()]
    param(
        [Parameter(Position=0)]
        [string]$Command = 'help',

        [Parameter(Position=1)]
        [string]$Arg1 = '',

        [switch]$Force
    )

    switch ($Command) {
        'setup'     { _ssb_setup }
        'status'    { _ssb_status }
        'logs'      { $n = if ($Arg1) { [int]$Arg1 } else { 50 }; _ssb_logs -Last $n }
        'start'     { _ssb_start }
        'stop'      { _ssb_stop }
        'disable'   { _ssb_disable }
        'enable'    { _ssb_enable }
        'uninstall' { _ssb_uninstall -Force:$Force }
        'help'      { _ssb_help }
        ''          { _ssb_help }
        default     { _ssb_err "Unknown command: $Command"; _ssb_help }
    }
}
