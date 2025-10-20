# Testing Strategy

## Overview

This document describes the comprehensive testing strategy for oh-my-pwsh, including test types, coverage targets, CI/CD integration, and developer workflows.

## Quick Links

- **Test Directory**: [tests/README.md](../tests/README.md) - Test structure and organization
- **Implementation Task**: [005-testing-infrastructure.md](../todo/005-testing-infrastructure.md)
- **Architecture Decisions**:
  - [ADR-001: Pester Test Framework](../adr/001-pester-test-framework.md)
  - [ADR-002: Test Isolation Strategy](../adr/002-test-isolation-strategy.md)
  - [ADR-003: Coverage Targets](../adr/003-coverage-targets.md)
  - [ADR-004: Git Hooks Optional](../adr/004-git-hooks-optional.md)

---

## Test Organization

All tests are located in `./tests/` directory with a three-tier structure:

### Directory Structure

```
tests/
├── Unit/              # Unit tests - isolated component testing (7 files)
├── Integration/       # Integration tests - component interaction (1 file)
├── E2E/              # End-to-end tests - full profile scenarios (1 file)
├── Helpers/          # Test utilities and templates
├── Fixtures/         # Test data and mock configurations
└── Coverage/         # Generated coverage reports (git-ignored)
```

### Test Categories

**Unit Tests** (`tests/Unit/`) - Fast, isolated, mocked dependencies:
- `Icons.Tests.ps1` - Icon fallback system
- `StatusMessage.Tests.ps1` - Status output & message segments
- `Logger.Tests.ps1` - Logging helpers
- `LinuxCompat.Tests.ps1` - Linux command compatibility
- `EnhancedTools.Tests.ps1` - Enhanced tool wrappers
- `FallbackBehavior.Tests.ps1` - Fallback when tools missing
- `TuiDemo.Tests.ps1` - TUI demo functionality

**Integration Tests** (`tests/Integration/`) - Component interactions:
- `LoggingFlow.Tests.ps1` - Icon → StatusMessage → Logger chain

**E2E Tests** (`tests/E2E/`) - Full profile scenarios:
- `ProfileLoad.Tests.ps1` - Smoke test - profile loads without errors

**See [tests/README.md](../tests/README.md) for detailed test documentation.**

---

## Philosophy

### Primary Goal: Regression Prevention

**User Story:**
> "As a developer, I want tests to run automatically before pushing, so I don't accidentally remove features that already worked."

**The Problem:**
oh-my-pwsh is a console solution with conditional logic for optional dependencies. It's easy to accidentally remove fallback handling for missing packages (bat, eza, ripgrep, fd, delta, fzf, zoxide, oh-my-stats) when developing on a machine where they're all installed.

**The Solution:**
Tests must verify behavior in ALL scenarios:
- ✅ When all tools are installed
- ✅ When some tools are missing
- ✅ When NO tools are installed
- ✅ When oh-my-stats is missing

### Core Principles

1. **Regression Prevention First** - Catch accidental removal of fallback code
2. **Fast Feedback** - Developers know immediately if they broke something
3. **High Confidence** - Tests give confidence to refactor and deploy
4. **Simple & Focused** - This is not a complex application, keep tests simple
5. **Pragmatic Coverage** - Focus on critical paths and edge cases

### What We Value

- ✅ **Testing missing dependencies** over only happy paths
- ✅ **Fast tests** over comprehensive slow tests
- ✅ **Clear failures** over cryptic error messages
- ✅ **Deterministic tests** over flaky tests
- ✅ **Meaningful coverage** over high percentages

---

## Test Architecture

### The Test Pyramid

```
        ┌─────────────┐
        │  E2E Tests  │  Few (5-10)
        │   Slow      │  Full scenarios
        └─────────────┘  Real environment
       ┌───────────────┐
       │ Integration   │  Some (20-30)
       │    Tests      │  Module interactions
       └───────────────┘  Controlled environment
     ┌───────────────────┐
     │   Unit Tests      │  Many (50-100+)
     │   Fast, Isolated  │  Single functions
     └───────────────────┘  Mocked dependencies
```

