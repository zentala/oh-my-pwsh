# 005 - Testing Infrastructure

**Status:** `active`
**Priority:** P1 (high - quality & confidence)
**Complexity:** High (multi-phase, ~2-3 sessions)

## Goal

Implement comprehensive testing infrastructure for oh-my-pwsh with automated tests, code coverage, CI/CD integration, and optional git hooks.

## Problem

Currently we have:
- ❌ No automated tests (Pester)
- ❌ No code coverage metrics
- ❌ No CI/CD test pipeline
- ❌ No quality gates before merge
- ✅ Only manual test scripts (test-*.ps1)

**Risks without testing:**
- Breaking changes go unnoticed
- Regressions in production
- Fear of refactoring
- Manual testing burden
- No confidence in deployments

## Solution Architecture

See [TESTING-STRATEGY.md](../docs/TESTING-STRATEGY.md) for full architectural overview.

### Architecture Decisions

This task implements the following ADRs:
- [ADR-001](../adr/001-pester-test-framework.md) - Pester 5.x as test framework
- [ADR-002](../adr/002-test-isolation-strategy.md) - 3-layer test strategy
- [ADR-003](../adr/003-coverage-targets.md) - Differentiated coverage targets
- [ADR-004](../adr/004-git-hooks-optional.md) - Optional pre-commit hooks

### High-Level Design

```
Testing Infrastructure
├── Layer 1: Test Foundation
│   ├── Pester 5.x installation
│   ├── Test folder structure (Unit/Integration/E2E)
│   └── Test helpers & fixtures
│
├── Layer 2: Test Suite
│   ├── Unit tests (fast, isolated)
│   ├── Integration tests (module interactions)
│   └── E2E tests (full profile scenarios)
│
├── Layer 3: Test Runner
│   ├── Invoke-Tests.ps1 (orchestrator)
│   ├── Coverage reporting
│   └── Multiple output formats
│
├── Layer 4: CI/CD Pipeline
│   ├── GitHub Actions workflows
│   ├── Test matrix (OS, PS versions)
│   └── Coverage upload & badges
│
└── Layer 5: Developer Tools
    ├── Git hooks (optional)
    ├── Test scaffolding
    └── Watch mode
```

---

## Implementation Plan

### Phase 1: Foundation (MVP) - ~2-3 hours

**Goal:** Basic testing infrastructure working locally

#### 1.1 Install & Configure Pester
- [ ] Create `scripts/Install-TestDeps.ps1`
  - Install Pester 5.5.0+
  - Verify installation
  - Check PowerShell version
- [ ] Document installation in README

#### 1.2 Create Test Structure
- [ ] Create folder structure:
  ```
  tests/
  ├── Unit/
  ├── Integration/
  ├── E2E/
  ├── Fixtures/
  ├── Helpers/
  └── Coverage/ (gitignored)
  ```
- [ ] Add `.gitignore` entries for test outputs

#### 1.3 Create Test Runner
- [ ] Implement `scripts/Invoke-Tests.ps1`:
  ```powershell
  param(
      [ValidateSet('Unit', 'Integration', 'E2E', 'All')]
      [string]$Type = 'All',

      [switch]$Coverage,
      [switch]$Fast,
      [switch]$Watch
  )
  ```
- [ ] Support different test types
- [ ] Generate coverage reports (HTML + XML)
- [ ] Exit codes for CI

#### 1.4 Write First Tests
- [ ] `tests/Unit/Icons.Tests.ps1`
  - Test Get-FallbackIcon for all roles
  - Test Get-IconColor
  - Test Test-NerdFontSupport
- [ ] `tests/Unit/StatusMessage.Tests.ps1`
  - Test Write-StatusMessage with strings
  - Test with message segments
  - Test -NoIndent parameter
- [ ] `tests/Unit/FallbackBehavior.Tests.ps1` **CRITICAL**
  - Test behavior when bat NOT installed
  - Test behavior when eza NOT installed
  - Test behavior when NO tools installed
- [ ] Run tests: `./scripts/Invoke-Tests.ps1 -Type Unit`

**Success Criteria:**
- ✅ Pester installed
- ✅ At least 15 passing unit tests (including fallback tests)
- ✅ Tests include missing dependency scenarios
- ✅ Tests run in < 30 seconds
- ✅ Coverage report generated

