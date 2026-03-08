# Tests

Automated tests for oh-my-pwsh using Pester framework.

## What We Test

**Primary Goal:** Regression prevention - ensure profile works with or without enhanced tools.

**Critical Scenarios:**
- ✅ All tools installed (bat, eza, ripgrep, fd, delta, fzf, zoxide)
- ✅ Some tools missing
- ✅ No enhanced tools (pure PowerShell fallback)
- ✅ Profile loads without errors

## Test Structure

```
tests/
├── Unit/              # Component isolation (7 files)
├── Integration/       # Component interaction (1 file)
├── E2E/              # Full profile scenarios (1 file)
├── Helpers/          # Test utilities
└── Fixtures/         # Mock configurations
```

**170 tests** | **≥75% coverage** | **All must pass in CI**

## For Developers

See [CLAUDE.md](../CLAUDE.md#testing) for:
- How to run tests
- How to write tests
- Test file descriptions
- Coverage targets by tier
- Pre-commit hooks
- CI/CD integration

## Related Docs

- [TESTING-STRATEGY.md](../docs/TESTING-STRATEGY.md) - Full strategy and rationale
- [ADR-001](../adr/001-pester-test-framework.md) - Why Pester?
- [ADR-002](../adr/002-test-isolation-strategy.md) - Test isolation
- [ADR-003](../adr/003-coverage-targets.md) - Coverage targets
