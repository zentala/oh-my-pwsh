# Custom Help System Specification

**Status:** ✅ Implemented (v0.1 - basic functionality)
**Module:** `modules/help-system.ps1`
**Priority:** P1 (core feature)

---

## Vision

Custom help system tailored for oh-my-pwsh users - Linux migrants and power users who want quick reference without leaving the terminal.

### Goals

1. **Quick Reference** - Type `help` → see what's available instantly
2. **No Context Switch** - Stay in terminal, no web browser needed
3. **Progressive Disclosure** - Simple by default, detailed on demand
4. **Learn PowerShell** - Show PS equivalents, not just aliases
5. **Contextual** - Show what's installed vs what could be installed

---

## Current Implementation (v0.1)

### What Works

**Basic Commands:**
```powershell
help           # Show all available commands
help quick     # Quick reference card
help tools     # Check which enhanced tools are installed
help learn     # PowerShell learning mode (alias equivalents)
help config    # View current configuration
```

**Features:**
- ✅ Categorized command list (Git, Navigation, Files, System)
- ✅ Tool detection (shows installed/missing enhanced tools)
- ✅ Learning mode (Linux → PowerShell mapping)
- ✅ Configuration viewer
- ✅ Clean, colorful output with icons

**Location:** `modules/help-system.ps1` (11,317 lines)

---

## Future Enhancements

### Phase 1: Enhanced Search & Filtering

**Goal:** Find commands faster

**Features:**
```powershell
help git              # Show only git-related commands
help search <term>    # Search commands by keyword
help <command>        # Detailed help for specific command
```

**Example:**
```powershell
PS> help grep
[i] Linux Command: grep
    PowerShell: Select-String

    Usage:
      grep "pattern" file.txt         # Basic search
      grep -r "pattern" directory/    # Recursive search

    PowerShell Equivalent:
      Select-String -Pattern "pattern" -Path file.txt
      Get-ChildItem -Recurse | Select-String "pattern"

    Enhanced Tool:
      [!] Install ripgrep for faster search: scoop install ripgrep

    Learn More:
      Get-Help Select-String -Examples
```

### Phase 2: Interactive Mode

**Goal:** Browse commands interactively

**Features:**
```powershell
help -Interactive     # Launch interactive browser (fzf-based)
```

**UI Mockup:**
```
┌─ oh-my-pwsh Help ─────────────────────────────────┐
│ > git                                             │
│   grep                                            │
│   ls                                              │
│   cat                                             │
│   touch                                           │
│   ...                                             │
├───────────────────────────────────────────────────┤
│ [✓] git (version control shortcuts)              │
│                                                   │
│ Commands:                                         │
│   gs    - git status                              │
│   ga    - git add .                               │
│   gc    - git commit -m "message"                 │
│   gp    - git push                                │
│                                                   │
│ Type command name for details, Esc to exit       │
└───────────────────────────────────────────────────┘
```

**Tech:** PSFzf integration (already installed)

### Phase 3: Examples & Snippets

**Goal:** Practical, copy-pasteable examples

**Features:**
```powershell
help <command> -Examples    # Show real-world examples
help <command> -Snippet     # Copy to clipboard
```

**Example:**
```powershell
PS> help mkcd -Examples

[i] mkcd - Create directory and cd into it

Examples:
  1. Basic usage
     mkcd projects/new-app
     → Creates C:\Users\You\projects\new-app and enters it

  2. Nested directories
     mkcd src/components/forms
     → Creates all parent directories automatically

  3. With spaces
     mkcd "My Projects/New Folder"
     → Handles spaces correctly

PowerShell Equivalent:
  New-Item -ItemType Directory -Force -Path <path> | Set-Location
```

### Phase 4: Cheat Sheets

**Goal:** Topic-based guides

**Features:**
```powershell
help cheat git        # Git command cheat sheet
help cheat files      # File operations cheat sheet
help cheat navigation # Navigation shortcuts
```

**Format:**
```
┌─ Git Cheat Sheet ─────────────────────────────────┐
│ Status & Info:                                    │
│   gs          git status                          │
│   gl          git log --oneline (last 10)         │
│                                                   │
│ Staging & Commit:                                 │
│   ga          git add .                           │
│   gc "msg"    git commit -m "msg"                 │
│   gp          git push                            │
│                                                   │
│ Branching:                                        │
│   gco <br>    git checkout <branch>               │
│   gb          git branch                          │
│                                                   │
│ More: Get-Help about_Git                          │
└───────────────────────────────────────────────────┘
```

### Phase 5: AI-Powered Help (Experimental)

**Goal:** Natural language queries

**Features:**
```powershell
help "how to search files recursively"
help "commit and push changes"
```

**Requires:** AI CLI integration (see task 008)

---

## Design Principles

### 1. Terminal-First

- No web browser needed
- Works offline
- Fast response time
- Keyboard-driven navigation

### 2. Progressive Complexity

```
help               → High-level overview (30 seconds)
help quick         → Quick reference (1 minute)
help <command>     → Detailed guide (2-3 minutes)
help <topic> -Deep → Complete documentation (5+ minutes)
```

