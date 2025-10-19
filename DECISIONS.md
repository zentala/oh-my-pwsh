# Key Decisions - Context for Future

> **Purpose:** Zachować kontekst decyzji, które mogą wydawać się dziwne po powrocie do projektu.
> **Audience:** Future-Me, nowi contributors, ktokolwiek kto to przejmie
> **Last Updated:** 2025-10-19
>
> **Why this exists:** Personal project - może być porzucony w dowolnym momencie. Ta dokumentacja zapewnia, że każdy (włącznie ze mną za pół roku) zrozumie "dlaczego tak zrobiliśmy".

---

## 🎯 Strategic Decisions

### 1. Why 30% Coverage Threshold (Not 75%)?

**Decision:** Critical threshold = 30%, Target = 75%

**Context:**
- 1 developer, console application (not banking system)
- 100% on critical modules (logger, status-output, icons)
- 75% would mean testing utility modules with low ROI

**Rationale:**
```
Tier 1 (core): 95.7% ✅ (target 90%)
Tier 2 (helpers): 87.7% ✅ (target 80%)
Overall: 36.69% (target 75%)
```

**Why It's OK:**
- Quality > Quantity - critical paths covered
- Regression prevention works (32+ fallback tests)
- 75% would test `help-system.ps1` (low value)

**When to Revisit:**
- If team grows (>3 developers)
- If critical bugs emerge in untested areas
- If project becomes mission-critical

**See:** [ADR-003: Coverage Targets](./adr/003-coverage-targets.md)

---

### 2. Why Optional Git Hooks (Not Mandatory)?

**Decision:** Pre-commit hooks są OPTIONAL i BYPASSABLE

**Context:**
- Frustration with mandatory hooks in past projects
- "WIP commits" są legit use case
- CI jest ultimate quality gate

**Rationale:**
- Developer autonomy > forced workflow
- Hooks help but don't block productivity
- `--no-verify` zawsze dostępne

**Quote from ADR-004:**
> "Philosophy: Helpful but not mandatory. CI is the ultimate gate."

**Why It Works:**
- CI catches wszystko przed merge
- Developerzy mogą robić WIP commits
- Hooks są opt-in (trzeba zainstalować)

**When to Revisit:**
- If CI costs become too high
- If team consistently bypasses tests
- If quality drops significantly

**See:** [ADR-004: Git Hooks Optional](./adr/004-git-hooks-optional.md)

---

### 3. Why No PowerShell Version Matrix?

**Decision:** Test only on "latest" (not PS 7.3, 7.4 matrix)

**Original Plan:**
```yaml
matrix:
  os: [windows-latest, ubuntu-latest]
  powershell: ['7.4', '7.3']  # ❌ Removed
```

**Why Removed:**
- `powershell/setup-powershell` action nie istnieje
- Alternatywy są złożone (manual install)
- Runners have latest pre-installed
- 1 developer = nie krytyczne

**Trade-offs:**
- ✅ Pro: Prostsze, mniej failures
- ❌ Con: Nie wykrywamy PS 7.3 breaking changes
- ⚖️ Decision: Ship with latest only

**When to Add Back:**
- If users report PS 7.3 issues
- If GitHub adds official PS version action
- If backward compatibility becomes critical

**See:** Commits `5287097`, `6f18e4c`

---

### 4. Why Builder Pattern for Test Configs?

**Decision:** Użycie builder pattern zamiast static fixtures

**Example:**
```powershell
# Instead of:
. tests/Fixtures/config-all-tools.ps1

# We use:
$config = New-TestConfig | Add-NerdFonts | Add-Tools @("bat", "eza")
```

**Rationale:**
- Flexibility - łatwo kombinować scenariusze
- Readability - self-documenting
- Extensibility - łatwo dodać `Add-Theme`, `Add-Plugin`
- DRY - reuse components

**Why It's Better:**
```powershell
# Static fixtures = 3 files:
config-no-tools.ps1
config-all-tools.ps1
config-partial-tools.ps1

# Builder = infinite combinations:
New-TestConfig | Add-Tools @("bat")
New-TestConfig | Add-Tools @("eza")
New-TestConfig | Add-Tools @("bat", "eza")
New-TestConfig | Add-NerdFonts | Add-Tools @("bat")
# ... etc
```

