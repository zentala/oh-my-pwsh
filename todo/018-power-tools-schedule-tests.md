---
id: 018
status: done
priority: P1
agent: general-purpose
points: 5
created: 2026-09-01
---
# 018 - Power Tools Schedule Query Tests

## Result

- Covered prefix filtering, sorting, sequential IDs, rounded remaining time,
  stale-task cleanup, empty output, scheduler failure, and create-command
  construction in `oh-my-pwsh/tests/Unit/PowerTools.Tests.ps1`.

## TLDR

Test `Get-PowerSchedule` with mocked Task Scheduler responses. The tests must
prove sorting, IDs, remaining-time calculation, and stale-task cleanup while
remaining safe to run on a developer machine.

## Objective

Protect the boundary between Windows Task Scheduler and the power menu status
display. No real scheduled task may be created, deleted, or modified.

## Acceptance Criteria

- [ ] Tasks are filtered to the `OhMyPwsh-Power-*` prefix.
- [ ] Results are sorted by `NextRunTime` and receive stable sequential IDs.
- [ ] `MinutesLeft` rounds up as the production code expects.
- [ ] Tasks with no next run or a past next run are cleaned up through the
      mocked delete path and excluded from results.
- [ ] Empty task output returns an empty collection.
- [ ] Scheduler query failures are handled according to the existing behavior.

## Tests

- Unit: add cases to `tests/Unit/PowerTools.Tests.ps1`.
- Mock `Get-ScheduledTask`, `Get-ScheduledTaskInfo`, and
  `Invoke-WithElevation`.
- Cover happy, nil, empty, and error paths.
