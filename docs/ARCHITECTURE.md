# oh-my-pwsh Architecture

> **Last Updated:** 2025-10-19
> **Status:** Current implementation, not TODO

## Philosophy

**Goal**: Zero-error PowerShell profile for power users with optional enhancements

### Core Principles

1. **Never Fail**: Profile must load without errors, even if tools are missing
2. **Graceful Degradation**: All enhanced tools are optional with native fallbacks
3. **Visibility**: Users see what loaded and what's available to install
4. **Power User Focus**: Show all warnings/errors, don't hide anything behind loaders
5. **Teacher Mode**: Optional PowerShell learning assistant (shows cmdlet equivalents)

## Directory Structure

```
pwsh-profile/
├── profile.ps1              # Main entry point
├── config.ps1               # User configuration (gitignored)
├── config.example.ps1       # Configuration template
│
├── modules/                 # Core functionality modules
│   ├── status-output.ps1    # ✅ NEW: Write-StatusMessage function
│   ├── logger.ps1           # ✅ UPDATED: Helper functions using Write-StatusMessage
│   ├── environment.ps1      # Environment variables, PATH setup
│   ├── psreadline.ps1       # PSReadLine configuration
│   ├── aliases.ps1          # Custom aliases
│   ├── functions.ps1        # Utility functions (touch, mkcd, .., ...)
│   ├── git-helpers.ps1      # Git convenience functions (gs, ga, gc, gp)
│   ├── enhanced-tools.ps1   # Optional enhanced CLI tools (bat, eza, rg, fd, delta)
│   ├── linux-compat.ps1     # Linux-like command aliases
│   └── help-system.ps1      # Custom help command
│
├── settings/                # ✅ NEW: Configuration and icon definitions
│   └── icons.ps1            # Icon system with Nerd Font/Unicode fallback
│
├── scripts/                 # Utility and tooling scripts
│   ├── install-dependencies.ps1  # Dependency installer
│   ├── Install-TestDeps.ps1      # ✅ NEW: Test framework installer (Pester)
│   ├── Invoke-Tests.ps1          # ✅ NEW: Test runner with coverage & watch mode
│   ├── New-TestFile.ps1          # ✅ NEW: Test scaffolding generator
│   ├── Install-GitHooks.ps1      # ✅ NEW: Git hook installer (optional)
│   └── Show-Coverage.ps1         # ✅ NEW: Coverage report viewer
│
├── tests/                   # ✅ NEW: Comprehensive test suite (Pester 5.x)
│   ├── Unit/                # Unit tests (176 tests, 100% critical modules)
│   ├── Integration/         # Integration tests (cross-module)
│   ├── Helpers/             # Test utilities and templates
│   │   ├── TestHelpers.ps1  # Builder pattern for test configs
│   │   └── Templates/       # Test file templates
│   ├── Fixtures/            # Test data (config-*.ps1)
│   └── Coverage/            # Coverage reports (gitignored)
│
├── themes/                  # Oh My Posh themes (optional)
│
├── docs/                    # ✅ UPDATED: Complete documentation
│   ├── ARCHITECTURE.md      # This file
│   ├── LOGGING-SYSTEM.md    # ✅ NEW: Logging system specification
│   ├── TESTING-STRATEGY.md  # ✅ NEW: Testing philosophy and strategy
│   ├── CODECOV-SETUP.md     # ✅ NEW: Codecov integration guide (optional)
│   └── linux-compatibility.md  # Linux command reference
│
├── adr/                     # ✅ NEW: Architecture Decision Records
│   ├── README.md            # ADR index
│   ├── 001-pester-test-framework.md
│   ├── 002-test-isolation-strategy.md
│   ├── 003-coverage-targets.md
│   └── 004-git-hooks-optional.md
│
├── todo/                    # ✅ NEW: Task management
│   ├── INDEX.md             # Master task list
│   ├── NNN-task-name.md     # Active tasks
│   ├── done/                # Completed tasks
│   └── backlog/             # Future enhancements
│
├── .github/                 # ✅ NEW: GitHub integrations
│   ├── workflows/
│   │   └── tests.yml        # CI/CD (Windows + Ubuntu, auto on push/PR)
│   └── hooks/
│       └── pre-commit       # Optional pre-commit hook (runs unit tests)
│
├── .claude/                 # ✅ NEW: Claude Code development assistance
│   ├── runbook/             # Daily work logs
│   │   ├── 2025-10-18.md    # Testing infrastructure session
│   │   └── 2025-10-19.md    # Contributors documentation session
│   └── settings.local.json  # Claude settings (gitignored)
│
├── STATUS.md                # ✅ NEW: Project status snapshot
├── DECISIONS.md             # ✅ NEW: Key decision context
├── CONTRIBUTING.md          # ✅ NEW: Contribution guide
├── LICENSE                  # ✅ NEW: MIT License with alpha disclaimer
└── README.md                # User-facing documentation
```

