# ADR-001: Pester as Test Framework

**Status:** Accepted
**Date:** 2025-10-18
**Deciders:** Paweł Żentała, Claude (Solution Architect)

## Context

We need a robust testing framework for oh-my-pwsh to ensure code quality, prevent regressions, and enable safe refactoring. PowerShell has several testing options, but we need to choose one that balances functionality, community support, and ease of use.

### Requirements
- Must support unit, integration, and E2E tests
- Must have mocking capabilities
- Must generate code coverage reports
- Must integrate with CI/CD (GitHub Actions)
- Must be actively maintained
- Should be PowerShell-native (not a port of another framework)

## Decision

**We will use Pester 5.x as our primary test framework.**

Specifically:
- **Version**: Pester 5.5.0 or later
- **Installation**: Via PowerShell Gallery (`Install-Module Pester`)
- **Scope**: All test types (unit, integration, E2E)

## Consequences

### Positive ✅

- **Mature & Stable**: Pester is the de-facto standard for PowerShell testing (10+ years)
- **Built-in Mocking**: Native support for `Mock`, `InModuleScope`, `Should -Invoke`
- **Code Coverage**: Built-in coverage analysis via `-CodeCoverage` parameter
- **CI/CD Integration**: Well-documented integration with GitHub Actions, Azure DevOps
- **Large Community**: Extensive documentation, examples, StackOverflow support
- **PowerShell Native**: Written in PowerShell, understands PowerShell semantics
- **Assertions**: Rich assertion library (`Should -Be`, `Should -Throw`, etc.)
- **JUnit XML**: Generates test reports compatible with CI systems

### Negative ⚠️

- **Learning Curve**: Pester 5.x has different syntax than 4.x (migration needed if upgrading)
- **Breaking Changes**: v4 → v5 was a breaking change (but we start fresh)
- **Performance**: Can be slow for very large test suites (mitigated by parallelization)
- **Mocking Limitations**: Some advanced mocking scenarios are tricky
- **Windows-First**: While cross-platform, some features work better on Windows

### Neutral ℹ️

- **Dependency**: Adds external dependency (but acceptable for dev/CI)
- **Version Management**: Need to ensure Pester version consistency across environments

## Alternatives Considered

### 1. PSate
- **Pros**: Simpler syntax, faster for small suites
- **Cons**: Abandoned (last update 2016), no mocking, no coverage
- **Verdict**: ❌ Not maintained

### 2. Custom Test Framework
- **Pros**: Full control, tailored to our needs
- **Cons**: Reinventing the wheel, maintenance burden, no community
- **Verdict**: ❌ Overkill

### 3. PSScriptAnalyzer Only
- **Pros**: Already commonly used, catches static issues
- **Cons**: Not a test framework, no runtime testing, no coverage
- **Verdict**: ❌ Complementary tool, not a replacement

### 4. Invoke-Pester (Pester 4.x)
- **Pros**: Older, more examples online
- **Cons**: Deprecated, no new features, slower
- **Verdict**: ❌ Superseded by Pester 5.x

## Implementation Notes

### Installation
```powershell
# Install Pester 5.x
Install-Module -Name Pester -MinimumVersion 5.5.0 -Force -SkipPublisherCheck

# Verify version
Get-Module Pester -ListAvailable
```

### Basic Test Structure
```powershell
BeforeAll {
    # Load module under test
    . $PSScriptRoot/../../modules/status-output.ps1
}

Describe "Write-StatusMessage" {
    Context "When given a simple string message" {
        It "Should output the message with icon" {
            # Arrange
            Mock Write-Host {}

            # Act
            Write-StatusMessage -Role "success" -Message "Test"

            # Assert
            Should -Invoke Write-Host -Times 4 # icon, brackets, message
        }
    }
}
```

### Coverage Example
```powershell
$config = [PesterConfiguration]::Default
$config.CodeCoverage.Enabled = $true
$config.CodeCoverage.Path = "modules/*.ps1"
$config.CodeCoverage.OutputFormat = "JaCoCo"

Invoke-Pester -Configuration $config
```

## Related

### Tasks
- [005-testing-infrastructure.md](../todo/005-testing-infrastructure.md) - Implementation task

### Documentation
- [TESTING-STRATEGY.md](../docs/TESTING-STRATEGY.md) - Overall testing strategy
- [TESTING-GUIDE.md](../docs/TESTING-GUIDE.md) - How to write tests (to be created)

### Other ADRs
- [ADR-002](./002-test-isolation-strategy.md) - How we structure tests
- [ADR-003](./003-coverage-targets.md) - Coverage requirements

## References

- [Pester Documentation](https://pester.dev/)
- [Pester GitHub](https://github.com/pester/Pester)
- [Pester 5 Migration Guide](https://pester.dev/docs/migrations/v3-to-v4)
