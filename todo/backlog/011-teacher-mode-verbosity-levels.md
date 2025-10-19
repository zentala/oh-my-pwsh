# 011 - Teacher Mode with Verbosity Levels

**Status:** backlog
**Priority:** P3
**Created:** 2025-10-19

## Goal

Enhance current "learning mode" (`$OhMyPwsh_ShowAliasTargets`) into full "Teacher Mode" with configurable verbosity levels.

## Current State

We have basic learning mode:
```powershell
# config.ps1
$global:OhMyPwsh_ShowAliasTargets = $true  # Shows: "mkdir → New-Item -ItemType Directory"
```

This shows PowerShell equivalents for Linux aliases, but it's binary (on/off).

## Proposed Enhancement

**Teacher Mode with Verbosity Levels:**

```powershell
# config.ps1
$global:OhMyPwsh_TeacherMode = "info"  # Options: "silent", "error", "info", "verbose"
```

### Verbosity Levels

**1. `silent`** - No teaching, just execute
- No feedback messages
- Commands work silently
- For experienced users

**2. `error`** - Only show when command doesn't exist
```powershell
PS> ee
[!] Command 'ee' not found
    💡 Did you mean: micro, nvim, notepad++?
    Install: scoop install micro
```

**3. `info`** (default) - Show PowerShell equivalents
```powershell
PS> mv file.txt newname.txt
  → PowerShell: Move-Item
✓ File moved
```

**4. `verbose`** - Extended explanations
```powershell
PS> mv file.txt newname.txt
  → PowerShell: Move-Item -Path "file.txt" -Destination "newname.txt"
  📚 Learn more: Get-Help Move-Item -Examples
✓ File moved: file.txt → newname.txt
```

## User Stories

### Story 1: Ex-Linux User Learning PowerShell
> "As a Linux user new to Windows, I want to see PowerShell equivalents for my Linux commands, so I can gradually learn PowerShell while maintaining productivity."

**Acceptance:**
- Set `$OhMyPwsh_TeacherMode = "info"`
- Type `ls -la`
- See: `→ PowerShell: Get-ChildItem`
- Command executes normally

### Story 2: Missing Command Suggestions
> "As a user typing `vim` out of habit, I want to see suggestions for Windows alternatives, so I can quickly install and use them."

**Acceptance:**
- Type `vim file.txt` (vim not installed)
- See: `[!] Command 'vim' not found`
- See: `💡 Try: nvim, micro, nano`
- See: `Install: scoop install neovim`

### Story 3: Deep Dive Learning
> "As a curious user, I want verbose explanations with examples, so I can truly understand PowerShell patterns."

**Acceptance:**
- Set `$OhMyPwsh_TeacherMode = "verbose"`
- Type `grep pattern file.txt`
- See full PowerShell command: `Select-String -Pattern "pattern" -Path "file.txt"`
- See learning tip: `Get-Help Select-String -Examples`

### Story 4: Silent Expert Mode
> "As an experienced PowerShell user, I want to disable teaching messages, so I have a clean, fast terminal."

**Acceptance:**
- Set `$OhMyPwsh_TeacherMode = "silent"`
- Type any command
- See only command output, no teaching messages

## Technical Architecture

### 1. Centralized Function

```powershell
# modules/teacher.ps1
function Write-TeacherMessage {
    param(
        [string]$Level,        # "error", "info", "verbose"
        [string]$Command,      # "mv"
        [string]$PowerShell,   # "Move-Item"
        [string]$FullSyntax,   # "Move-Item -Path ... -Destination ..."
        [string]$LearnMore,    # "Get-Help Move-Item -Examples"
        [string[]]$Suggestions # @("micro", "nvim", "notepad++")
    )

    $mode = $global:OhMyPwsh_TeacherMode

    if ($mode -eq "silent") { return }
    if ($Level -eq "error" -and $mode -eq "error") {
        # Show command not found + suggestions
    }
    if ($Level -eq "info" -and $mode -in @("info", "verbose")) {
        # Show basic PowerShell equivalent
    }
    if ($Level -eq "verbose" -and $mode -eq "verbose") {
        # Show full syntax + learn more
    }
}
```

