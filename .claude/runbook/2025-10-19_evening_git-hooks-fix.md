# 2025-10-19 Evening - Git Hook PowerShell Extension Fix

**Parent:** [2025-10-19.md](./2025-10-19.md)

## Goal: Fix pre-commit hook failing on Windows

**Problem:**
```
git commit -m "..."
Processing -File '.git/hooks/pre-commit' failed because the file
does not have a '.ps1' extension.
```

**Root cause:**
- `.github/hooks/pre-commit` was PowerShell script without `.ps1` extension
- Git on Windows uses Git Bash
- PowerShell's `-File` parameter requires `.ps1` extension
- Shebang `#!/usr/bin/env pwsh` doesn't work properly in Git Bash on Windows

## Work Done

### 1. Created Two-File Hook System

**Solution:** Split into wrapper + PowerShell script

**File 1: `.github/hooks/pre-commit`** (shell wrapper)
```sh
#!/bin/sh
# Calls the PowerShell script
HOOK_DIR="$(cd "$(dirname "$0")" && pwd)"
pwsh.exe -NoProfile -ExecutionPolicy Bypass -File "$HOOK_DIR/pre-commit.ps1"
exit $?
```

**File 2: `.github/hooks/pre-commit.ps1`** (PowerShell logic)
- Contains all test execution logic
- Has `.ps1` extension (required by PowerShell `-File`)

### 2. Verified Hook Works

**Test:**
```bash
$ git commit -m "test"
🧪 Running pre-commit tests...
   (bypass with: git commit --no-verify)
✅ Tests executed successfully
```

### 3. Known Issue: Install-GitHooks.ps1

**Status:** ⚠️ Script still copies only one file

**Current code:**
```powershell
Copy-Item -Path $sourceHook -Destination $targetHook -Force
```

**Needed:**
```powershell
Copy-Item -Path $sourceHookWrapper -Destination $targetHookWrapper -Force
Copy-Item -Path $sourceHookPs1 -Destination $targetHookPs1 -Force
```

**Why not fixed:**
- File kept getting modified during edits (race condition with file watcher?)
- Tried multiple approaches (Edit tool, PowerShell Replace, sed, heredoc)
- All failed due to escaping issues or file locks

**Workaround:**
- Hooks manually installed in `.git/hooks/` → **working correctly**
- Future developers: Copy both files manually or update Install-GitHooks.ps1

## Files Modified

- [.github/hooks/pre-commit](../../.github/hooks/pre-commit) - NEW shell wrapper
- [.github/hooks/pre-commit.ps1](../../.github/hooks/pre-commit.ps1) - PowerShell script
- [.git/hooks/pre-commit](../../.git/hooks/pre-commit) - Installed wrapper
- [.git/hooks/pre-commit.ps1](../../.git/hooks/pre-commit.ps1) - Installed script

## Commits

- `dd47ec0` - fix(git-hooks): Windows PowerShell compatibility for pre-commit hook
- `5db18e9` - docs(todo): moved 006-contributing-docs.md to done
- `f4761e6` - chore(claude): settings.local.json

## Decisions Made

1. **Two-file approach** (wrapper + .ps1 script)
   - Shell wrapper compatible with Git Bash
   - PowerShell script has required extension
   - Clean separation of concerns

2. **Install-GitHooks.ps1 as Known Issue**
   - Hook system works (manually installed)
   - Script update blocked by tooling issues
   - Documented for future fix

3. **Manual installation acceptable**
   - Project in alpha, solo dev
   - Hooks optional (ADR-004)
   - Can be bypassed with `--no-verify`

## Tech Notes

**Why Git Bash doesn't handle PowerShell shebangs:**
- Git Bash on Windows doesn't properly interpret `#!/usr/bin/env pwsh`
- When git invokes hook, it tries to execute with sh/bash
- PowerShell invoked via bash requires proper extension for `-File`

**Solution pattern for other PowerShell hooks:**
```
hook (no extension) → sh wrapper → calls hook.ps1
```

## Next Steps

- [ ] Update Install-GitHooks.ps1 when tooling allows (manual editing?)
- [ ] Test hook on another machine to verify portability
- [ ] Consider adding to CONTRIBUTING.md: "Manual hook installation"

---

**Status:** ✅ Hook system working - Install script needs future update
