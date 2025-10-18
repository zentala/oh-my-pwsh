# ADR-004: Git Hooks Optional

**Status:** Accepted
**Date:** 2025-10-18
**Deciders:** Paweł Żentała, Claude (Solution Architect)

## Context

Git hooks can automatically run tests before commits or pushes, catching issues early. However, mandatory hooks can frustrate developers, slow down workflows, and create friction. We need to balance early error detection with developer experience.

### Developer Pain Points
- Hooks can be slow (waiting 30s-2min before commit)
- May block quick WIP commits
- Can break workflow during rapid prototyping
- Hard to debug when hooks fail
- Different developers have different workflows

### Benefits of Hooks
- Catch errors before they reach CI
- Enforce standards automatically
- Save CI resources
- Faster feedback than waiting for CI

## Decision

**Git hooks are OPTIONAL and BYPASSABLE:**

1. **Pre-commit hook provided but not mandatory**
   - Located in `.github/hooks/pre-commit`
   - Must be manually installed by developer
   - Installation script: `scripts/Install-GitHooks.ps1`

2. **Hook runs fast unit tests only** (not full suite)
   - Target: < 30 seconds
   - Skip integration/E2E tests locally

3. **Hook can be bypassed** with `--no-verify`
   ```bash
   git commit --no-verify -m "WIP: quick save"
   ```

4. **CI is the ultimate quality gate**
   - CI runs ALL tests (unit + integration + E2E)
   - CI blocks merge if tests fail
   - No bypassing CI

## Consequences

### Positive ✅

- **Developer Friendly**: Not forced, respects workflows
- **Fast**: Only fast tests, < 30s
- **Flexible**: Can bypass for WIP commits
- **Gradual Adoption**: Developers can opt-in when ready
- **No Setup Friction**: Works without hooks installed
- **CI Remains Authoritative**: Can't bypass CI checks

### Negative ⚠️

- **Inconsistent**: Some devs use hooks, some don't
- **Later Failures**: Might fail in CI, not locally
- **Wasted CI Time**: CI catches what hooks could have caught
- **Manual Setup**: Devs must remember to install hooks

### Neutral ℹ️

- **Best Practice**: Recommend installation in docs
- **Culture**: Relies on team discipline

## Implementation

### Hook Installation (Optional)
```powershell
# scripts/Install-GitHooks.ps1

<#
.SYNOPSIS
    Install git hooks for oh-my-pwsh

.DESCRIPTION
    Copies pre-commit hook to .git/hooks/
    This is OPTIONAL - hooks can be bypassed with --no-verify

.EXAMPLE
    .\scripts\Install-GitHooks.ps1
#>

param(
    [switch]$Force
)

$hooksSource = Join-Path $PSScriptRoot "../.github/hooks"
$hooksTarget = Join-Path (git rev-parse --git-dir) "hooks"

# Check if hook already exists
$targetHook = Join-Path $hooksTarget "pre-commit"
if ((Test-Path $targetHook) -and -not $Force) {
    Write-Warning "Hook already exists. Use -Force to overwrite."
    exit 1
}

# Copy hook
Copy-Item "$hooksSource/pre-commit" $targetHook -Force

# Make executable (Linux/Mac)
if ($IsLinux -or $IsMacOS) {
    chmod +x $targetHook
}

Write-Host "✓ Git hooks installed" -ForegroundColor Green
Write-Host "  Pre-commit hook will run unit tests before each commit"
Write-Host "  Bypass with: git commit --no-verify"
```

### Pre-commit Hook
```bash
#!/usr/bin/env pwsh
# .github/hooks/pre-commit

# Run fast unit tests only
Write-Host "Running pre-commit tests..." -ForegroundColor Cyan

$result = & "$PSScriptRoot/../../scripts/Invoke-Tests.ps1" -Type Unit -Fast

if ($result.FailedCount -gt 0) {
    Write-Host "❌ Tests failed. Commit blocked." -ForegroundColor Red
    Write-Host "   Fix the tests or bypass with: git commit --no-verify"
    exit 1
}

Write-Host "✓ All tests passed" -ForegroundColor Green
exit 0
```

