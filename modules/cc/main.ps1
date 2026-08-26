# ============================================
# cc - Claude Code CLI (plans)
# Provides: cc plan [...]
# ============================================

# ── Config paths ─────────────────────────────────────────────────────────────
$script:CcConfigDir        = Join-Path $env:APPDATA 'cc'
$script:CcPlansDir         = Join-Path $script:CcConfigDir 'plans'
$script:CcPlanDaemonScript = Join-Path $PSScriptRoot '..\..\scripts\cc\plan-daemon.ps1'
$script:CcPlanTaskPrefix   = 'cc-plan-'

# ── Output helpers ───────────────────────────────────────────────────────────
function _cc_ok    { param($msg) Write-Host "[OK]  $msg" -ForegroundColor Green }
function _cc_err   { param($msg) Write-Host "[ERR] $msg" -ForegroundColor Red }
function _cc_warn  { param($msg) Write-Host "[!]   $msg" -ForegroundColor Yellow }
function _cc_info  { param($msg) Write-Host "      $msg" -ForegroundColor Cyan }
function _cc_head  { param($msg) Write-Host "`n$msg" -ForegroundColor Blue }

# ── Load submodules ──────────────────────────────────────────────────────────
. $PSScriptRoot\plan.ps1

# ── Help ─────────────────────────────────────────────────────────────────────
function _cc_help {
    Write-Host ''
    Write-Host '  cc — Claude Code CLI for Windows' -ForegroundColor Cyan
    Write-Host ''
    Write-Host '  Namespaces:' -ForegroundColor White
    Write-Host '    cc plan [cmd]       Scheduled Claude tasks (wake PC & run prompt)'
    Write-Host ''
    Write-Host '  Quick reference:' -ForegroundColor White
    Write-Host '    cc plan "prompt" --at 1:00             Schedule overnight task'
    Write-Host '    cc plan list                           List plans'
    Write-Host ''
    Write-Host '  Details:' -ForegroundColor White
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
        [string[]]$Rest
    )

    switch ($Namespace) {
        'plan'    { _cc_plan_dispatch -SubArgs ((@($Command, $Arg1, $Arg2) + $Rest) | Where-Object { $_ -ne '' }) }
        'help'    { _cc_help }
        default   { _cc_err "Unknown namespace: $Namespace. Use: cc plan"; _cc_help }
    }
}
