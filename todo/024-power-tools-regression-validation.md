---
id: 024
status: done
priority: P1
agent: general-purpose
points: 5
created: 2026-09-01
---
# 024 - Power Tools Regression and Full-Suite Validation

## Result

- Mutation smoke test caught the old action-as-task-name implementation.
- Full `All -Fast`: 339 passed, 0 failed, 1 skipped.
- Full `All -Coverage`: 339 passed, 0 failed, 1 skipped; 40.36% command
  coverage overall and 196/261 lines (75.1%) for `power-tools.ps1`.
- Changed-file lint: no errors or warnings in the added code; existing style
  warnings remain in `power-tools.ps1`. Repository-wide lint has no errors.

## TLDR

Run the complete verification pass after the focused tests exist. This task
proves the original cancellation bug is caught by a test and that the new power
tests do not regress unrelated profile behavior.

## Acceptance Criteria

- [ ] The regression test fails against the intentionally reverted bug and
      passes with the fix restored.
- [ ] Focused power tests pass in isolation.
- [ ] Full unit, integration, and E2E suites run after task 023 is complete.
- [ ] PSScriptAnalyzer reports no new violations in changed files.
- [ ] Coverage output includes `modules/power-tools.ps1` and documents the
      achieved percentage.
- [ ] Any remaining environmental failures are recorded with reproduction and
      owner, not hidden or ignored.

## Tests

- Mutation-style regression check for action-name cancellation.
- `./scripts/Invoke-Tests.ps1 -Type All -Fast`.
- `./scripts/Invoke-Linter.ps1` or the repository's documented linter command.
- Manual smoke test only after all mocks pass: inspect status/help output; do
      not execute a real power action.
