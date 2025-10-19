# Feature Spec: Smart Editor Suggestions

**Status:** Draft
**Created:** 2025-10-19
**Related Task:** [todo/backlog/007-smart-editor-suggestions.md](../todo/backlog/007-smart-editor-suggestions.md)
**Implementation:** `modules/command-suggestions.ps1` (pending)
**Tests:** `tests/modules/command-suggestions.Tests.ps1` (pending)

---

## Vision

When a Linux user migrating to Windows types a familiar editor command that doesn't exist (like `ee`, `vim`, `nano`), the system detects this and suggests modern Windows alternatives with educational context, offering one-click installation.

**Core principle:** Educational, not intrusive. User always has control.

---

## User Stories

### Story 1: Missing Editor Discovery

> "As a Linux user new to Windows, when I type `ee` out of habit, I want to discover that `micro` is a similar Windows alternative and learn what it offers, so I can make an informed decision about installing it."

### Story 2: Quick Installation

> "As a power user, when I decide to install a suggested tool, I want it to install automatically using the best available package manager, so I don't waste time on manual downloads."

### Story 3: Alternative Exploration

> "As a curious developer, when a tool is suggested, I want to see other alternatives and compare them, so I can choose the best fit for my workflow."

### Story 4: Educational Context

> "As someone learning PowerShell, when a tool is suggested, I want to understand what it replaces from Linux and why I might want it, so I can build my mental model of the Windows ecosystem."

---

## UX Flow: Version 1 (Simple ASCII - No Dependencies)

### Scenario A: User types unknown command

```
PS> ee myfile.txt

[!] Command 'ee' not found

💡 Windows Alternative: micro

   Easy terminal editor (most similar to 'ee')

   Features:
    • Mouse support
    • Familiar keybindings (Ctrl+S, Ctrl+Q)
    • Syntax highlighting
    • No learning curve (unlike vim)

   🐧 Linux equivalent: ee, nano

Install micro? [Yes/Cancel/More]:
```

**User input options:**
- `Yes` or `Y` or `y` → Proceed to installation
- `Cancel` or `C` or `c` or `n` → Cancel, don't ask again for this session
- `More` or `M` or `m` → Show alternatives

### Scenario B: User chooses "More"

```
Install micro? [Yes/Cancel/More]: More

Windows alternatives for 'ee':

  1. micro  - Easy editor (recommended) ⭐
     Features: Mouse support, familiar keys, no learning curve
     Install: winget install zyedidia.micro

  2. nano   - Simple Unix-style editor
     Features: Lightweight, familiar for Linux users
     Install: winget install GNU.Nano

  3. nvim   - Modern Vim (advanced)
     Features: Powerful, extensible, but steep learning curve
     Install: winget install Neovim.Neovim

Select option [1/2/3] or [Cancel]:
```

**User input:**
- `1`, `2`, `3` → Install selected alternative
- `Cancel` or `C` or `c` → Cancel suggestion

### Scenario C: Installation Flow (Happy Path)

```
Select option [1/2/3] or [Cancel]: 1

Installing micro...

✓ Package manager detected: winget
✓ Installing: winget install zyedidia.micro

[Progress indicator - simple dots or spinner]
Installing ........

✓ micro installed successfully!

You can now use it:
  micro myfile.txt

Try it now? [Yes/No]: Yes

[launches: micro myfile.txt]
```

### Scenario D: Installation - No Package Manager

```
Installing micro...

[!] No package manager detected

To install micro, you need a package manager first.

Recommended: winget (built-in on Windows 11)

  1. Install winget
     → Open Microsoft Store
     → Search for "App Installer"
     → Install

  2. Use scoop (portable, no admin needed)
     → Open PowerShell and run:
       irm get.scoop.sh | iex

  3. Manual install
     → Download from: https://github.com/zyedidia/micro/releases

After installing a package manager, restart PowerShell and try again:
  ee myfile.txt

Press any key to continue...
```

### Scenario E: Installation - Needs Admin Rights (with gsudo)

```
Installing micro...

✓ Package manager detected: winget
[!] This package requires administrator rights

💡 Suggestion: Install gsudo for easier elevation

   gsudo is like Linux 'sudo' for Windows
   Allows running commands with admin rights without UAC popup

   Install gsudo? [Yes/No/Manual]:
```

**Options:**
- `Yes` → Install gsudo first, then install micro
- `No` → Show manual instructions
- `Manual` → Show how to install manually with admin terminal

### Scenario F: Installation - No gsudo, Needs Admin (Manual Instructions)

```
Installing micro...

✓ Package manager detected: winget
[!] This package requires administrator rights

Manual installation steps:

  1. Right-click PowerShell icon
  2. Select "Run as Administrator"
  3. In admin terminal, run:
     winget install zyedidia.micro

  4. Restart your normal PowerShell session

Press any key to continue...
```

