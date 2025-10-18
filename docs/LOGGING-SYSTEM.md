# Logging System Specification

## Overview

Universal, extensible logging system for oh-my-pwsh profile status messages.

## Design Goals

1. **Single Responsibility**: One function (`Write-Log`) handles ALL output
2. **Composability**: Higher-level helpers compose `Write-Log` with specific patterns
3. **Flexibility**: Support any message format without code duplication
4. **Extensibility**: Easy to add new log types without modifying core
5. **Future-proof**: Support icon fallbacks, themes, verbosity levels

## Core Architecture

### Base Layer: `Write-Log`

**Single universal function** that ALL logging goes through:

```powershell
Write-Log -Level <level> -Message <text> [options]
```

**Parameters:**
- `Level` (required): success | warning | error | info | custom
- `Message` (required): Main message text (can be array/splatted)
- `Icon` (optional): Override default icon for level
- `NoIndent` (optional): Skip 2-space indent
- `NoNewline` (optional): Don't add newline at end

**Behavior:**
```
  [icon] message text
```

### Message Composition Layer

Build complex messages by composing text segments:

```powershell
# Simple message
Write-Log -Level success -Message "bat (enhanced cat)"

# Composed message (array of text segments with styles)
Write-Log -Level warning -Message @(
    @{Text = "install "; Color = "White"}
    @{Text = "``bat``"; Color = "White"}
    @{Text = " for "; Color = "White"}
    @{Text = "improved cat"; Color = "White"}
    @{Text = ": "; Color = "White"}
    @{Text = "scoop install bat"; Color = "DarkGray"}
)
```

### Helper Layer: Semantic Convenience Functions

Domain-specific helpers that compose `Write-Log`:

```powershell
# Tool status (existing use case)
Write-ToolStatus -Name "bat" -Installed $true -Description "enhanced cat"
Write-ToolStatus -Name "eza" -Installed $false -Description "modern ls" -InstallCommand "scoop install eza"

# Module status
Write-ModuleStatus -Name "PSFzf" -Loaded $true -Description "Ctrl+R, Ctrl+T"

# Custom install hints (flexible level)
Write-InstallHint -Tool "fzf" -Description "fuzzy finder" -Command "winget install fzf" -Level warning
Write-InstallHint -Tool "nerd-fonts" -Description "better icons" -Command "scoop install FiraCode-NF" -Level info

# Load time
Write-ProfileLoadTime -Milliseconds 1234

# Feature announcement
Write-FeatureTip -Feature "Ctrl+R" -Description "Search command history with fzf"
```

## Message Types & Use Cases

### 1. Success (Green ✓)

**When:** Feature loaded/installed successfully
```
  [✓] bat (enhanced cat)
  [✓] PSFzf (Ctrl+R, Ctrl+T)
```

### 2. Warning (Yellow !)

**When:** Optional feature missing, user should know about it
```
  [!] install `eza` for modern ls: scoop install eza
  [!] config.ps1 not found, using defaults
```

### 3. Error (Red �)

**When:** Critical failure that breaks functionality
```
  [�] Failed to load module: PowerShell 7+ required
  [�] Git not found in PATH
```

### 4. Info (Cyan i)

**When:** Informational, non-actionable message
```
  [i] Profile loaded in 1234ms
  [i] Tip: Type 'help' to see available commands
```

### 5. Custom Levels

**When:** Special contexts (help tips, feature highlights, etc.)
```
  [💡] Press Ctrl+R to search command history
  [🚀] New feature: z command for smart directory jumping
```

## Implementation Plan

### Phase 1: Core `Write-Log` Function

