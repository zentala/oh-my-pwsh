---
id: 017
status: done
priority: P1
agent: general-purpose
points: 5
created: 2026-09-01
---
# 017 - Power Tools Unit Tests

## Result

- Added `oh-my-pwsh/tests/Unit/PowerTools.Tests.ps1` with helper, boundary,
  scheduler, cancellation, dispatcher, and UI behavior coverage.
- Focused result: 26 passed, 0 failed.

## TLDR

Add isolated Pester coverage for the pure helper functions in
`modules/power-tools.ps1`. These tests should prove command aliases, time
parsing, command generation, and duration formatting without touching Windows
Task Scheduler or executing a power action.

## Objective

Create the fast unit-test foundation for the `power` command. The task covers
deterministic helpers only; scheduler and UI behavior belong to tasks 018-022.

## Scope

- `Resolve-PowerAction`
- `ConvertTo-PowerMinutes`
- `Get-PowerCommand`
- `Format-PowerDuration`

## Acceptance Criteria

- [ ] Every supported canonical action and alias is tested.
- [ ] Valid, invalid, boundary, and `now` time inputs are tested.
- [ ] Every generated native command is asserted exactly.
- [ ] Tests are independent of real time where practical and never call a
      power command.
- [ ] Test file follows the existing Pester naming/style conventions.

## Tests

- Unit: add `tests/Unit/PowerTools.Tests.ps1`.
- Run the focused Pester file and verify the test suite fails if the helper
  mappings are intentionally reverted.

## Notes

Use the accepted decisions in `adr/001-pester-test-framework.md` and
`adr/002-test-isolation-strategy.md`. `agent: general-purpose` is intentional:
the repository has no registered `pwsh-dev` agent yet.
