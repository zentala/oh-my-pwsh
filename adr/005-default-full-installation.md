# ADR-005: Default Full Installation with Opt-Out Flags

**Status:** Accepted
**Date:** 2025-11-06
**Deciders:** zentala, Claude Code

## Context

The original installation flow required users to explicitly opt-in to enhanced features:

```powershell
# Before: Opt-in model
Install-OhMyPwsh.ps1                    # Minimal install
Install-OhMyPwsh.ps1 -InstallEnhancedTools  # Must request
Install-OhMyPwsh.ps1 -InstallNerdFonts      # Must request
```

**Problems identified:**
1. Users getting minimal installation by default → poor first experience
2. No automatic Scoop installation → users had to install it manually first
3. Enhanced tools (bat, eza, ripgrep, fd, delta) not installed by default
4. Nerd Fonts not installed by default → terminal icons don't work
5. Multiple installation steps required for full experience

**User research:** Target users (power users, often ex-Linux users) expect:
- One-command installation that "just works"
- Beautiful terminal experience out of the box
- Modern CLI tools (bat, eza, etc.) without manual setup

## Decision

**Invert the installation model from opt-in to opt-out:**

### New Default Behavior
```powershell
# Now: Full installation by default
Install-OhMyPwsh.ps1  # Installs EVERYTHING:
                      # - Scoop (if missing)
                      # - Enhanced tools (bat, eza, ripgrep, fd, delta)
                      # - Nerd Fonts (CascadiaCode by default)
```

### New Skip Flags (opt-out)
```powershell
Install-OhMyPwsh.ps1 -SkipScoop          # Skip Scoop installation
Install-OhMyPwsh.ps1 -SkipEnhancedTools  # Skip enhanced tools
Install-OhMyPwsh.ps1 -SkipNerdFonts      # Skip Nerd Fonts
```

### Backward Compatibility
Keep legacy opt-in flags working:
```powershell
# Legacy flags still work (override Skip flags)
Install-OhMyPwsh.ps1 -InstallEnhancedTools
Install-OhMyPwsh.ps1 -InstallNerdFonts
```

### Automatic Scoop Installation
Add new Step 1.5 in installation flow:
1. Check if `scoop` command exists
2. If missing, automatically install via `irm get.scoop.sh | iex`
3. Set `ExecutionPolicy RemoteSigned -Scope CurrentUser`

### Installation Order
```
Step 1:   oh-my-stats (clone to sibling directory)
Step 1.5: Scoop (NEW - auto-install if missing)
Step 2:   Dependencies (Oh My Posh, fzf, zoxide, PSReadLine, etc.)
Step 3:   PowerShell profile
Step 4:   config.ps1
Step 5:   Enhanced Tools (bat, eza, ripgrep, fd, delta)
Step 6:   Nerd Fonts (interactive or silent mode)
```

## Consequences

### Positive
- ✅ **Better first experience** - Users get full-featured terminal immediately
- ✅ **One-command installation** - No need to run installer multiple times
- ✅ **Scoop auto-installed** - Removes manual prerequisite step
- ✅ **Better for demos** - "Just works" for showcasing to others
- ✅ **Backward compatible** - Old scripts using `-Install*` flags still work
- ✅ **Matches user expectations** - Power users expect comprehensive tools
- ✅ **Faster onboarding** - New users don't miss features they don't know exist

### Negative
- ⚠️ **Longer initial install** - Downloads more packages (5-10 min vs 2-3 min)
- ⚠️ **More disk space** - ~200MB additional (Scoop + tools + fonts)
- ⚠️ **Requires internet** - Cannot install offline (but already required for dependencies)
- ⚠️ **Breaking change** - Default behavior changed (mitigated by skip flags)
- ⚠️ **UAC prompts** - Scoop/winget may request elevation

### Neutral
- 🔄 **More automated** - Less user control, more convenience
- 🔄 **More dependencies** - Scoop becomes effectively required
- 🔄 **Installation complexity** - More steps but invisible to user

## Alternatives Considered

### Alternative 1: Keep Opt-In Model
**Rejected** - Poor user experience, users miss features

### Alternative 2: Interactive Prompts
```powershell
Install-OhMyPwsh.ps1
# Prompt: Install enhanced tools? (Y/n)
# Prompt: Install Nerd Fonts? (Y/n)
```
**Rejected** - Interrupts automation, annoying for scripts

### Alternative 3: Separate "Full" and "Minimal" Installers
```powershell
Install-OhMyPwsh-Full.ps1    # Everything
Install-OhMyPwsh-Minimal.ps1  # Basic only
```
**Rejected** - Two scripts to maintain, confusing for users

### Alternative 4: Profile Flag
```powershell
Install-OhMyPwsh.ps1 -Profile Full    # Default
Install-OhMyPwsh.ps1 -Profile Minimal
```
**Rejected** - Overcomplicates, less discoverable than skip flags

## Implementation Details

### Flag Logic (Backward Compatible)
```powershell
# New variables determine what to install
$ShouldInstallScoop = -not $SkipScoop
$ShouldInstallEnhancedTools = $InstallEnhancedTools -or (-not $SkipEnhancedTools)
$ShouldInstallNerdFonts = $InstallNerdFonts -or (-not $SkipNerdFonts)

# Legacy -Install* flags override -Skip* flags
```

### Error Handling
- If Scoop installation fails → show manual instructions, continue
- If enhanced tools fail → show per-tool errors, continue
- If Nerd Fonts fail → show manual instructions, continue
- **Zero-error philosophy maintained** - installation never completely fails

## Related

- **Task**: [Nerd Fonts auto-config](../todo/backlog/008-nerd-fonts-auto-config.md)
- **ADR**: [ADR-006: Windows Terminal Auto-Configuration](./006-windows-terminal-auto-config.md)
- **Tests**:
  - `tests/Integration/InstallScript.Tests.ps1`
  - `tests/Unit/NerdFonts.Tests.ps1`
- **Documentation**: [CLAUDE.md](../CLAUDE.md) - Installation Scripts section

## Future Considerations

- Add `-Minimal` flag as alias for all skip flags combined?
- Add telemetry to track installation completion rates?
- Support offline installation with cached packages?
- Add progress bars for long-running installations?
