# ADR-003: Code Coverage Targets

**Status:** Accepted
**Date:** 2025-10-18
**Deciders:** Paweł Żentała, Claude (Solution Architect)

## Context

Code coverage metrics help ensure adequate testing, but arbitrary targets can lead to wasteful test-writing or gaming the metrics. We need pragmatic, component-specific coverage targets that balance quality assurance with development velocity.

### Considerations
- Not all code is equally critical
- 100% coverage is unrealistic and often counterproductive
- Some code (like profile.ps1 orchestration) is hard to unit test
- Coverage should improve over time, not regress
- Need different metrics: line, branch, function coverage

## Decision

**We adopt differentiated coverage targets based on component criticality:**

### Tier 1: Core Functions (90% target)
**Components:**
- `settings/icons.ps1` - Get-FallbackIcon, Get-IconColor, Test-NerdFontSupport
- `modules/status-output.ps1` - Write-StatusMessage

**Rationale:**
- Used by entire profile
- Breaking these breaks everything
- Pure functions, easy to test
- High ROI on test effort

**Metrics:**
- Line coverage: ≥ 90%
- Branch coverage: ≥ 85%
- Function coverage: 100% (all public functions)

### Tier 2: Helper Modules (80% target)
**Components:**
- `modules/logger.ps1` - Write-InstallHint, Write-ToolStatus, Write-ModuleStatus
- `modules/linux-compat.ps1` - Compatibility wrappers

**Rationale:**
- Important but not critical
- Some edge cases OK to skip
- Good balance of effort vs. value

**Metrics:**
- Line coverage: ≥ 80%
- Branch coverage: ≥ 70%
- Function coverage: ≥ 90%

### Tier 3: Feature Modules (70% target)
**Components:**
- `modules/enhanced-tools.ps1` - Tool wrappers
- `modules/functions.ps1` - Utility functions
- `modules/git-helpers.ps1` - Git utilities

**Rationale:**
- Many external dependencies (hard to mock)
- Lower criticality
- Manual testing often sufficient

**Metrics:**
- Line coverage: ≥ 70%
- Branch coverage: ≥ 60%
- Function coverage: ≥ 80%

### Tier 4: Orchestration (60% target)
**Components:**
- `profile.ps1` - Main profile loader

**Rationale:**
- Mostly orchestration, not logic
- Covered by E2E tests
- Hard to unit test effectively

**Metrics:**
- Line coverage: ≥ 60%
- Branch coverage: ≥ 50%
- E2E coverage: 100% (all load paths)

### Overall Target
**Minimum: 75% overall line coverage**

This is calculated as weighted average across all tiers.

## Consequences

### Positive ✅

- **Pragmatic**: Focuses effort where it matters most
- **Achievable**: Targets are realistic given codebase
- **Clear**: Each component knows its target
- **Flexible**: Can adjust per-component as needed
- **Quality Gate**: CI enforces minimum 75%
- **Trend Tracking**: Can monitor coverage over time

### Negative ⚠️

- **Complexity**: Different targets per component (not simple "80% everywhere")
- **Maintenance**: Need to classify new files into tiers
- **Gaming**: Developers might write trivial tests to hit numbers
- **False Security**: High coverage doesn't guarantee good tests

### Neutral ℹ️

- **Tool Support**: Pester supports per-file coverage, need aggregation
- **Reporting**: Need custom reports showing per-tier breakdown

## Implementation

### Pester Configuration
```powershell
# Invoke-Tests.ps1

$config = [PesterConfiguration]::Default

# Coverage paths
$config.CodeCoverage.Enabled = $true
$config.CodeCoverage.Path = @(
    "settings/icons.ps1",           # Tier 1
    "modules/status-output.ps1",    # Tier 1
    "modules/logger.ps1",           # Tier 2
    "modules/*.ps1"                 # Tier 3
)

# Output formats
$config.CodeCoverage.OutputFormat = "JaCoCo"  # For CI
$config.CodeCoverage.OutputPath = "tests/Coverage/coverage.xml"

# Thresholds (overall)
$result = Invoke-Pester -Configuration $config

if ($result.CodeCoverage.CoveragePercent -lt 75) {
    throw "Coverage $($result.CodeCoverage.CoveragePercent)% is below minimum 75%"
}
```

