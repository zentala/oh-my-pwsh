# 🚀 oh-my-pwsh

![Tests](https://github.com/zentala/pwsh-profile/actions/workflows/tests.yml/badge.svg)
[![Stability](https://img.shields.io/badge/stability-alpha-f4d03f.svg)](https://github.com/mkenney/software-guides/blob/master/STABILITY-BADGES.md#alpha)
[![Version](https://img.shields.io/badge/version-0.0.1--alpha-blue.svg)](https://github.com/zentala/pwsh-profile/releases)
[![PowerShell](https://img.shields.io/badge/PowerShell-7.x-5391FE.svg?logo=powershell&logoColor=white)](https://github.com/PowerShell/PowerShell)
[![Platform](https://img.shields.io/badge/platform-Windows-0078D6.svg?logo=windows&logoColor=white)](https://www.microsoft.com/windows)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](./LICENSE)

**PowerShell Profile Enhanced** - A modern, modular PowerShell configuration that brings the best of Linux CLI experience to Windows with optional enhanced tools.

> ⚠️ **Alpha Status:** This project works for the maintainer but is under active development. APIs and configuration may change. Use in production at your own risk.

<img src="https://cdn.zentala.io/terminal/pwsh.png" alt="PowerShell Terminal Screenshot" style="max-width: 700px; height: auto;">

---

## 🎯 For Linux Users Migrating to Windows

**Missing your beloved bash/zsh workflow?** You're not alone.

oh-my-pwsh helps you **painlessly migrate from Linux to Windows** while:
- ✅ **Preserving your CLI habits** - Keep using `ls -la`, `grep`, `cat`, `touch`, and other familiar commands
- 📚 **Learning PowerShell on the way** - Optional learning mode shows PowerShell equivalents for every command
- 🚀 **Discovering awesome PowerShell apps** - Modern tools like `bat`, `eza`, `ripgrep`, `fzf`, and `zoxide`
- 💎 **Appreciating beauty** - Stunning prompt with [Oh My Posh](https://ohmyposh.dev/) (PowerShell's answer to oh-my-zsh)

**For power users** - Every feature is optional, every tool has fallbacks, and you control your environment.

---

## ✨ What You Get

### 🎨 Beautiful Terminal
- **[Oh My Posh](https://ohmyposh.dev/)** - Stunning prompt with git status, execution time, and more
- **[posh-git](https://github.com/dahlbyk/posh-git)** - Git branch/status integration in prompt
- **[Terminal Icons](https://github.com/devblackops/Terminal-Icons)** - Colorful file/folder icons
- **[Oh My Stats](https://github.com/zentala/oh-my-stats)** - System stats (CPU, RAM, disk) on startup

### ⚡ Productivity Tools
- **[PSReadLine](https://github.com/PowerShell/PSReadLine)** - Fish/Zsh-like autocompletion with history
- **[PSFzf](https://github.com/kelleyma49/PSFzf)** - Fuzzy search for files, history, git (`Ctrl+R`, `Ctrl+T`)
- **[zoxide](https://github.com/ajeetdsouza/zoxide)** - Smart directory jumping - `z` remembers your most used folders
- **[gsudo](https://github.com/gerardog/gsudo)** - Linux-style `sudo` for Windows

### 🐧 Linux-Style Experience
- **Aliases** - `ls -la`, `grep`, `cat`, `touch`, `mkdir -p`, `which`, `curl`, `wget`, and more
- **Git shortcuts** - `gs` (status), `ga` (add), `gc "msg"` (commit), `gp` (push), `gl` (log)
- **Quick navigation** - `..`, `...`, `....`, `~`, `mkcd newdir`, `z folder`
- **Helper functions** - `touch`, `mkcd`, `sudo`, and more
- **Learning mode** - See PowerShell equivalents for each command
- **Smart suggestions** _(Coming Soon)_ - Type `vim` or `ee`? Get suggestions for Windows alternatives (`nvim`, `micro`) with one-click install

### ⚡ Enhanced Tools (Optional)
Modern alternatives to classic Unix tools:
- **[bat](https://github.com/sharkdp/bat)** → Better `cat` with syntax highlighting
- **[eza](https://github.com/eza-community/eza)** → Modern `ls` with icons and colors
- **[ripgrep](https://github.com/BurntSushi/ripgrep)** → Faster `grep` for searching
- **[fd](https://github.com/sharkdp/fd)** → Faster `find` for locating files
- **[delta](https://github.com/dandavison/delta)** → Beautiful `git diff` viewer

## 📂 Structure

```
oh-my-pwsh/
├── profile.ps1                    # Main entry point
├── config.ps1                     # Your config (gitignored)
├── config.example.ps1             # Config template
├── modules/
│   ├── linux-compat.ps1          # Linux-style aliases (optional)
│   ├── enhanced-tools.ps1        # Modern tool integrations (optional)
│   ├── help-system.ps1           # Custom help command
│   ├── functions.ps1             # Helper functions (touch, mkcd, .., ...)
│   ├── git-helpers.ps1           # Git shortcuts (gs, ga, gc, gp, ...)
│   ├── psreadline.ps1            # PSReadLine configuration
│   └── environment.ps1           # PATH & environment variables
├── scripts/
│   └── install-dependencies.ps1  # Automatic dependency installer
└── themes/                        # Oh My Posh themes (optional)
```

## 🔧 Installation

### Quick Install (Automated)

1. **Clone the repo:**
   ```powershell
   cd C:\code
   git clone git@github.com:zentala/pwsh-profile.git
   cd pwsh-profile
   ```

2. **Run installation script:**
   ```powershell
   pwsh -ExecutionPolicy Bypass -File scripts\install-dependencies.ps1
   ```

   This will automatically check and install all dependencies!

3. **Configure oh-my-pwsh:**
   ```powershell
   # Config will be created automatically on first run
   # Edit it to customize your experience
   code config.ps1
   ```

4. **Install enhanced tools (optional but recommended):**
   ```powershell
   # After restarting PowerShell, run:
   Install-EnhancedTools
   ```

5. **Restart PowerShell** and type `help` to see what's available!

---

### Manual Install (Step by Step)

### 1. Clone the repo

```powershell
cd C:\code
git clone git@github.com:zentala/pwsh-profile.git
```

### 2. Install PowerShell 7.x

```powershell
winget install Microsoft.PowerShell
```

### 3. Install Required Tools

```powershell
# Oh My Posh - Beautiful prompt
winget install JanDeDobbeleer.OhMyPosh

# fzf - Fuzzy finder binary (required for PSFzf)
winget install fzf

# zoxide - Smart directory jumping (Rust-based, super fast)
winget install ajeetdsouza.zoxide

# gsudo - Linux-style sudo for Windows
winget install gerardog.gsudo
```

### 4. Install PowerShell Modules

```powershell
# PSReadLine - Advanced command line editing
Install-Module -Name PSReadLine -Force

# posh-git - Git integration
Install-Module -Name posh-git -Scope CurrentUser

# Terminal-Icons - File icons
Install-Module -Name Terminal-Icons -Scope CurrentUser

# PSFzf - Fuzzy finder for PowerShell
Install-Module -Name PSFzf -Scope CurrentUser

# Oh My Stats - System stats (optional but recommended)
# See: https://github.com/zentala/oh-my-stats
```

### 5. Load Profile

Replace your main PowerShell profile:

```powershell
# Backup old profile
Copy-Item $PROFILE "$PROFILE.backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"

# Create new profile that loads from repo
@"
# Load profile from repo
`$ProfileRepo = "C:\code\pwsh-profile\profile.ps1"
if (Test-Path `$ProfileRepo) {
    . `$ProfileRepo
}
"@ | Out-File $PROFILE -Encoding UTF8
```

### 6. Restart PowerShell

Open a new PowerShell window and enjoy your modern terminal!

## 💡 Getting Started

After installation, type:

```powershell
help              # Show all available commands
help quick        # Quick reference
help tools        # Check which tools are installed
help learn        # See PowerShell equivalents (learning mode)
help config       # View configuration
```

## 🎯 Key Features Explained

### Fuzzy Search & Smart Navigation

**PSFzf** - Fuzzy finder:
- **`Ctrl+R`** - Search command history with fuzzy matching
- **`Ctrl+T`** - Search files in current directory
- **`gst`** - Fuzzy git status selector

**zoxide** - Smart directory jumping:
- **`z folder`** - Jump to frequently used folder (e.g., `z code`)
- **`z -`** - Go back to previous directory
- **`zi`** - Interactive folder selection with fzf

### Git Shortcuts

```powershell
gs          # git status
ga          # git add .
gc "msg"    # git commit -m "msg"
gp          # git push
gl          # git log --oneline --graph (last 10)
gco branch  # git checkout branch
```

### Linux-Style Commands

```powershell
# File operations
ls, ll, la       # List files (enhanced with eza if installed)
cat file.txt     # View file (enhanced with bat if installed)
touch file       # Create file or update timestamp
mkdir -p a/b/c   # Create nested directories

# Search
grep pattern     # Search in files (enhanced with ripgrep if installed)
find pattern     # Find files (enhanced with fd if installed)
which cmd        # Find command location

# Navigation
..          # cd ..
...         # cd ../..
....        # cd ../../..
~           # cd $HOME
mkcd dir    # Create directory and cd into it
z folder    # Smart jump to frequently used folders
```

### Enhanced Tools Usage

When installed, these tools automatically replace their classic counterparts:

```powershell
cat file.txt     # Uses bat (with syntax highlighting)
ls              # Uses eza (with icons and colors)
grep pattern    # Uses ripgrep (faster search)
find pattern    # Uses fd (faster file finding)
git diff        # Uses delta (beautiful diffs)
```

### Admin Access

```powershell
sudo command  # Run command with admin privileges
```

## ⚙️ Configuration

Edit `config.ps1` to customize your experience:

```powershell
# Linux Compatibility - Enable Linux-style aliases
$global:OhMyPwsh_EnableLinuxCompat = $true

# Enhanced Tools - Use bat, eza, ripgrep, fd, delta
$global:OhMyPwsh_UseEnhancedTools = $true

# Custom Help System
$global:OhMyPwsh_EnableCustomHelp = $true

# Learning Mode - Show PowerShell equivalents
$global:OhMyPwsh_ShowAliasTargets = $true

# Feedback Messages - Get visual confirmation
$global:OhMyPwsh_ShowFeedback = $true

# Welcome Message - Show help tip on startup
$global:OhMyPwsh_ShowWelcome = $true
```

### Change Oh My Posh Theme

Edit `profile.ps1` line ~79:

```powershell
$omp_config = "$env:POSH_THEMES_PATH\your-theme.omp.json"
```

Browse themes: https://ohmyposh.dev/docs/themes

### Add Your Own Scripts

Place your scripts in `scripts/` folder and source them in `profile.ps1`.

## 🎓 Learning PowerShell

With learning mode enabled (`$OhMyPwsh_ShowAliasTargets = $true`), you'll see PowerShell equivalents:

```powershell
PS> mkdir test
✓ Created directory: test
  → New-Item -ItemType Directory -Force
```

Type `help learn` to see a full mapping of Linux commands to PowerShell cmdlets.

## 📊 Performance

Profile loads in ~1-2 seconds with all features enabled. Timer is included - check `$global:PSProfileLoadStart` to measure.

## 🐛 Troubleshooting

### Commands not working

```powershell
# Reload profile
. $PROFILE
```

### Missing enhanced tools

```powershell
# Check what's missing
help tools

# Install all at once
Install-EnhancedTools
```

### Permission issues

```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

## 🧪 Testing

This project has comprehensive test coverage with automated CI/CD.

**Run Tests:**
```powershell
# Run all tests
./scripts/Invoke-Tests.ps1

# Run with coverage
./scripts/Invoke-Tests.ps1 -Coverage

# Watch mode (auto-rerun on changes)
./scripts/Invoke-Tests.ps1 -Watch

# Install git hooks (optional)
./scripts/Install-GitHooks.ps1
```

**Status:**
- ✅ 176 passing tests
- ✅ 100% coverage on critical modules
- ✅ CI/CD on GitHub Actions (Windows + Ubuntu)
- ✅ Pre-commit hooks available (optional)

**Documentation:**
- [Testing Strategy](./docs/TESTING-STRATEGY.md) - Complete testing approach
- [STATUS.md](./STATUS.md) - Project status & quick start
- [DECISIONS.md](./DECISIONS.md) - Key decisions & context

---

## 📚 Documentation

**For Users:**
- [STATUS.md](./STATUS.md) - Project snapshot, what works, known issues
- [ARCHITECTURE.md](./docs/ARCHITECTURE.md) - Module structure
- [TESTING-STRATEGY.md](./docs/TESTING-STRATEGY.md) - How to test

**For Developers:**
- [DECISIONS.md](./DECISIONS.md) - Why we made certain choices
- [ADRs](./adr/) - Architecture Decision Records
- [Runbook](./.claude/runbook/2025-10-18.md) - Implementation session log
- [.future.md](./.future.md) - Future enhancement ideas

**Quick Links:**
- [Task 005](./todo/005-testing-infrastructure.md) - Testing infrastructure plan
- [Git Hooks Guide](./docs/TESTING-STRATEGY.md#git-hooks-optional) - Optional pre-commit setup

---

## 📝 License

MIT - Paweł Żentała © 2025

---

**Made with ❤️ for modern Windows terminal experience**

> **Project Status:** ✅ Stable & Tested (see [STATUS.md](./STATUS.md) for current state)
