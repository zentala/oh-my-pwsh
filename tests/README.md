# Tests Directory

Automated tests for oh-my-pwsh PowerShell profile using Pester testing framework.

## Quick Start

```powershell
# Run all tests with coverage
.\scripts\Invoke-Tests.ps1 -Coverage

# Run specific test suite
.\scripts\Invoke-Tests.ps1 -TestPath tests/Unit/Icons.Tests.ps1

# Fast mode (no coverage)
.\scripts\Invoke-Tests.ps1
```

## Test Structure

```
tests/
├── Unit/              # Unit tests - isolated component testing
├── Integration/       # Integration tests - component interaction
├── E2E/              # End-to-end tests - full profile scenarios
├── Helpers/          # Test utilities and templates
├── Fixtures/         # Test data and mock configurations
└── Coverage/         # Code coverage reports (generated)
```

## Test Categories

### Unit Tests (`tests/Unit/`)

Fast, isolated tests for individual components. Mock all external dependencies.

| Test File | What It Tests | Coverage Target |
|-----------|---------------|-----------------|
| `Icons.Tests.ps1` | Icon fallback system (Unicode/NerdFont) | 90% (Tier 1) |
| `StatusMessage.Tests.ps1` | Colored status output and message segments | 90% (Tier 1) |
| `Logger.Tests.ps1` | Logging helpers (Write-InstallHint, etc.) | 80% (Tier 2) |
| `LinuxCompat.Tests.ps1` | Linux command compatibility layer | 80% (Tier 2) |
| `EnhancedTools.Tests.ps1` | Enhanced tool wrappers (bat, eza, etc.) | 70% (Tier 3) |
| `FallbackBehavior.Tests.ps1` | Fallback when tools are missing | 70% (Tier 3) |
| `TuiDemo.Tests.ps1` | TUI demo script functionality | 70% (Tier 3) |

**Key Principle:** Every enhanced tool MUST have fallback tests for when the tool is missing.

### Integration Tests (`tests/Integration/`)

Tests for component interactions without full profile load.

| Test File | What It Tests |
|-----------|---------------|
| `LoggingFlow.Tests.ps1` | Icon system → StatusMessage → Logger chain |

### End-to-End Tests (`tests/E2E/`)

Full profile scenarios testing real-world usage.

| Test File | What It Tests |
|-----------|---------------|
| `ProfileLoad.Tests.ps1` | Smoke test - profile loads without errors |

## Test Helpers

### `Helpers/TestHelpers.ps1`

Shared test utilities:
- Mock setup functions
- Assertion helpers
- Common test data

### `Helpers/Templates/`

Templates for creating new tests:
- `Unit.Tests.ps1.template` - Unit test skeleton

## Test Fixtures

### `Fixtures/`

Mock configurations for testing different scenarios:
- `config-all-tools.ps1` - All enhanced tools available
- `config-no-tools.ps1` - No enhanced tools (pure fallback)
- `config-partial-tools.ps1` - Some tools available, some missing

## Running Tests

### Local Development

```powershell
# Before committing (fast)
.\scripts\Invoke-Tests.ps1

# Weekly/before PR (with coverage)
.\scripts\Invoke-Tests.ps1 -Coverage
```

### Pre-commit Hook (Optional)

```powershell
# Install git hook (optional, runs tests before commit)
.\scripts\Install-GitHooks.ps1
```

Hook runs fast mode (no coverage) to keep commits quick.

### CI/CD Pipeline

GitHub Actions runs on every push:
- Full test suite with coverage
- Coverage must be ≥75%
- All tests must pass

## Coverage Targets

**Overall:** ≥75% line coverage

**By Tier:**
- Tier 1 (core): 90% - icons, status output
- Tier 2 (helpers): 80% - logger, linux-compat
- Tier 3 (features): 70% - enhanced tools, demos
- Tier 4 (orchestration): 60% - profile.ps1

See [TESTING-STRATEGY.md](../docs/TESTING-STRATEGY.md) for details.

## Writing Tests

### Unit Test Example

```powershell
BeforeAll {
    # Import module under test
    . "$PSScriptRoot/../../modules/status-output.ps1"
}

Describe "Write-StatusMessage" {
    Context "When tool is missing" {
        BeforeAll {
            Mock Get-Command { $null }
        }

        It "Shows warning icon" {
            # Test implementation
        }

        It "Falls back gracefully" {
            # Test implementation
        }
    }
}
```

### Key Testing Principles

1. **Test fallbacks** - Every feature MUST work without enhanced tools
2. **Mock external calls** - No real Git, network, or tool execution in unit tests
3. **Fast tests** - Unit tests should run in milliseconds
4. **Descriptive names** - Test names should explain what breaks when they fail

## Troubleshooting

### Tests fail locally but pass in CI
- Check PowerShell version (requires 7.x)
- Clear mock state: restart PowerShell session

### Coverage is lower than expected
- Check if fallback paths are tested
- Verify BeforeAll/AfterAll hooks run

### "Cannot find module" errors
- Tests use dot-sourcing (`. $PSScriptRoot/...`)
- Ensure paths are relative to test file location

## Related Documentation

- [TESTING-STRATEGY.md](../docs/TESTING-STRATEGY.md) - Full testing strategy and rationale
- [ADR-001](../adr/001-pester-test-framework.md) - Why Pester?
- [ADR-002](../adr/002-test-isolation-strategy.md) - Test isolation approach
- [ADR-003](../adr/003-coverage-targets.md) - Coverage target decisions