### Test Layers

#### Layer 1: Unit Tests
**Purpose:** Test individual functions in isolation

**Characteristics:**
- ⚡ **Very fast** (< 100ms each)
- 🔒 **Fully isolated** (all dependencies mocked)
- 🎯 **Focused** (one function per test file)
- 📊 **High coverage** (80-90% for core modules)

**Location:** `tests/Unit/`

**Example:**
```powershell
Describe "Get-FallbackIcon" {
    Context "When role is 'success'" {
        BeforeAll {
            Mock Test-NerdFontSupport { return $false }
        }

        It "Returns Unicode checkmark" {
            $result = Get-FallbackIcon -Role "success"
            $result | Should -Be "✓"
        }
    }

    Context "When Nerd Fonts are enabled" {
        BeforeAll {
            Mock Test-NerdFontSupport { return $true }
        }

        It "Returns Nerd Font icon" {
            $result = Get-FallbackIcon -Role "success"
            $result | Should -Be "󰄵"
        }
    }
}
```

#### Layer 2: Integration Tests
**Purpose:** Test how modules work together

**Characteristics:**
- ⏱️ **Fast** (< 500ms each)
- 🔄 **Real interactions** (minimal mocking)
- 📦 **Module-level** (multiple functions)
- 🎨 **Realistic scenarios**

**Location:** `tests/Integration/`

**Example:**
```powershell
Describe "Logging Flow Integration" {
    BeforeAll {
        # Load real modules
        . $PSScriptRoot/../../settings/icons.ps1
        . $PSScriptRoot/../../modules/status-output.ps1
        . $PSScriptRoot/../../modules/logger.ps1

        # Mock only console output
        Mock Write-Host {}
    }

    It "Write-InstallHint uses icon system correctly" {
        Write-InstallHint -Tool "bat" -Description "cat" -InstallCommand "scoop install bat"

        # Verify flow: InstallHint → StatusMessage → FallbackIcon
        Should -Invoke Write-Host -ParameterFilter { $Object -eq "!" }
        Should -Invoke Write-Host -ParameterFilter { $Object -eq "bat" }
    }
}
```

#### Layer 3: E2E Tests
**Purpose:** Test complete user scenarios

**Characteristics:**
- 🐌 **Slower** (< 5s each)
- 🌐 **Real environment** (actual profile load)
- 👤 **User perspective** (how users interact)
- 🎭 **Full scenarios** (end-to-end flows)

**Location:** `tests/E2E/`

**Example:**
```powershell
Describe "Profile Load E2E" {
    BeforeAll {
        # Create temp profile environment
        $tempDir = New-Item -ItemType Directory -Path (Join-Path $TestDrive "profile")
        Copy-Item -Recurse "$PSScriptRoot/../../*" $tempDir
    }

    It "Loads profile without errors" {
        { . "$tempDir/profile.ps1" } | Should -Not -Throw
    }

    It "All core modules are sourced" {
        . "$tempDir/profile.ps1"
        Get-Command Write-StatusMessage -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Get-FallbackIcon -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It "Help command works" {
        . "$tempDir/profile.ps1"
        { Show-OhMyPwshHelp } | Should -Not -Throw
    }
}
```

---

## Coverage Strategy

### Coverage Targets by Component

| Tier | Components | Line Coverage | Critical |
|------|-----------|---------------|----------|
| **Tier 1** | Core functions (icons, status-output) | ≥ 90% | Yes |
| **Tier 2** | Helpers (logger, linux-compat) | ≥ 80% | Yes |
| **Tier 3** | Feature modules (enhanced-tools) | ≥ 70% | No |
| **Tier 4** | Orchestration (profile.ps1) | ≥ 60% | No |

**Overall Target:** ≥ 75% line coverage