**Acceptance Criteria:**
- [ ] Tests pass on machine with all tools installed
- [ ] Tests pass on machine with NO tools installed
- [ ] Profile loads without errors in both scenarios
- [ ] All fallback paths are tested

**Definition of Done:**
- [ ] Code written and committed
- [ ] All tests passing locally
- [ ] Coverage report shows ≥ 60% overall
- [ ] No errors when running tests
- [ ] Documentation updated (README testing section)

---

### Phase 2: Core Test Coverage - ~3-4 hours

**Goal:** Achieve 75%+ overall coverage

#### 2.1 Unit Tests for Core Modules
- [ ] `tests/Unit/Logger.Tests.ps1`
  - Write-InstallHint
  - Write-ToolStatus
  - Write-ModuleStatus
  - Write-ProfileStatus
- [ ] `tests/Unit/LinuxCompat.Tests.ps1`
  - Test all compatibility aliases
  - Test fallback behavior
- [ ] Target: 90% coverage for Tier 1, 80% for Tier 2

#### 2.2 Integration Tests
- [ ] `tests/Integration/LoggingFlow.Tests.ps1`
  - Test Write-InstallHint → Write-StatusMessage → Get-FallbackIcon flow
  - Test message segment composition end-to-end
- [ ] `tests/Integration/ToolDetection.Tests.ps1`
  - Test tool detection with mocked Get-Command
  - Test status output for installed/missing tools

#### 2.3 Test Helpers & Fixtures
- [ ] `tests/Helpers/TestHelpers.ps1`
  - Mock-ConsoleOutput
  - Assert-OutputContains
  - New-TempConfig
- [ ] `tests/Fixtures/`
  - config-valid.ps1
  - config-invalid.ps1
  - config-minimal.ps1

**Success Criteria:**
- ✅ 50+ total tests
- ✅ Coverage ≥ 75% overall
- ✅ Coverage ≥ 90% for Tier 1 components (icons, status-output)
- ✅ All tests pass consistently

**Acceptance Criteria:**
- [ ] All modules have unit tests
- [ ] Integration tests cover message segment composition
- [ ] Tests cover all missing dependency scenarios
- [ ] Install script consistency test implemented
- [ ] Builder pattern for test configs working

**Definition of Done:**
- [ ] All unit tests written for Tier 1 & 2 modules
- [ ] Integration tests written and passing
- [ ] Coverage report shows ≥ 75% overall
- [ ] All tests passing on machine with/without tools
- [ ] Test helpers and fixtures created
- [ ] Code committed with clear commit message

---

### Phase 3: CI/CD Integration - ~2-3 hours

**Goal:** Automated testing in GitHub Actions

#### 3.1 Create GitHub Workflows
- [ ] `.github/workflows/tests.yml`
  ```yaml
  name: Tests
  on: [push, pull_request]

  jobs:
    test:
      runs-on: ${{ matrix.os }}
      strategy:
        matrix:
          os: [windows-latest, ubuntu-latest]
          powershell: ['7.4', '7.3']

      steps:
        - uses: actions/checkout@v4
        - name: Install dependencies
          run: ./scripts/Install-TestDeps.ps1
        - name: Run tests
          run: ./scripts/Invoke-Tests.ps1 -Coverage
        - name: Upload coverage
          uses: codecov/codecov-action@v3
  ```

#### 3.2 Coverage Reporting
- [ ] Sign up for Codecov/Coveralls
- [ ] Add coverage badges to README
- [ ] Configure coverage comments on PRs

#### 3.3 Quality Gates
- [ ] Fail CI if tests fail
- [ ] Fail CI if coverage < 75%
- [ ] Warn if coverage decreases

**Success Criteria:**
- ✅ CI runs on every PR
- ✅ Tests pass in CI
- ✅ Coverage displayed in GitHub Actions logs
- ✅ Cannot merge if tests fail

**Acceptance Criteria:**
- [ ] GitHub Actions workflow runs on push and PR
- [ ] Tests run on Windows and Ubuntu
- [ ] Coverage report generated in CI
- [ ] Coverage displayed in action logs
- [ ] Failing tests block PR merge
- [ ] Matrix tests multiple PowerShell versions (7.3, 7.4)

