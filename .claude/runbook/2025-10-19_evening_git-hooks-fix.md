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

### 3. Fixed Install-GitHooks.ps1 ✅

**Problem:** Script was copying only one file (wrapper)

**Solution:** Created dedicated PowerShell script to update the file
- Created `/tmp/fix-install-hooks.ps1` with line-by-line replacement logic
- Avoided Edit tool issues by using separate script
- Updated all variable names: `$sourceHook` → `$sourceHookWrapper`, `$targetHookPs1`, etc.
- Added verification for both files
- Updated uninstall message to use wildcard: `pre-commit*`

**Testing:**
```bash
$ rm .git/hooks/pre-commit*
$ pwsh -File scripts/Install-GitHooks.ps1
✅ Git hooks installed successfully!

$ ls .git/hooks/pre-commit*
pre-commit      # wrapper
pre-commit.ps1  # PowerShell script
```

**Result:** ✅ Script now correctly installs both files

## Files Modified

- [.github/hooks/pre-commit](../../.github/hooks/pre-commit) - NEW shell wrapper
- [.github/hooks/pre-commit.ps1](../../.github/hooks/pre-commit.ps1) - PowerShell script
- [scripts/Install-GitHooks.ps1](../../scripts/Install-GitHooks.ps1) - FIXED to copy both files
- [.git/hooks/pre-commit](../../.git/hooks/pre-commit) - Installed wrapper
- [.git/hooks/pre-commit.ps1](../../.git/hooks/pre-commit.ps1) - Installed script

## Commits

- `dd47ec0` - fix(git-hooks): Windows PowerShell compatibility for pre-commit hook
- `5db18e9` - docs(todo): moved 006-contributing-docs.md to done
- `f4761e6` - chore(claude): settings.local.json
- `6b3ceb5` - docs(runbook): Document git hooks fix session
- `a05d904` - fix(git-hooks): Update Install-GitHooks.ps1 to copy both hook files ⭐

## Decisions Made

1. **Two-file approach** (wrapper + .ps1 script)
   - Shell wrapper compatible with Git Bash
   - PowerShell script has required extension
   - Clean separation of concerns

2. **Install-GitHooks.ps1 fix approach**
   - Edit tool had race conditions/file locks
   - Created separate PowerShell script for transformation
   - Line-by-line replacement with clear logic
   - Tested installation before committing

## Tech Notes

**Why Git Bash doesn't handle PowerShell shebangs:**
- Git Bash on Windows doesn't properly interpret `#!/usr/bin/env pwsh`
- When git invokes hook, it tries to execute with sh/bash
- PowerShell invoked via bash requires proper extension for `-File`

**Solution pattern for other PowerShell hooks:**
```
hook (no extension) → sh wrapper → calls hook.ps1
```

## Lessons Learned

1. **Edit tool limitations**
   - Can fail with file watchers/locks on Windows
   - Workaround: Create separate PowerShell script for complex transformations
   - Line-by-line processing more reliable than regex replace

2. **Testing is critical**
   - Deleted hooks and ran install script to verify
   - Both files correctly installed
   - Hook execution confirmed working

## Next Steps

- [x] Update Install-GitHooks.ps1 ✅ (fixed via `/tmp/fix-install-hooks.ps1`)
- [ ] Test hook on another machine to verify portability

---

**Status:** ✅ COMPLETE - Hook system fully working, install script fixed
