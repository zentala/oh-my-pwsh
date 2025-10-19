# Contributing to oh-my-pwsh

Want to customize your terminal or contribute to the project? This guide covers everything from basic customization to full development workflow.

---

## 🛠️ Technologies Used

| Category | Technologies |
|----------|-------------|
| **Core** | ![PowerShell](https://img.shields.io/badge/PowerShell-%235391FE.svg?style=flat&logo=powershell&logoColor=white) ![Windows](https://img.shields.io/badge/Windows-0078D6?style=flat&logo=windows&logoColor=white) |
| **Testing** | ![Pester](https://img.shields.io/badge/Pester-5.x-blue?style=flat) ![Code Coverage](https://img.shields.io/badge/Coverage-≥75%25-brightgreen?style=flat) |
| **CI/CD** | ![GitHub Actions](https://img.shields.io/badge/GitHub_Actions-2088FF?style=flat&logo=github-actions&logoColor=white) ![Git Hooks](https://img.shields.io/badge/Git_Hooks-Optional-yellow?style=flat) |
| **AI Assistant** | ![Claude Code](https://img.shields.io/badge/Claude_Code-Recommended-blueviolet?style=flat&logo=anthropic&logoColor=white) |
| **Documentation** | ![Markdown](https://img.shields.io/badge/Markdown-000000?style=flat&logo=markdown&logoColor=white) ![MADR](https://img.shields.io/badge/MADR-ADRs-informational?style=flat) |

---

## 📋 Prerequisites

Before you start, make sure you have:

- **PowerShell 7.x** - [Install via winget](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-windows)
- **Git** - Version control
- **Code Editor** - VS Code recommended
- **(Optional but Recommended)** [Claude Code](https://claude.com/claude-code) - AI development assistant

---

## 🚀 Getting Started

### 1. Fork & Clone

```powershell
# Clone your fork
git clone git@github.com:YOUR_USERNAME/pwsh-profile.git
cd pwsh-profile
```

### 2. Install Dependencies

```powershell
# Run the installation script
pwsh -ExecutionPolicy Bypass -File scripts\install-dependencies.ps1
```

### 3. Run Tests

```powershell
# Run all tests
.\scripts\Invoke-Tests.ps1

# Run with coverage report
.\scripts\Invoke-Tests.ps1 -Coverage
```

---

## 📖 Understanding the Documentation Structure

oh-my-pwsh uses a unique documentation system designed to work with both human developers and AI assistants:

### For AI Assistants (Claude Code)

- **`CLAUDE.md`** - Development guide for AI assistant
  - Contains coding conventions, design principles, and architecture decisions
  - **If you're developing with Claude Code:** Claude reads this automatically
  - **If you're developing without Claude:** READ THIS FILE! It contains important project conventions

- **`.claude/runbook/YYYY-MM-DD.md`** - Daily work logs
  - Chronological records of what was done each day
  - Links to modified files, commits, and decisions made

### For Developers (Humans & AI)

- **[`README.md`](./README.md)** - User-facing documentation (how to use oh-my-pwsh)
- **[`CONTRIBUTING.md`](./CONTRIBUTING.md)** (this file) - How to contribute to the project
- **`docs/`** - Technical documentation for implemented features
  - [`ARCHITECTURE.md`](./docs/ARCHITECTURE.md) - Project structure and module organization
  - [`TESTING-STRATEGY.md`](./docs/TESTING-STRATEGY.md) - Testing philosophy and coverage targets
  - [`LOGGING-SYSTEM.md`](./docs/LOGGING-SYSTEM.md) - How to use the status message system
  - [`linux-compatibility.md`](./docs/linux-compatibility.md) - Linux command aliases and compatibility

### Development Tracking

- **`todo/`** - Task management
  - [`todo/INDEX.md`](./todo/INDEX.md) - Master list of all tasks with status
  - `todo/NNN-task-name.md` - Active tasks
  - [`todo/done/`](./todo/done/) - Completed tasks
  - [`todo/backlog/`](./todo/backlog/) - Unrefined ideas

- **[`adr/`](./adr/)** - Architecture Decision Records
  - Uses [MADR](https://adr.github.io/madr/) format
  - Documents important architectural and design decisions
  - See [`adr/README.md`](./adr/README.md) for conventions

---

## 🤖 Developing with Claude Code

**Claude Code is positioned as a junior engineer / development assistant** for this project.

### Why Claude Code?

- Understands project conventions by reading `CLAUDE.md`
- Helps write tests automatically
- Follows DRY principle and coding standards
- Can explain complex PowerShell patterns

### How to Use Claude Code

1. **Install Claude Code:** Follow instructions at [claude.com/claude-code](https://claude.com/claude-code)
2. **Open the project:** Claude automatically reads `CLAUDE.md`
3. **Ask for help:**
   - "Implement fallback handling for bat command"
   - "Write Pester tests for enhanced-tools.ps1"
   - "Explain how the icon system works"

### Developing Without Claude Code

**That's perfectly fine!** Just make sure to:

1. **Read `CLAUDE.md`** - It contains critical development conventions
2. **Follow the same principles:**
   - Zero-error philosophy
   - All enhanced tools are optional with fallbacks
   - Write tests for regression prevention
   - Use DRY principle

---

## ✅ Testing Requirements

**Primary Goal:** Prevent regressions when developing on machines with all tools installed.

### Critical Test Scenarios

ALL tests must verify behavior in these scenarios:

1. ✅ **All tools installed** - bat, eza, ripgrep, fd, delta, fzf, zoxide, oh-my-stats
2. ⚠️ **Some tools missing** - partial installation (e.g., bat yes, eza no)
3. ❌ **No enhanced tools** - only native PowerShell available
4. ❌ **oh-my-stats missing** - profile still loads without errors

### Fallback Testing (CRITICAL)

Every enhanced tool MUST have tests for:

- ✅ Behavior when tool IS installed (happy path)
- ✅ Behavior when tool is NOT installed (fallback path)
- ✅ Warning message shown when missing
- ✅ Fallback to native PowerShell command works
- ✅ No errors thrown in either case

### Running Tests

```powershell
# Run all tests
.\scripts\Invoke-Tests.ps1

# Run with coverage
.\scripts\Invoke-Tests.ps1 -Coverage

# Watch mode (runs on file changes)
.\scripts\Invoke-Tests.ps1 -Watch
```

### Coverage Targets

- **Overall:** ≥ 75% line coverage
- **Tier 1 (core):** 90% - `settings/icons.ps1`, `modules/status-output.ps1`
- **Tier 2 (helpers):** 80% - `modules/logger.ps1`, `modules/linux-compat.ps1`
- **Tier 3 (features):** 70% - `modules/enhanced-tools.ps1`, `modules/help-system.ps1`
- **Tier 4 (orchestration):** 60% - `profile.ps1`

See [TESTING-STRATEGY.md](./docs/TESTING-STRATEGY.md) for complete details.

---

## 🔨 Development Workflow

### 1. Create a Task (Optional for Small Changes)

For significant features or bugs:

```powershell
# Create task file
New-Item "todo/007-my-feature.md" -ItemType File

# Add to todo/INDEX.md
# Follow the template in other task files
```

### 2. Make Your Changes

- Follow conventions in `CLAUDE.md`
- Write or update tests
- Ensure all tests pass

### 3. Update Documentation

- Update `README.md` if adding user-facing features
- Update `docs/` if changing architecture
- Create ADR if making significant architectural decision

### 4. Test Thoroughly

```powershell
# Ensure tests pass
.\scripts\Invoke-Tests.ps1

# Check coverage
.\scripts\Invoke-Tests.ps1 -Coverage
```

### 5. Commit & Push

```powershell
git add .
git commit -m "feat: Add awesome feature"
git push origin your-branch
```

### 6. Create Pull Request

- Reference any related issues or tasks
- Describe what changed and why
- Ensure CI/CD passes (GitHub Actions)

---

## 📐 Code Style & Conventions

### File Naming

- **Markdown files:** `CAPITAL_TITLE.md` (capital name, lowercase extension)
  - ✅ `README.md`, `ARCHITECTURE.md`
  - ❌ `readme.md`, `Architecture.MD`

### Icon System

- **ALL icons** must use `Get-FallbackIcon -Role <name>`
- Never hardcode icons (✓, !, x) directly

```powershell
# ❌ Bad
Write-Host "✓" -ForegroundColor Green

# ✅ Good
$icon = Get-FallbackIcon -Role "success"
Write-Host $icon -ForegroundColor Green
```

### Logging System

- **ALL output** goes through `Write-StatusMessage`
- No direct `Write-Host` for status messages

```powershell
# ✅ Good
Write-StatusMessage -Role "success" -Message "Module loaded"
Write-StatusMessage -Role "warning" -Message "bat not found"
```

See [LOGGING-SYSTEM.md](./docs/LOGGING-SYSTEM.md) for details.

### Error Philosophy

- Profile should **NEVER** fail or throw errors
- All enhanced tools are **OPTIONAL**
- Each tool MUST have a fallback to native PowerShell
- Missing tools show `[!]` warnings (yellow), not errors

---

## 📚 Key Documentation Files

| File | Purpose |
|------|---------|
| [CLAUDE.md](./CLAUDE.md) | Development guide for AI assistant (READ THIS!) |
| [README.md](./README.md) | User documentation |
| [ARCHITECTURE.md](./docs/ARCHITECTURE.md) | Project structure |
| [TESTING-STRATEGY.md](./docs/TESTING-STRATEGY.md) | Testing philosophy |
| [LOGGING-SYSTEM.md](./docs/LOGGING-SYSTEM.md) | Status message system |
| [adr/README.md](./adr/README.md) | Architecture Decision Records index |

---

## 🎯 Design Principles

### Target Users

- Power users
- Often ex-Linux (bash/zsh) users
- Appreciate beauty
- Value visibility into what's happening

### Value Proposition

- Painlessly migrate from Linux (bash/zsh) to Windows (pwsh)
- Preserve your own CLI habits
- Learn about PowerShell commands on the way
- Discover the ecosystem of PowerShell apps

### Core Philosophy

1. **Zero-error philosophy** - Profile never fails
2. **Graceful degradation** - All enhanced tools are optional
3. **DRY principle** - No code duplication
4. **Testable code** - All code must be testable with Pester
5. **Think composability** - Make all code reusable

---

## 💡 Tips for Contributors

1. **Run tests before committing** - Use optional pre-commit hook or run manually
2. **Read existing ADRs** - Understand past decisions
3. **Ask questions** - Open an issue or discussion
4. **Keep it simple** - Solution must be logical and easy to understand
5. **Consider Claude Code** - Even if you don't use it, the conventions help humans too!

---

## 📞 Need Help?

- **Issues:** [GitHub Issues](https://github.com/zentala/pwsh-profile/issues)
- **Discussions:** [GitHub Discussions](https://github.com/zentala/pwsh-profile/discussions)
- **Documentation:** Start with [CLAUDE.md](./CLAUDE.md) and [docs/](./docs/)

---

## 📝 License

MIT - Paweł Żentała © 2025

---

**Thank you for contributing! 🚀**
