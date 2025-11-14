# 013 - Code Quality: Fix Linter Warnings

**Status:** `active`
**Priority:** P2 (improvement - code quality)
**Complexity:** Medium (2-3 hours)
**Type:** Code Quality / Refactoring

---

## Problem Statement

### Current State
PSScriptAnalyzer reports **53 warnings** across the codebase:

```
Total issues: 53
  Errors: 0
  Warnings: 53
  Information: 0
```

**Breakdown by Category:**
- **26 warnings:** `PSUseConsistentWhitespace` - spacing/formatting
- **10 warnings:** `PSPlaceCloseBrace` - brace placement
- **2 warnings:** `PSUseApprovedVerbs` - `ssh-keygen` function name
- **2 warnings:** `PSUseDeclaredVarsMoreThanAssignments` - unused variables
- **1 warning:** `PSReviewUnusedParameter` - unused parameter
- **12 warnings:** Other style/consistency issues

**Impact:**
- ⚠️ Inconsistent code style
- ⚠️ Harder to read and maintain
- ⚠️ May hide real issues
- ✅ Zero functional bugs (all are style warnings)

---

## Business Value

### Why Fix These?

1. **Code Maintainability** - Consistent style is easier to read and modify
2. **Professionalism** - Clean code signals quality to contributors
3. **Best Practices** - Follow PowerShell community standards
4. **Future-Proofing** - Easier to enforce stricter rules later
5. **Developer Experience** - Cleaner diffs, easier reviews

### Why Now?
- Linter just integrated (good timing)
- Warnings are fresh (not accumulated tech debt)
- Low risk (style-only changes)
- Can be done incrementally

---

## Solution Architecture

### Approach
**Incremental cleanup** - Fix high-frequency issues first, one category at a time.

### Priority Order
1. **P0 (Quick Wins):** Unused variables/parameters (2 warnings)
2. **P1 (High Impact):** Whitespace consistency (26 warnings)
3. **P2 (Medium Impact):** Brace placement (10 warnings)
4. **P3 (Low Priority):** Function naming (2 warnings) - may skip

---

## Implementation Plan

### Phase 1: Unused Variables/Parameters (P0)

**Effort:** 15 minutes
**Files Affected:** 3

#### 1.1 Fix Unused Variables

**File:** [`profile.ps1:62`](../profile.ps1)
```powershell
# Issue: Variable 'OhMyStatsFound' assigned but never used
# Fix: Either use it or remove it

# Option A: Remove if truly unused
# Delete line 62

# Option B: Use it in conditional logic
if ($OhMyStatsFound) {
    # ... oh-my-stats specific setup
}
```

**File:** [`scripts/Invoke-Tests.ps1:178`](../scripts/Invoke-Tests.ps1)
```powershell
# Issue: Variable 'changeType' assigned but never used
$changeType = $Event.SourceEventArgs.ChangeType

# Fix: Remove if not needed for logging
$path = $Event.SourceEventArgs.FullPath
# Remove: $changeType = ...
```

#### 1.2 Fix Unused Parameters

**File:** [`modules/nerd-fonts.ps1:137`](../modules/nerd-fonts.ps1)
```powershell
# Issue: Parameter 'Silent' declared but not used
param([switch]$Silent)

# Fix: Either use it or remove it
if (-not $Silent) {
    Write-Host "Installing Nerd Font..."
}
```

**Acceptance Criteria:**
- [ ] No `PSUseDeclaredVarsMoreThanAssignments` warnings
- [ ] No `PSReviewUnusedParameter` warnings
- [ ] Functionality unchanged
- [ ] Tests pass

---

### Phase 2: Whitespace Consistency (P1)

**Effort:** 1-2 hours
**Files Affected:** 6
**Warnings:** 26

#### 2.1 Auto-Fix Attempt
```powershell
# Try auto-fix first
./scripts/Invoke-Linter.ps1 -Fix

# Review changes
git diff

# If good, commit. If not, manual fix.
```

#### 2.2 Manual Fix Guidelines

**Issue:** `PSUseConsistentWhitespace`

**Rule:** Space before and after binary and assignment operators

```powershell
# Bad
$icon="✓"
$color= "Green"

# Good
$icon = "✓"
$color = "Green"
```

**Files to fix:**
- [`settings/icons.ps1`](../settings/icons.ps1) - 12 warnings
- [`modules/linux-compat.ps1`](../modules/linux-compat.ps1) - 10 warnings
- [`modules/logger.ps1`](../modules/logger.ps1) - 6 warnings
- [`scripts/Install-PSScriptAnalyzer.ps1`](../scripts/Install-PSScriptAnalyzer.ps1) - 5 warnings
- [`scripts/Invoke-Linter.ps1`](../scripts/Invoke-Linter.ps1) - 2 warnings
- [`scripts/Invoke-Tests.ps1`](../scripts/Invoke-Tests.ps1) - 3 warnings

