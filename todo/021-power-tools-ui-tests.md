---
id: 021
status: done
priority: P1
agent: general-purpose
points: 8
created: 2026-09-01
---
# 021 - Power Tools Menu UI Tests

## Result

- Covered all eight fallback choices, safe exit/invalid input, empty-schedule
  cancellation, and equivalent Spectre selection/text routing.

## TLDR

Cover both menu implementations: the preferred `PwshSpectreConsole` path and
the plain `Read-Host` fallback. These tests protect the user-visible choices
and ensure menu input cannot trigger unintended power operations.

## Acceptance Criteria

- [ ] All eight menu choices are represented and routed correctly.
- [ ] Exit performs no action.
- [ ] Schedule choices prompt for time and call the correct action.
- [ ] Single cancellation prompts for an item and removes the selected ID.
- [ ] Cancel-all routes to the all-actions path.
- [ ] Empty schedules show an informational message and do not prompt for an
      item.
- [ ] Invalid fallback input exits safely without side effects.
- [ ] Spectre and fallback branches have equivalent behavior.

## Tests

- Unit/UI behavior: mock `Test-SpectreAvailable`, selection/text readers,
  `Get-PowerSchedule`, and all mutating command functions.
- Capture `Write-Host`/status output where it is part of the contract.
- Cover happy, nil, empty, and error paths for both UI branches.
