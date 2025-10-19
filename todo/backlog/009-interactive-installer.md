# 009 - Interactive Installer with Choices

**Status:** backlog
**Priority:** P2
**Created:** 2025-10-19
**Depends on:** [010-tui-research.md](./010-tui-research.md) - TUI library decision

## Goal

Create a comprehensive, interactive installer for oh-my-pwsh that allows users to:
- Choose what to install (minimal, recommended, full)
- See descriptions of each tool (especially for Linux users migrating)
- Understand what each tool replaces (e.g., bat replaces cat)
- Skip through with defaults for quick setup
- Thoroughly test all installation scenarios

## User Story

> "As a Linux user new to Windows PowerShell, I want an interactive installer that explains what each tool does and how it compares to my familiar Linux tools, so I can make informed choices about what to install and understand my new environment."

## Context

User's requirements:
> "trzeba zrobic porzadny instaltor dla naszego systemu oraz go otestowac porzdnie. instaltor ma pozwac przezjsc z default settings, ma pozwalac wybierac co installowac, ma tez dawac opisy co jest co dla migration linux user np co daje bat zamiast cat, ok?"

**Current state:**
- `scripts/install-dependencies.ps1` exists but is basic
- No interactive choices
- No explanations for Linux users
- Limited testing

## Installation Modes

### 1. Quick Install (Default)
```powershell
.\install.ps1

🚀 oh-my-pwsh Quick Install

This will install recommended tools for the best experience.

Press ENTER for quick install, or 'c' for custom install [ENTER/c]:
```

**Installs:**
- PowerShell 7.x (if not present)
- Oh My Posh
- posh-git
- Terminal-Icons
- PSReadLine
- PSFzf
- fzf binary
- zoxide
- gsudo

### 2. Custom Install
```powershell
.\install.ps1 -Mode Custom

🎨 oh-my-pwsh Custom Install

Choose what to install:

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 CORE REQUIREMENTS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[✓] PowerShell 7.x
    Required for this profile
    Current: 7.4.0 ✓

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 BEAUTIFUL TERMINAL (Recommended)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[?] Oh My Posh - Customizable prompt (like oh-my-zsh)
    Shows git status, execution time, system info
    Install: winget install JanDeDobbeleer.OhMyPosh
    Linux equivalent: oh-my-zsh, starship
    [Y/n]:

[?] posh-git - Git integration in prompt
    Shows branch name, status, ahead/behind
    Install: Install-Module posh-git
    Linux equivalent: built into oh-my-zsh
    [Y/n]:

[?] Terminal-Icons - Colorful file/folder icons
    Visual file type indicators (like ls with icons)
    Install: Install-Module Terminal-Icons
    Linux equivalent: ls with --color, exa icons
    [Y/n]:

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 PRODUCTIVITY TOOLS (Recommended)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[?] PSReadLine - Advanced command line editing
    Fish/Zsh-like autocompletion, history search
    Install: Install-Module PSReadLine
    Linux equivalent: fish shell, zsh autosuggestions
    [Y/n]:

[?] fzf + PSFzf - Fuzzy finder (Ctrl+R for history)
    Interactive file/history search
    Install: winget install fzf + Install-Module PSFzf
    Linux equivalent: fzf
    [Y/n]:

[?] zoxide - Smart directory jumping (z command)
    Jump to frequently used directories
    Install: winget install ajeetdsouza.zoxide
    Linux equivalent: autojump, z
    [Y/n]:

[?] gsudo - Linux-style sudo for Windows
    Run commands with admin privileges
    Install: winget install gerardog.gsudo
    Linux equivalent: sudo
    [Y/n]:

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 ENHANCED TOOLS (Optional - Modern Unix alternatives)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[?] bat - Better cat with syntax highlighting
    Replaces: cat (with colors and line numbers)
    Install: scoop install bat
    [y/N]:

[?] eza - Modern ls with icons and colors
    Replaces: ls (with git status, icons, tree view)
    Install: scoop install eza
    [y/N]:

[?] ripgrep - Faster grep for searching
    Replaces: grep (much faster, respects .gitignore)
    Install: scoop install ripgrep
    [y/N]:

[?] fd - Faster find for locating files
    Replaces: find (simpler syntax, faster)
    Install: scoop install fd
    [y/N]:

[?] delta - Beautiful git diff viewer
    Replaces: git diff (side-by-side, syntax highlighting)
    Install: scoop install delta
    [y/N]:
```

### 3. Minimal Install
```powershell
.\install.ps1 -Mode Minimal

📦 Minimal oh-my-pwsh Install

Installing only core requirements:
- PowerShell 7.x (if needed)
- PSReadLine (for basic editing)

All enhanced tools will have native PowerShell fallbacks.
You can install more tools later with: Install-EnhancedTools
```

## Installation Flow

```
1. Pre-flight checks
   ├─ Check PowerShell version (>= 7.0)
   ├─ Check admin rights (if needed)
   ├─ Check internet connection
   └─ Check package managers (winget, scoop)

2. Package manager setup
   ├─ If winget missing → suggest install or use scoop
   └─ If scoop missing (and needed) → offer to install

3. Tool installation
   ├─ For each selected tool:
   │  ├─ Check if already installed
   │  ├─ Show install command
   │  ├─ Install with progress
   │  ├─ Verify installation
   │  └─ Show success/error
   └─ Summary report

4. Profile configuration
   ├─ Backup existing $PROFILE
   ├─ Create/update profile to load oh-my-pwsh
   └─ Create default config.ps1

5. Post-install
   ├─ Show summary (what was installed)
   ├─ Show next steps
   └─ Offer to reload profile
```

## Tool Descriptions for Linux Users

