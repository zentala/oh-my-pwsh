---
id: 019
status: done
priority: P0
agent: general-purpose
points: 8
created: 2026-09-01
---
# 019 - Power Tools Cancellation Tests

## Result

- Covered ID, canonical action, alias, all-actions, multiple-match
  confirmation, declined confirmation, missing target, and empty schedule.
- The `power cancel hibernate` regression is asserted through the action
  branch and exact `schtasks /delete` command checks.

## TLDR

Add behavioral tests for every scheduled-action cancellation mode. This is the
main regression area: `power cancel hibernate` previously treated `hibernate`
as a task name instead of an action type.

## Objective

Prove that `Remove-PowerSchedule` selects the intended scheduled tasks and
deletes only those tasks, with correct confirmation behavior.

## Acceptance Criteria

- [ ] Numeric cancellation removes only the matching ID.
- [ ] Canonical actions and aliases work: `hibernate`/`h`, `sleep`/`s`,
      `shutdown`/`off`, and `restart`/`r`.
- [ ] `all` removes every scheduled action and confirms when appropriate.
- [ ] Multiple matches for an action require confirmation before removal.
- [ ] A declined confirmation leaves all selected tasks untouched.
- [ ] Missing ID, action, task name, and empty schedule produce the expected
      status message without attempting deletion.
- [ ] Each delete uses the expected `schtasks /delete /tn ... /f` command.

## Tests

- Unit: mock `Get-PowerSchedule`, `Confirm-PowerAction`, and
  `Invoke-WithElevation`.
- Regression: temporarily revert the action-type branch and verify the
  `power cancel hibernate` test fails before restoring the fix.
- Cover happy, nil, empty, and error paths.
