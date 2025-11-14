# 012 - Fix -Coverage Parameter Type Error

**Status:** `active`
**Priority:** P0 (blocker - technical debt)
**Complexity:** Low (< 30 minutes)
**Type:** Bug Fix

---

## Problem Statement

### Current Behavior
When running `Invoke-Tests.ps1 -Coverage`, PowerShell throws a non-fatal warning:
```
Invoke-Tests.ps1: Cannot convert value "Pester.CodeCoverage" to type
"System.Management.Automation.SwitchParameter". Boolean parameters accept
only Boolean values and numbers, such as $True, $False, 1 or 0.
```

**Impact:**
- ⚠️ Console output pollution
- ⚠️ Confusing for users
- ⚠️ May indicate type system issue
- ✅ Functionality works (tests + coverage both OK)

### Root Cause
Line 52 in [`scripts/Invoke-Tests.ps1`](../scripts/Invoke-Tests.ps1):
```powershell
[Parameter()]
[switch]$Coverage,
```

PowerShell's parameter binding has edge cases with `[switch]` type conversion in certain contexts (likely tab-completion or parameter validation).

---

## Solution

### Technical Approach

**Option A: Change to [bool] with default** (Recommended)
```powershell
[Parameter()]
[bool]$Coverage = $false,
```

**Option B: Keep [switch], suppress warning**
```powershell
[Parameter()]
[switch]$Coverage
# Add: $ErrorActionPreference = 'SilentlyContinue' before param binding
```

**Recommendation:** Option A - more explicit, cleaner semantics.

---

## Implementation Plan

### Step 1: Update Parameter Definition
**File:** [`scripts/Invoke-Tests.ps1`](../scripts/Invoke-Tests.ps1)
**Line:** 52

**Change:**
```powershell
# Before
[Parameter()]
[switch]$Coverage,

# After
[Parameter()]
[bool]$Coverage = $false,
```

### Step 2: Update Help Documentation
**File:** [`scripts/Invoke-Tests.ps1`](../scripts/Invoke-Tests.ps1)
**Lines:** 12-13

**Update .PARAMETER section:**
```powershell
.PARAMETER Coverage
    Generate code coverage report (HTML + XML). Default: $false
```

### Step 3: Verify Backward Compatibility
Test all invocation patterns:
```powershell
# Should work
./scripts/Invoke-Tests.ps1 -Coverage          # -Coverage = $true
./scripts/Invoke-Tests.ps1 -Coverage:$true    # Explicit
./scripts/Invoke-Tests.ps1 -Coverage:$false   # Explicit
./scripts/Invoke-Tests.ps1                    # No coverage

# Should work (PowerShell coercion)
./scripts/Invoke-Tests.ps1 -Coverage 1        # = $true
./scripts/Invoke-Tests.ps1 -Coverage 0        # = $false
```

### Step 4: Test in CI
Verify GitHub Actions workflow still works:
- File: [`.github/workflows/tests.yml`](../.github/workflows/tests.yml)
- Line: 53: `./scripts/Invoke-Tests.ps1 -Coverage`

---

## Testing Plan

### Unit Test (Optional)
No unit test needed - parameter validation is PowerShell's responsibility.

### Manual Testing
```powershell
# Test 1: Coverage enabled
pwsh -NoProfile -File ./scripts/Invoke-Tests.ps1 -Coverage
# Expected: No warning, coverage report generated

# Test 2: Coverage disabled
pwsh -NoProfile -File ./scripts/Invoke-Tests.ps1
# Expected: No warning, no coverage report

# Test 3: Explicit true
pwsh -NoProfile -File ./scripts/Invoke-Tests.ps1 -Coverage:$true
# Expected: No warning, coverage report generated

# Test 4: Explicit false
pwsh -NoProfile -File ./scripts/Invoke-Tests.ps1 -Coverage:$false
# Expected: No warning, no coverage report
```

### Acceptance Criteria
- [ ] No PowerShell warning when running with `-Coverage`
- [ ] Coverage report still generated correctly
- [ ] All existing usage patterns still work
- [ ] Help documentation accurate
- [ ] CI pipeline passes

---

## Definition of Done

- [ ] Parameter changed from `[switch]` to `[bool]`
- [ ] Default value `$false` added
- [ ] Help documentation updated
- [ ] Manual testing completed (all 4 scenarios)
- [ ] CI pipeline passes on GitHub
- [ ] No warnings in console output
- [ ] Code committed with clear message
- [ ] Task moved to `todo/done/`

---

## Files to Modify

| File | Lines | Change Type |
|------|-------|-------------|
| [`scripts/Invoke-Tests.ps1`](../scripts/Invoke-Tests.ps1) | 52 | Parameter type change |
| [`scripts/Invoke-Tests.ps1`](../scripts/Invoke-Tests.ps1) | 12-13 | Documentation update |

---

## Dependencies

**Blocks:** None
**Blocked By:** None
**Related:**
- [005-testing-infrastructure.md](./done/005-testing-infrastructure.md) - Created this script

---

## Risks & Mitigations

### Risk 1: Breaking Existing Scripts
**Likelihood:** Low
**Impact:** Medium
**Mitigation:**
- `[bool]` parameters accept same values as `[switch]`
- PowerShell coerces `-Coverage` to `-Coverage:$true`
- Test all invocation patterns before commit

### Risk 2: CI Failure
**Likelihood:** Very Low
**Impact:** Medium
**Mitigation:**
- CI uses `-Coverage` (no explicit true/false)
- This works with both `[switch]` and `[bool]`
- Test locally before push

---

## Related Documentation

- PowerShell [about_Functions_Advanced_Parameters](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_functions_advanced_parameters)
- PowerShell [about_Switch](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_switch)

---

## Notes

### Why [bool] Over [switch]?

| Aspect | [switch] | [bool] |
|--------|----------|--------|
| **Default value** | Always $false | Can specify explicit default |
| **Clarity** | Implicit | Explicit |
| **Type safety** | Less strict | More strict |
| **Edge cases** | Can have conversion issues | Cleaner semantics |
| **Best for** | Optional flags | Parameters with defaults |

### Why Now?
- Bug discovered during linter integration
- Low effort, high value fix
- Improves code quality and user experience
- No dependencies or blockers

---

## Success Metrics

- ✅ Zero PowerShell warnings when running tests
- ✅ 100% backward compatibility maintained
- ✅ CI pipeline success rate unchanged
- ✅ Developer experience improved (cleaner output)
