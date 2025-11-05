# 2025-11-05: Installation Process Improvements

## Context
User requested setup of oh-my-pwsh and oh-my-stats. During the process, identified and fixed several installation issues.

## Work Done

### 1. Initial Setup ✅
- Verified PowerShell profile location: `C:\Users\zentala\Documents\PowerShell\Microsoft.PowerShell_profile.ps1`
- Existing profile contained only Chocolatey configuration
- No package managers installed (scoop missing, winget and chocolatey available)

### 2. oh-my-stats Installation ✅
- Cloned oh-my-stats from GitHub: `https://github.com/zentala/oh-my-stats.git`
- Location: `C:\code\oh-my-stats`
- Integrated successfully with profile

### 3. Dependencies Installation ✅
Ran `scripts/install-dependencies.ps1`:
- **Newly installed:**
  - Oh My Posh (v27.5.0)
  - fzf (via winget)
  - zoxide (v0.9.8)
  - posh-git (PowerShell module)
  - Terminal-Icons (PowerShell module)
  - PSFzf (PowerShell module)
- **Already installed:**
  - gsudo
  - PSReadLine

### 4. Profile Configuration ✅
- Created backup of existing profile
- Updated profile to load oh-my-pwsh
- Preserved existing Chocolatey configuration
- Created `config.ps1` from `config.example.ps1` with default settings

### 5. Issues Found & Fixed

#### Issue #1: Oh My Posh Theme Not Found
**Problem:** Profile referenced non-existent theme `quick-term.omp.json`
- Error: `[!] Oh My Posh [ theme not found ]`
- `$env:POSH_THEMES_PATH` not set before Oh My Posh init

**Solution:** Modified `profile.ps1` (lines 117-129)
```powershell
# Try user's custom theme first, then fallback to standard theme
$omp_config = "$ProfileRoot\themes\quick-term.omp.json"
if (-not (Test-Path $omp_config)) {
    # Use standard paradox theme from Oh My Posh
    $omp_config = "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/paradox.omp.json"
}
```

**Benefits:**
- Profile works immediately without custom theme
- Users can create custom theme later in `themes/quick-term.omp.json`
- Graceful fallback to standard theme

#### Issue #2: fzf and zoxide Not Detected After Install
**Problem:** Tools installed but not in PATH in same session
- Warnings shown: `[!] install fzf/zoxide` even after successful installation
- winget installs require terminal restart to update PATH

**Solution:** Not a code fix - documented requirement
- Added clear instructions to restart terminal
- PATH updates only apply to new sessions

### 6. One-Click Installation Script ✅
Created `scripts/Install-OhMyPwsh.ps1`:
- Complete automation of entire setup process
- Steps:
  1. Clone oh-my-stats (if needed)
  2. Install dependencies (via `install-dependencies.ps1`)
  3. Configure PowerShell profile (with backup)
  4. Create config.ps1 (if needed)
- Parameters:
  - `-SkipDependencies`: Skip dependency installation
  - `-SkipProfile`: Skip profile configuration
- Clear next steps and warnings about terminal restart

## Files Modified

1. **profile.ps1** (line 117-129)
   - Fixed Oh My Posh theme loading with fallback

2. **New files created:**
   - `config.ps1` - User configuration
   - `scripts/Install-OhMyPwsh.ps1` - One-click installer
   - `.claude/runbook/2025-11-05_installation-improvements.md` - This file

3. **User profile updated:**
   - `C:\Users\zentala\Documents\PowerShell\Microsoft.PowerShell_profile.ps1`
   - Backup created: `Microsoft.PowerShell_profile.ps1.backup-TIMESTAMP`

## Testing

### Test 1: Profile Loading ✅
```powershell
pwsh -Command 'Start-Sleep 2'
```
**Result:**
- oh-my-stats displays system info
- Oh My Posh loads successfully (no theme error)
- All modules load without errors
- Warnings shown for missing optional tools (expected)

### Test 2: Enhanced Tools Detection ⚠️
**Expected warnings (normal after fresh install):**
- fzf - installed but needs terminal restart
- zoxide - installed but needs terminal restart
- bat, eza, ripgrep, fd, delta - not installed (scoop needed)

## Recommendations for Future Improvements

### 1. Enhanced Tools Installation Helper
Create function `Install-EnhancedTools`:
```powershell
function Install-EnhancedTools {
    if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
        Write-Host "Installing scoop..."
        Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
        irm get.scoop.sh | iex
    }
    scoop install bat eza ripgrep fd delta
}
```

### 2. Smarter Package Manager Detection
Currently hardcoded suggestions for scoop/winget. Could improve:
- Check which package managers are available
- Suggest appropriate install command based on what's installed
- Detect if tool was installed via winget but PATH not refreshed

### 3. Post-Install Verification
Add to `Install-OhMyPwsh.ps1`:
- Check if PATH refresh is needed
- Verify all expected tools are available
- Report what requires terminal restart vs what's missing

### 4. Theme Selection During Install
Ask user during installation:
- "Which Oh My Posh theme do you want?"
- Show popular options (paradox, agnoster, jandedobbeleer)
- Download selected theme to `themes/quick-term.omp.json`

## User Instructions for Next Steps

**Provided to user:**

1. **Restart terminal** (REQUIRED)
   - fzf and zoxide will work after restart

2. **(Optional) Install enhanced tools:**
   ```powershell
   # Install scoop
   Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
   irm get.scoop.sh | iex

   # Install enhanced tools
   scoop install bat eza ripgrep fd delta
   ```

3. **Customize configuration:**
   ```powershell
   code C:\code\oh-my-pwsh\config.ps1
   ```

4. **Type `help`** to see available commands

## Session Summary

**Time invested:** ~30-40 minutes
**Complexity:** Medium (required debugging and fixes)
**Outcome:** ✅ Fully working installation

**User experience improvements:**
- Fixed theme loading bug
- Created one-click installer
- Clear documentation of requirements
- Improved fallback behavior
