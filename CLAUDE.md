# oh-my-pwsh - Claude Development Guide

> **📅 Last Active:** 2025-11-05 | **Status:** ✅ Stable, Production Ready
>
> **⚠️ Personal Project:** May be abandoned at any time. Documentation is designed to be self-explanatory for anyone resuming work (including Future-Me after months/years).

## Project Overview

PowerShell profile with zero-error philosophy and graceful degradation for power users.

**Quick Start (If Resuming After Inactivity):**
1. Read [STATUS.md](./STATUS.md) - Current state, what works, what doesn't
2. Read [DECISIONS.md](./DECISIONS.md) - Why we made certain choices
3. Read [.claude/runbook/2025-10-18.md](./.claude/runbook/2025-10-18.md) - Latest session log
4. Run tests: `./scripts/Invoke-Tests.ps1 -Coverage`
5. Check CI: `gh run list --limit 5`

---

## Installation Scripts

### For End Users (Complete Setup)

**`scripts/Install-OhMyPwsh.ps1`** - One-click installer (recommended)
```powershell
pwsh -ExecutionPolicy Bypass -File scripts\Install-OhMyPwsh.ps1
```

**What it does:**
1. Clones [oh-my-stats](https://github.com/zentala/oh-my-stats) **next to oh-my-pwsh** (same parent dir)
2. Runs `install-dependencies.ps1` (see below)
3. Configures PowerShell profile (backs up existing)
4. Creates `config.ps1` from `config.example.ps1`
5. Optionally installs enhanced tools (with `-InstallEnhancedTools`)

**Parameters:**
- `-InstallEnhancedTools` - Also install bat, eza, ripgrep, fd, delta (via scoop)
- `-InstallNerdFonts` - Also install Nerd Fonts (CaskaydiaCove recommended, via scoop)
- `-SkipDependencies` - Skip dependency installation
- `-SkipProfile` - Skip profile configuration

**Important:**
- ⚠️ Shows UAC warning (winget may require elevation)
- ⚠️ Works anywhere - not hardcoded to C:\code
- 📁 oh-my-stats cloned to: `../oh-my-stats` (relative to oh-my-pwsh)
- 🔄 profile.ps1 searches multiple locations (relative path first, then C:\code for backward compatibility)
- 🔤 Nerd Fonts improve terminal appearance but are optional

**Post-install:** User must restart terminal for PATH updates (fzf, zoxide)

### For Development Setup

**`scripts/install-dependencies.ps1`** - Install required dependencies only

**Installs via winget:**
- Oh My Posh (prompt theme engine)
- fzf (fuzzy finder)
- zoxide (smart directory jumping)
- gsudo (sudo for Windows)

**Installs PowerShell modules:**
- PSReadLine (better command line editing)
- posh-git (git integration)
- Terminal-Icons (file icons)
- PSFzf (fuzzy finder integration)

**Does NOT install:**
- Enhanced tools (bat, eza, ripgrep, fd, delta) - these are optional
- Use `Install-EnhancedTools` function after profile loads
- Requires scoop package manager

### Enhanced Tools (Optional)

**`Install-EnhancedTools`** - Function in `modules/enhanced-tools.ps1`

**Prerequisites:** Scoop package manager
```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
irm get.scoop.sh | iex
```

**Installs:** bat, eza, ripgrep, fd, delta

**Why separate?** Graceful degradation - profile works without enhanced tools

### Nerd Fonts (Optional)

**`modules/nerd-fonts.ps1`** - Nerd Fonts detection and installation

**Functions:**
- `Test-NerdFontInstalled` - Detects Nerd Fonts in Windows registry
- `Get-RecommendedNerdFonts` - Lists recommended fonts with descriptions
- `Install-NerdFonts` - Interactive installer for Nerd Fonts

**Recommended fonts:**
1. **CaskaydiaCove Nerd Font** (default) - Microsoft's Cascadia Code + icons
2. **FiraCode Nerd Font** - Excellent ligatures
3. **JetBrainsMono Nerd Font** - Optimized for IDEs
4. **Meslo Nerd Font** - Universal, very readable

**Installation:**
```powershell
# Interactive menu
Install-NerdFonts

# Silent mode (installs CaskaydiaCove)
Install-NerdFonts -Silent

# Specific font
Install-NerdFonts -FontName "FiraCode-NF"
```

**Via installer:**
```powershell
pwsh -File scripts\Install-OhMyPwsh.ps1 -InstallNerdFonts
```

**After installation:**
1. Restart terminal
2. Configure terminal to use the Nerd Font (Settings → Font Face)
3. Enable in `config.ps1`: `$global:OhMyPwsh_UseNerdFonts = $true`

**Detection:** Profile automatically checks for Nerd Fonts on load and shows hint if missing

**Why optional?** Works best in Windows Terminal / VS Code, may render poorly in older terminals

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
- **When planning tasks:** Always plan tests alongside features (test-first mindset)

### Feature Specifications
- **Location**: `./specs/FEATURE-NAME.md`
- **Purpose**: Single source of truth for how a feature should look/behave (NOT code)
- **Contents:**
  - Feature vision and user stories
  - UI/UX flow (text-based mockups)
  - Expected behavior and edge cases
  - NOT implementation details - only WHAT, not HOW
- **Linking:**
  - Each spec links to related task(s)
  - Each spec links to test file(s)
  - Each spec links to implementation file(s)
- **Why:** Preserve the vision of what/why we want, separate from implementation
- **Format:** Pure text, mockups, user flows - no code examples

**Example:**
```
./specs/smart-editor-suggestions.md
├─ Links to: ./todo/007-smart-editor-suggestions.md
├─ Links to: ./tests/modules/command-suggestions.Tests.ps1
└─ Links to: ./modules/command-suggestions.ps1
```

### Daily Runbooks
- **Location**: `.claude/runbook/YYYY-MM-DD.md`
- **Purpose**: Daily work log with links to files, tasks, and commits
- **Contents**:
  - What was done today
  - Links to modified files
  - Links to tasks (if task has own runbook, link to it; otherwise describe work here)
  - Commits made
  - Small tasks/fixes without separate task documentation
  - Decisions made
  - Blockers/issues encountered
- **Format**: Chronological, markdown, concise
- **When**: Create/update at end of session or when significant work done

### Documentation vs Tasks
- `./docs/` - **User documentation** for implemented features (how to use)
- `./todo/` - **Development documentation** (how to implement/architecture decisions)
- Every `./docs/` file linked in CLAUDE.md with description

### Architecture Decision Records (ADRs)
- **Location**: `./adr/NNN-short-title.md`
- **Format**: [MADR](https://adr.github.io/madr/) (Markdown Any Decision Records)
- **Purpose**: Document important architectural and design decisions
- **Naming**: Zero-padded 3 digits + lowercase-with-hyphens (e.g., `001-pester-test-framework.md`)
- **Index**: All ADRs listed in [adr/README.md](./adr/README.md)
- **Cross-linking**: ADRs link to related tasks, docs, and other ADRs

**When to create an ADR:**
- Significant architectural decision
- Choosing between multiple valid approaches
- Setting a technical standard or convention
- Making a trade-off that affects multiple components

**Format:**
```markdown
# ADR-NNN: Title
Status: [Proposed | Accepted | Deprecated | Superseded]
Date: YYYY-MM-DD

## Context
What is the issue?

## Decision
What did we decide?

## Consequences
Positive/Negative/Neutral impacts

## Alternatives Considered
What other options did we evaluate?

## Related
- Links to tasks, docs, other ADRs
```

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
- **ALL output** goes through `Write-StatusMessage` function
- No direct `Write-Host` chains in code
- `Write-StatusMessage` uses `Get-FallbackIcon` for icons
- Supports both simple strings and styled message segments
- See: [LOGGING-SYSTEM.md](./docs/LOGGING-SYSTEM.md) for architecture

**Example:**
```powershell
# Simple string
Write-StatusMessage -Role "success" -Message "Module loaded"

# Styled segments
$segments = @(
    @{Text = "install "; Color = "White"}
    @{Text = "bat"; Color = "Yellow"}
    @{Text = ": "; Color = "White"}
    @{Text = "scoop install bat"; Color = "DarkGray"}
)
Write-StatusMessage -Role "warning" -Message $segments
```

---

## Testing Requirements

### Primary Goal: Regression Prevention

**User Story:**
> "As a developer, I want tests to run automatically before pushing, so I don't accidentally remove features that already worked."

### The Problem
oh-my-pwsh is a console solution with conditional logic for optional dependencies. It's easy to accidentally remove fallback handling for missing packages when developing on a machine where everything is installed.

### Critical Test Scenarios

**ALL tests must verify behavior in these scenarios:**

1. **All tools installed** - bat, eza, ripgrep, fd, delta, fzf, zoxide, oh-my-stats
2. **Some tools missing** - partial installation (e.g., bat yes, eza no)
3. **No enhanced tools** - only native PowerShell available
4. **oh-my-stats missing** - profile still loads without errors

### Testing Fallback Behavior (CRITICAL)

Every enhanced tool MUST have tests for:
- ✅ Behavior when tool IS installed (happy path)
- ✅ Behavior when tool is NOT installed (fallback path)
- ✅ Warning message shown when missing
- ✅ Fallback to native PowerShell command works
- ✅ No errors thrown in either case

**Example:**
```powershell
Describe "bat fallback" {
    Context "When bat is NOT installed" {
        BeforeAll {
            Mock Get-Command { $null } -ParameterFilter { $Name -eq "bat" }
        }

        It "Falls back to Get-Content" { }
        It "Shows warning with install hint" { }
        It "Does not throw errors" { }
    }
}
```

### Install Script Consistency

**Requirement:** Install script must stay synchronized with profile.

- If install script lists a tool → profile must handle it being missing
- If profile uses a tool → install script should list it (or document why not)
- Test verifies this consistency automatically

### Automated Testing

**When tests run:**
- Locally: `./scripts/Invoke-Tests.ps1`
- Before commit: Optional git pre-commit hook (< 30 seconds)
- Before merge: GitHub Actions CI (required, cannot bypass)

**What tests prevent:**
- Accidentally removing fallback code
- Breaking conditional handling
- Profile failing on machines without enhanced tools
- Regressions in existing features

### Test Coverage Targets

**Overall:** ≥ 75% line coverage

**By Tier:**
- Tier 1 (core): 90% - `settings/icons.ps1`, `modules/status-output.ps1`
- Tier 2 (helpers): 80% - `modules/logger.ps1`, `modules/linux-compat.ps1`
- Tier 3 (features): 70% - `modules/enhanced-tools.ps1`, `modules/help-system.ps1`
- Tier 4 (orchestration): 60% - `profile.ps1`

**See:** [TESTING-STRATEGY.md](./docs/TESTING-STRATEGY.md) for full strategy

---

## Development Principles

1. **Follow DRY principle**
   - Make all code reusable
   - Avoid duplication
   - Think composability

2. **Write testable code**
   - All code must be testable with Pester
   - All enhanced tools must have fallback behavior tests
   - Tests run before push (optional git hook)
   - Tests run in CI/CD pipeline (required)

3. **Align with user (dev) before implementing**
   - Discuss architecture decisions
   - Think like solution architect, not just coder
   - Solution must be logical and simple to understand
   - Abstractions are OK if they improve clarity

---

## Design Principles

### `Target Users`
 - Power users
 - often ex Linux users
 - appreciate beauty

### Value propostion for `Target Users`

- painless migration from Linux (bash/zsh) to Windows(pwsh):
  - preserving your own CLI habbits
  - learingn about PWSH commands on the way 
  - discovering ecosystem of (awesome) pwsh apps

### Your role

When designing for `Target Users`, enter into role of `Developer Experience Engienier`.
Design theirs `User Stories`, align them with me and and then design under those stories. 
Eg. eg 
 - migration from windows: `Linux console user wants to discover pwsh apps ecosystem that will help him quickly migrate from oh-my-zsh. He is missing his CLI code editor... therefore when user will call some linux editor command we will propose him to install anlternative.` 
 - exploeration: 

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
- `[ ]` Red - critical error (use sparingly, Nerd Font f467)
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

- [005-testing-infrastructure.md](./todo/005-testing-infrastructure.md) - **P1** - Testing infrastructure with Pester, CI/CD, coverage
- [006-contributors-documentation.md](./todo/006-contributors-documentation.md) - **P2** - Contributors guide with tech stack and Claude Code info
- [003-nerd-font-architecture.md](./todo/003-nerd-font-architecture.md) - **Experimental** - NF partial support (suspended)

## Completed Tasks

- [001-logging-system.md](./todo/done/001-logging-system.md) - Message segment composition for styled output
- [004-write-status-message.md](./todo/done/004-write-status-message.md) - Colored status output (Option B)
- [002-icon-fallback-system.md](./todo/done/002-icon-fallback-system.md) - Icon system (Unicode working, NF experimental)

---

## Documentation

### Technical Documentation
- [ARCHITECTURE.md](./docs/ARCHITECTURE.md) - Project architecture and module structure
- [LOGGING-SYSTEM.md](./docs/LOGGING-SYSTEM.md) - Logging system specification and usage
- [TESTING-STRATEGY.md](./docs/TESTING-STRATEGY.md) - Testing strategy, coverage targets, CI/CD
- [linux-compatibility.md](./docs/linux-compatibility.md) - Linux command compatibility layer

### Architecture Decisions
- [adr/README.md](./adr/README.md) - ADR index and conventions
- [ADR-001](./adr/001-pester-test-framework.md) - Pester as test framework
- [ADR-002](./adr/002-test-isolation-strategy.md) - Test isolation strategy (3 layers)
- [ADR-003](./adr/003-coverage-targets.md) - Code coverage targets (75% overall)
- [ADR-004](./adr/004-git-hooks-optional.md) - Git hooks optional (developer-friendly)

---

## Implemented Features

### Core Systems
- ✅ **Icon Fallback System** - `Get-FallbackIcon` with Unicode (default) and experimental Nerd Font support
- ✅ **Status Message System** - `Write-StatusMessage` with granular color control
- ✅ **Message Segment Composition** - Styled text segments for complex messages
- ✅ **Logging Helpers** - `Write-InstallHint`, `Write-ToolStatus`, `Write-ModuleStatus`

### Profile Behavior
- ✅ Zero-error philosophy - profile never fails
- ✅ Graceful degradation - all enhanced tools are optional
- ✅ Fallback functions for: bat, eza, ripgrep, fd, delta, fzf, zoxide
- ✅ Warning (yellow `[!]`) for missing tools, not errors
- ✅ Clean help output (no Clear-Host)

### Developer Experience
- ✅ Task management system (./todo/)
- ✅ Daily runbooks (.claude/runbook/)
- ✅ Comprehensive documentation
- ✅ DRY principle - no code duplication
