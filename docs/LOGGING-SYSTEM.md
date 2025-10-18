# Logging System Specification

## Overview

Universal, extensible logging system for oh-my-pwsh profile status messages.

## Design Goals

1. **Single Responsibility**: One function (`Write-StatusMessage`) handles ALL output
2. **Composability**: Higher-level helpers compose `Write-StatusMessage` with specific patterns
3. **Flexibility**: Support any message format without code duplication
4. **Extensibility**: Easy to add new log types without modifying core
5. **Future-proof**: Support icon fallbacks, themes, verbosity levels

## Core Architecture

### Base Layer: `Write-StatusMessage`

**Single universal function** that ALL logging goes through:

```powershell
Write-StatusMessage -Role <role> -Message <text> [options]
```

**Location:** `modules/status-output.ps1`

**Parameters:**
- `Role` (required): success | warning | error | info | tip | question
- `Message` (required): String OR array of styled segments
- `NoIndent` (optional): Skip 2-space indent

**Output Format:**
- **Unicode mode** (default): `[icon] message`
- **Nerd Font mode**: `icon message` (no brackets)

**Color Control:**
- Brackets: DarkGray
- Icon: Role-specific color (Green/Yellow/Red/Cyan/Blue/Magenta)
- Text: White (or custom colors with segments)

### Message Composition Layer

Build complex messages by composing text segments:

```powershell
# Simple message (string)
Write-StatusMessage -Role "success" -Message "bat (enhanced cat)"

# Styled segments (array of hashtables)
$segments = @(
    @{Text = "install "; Color = "White"}
    @{Text = "bat"; Color = "Yellow"}
    @{Text = " for "; Color = "White"}
    @{Text = "improved cat"; Color = "White"}
    @{Text = ": "; Color = "White"}
    @{Text = "scoop install bat"; Color = "DarkGray"}
)
Write-StatusMessage -Role "warning" -Message $segments
```

### Helper Layer: Semantic Convenience Functions

**Location:** `modules/logger.ps1`

Domain-specific helpers that compose `Write-StatusMessage`:

```powershell
# Tool status - checks if tool is installed
Write-ToolStatus -Name "bat" -Installed $true -Description "enhanced cat"
Write-ToolStatus -Name "eza" -Installed $false -Description "modern ls" -ScoopPackage "eza"

# Module status - checks if PowerShell module is loaded
Write-ModuleStatus -Name "PSFzf" -Loaded $true -Description "Ctrl+R, Ctrl+T"

# Install hint - shows install command for missing tools
Write-InstallHint -Tool "fzf" -Description "fuzzy finder" -InstallCommand "winget install fzf"

# Profile status - generic status message
Write-ProfileStatus -Level "success" -Primary "Configuration loaded"
Write-ProfileStatus -Level "warning" -Primary "Config not found" -Secondary "using defaults"
```

**Implementation:**
All helpers internally call `Write-StatusMessage` with appropriate styling.

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

### 3. Error (Red x)

**When:** Critical failure that breaks functionality
```
  [x] Failed to load module: PowerShell 7+ required
  [x] Git not found in PATH
```

### 4. Info (Cyan i)

**When:** Informational, non-actionable message
```
  [i] Profile loaded in 1234ms
  [i] Configuration loaded
```

### 5. Tip (Blue ※)

**When:** Helpful hints or suggestions
```
  [※] Press Ctrl+R to search command history
  [※] Type 'help' to see available commands
```

### 6. Question (Magenta ?)

**When:** Prompting user for input or confirmation
```
  [?] Continue with installation?
  [?] Select configuration option
```

## Implementation Status

✅ **COMPLETED** - Logging system fully implemented!

### Implemented Components

#### 1. Core Functions
- **`Write-StatusMessage`** (modules/status-output.ps1)
  - Supports simple strings and styled segments
  - Automatic Nerd Font / Unicode detection
  - Granular color control

- **`Get-FallbackIcon`** (settings/icons.ps1)
  - Icon system with role-based lookup
  - Unicode default, Nerd Font experimental
  - Custom icon override support

#### 2. Helper Functions
- **`Write-InstallHint`** - Install hints with styled segments
- **`Write-ToolStatus`** - Tool availability status
- **`Write-ModuleStatus`** - PowerShell module status
- **`Write-ProfileStatus`** - Generic status messages

#### 3. Integration
- All profile status output goes through `Write-StatusMessage`
- No manual `Write-Host` chains in codebase
- DRY principle applied throughout

### Usage Examples

```powershell
# Simple success message
Write-StatusMessage -Role "success" -Message "Module loaded"

# Warning with styled segments
$segments = @(
    @{Text = "install "; Color = "White"}
    @{Text = "bat"; Color = "Yellow"}
    @{Text = ": "; Color = "White"}
    @{Text = "scoop install bat"; Color = "DarkGray"}
)
Write-StatusMessage -Role "warning" -Message $segments

# Using helpers
Write-InstallHint -Tool "fzf" -Description "fuzzy finder" -InstallCommand "winget install fzf"
Write-ModuleStatus -Name "PSFzf" -Loaded $true -Description "Ctrl+R, Ctrl+T"
```

## Future Enhancements

### Potential Features
- **Verbosity levels**: quiet | normal | verbose | debug
- **Themes**: dark | light | custom color schemes
- **Log file output**: Optional file logging
- **Timestamp support**: Add timestamps to messages
- **Custom icon packs**: User-defined icon sets

### Extension Points
The architecture supports easy extension through:
- New helper functions for specific use cases
- Custom message segment builders
- Theme system for color customization
- Icon override system (already implemented)

## Benefits

1. **DRY**: No duplicated Write-Host chains
2. **Testable**: Single function to test, not scattered logic
3. **Maintainable**: Change format in one place
4. **Extensible**: Add new message types without touching core
5. **Themeable**: Ready for themes and icon packs
6. **Composable**: Build complex messages from simple parts
7. **Backward compatible**: Simple strings still work