See [ADR-003: Coverage Targets](../adr/003-coverage-targets.md) for detailed rationale.

### What We DON'T Cover

Some code is intentionally excluded:
- Test files themselves (`*.Tests.ps1`)
- Manual test scripts (`test-*.ps1`)
- Config templates (`config.example.ps1`)
- Documentation
- Code marked with `# SKIP-COVERAGE`

### Coverage Metrics

We track three metrics:

1. **Line Coverage** - What % of lines are executed
2. **Branch Coverage** - What % of if/else paths are tested
3. **Function Coverage** - What % of functions are tested

**Primary metric:** Line coverage (easier to measure, good proxy)

---

## Test Execution

### Running Tests Locally

```powershell
# Run all tests
./scripts/Invoke-Tests.ps1

# Run specific type
./scripts/Invoke-Tests.ps1 -Type Unit
./scripts/Invoke-Tests.ps1 -Type Integration
./scripts/Invoke-Tests.ps1 -Type E2E

# With coverage
./scripts/Invoke-Tests.ps1 -Coverage

# Fast mode (for git hooks)
./scripts/Invoke-Tests.ps1 -Type Unit -Fast

# Watch mode (re-run on file change)
./scripts/Invoke-Tests.ps1 -Watch

# Filter by name
./scripts/Invoke-Tests.ps1 -Filter "Icon*"
```

### Test Runner (Invoke-Tests.ps1)

```powershell
<#
.SYNOPSIS
    Run tests for oh-my-pwsh

.PARAMETER Type
    Type of tests to run: Unit, Integration, E2E, All

.PARAMETER Coverage
    Generate code coverage report

.PARAMETER Fast
    Fast mode - parallel execution, no coverage

.PARAMETER Watch
    Watch mode - re-run tests on file changes

.PARAMETER Filter
    Run only tests matching filter
#>

param(
    [ValidateSet('Unit', 'Integration', 'E2E', 'All')]
    [string]$Type = 'All',

    [switch]$Coverage,
    [switch]$Fast,
    [switch]$Watch,
    [string]$Filter = "*"
)

# Configure Pester
$config = [PesterConfiguration]::Default

# Set test path based on type
switch ($Type) {
    'Unit'        { $config.Run.Path = "tests/Unit" }
    'Integration' { $config.Run.Path = "tests/Integration" }
    'E2E'         { $config.Run.Path = "tests/E2E" }
    'All'         { $config.Run.Path = "tests" }
}

# Fast mode optimizations
if ($Fast) {
    $config.Run.Parallel = $true
    $config.CodeCoverage.Enabled = $false
}

# Coverage configuration
if ($Coverage) {
    $config.CodeCoverage.Enabled = $true
    $config.CodeCoverage.Path = @(
        "settings/icons.ps1",
        "modules/status-output.ps1",
        "modules/logger.ps1",
        "modules/*.ps1"
    )
    $config.CodeCoverage.OutputFormat = "JaCoCo"
    $config.CodeCoverage.OutputPath = "tests/Coverage/coverage.xml"
}

# Run tests
$result = Invoke-Pester -Configuration $config

# Check results
if ($result.FailedCount -gt 0) {
    Write-Error "Tests failed: $($result.FailedCount) failures"
    exit 1
}

# Check coverage threshold
if ($Coverage -and $result.CodeCoverage.CoveragePercent -lt 75) {
    Write-Warning "Coverage $($result.CodeCoverage.CoveragePercent)% is below target 75%"
    exit 1
}

exit 0
```

---

## CI/CD Integration

### GitHub Actions Workflow

**File:** `.github/workflows/tests.yml`

**Status:** ✅ Implemented (Phase 3)

Tests run automatically on:
- 📤 Every push to `main` branch
- 🔀 Every pull request to `main`

**Test Matrix:**
- 🪟 Windows (windows-latest) + 🐧 Ubuntu (ubuntu-latest)
- 💻 PowerShell 7.4 and 7.3
- 🔄 4 combinations total (fail-fast: false)

