# 007 - Smart Editor Command Suggestions

**Status:** backlog
**Priority:** P3 (nice-to-have)
**Created:** 2025-10-19
**Spec:** [specs/smart-editor-suggestions.md](../../specs/smart-editor-suggestions.md) - **READ THIS FIRST**
**Implementation:** `modules/command-suggestions.ps1` (pending)
**Tests:** `tests/modules/command-suggestions.Tests.ps1` (pending)

## Goal

Detect when user tries to use Linux/Unix editor commands that don't exist on Windows, and suggest modern Windows alternatives with interactive installation.

## User Story

> "As a Linux user migrating to Windows, when I type `vim` or `ee` out of habit and the command doesn't exist, I want the system to suggest a Windows alternative (like `nvim` or `micro`) and offer to install it, so I can quickly discover the PowerShell ecosystem without googling."

## Context

User's request:
> "CHODZI O TO ABY WYKRYWALO ZE JA WPSIUJE EE I JUZ BYLA POD TYM JAKS KOEMNDA TYCZMOWA MOWAICA ZE ZAMIAST EE WINDOWS MA MICRO KTORY JEST ODOBMY, ZAISNTLWOAC? I YSER MOZE WYBRC TKA I ISE ISNTLAUJEA BL ODAJE MU ISNTRUJCE."

### Example Workflow

```powershell
PS> ee myfile.txt

[!] Command 'ee' not found

💡 Did you mean one of these Windows alternatives?

  1. micro  - Easy terminal editor (most similar to 'ee')
     Install: winget install zyedidia.micro

  2. nano   - Simple Unix-style editor
     Install: winget install GNU.Nano

  3. nvim   - Modern Vim (powerful but steep learning curve)
     Install: winget install Neovim.Neovim

Would you like to install one now? [1/2/3/n]:
```

## Editor Mapping Table

| Linux/Unix Command | Windows Alternative | Similarity | Installation Command | Notes |
|-------------------|---------------------|------------|---------------------|-------|
| `ee` | `micro` | ⭐⭐⭐⭐⭐ | `winget install zyedidia.micro` | Easy editor with mouse support |
| `vim` | `nvim` (Neovim) | ⭐⭐⭐⭐⭐ | `winget install Neovim.Neovim` | Modern Vim fork |
| `vim` | `vim` | ⭐⭐⭐⭐⭐ | `winget install Vim.Vim` | Classic Vim |
| `nano` | `nano` | ⭐⭐⭐⭐⭐ | `winget install GNU.Nano` | GNU Nano for Windows |
| `emacs` | `emacs` | ⭐⭐⭐⭐⭐ | `winget install GNU.Emacs` | GNU Emacs for Windows |
| `vi` | `nvim` or `vim` | ⭐⭐⭐⭐ | (see vim above) | Vi compatibility mode |

## Architecture Design

### 1. Command Not Found Hook

PowerShell has a `CommandNotFoundAction` event we can hook into:

```powershell
# In modules/command-suggestions.ps1
$ExecutionContext.InvokeCommand.CommandNotFoundAction = {
    param($CommandName, $CommandLookupEventArgs)

    # Check if command is in our mapping
    if ($EditorSuggestions.ContainsKey($CommandName)) {
        Show-EditorSuggestion -Command $CommandName
        $CommandLookupEventArgs.StopSearch = $true
    }
}
```

### 2. Editor Suggestions Module

