# Known Issues

## Non-Blocking Issues

### 1. PowerShell -Coverage Parameter Warning

**Status:** Cosmetic (does not affect functionality)
**Priority:** P3 (low)
**File:** [`scripts/Invoke-Tests.ps1:52`](./scripts/Invoke-Tests.ps1)

**Description:**
When running tests with coverage, PowerShell may display a non-fatal warning:
```
Invoke-Tests.ps1: Cannot convert value "Pester.CodeCoverage" to type
"System.Management.Automation.SwitchParameter". Boolean parameters accept
only Boolean values and numbers, such as $True, $False, 1 or 0.
```

**Impact:**
- Console output slightly polluted
- No functional impact - tests and coverage work correctly

**Workaround:**
- Ignore the warning
- Or use: `.\Invoke-Tests.ps1 -Coverage:$true` (explicit)

**Root Cause:**
PowerShell parameter binding edge case with `[switch]` type in certain contexts (likely tab-completion).

**Why Not Fixed:**
- Changing to `[bool]` breaks CI (requires `-Coverage:$true` instead of `-Coverage`)
- Functional workaround exists
- Low priority vs. other improvements

**Tracked In:** [todo/012-fix-coverage-parameter-type.md](./todo/012-fix-coverage-parameter-type.md)

---

_Last updated: 2025-01-14_