## Module Loading Order

The order matters for dependencies:

1. **Settings** (`settings/icons.ps1`)
   - Load icon definitions first (used by status-output)

2. **Status Output** (`modules/status-output.ps1`)
   - Core `Write-StatusMessage` function
   - Used by all other modules

3. **Logger Helpers** (`modules/logger.ps1`)
   - Helper functions: `Write-InstallHint`, `Write-ToolStatus`, `Write-ModuleStatus`
   - Uses `Write-StatusMessage`

4. **Core Dependencies** (Terminal-Icons, posh-git, PSFzf, zoxide)
   - Optional PowerShell modules
   - Status logged via `Write-ModuleStatus`

5. **Core Modules** (environment, psreadline, aliases, functions, git-helpers)
   - Baseline functionality
   - No external dependencies

6. **Optional Features** (enhanced-tools, linux-compat, help-system)
   - Controlled by config flags
   - Graceful fallbacks

7. **Oh My Posh** (prompt theme)
   - Visual prompt customization

8. **oh-my-stats** (system info display)
   - Loads last so errors/warnings appear above it

## Status Message System

### Architecture (3 Layers)

```
┌─────────────────────────────────────┐
│  LAYER 3: Semantic Helpers          │
│  Write-ToolStatus, Write-InstallHint│  modules/logger.ps1
│  "WHAT to say"                      │
├─────────────────────────────────────┤
│  LAYER 2: Message Composer          │
│  Styled text segments               │  (caller responsibility)
│  "HOW to structure"                 │
├─────────────────────────────────────┤
│  LAYER 1: Write-StatusMessage       │
│  Single output function             │  modules/status-output.ps1
│  "HOW to render"                    │
└─────────────────────────────────────┘
         ↓ uses ↓
┌─────────────────────────────────────┐
│  LAYER 0: Icon System               │
│  Get-FallbackIcon, Get-IconColor    │  settings/icons.ps1
│  Nerd Font / Unicode detection      │
└─────────────────────────────────────┘
```

### Core Functions

#### Layer 0: Icon System (`settings/icons.ps1`)

**Purpose:** Universal icon definitions with Nerd Font/Unicode fallback

**Functions:**
- `Get-FallbackIcon -Role <name>` - Returns appropriate icon (NF or Unicode)
- `Get-IconColor -Role <name>` - Returns role color
- `Test-NerdFontSupport` - Detects if Nerd Fonts are enabled

**Roles:** `success`, `warning`, `error`, `info`, `tip`, `question`

**State:** ✅ IMPLEMENTED
- Nerd Font support: EXPERIMENTAL (suspended, default OFF)
- Unicode fallback: ACTIVE (default)
- Custom icon overrides: Supported

#### Layer 1: Status Output (`modules/status-output.ps1`)

**Purpose:** Core rendering function - ALL output goes through this

**Function:** `Write-StatusMessage`

```powershell
Write-StatusMessage -Role <role> -Message <text|segments> [-NoIndent]
```

**Parameters:**
- `Role` (required): success | warning | error | info | tip | question
- `Message` (required): String OR array of styled segments
- `NoIndent` (optional): Skip 2-space indent

**Output Modes:**
- **Unicode** (default): `  [✓] message`
- **Nerd Font**: `  󰄵 message`

**Color Control:**
- Brackets: `DarkGray`
- Icon: Role-specific (Green/Yellow/Red/Cyan/Blue/Magenta)
- Text: `White` (or custom with segments)

**State:** ✅ IMPLEMENTED (supports styled segments)

#### Layer 2: Message Composition

**Purpose:** Build complex messages with color control

**Pattern:**
```powershell
# Simple string
Write-StatusMessage -Role "success" -Message "bat (enhanced cat)"

# Styled segments (advanced)
$segments = @(
    @{Text = "install "; Color = "White"}
    @{Text = "bat"; Color = "Yellow"}
    @{Text = ": "; Color = "White"}
    @{Text = "scoop install bat"; Color = "DarkGray"}
)
Write-StatusMessage -Role "warning" -Message $segments
```