**Workflow Steps:**
1. ✅ Checkout code
2. ✅ Setup PowerShell (specific version)
3. ✅ Display PowerShell version info
4. ✅ Install Pester 5.5.0+ (`Install-TestDeps.ps1`)
5. ✅ Run tests with coverage (`Invoke-Tests.ps1 -Coverage`)
6. ✅ Display coverage report (`Show-Coverage.ps1`)
7. ✅ Upload coverage artifact (30-day retention)
8. ✅ Check coverage threshold (fail if < 30% critical minimum)

**Coverage Reporting:**
- Coverage reports uploaded as artifacts (per OS + PS version)
- Coverage percentage displayed in action logs
- Codecov integration optional (see [CODECOV-SETUP.md](./CODECOV-SETUP.md))

**Badge:**
```markdown
![Tests](https://github.com/zentala/pwsh-profile/actions/workflows/tests.yml/badge.svg)
```

### Quality Gates

**CI fails if:**
- ❌ Any test fails
- ❌ Coverage < 30% (critical threshold)
- ❌ PowerShell version incompatibility

**CI provides:**
- ✅ Coverage percentage in logs
- ✅ Test execution time
- ✅ Coverage artifacts for review
- ✅ Matrix results for all OS/PS combinations

**Future quality gates:**
- ⏸️ Coverage < 75% target (warn only)
- ⏸️ PSScriptAnalyzer errors (see `.future.md`)
- ⏸️ Coverage regression detection

---

## Git Hooks (Optional)

**Status:** ✅ Implemented (Phase 4)

### Pre-commit Hook

**Installation:**
```powershell
./scripts/Install-GitHooks.ps1
```

**What it does:**
- Runs **unit tests only** (fast, typically 10-20s)
- Blocks commit if tests fail
- Shows clear error messages with bypass instructions
- Auto-displays test results before commit

**Hook Location:**
- Source: `.github/hooks/pre-commit`
- Installed to: `.git/hooks/pre-commit`

**Bypass When Needed:**
```bash
git commit --no-verify -m "WIP: quick save"
```

**Example Output:**
```
🧪 Running pre-commit tests...
   (bypass with: git commit --no-verify)

✅ All unit tests passed in 12.3s
```

**Uninstall:**
```powershell
Remove-Item .git/hooks/pre-commit
```

**Philosophy:** Helpful but not mandatory. CI is the ultimate quality gate.

See [ADR-004: Git Hooks Optional](../adr/004-git-hooks-optional.md) for rationale.

---

## Test Infrastructure

### Folder Structure

```
tests/
├── Unit/                      # Fast, isolated tests
│   ├── Icons.Tests.ps1
│   ├── StatusMessage.Tests.ps1
│   ├── Logger.Tests.ps1
│   └── ...
│
├── Integration/               # Module interactions
│   ├── LoggingFlow.Tests.ps1
│   ├── ToolDetection.Tests.ps1
│   └── ...
│
├── E2E/                       # End-to-end scenarios
│   ├── ProfileLoad.Tests.ps1
│   ├── HelpSystem.Tests.ps1
│   └── ...
│
├── Fixtures/                  # Test data
│   ├── config-valid.ps1
│   ├── config-invalid.ps1
│   └── ...
│
├── Helpers/                   # Test utilities
│   ├── TestHelpers.ps1       # Common test functions
│   ├── Mocks.ps1             # Reusable mocks
│   ├── Assertions.ps1        # Custom assertions
│   └── Templates/            # Test file templates
│
└── Coverage/                  # Generated reports (gitignored)
    ├── coverage.xml
    └── coverage.html
```

### Test Helpers

**Location:** `tests/Helpers/TestHelpers.ps1`