**When to Revisit:**
- Never - this pattern scales perfectly

**See:** `tests/Helpers/TestHelpers.ps1`

---

### 5. Why Nerd Fonts Suspended?

**Decision:** Nerd Fonts = EXPERIMENTAL (default OFF)

**Context:**
- Most terminals render NF poorly (squares, missing glyphs)
- Windows Terminal, VS Code = OK
- ConEmu, standard cmd.exe = broken
- PowerShell ISE = broken

**Current State:**
```powershell
$global:OhMyPwsh_UseNerdFonts = $false  # Default
```

**Why Not Remove Completely:**
- Future terminals may improve
- Code is clean, no harm keeping it
- Easy to re-enable when ready

**Migration Path:**
```powershell
# When terminals improve:
$global:OhMyPwsh_UseNerdFonts = $true
# Icons automatically upgrade
```

**See:** [003-nerd-font-architecture.md](./todo/003-nerd-font-architecture.md)

---

## 🛠️ Technical Decisions

### 6. Why Pester 5.x (Not Jest, Mocha, etc.)?

**Decision:** Pester 5.5.0+ as test framework

**Alternatives Considered:**
1. **PSate** - Abandoned, unmaintained
2. **Custom framework** - Overkill for profile
3. **Jest/Mocha** - Wrong ecosystem (Node.js)

**Why Pester:**
- De-facto standard for PowerShell
- Active maintenance
- JaCoCo coverage format
- Good mocking support

**See:** [ADR-001: Pester Test Framework](./adr/001-pester-test-framework.md)

---

### 7. Why 3-Layer Test Strategy?

**Decision:** Unit → Integration → E2E (pyramid)

**Rationale:**
```
     E2E (few, slow)
   Integration (some)
 Unit (many, fast)
```

**Distribution:**
- Unit: 148 tests (~84%)
- Integration: 12 tests (~7%)
- E2E: 0 tests (Phase 5)

**Why E2E Missing:**
- Phase 5 nie ukończony
- Unit + Integration catch 99% regressions
- E2E = nice-to-have dla console app

**See:** [ADR-002: Test Isolation Strategy](./adr/002-test-isolation-strategy.md)

---

### 8. Why FileSystemWatcher (Not Polling)?

**Decision:** Watch mode uses FileSystemWatcher + debounce

**Alternatives:**
1. **Polling** - CPU intensive, battery drain
2. **No watch mode** - manual rerun (poor DX)
3. **External tools** (nodemon) - extra dependency

**Implementation:**
```powershell
$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $projectRoot
$watcher.Filter = "*.ps1"
# 2-second debounce
```

**Why It's Good:**
- Native PowerShell (no dependencies)
- Efficient (event-driven)
- Debounce prevents multiple runs
- Clean shutdown on Ctrl+C

**See:** `scripts/Invoke-Tests.ps1` line 133-214

---

## 🎨 Design Decisions

### 9. Why Message Segments (Not Simple Strings)?

**Decision:** Write-StatusMessage accepts segment arrays

**Before:**
```powershell
Write-Host "[!] install bat: scoop install bat"
```

**After:**
```powershell
$segments = @(
    @{Text = "install "; Color = "White"}
    @{Text = "bat"; Color = "Yellow"}
    @{Text = ": "; Color = "White"}
    @{Text = "scoop install bat"; Color = "DarkGray"}
)
Write-StatusMessage -Role "warning" -Message $segments
```

**Why Complexity:**
- Tool names stand out (Yellow)
- Commands dimmed (DarkGray)
- Visual hierarchy improves UX
- Backward compatible (accepts strings)

**See:** [LOGGING-SYSTEM.md](./docs/LOGGING-SYSTEM.md)

---

### 10. Why Runbook (Not Just Commits)?

**Decision:** Daily runbook in `.claude/runbook/YYYY-MM-DD.md`