```powershell
function Write-Log {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('success', 'warning', 'error', 'info')]
        [string]$Level,

        [Parameter(Mandatory, ValueFromRemainingArguments)]
        $Message,  # Can be string or array of styled segments

        [string]$Icon = "",  # Optional override
        [switch]$NoIndent,
        [switch]$NoNewline
    )

    # Get icon and color for level
    $iconInfo = Get-LogIcon -Level $Level -CustomIcon $Icon

    # Build output
    $indent = if ($NoIndent) { "" } else { "  " }

    Write-Host $indent -NoNewline
    Write-Host "[" -NoNewline -ForegroundColor DarkGray
    Write-Host $iconInfo.Icon -NoNewline -ForegroundColor $iconInfo.Color
    Write-Host "]" -NoNewline -ForegroundColor DarkGray
    Write-Host " " -NoNewline

    # Render message (simple string or styled segments)
    if ($Message -is [string]) {
        Write-Host $Message -NoNewline -ForegroundColor White
    } else {
        # Array of styled segments: @{Text="foo"; Color="White"}
        foreach ($segment in $Message) {
            Write-Host $segment.Text -NoNewline -ForegroundColor $segment.Color
        }
    }

    if (-not $NoNewline) {
        Write-Host ""
    }
}
```

### Phase 2: Icon System with Fallbacks

```powershell
function Get-LogIcon {
    param(
        [string]$Level,
        [string]$CustomIcon = ""
    )

    if ($CustomIcon) {
        return @{ Icon = $CustomIcon; Color = "White" }
    }

    # Auto-detect Nerd Font support (future enhancement)
    $hasNerdFont = Test-NerdFontSupport

    $icons = @{
        success = @{
            NerdFont = "" # U+F00C
            Fallback = "✓"
            Color = "Green"
        }
        warning = @{
            NerdFont = "" # U+F0205
            Fallback = "!"
            Color = "Yellow"
        }
        error = @{
            NerdFont = "" # U+F467
            Fallback = "✗"
            Color = "Red"
        }
        info = @{
            NerdFont = "" # U+F129
            Fallback = "i"
            Color = "Cyan"
        }
    }

    $levelIcons = $icons[$Level]
    $icon = if ($hasNerdFont) { $levelIcons.NerdFont } else { $levelIcons.Fallback }

    return @{
        Icon = $icon
        Color = $levelIcons.Color
    }
}
```

### Phase 3: Helper Functions

All helpers compose `Write-Log`:

```powershell
function Write-InstallHint {
    param(
        [Parameter(Mandatory)]
        [string]$Tool,

        [string]$Description = "",

        [Parameter(Mandatory)]
        [string]$Command,

        [ValidateSet('info', 'warning')]
        [string]$Level = 'warning'  # Flexible level!
    )

    # Build message segments
    $segments = @(
        @{Text = "install "; Color = "White"}
        @{Text = "``$Tool``"; Color = "White"}
    )

    if ($Description) {
        $segments += @(
            @{Text = " for "; Color = "White"}
            @{Text = $Description; Color = "White"}
        )
    }

    $segments += @(
        @{Text = ": "; Color = "White"}
        @{Text = $Command; Color = "DarkGray"}
    )

    Write-Log -Level $Level -Message $segments
}
```

## Migration Strategy

### Step 1: Implement `Write-Log` and `Get-LogIcon`

### Step 2: Refactor helpers to use `Write-Log`

**Before:**
```powershell
Write-Host "[" -NoNewline -ForegroundColor DarkGray
Write-Host "!" -NoNewline -ForegroundColor Yellow
Write-Host "]" -NoNewline -ForegroundColor DarkGray
Write-Host " install " -NoNewline -ForegroundColor White
# ... 10 more lines
```

**After:**
```powershell
Write-Log -Level warning -Message $segments
```

### Step 3: Add new helper functions as needed

### Step 4: Add icon fallback detection (future)

### Step 5: Add theme support (future)

## Future Enhancements

### Verbosity Levels
```powershell
$global:OhMyPwsh_LogLevel = "normal" # quiet | normal | verbose | debug
```

### Themes
```powershell
$global:OhMyPwsh_Theme = "dark" # dark | light | custom
```

### Custom Icons
```powershell
$global:OhMyPwsh_CustomIcons = @{
    success = "✅"
    warning = "⚠️"
    error = "❌"
}
```

## Benefits

1. **DRY**: No more duplicated Write-Host chains
2. **Testable**: Single function to test, not scattered logic
3. **Maintainable**: Change format in one place
4. **Extensible**: Add new message types without touching core
5. **Themeable**: Easy to add themes, icon packs, etc.
6. **Future-proof**: Ready for icon fallbacks, verbosity, etc.
