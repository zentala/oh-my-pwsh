# 004 - Write-StatusMessage Function

**Status:** `active`
**Priority:** P0 (blocking Task #001)

## Goal

Create `Write-StatusMessage` function that renders status messages with proper color control for each component (brackets, icon, text).

## Problem

Current `Get-FallbackIcon -AsStatusBadge` returns a string that can't be colored partially:
```powershell
$badge = Get-FallbackIcon -Role "success" -AsStatusBadge
Write-Host "${badge}Module loaded" -ForegroundColor Green
# Everything is green - can't color brackets separately
```

## Solution: Write-StatusMessage (Option B)

Dedicated function that composes and colors each part independently.

### Implementation

```powershell
function Write-StatusMessage {
    <#
    .SYNOPSIS
    Write a status message with colored icon badge

    .DESCRIPTION
    Renders status message with proper colors:
    - Brackets: DarkGray
    - Icon: Role color (Green/Yellow/Red/Cyan/Blue/Magenta)
    - Text: White

    Supports both Nerd Font and Unicode modes.

    .PARAMETER Role
    Icon role: success, warning, error, info, tip, question

    .PARAMETER Message
    Status message text

    .EXAMPLE
    Write-StatusMessage -Role "success" -Message "Module loaded"
    # Unicode: [✓] Module loaded
    # NF:      󰄵 Module loaded

    .EXAMPLE
    Write-StatusMessage -Role "warning" -Message "Optional tool missing"
    # Unicode: [!] Optional tool missing
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('success', 'warning', 'error', 'info', 'tip', 'question')]
        [string]$Role,

        [Parameter(Mandatory)]
        [string]$Message,

        [switch]$NoIndent
    )

    $icon = Get-FallbackIcon -Role $Role  # Standalone icon
    $iconColor = Get-IconColor -Role $Role

    # Indent (2 spaces by default)
    $indent = if ($NoIndent) { "" } else { "  " }
    Write-Host $indent -NoNewline

    if (Test-NerdFontSupport) {
        # Nerd Font mode: icon + space (no brackets)
        Write-Host $icon -NoNewline -ForegroundColor $iconColor
        Write-Host " " -NoNewline
        Write-Host $Message -ForegroundColor White
    } else {
        # Unicode mode: [icon] + space
        Write-Host "[" -NoNewline -ForegroundColor DarkGray
        Write-Host $icon -NoNewline -ForegroundColor $iconColor
        Write-Host "] " -NoNewline -ForegroundColor DarkGray
        Write-Host $Message -ForegroundColor White
    }
}
```

### Color Breakdown

**Unicode Mode:**
```
  [✓] Module loaded
  ^ ^ ^           ^
  │ │ │           └─ White (message text)
  │ │ └─ DarkGray (closing bracket)
  │ └─ Green (icon in role color)
  └─ DarkGray (opening bracket)
```

**Nerd Font Mode:**
```
  󰄵 Module loaded
  ^ ^           ^
  │ │           └─ White (message text)
  │ └─ (space)
  └─ Green (icon in role color)
```

## File Structure

### Create New File

**`modules/status-output.ps1`**

```powershell
# ============================================
# Status Output Module
# ============================================
# Colored status message rendering

function Write-StatusMessage {
    # ... implementation above
}
```

### Update profile.ps1

Source the new module:

```powershell
# After icons.ps1, before logger.ps1
. "$ProfileRoot\settings\icons.ps1"
. "$ProfileRoot\modules\status-output.ps1"  # NEW
. "$ProfileRoot\modules\logger.ps1"
```

## Migration Plan

### Phase 1: Create Function
- [ ] Create `modules/status-output.ps1`
- [ ] Implement `Write-StatusMessage`
- [ ] Source in `profile.ps1`
- [ ] Test manually

### Phase 2: Update Existing Helpers

Update helpers in `modules/logger.ps1` to use `Write-StatusMessage`:

**Before:**
```powershell
function Write-ToolStatus {
    if ($Installed) {
        Write-ProfileStatus -Level success -Primary $displayName
    } else {
        Write-InstallHint -Tool $Name -Description $Description -InstallCommand "..."
    }
}
```

**After:**
```powershell
function Write-ToolStatus {
    param([string]$Name, [bool]$Installed, [string]$Description = "")

    if ($Installed) {
        $msg = if ($Description) { "$Name ($Description)" } else { $Name }
        Write-StatusMessage -Role "success" -Message $msg
    } else {
        # For missing tools, use warning + install hint
        $msg = "install ``$Name``"
        if ($Description) { $msg += " for $Description" }
        $msg += ": scoop install $Name"
        Write-StatusMessage -Role "warning" -Message $msg
    }
}
```

**Files to update:**
- [ ] `Write-ToolStatus`
- [ ] `Write-ModuleStatus`
- [ ] `Write-InstallHint`

### Phase 3: Update Direct Usages

Find all places that manually build status messages and replace:

**Before:**
```powershell
Write-Host "  " -NoNewline
Write-Host "[" -NoNewline -ForegroundColor DarkGray
Write-Host "!" -NoNewline -ForegroundColor Yellow
# ... etc
```

**After:**
```powershell
Write-StatusMessage -Role "warning" -Message "Optional tool missing"
```

### Phase 4: Testing
- [ ] Test with `$global:OhMyPwsh_UseNerdFonts = $false` (Unicode)
- [ ] Test with `$global:OhMyPwsh_UseNerdFonts = $true` (NF)
- [ ] Verify colors:
  - Brackets: DarkGray
  - Icons: Role colors
  - Text: White
- [ ] Test all 6 roles (success, warning, error, info, tip, question)

### Phase 5: Documentation
- [ ] Update `docs/ARCHITECTURE.md`
- [ ] Add examples to `docs/LOGGING-SYSTEM.md`
- [ ] Update `CLAUDE.md` if needed

## Success Criteria

- [ ] `Write-StatusMessage` works for all roles
- [ ] Colors are correct (brackets gray, icon colored, text white)
- [ ] Works in both Unicode and NF modes
- [ ] All existing helpers use `Write-StatusMessage`
- [ ] No more manual `Write-Host` chains for status messages
- [ ] Profile loads without errors

## Dependencies

- ✅ Task #002 (Icon Fallback System) - DONE
- Blocks: Task #001 (Logging System) - builds on this

## Notes

### Why Not Merge Into Write-Log?

Task #001 (Logging System) is more complex:
- Message composition with styled segments
- Multiple output formats
- Verbosity levels
- etc.

`Write-StatusMessage` is:
- **Simpler** - single purpose
- **Needed now** - existing code needs it
- **Foundation** - Write-Log will use it internally

### Future: Write-Log Integration

Later, `Write-Log` will use `Write-StatusMessage` internally:

```powershell
function Write-Log {
    param([string]$Level, $Message)

    if ($Message -is [string]) {
        # Simple message - delegate to Write-StatusMessage
        Write-StatusMessage -Role $Level -Message $Message
    } else {
        # Complex message with styled segments
        # ... handle separately
    }
}
```

## Related Files

- `settings/icons.ps1` - Icon system
- `modules/logger.ps1` - Current helpers (to update)
- `profile.ps1` - Module loading order
- `test-icons.ps1` - Testing (can add Write-StatusMessage tests)