**Definition of Done:**
- [ ] `.github/workflows/tests.yml` created
- [ ] Workflow runs successfully on test PR
- [ ] All tests pass in CI
- [ ] Coverage visible in action output
- [ ] Branch protection rules configured (if applicable)
- [ ] Documentation updated with CI badge/status

---

### Phase 4: Developer Experience - ~2 hours

**Goal:** Make testing easy and pleasant

#### 4.1 Git Hooks (Optional)
- [ ] Create `.github/hooks/pre-commit`
  - Run unit tests only (fast)
  - Clear error messages
  - Bypassable with --no-verify
- [ ] Create `scripts/Install-GitHooks.ps1`
  - Copy hooks to .git/hooks/
  - Make executable
  - Print installation message

#### 4.2 Test Scaffolding
- [ ] Create `scripts/New-TestFile.ps1`
  ```powershell
  param([string]$Path)
  # Generates test file from template
  # Creates tests/Unit/<ModuleName>.Tests.ps1
  ```
- [ ] Test templates in `tests/Helpers/Templates/`

#### 4.3 Developer Tools
- [ ] Watch mode: `Invoke-Tests.ps1 -Watch`
  - Re-run tests on file change
  - Uses FileSystemWatcher
- [ ] `scripts/Show-Coverage.ps1`
  - Opens HTML coverage report in browser

**Success Criteria:**
- ✅ Git hook installs successfully
- ✅ Hook runs in < 30 seconds
- ✅ Scaffolding generates valid test files
- ✅ Watch mode works

**Acceptance Criteria:**
- [ ] `Install-GitHooks.ps1` works without errors
- [ ] Pre-commit hook runs only unit tests (fast)
- [ ] Hook can be bypassed with `--no-verify`
- [ ] `New-TestFile.ps1` generates valid Pester tests
- [ ] Watch mode detects file changes correctly

**Definition of Done:**
- [ ] Git hook script created in `.github/hooks/`
- [ ] Installation script created and tested
- [ ] Hook tested on real commit
- [ ] Test scaffolding script created
- [ ] Watch mode implemented (optional)
- [ ] Documentation updated with hook installation instructions

---

### Phase 5: E2E & Advanced (Optional) - ~2-3 hours

**Goal:** Full scenario coverage

#### 5.1 E2E Tests
- [ ] `tests/E2E/ProfileLoad.Tests.ps1`
  - Full profile load without errors
  - All modules sourced correctly
  - Config loaded
- [ ] `tests/E2E/HelpSystem.Tests.ps1`
  - Help command works
  - All help topics accessible
- [ ] `tests/E2E/ToolIntegration.Tests.ps1`
  - Enhanced tools work when installed
  - Fallbacks work when missing

#### 5.2 Performance Tests
- [ ] Profile load time benchmark
- [ ] Test execution time tracking
- [ ] Regression detection

#### 5.3 Documentation
- [ ] Create `docs/TESTING-GUIDE.md`
  - How to write unit tests
  - How to write integration tests
  - Mocking patterns
  - Best practices

**Success Criteria:**
- ✅ E2E tests cover main scenarios
- ✅ Performance baseline established
- ✅ Developer guide complete

**Acceptance Criteria:**
- [ ] E2E test for full profile load (with all tools)
- [ ] E2E test for profile load (with NO tools) **CRITICAL**
- [ ] E2E test for help system
- [ ] Performance benchmark for profile load time
- [ ] `docs/TESTING-GUIDE.md` complete with examples

**Definition of Done:**
- [ ] E2E tests written and passing
- [ ] Performance baseline documented
- [ ] Testing guide created with:
  - How to write unit tests
  - How to write integration tests
  - Mocking patterns
  - Best practices for testing fallbacks
- [ ] All documentation reviewed and complete

---

## File Structure (Final)