---

## Data Structure

**File:** `modules/data/command-suggestions.psd1`

**Format:** PowerShell Data File (native, fast, supports comments)

**Structure:** Two-section normalized design
1. **Tools** - Full tool definitions (single source of truth)
2. **Suggestions** - Map missing commands → tool references

### Why This Design?

**DRY Principle:** Tool definition exists once, referenced multiple times
- `micro` defined once in Tools
- Referenced by: `ee` suggestion, `vim` alternative, `nano` alternative

**Easy to Extend:** Add new tool = one entry in Tools, reference it in Suggestions

**Reusable:** Tool data can be used for:
- Command suggestions
- Help system ("tell me about micro")
- Installer tool lists
- Statistics ("what editors are installed")

### Example Structure

```powershell
@{
    Tools = @{
        micro = @{
            Name = 'micro'
            Category = 'editor'
            Description = 'Easy terminal editor (most similar to ee)'
            InstallCmd = 'winget install zyedidia.micro'
            PackageManager = 'winget'
            RequiresAdmin = $false
            LinuxEquiv = @('ee', 'nano')
            Features = @('Mouse support', 'Familiar keys', '...')
            Homepage = 'https://micro-editor.github.io'
        }
        nano = @{ ... }
        nvim = @{ ... }
    }

    Suggestions = @{
        ee = @{
            Primary = 'micro'              # Reference to Tools.micro
            Alternatives = @('nano', 'nvim')  # References to other tools
            Context = 'Easy Editor from FreeBSD'
        }
        vim = @{
            Primary = 'nvim'
            Alternatives = @('vim', 'micro')
            Context = 'Vi IMproved text editor'
        }
    }
}
```

### How Code Uses It

```powershell
# Load once
$Data = Import-PowerShellDataFile "modules/data/command-suggestions.psd1"

# When 'ee' not found:
$suggestion = $Data.Suggestions['ee']           # Get suggestion
$tool = $Data.Tools[$suggestion.Primary]        # Get full tool details
Show-Suggestion -Tool $tool -Alternatives $suggestion.Alternatives
```

### Categories

**Phase 1 (MVP):**
- Editors: `ee`, `vim`, `vi`, `nano`
- System: `sudo`

**Phase 2 (Future):**
- Package managers: `apt`, `yum`, `brew` → `winget`, `scoop`
- System monitoring: `htop`, `top` → `btm`, `ntop`
- Network: curl alternatives, dig → Resolve-DnsName

---

## Behavior Rules

### Detection Rules

1. **Only trigger on truly missing commands**
   - Don't suggest if command exists (even if it's an alias)
   - Don't suggest if user has already installed the tool

2. **Don't be annoying**
   - If user cancels, don't ask again for this command in current session
   - Respect user's `$OhMyPwsh_DisableSuggestions` config flag

3. **Educational focus**
   - Always explain what the tool does
   - Always show Linux equivalent
   - Show features/benefits, not just "install this"

### Installation Rules

1. **Package Manager Priority:**
   ```
   1. winget (prefer - built-in on Windows 11)
   2. scoop (fallback - portable, no admin)
   3. Manual (last resort)
   ```

2. **Admin Rights Handling:**
   - Check if package requires admin
   - If yes + gsudo exists → Offer gsudo elevation
   - If yes + no gsudo → Suggest installing gsudo OR show manual steps
   - Never auto-elevate without asking

3. **Verification:**
   - After install, verify command is available
   - Show success message with usage example
   - Offer to launch immediately if appropriate

### Configuration

**User can control via config.ps1:**

```powershell
# Enable/disable all suggestions
$global:OhMyPwsh_EnableCommandSuggestions = $true

# Auto-install without asking (if no admin needed)
$global:OhMyPwsh_AutoInstallSuggested = $false  # Default: always ask

# Prefer gsudo for admin elevation
$global:OhMyPwsh_PreferGsudo = $true

# Commands to never suggest for (user preference)
$global:OhMyPwsh_DisabledSuggestions = @('vim')  # User prefers no vim suggestion
```

---

## Edge Cases

### 1. Package Manager Not Available

**Behavior:** Show instructions to install package manager
**Options:** winget (Store), scoop (script), manual download
**Education:** Explain what package managers are (like apt/yum for Windows)

### 2. Install Fails

**Behavior:**
- Show error message
- Offer to show manual install instructions
- Log error for debugging

**Example:**
```
[✗] Installation failed

Error: Package not found in winget repository

Try manual installation:
  1. Download: https://github.com/zyedidia/micro/releases
  2. Extract to: C:\Program Files\micro
  3. Add to PATH

Or try scoop:
  scoop install micro
```