**What's In It:**
- What was done (narrative)
- Files created/modified
- Commits made
- Decisions explained
- Blockers encountered
- Next steps

**Why It Matters:**
- Git log = WHAT changed
- Runbook = WHY + HOW + CONTEXT
- Future-You will thank Past-You

**Example Use Case:**
> "Za 2 lata: *Dlaczego usunęliśmy PS version matrix?*"
> Check runbook → "powershell/setup-powershell nie istnieje"

**See:** [.claude/runbook/2025-10-18.md](./.claude/runbook/2025-10-18.md)

---

## 🚫 What We DIDN'T Do (And Why)

### 11. Why No Codecov Integration?

**Decision:** Skip Codecov (for now)

**Reason:**
- 1 developer = local coverage wystarczy
- GitHub Actions logs mają coverage %
- Codecov = extra setup, credentials, complexity

**When to Add:**
- If team grows (>3 developers)
- If coverage trends matter
- If PR reviews need coverage diff

**See:** [CODECOV-SETUP.md](./docs/CODECOV-SETUP.md) (instructions ready)

---

### 12. Why No Mutation Testing?

**Decision:** Skip mutation testing (Phase 5)

**Reason:**
- Overkill for console profile
- High cost (slow execution)
- Low ROI for this project

**What is Mutation Testing:**
```
Change code: $result = $true → $result = $false
If tests still pass → dead test!
```

**When to Revisit:**
- If critical bugs slip through tests
- If "dead tests" suspected
- If quality bar increases

**See:** `.future.md` item #19

---

### 13. Why No PSScriptAnalyzer in CI?

**Decision:** Skip PSScriptAnalyzer (for now)

**Reason:**
- Phase 5 feature
- Nice-to-have (not critical)
- Easy to add later

**When to Add:**
```yaml
# .github/workflows/tests.yml
- name: Run PSScriptAnalyzer
  run: Invoke-ScriptAnalyzer -Path . -Recurse
```

**See:** `.future.md` item #1

---

## 🔮 Future Considerations

### Questions for Future-You:

**If Tests Are Failing After 2 Years:**
1. Check Pester version - upgrade may be needed
2. Check PowerShell version - 7.x → 8.x breaking changes?
3. Check GitHub Actions logs - infrastructure changes?
4. Review runbook - maybe we documented this issue?

**If Coverage Dropped Significantly:**
1. Did we add untested code? (check git diff)
2. Did coverage format change? (JaCoCo → something else?)
3. Is Pester broken? (try older version)

**If Performance Degraded:**
1. No baseline = can't detect regression
2. Add performance tests (Phase 5)
3. Check profile load time manually

**If You Want to Resume Development:**
1. Read STATUS.md (this file)
2. Read .claude/runbook/2025-10-18.md
3. Run tests: `Invoke-Tests.ps1 -Coverage`
4. Check .future.md for ideas

---

## 📚 Document Index

**Start Here:**
- [STATUS.md](./STATUS.md) - Project snapshot, quick start
- [DECISIONS.md](./DECISIONS.md) - This file (context)

**Architecture:**
- [ARCHITECTURE.md](./docs/ARCHITECTURE.md) - Module structure
- [adr/](./adr/) - Architecture Decision Records

**Testing:**
- [TESTING-STRATEGY.md](./docs/TESTING-STRATEGY.md) - Complete strategy
- [005-testing-infrastructure.md](./todo/005-testing-infrastructure.md) - Implementation plan

**Session Logs:**
- [.claude/runbook/2025-10-18.md](./.claude/runbook/2025-10-18.md) - Implementation session

**Future:**
- [.future.md](./.future.md) - 22 enhancement ideas

---

**Last Updated:** 2025-10-19
**Environment:** PowerShell 7.5.3, Pester 5.7.1, GitHub Actions (windows-latest, ubuntu-latest)

**Remember:** These decisions made sense in October 2025 with 1 developer. Context may change. Decisions can be revisited. This document explains WHY things are the way they are, not prescribes FOREVER.

**Update this file:** If you change a major decision, update the relevant section with new date and rationale.