```
oh-my-pwsh/
├── tests/
│   ├── Unit/
│   │   ├── Icons.Tests.ps1
│   │   ├── StatusMessage.Tests.ps1
│   │   ├── Logger.Tests.ps1
│   │   ├── LinuxCompat.Tests.ps1
│   │   └── ...
│   ├── Integration/
│   │   ├── LoggingFlow.Tests.ps1
│   │   ├── ToolDetection.Tests.ps1
│   │   └── ...
│   ├── E2E/
│   │   ├── ProfileLoad.Tests.ps1
│   │   ├── HelpSystem.Tests.ps1
│   │   └── ...
│   ├── Fixtures/
│   │   ├── config-valid.ps1
│   │   └── ...
│   ├── Helpers/
│   │   ├── TestHelpers.ps1
│   │   ├── Mocks.ps1
│   │   └── Templates/
│   └── Coverage/ (gitignored)
│
├── scripts/
│   ├── Invoke-Tests.ps1
│   ├── Install-TestDeps.ps1
│   ├── Install-GitHooks.ps1
│   ├── New-TestFile.ps1
│   └── Show-Coverage.ps1
│
├── .github/
│   ├── workflows/
│   │   ├── tests.yml
│   │   └── coverage.yml
│   └── hooks/
│       └── pre-commit
│
└── docs/
    ├── TESTING-STRATEGY.md
    └── TESTING-GUIDE.md
```

---

## Dependencies

### Prerequisites
- PowerShell 7.0+
- Git (for hooks)
- Internet connection (for Pester install, CI)

### External Dependencies
- Pester 5.5.0+ (from PowerShell Gallery)
- Codecov/Coveralls account (for coverage)

### Internal Dependencies
- All existing modules must remain testable
- No breaking changes to public APIs

---

## Testing the Tests

Meta-testing strategy:

### Test Quality Checklist
- [ ] Tests are fast (unit < 100ms)
- [ ] Tests are deterministic (no flaky tests)
- [ ] Tests are isolated (no shared state)
- [ ] Tests have clear names (describes what they test)
- [ ] Tests fail when they should
- [ ] Mocks are minimal and targeted

### Mutation Testing (Future)
Consider using mutation testing to verify test quality:
- Change code intentionally
- Tests should fail
- If tests pass, they're not testing the right thing

---

## Success Criteria (Overall)

### MVP (Minimum Viable Product)
- [x] Architecture designed (this task)
- [ ] Pester installed
- [ ] 20+ unit tests written
- [ ] Coverage ≥ 75%
- [ ] CI pipeline running
- [ ] Documentation complete

### Complete Implementation
- [ ] 50+ total tests (unit + integration + E2E)
- [ ] Coverage ≥ 85%
- [ ] All tier targets met
- [ ] Git hooks functional
- [ ] Developer guide published
- [ ] Coverage badge in README

### Advanced (Nice-to-Have)
- [ ] Matrix testing (multiple OS/PS versions)
- [ ] Performance benchmarks
- [ ] Watch mode
- [ ] Test scaffolding tools

---

## Related Documentation

### Architecture Decision Records
- [ADR-001: Pester Test Framework](../adr/001-pester-test-framework.md)
- [ADR-002: Test Isolation Strategy](../adr/002-test-isolation-strategy.md)
- [ADR-003: Coverage Targets](../adr/003-coverage-targets.md)
- [ADR-004: Git Hooks Optional](../adr/004-git-hooks-optional.md)

### Documentation
- [TESTING-STRATEGY.md](../docs/TESTING-STRATEGY.md) - Overall strategy (to be created)
- [TESTING-GUIDE.md](../docs/TESTING-GUIDE.md) - Developer guide (to be created)
- [README.md](../README.md) - Will add testing section

### Related Tasks
- [001-logging-system.md](./done/001-logging-system.md) - Code to be tested
- [002-icon-fallback-system.md](./done/002-icon-fallback-system.md) - Code to be tested
- [004-write-status-message.md](./done/004-write-status-message.md) - Code to be tested

---

## Implementation Timeline

**Estimated Total: 11-15 hours across 3-4 sessions**

| Phase | Time | Priority | Dependencies |
|-------|------|----------|--------------|
| Phase 1: Foundation | 2-3h | P0 | None |
| Phase 2: Coverage | 3-4h | P0 | Phase 1 |
| Phase 3: CI/CD | 2-3h | P1 | Phase 2 |
| Phase 4: Dev Tools | 2h | P2 | Phase 1 |
| Phase 5: E2E | 2-3h | P3 | Phase 2 |

