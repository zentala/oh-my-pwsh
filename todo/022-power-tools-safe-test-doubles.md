---
id: 022
status: done
priority: P0
agent: general-purpose
points: 8
created: 2026-09-01
---
# 022 - Safe Power Tools Test Doubles

## Result

- Added reusable doubles in `oh-my-pwsh/tests/Helpers/PowerToolsTestHelpers.ps1`.
- Added the `Invoke-PowerProcess` seam and fail-fast tests so native power and
  scheduler commands cannot run from the test suite.

## TLDR

Build the test seams needed to guarantee that the power test suite cannot
hibernate, sleep, shut down, restart, or alter real scheduled tasks. This task
turns safety from convention into an executable test invariant.

## Objective

Provide reusable mocks/helpers for native process calls and scheduler calls,
following the existing isolation strategy rather than introducing a new test
framework or runtime dependency.

## Acceptance Criteria

- [ ] Tests fail if `cmd.exe`, `shutdown.exe`, `rundll32.exe`, or real
      `schtasks` execution is attempted.
- [ ] Tests can inspect the command strings passed to the elevation wrapper.
- [ ] Test doubles are reusable by tasks 018-021.
- [ ] No test requires administrator privileges, registry access, network, or
      a pre-existing scheduled task.
- [ ] Safety behavior is documented for future power-command tests.

## Tests

- Unit: direct safety tests for each blocked external command.
- Integration: run the power test group in a clean process and assert no real
  scheduler mutation occurred.
- Cover missing dependencies and mocked command failures.
