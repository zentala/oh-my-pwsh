# 003 - Nerd Font Architecture (No Brackets)

**Status:** `active`
**Priority:** P1

## Goal

Re-enable Nerd Font support with proper formatting:
- Nerd Font mode: `icon text` (no brackets)
- Unicode fallback: `[icon] text` (with brackets)

## New Nerd Font Codes

Updated icon definitions:
- `success`: f0135 󰄵
- `warning`: f05d6 󰗖
- `error`: f052f
- `info`: f0449
- `tip`: f0400
- `question`: f0420

## Problem with Current Architecture

Current `Write-Log` / helpers always add brackets `[icon]` regardless of mode.
This looks good for Unicode but bad for Nerd Fonts.

**Current output:**
```
[󰄵] Module loaded    # Nerd Font - brackets look weird
[✓] Module loaded    # Unicode - brackets OK
```

**Desired output:**
```
󰄵 Module loaded      # Nerd Font - clean, no brackets
[✓] Module loaded    # Unicode - brackets for clarity
```

## Architecture Changes Needed

### Option A: Format in `Get-FallbackIcon`

Make `Get-FallbackIcon` return pre-formatted string with/without brackets:

```powershell
function Get-FallbackIcon {
    param([string]$Role, [switch]$WithBrackets)

    $icon = # ... get icon

    if ($WithBrackets -or -not (Test-NerdFontSupport)) {
        return "[$icon]"
    } else {
        return $icon
    }
}
```

**Pros:** Simple, one function handles all
**Cons:** Mixing icon retrieval with formatting

### Option B: Separate Formatting Function

Keep `Get-FallbackIcon` pure (just returns icon character).
Add new `Format-StatusIcon` for formatting:

```powershell
function Get-FallbackIcon {
    # Returns just the icon character
}

function Format-StatusIcon {
    param([string]$Icon)

    if (Test-NerdFontSupport) {
        return "$Icon "  # Icon + space, no brackets
    } else {
        return "[$Icon] "  # [Icon] + space
    }
}
```

**Pros:** Separation of concerns, testable
**Cons:** Two function calls needed

### Option C: Smart `Write-Log`

`Write-Log` handles formatting internally:

```powershell
function Write-Log {
    param([string]$Level, [string]$Message)

    $icon = Get-FallbackIcon -Role $Level

    if (Test-NerdFontSupport) {
        Write-Host "$icon $Message"  # No brackets
    } else {
        Write-Host "[$icon] $Message"  # Brackets
    }
}
```

**Pros:** Centralized logic in one place
**Cons:** `Write-Log` needs to exist first (Task #001)

## Recommended Approach

**Option B** - Separate formatting function.

Why:
1. Clean separation: `Get-FallbackIcon` = data, `Format-StatusIcon` = presentation
2. Testable independently
3. Can be used in any context (not just `Write-Log`)
4. Doesn't block Task #001 (logging system)

## Implementation Plan

### Phase 1: Add Formatting Function
- [ ] Create `Format-StatusIcon` in `settings/icons.ps1`
- [ ] Takes icon character, returns formatted string with/without brackets
- [ ] Based on `Test-NerdFontSupport`

### Phase 2: Update Icon Codes
- [x] Update `$script:IconMap` with new NF codes (already done)
- [ ] Test rendering in terminal with NF installed

### Phase 3: Update Helpers
- [ ] Update `Write-InstallHint` to use `Format-StatusIcon`
- [ ] Update `Write-ToolStatus` to use `Format-StatusIcon`
- [ ] Update `Write-ModuleStatus` to use `Format-StatusIcon`

### Phase 4: Test Both Modes
- [ ] Test with `$global:OhMyPwsh_UseNerdFonts = $false` (Unicode with brackets)
- [ ] Test with `$global:OhMyPwsh_UseNerdFonts = $true` (NF without brackets)
- [ ] Update `test-icons.ps1` to show formatted output

### Phase 5: Documentation
- [ ] Update CLAUDE.md with new architecture decision
- [ ] Remove "suspended" notice if NF works well
- [ ] Document formatting logic

## Success Criteria

- [ ] Nerd Font mode shows: `󰄵 text` (no brackets)
- [ ] Unicode mode shows: `[✓] text` (with brackets)
- [ ] All existing code works with new formatting
- [ ] Icons render correctly in terminals with NF

## Files to Modify

- `settings/icons.ps1` - add `Format-StatusIcon`
- `modules/logger.ps1` - update helpers to use formatting
- `test-icons.ps1` - test formatted output
- `CLAUDE.md` - update architecture docs

## Dependencies

- None (can implement independently of Task #001)