**Acceptance Criteria:**
- [ ] No `PSUseConsistentWhitespace` warnings
- [ ] Formatting follows project standards
- [ ] Tests pass
- [ ] Git diff shows only whitespace changes

---

### Phase 3: Brace Placement (P2)

**Effort:** 30 minutes
**Files Affected:** 2
**Warnings:** 10

**Issue:** `PSPlaceCloseBrace` - Close brace before a branch statement is followed by a new line

```powershell
# Bad (linter complains)
if ($condition) {
    # ...
}
else {
    # ...
}

# Good (expected style)
if ($condition) {
    # ...
} else {
    # ...
}
```

**Files to fix:**
- [`modules/linux-compat.ps1`](../modules/linux-compat.ps1) - 5 warnings (lines 200, 233, 271, 316, 355)
- [`scripts/Install-PSScriptAnalyzer.ps1`](../scripts/Install-PSScriptAnalyzer.ps1) - 1 warning (line 76)

**Note:** This is controversial styling. Consider if it's worth changing.

**Decision Points:**
1. Does our project have a strong preference?
2. Is consistency more important than personal style?
3. Should we disable this rule instead?

**Acceptance Criteria:**
- [ ] Either: Fix all brace placement issues
- [ ] Or: Add `PSPlaceCloseBrace` to ExcludeRules
- [ ] Decision documented
- [ ] Tests pass

---

### Phase 4: Function Naming (P3 - Optional)

**Effort:** 15 minutes
**Warnings:** 2

**Issue:** `PSUseApprovedVerbs` - The cmdlet 'ssh-keygen' uses an unapproved verb

```powershell
# Bad
function ssh-keygen { ... }

# Good options:
function New-SshKey { ... }        # Generate new SSH key
function Invoke-SshKeygen { ... }  # Wrapper around ssh-keygen
```

**Files:**
- [`modules/functions.ps1:39`](../modules/functions.ps1)
- [`modules/linux-compat.ps1:392`](../modules/linux-compat.ps1)

**Decision:** This is a **Linux compatibility alias**. We may want to:
1. Keep it as-is (user convenience)
2. Add to linter ExcludeRules
3. Rename to `New-SshKey` with `ssh-keygen` alias

**Recommendation:** Add to ExcludeRules - it's intentional Linux compat.

**Acceptance Criteria:**
- [ ] Decision made and documented
- [ ] Either: Functions renamed
- [ ] Or: Rule excluded in `.PSScriptAnalyzerSettings.psd1`

---

## Implementation Strategy

### Option A: Big Bang (Not Recommended)
- Fix all 53 warnings in one commit
- Risk: Large diff, hard to review
- Pro: Fast

### Option B: Incremental (Recommended)
- Fix one category per commit
- Each commit is small, focused, reviewable
- Can be done across multiple sessions

**Recommended Order:**
1. Commit 1: Fix unused variables/parameters (2 warnings) - 15 min
2. Commit 2: Auto-fix whitespace (try `-Fix` flag) - 30 min
3. Commit 3: Manual whitespace fixes (remaining) - 1 hour
4. Commit 4: Brace placement (or exclude rule) - 30 min
5. Commit 5: Function naming (or exclude rule) - 15 min

---

## Files to Modify

| File | Warnings | Categories |
|------|----------|------------|
| [`settings/icons.ps1`](../settings/icons.ps1) | 12 | Whitespace |
| [`modules/linux-compat.ps1`](../modules/linux-compat.ps1) | 17 | Whitespace, Brace, Naming |
| [`modules/logger.ps1`](../modules/logger.ps1) | 6 | Whitespace |
| [`modules/nerd-fonts.ps1`](../modules/nerd-fonts.ps1) | 2 | Unused param, Whitespace |
| [`modules/functions.ps1`](../modules/functions.ps1) | 1 | Naming |
| [`profile.ps1`](../profile.ps1) | 1 | Unused var |
| [`scripts/Install-PSScriptAnalyzer.ps1`](../scripts/Install-PSScriptAnalyzer.ps1) | 6 | Whitespace, Brace |
| [`scripts/Invoke-Linter.ps1`](../scripts/Invoke-Linter.ps1) | 2 | Whitespace |
| [`scripts/Invoke-Tests.ps1`](../scripts/Invoke-Tests.ps1) | 4 | Whitespace, Unused var |
| [`scripts/New-TestFile.ps1`](../scripts/New-TestFile.ps1) | 3 | Whitespace, Indentation |