### Fast Test Mode
```powershell
# scripts/Invoke-Tests.ps1

param(
    [ValidateSet('Unit', 'Integration', 'E2E', 'All')]
    [string]$Type = 'All',

    [switch]$Fast  # Skip slow tests, parallel execution
)

if ($Fast) {
    # Only unit tests, parallel, no coverage
    $config.Run.Path = "tests/Unit"
    $config.Run.Parallel = $true
    $config.CodeCoverage.Enabled = $false
}
```

## Hook Workflow Examples

### Good Workflow (Using Hooks)
```bash
# 1. Make changes
vim modules/logger.ps1

# 2. Commit (hook runs automatically)
git commit -m "feat: add new helper"
# → Hook runs unit tests (~20s)
# → ✓ Tests pass, commit succeeds

# 3. Push (CI runs full suite)
git push
# → CI runs all tests (~3min)
# → ✓ All pass, merge allowed
```

### Bypass Workflow (WIP Commits)
```bash
# Quick save work-in-progress
git commit --no-verify -m "WIP: experimenting"
# → No hook, instant commit

# Later, before push
./scripts/Invoke-Tests.ps1
# → Run tests manually

git commit --amend -m "feat: add feature"
# → Hook runs this time
```

### CI Catches Issues
```bash
# Developer bypassed hook
git commit --no-verify -m "feat: broken code"
git push

# CI fails
# → PR blocked
# → Developer notified
# → Must fix and force-push
```

## Opt-In vs Opt-Out Analysis

| Approach | Setup | Adoption | Friction | Bypassing |
|----------|-------|----------|----------|-----------|
| **Opt-In** (our choice) | Manual install | Gradual | Low | Easy (just don't install) |
| **Opt-Out** | Auto-installed | Immediate | High | Needs --no-verify every time |
| **Mandatory** | Auto, no bypass | 100% | Very High | Impossible (bad DX) |

**Verdict**: Opt-in balances quality with developer experience.

## Alternatives Considered

### 1. Mandatory Pre-commit Hook
- **Pros**: 100% adoption, catches all issues early
- **Cons**: Frustrates developers, slows workflow, reduces velocity
- **Verdict**: ❌ Too restrictive

### 2. No Git Hooks at All
- **Pros**: Zero friction, maximum flexibility
- **Cons**: More CI failures, wasted time
- **Verdict**: ❌ Misses easy wins

### 3. Pre-push Hook Instead
- **Pros**: Less frequent, can accumulate commits first
- **Cons**: Runs less often, later feedback
- **Verdict**: ⚠️ Alternative, but pre-commit is better

### 4. Commit-msg Hook (Conventional Commits)
- **Pros**: Enforces commit message format
- **Cons**: Different concern, orthogonal to testing
- **Verdict**: 💡 Separate ADR if needed

## Developer Education

### Documentation Updates
```markdown
## Running Tests

### Quick Check (Recommended)
pwsh scripts/Invoke-Tests.ps1 -Type Unit

### Full Suite (Before PR)
pwsh scripts/Invoke-Tests.ps1

### Install Git Hooks (Optional)
pwsh scripts/Install-GitHooks.ps1

This runs unit tests automatically before each commit.
Bypass with: git commit --no-verify
```

### Onboarding Checklist
- [ ] Clone repository
- [ ] Run `Install-TestDeps.ps1`
- [ ] Run tests manually once
- [ ] (Optional) Install git hooks

## Related

### Tasks
- [005-testing-infrastructure.md](../todo/005-testing-infrastructure.md) - Includes hook implementation

### Documentation
- [TESTING-STRATEGY.md](../docs/TESTING-STRATEGY.md) - Overall strategy
- [README.md](../README.md) - User-facing docs

### Other ADRs
- [ADR-001](./001-pester-test-framework.md) - Test framework used by hooks
- [ADR-002](./002-test-isolation-strategy.md) - Why only unit tests in hook

## References

- [Git Hooks Documentation](https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks)
- [Husky (JS equivalent)](https://typicode.github.io/husky/) - Inspiration for opt-in approach
- [Pre-commit Framework](https://pre-commit.com/) - Alternative tool
