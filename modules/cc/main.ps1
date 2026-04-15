# ============================================
# cc - Claude Code CLI (blocks + plans)
# Provides: cc blocks [...] and cc plan [...]
# ============================================

# ── Config paths ─────────────────────────────────────────────────────────────
$script:CcConfigDir      = Join-Path $env:APPDATA 'cc'
$script:CcConfigFile     = Join-Path $script:CcConfigDir 'config.json'
$script:CcLogFile        = Join-Path $script:CcConfigDir 'cc.log'
$script:CcActivityFile   = Join-Path $script:CcConfigDir '.last-activity'
$script:CcDaemonScript   = Join-Path $PSScriptRoot '..\..\scripts\cc\blocks-daemon.ps1'
$script:CcTaskName       = 'cc-blocks'
$script:CcPlansDir       = Join-Path $script:CcConfigDir 'plans'
$script:CcPlanDaemonScript = Join-Path $PSScriptRoot '..\..\scripts\cc\plan-daemon.ps1'
$script:CcPlanTaskPrefix = 'cc-plan-'

# ── Schedule presets ─────────────────────────────────────────────────────────
$script:CcPresets = @{
    '247'     = @{ Hours = @(0, 6, 12, 18);  Label = '24/7 Max Coverage';  Description = '12 AM, 6 AM, 12 PM, 6 PM daily' }
    'work'    = @{ Hours = @(9, 14);         Label = 'Work Hours';          Description = '9 AM, 2 PM Mon-Fri'; WeekdaysOnly = $true }
    'night'   = @{ Hours = @(18, 23);        Label = 'Night Owl';           Description = '6 PM, 11 PM daily' }
    'zentala' = @{ Hours = @(5, 10, 15, 20); Label = 'Zentala Schedule';    Description = '5 AM, 10 AM, 3 PM, 8 PM — covers 9 AM to 1 AM' }
}

# ── Output helpers ───────────────────────────────────────────────────────────
function _cc_ok    { param($msg) Write-Host "[OK]  $msg" -ForegroundColor Green }
function _cc_err   { param($msg) Write-Host "[ERR] $msg" -ForegroundColor Red }
function _cc_warn  { param($msg) Write-Host "[!]   $msg" -ForegroundColor Yellow }
function _cc_info  { param($msg) Write-Host "      $msg" -ForegroundColor Cyan }
function _cc_head  { param($msg) Write-Host "`n$msg" -ForegroundColor Blue }

# ── Config I/O ───────────────────────────────────────────────────────────────
function _cc_read_config {
    if (-not (Test-Path $script:CcConfigFile)) { return $null }
    Get-Content $script:CcConfigFile -Raw | ConvertFrom-Json
}

function _cc_write_config {
    param($Config)
    New-Item -ItemType Directory -Path $script:CcConfigDir -Force | Out-Null
    $Config | ConvertTo-Json -Depth 5 | Set-Content $script:CcConfigFile -Encoding UTF8
}

# ── Task Scheduler helpers ───────────────────────────────────────────────────
function _cc_task_exists {
    $null -ne (Get-ScheduledTask -TaskName $script:CcTaskName -ErrorAction SilentlyContinue)
}

