# Test Configuration: No Enhanced Tools
# Simulates a clean Windows machine with no enhanced tools installed

$global:OhMyPwsh_UseNerdFonts = $false
$global:OhMyPwsh_ShowFeedback = $false
$global:OhMyPwsh_EnableLinuxCompat = $true

# This fixture is loaded with mocked Get-Command calls
# that return $null for all enhanced tools:
# - bat, eza, ripgrep (rg), fd, delta, fzf, zoxide all return null
# - oh-my-stats module not available
#
# Expected behavior:
# - Profile should load without errors
# - Fallbacks to native PowerShell commands
# - Warning messages shown for missing tools