```powershell
# modules/editor-suggestions.ps1

$global:EditorSuggestions = @{
    'ee' = @{
        Primary = @{
            Name = 'micro'
            Description = 'Easy terminal editor (most similar to ee)'
            InstallCmd = 'winget install zyedidia.micro'
            LaunchCmd = 'micro'
        }
        Alternatives = @(
            @{
                Name = 'nano'
                Description = 'Simple Unix-style editor'
                InstallCmd = 'winget install GNU.Nano'
            }
        )
    }
    'vim' = @{
        Primary = @{
            Name = 'nvim'
            Description = 'Modern Vim with better defaults'
            InstallCmd = 'winget install Neovim.Neovim'
            LaunchCmd = 'nvim'
        }
        Alternatives = @(
            @{
                Name = 'vim'
                Description = 'Classic Vim'
                InstallCmd = 'winget install Vim.Vim'
            },
            @{
                Name = 'micro'
                Description = 'Easier alternative to Vim'
                InstallCmd = 'winget install zyedidia.micro'
            }
        )
    }
    # ... more mappings
}

function Show-EditorSuggestion {
    param([string]$Command)

    $suggestion = $global:EditorSuggestions[$Command]

    Write-Host ""
    Write-StatusMessage -Role "warning" -Message "Command '$Command' not found"
    Write-Host ""
    Write-Host "💡 Did you mean one of these Windows alternatives?" -ForegroundColor Cyan
    Write-Host ""

    # Show primary suggestion
    Write-Host "  1. " -NoNewline -ForegroundColor Yellow
    Write-Host "$($suggestion.Primary.Name)" -NoNewline -ForegroundColor Green
    Write-Host " - $($suggestion.Primary.Description)"
    Write-Host "     Install: " -NoNewline -ForegroundColor DarkGray
    Write-Host $suggestion.Primary.InstallCmd -ForegroundColor White
    Write-Host ""

    # Show alternatives
    $index = 2
    foreach ($alt in $suggestion.Alternatives) {
        Write-Host "  $index. " -NoNewline -ForegroundColor Yellow
        Write-Host "$($alt.Name)" -NoNewline -ForegroundColor Green
        Write-Host " - $($alt.Description)"
        Write-Host "     Install: " -NoNewline -ForegroundColor DarkGray
        Write-Host $alt.InstallCmd -ForegroundColor White
        Write-Host ""
        $index++
    }

    # Interactive prompt
    $choice = Read-Host "Would you like to install one now? [1/2/3/n]"

    if ($choice -match '^\d+$' -and $choice -ge 1) {
        if ($choice -eq 1) {
            Install-Tool -InstallCmd $suggestion.Primary.InstallCmd -Name $suggestion.Primary.Name
        } else {
            $altIndex = [int]$choice - 2
            if ($altIndex -lt $suggestion.Alternatives.Count) {
                $alt = $suggestion.Alternatives[$altIndex]
                Install-Tool -InstallCmd $alt.InstallCmd -Name $alt.Name
            }
        }
    }
}

function Install-Tool {
    param([string]$InstallCmd, [string]$Name)

    Write-Host ""
    Write-Host "Installing $Name..." -ForegroundColor Cyan
    Invoke-Expression $InstallCmd

    if ($LASTEXITCODE -eq 0) {
        Write-StatusMessage -Role "success" -Message "$Name installed successfully!"
        Write-Host "You can now use it: " -NoNewline
        Write-Host $Name -ForegroundColor Green
    } else {
        Write-StatusMessage -Role "error" -Message "Installation failed. Try manually: $InstallCmd"
    }
}
```

### 3. Configuration

Add to `config.example.ps1`:

```powershell
# Smart Editor Suggestions - Suggest Windows alternatives for Linux editors
$global:OhMyPwsh_EnableEditorSuggestions = $true
```

### 4. README Section (Coming Soon)

Add to README.md under "Linux-Style Experience":

```markdown
### 🎓 Smart Command Suggestions (Coming Soon)

Missing your favorite Linux editor? oh-my-pwsh will detect when you try to use commands like `vim`, `ee`, or `nano` and suggest modern Windows alternatives:

- `ee` → Suggests `micro` (easy terminal editor)
- `vim` → Suggests `nvim` (Neovim) or classic `vim`
- `nano` → Suggests GNU Nano for Windows

Interactive installation prompts help you discover the PowerShell ecosystem.
```

## Architecture Overview

**See:** [specs/smart-editor-suggestions.md](../../specs/smart-editor-suggestions.md) for complete UX flows and behavior

### File Structure

```
modules/
├── command-suggestions.ps1           # Main module (hook, detection, prompts)
├── command-suggestions-install.ps1   # Installation logic (package managers, admin)
└── data/
    └── command-suggestions.psd1      # Tool definitions and mappings

tests/
└── modules/
    ├── command-suggestions.Tests.ps1
    └── command-suggestions-install.Tests.ps1

specs/
└── smart-editor-suggestions.md       # Feature spec (UX, flows, behavior)
```

### Data Structure (Normalized)

**Two-section design:**
1. **Tools** - Full tool definitions (single source of truth)
2. **Suggestions** - Map missing commands → tool references (DRY)

**Example:**
```powershell
@{
    Tools = @{
        micro = @{ Name='micro'; InstallCmd='winget install ...'; Features=@(...) }
        nano = @{ ... }
    }
    Suggestions = @{
        ee = @{ Primary='micro'; Alternatives=@('nano','nvim') }
    }
}
```

