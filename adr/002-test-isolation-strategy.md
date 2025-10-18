# ADR-002: Test Isolation Strategy

**Status:** Accepted
**Date:** 2025-10-18
**Deciders:** Paweł Żentała, Claude (Solution Architect)

## Context

When testing PowerShell modules, we need to decide how much isolation to enforce between tests and production code. Too much isolation makes tests brittle and mock-heavy. Too little isolation makes tests slow and prone to environmental issues.

### Key Questions
1. Should unit tests mock all dependencies?
2. Should we use `InModuleScope` for testing private functions?
3. How do we handle external dependencies (filesystem, network, registry)?
4. What's the boundary between unit and integration tests?

## Decision

**We adopt a pragmatic isolation strategy with three test layers:**

### Layer 1: Unit Tests (High Isolation)
- **Scope**: Single function or cmdlet
- **Dependencies**: All external calls mocked
- **Environment**: No filesystem, network, or system calls
- **Speed**: < 100ms per test
- **Location**: `tests/Unit/`

**Rules:**
- Mock `Write-Host`, `Write-Output`, console output
- Mock `Get-Command`, `Test-Path`, filesystem checks
- Mock external module calls
- Use `InModuleScope` only when testing private functions
- No `Start-Process`, `Invoke-WebRequest`, registry access

### Layer 2: Integration Tests (Moderate Isolation)
- **Scope**: Multiple functions interacting
- **Dependencies**: Real implementations where safe
- **Environment**: Controlled test fixtures
- **Speed**: < 500ms per test
- **Location**: `tests/Integration/`

**Rules:**
- Use real functions within same module
- Mock only external modules (PSFzf, posh-git)
- Use test fixtures for config files
- No network calls, real filesystem OK (temp dirs)

### Layer 3: E2E Tests (Minimal Isolation)
- **Scope**: Full profile load scenarios
- **Dependencies**: Real environment (but sandboxed)
- **Environment**: Clean temp profile directory
- **Speed**: < 5s per test
- **Location**: `tests/E2E/`

**Rules:**
- Load actual profile.ps1
- Use real config (in temp directory)
- Real module imports (but check availability first)
- Can skip if dependencies missing

## Consequences

### Positive ✅

- **Clear Boundaries**: Each layer has well-defined purpose
- **Fast Feedback**: Unit tests give instant feedback (< 30s for full suite)
- **Confidence**: Integration tests catch interaction bugs
- **Realistic**: E2E tests validate actual user scenarios
- **Maintainable**: Not over-mocked, easier to understand
- **Debuggable**: Can run E2E tests locally to reproduce issues

### Negative ⚠️

- **More Test Code**: Need to write mocks for unit tests
- **Duplication**: Some scenarios tested at multiple layers
- **Maintenance**: Mocks need updating when implementations change
- **Gaps**: Possible to pass unit tests but fail integration

### Neutral ℹ️

- **Test Count**: Expect more unit tests than integration, very few E2E
- **Coverage**: Unit tests drive coverage metrics

## Implementation Guidelines

### Unit Test Example
```powershell
Describe "Get-FallbackIcon" {
    BeforeAll {
        # Mock dependencies
        Mock Test-NerdFontSupport { return $false }
    }

    Context "When role is 'success'" {
        It "Returns Unicode checkmark" {
            # No real dependencies, pure function test
            $result = Get-FallbackIcon -Role "success"
            $result | Should -Be "✓"
        }
    }

    Context "When Nerd Fonts enabled" {
        It "Returns Nerd Font icon" {
            Mock Test-NerdFontSupport { return $true }
            $result = Get-FallbackIcon -Role "success"
            $result | Should -Be "󰄵"
        }
    }
}
```

### Integration Test Example
```powershell
Describe "Write-InstallHint Integration" {
    BeforeAll {
        # Load real modules
        . $PSScriptRoot/../../settings/icons.ps1
        . $PSScriptRoot/../../modules/status-output.ps1
        . $PSScriptRoot/../../modules/logger.ps1

        # Mock only output
        Mock Write-Host {}
    }

    It "Uses icon system correctly" {
        Write-InstallHint -Tool "bat" -Description "cat" -InstallCommand "scoop install bat"

        # Verify icon function was called
        Should -Invoke Write-Host -ParameterFilter { $Object -eq "!" }
    }
}
```

### E2E Test Example
```powershell
Describe "Profile Load E2E" {
    BeforeAll {
        # Create temp profile directory
        $tempDir = New-Item -ItemType Directory -Path (Join-Path $TestDrive "profile")
        Copy-Item -Recurse "$PSScriptRoot/../../*" $tempDir

        # Set environment
        $env:PSModulePath = "$tempDir\modules;$env:PSModulePath"
    }

    It "Loads profile without errors" {
        # Load actual profile
        { . "$tempDir/profile.ps1" } | Should -Not -Throw
    }

    It "Help command works" {
        . "$tempDir/profile.ps1"
        { Show-OhMyPwshHelp } | Should -Not -Throw
    }
}
```

## Alternatives Considered

### 1. Pure Unit Testing (100% Isolation)
- **Pros**: Fastest, most isolated
- **Cons**: Over-mocking, brittle tests, no confidence in integration
- **Verdict**: ❌ Too extreme for PowerShell modules

### 2. Integration-First Testing
- **Pros**: More realistic, less mocking
- **Cons**: Slower, harder to debug failures, environmental dependencies
- **Verdict**: ❌ Loses fast feedback loop

### 3. E2E Only
- **Pros**: Tests real scenarios, minimal mocking
- **Cons**: Very slow, hard to pinpoint failures, flaky
- **Verdict**: ❌ Insufficient for TDD

### 4. Sociable Unit Tests (London School)
- **Pros**: Tests behavior, less coupling to implementation
- **Cons**: Still requires clear boundaries
- **Verdict**: ⚠️ Considered, but not significantly different from our approach

## Related

### Tasks
- [005-testing-infrastructure.md](../todo/005-testing-infrastructure.md) - Implementation task

### Documentation
- [TESTING-STRATEGY.md](../docs/TESTING-STRATEGY.md) - Overall strategy
- [TESTING-GUIDE.md](../docs/TESTING-GUIDE.md) - How to write each type

### Other ADRs
- [ADR-001](./001-pester-test-framework.md) - Test framework choice
- [ADR-003](./003-coverage-targets.md) - Coverage expectations

## References

- [Test Pyramid](https://martinfowler.com/articles/practical-test-pyramid.html)
- [Pester Mocking Guide](https://pester.dev/docs/usage/mocking)
- [xUnit Test Patterns](http://xunitpatterns.com/Test%20Double.html)
