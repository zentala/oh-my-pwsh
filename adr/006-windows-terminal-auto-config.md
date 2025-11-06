# ADR-006: Windows Terminal Automatic Font Configuration

**Status:** Accepted
**Date:** 2025-11-06
**Deciders:** zentala, Claude Code

## Context

After installing Nerd Fonts, users had to manually configure their terminal:

**Previous user experience:**
1. Install font via `Install-NerdFonts`
2. See instructions:
   ```
   📌 Next steps:
     1. Restart your terminal
     2. In Windows Terminal: Settings → Profiles → Defaults → Appearance → Font face
     3. Select the Nerd Font you just installed
     4. Enable in oh-my-pwsh: Edit config.ps1
        Set: $global:OhMyPwsh_UseNerdFonts = $true
   ```
3. User must:
   - Navigate Windows Terminal UI (4+ clicks)
   - Find correct font name in dropdown (100+ fonts)
   - Remember to enable in config.ps1
   - **Many users skip this step** → icons don't work

**Problems identified:**
- Multi-step manual process → high abandonment rate
- Requires UI navigation → not scriptable
- Font name mismatch → users select wrong variant (e.g., Mono)
- No validation → users don't know if it worked
- Poor UX for target audience (power users who prefer CLI)

## Decision

**Implement automatic font configuration for Windows Terminal:**

### Core Feature: `Set-WindowsTerminalFont`

Automatically modify `settings.json` to configure font:

```powershell
Set-WindowsTerminalFont -FontName "CaskaydiaCove Nerd Font"
```

**What it does:**
1. Detect terminal type (Windows Terminal, VS Code, ConEmu, Legacy)
2. Locate `settings.json` (Windows Terminal specific path)
3. Create timestamped backup
4. Read and parse JSON
5. Modify `profiles.defaults.font.face`
6. Write back to file
7. On error: Restore backup automatically

### Terminal Detection: `Get-TerminalType`

Detect which terminal emulator is running:

```powershell
function Get-TerminalType {
    # Priority order:
    if ($env:WT_SESSION) { return "WindowsTerminal" }
    if ($env:VSCODE_PID) { return "VSCode" }
    if ($env:ConEmuPID) { return "ConEmu" }
    return "LegacyConsole"
}
```

### Integration with `Install-NerdFonts`

After successful font installation:

```powershell
# 1. Detect terminal
$termType = Get-TerminalType

# 2. If Windows Terminal → offer auto-config
if ($termType -eq "WindowsTerminal") {
    Write-Host "🎯 Detected Windows Terminal!"
    $autoConfig = Read-Host "Would you like to automatically configure this font? (Y/n)"

    if ($autoConfig -ne 'n') {
        Set-WindowsTerminalFont -FontName $fontDisplayName
        # Success → show "RESTART terminal" instructions
        # Failure → show manual instructions
    }
}

# 3. If other terminal → show terminal-specific instructions
```

### Safety Mechanisms

1. **Backup before modify**
   ```powershell
   $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
   $backupPath = "$settingsPath.backup-$timestamp"
   Copy-Item $settingsPath $backupPath
   ```

2. **Rollback on error**
   ```powershell
   try {
       # Modify settings
   } catch {
       Copy-Item $backupPath $settingsPath  # Restore backup
   }
   ```

3. **Validation**
   - Check if running in Windows Terminal
   - Verify settings.json exists
   - Test JSON parsing before writing

## Consequences

### Positive
- ✅ **One-click configuration** - User answers "Y", font is configured
- ✅ **Prevents wrong variant** - Script uses correct font name (Regular, not Mono)
- ✅ **Safer than manual** - Automatic backup/restore on error
- ✅ **Better UX for power users** - CLI-based, scriptable
- ✅ **Reduces support questions** - Fewer "icons don't work" issues
- ✅ **Terminal-aware** - Shows appropriate instructions per terminal type

### Negative
- ⚠️ **Windows Terminal only** - VS Code/ConEmu get manual instructions
- ⚠️ **Requires restart** - Windows Terminal must be closed/reopened
- ⚠️ **JSON complexity** - settings.json has complex structure
- ⚠️ **Could conflict** - User's custom settings.json modifications
- ⚠️ **Breaking on WT updates** - If Microsoft changes settings.json format

### Neutral
- 🔄 **More automation** - Less user control vs more convenience
- 🔄 **settings.json dependency** - Tied to Windows Terminal implementation
- 🔄 **Backup accumulation** - Multiple `.backup-*` files over time

## Alternatives Considered

### Alternative 1: Use Windows Terminal CLI
```powershell
wt.exe --profile defaults --font-face "CaskaydiaCove Nerd Font"
```
**Rejected** - No such CLI option exists in Windows Terminal

### Alternative 2: PowerShell Modules for WT
Use existing community modules (e.g., `WTSettings`)

**Rejected** - Adds external dependency, may not be maintained

### Alternative 3: Registry-Based Configuration
Modify Windows Terminal registry settings

**Rejected** - Settings are JSON-file based, not registry

### Alternative 4: Always Auto-Configure (No Prompt)
```powershell
# Silent mode - no asking
Set-WindowsTerminalFont -FontName $font -Silent
```
**Rejected** - Too aggressive, users should consent to file modifications

### Alternative 5: VS Code Support
Also auto-configure VS Code terminal

**Considered for future** - Different API (`settings.json` in different location)

## Implementation Details

### Font Name Mapping
```powershell
# Scoop package name → Display name
$fontMapping = @{
    "CascadiaCode-NF" = "CaskaydiaCove Nerd Font"
    "FiraCode-NF" = "FiraCode Nerd Font"
    "JetBrainsMono-NF" = "JetBrainsMono Nerd Font"
    "Meslo-NF" = "Meslo Nerd Font"
}
```

### JSON Structure
```json
{
  "profiles": {
    "defaults": {
      "font": {
        "face": "CaskaydiaCove Nerd Font"
      }
    }
  }
}
```

### Error Messages
```powershell
# Not Windows Terminal
"⚠️  Not running in Windows Terminal - cannot auto-configure"

# Settings not found
"✗ Windows Terminal settings not found at: [path]"

# Success
"✓ Font set to: CaskaydiaCove Nerd Font
  Restart Windows Terminal for changes to take effect"
```

## Testing Strategy

Created comprehensive test suite (`tests/Unit/NerdFonts.Tests.ps1`):

1. **Terminal detection tests** (6 tests)
   - Windows Terminal detection
   - VS Code detection
   - ConEmu detection
   - Legacy console detection
   - Priority order

2. **Font configuration tests** (8 tests)
   - Success path with mocking
   - Error handling
   - Backup creation
   - Rollback on failure
   - Settings file validation

3. **Integration tests**
   - End-to-end installation flow
   - User interaction scenarios

## Related

- **ADR**: [ADR-005: Default Full Installation](./005-default-full-installation.md)
- **ADR**: [ADR-007: Font Variant Warnings](./007-font-variant-warnings.md)
- **Module**: `modules/nerd-fonts.ps1`
- **Tests**: `tests/Unit/NerdFonts.Tests.ps1`
- **Documentation**: [CLAUDE.md](../CLAUDE.md) - Installation Scripts section

## Future Considerations

- Support VS Code terminal auto-configuration?
- Support ConEmu configuration?
- Detect and warn about conflicting font settings?
- Add font preview before installation?
- Support custom font sizes/weights?
- Handle Windows Terminal Canary/Preview versions?
