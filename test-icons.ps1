# Quick test for icon system
$ProfileRoot = Split-Path -Parent $PSCommandPath

# Load icons
. "$ProfileRoot\settings\icons.ps1"

Write-Host "`n=== Icon System Test ===`n" -ForegroundColor Cyan

# Test 1: Unicode mode (default)
Write-Host "TEST 1: Unicode fallback mode (default)" -ForegroundColor Yellow
$global:OhMyPwsh_UseNerdFonts = $false
$global:OhMyPwsh_CustomIcons = $null  # Clear custom icons

foreach ($role in @('success', 'warning', 'error', 'info', 'tip', 'question')) {
    $icon = Get-FallbackIcon -Role $role
    $color = Get-IconColor -Role $role
    Write-Host "  [$icon] $role" -ForegroundColor $color
}

Write-Host ""

# Test 2: Nerd Font mode
Write-Host "TEST 2: Nerd Font mode (if you have NF installed)" -ForegroundColor Yellow
$global:OhMyPwsh_UseNerdFonts = $true
$global:OhMyPwsh_CustomIcons = $null  # Clear custom icons

foreach ($role in @('success', 'warning', 'error', 'info', 'tip', 'question')) {
    $icon = Get-FallbackIcon -Role $role
    $color = Get-IconColor -Role $role
    Write-Host "  [$icon] $role" -ForegroundColor $color
}

Write-Host ""

# Test 3: Custom icons
Write-Host "TEST 3: Custom icon overrides" -ForegroundColor Yellow
$global:OhMyPwsh_CustomIcons = @{
    success = "✅"
    warning = "⚠️"
}

foreach ($role in @('success', 'warning', 'error', 'info', 'tip', 'question')) {
    $icon = Get-FallbackIcon -Role $role
    $color = Get-IconColor -Role $role
    Write-Host "  [$icon] $role" -ForegroundColor $color
}

Write-Host "`n=== Test Complete ===`n" -ForegroundColor Green
