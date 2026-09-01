---
id: 020
status: done
priority: P1
agent: general-purpose
points: 5
created: 2026-09-01
---
# 020 - Power Command Dispatcher Tests

## Result

- Covered menu/status/help/cancel routing, both schedule argument orders,
  numeric and action cancellation, `c h`, `now`, and invalid input with no
  mutating side effects.

## TLDR

Test `Invoke-Power` as the public command boundary. The goal is to prevent
alias and argument-routing regressions while mocking every operation that could
schedule or execute a real power action.

## Acceptance Criteria

- [ ] No arguments routes to the interactive menu.
- [ ] `status`, `help`, `menu`, and `cancel` route correctly.
- [ ] `<action> <time>` and `<time> <action>` both schedule correctly.
- [ ] `power cancel 1`, `power cancel hibernate`, and `power c h` route to
      cancellation.
- [ ] `now` routes to immediate execution with confirmation.
- [ ] Unknown commands, invalid time, and too many arguments produce errors
      without side effects.

## Tests

- Unit/integration boundary: mock `Show-PowerMenu`, `Show-PowerStatus`,
  `Show-PowerHelp`, `New-PowerSchedule`, `Remove-PowerSchedule`, and
  `Invoke-PowerNow`.
- Assert exact parameters passed to the selected function.
- Cover happy, nil, empty, and error inputs.