```powershell
# Mock console output
function Mock-ConsoleOutput {
    Mock Write-Host {}
    Mock Write-Output {}
}

# Assert output contains text
function Assert-OutputContains {
    param([string]$Expected)
    Should -Invoke Write-Host -ParameterFilter { $Object -like "*$Expected*" }
}

# Create temp config
function New-TempConfig {
    param([hashtable]$Settings)

    $tempConfig = Join-Path $TestDrive "config.ps1"
    $Settings.GetEnumerator() | ForEach-Object {
        "`$$($_.Key) = $($_.Value)" | Out-File $tempConfig -Append
    }
    return $tempConfig
}
```

---

## Test Data Strategy

### The Critical Test Scenarios

**Primary requirement:** Test behavior when dependencies are MISSING.

oh-my-pwsh must work correctly in these scenarios:
1. **All tools installed** - bat, eza, ripgrep, fd, delta, fzf, zoxide, oh-my-stats
2. **Some tools missing** - e.g., bat installed but eza missing
3. **No enhanced tools** - only native PowerShell commands available
4. **oh-my-stats missing** - profile still loads without errors

### Static Fixtures

**Location:** `tests/Fixtures/`

**Purpose:** Pre-defined test configurations stored in repository

**Examples:**
```powershell
# tests/Fixtures/config-all-tools.ps1
# Simulates machine with all tools installed
$global:OhMyPwsh_UseNerdFonts = $false
# Mock all Get-Command calls to return true

# tests/Fixtures/config-no-tools.ps1
# Simulates machine with NO tools installed
$global:OhMyPwsh_UseNerdFonts = $false
# Mock all Get-Command calls to return $null

# tests/Fixtures/config-partial-tools.ps1
# Simulates some tools installed
# bat ✓, eza ✗, ripgrep ✓, fd ✗, etc.
```

### Builder Pattern for Test Configs

**Purpose:** Flexible, composable test configuration generation

**Implementation:**
```powershell
# tests/Helpers/ConfigBuilder.ps1

function New-TestConfig {
    [CmdletBinding()]
    param()

    return @{
        UseNerdFonts = $false
        Tools = @{}
    }
}

function Add-NerdFonts {
    param([hashtable]$Config)
    $Config.UseNerdFonts = $true
    return $Config
}

function Add-Tools {
    param(
        [hashtable]$Config,
        [string[]]$ToolNames
    )
    foreach ($tool in $ToolNames) {
        $Config.Tools[$tool] = $true
    }
    return $Config
}