**Benefits:**
- DRY: Tool defined once, referenced many times
- Easy to extend: Add tool → reference it
- Reusable: Data for suggestions, help, installer, stats

### Implementation Phases

**Phase 1: Simple ASCII (No TUI dependency)**
- Implement with basic `Read-Host` and `Write-Host`
- Works on all systems, zero dependencies
- Good enough for MVP

**Phase 2: Enhanced TUI (After Task 010)**
- Upgrade to Spectre.Console for rich menus
- Better progress bars, colored selections
- Keep Phase 1 as fallback

## Tasks

### Data & Architecture
- [x] Design data structure (normalized .psd1 format)
- [x] Create `modules/data/command-suggestions.psd1`
- [x] Document architecture in spec

### Core Implementation
- [ ] Create `modules/command-suggestions.ps1` (hook, detection, prompts)
- [ ] Implement `CommandNotFoundAction` hook (PowerShell 7.4+)
- [ ] Implement `Show-CommandSuggestion` (primary suggestion display)
- [ ] Implement `Show-Alternatives` (when user selects "More")
- [ ] Load and parse .psd1 data file

### Installation Logic
- [ ] Create `modules/command-suggestions-install.ps1`
- [ ] Implement package manager detection (winget, scoop priority)
- [ ] Implement `Install-SuggestedTool` function
- [ ] Handle admin rights (offer gsudo, show manual steps)
- [ ] Handle no package manager (show instructions)
- [ ] Verify installation after install

### Configuration
- [ ] Add config options to `config.example.ps1`:
  - `$OhMyPwsh_EnableCommandSuggestions`
  - `$OhMyPwsh_AutoInstallSuggested`
  - `$OhMyPwsh_PreferGsudo`
  - `$OhMyPwsh_DisabledSuggestions`
- [ ] Session-based "don't ask again" tracking

### Testing (Test-First!)
- [ ] Create `tests/modules/command-suggestions.Tests.ps1`
- [ ] Test: Suggestion detection (ee→micro, vim→nvim)
- [ ] Test: Ignore existing commands
- [ ] Test: Package manager detection and priority
- [ ] Test: User input handling (Yes/Cancel/More)
- [ ] Test: Alternative selection (1/2/3)
- [ ] Create `tests/modules/command-suggestions-install.Tests.ps1`
- [ ] Test: Installation via winget (mocked)
- [ ] Test: Installation via scoop (mocked)
- [ ] Test: Admin rights detection
- [ ] Test: gsudo availability and usage
- [ ] Test: Manual installation instructions
- [ ] Test: Installation verification

### Documentation
- [ ] Update README "Coming Soon" section (already done)
- [ ] Create ADR for CommandNotFoundAction approach
- [ ] Document configuration options

## Technical Considerations

### PowerShell `CommandNotFoundAction`

- Available in PowerShell 7.4+
- Fires when command not found
- Can suggest alternatives or create dynamic aliases
- Must set `$CommandLookupEventArgs.StopSearch = $true` to prevent error

### Winget Availability

- Check if winget exists before suggesting it
- Fallback to scoop if user has it
- Show manual install instructions if no package manager

### User Experience

- **Non-intrusive**: Only triggers on command-not-found
- **Educational**: Shows multiple options with descriptions
- **Interactive**: User can install with one keystroke
- **Escapable**: User can press 'n' to skip

## Success Criteria

- [ ] User types `ee`, gets suggestion for `micro`
- [ ] User types `vim`, gets suggestion for `nvim`
- [ ] Interactive prompt allows installation
- [ ] Suggestion only shows if command truly doesn't exist
- [ ] Works with both winget and scoop
- [ ] Tests verify all editor mappings
- [ ] README documents the feature

## Related

- [modules/linux-compat.ps1](../../modules/linux-compat.ps1) - Existing Linux compatibility layer
- [modules/enhanced-tools.ps1](../../modules/enhanced-tools.ps1) - Tool detection patterns
- [CLAUDE.md](../../CLAUDE.md) - DevEx mindset for user stories

## Notes

- This aligns with "discovering awesome PowerShell apps" value proposition
- Follows zero-error philosophy (suggestions, not errors)
- Educational approach (shows equivalents, not just "command not found")
- Power user friendly (can disable with config)

## Future Extensions

- Extend to other command categories (package managers: `apt` → `winget`/`scoop`)
- Network tools: `curl` → built-in `curl` alias or `Invoke-WebRequest`
- System tools: `htop` → `ntop` or `btm` (bottom)
- Create generic suggestion framework for any missing command
