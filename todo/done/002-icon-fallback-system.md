# 002 - Icon Fallback System

**Status:** `done` (Nerd Font support suspended - Unicode only)
**Priority:** P0 (highest)

## Goal

Create universal icon system with Nerd Font detection and Unicode fallbacks. All icons in the codebase must use this system.

## Problem

Current code:
- Hardcodes icons (✓, !, ✗, i) directly in strings
- No Nerd Font support
- Can't customize icons per user preference
- Icons scattered across multiple files

## Solution Architecture

### Icon Configuration

Store icon definitions in `settings/icons.ps1`:

```powershell
# Icon definitions with Nerd Font → Unicode fallback
$script:IconMap = @{
    success = @{
        NerdFont = "" # U+F00C (check)
        Unicode  = "✓"
        Color    = "Green"
    }
    warning = @{
        NerdFont = "" # U+F0205 (alert outline)
        Unicode  = "!"
        Color    = "Yellow"
    }
    error = @{
        NerdFont = "" # U+F467 (close circle)
        Unicode  = "✗"
        Color    = "Red"
    }
    info = @{
        NerdFont = "" # U+F129 (info circle)
        Unicode  = "i"
        Color    = "Cyan"
    }
    tip = @{
        NerdFont = "💡" # Lightbulb
        Unicode  = "💡"
        Color    = "Yellow"
    }
}
```

### Nerd Font Detection

```powershell
function Test-NerdFontSupport {
    # Check if Nerd Fonts are configured
    if ($null -ne $global:OhMyPwsh_UseNerdFonts) {
        return $global:OhMyPwsh_UseNerdFonts
    }

    # Auto-detect: Check terminal font
    # For now, default to $false (user must opt-in via config)
    return $false
}
```

### Core Function: `Get-FallbackIcon`

**Universal icon getter:**

```powershell
function Get-FallbackIcon {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Role  # success, warning, error, info, tip, etc.
    )

    # Get icon definition
    if (-not $script:IconMap.ContainsKey($Role)) {
        Write-Warning "Unknown icon role: $Role. Using default."
        return "?"
    }

    $iconDef = $script:IconMap[$Role]

    # Check Nerd Font support
    $useNerdFont = Test-NerdFontSupport

    # Return appropriate icon
    if ($useNerdFont) {
        return $iconDef.NerdFont
    } else {
        return $iconDef.Unicode
    }
}
```

### Helper: Get Icon Color

```powershell
function Get-IconColor {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Role
    )

    if (-not $script:IconMap.ContainsKey($Role)) {
        return "White"
    }

    return $script:IconMap[$Role].Color
}
```

## Configuration

User can override in `config.ps1`:

```powershell
# Enable Nerd Fonts (requires terminal with Nerd Font installed)
$global:OhMyPwsh_UseNerdFonts = $true

# Custom icon overrides (optional)
$global:OhMyPwsh_CustomIcons = @{
    success = "✅"  # Use emoji instead
    warning = "⚠️"
}
```

## Usage Examples

### In Write-Log

```powershell
function Write-Log {
    param(
        [string]$Level,
        [string]$Message
    )

    $icon = Get-FallbackIcon -Role $Level
    $color = Get-IconColor -Role $Level

    Write-Host "[" -NoNewline -ForegroundColor DarkGray
    Write-Host $icon -NoNewline -ForegroundColor $color
    Write-Host "] " -NoNewline -ForegroundColor DarkGray
    Write-Host $Message -ForegroundColor White
}
```

### Direct Usage

```powershell
# Get icon for custom use
$successIcon = Get-FallbackIcon -Role "success"
Write-Host "Build complete $successIcon" -ForegroundColor Green

# Feature tip
$tipIcon = Get-FallbackIcon -Role "tip"
Write-Host "$tipIcon Press Ctrl+R to search history" -ForegroundColor Cyan
```

## Implementation Plan

### Phase 1: Icon System
- [ ] Create `settings/icons.ps1`
- [ ] Define `$script:IconMap` with all icon roles
- [ ] Implement `Test-NerdFontSupport`
- [ ] Implement `Get-FallbackIcon`
- [ ] Implement `Get-IconColor`