# Usage in tests:
$config = New-TestConfig | Add-Tools -ToolNames @("bat", "eza")
$config = New-TestConfig | Add-NerdFonts | Add-Tools -ToolNames @("bat", "eza", "ripgrep")
$config = New-TestConfig  # No tools at all
```

### Testing Missing Dependencies

**Critical test cases:**

```powershell
Describe "Enhanced Tools Fallback" {
    Context "When bat is NOT installed" {
        BeforeAll {
            Mock Get-Command { $null } -ParameterFilter { $Name -eq "bat" }
        }

        It "Falls back to Get-Content" {
            cat somefile.txt
            # Should use Get-Content, not throw error
        }

        It "Shows warning message" {
            # Should invoke Write-StatusMessage with warning
            Should -Invoke Write-StatusMessage -ParameterFilter {
                $Segments.Role -contains "warning"
            }
        }
    }

    Context "When NO tools are installed" {
        BeforeAll {
            Mock Get-Command { $null }  # All commands return null
        }

        It "Profile loads without errors" {
            { . $PSScriptRoot/../../profile.ps1 } | Should -Not -Throw
        }

        It "Shows multiple warning messages" {
            # Should show warnings for each missing tool
        }

        It "All fallback functions work" {
            # Test cat, ls, grep, find, etc.
        }
    }
}
```

### Install Script Testing

**Requirement:** Install script must match profile requirements.

**Link:** If install script installs tools, profile must handle them being missing.

```powershell
Describe "Install Script Consistency" {
    It "Lists all optional dependencies" {
        $installScript = Get-Content scripts/install-dependencies.ps1 -Raw

        # Verify each tool has fallback in profile
        $tools = @("bat", "eza", "ripgrep", "fd", "delta", "fzf", "zoxide")
        foreach ($tool in $tools) {
            $installScript | Should -Match $tool
            # And verify fallback exists in profile
            $profile = Get-Content profile.ps1 -Raw
            $profile | Should -Match "if.*Get-Command $tool"
        }
    }
}
```

### Test Data Management

**Principles:**
- ✅ Static fixtures committed to repository
- ✅ Generated configs via builder pattern
- ✅ Test results logged to console (no external storage)
- ✅ Coverage reports in `tests/Coverage/` (gitignored)
- ❌ No external test data services
- ❌ No database connections
- ❌ No API calls (mock external dependencies)

---

## Developer Workflow

### Writing a New Test

**✅ Phase 4: Developer Experience Tools Available**

1. **Generate test file from template:**
   ```powershell
   ./scripts/New-TestFile.ps1 -Path modules/my-module.ps1
   # Creates tests/Unit/MyModule.Tests.ps1 with template
   ```

2. **Write tests using AAA pattern:**
   ```powershell
   It "Does something correctly" {
       # Arrange
       $input = "test"
       Mock Get-Something { return "mocked" }

       # Act
       $result = Invoke-MyFunction -Input $input

       # Assert
       $result | Should -Be "expected"
       Should -Invoke Get-Something -Times 1
   }
   ```

3. **Run tests in watch mode (auto-rerun on changes):**
   ```powershell
   ./scripts/Invoke-Tests.ps1 -Type Unit -Watch
   # Watches for file changes and re-runs tests automatically
   ```

4. **Or run tests once with filter:**
   ```powershell
   ./scripts/Invoke-Tests.ps1 -Filter "MyModule*"
   ```

5. **Check coverage:**
   ```powershell
   ./scripts/Invoke-Tests.ps1 -Coverage
   ./scripts/Show-Coverage.ps1  # Display coverage percentage
   ```

### Developer Tools (Phase 4)

**Test Scaffolding:**
```powershell
# Generate new test file
./scripts/New-TestFile.ps1 -Path modules/logger.ps1
./scripts/New-TestFile.ps1 -Path modules/git-helpers.ps1 -Type Integration
```

**Watch Mode:**
```powershell
# Auto-rerun tests on file changes
./scripts/Invoke-Tests.ps1 -Type Unit -Watch
# Edit files → tests rerun automatically
# Press Ctrl+C to stop
```

**Git Hooks (Optional):**
```powershell
# Install pre-commit hook (runs unit tests before commit)
./scripts/Install-GitHooks.ps1

# Bypass when needed
git commit --no-verify -m "WIP: quick save"
```

### Test-Driven Development (TDD)

Recommended workflow:

1. **Red** - Write failing test
   ```powershell
   It "Returns success icon" {
       $result = Get-FallbackIcon -Role "success"
       $result | Should -Be "✓"
   }
   # Test fails - function doesn't exist yet
   ```

2. **Green** - Make it pass (minimal code)
   ```powershell
   function Get-FallbackIcon {
       param([string]$Role)
       return "✓"
   }
   # Test passes
   ```

3. **Refactor** - Improve code
   ```powershell
   function Get-FallbackIcon {
       param([string]$Role)

       $icons = @{
           success = "✓"
           warning = "!"
           # ...
       }
       return $icons[$Role]
   }
   # Test still passes
   ```

---

## Best Practices

### DO ✅

- **Write tests first** (TDD) when adding new features
- **Keep tests simple** - one logical assertion per test
- **Use descriptive names** - "It should return X when Y"
- **Mock external dependencies** - filesystem, network, etc.
- **Test edge cases** - null, empty, invalid inputs
- **Keep tests fast** - avoid `Start-Sleep`, real network calls
- **Make tests deterministic** - no randomness, no time dependencies
- **Clean up after tests** - use `BeforeAll`/`AfterAll`

### DON'T ❌

- **Don't test implementation details** - test behavior, not internals
- **Don't write flaky tests** - if it fails 1/100 times, it's broken
- **Don't mock everything** - integration tests need real interactions
- **Don't ignore failing tests** - fix or delete them
- **Don't skip tests** - unless temporary and documented
- **Don't write tests just for coverage** - write meaningful tests
- **Don't test framework code** - trust Pester, PowerShell

### Naming Conventions

**Test files:**
```
<ModuleName>.Tests.ps1
Icons.Tests.ps1          ✅
Icon.Tests.ps1           ❌ (singular)
test-icons.ps1           ❌ (wrong pattern)
```

**Test descriptions:**
```powershell
# Good ✅
It "Returns checkmark for success role" { }
It "Throws when role is invalid" { }
It "Uses Unicode by default" { }