### Custom Coverage Report
```powershell
# scripts/Show-Coverage.ps1

$report = Get-CoverageReport

# Group by tier
$tier1 = $report | Where-Object Path -match "icons|status-output"
$tier2 = $report | Where-Object Path -match "logger|linux-compat"
# ...

# Check tier targets
if ($tier1.Coverage -lt 90) {
    Write-Warning "Tier 1 coverage below 90%"
}
```

### CI Enforcement
```yaml
# .github/workflows/tests.yml

- name: Check Coverage
  run: |
    pwsh scripts/Invoke-Tests.ps1 -Coverage

    # Fail if below 75%
    $coverage = Get-Content coverage.xml | ConvertFrom-Xml
    if ($coverage.coverage.@line-rate -lt 0.75) {
      exit 1
    }
```

## Coverage Evolution Strategy

### Phase 1: Baseline (Current)
- Measure current coverage (likely ~0%)
- Set initial realistic targets

### Phase 2: Core Coverage (MVP)
- Achieve Tier 1: 90%
- Achieve Tier 2: 80%
- Overall: ≥ 70%

### Phase 3: Full Coverage (Complete)
- Achieve all tier targets
- Overall: ≥ 75%

### Phase 4: Continuous Improvement
- Increase targets over time
- Add branch/path coverage tracking
- Consider mutation testing

### Coverage Ratcheting
```powershell
# Never allow coverage to decrease
$previousCoverage = 75.5
$currentCoverage = 75.0

if ($currentCoverage -lt $previousCoverage) {
    throw "Coverage decreased from $previousCoverage% to $currentCoverage%"
}
```

## What We DON'T Measure

- **Test quality** - coverage doesn't mean good tests
- **Assertion density** - number of assertions per test
- **Test maintenance cost** - how brittle are tests
- **Developer experience** - how painful is testing

These require manual review and team discipline.

## Exclusions

Some code is explicitly excluded from coverage:

```powershell
# Excluded from coverage requirements:
- Test files (tests/*.Tests.ps1)
- Manual test scripts (test-*.ps1)
- Config templates (config.example.ps1)
- Documentation (docs/)
- Legacy code marked # SKIP-COVERAGE
```

## Alternatives Considered

### 1. Fixed 80% Everywhere
- **Pros**: Simple, clear target
- **Cons**: Unrealistic for orchestration code, wasteful for low-risk code
- **Verdict**: ❌ Too inflexible

### 2. No Coverage Targets
- **Pros**: No artificial pressure
- **Cons**: No quality gate, coverage likely drops
- **Verdict**: ❌ Insufficient discipline

### 3. 100% Coverage
- **Pros**: Maximum confidence
- **Cons**: Unrealistic, diminishing returns, game-able
- **Verdict**: ❌ Perfectionism, not pragmatism

### 4. Branch Coverage Only
- **Pros**: More meaningful than line coverage
- **Cons**: Harder to measure, less tool support
- **Verdict**: ⚠️ Track it, but don't enforce strictly

## Related

### Tasks
- [005-testing-infrastructure.md](../todo/005-testing-infrastructure.md) - Implementation task

### Documentation
- [TESTING-STRATEGY.md](../docs/TESTING-STRATEGY.md) - Overall testing approach
- [TESTING-GUIDE.md](../docs/TESTING-GUIDE.md) - How to achieve coverage

### Other ADRs
- [ADR-001](./001-pester-test-framework.md) - Test framework with coverage support
- [ADR-002](./002-test-isolation-strategy.md) - Test types that generate coverage

## References

- [Martin Fowler: Test Coverage](https://martinfowler.com/bliki/TestCoverage.html)
- [Google Testing Blog: Code Coverage Best Practices](https://testing.googleblog.com/2020/08/code-coverage-best-practices.html)
- [Pester Code Coverage](https://pester.dev/docs/usage/code-coverage)