**Recommended Order:**
1. Phase 1 (session 1)
2. Phase 2 (session 2)
3. Phase 3 + Phase 4 (session 3)
4. Phase 5 (optional, session 4)

---

## Dependencies & Blockers Matrix

### Phase Dependencies

| Phase | Depends On | Blocks | Can Run In Parallel With |
|-------|-----------|--------|--------------------------|
| **Phase 1** | None | Phases 2-5 | None (prerequisite for all) |
| **Phase 2** | Phase 1 complete | Phase 3, 5 | Phase 4 (partial) |
| **Phase 3** | Phase 2 complete | None | Phase 4 |
| **Phase 4** | Phase 1 complete | None | Phases 2, 3 |
| **Phase 5** | Phase 2 complete | None | Phases 3, 4 |

### External Dependencies

| Dependency | Required For | Mitigation if Unavailable |
|------------|-------------|---------------------------|
| **Pester 5.5.0+** | All phases | BLOCKER - must install from PSGallery |
| **PowerShell 7.0+** | All phases | BLOCKER - upgrade required |
| **Git** | Phase 4 only | Skip git hooks, continue with other phases |
| **GitHub Actions access** | Phase 3 only | Run tests locally only |
| **Internet connection** | Pester install, CI | Use cached Pester if available |

### Internal Dependencies

| Component | Must Work With | Integration Points |
|-----------|---------------|-------------------|
| **Tests** | All modules in `modules/` | Source all modules to test |
| **Install script** | Profile dependencies | Must match profile's optional tools list |
| **Fallback tests** | `Get-Command` mocking | Mock tool availability |
| **Coverage reports** | Pester CodeCoverage | Requires Pester 5.x+ |
| **Git hooks** | Test runner script | Calls `Invoke-Tests.ps1 -Type Unit -Fast` |

### Critical Test Requirements

**These requirements MUST be met for testing infrastructure to be considered complete:**

1. **Test Missing Dependencies** (CRITICAL)
   - Test profile behavior when bat NOT installed
   - Test profile behavior when eza NOT installed
   - Test profile behavior when NO enhanced tools installed
   - Test profile behavior when oh-my-stats NOT installed
   - Verify fallback to native PowerShell commands works

2. **Install Script Consistency**
   - Verify install script lists all optional dependencies
   - Verify profile has fallback for each tool in install script
   - Keep install script and profile requirements synchronized

3. **No Regressions**
   - Tests catch when fallback code is accidentally removed
   - Tests catch when conditional handling is broken
   - Tests verify profile loads without errors in all scenarios

4. **Auto-run Before Push**
   - Git pre-commit hook runs unit tests
   - Hook is fast (< 30 seconds)
   - Hook is bypassable for WIP commits
   - CI remains ultimate quality gate

---

## Risks & Mitigations

### Risk 1: Slow Test Suite
**Impact:** Developers avoid running tests
**Mitigation:**
- Keep unit tests fast (< 100ms each)
- Use parallel execution
- Provide -Fast mode
- Git hooks run unit tests only

### Risk 2: Flaky Tests
**Impact:** Loss of trust in test suite
**Mitigation:**
- Avoid time-based tests
- Mock external dependencies
- Use deterministic test data
- Retry logic in CI

### Risk 3: Low Adoption of Git Hooks
**Impact:** Developers commit untested code
**Mitigation:**
- Make hooks optional but recommended
- Document benefits clearly
- Keep hooks fast (< 30s)
- CI remains ultimate gate

### Risk 4: Coverage Metric Gaming
**Impact:** High coverage but poor tests
**Mitigation:**
- Code review for test quality
- Focus on meaningful assertions
- Mutation testing (future)
- Monitor test-to-code ratio

---

## Notes

### Why Now?
- Codebase is growing
- More contributors expected
- Refactoring planned
- Need confidence in changes

### Technical Debt
This task addresses:
- No automated testing
- Manual testing burden
- Fear of breaking changes
- No quality gates

### Future Enhancements
- Visual regression testing (screenshots)
- Contract testing (module interfaces)
- Property-based testing (Hypothesis-style)
- Benchmark regression tests