# Bad ❌
It "Works" { }
It "Test 1" { }
It "Should work correctly" { }  # "Should" is redundant in Pester
```

---

## Troubleshooting

### Tests Pass Locally but Fail in CI

**Causes:**
- Environmental differences (paths, OS, PS version)
- Undeclared dependencies
- Test order dependency
- Timing issues

**Solutions:**
- Use `$TestDrive` for temp files, not hardcoded paths
- Mock all external dependencies
- Ensure tests can run in any order
- Avoid time-based assertions

### Slow Test Suite

**Causes:**
- Too many E2E tests
- Not using mocks
- Real network/disk I/O
- Sequential execution

**Solutions:**
- Move more tests to unit layer
- Mock external calls
- Use in-memory fixtures
- Enable parallel execution (`-Parallel`)

### Flaky Tests

**Causes:**
- Time-based logic
- Shared state between tests
- Race conditions
- External service dependencies

**Solutions:**
- Use deterministic test data
- Isolate tests (`BeforeEach`, not `BeforeAll` for state)
- Mock time-dependent code
- Never depend on external services

### Low Coverage Despite Many Tests

**Causes:**
- Tests not exercising critical paths
- Too much test duplication
- Testing wrong layer (too many E2E, not enough unit)

**Solutions:**
- Review coverage report to find gaps
- Focus on untested branches
- Add unit tests for core logic
- Use coverage-driven test writing

---

## Future Enhancements

### Planned Improvements

1. **Mutation Testing**
   - Verify test quality by mutating code
   - Tests should fail when code changes

2. **Performance Benchmarks**
   - Track profile load time
   - Detect performance regressions

3. **Visual Regression Testing**
   - Screenshot comparison for help output
   - Terminal color scheme verification

4. **Contract Testing**
   - Test module interfaces
   - Ensure backward compatibility

5. **Property-Based Testing**
   - Generate random test inputs
   - Find edge cases automatically

---

## Resources

### External Documentation
- [Pester Documentation](https://pester.dev/)
- [Pester Best Practices](https://pester.dev/docs/usage/best-practices)
- [Test Pyramid](https://martinfowler.com/articles/practical-test-pyramid.html)

### Internal Documentation
- [TESTING-GUIDE.md](./TESTING-GUIDE.md) - How to write tests (to be created)
- [CLAUDE.md](../CLAUDE.md) - Development guidelines
- [ADR folder](../adr/) - Architecture decisions

### Related Tasks
- [005-testing-infrastructure.md](../todo/005-testing-infrastructure.md) - Implementation task

---

## Glossary

- **AAA Pattern** - Arrange, Act, Assert test structure
- **Code Coverage** - % of code executed by tests
- **E2E** - End-to-End testing
- **Flaky Test** - Test that passes/fails non-deterministically
- **Mock** - Fake implementation of a dependency
- **Pester** - PowerShell testing framework
- **TDD** - Test-Driven Development
- **Test Pyramid** - More unit tests, fewer E2E tests
- **Unit Test** - Test of a single function in isolation