function _cc_make_triggers {
    param([int[]]$Hours, [bool]$WeekdaysOnly = $false)
    $triggers = @()
    foreach ($h in $Hours) {
        $time = '{0:D2}:00' -f $h
        if ($WeekdaysOnly) {
            $triggers += New-ScheduledTaskTrigger -Weekly `
                -DaysOfWeek Monday,Tuesday,Wednesday,Thursday,Friday -At $time
        } else {
            $triggers += New-ScheduledTaskTrigger -Daily -At $time
        }
    }
    return $triggers
}

function _cc_register_task {
    param([int[]]$Hours, [bool]$WeekdaysOnly = $false)

    $daemonPath = (Resolve-Path $script:CcDaemonScript).Path
    $action = New-ScheduledTaskAction `
        -Execute 'pwsh.exe' `
        -Argument "-NonInteractive -WindowStyle Hidden -File `"$daemonPath`""

    $triggers = _cc_make_triggers -Hours $Hours -WeekdaysOnly $WeekdaysOnly

    $settings = New-ScheduledTaskSettingsSet `
        -WakeToRun `
        -ExecutionTimeLimit (New-TimeSpan -Minutes 2) `
        -MultipleInstances IgnoreNew `
        -StartWhenAvailable

    if (_cc_task_exists) {
        Unregister-ScheduledTask -TaskName $script:CcTaskName -Confirm:$false
    }

    Register-ScheduledTask `
        -TaskName $script:CcTaskName `
        -Action $action `
        -Trigger $triggers `
        -Settings $settings `
        -Description 'cc blocks: auto-trigger Claude Code 5-hour blocks' `
        -RunLevel Limited | Out-Null
}

# ── Validation ───────────────────────────────────────────────────────────────
function _cc_validate_hours {
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
    $wrapGap = 24 - $sorted[-1] + $sorted[0]
    if ($wrapGap -lt 5) {
        _cc_err "Wraparound gap too small: $($sorted[-1]) to $($sorted[0]) (next day) = $($wrapGap)h"
        return $false
    }
    return $true
}

# ── Sleep/Hibernate check ────────────────────────────────────────────────────
function _cc_check_sleep_config {
    try {
        $standby = powercfg /query SCHEME_CURRENT SUB_SLEEP STANDBYIDLE 2>$null
        $hibernate = powercfg /query SCHEME_CURRENT SUB_SLEEP HIBERNATEIDLE 2>$null

        $standbyOn  = $standby  -match 'Current AC Power Setting Index: 0x(?!00000000)'
        $hibernateOn = $hibernate -match 'Current AC Power Setting Index: 0x(?!00000000)'

        if (-not $standbyOn -and $hibernateOn) {
            _cc_warn 'PC uses HIBERNATE instead of SLEEP'
            _cc_warn 'WakeToRun does NOT work with Hibernation (S4)!'
            _cc_info 'Fix: Enable Sleep or Hybrid Sleep in Power Options'
            _cc_info '     Control Panel > Power Options > Change plan settings > Advanced'
            _cc_info '     Sleep > Allow hybrid sleep > On'
        } elseif ($standbyOn) {
            _cc_ok 'Sleep (S3) is enabled — WakeToRun will work'
        }
    } catch {
        # powercfg may fail in some environments — ignore silently
    }
}

# ── Migration from ccblocks ──────────────────────────────────────────────────
function _cc_migrate_from_ccblocks {
    $oldDir = Join-Path $env:APPDATA 'ccblocks'
    if ((Test-Path $oldDir) -and -not (Test-Path $script:CcConfigDir)) {
        _cc_info 'Migrating config from ccblocks to cc...'
        Copy-Item $oldDir $script:CcConfigDir -Recurse -Force
        _cc_ok "Config migrated to: $script:CcConfigDir"
        _cc_info "Old config preserved at: $oldDir (safe to delete manually)"
    }

    # Migrate Task Scheduler task
    $oldTask = Get-ScheduledTask -TaskName 'ccblocks' -ErrorAction SilentlyContinue
    if ($oldTask) {
        _cc_info 'Found old ccblocks task — will be replaced on next setup'
    }
}

# Run migration check on load
_cc_migrate_from_ccblocks

# ── Load submodules ──────────────────────────────────────────────────────────
. $PSScriptRoot\blocks.ps1
. $PSScriptRoot\plan.ps1

# ── Help ─────────────────────────────────────────────────────────────────────
function _cc_help {
    Write-Host ''
    Write-Host '  cc — Claude Code CLI for Windows' -ForegroundColor Cyan
    Write-Host ''
    Write-Host '  Namespaces:' -ForegroundColor White
    Write-Host '    cc blocks [cmd]     Block scheduler (auto-trigger 5h usage blocks)'
    Write-Host '    cc plan [cmd]       Scheduled Claude tasks (wake PC & run prompt)'
    Write-Host ''
    Write-Host '  Quick reference:' -ForegroundColor White
    Write-Host '    cc blocks setup                       Install block scheduler'
    Write-Host '    cc blocks status                      Show status'
    Write-Host '    cc plan "prompt" --at 1:00             Schedule overnight task'
    Write-Host '    cc plan list                           List plans'
    Write-Host ''
    Write-Host '  Details:' -ForegroundColor White
    Write-Host '    cc blocks help                        Full blocks help'
    Write-Host '    cc plan help                          Full plan help'
    Write-Host ''
}

# ── Public entry point ───────────────────────────────────────────────────────
function cc {
    [CmdletBinding()]
    param(
        [Parameter(Position=0)]
        [string]$Namespace = 'help',

        [Parameter(Position=1)]
        [string]$Command = '',

        [Parameter(Position=2)]
        [string]$Arg1 = '',

        [Parameter(Position=3)]
        [string]$Arg2 = '',

        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Rest,

        [switch]$Force,
        [int]$Last = 50
    )

    switch ($Namespace) {
        'blocks'  { _cc_blocks_dispatch -Command $Command -Arg1 $Arg1 -Arg2 $Arg2 -Force:$Force -Last $Last }
        'plan'    { _cc_plan_dispatch -SubArgs ((@($Command, $Arg1, $Arg2) + $Rest) | Where-Object { $_ -ne '' }) }
        'help'    { _cc_help }
        default   { _cc_err "Unknown namespace: $Namespace. Use: cc blocks | cc plan"; _cc_help }
    }
}

# ── Backward compatibility ───────────────────────────────────────────────────
function ccblocks {
    [CmdletBinding()]
    param(
        [Parameter(Position=0)]
        [string]$Command = 'help',
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Rest
    )
    _cc_warn "ccblocks is deprecated. Use: cc blocks $Command $($Rest -join ' ')"
    cc blocks $Command @Rest
}
