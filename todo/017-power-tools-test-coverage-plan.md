# Power Tools Test Coverage Plan

> **Implementation status:** Complete on 2026-09-02. Tasks 017–024 are
> implemented and validated; the only skipped test requires the optional
> `PwshSpectreConsole` module.

## TLDR

This plan hardens `modules/power-tools.ps1` after the cancellation regression
where action names were treated as task names. It adds isolated unit tests,
dispatcher/menu coverage, safety doubles, and a separate fix for the Pester
registry-isolation failure that currently prevents reliable test execution.

## Problem

The `power` command combines pure parsing, Task Scheduler integration, native
power commands, interactive menu behavior, and optional Spectre UI. Existing
tests do not cover this module. A full unit run currently fails in the Pester
framework while trying to create temporary registry keys, so it reports no
meaningful test results.

## Scope

- Test `modules/power-tools.ps1` without real power operations.
- Preserve the existing action aliases and cancellation behavior.
- Make the test runner report real assertions in restricted environments.
- Add regression coverage for `power cancel hibernate`.

Out of scope: redesigning the command UX, changing the scheduler backend, or
adding a new test framework.

## Existing Decisions and Patterns

- Pester 5.x is the project test framework: `adr/001-pester-test-framework.md`.
- Use the three-layer isolation model: `adr/002-test-isolation-strategy.md`.
- Follow differentiated coverage targets in `adr/003-coverage-targets.md`.
- Reuse the existing `tests/Unit`, `tests/Integration`, and `tests/E2E` layout.
- Keep external Windows operations behind mocks/fakes.

## Test Strategy

### Unit

Target: helper parsing/generation, action cancellation, and dispatcher routing.
The assertions that fail today are the missing mappings for action-level
cancellation and the untested invalid/empty branches. Files: `tests/Unit/`.

### Integration

Target: scheduler query plus cancellation command construction, with mocked
Task Scheduler and native process boundaries. The assertions that fail today
are the missing guarantees around stale-task cleanup, IDs, confirmation, and
delete commands. Files: `tests/Integration/` where cross-function behavior is
more readable than a unit mock.

### UI behavior

Target: all menu choices in both the Spectre and `Read-Host` fallback branches.
The assertions that fail today are absent: no test currently proves that menu
selection reaches the intended action or that invalid input is harmless. Keep
this as behavior testing, not pixel testing, because this is a terminal UI.

### Runner and regression

Target: a clean `pwsh -NoProfile` test process and the intentionally reverted
`power cancel hibernate` bug. The current runner failure is a Pester
`SecurityException` while creating temporary registry keys; task 023 must make
that failure observable as an environment/test setup issue rather than 267
false assertion failures. Task 024 must prove the regression test fails with
the old implementation and passes with the fix.

### Required paths and targets

Every new data/control path covers happy, nil, empty, and error cases. Critical
helpers target 100% branch coverage; power business logic targets at least 80%;
menu behavior targets at least 70%, consistent with the repository's existing
coverage decisions.

## Alternatives

### A — Focused unit tests only

Summary: Add tests around helpers and cancellation, with minimal UI coverage.
Effort: M. Risk: M. Reuses current Pester setup. Pros: smallest diff and fast
feedback. Cons: can miss menu routing and environment failures.

### B — Full layered coverage (recommended)

Summary: Cover helpers, scheduler boundary, cancellation, dispatcher, both UI
branches, safe doubles, and runner isolation. Effort: L. Risk: M. Reuses
Pester, existing mocks, and current test layers. Pros: catches the reported
regression and its likely UI/environment variants. Cons: more test maintenance.

### C — End-to-end real Task Scheduler tests

Summary: Create and delete real one-shot tasks on Windows during tests. Effort:
L/XL. Risk: H. Reuses the production scheduler path. Pros: highest realism.
Cons: requires privileges, is timing-sensitive, can mutate the host, and is
unsuitable for normal CI.

## Recommendation

Choose B. The failure spans logic, UI routing, and test infrastructure; helper
tests alone would leave the menu and safety boundary unprotected. Real scheduler
E2E tests are intentionally excluded from the normal suite.

## Task Order

1. 022 — safe test doubles
2. 017 — helper unit tests
3. 018 — scheduler query tests
4. 019 — cancellation and regression tests
5. 020 — dispatcher tests
6. 021 — UI menu tests
7. 023 — repair Pester registry isolation
8. 024 — full regression and suite validation

## Definition of Done

- All tasks 017-024 are complete or have an explicit blocker recorded.
- `power cancel hibernate` has a regression test that fails when the fix is
  reverted.
- No test can invoke a real shutdown/sleep/hibernate/restart or mutate a real
  Task Scheduler entry.
- Full test and lint results are recorded in the task history.
