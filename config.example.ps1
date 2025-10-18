# ============================================
# oh-my-pwsh Configuration Template
# ============================================
# Copy this file to 'config.ps1' and customize your settings
#
# Installation:
#   Copy-Item config.example.ps1 config.ps1
#
# Note: config.ps1 is gitignored so you can update the repo safely

# ============================================
# LINUX COMPATIBILITY
# ============================================
# Enable Linux-style aliases (ls, grep, cat, mkdir, touch, etc.)
$global:OhMyPwsh_EnableLinuxCompat = $true

# ============================================
# ICONS & APPEARANCE
# ============================================
# Use Nerd Font icons instead of Unicode fallbacks
# Requires a Nerd Font installed in your terminal (e.g., FiraCode Nerd Font)
# Download: https://www.nerdfonts.com/
#
# Set to $true if you have Nerd Fonts installed, $false for Unicode fallback
$global:OhMyPwsh_UseNerdFonts = $false

# Custom icon overrides (optional)
# $global:OhMyPwsh_CustomIcons = @{
#     success = "✅"
#     warning = "⚠️"
#     error = "❌"
# }

# ============================================
# ENHANCED TOOLS
# ============================================
# Use modern alternatives when available:
# - bat instead of cat (syntax highlighting)
# - eza instead of ls (modern, colorful)
# - ripgrep (rg) instead of grep (faster)
# - fd instead of find (faster, better UX)
# - delta for git diff (better diffs)
$global:OhMyPwsh_UseEnhancedTools = $true

# ============================================
# HELP SYSTEM
# ============================================
# Show custom help command (type 'help' to see available commands)
$global:OhMyPwsh_EnableCustomHelp = $true

# ============================================
# FEEDBACK & LEARNING MODE
# ============================================
# Show what commands are aliased to (helps learning PowerShell)
# Example: "mkdir → New-Item -ItemType Directory"
$global:OhMyPwsh_ShowAliasTargets = $true

# Show feedback messages for operations (Created, Deleted, etc.)
$global:OhMyPwsh_ShowFeedback = $true

# Show welcome tip about help command
$global:OhMyPwsh_ShowWelcome = $true

# ============================================
# STARTUP DISPLAY
# ============================================
# Disable fastfetch at startup (set to $false to enable)
$global:DisableFastfetch = $true
