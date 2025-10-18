# Test Configuration: Partial Tool Installation
# Simulates a machine with some tools installed, some missing

$global:OhMyPwsh_UseNerdFonts = $false
$global:OhMyPwsh_ShowFeedback = $false
$global:OhMyPwsh_EnableLinuxCompat = $true

# This fixture is loaded with mocked Get-Command calls:
# INSTALLED:
# - bat ✓
# - ripgrep (rg) ✓
# - delta ✓
#
# MISSING:
# - eza ✗
# - fd ✗
# - fzf ✗
# - zoxide ✗
# - oh-my-stats ✗
#
# Expected behavior:
# - Profile loads successfully
# - Warnings shown for missing tools only
# - Installed tools work normally
# - Missing tools use fallbacks