### Phase 2: Integration
- [ ] Source `settings/icons.ps1` in `profile.ps1` (early)
- [ ] Update `Write-Log` to use `Get-FallbackIcon`
- [ ] Add config option to `config.example.ps1`

### Phase 3: Refactor Existing Code
- [ ] Find all hardcoded icons in codebase
- [ ] Replace with `Get-FallbackIcon` calls
- [ ] Test all icon usages

### Phase 4: Testing
- [ ] Test with `$global:OhMyPwsh_UseNerdFonts = $false` (Unicode)
- [ ] Test with `$global:OhMyPwsh_UseNerdFonts = $true` (Nerd Fonts)
- [ ] Test custom icon overrides
- [ ] Verify all icon roles render correctly

### Phase 5: Documentation
- [ ] Document in `./docs/ICONS.md`
- [ ] Add examples for custom icons
- [ ] Document available icon roles

## Icon Roles Needed

Based on current codebase:
- `success` - Feature loaded
- `warning` - Optional feature missing
- `error` - Critical failure
- `info` - Informational message
- `tip` - Helpful hint
- (Future) `loading`, `question`, `rocket`, etc.

## Success Criteria

- [ ] Zero hardcoded icons in codebase
- [ ] All icons use `Get-FallbackIcon`
- [ ] Works with and without Nerd Fonts
- [ ] User can override icons in config
- [ ] Easy to add new icon roles

## Files to Create/Modify

- `settings/icons.ps1` (new)
- `config.example.ps1` (add Nerd Font option)
- `modules/logging.ps1` (integrate `Get-FallbackIcon`)
- `profile.ps1` (source icons.ps1 early)
- `docs/ICONS.md` (new - user documentation)

## Dependencies

- None (but task #001 depends on this)

## Notes

- Default to Unicode fallback for safety (not all terminals have Nerd Fonts)
- User must explicitly enable Nerd Fonts in config
- Consider future: auto-detect based on `$env:TERM` or font name

---

## 🛑 IMPLEMENTATION OUTCOME (2025-01-18)

**Status:** Core system implemented, Nerd Font support SUSPENDED

### What Works ✅
- ✅ `Get-FallbackIcon -Role <name>` function implemented
- ✅ `Get-IconColor -Role <name>` function implemented
- ✅ Icon definitions in `settings/icons.ps1`
- ✅ Configuration option in `config.example.ps1`
- ✅ Unicode fallbacks work perfectly

### What's Suspended ⚠️
- ⚠️ **Nerd Font rendering** - looks bad/broken in most terminals
- ⚠️ Characters render as `?` or broken glyphs
- ⚠️ Not reliable across different terminal emulators

### Decision
**Use Unicode only** for now. Nerd Font codes preserved in `IconMap` but:
- Default: `$global:OhMyPwsh_UseNerdFonts = $false`
- **DO NOT REMOVE** NerdFont definitions from `settings/icons.ps1`
- Kept for future when terminal support improves
- All documentation updated to reflect Unicode-only approach

### Current Icon Set (Unicode)
| Role       | Icon | Color   |
|------------|------|---------|
| `success`  | `✓`  | Green   |
| `warning`  | `!`  | Yellow  |
| `error`    | `x`  | Red     |
| `info`     | `i`  | Cyan    |
| `tip`      | `※`  | Blue    |
| `question` | `?`  | Magenta |

### For Future Developers
If you want to re-enable Nerd Fonts:
1. Test with `.\test-icons.ps1`
2. Verify icons render correctly in Windows Terminal / your terminal
3. If working: update `CLAUDE.md` to remove suspension notice
4. If still broken: leave as-is, Unicode works fine

### Files Modified
- `settings/icons.ps1` - warning added about suspended feature
- `CLAUDE.md` - documented Unicode-only approach
- `config.example.ps1` - Nerd Font option with warning
- `profile.ps1` - sources icons.ps1

**Bottom line:** System is complete and works. Just using Unicode instead of Nerd Fonts.
