# oh-my-pwsh Architecture

## Philosophy

**Goal**: Zero-error PowerShell profile for power users with optional enhancements

### Core Principles

1. **Never Fail**: Profile must load without errors, even if tools are missing
2. **Graceful Degradation**: All enhanced tools are optional with native fallbacks
3. **Visibility**: Users see what loaded and what's available to install
4. **Power User Focus**: Show all warnings/errors, don't hide anything behind loaders

## Directory Structure

```
pwsh-profile/
├── profile.ps1              # Main entry point
├── config.example.ps1       # User configuration template
├── modules/
│   ├── logger.ps1           # Centralized status message system
│   ├── environment.ps1      # Environment variables, PATH setup
│   ├── psreadline.ps1       # PSReadLine configuration
│   ├── aliases.ps1          # Custom aliases
│   ├── functions.ps1        # Utility functions
│   ├── git-helpers.ps1      # Git convenience functions
│   ├── enhanced-tools.ps1   # Optional enhanced CLI tools
│   ├── linux-compat.ps1     # Linux-like command aliases
│   └── help-system.ps1      # Custom help command
├── scripts/
│   └── install-dependencies.ps1
├── themes/                  # Oh My Posh themes
└── docs/
    ├── ARCHITECTURE.md      # This file
    └── linux-compatibility.md
```

## Module Loading Order

1. **Logger Module** (sourced first in profile.ps1)
2. **Core Dependencies** (Terminal-Icons, posh-git, PSFzf, zoxide)
3. **Core Modules** (environment, psreadline, aliases, functions, git-helpers)
4. **Optional Features** (enhanced-tools, linux-compat, help-system)
5. **Oh My Posh** (prompt theme)
6. **oh-my-stats** (system info display at end)

## Status Message System

### Centralized Logging (`modules/logger.ps1`)

All status messages use functions from `logger.ps1`:

- `Write-ProfileStatus` - Base function for all status messages
- `Write-ModuleStatus` - For PowerShell modules (Terminal-Icons, posh-git, etc.)
- `Write-ToolStatus` - For CLI tools (bat, eza, ripgrep, fd, delta)

### Status Levels

| Level | Icon | Color | Usage |
|-------|------|-------|-------|
| `success` | ✓ | Green | Feature loaded successfully |
| `warning` | ! | Yellow | Optional feature missing (with install hint) |
| `error` | � (f467) | Red | Critical error (use sparingly) |
| `info` | i (f129) | Cyan | Informational message |

### Message Format

**Installed/Loaded:**
```
  [✓] tool-name (description)
```

**Missing (with fallback):**
```
  [!] install `tool` for <benefit>: scoop install tool
```

Example:
```
  [✓] bat (enhanced cat)
  [!] install `eza` for modern ls: scoop install eza
```

## Enhanced Tools with Fallbacks

All enhanced tools are **optional** and have native PowerShell fallbacks:

| Tool | Purpose | Fallback | Warning Level |
|------|---------|----------|---------------|
| bat | Better `cat` | `Get-Content` | warning |
| eza | Modern `ls` | `Get-ChildItem` | warning |
| ripgrep | Fast `grep` | `Select-String` | warning |
| fd | Fast `find` | `Get-ChildItem -Recurse` | warning |
| delta | Git diff viewer | git default pager | warning |
| fzf | Fuzzy finder | PSReadLine defaults | warning |
| zoxide | Smart `cd` | `Set-Location` | warning |

### Implementation Pattern

```powershell
if (Get-Command enhanced-tool -ErrorAction SilentlyContinue) {
    # Use enhanced tool
    function alias { enhanced-tool @args }
    Write-ToolStatus -Name "tool" -Installed $true -Description "benefit"
} else {
    # Fallback to native PowerShell
    Write-ToolStatus -Name "tool" -Installed $false -Description "benefit" -ScoopPackage "tool"
    function alias { Native-PowerShell-Cmdlet @args }
}
```

## Configuration

User configuration in `config.ps1`:

```powershell
# Feature flags
$global:OhMyPwsh_EnableLinuxCompat = $true
$global:OhMyPwsh_UseEnhancedTools = $true
$global:OhMyPwsh_ShowFeedback = $true
$global:OhMyPwsh_ShowAliasTargets = $false
$global:OhMyPwsh_EnableCustomHelp = $true
```

## Future Improvements

### Icon Fallback System (TODO)

Create `settings/icons.ps1` with Nerd Font detection:

```powershell
# Auto-detect Nerd Font support
if (Test-NerdFontSupport) {
    $icons = @{
        Success = "" # f00c
        Warning = "" # f0205
        Error = "" # f467
        Info = "" # f129
    }
} else {
    $icons = @{
        Success = "v"
        Warning = "!"
        Error = "x"
        Info = "i"
    }
}
```

### Reusable Status Message Function (TODO)

Instead of repeating Write-Host calls, create:

```powershell
function Write-InstallHint {
    param(
        [string]$Tool,
        [string]$Description,
        [string]$InstallCommand
    )
    # Single function that formats the entire message
}
```

### Profile Load Time (TODO)

Replace PowerShell's default "Loading personal and system profiles took XXXXms" with:

```
  [i] Profile loaded in 1234ms
```

## Design Decisions

### Why Warnings Instead of Errors?

Enhanced tools improve UX but aren't required. Users should:
- See what's available to install (transparency)
- Not be blocked from using the terminal (graceful degradation)
- Get immediate value without installing anything (fallbacks work)

### Why Custom Logger Module?

- **Consistency**: All messages have same format
- **Maintainability**: Change format in one place
- **Flexibility**: Easy to add colors, icons, or formatting
- **Future-proof**: Can add icon fallback system later

### Why Load Order Matters?

1. Logger must load first (other modules use it)
2. Core modules establish baseline functionality
3. Enhanced tools override with better alternatives
4. oh-my-stats loads last (so errors/warnings appear above it)