### Format
```powershell
$ToolDescriptions = @{
    'bat' = @{
        Name = 'bat'
        ShortDesc = 'Better cat with syntax highlighting'
        Replaces = 'cat'
        LinuxEquivalent = 'cat (with colors and line numbers)'
        Benefits = @(
            'Syntax highlighting for code'
            'Git integration (shows changes)'
            'Line numbers'
            'Paging for long files'
        )
        InstallCmd = 'scoop install bat'
        PackageManager = 'scoop'  # or 'winget'
        RequiresAdmin = $false
    }
    # ... more tools
}
```

## Testing Requirements

### Test Scenarios

**Installation Modes:**
- [ ] Quick install with all defaults
- [ ] Custom install with all tools selected
- [ ] Custom install with no optional tools
- [ ] Minimal install
- [ ] Partial install (some tools fail)

**System States:**
- [ ] Fresh Windows install (nothing installed)
- [ ] PowerShell 7.x already installed
- [ ] Some tools already installed (should skip)
- [ ] All tools already installed (should detect)
- [ ] No internet connection (should fail gracefully)
- [ ] No admin rights (should handle appropriately)

**Package Managers:**
- [ ] winget available
- [ ] scoop available
- [ ] Both available (prefer winget)
- [ ] Neither available (offer to install scoop)

**User Interactions:**
- [ ] User accepts all defaults (ENTER spam)
- [ ] User rejects all optional tools (n spam)
- [ ] User cancels mid-installation (Ctrl+C)
- [ ] User has invalid input (handle gracefully)

**Error Handling:**
- [ ] Install fails (network error)
- [ ] Package not found
- [ ] Version conflict
- [ ] Disk space issues
- [ ] Permission denied

### Test Structure

```powershell
Describe "oh-my-pwsh Installer" {
    Context "Quick Install Mode" {
        It "Installs all recommended tools" { }
        It "Skips already installed tools" { }
        It "Creates profile configuration" { }
        It "Shows summary report" { }
    }

    Context "Custom Install Mode" {
        It "Shows interactive menu" { }
        It "Respects user choices" { }
        It "Explains each tool for Linux users" { }
    }

    Context "Package Manager Detection" {
        It "Detects winget" { }
        It "Detects scoop" { }
        It "Offers to install scoop if missing" { }
    }

    Context "Error Handling" {
        It "Handles network failures gracefully" { }
        It "Continues on partial failures" { }
        It "Shows helpful error messages" { }
    }
}
```

## Architecture (Pending TUI Research)

**Note:** Final implementation depends on Task 010 (TUI Research) to choose the right library for interactive menus.

### Possible TUI Options

1. **Native PowerShell** - `Read-Host`, `Write-Host`
   - Pros: No dependencies
   - Cons: Limited UX

2. **Terminal.Gui (PowerShell wrapper)**
   - Pros: Rich TUI, forms, dialogs
   - Cons: Requires .NET library

3. **Spectre.Console.Cli**
   - Pros: Beautiful console UI, progress bars, tables
   - Cons: Requires NuGet package

**Decision:** Wait for Task 010 research results

### Installer Module Structure

```
scripts/
├── Install.ps1                      # Main entry point
├── installer/
│   ├── Install-Core.ps1            # Core installation logic
│   ├── Install-Tools.ps1           # Individual tool installers
│   ├── Install-PackageManagers.ps1 # winget/scoop setup
│   ├── Install-UI.ps1              # Interactive menus (TUI)
│   ├── Install-Descriptions.ps1    # Tool descriptions data
│   └── Install-Tests.ps1           # Pre/post flight checks
```

## Configuration

### Installation Modes
```powershell
# Default mode
.\Install.ps1

# Custom mode
.\Install.ps1 -Mode Custom

# Minimal mode
.\Install.ps1 -Mode Minimal

# Unattended mode (for CI/CD)
.\Install.ps1 -Mode Unattended -Tools "core,posh,fzf"
```

### Tool Categories
```powershell
$ToolCategories = @{
    Core = @('pwsh', 'psreadline')
    Beautiful = @('oh-my-posh', 'posh-git', 'terminal-icons')
    Productivity = @('fzf', 'psfzf', 'zoxide', 'gsudo')
    Enhanced = @('bat', 'eza', 'ripgrep', 'fd', 'delta')
}
```

## Tasks (When Moving to Active)

- [ ] **BLOCKED by Task 010** - Wait for TUI research
- [ ] Design interactive menu UX (after TUI decision)
- [ ] Create tool descriptions database
- [ ] Implement installation modes (Quick, Custom, Minimal)
- [ ] Create package manager detection/setup
- [ ] Implement progress reporting
- [ ] Add rollback on failure
- [ ] Write comprehensive tests (all scenarios above)
- [ ] Test on fresh Windows installs
- [ ] Document installation process
- [ ] Create video walkthrough

## Success Criteria

- [ ] Linux user understands what each tool does
- [ ] User can choose between quick/custom/minimal install
- [ ] Installer handles all error cases gracefully
- [ ] All installation scenarios tested
- [ ] Installer works on fresh Windows install
- [ ] Clear progress feedback during installation
- [ ] Summary report shows what was installed
- [ ] Documentation explains all options

## Related

- [010-tui-research.md](./010-tui-research.md) - **BLOCKS THIS TASK** - TUI library decision
- [scripts/install-dependencies.ps1](../../scripts/install-dependencies.ps1) - Current basic installer
- [CLAUDE.md](../../CLAUDE.md) - DevEx mindset for user-facing tools

## Notes

- **BLOCKED:** This task is blocked by Task 010 (TUI Research)
- Once we choose a TUI library, we can design the interactive menus
- Priority after TUI research: P2 (important for user onboarding)
- Focus on Linux user education (explaining tool equivalents)
- Comprehensive testing is critical (installer is first impression)