**State:** ✅ IMPLEMENTED

#### Layer 3: Semantic Helpers (`modules/logger.ps1`)

**Purpose:** Domain-specific convenience functions

**Functions:**

```powershell
# Tool status (checks if CLI tool is installed)
Write-ToolStatus -Name "bat" -Installed $true -Description "enhanced cat"
Write-ToolStatus -Name "eza" -Installed $false -ScoopPackage "eza"

# Module status (checks if PS module is loaded)
Write-ModuleStatus -Name "PSFzf" -Loaded $true -Description "Ctrl+R, Ctrl+T"

# Install hint (shows install command)
Write-InstallHint -Tool "fzf" -Description "fuzzy finder" -InstallCommand "winget install fzf"

# Generic profile status
Write-ProfileStatus -Level "success" -Primary "Configuration loaded"
```

**State:** ✅ IMPLEMENTED

### Message Types & Colors

| Role | Icon (Unicode) | Icon (NF) | Color | Usage |
|------|----------------|-----------|-------|-------|
| `success` | ✓ | 󰄵 | Green | Feature loaded successfully |
| `warning` | ! | 󰗖 | Yellow | Optional feature missing |
| `error` | x |  | Red | Critical failure |
| `info` | i |  | Cyan | Informational message |
| `tip` | ※ |  | Blue | Helpful hint |
| `question` | ? |  | Magenta | User prompt |

### Example Outputs

**Success (tool installed):**
```
  [✓] bat (enhanced cat)
```

**Warning (tool missing):**
```
  [!] install `eza` for modern ls: scoop install eza
```

**Error (critical failure):**
```
  [x] PowerShell 7+ required
```

**Info (non-actionable):**
```
  [i] Profile loaded in 1234ms
```

## Enhanced Tools with Fallbacks

All enhanced tools are **optional** with native PowerShell fallbacks:

| Tool | Purpose | Fallback | Config Flag |
|------|---------|----------|-------------|
| bat | Better `cat` | `Get-Content` | `$OhMyPwsh_UseEnhancedTools` |
| eza | Modern `ls` | `Get-ChildItem` | `$OhMyPwsh_UseEnhancedTools` |
| ripgrep | Fast `grep` | `Select-String` | `$OhMyPwsh_UseEnhancedTools` |
| fd | Fast `find` | `Get-ChildItem -Recurse` | `$OhMyPwsh_UseEnhancedTools` |
| delta | Git diff viewer | git default pager | `$OhMyPwsh_UseEnhancedTools` |
| fzf | Fuzzy finder (binary) | PSReadLine defaults | (PSFzf module) |
| zoxide | Smart `cd` | `Set-Location` | (zoxide module) |

### Implementation Pattern

```powershell
# modules/enhanced-tools.ps1
if (Get-Command bat -ErrorAction SilentlyContinue) {
    # Tool installed - use it
    function cat { bat @args }
    Write-ToolStatus -Name "bat" -Installed $true -Description "enhanced cat"
} else {
    # Tool missing - fallback + install hint
    function cat { Get-Content @args }
    Write-ToolStatus -Name "bat" -Installed $false -Description "enhanced cat" -ScoopPackage "bat"
}
```

**Key:** Profile never fails, user always gets functionality (native or enhanced).

## Configuration System

User configuration in `config.ps1` (gitignored):

```powershell
# Feature Flags
$global:OhMyPwsh_EnableLinuxCompat = $true      # Linux-style aliases
$global:OhMyPwsh_UseEnhancedTools = $true       # bat, eza, ripgrep, fd, delta
$global:OhMyPwsh_EnableCustomHelp = $true       # Custom help command
$global:OhMyPwsh_UseNerdFonts = $false          # Nerd Font icons (experimental)

# Feedback & Learning
$global:OhMyPwsh_ShowAliasTargets = $true       # Teacher mode (show PS equivalents)
$global:OhMyPwsh_ShowFeedback = $true           # Operation feedback messages
$global:OhMyPwsh_ShowWelcome = $true            # Welcome tip on startup

# Startup Display
$global:DisableFastfetch = $true                # Disable fastfetch at startup

# Custom Icons (optional)
# $global:OhMyPwsh_CustomIcons = @{
#     success = "✅"
#     warning = "⚠️"
# }
```