### 3. Multiple Package Managers Available

**Behavior:** Prefer winget, but allow user to choose

**Example:**
```
Detected package managers: winget, scoop

Install micro using:
  [1] winget (recommended)
  [2] scoop

Select [1/2]:
```

### 4. Command Exists But Different

**Example:** User has `vim` (classic) but we want to suggest `nvim` (modern)

**Behavior:** Don't trigger - user already has vim
**Future:** Offer "upgrade suggestions" as separate feature

### 5. Offline / No Internet

**Behavior:**
- Detect no internet connection
- Show manual download instructions
- Don't attempt install

---

## Testing Scenarios

### Unit Tests

1. **Suggestion Detection**
   - Detects 'ee' and suggests 'micro'
   - Detects 'vim' and suggests 'nvim'
   - Ignores commands already installed
   - Ignores commands not in suggestion database

2. **Package Manager Detection**
   - Detects winget when available
   - Detects scoop when available
   - Prefers winget over scoop
   - Handles neither available

3. **Admin Rights**
   - Detects when admin needed
   - Offers gsudo if available
   - Shows manual steps if no gsudo
   - Never auto-elevates without asking

4. **User Input**
   - Accepts [Yes/Y/y] for install
   - Accepts [Cancel/C/c/N/n] for cancel
   - Accepts [More/M/m] for alternatives
   - Accepts [1/2/3] for alternative selection

5. **Installation**
   - Installs via winget successfully
   - Installs via scoop successfully
   - Verifies installation after install
   - Handles install failures gracefully

### Integration Tests

1. **Full Flow: Happy Path**
   - User types 'ee'
   - Suggestion shown
   - User accepts
   - Package installed via winget
   - Verification successful
   - Success message shown

2. **Full Flow: No Package Manager**
   - User types 'ee'
   - Suggestion shown
   - User accepts
   - No package manager detected
   - Manual instructions shown

3. **Full Flow: Needs Admin**
   - User types 'ee'
   - Suggestion shown
   - User accepts
   - Package needs admin
   - gsudo available → offer elevation
   - gsudo not available → show manual steps

---

## Implementation Notes (For Developer)

**NOT part of spec, but helpful context:**

- Use PowerShell `CommandNotFoundAction` event (PS 7.4+)
- Store suggestions in hashtable (easy to extend)
- Module: `modules/command-suggestions.ps1`
- Config integration: `config.ps1`
- Logging: Use existing `Write-StatusMessage` system

**Testing:**
- Mock `Get-Command` to simulate missing commands
- Mock `winget`, `scoop` availability
- Mock admin rights detection
- Test all user input variations

---

## Future Enhancements

**Not in MVP, but ideas for later:**

1. **Context-Aware Suggestions**
   - User types `vim Dockerfile` → suggest Docker-specific tools
   - User in git repo → suggest git-specific tools

2. **Learning Mode Integration**
   - Show PowerShell equivalent alongside suggestion
   - "In PowerShell, you can also use: Get-Content"

3. **Suggestion Categories Beyond Editors**
   - Package managers (`apt` → `winget`/`scoop`)
   - System monitoring (`htop` → `btm`/`ntop`)
   - Network tools (`dig` → `Resolve-DnsName`)

4. **Interactive TUI (After Task 010)**
   - Use Spectre.Console for rich menus
   - Better progress bars
   - Color-coded feature lists

5. **Telemetry (Optional)**
   - Track which suggestions users accept/reject
   - Help prioritize future suggestions

---

## Questions & Decisions

### ✅ Resolved

1. **Q:** Use hashtable or JSON for data?
   **A:** Hashtable (native PowerShell, easy to extend, no parsing overhead)

2. **Q:** Auto-install or always ask?
   **A:** Always ask (config flag: `$OhMyPwsh_AutoInstallSuggested = $false` by default)

3. **Q:** Use gsudo?
   **A:** Yes, but offer to install it first if missing. If user declines, show manual steps.

4. **Q:** Wait for Task 010 (TUI)?
   **A:** No - implement simple ASCII version first. After Task 010, enhance with Spectre.Console.

5. **Q:** Where save "don't ask again"?
   **A:** Session-only for now (config.ps1 for permanent disable)

### 🤔 Pending

*None currently*

---

## Success Metrics

**Feature is successful when:**

- ✅ Linux user types `ee` and discovers `micro`
- ✅ User understands what tool does and why to install it
- ✅ Installation works with one click (if package manager available)
- ✅ User can explore alternatives before deciding
- ✅ No errors on edge cases (no package manager, no internet, needs admin)
- ✅ Tests cover all scenarios
- ✅ User can disable feature via config

---

**Last Updated:** 2025-10-19
**Status:** Ready for implementation (pending Task 010 for TUI enhancements)