### 3. Learning-Focused

Always show:
- ✅ What the command does (short description)
- ✅ PowerShell equivalent (learning aid)
- ✅ Practical example (copy-pasteable)
- ✅ Related commands (discovery)

### 4. Visual Hierarchy

```
[i] Header         # Cyan, informational
    Body text      # White, main content
    → Mapping      # DarkGray, subtle reference

[✓] Installed      # Green, success
[!] Not installed  # Yellow, actionable
[x] Error          # Red, problem
```

### 5. Context-Aware

Adapt output based on:
- What's installed (show available tools)
- User config (teacher mode on/off)
- Terminal capabilities (Nerd Fonts, colors)
- Command history (suggest related commands)

---

## Technical Architecture

### Current Structure

```powershell
# modules/help-system.ps1

function Show-CustomHelp {
    param([string]$Topic)

    switch ($Topic) {
        "quick"  { Show-QuickReference }
        "tools"  { Show-ToolStatus }
        "learn"  { Show-LearningMode }
        "config" { Show-Configuration }
        default  { Show-AllCommands }
    }
}

# Alias for convenience
Set-Alias -Name help -Value Show-CustomHelp -Scope Global -Force
```

### Planned Enhancements

**1. Modular Topics**
```
modules/help-system/
├── core.ps1              # Main help function
├── topics/
│   ├── git.ps1           # Git commands help
│   ├── files.ps1         # File operations help
│   ├── navigation.ps1    # Navigation shortcuts help
│   └── tools.ps1         # Enhanced tools help
└── templates/
    ├── command.template  # Command detail template
    └── cheatsheet.template
```

**2. Search Index**
```powershell
# Build search index for fast lookup
$HelpIndex = @{
    "grep" = @{
        Category = "Files"
        Aliases = @("search", "find text")
        PowerShell = "Select-String"
        EnhancedTool = "ripgrep"
    }
    # ...
}
```

**3. Interactive Browser**
```powershell
function Show-InteractiveHelp {
    $commands = Get-AllCommands
    $selected = $commands | Out-Fzf -Prompt "Select command > "
    Show-CommandDetail -Command $selected
}
```

---

## User Stories

### Story 1: Quick Lookup
> "As a new user, I want to type `help` and see what commands are available, so I can start using oh-my-pwsh immediately."

**Acceptance:**
- Type `help` → see categorized list
- Takes < 1 second to display
- Shows ~30 most useful commands
- Grouped by category (Git, Files, Navigation, System)

### Story 2: Learn PowerShell
> "As a Linux user, I want to see PowerShell equivalents for my familiar commands, so I can learn PowerShell while staying productive."

**Acceptance:**
- Type `help learn` → see Linux → PowerShell mapping
- Shows alias → cmdlet for each command
- Optional: Enable teacher mode for inline learning

### Story 3: Discover Tools
> "As a power user, I want to see which enhanced tools I have installed, so I know what capabilities are available."

**Acceptance:**
- Type `help tools` → see tool status
- Shows installed (green ✓) vs missing (yellow !)
- Provides install commands for missing tools

### Story 4: Deep Dive
> "As a developer, I want detailed help for specific commands with examples, so I can learn advanced usage."

**Acceptance:**
- Type `help <command>` → see detailed guide
- Shows syntax, examples, PowerShell equivalent
- Copy-pasteable code snippets
- Links to official docs (Get-Help)

---

## Success Metrics

### v0.1 (Current)
- ✅ Basic `help` command implemented
- ✅ Quick reference available
- ✅ Tool status check working
- ✅ Learning mode functional
- ✅ Config viewer operational

### v0.2 (Next)
- 🎯 Search functionality (`help search <term>`)
- 🎯 Command detail pages (`help <command>`)
- 🎯 Categorized help (`help git`)

### v0.3 (Future)
- 🎯 Interactive browser (fzf-based)
- 🎯 Example snippets
- 🎯 Cheat sheets

### v1.0 (Vision)
- 🎯 Comprehensive command documentation
- 🎯 Context-aware suggestions
- 🎯 Offline-first, fast, beautiful
- 🎯 Best-in-class PowerShell help experience

---

## Related

- **Implementation:** `modules/help-system.ps1`
- **Config:** `$OhMyPwsh_EnableCustomHelp` in `config.ps1`
- **Similar:** bash `man` pages, zsh `help`, fish `help`
- **Inspiration:** [tldr](https://github.com/tldr-pages/tldr), [cheat.sh](https://cheat.sh/)

---

## Notes

- Keep it fast (< 100ms response time)
- Work offline (no API calls to external services)
- Be discoverable (type `help` to start)
- Be helpful (show examples, not just syntax)
- Be beautiful (colors, icons, formatting)

**Remember:** Help system is first thing users see when they type `help`. Make it count!

---

**Last Updated:** 2025-10-19
**Version:** 0.1 (basic implementation)
**Maintainer:** Paweł Żentała