**Template:** `config.example.ps1` (committed to repo)

## Testing Infrastructure

### Overview

- **Framework:** Pester 5.7.1
- **Coverage:** 36.69% overall, 100% on critical modules
- **Tests:** 176 passing (0 failures)
- **CI/CD:** GitHub Actions (Windows + Ubuntu)
- **Execution:** ~11 seconds

### Test Structure

```
tests/
├── Unit/                        # 148 tests (~84%)
│   ├── Icons.Tests.ps1          # Icon system (17 tests, 93.5% coverage)
│   ├── StatusMessage.Tests.ps1  # Status output (13 tests, 100% coverage)
│   ├── Logger.Tests.ps1         # Logger helpers (84 tests, 100% coverage)
│   ├── LinuxCompat.Tests.ps1    # Linux compatibility (64 tests, 82.1% coverage)
│   ├── EnhancedTools.Tests.ps1  # Enhanced tools (16 tests)
│   └── FallbackBehavior.Tests.ps1  # ✅ CRITICAL: 32 regression tests
│
├── Integration/                 # 12 tests (~7%)
│   └── LoggingFlow.Tests.ps1    # Cross-module integration
│
├── Helpers/
│   ├── TestHelpers.ps1          # Builder pattern for test configs
│   └── Templates/               # Test scaffolding templates
│       └── Unit.Tests.ps1.template
│
└── Fixtures/                    # Test data
    ├── config-all-tools.ps1     # Full installation scenario
    ├── config-no-tools.ps1      # Clean machine scenario
    └── config-partial-tools.ps1 # Partial installation scenario
```

### Coverage Targets (Tiered)

| Tier | Modules | Coverage | Target | Status |
|------|---------|----------|--------|--------|
| **1** (core) | logger, status-output, icons | 95.7% | 90% | ✅ EXCEEDED |
| **2** (helpers) | linux-compat | 87.7% | 80% | ✅ EXCEEDED |
| **3** (features) | enhanced-tools | Covered | 70% | ✅ TESTED |
| **4** (orchestration) | profile, help-system | Not tested | 60% | ⏸️ Optional |
| **Overall** | All modules | 36.69% | 75% | ⚠️ Below target |

**Philosophy:** Quality > Quantity (100% on critical modules > 75% overall)

### Test Execution

```powershell
# Run all tests
./scripts/Invoke-Tests.ps1

# Run with coverage
./scripts/Invoke-Tests.ps1 -Coverage

# Watch mode (auto-rerun on changes)
./scripts/Invoke-Tests.ps1 -Watch

# Install optional git hooks
./scripts/Install-GitHooks.ps1
```

### CI/CD Integration

**GitHub Actions:** `.github/workflows/tests.yml`
- Triggers: Push to main, Pull requests
- Matrix: Windows (windows-latest), Ubuntu (ubuntu-latest)
- Steps:
  1. Install Pester 5.5.0+
  2. Run tests with coverage
  3. Upload coverage artifacts (30-day retention)
  4. Fail if coverage < 30% (critical threshold)

