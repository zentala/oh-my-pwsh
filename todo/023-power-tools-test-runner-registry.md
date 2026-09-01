---
id: 023
status: done
priority: P0
agent: general-purpose
points: 8
created: 2026-09-01
---
# 023 - Repair Pester Registry Isolation

## Result

- Disabled Pester's optional `TestRegistry` plugin in the normal runner; no
  test in this repository requires registry write access.
- Added clean handling for optional `PwshSpectreConsole` coverage and fixed
  the runner's focused file filter and coverage-variable collision.
- Unit runner result: 292 passed, 0 failed, 1 skipped.

## TLDR

Make the test runner usable in the current sandbox and CI environments. The
observed failure was environmental: Pester 6.1.0 attempted to create temporary
registry keys and every test container failed with `SecurityException` before
executing assertions.

## Objective

Identify which existing tests require registry access, then remove or isolate
that dependency so a normal unit run reports real test results instead of 267
framework failures.

## Acceptance Criteria

- [ ] `Invoke-Tests.ps1 -Type Unit -Fast` reaches test assertions.
- [ ] Tests do not require writable registry access unless explicitly marked
      as Windows integration tests.
- [ ] Pester version assumptions are documented and consistent with the
      existing ADR/CI configuration.
- [ ] The runner reports a useful failure when a required dependency is absent.
- [ ] The fix works in local PowerShell and GitHub Actions environments.

## Tests

- Runner smoke test: execute the focused suite in a clean `pwsh -NoProfile`
  process.
- Full unit suite: confirm framework failures are zero and report actual
  passed/failed counts.
- Error-path test: verify missing Pester is still diagnosed clearly.

## Notes

Do not weaken production code or grant broad permissions merely to make tests
green. Prefer the accepted isolation strategy in
`adr/002-test-isolation-strategy.md`.