---

## Testing Plan

### Before Each Commit
```powershell
# 1. Run linter
./scripts/Invoke-Linter.ps1

# 2. Run tests
./scripts/Invoke-Tests.ps1

# 3. Check git diff
git diff

# 4. Verify only intended changes
# - No functional changes
# - Only style/formatting
```

### Acceptance Criteria (Overall)
- [ ] Linter warnings reduced from 53 to target number
- [ ] All tests pass (260/260)
- [ ] Coverage unchanged (78.44%)
- [ ] No functional changes
- [ ] Each commit has clear message

### Target Goals

**Minimum (P0+P1):**
- Unused variables/parameters: 0 warnings
- Whitespace: < 5 warnings (most fixed)
- Total: < 35 warnings

**Ideal (All phases):**
- All categories addressed
- Total: < 10 warnings (or explicitly excluded)

---

## Definition of Done

### Phase 1 (Unused Vars) - REQUIRED
- [ ] Fixed or removed unused variables (2)
- [ ] Fixed or removed unused parameters (1)
- [ ] Tests pass
- [ ] Committed

### Phase 2 (Whitespace) - REQUIRED
- [ ] Auto-fix attempted
- [ ] Manual fixes applied where needed
- [ ] Whitespace warnings < 5
- [ ] Tests pass
- [ ] Committed

### Phase 3 (Braces) - OPTIONAL
- [ ] Decision made (fix or exclude)
- [ ] If fix: Applied to all files
- [ ] If exclude: Added to config
- [ ] Tests pass
- [ ] Committed

### Phase 4 (Naming) - OPTIONAL
- [ ] Decision made (rename or exclude)
- [ ] If rename: Applied with aliases
- [ ] If exclude: Added to config
- [ ] Tests pass
- [ ] Committed

### Overall
- [ ] Total warnings ≤ 35 (minimum goal)
- [ ] CI pipeline passes
- [ ] Documentation updated (if rules excluded)
- [ ] Task moved to `todo/done/`

---

## Dependencies

**Blocks:** None
**Blocked By:** None
**Related:**
- [012-fix-coverage-parameter-type.md](./012-fix-coverage-parameter-type.md) - Related code quality
- PSScriptAnalyzer integration (just completed)

---

## Risks & Mitigations

### Risk 1: Accidental Functional Changes
**Likelihood:** Low
**Impact:** High
**Mitigation:**
- Run tests after each change
- Review diffs carefully
- Commit small, focused changes
- Revert if tests fail

### Risk 2: Merge Conflicts (If Others Working)
**Likelihood:** Medium
**Impact:** Low
**Mitigation:**
- Coordinate with team
- Do this during low-activity period
- Rebase frequently

### Risk 3: Controversial Style Choices
**Likelihood:** Medium
**Impact:** Low
**Mitigation:**
- Follow community standards (PSScriptAnalyzer defaults)
- Document decisions
- Be pragmatic (exclude rules if needed)

---

## Success Metrics

**Before:**
- 53 linter warnings
- Inconsistent code style
- Mixed formatting

**After (Minimum):**
- ≤ 35 linter warnings (34% reduction)
- Zero unused code
- Consistent whitespace

**After (Ideal):**
- ≤ 10 linter warnings (81% reduction)
- All style rules enforced or explicitly excluded
- Clean `Invoke-Linter.ps1` output

---

## Notes

### Auto-Fix Safety

PSScriptAnalyzer's `-Fix` flag is generally safe but:
- Always review changes with `git diff`
- Test after auto-fix
- Revert if unexpected changes occur

### When to Exclude Rules

Exclude a rule when:
1. It conflicts with project conventions
2. It's intentional (e.g., Linux compat aliases)
3. Fixing creates more problems than it solves
4. Team consensus is to ignore it

### Future Automation

Consider adding to CI:
```yaml
- name: Check code style
  run: |
    $warnings = ./scripts/Invoke-Linter.ps1
    if ($warnings -gt 35) {
      Write-Error "Too many linter warnings: $warnings (max: 35)"
      exit 1
    }
```

This enforces a "ratchet" - warnings can't increase.

---

## Related Documentation

- [PSScriptAnalyzer Rules](https://learn.microsoft.com/en-us/powershell/utility-modules/psscriptanalyzer/rules/readme)
- [`.PSScriptAnalyzerSettings.psd1`](../.PSScriptAnalyzerSettings.psd1) - Current config
- PowerShell [Style Guide](https://poshcode.gitbook.io/powershell-practice-and-style/)
