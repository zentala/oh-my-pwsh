# oh-my-pwsh - Claude Development Guide

## Project Overview

PowerShell profile with zero-error philosophy and graceful degradation for power users.

---

## Development Rules & Conventions

### File Naming
- **Markdown files**: `CAPITAL_TITLE.md` (capital name, lowercase extension)
  - ✅ `LOGGING.md`, `ARCHITECTURE.md`, `README.md`
  - ❌ `logging.md`, `Architecture.MD`

### Task Management
- Task descriptions: `./todo/NNN-goal.md`
- Active tasks: `./todo/`
- Completed tasks: `./todo/done/`
- Backlog (unrefined ideas): `./todo/backlog/`
- Move tasks between folders with `mv` (don't rewrite with tools)
- `./todo/INDEX.md` - master list with status: `backlog | active | done | abandoned`
- Link all active tasks in this CLAUDE.md

### Documentation vs Tasks
- `./docs/` - **User documentation** for implemented features (how to use)
- `./todo/` - **Development documentation** (how to implement/architecture decisions)
- Every `./docs/` file linked in CLAUDE.md with description

---

## Current Architecture Decisions

### Icon System
- **ALL icons** must use `Get-FallbackIcon -Role <name>` function
- Never hardcode icons (✓, !, x, etc.) directly in code
- Function returns Unicode icons (best compatibility)
- **Nerd Font support: EXPERIMENTAL/SUSPENDED** - renders poorly in most terminals
  - Default: `$global:OhMyPwsh_UseNerdFonts = $false`
  - NerdFont codes preserved in `settings/icons.ps1` for future use
  - Do NOT remove NerdFont definitions - kept for when terminal support improves

**Example:**
```powershell
# ❌ Bad - hardcoded
Write-Host "✓" -ForegroundColor Green

# ✅ Good - using icon system
$icon = Get-FallbackIcon -Role "success"
Write-Host $icon -ForegroundColor Green
```

### Logging System
- **ALL output** goes through `Write-Log` function
- No direct `Write-Host` chains in code
- `Write-Log` uses `Get-FallbackIcon` for icons
- See: [LOGGING.md](./docs/LOGGING.md) for architecture

---

## Current Priorities (in order)

1. **Improve logging system**
   - Implement reusable `Write-Log` function
   - Architecture: [LOGGING-SYSTEM.md](./todo/001-logging-system.md)

2. **Architect and implement icon fallback system**
   - `Get-FallbackIcon -Role <name>` function
   - Nerd Font detection in settings
   - Icon definitions in `settings/icons.ps1`

3. **Follow DRY principle**
   - Make all code reusable
   - Avoid duplication
   - Think composability

4. **Write testable code**
   - Future task: Test all with Pester
   - Future task: Test before push (git hooks)
   - Future task: Test in deployment pipeline

5. **Align with user (dev) before implementing**
   - Discuss architecture decisions
   - Think like solution architect, not just coder
   - Solution must be logical and simple to understand
   - Abstractions are OK if they improve clarity

---

## Design Principles

### Target Users
Power users who want visibility into what's happening

### Error Philosophy
- Profile should NEVER fail or throw errors
- All enhanced tools (bat, eza, ripgrep, fd, delta, fzf, zoxide) are OPTIONAL
- Each tool MUST have a fallback to native PowerShell commands
- Missing tools show as `[!]` warnings (yellow), not errors
- User gets improved experience with tools installed, but default experience without them

### Fallback System
- `bat` → fallback to `Get-Content` (alias: `cat`)
- `eza` → fallback to `Get-ChildItem` (native ls)
- `ripgrep` → fallback to `Select-String` (grep function)
- `fd` → fallback to `Get-ChildItem -Recurse` (find function)
- `delta` → fallback to git's default pager
- `fzf` → PSFzf features disabled, basic PSReadLine still works
- `zoxide` → standard `cd`/`Set-Location` works

### Install Command Intelligence
- Check if package manager (scoop/winget) exists before suggesting install commands
- Only show `scoop install <tool>` if scoop is available
- Otherwise suggest installing package manager first

---

## Status Messages

### Levels
- `[✓]` Green - feature loaded successfully
- `[!]` Yellow - optional feature not installed (with install command)
- `[�]` Red - critical error (use sparingly, Nerd Font f467)
- `[i]` Cyan - informational message (Nerd Font f129)

### Icon Mappings (Unicode - Active)
Currently using **Unicode only** (Nerd Fonts suspended due to rendering issues):

| Role       | Icon | Color   | Notes |
|------------|------|---------|-------|
| `success`  | `✓`  | Green   | Feature loaded |
| `warning`  | `!`  | Yellow  | Optional missing |
| `error`    | `x`  | Red     | Critical failure |
| `info`     | `i`  | Cyan    | Information |
| `tip`      | `※`  | Blue    | Helpful tip/hint |
| `question` | `?`  | Magenta | User prompt/question |

**Nerd Font codes** (f00c, f071, f467, f129, f0eb, f128) are preserved in `settings/icons.ps1` but not actively used.

---

## Active Tasks

- [001-logging-system.md](./todo/001-logging-system.md) - Reusable logging architecture

## Completed Tasks

- [002-icon-fallback-system.md](./todo/done/002-icon-fallback-system.md) - Icon system (Unicode only, NF suspended)

---

## Documentation

- [ARCHITECTURE.md](./docs/ARCHITECTURE.md) - Project architecture and module structure
- [LOGGING-SYSTEM.md](./docs/LOGGING-SYSTEM.md) - Logging system specification
- [linux-compatibility.md](./docs/linux-compatibility.md) - Linux command compatibility layer

---

## Completed Features

- ✅ Clear-Host removed from help command
- ✅ Fallback functions for all enhanced tools
- ✅ Warning (not error) icons for missing tools
- ✅ Icon system with `Get-FallbackIcon` (Unicode-based, NF experimental/suspended)
