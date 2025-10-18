# 001 - Logging System Architecture

**Status:** `active`
**Priority:** P0 (highest)

## Goal

Create reusable, composable logging system that eliminates code duplication and provides consistent output formatting.

## Problem

Current code has:
- Duplicated `Write-Host` chains across multiple files
- No central control over message formatting
- Hard to test
- Hard to add features (themes, verbosity, icon fallbacks)

**Example of current duplication:**
```powershell
# Repeated in multiple places
Write-Host "[" -NoNewline -ForegroundColor DarkGray
Write-Host "!" -NoNewline -ForegroundColor Yellow
Write-Host "]" -NoNewline -ForegroundColor DarkGray
Write-Host " install " -NoNewline -ForegroundColor White
# ... etc
```

## Solution Architecture

### 3-Layer Design

```
┌─────────────────────────────────────┐
│  LAYER 3: Helpers (semantic)        │
│  Write-ToolStatus, Write-InstallHint│
│  "WHAT to say"                      │
├─────────────────────────────────────┤
│  LAYER 2: Message Composer          │
│  Build styled text segments         │
│  "HOW to structure"                 │
├─────────────────────────────────────┤
│  LAYER 1: Write-Log (core)          │
│  Single output function             │
│  "HOW to render"                    │
└─────────────────────────────────────┘
```

### Layer 1: Core `Write-Log`

**Single universal function:**

```powershell
function Write-Log {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('success', 'warning', 'error', 'info')]
        [string]$Level,

        [Parameter(Mandatory)]
        $Message,  # String or array of styled segments

        [switch]$NoIndent
    )

    # Get icon using icon system
    $icon = Get-FallbackIcon -Role $Level
    $color = Get-LevelColor -Level $Level

    # Render message
    $indent = if ($NoIndent) { "" } else { "  " }

    Write-Host $indent -NoNewline
    Write-Host "[" -NoNewline -ForegroundColor DarkGray
    Write-Host $icon -NoNewline -ForegroundColor $color
    Write-Host "] " -NoNewline -ForegroundColor DarkGray

    # Handle string or styled segments
    if ($Message -is [string]) {
        Write-Host $Message -ForegroundColor White
    } else {
        # Array of @{Text="..."; Color="..."}
        foreach ($segment in $Message) {
            Write-Host $segment.Text -NoNewline -ForegroundColor $segment.Color
        }
        Write-Host ""  # Newline
    }
}
```

### Layer 2: Message Composer

Helper to build styled message segments:

```powershell
function New-MessageSegment {
    param(
        [string]$Text,
        [string]$Color = "White"
    )
    return @{ Text = $Text; Color = $Color }
}

# Or use splatting:
$segments = @(
    @{Text = "install "; Color = "White"}
    @{Text = "``bat``"; Color = "White"}
    @{Text = " for "; Color = "White"}
    @{Text = "improved cat"; Color = "White"}
    @{Text = ": "; Color = "White"}
    @{Text = "scoop install bat"; Color = "DarkGray"}
)
```

### Layer 3: Semantic Helpers

```powershell
function Write-InstallHint {
    param(
        [Parameter(Mandatory)]
        [string]$Tool,

        [string]$Description = "",

        [Parameter(Mandatory)]
        [string]$Command,

        [ValidateSet('info', 'warning')]
        [string]$Level = 'warning'
    )

    $segments = @(
        @{Text = "install "; Color = "White"}
        @{Text = "``$Tool``"; Color = "White"}
    )

    if ($Description) {
        $segments += @{Text = " for "; Color = "White"}
        $segments += @{Text = $Description; Color = "White"}
    }

    $segments += @{Text = ": "; Color = "White"}
    $segments += @{Text = $Command; Color = "DarkGray"}

    Write-Log -Level $Level -Message $segments
}
```

## Implementation Plan

### Phase 1: Core Infrastructure
- [ ] Create `modules/logging.ps1` (rename from `logger.ps1`)
- [ ] Implement `Write-Log` function
- [ ] Implement `Get-LevelColor` helper
- [ ] Ensure `Write-Log` uses `Get-FallbackIcon` (from task #002)

### Phase 2: Refactor Existing Code
- [ ] Refactor `Write-InstallHint` to use `Write-Log`
- [ ] Refactor `Write-ToolStatus` to use `Write-Log`
- [ ] Refactor `Write-ModuleStatus` to use `Write-Log`
- [ ] Update `profile.ps1` to use helpers (remove manual Write-Host chains)

### Phase 3: Testing
- [ ] Test all log levels
- [ ] Test with/without descriptions
- [ ] Test message segment composition
- [ ] Verify icon integration works

### Phase 4: Documentation
- [ ] Update `./docs/LOGGING-SYSTEM.md` with final implementation
- [ ] Add usage examples
- [ ] Document for contributors

## Dependencies

- Task #002 (Icon Fallback System) - `Write-Log` must use `Get-FallbackIcon`

## Success Criteria

- [ ] Zero `Write-Host` chains outside of `Write-Log`
- [ ] All output goes through `Write-Log` or helpers
- [ ] Code is DRY and testable
- [ ] Easy to add new message types

## Files to Modify

- `modules/logger.ps1` → `modules/logging.ps1`
- `modules/enhanced-tools.ps1`
- `profile.ps1`
- `docs/LOGGING-SYSTEM.md`
