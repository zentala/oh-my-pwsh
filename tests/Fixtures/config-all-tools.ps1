# Test Configuration: All Tools Installed
# Simulates a machine with all enhanced tools available

$global:OhMyPwsh_UseNerdFonts = $false
$global:OhMyPwsh_ShowFeedback = $false
$global:OhMyPwsh_EnableLinuxCompat = $true

# This fixture is loaded with mocked Get-Command calls
# to simulate all tools being installed:
# - bat, eza, ripgrep (rg), fd, delta, fzf, zoxide
# - oh-my-stats module