### 2. Integration Points

**A. Linux Compatibility Module** (`modules/linux-compat.ps1`)
```powershell
function mv {
    Write-TeacherMessage -Level "info" -Command "mv" -PowerShell "Move-Item"
    Move-Item @args
}
```

**B. Command Not Found Hook** (PowerShell 7.4+)
```powershell
# profile.ps1
$ExecutionContext.InvokeCommand.CommandNotFoundAction = {
    param($CommandName, $CommandLookupEventArgs)

    $suggestions = Get-CommandSuggestions -Command $CommandName
    Write-TeacherMessage -Level "error" -Command $CommandName -Suggestions $suggestions
}
```

### 3. Smart Suggestions Database

```powershell
# settings/command-suggestions.ps1
$global:CommandSuggestions = @{
    # Editors
    "vim"   = @{ Alternatives = @("nvim", "micro"); Install = "scoop install neovim" }
    "vi"    = @{ Alternatives = @("nvim", "micro"); Install = "scoop install neovim" }
    "ee"    = @{ Alternatives = @("micro", "nano"); Install = "scoop install micro" }
    "nano"  = @{ Alternatives = @("nano", "micro"); Install = "scoop install nano" }

    # Tools
    "htop"  = @{ Alternatives = @("ntop", "bottom"); Install = "scoop install bottom" }
    "top"   = @{ Alternatives = @("ntop", "bottom"); Install = "scoop install bottom" }
}
```

## Implementation Phases

### Phase 1: Refactor Current Learning Mode
- Rename `$OhMyPwsh_ShowAliasTargets` → `$OhMyPwsh_TeacherMode`
- Support both for backward compatibility
- Default: `"info"`

### Phase 2: Add Verbosity Levels
- Implement `Write-TeacherMessage` function
- Support: `"silent"`, `"info"`, `"verbose"`
- Update all linux-compat functions

### Phase 3: Command Not Found Hook
- Implement `CommandNotFoundAction` (PS 7.4+)
- Add suggestions database
- Support `"error"` level

### Phase 4: Documentation
- Create `docs/TEACHER-MODE.md`
- Add examples for each verbosity level
- Update README with teacher mode section
- Link from config.example.ps1

## Documentation Needed

### `docs/TEACHER-MODE.md`

```markdown
# Teacher Mode - Learn PowerShell While You Work

oh-my-pwsh includes an optional "Teacher Mode" that helps you learn PowerShell
while maintaining your Linux CLI habits.

## Quick Start

Edit `config.ps1`:
```powershell
$global:OhMyPwsh_TeacherMode = "info"  # Default, shows PowerShell equivalents
```

## Verbosity Levels

[Examples for each level...]

## Configuration

[All config options...]

## FAQ

**Q: Will this slow down my terminal?**
A: No. Teacher messages are lightweight and only shown for aliased commands.

**Q: Can I toggle it on/off quickly?**
A: Yes. Run: `$OhMyPwsh_TeacherMode = "silent"` to disable instantly.
```

## Success Criteria

- [ ] All 4 verbosity levels implemented
- [ ] Backward compatible with `$OhMyPwsh_ShowAliasTargets`
- [ ] Command not found suggestions working
- [ ] Documentation created (`docs/TEACHER-MODE.md`)
- [ ] README updated with teacher mode section
- [ ] Tests added for verbosity levels
- [ ] Default: `"info"` (balanced learning)

## Related

- Current implementation: `config.example.ps1` line 56
- Linux compat module: `modules/linux-compat.ps1`
- Similar feature: Smart suggestions (task 007)
- Documentation: Will link from README

## Notes

- PowerShell 7.4+ required for `CommandNotFoundAction` hook
- Falls back gracefully on older versions (no command-not-found suggestions)
- Teacher mode is opt-in, can be disabled completely
- Designed to be non-intrusive and educational