**Badge:** ![Tests](https://github.com/zentala/pwsh-profile/actions/workflows/tests.yml/badge.svg)

### Developer Tools

- **Pre-commit hook** (optional): Runs unit tests before commit
  - Bypassable with `--no-verify`
  - Takes ~10-20 seconds
  - Philosophy: Helpful but not mandatory (ADR-004)

- **Test scaffolding:** `New-TestFile.ps1`
  - Generates test files from templates
  - AAA pattern (Arrange-Act-Assert)
  - Auto-naming with PascalCase

- **Watch mode:** FileSystemWatcher with 2-second debounce
  - Auto-reruns on file changes
  - Clear screen + timestamp
  - Ignores .git and coverage files

## Documentation

### User Documentation

- **[README.md](../README.md)** - User-facing guide
- **[docs/linux-compatibility.md](./linux-compatibility.md)** - Linux command reference

### Developer Documentation

- **[CONTRIBUTING.md](../CONTRIBUTING.md)** - How to contribute or customize
- **[ARCHITECTURE.md](./ARCHITECTURE.md)** - This file (architecture overview)
- **[LOGGING-SYSTEM.md](./LOGGING-SYSTEM.md)** - Logging system specification
- **[TESTING-STRATEGY.md](./TESTING-STRATEGY.md)** - Testing philosophy and approach
- **[CODECOV-SETUP.md](./CODECOV-SETUP.md)** - Optional Codecov integration guide

### Project Management

- **[STATUS.md](../STATUS.md)** - Project snapshot (what works, what doesn't)
- **[DECISIONS.md](../DECISIONS.md)** - Key decision context (why things are the way they are)
- **[todo/INDEX.md](../todo/INDEX.md)** - Master task list
- **[.claude/runbook/](../.claude/runbook/)** - Daily work logs

### Architecture Decisions

- **[adr/README.md](../adr/README.md)** - ADR index
- **[ADR-001](../adr/001-pester-test-framework.md)** - Why Pester 5.x
- **[ADR-002](../adr/002-test-isolation-strategy.md)** - 3-layer test strategy
- **[ADR-003](../adr/003-coverage-targets.md)** - Tiered coverage targets
- **[ADR-004](../adr/004-git-hooks-optional.md)** - Optional git hooks philosophy

## Design Decisions

### Why Warnings Instead of Errors?

Enhanced tools improve UX but aren't required. Users should:
- ✅ See what's available to install (transparency)
- ✅ Not be blocked from using the terminal (graceful degradation)
- ✅ Get immediate value without installing anything (fallbacks work)

**Result:** Profile never fails, even with zero enhanced tools installed.

### Why Centralized Logging?

**Benefits:**
- **Consistency:** All messages have same format
- **Maintainability:** Change format in one place
- **Testability:** Single function to test vs scattered `Write-Host` calls
- **Flexibility:** Easy to add colors, icons, themes
- **Composability:** Build complex messages from simple parts
- **Future-proof:** Ready for verbosity levels, themes, icon packs

**State:** ✅ Fully implemented (tasks 001, 002, 004 completed)

### Why Load Order Matters?

1. **Icons** must load first (used by status-output)
2. **Status output** must load before logger helpers
3. **Logger** must load before modules that use it
4. **Core modules** establish baseline functionality
5. **Enhanced tools** override with better alternatives
6. **oh-my-stats** loads last (errors/warnings appear above it)

### Why Optional Git Hooks?

**Philosophy:** Helpful but not mandatory (ADR-004)

**Rationale:**
- Developer autonomy > forced workflow
- WIP commits are legitimate use case
- CI is the ultimate quality gate
- Always bypassable with `--no-verify`

**Result:** Opt-in developer experience enhancement, not blocker.

### Why Teacher Mode?

**Philosophy:** Learn PowerShell while maintaining productivity

**Implementation:**
- Shows PowerShell equivalents: `mkdir → New-Item -ItemType Directory`
- Enabled by default (`$OhMyPwsh_ShowAliasTargets = $true`)
- Non-intrusive (doesn't slow down commands)
- Future enhancement: Verbosity levels (task 011)

**Result:** Users learn PowerShell gradually without friction.

## Future Enhancements

See [todo/backlog/](../todo/backlog/) for planned features:

- **[007-smart-editor-suggestions.md](../todo/backlog/007-smart-editor-suggestions.md)** - Missing command hints (vim→nvim, ee→micro)
- **[011-teacher-mode-verbosity-levels.md](../todo/backlog/011-teacher-mode-verbosity-levels.md)** - Enhanced teacher mode (silent/error/info/verbose)
- **[009-interactive-installer.md](../todo/backlog/009-interactive-installer.md)** - Interactive tool installer
- **[008-ai-cli-integration.md](../todo/backlog/008-ai-cli-integration.md)** - AI CLI integration (research)

## Version History

- **2025-10-19:** Complete architecture documentation update
  - Added testing infrastructure section
  - Updated status message system with 3-layer architecture
  - Added configuration system details
  - Documented CI/CD integration
  - Removed "TODO" sections (now implemented)
  - Added comprehensive documentation index

- **2025-10-18:** Testing infrastructure implementation (task 005)
  - Phases 1-4 complete (176 tests, CI/CD, dev tools)
  - 100% coverage on critical modules

- **2025-10-17:** Logging system implementation (tasks 001, 002, 004)
  - `Write-StatusMessage` with styled segments
  - Icon system with Nerd Font/Unicode fallback
  - Helper functions in logger.ps1

- **Earlier:** Initial profile structure and Linux compatibility

---

**Last Updated:** 2025-10-19
**Maintainer:** Paweł Żentała
**Status:** ✅ Current (not TODO, reflects actual implementation)
