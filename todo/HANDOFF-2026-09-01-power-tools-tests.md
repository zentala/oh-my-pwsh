# Handoff: Power Tools Test Coverage

> **Completed:** 2026-09-02. Tasks 017–024 are implemented in the working
> tree and all required verification has run.

## TLDR

Implement the tasks listed in the power-tools test plan, starting with safe
test doubles and pure helper coverage. The key regression is cancellation by
action (`power cancel hibernate` / `power cancel h`); all tests must be isolated
from real Windows power and Task Scheduler operations. The current Pester runner
also needs a separate registry-isolation repair before its full results are
trusted.

## Context

Repository: `oh-my-pwsh`

Source under test: `modules/power-tools.ps1`

Existing test layout: `tests/Unit`, `tests/Integration`, `tests/E2E`

Existing test decisions:

- `adr/001-pester-test-framework.md`
- `adr/002-test-isolation-strategy.md`
- `adr/003-coverage-targets.md`

## Important Current State

- The source fix for action-level cancellation is currently an uncommitted
  change in `modules/power-tools.ps1`. Preserve it; do not reset, checkout, or
  overwrite it.
- The fix adds support for `power cancel h`, `power cancel hibernate`, and the
  short cancellation alias `power c`.
- A syntax/alias smoke check passed.
- `Invoke-Tests.ps1 -Type Unit -Fast` currently fails before assertions because
  Pester 6.1.0 cannot create temporary registry keys in the restricted
  environment. Record new evidence after task 023; do not mislabel this as a
  product failure.

## Execution Waves

### Wave 1 — isolation and pure behavior

- 022 safe test doubles — 8 points
- 017 helper unit tests — 5 points

These can be developed independently, but 017 must use the safety contract
defined by 022.

### Wave 2 — scheduler and cancellation behavior

- 018 schedule query tests — 5 points
- 019 cancellation tests — 8 points

019 depends on the scheduler fixtures/mocks from 018 and must include the
reverted-fix regression check.

### Wave 3 — public routing and UI

- 020 dispatcher tests — 5 points
- 021 menu UI tests — 8 points

Both tasks depend on the test doubles and cancellation behavior, and may run in
parallel after Wave 2.

### Wave 4 — runner and final verification

- 023 Pester registry isolation — 8 points
- 024 regression/full-suite validation — 5 points

024 starts only after 023 is fixed or explicitly documented as blocked.

## Mental Model

`Invoke-Power` is the public dispatcher. `Show-PowerMenu` handles interactive
selection. `Get-PowerSchedule` reads and cleans Task Scheduler entries.
`Remove-PowerSchedule` resolves ID, action, task name, or `all`, then builds a
`schtasks /delete` command. `New-PowerSchedule` builds a scheduled task, while
`Invoke-PowerNow` executes an immediate native command after confirmation.

Tests should assert observable behavior and parameters at these boundaries,
not implementation-private details that do not affect users.

## Safety Rules

- Never call real `shutdown.exe`, `rundll32.exe`, `schtasks`, or elevation in a
  test.
- Never create a real scheduled task to test timing.
- Mock `Get-ScheduledTask`, `Get-ScheduledTaskInfo`,
  `Invoke-WithElevation`, `Confirm-PowerAction`, and UI readers.
- For any subprocess boundary, make the test fail if an unexpected process
  invocation occurs.
- Do not grant broad permissions to make Pester pass.

## Verification Commands

```powershell
pwsh -NoProfile -NonInteractive -Command "& { . ./modules/power-tools.ps1; ... }"
./scripts/Invoke-Tests.ps1 -Type Unit -Fast
./scripts/Invoke-Tests.ps1 -Type All -Fast
```

Use the repository's linter command from `scripts/` after tests. If the full
runner still fails in the environment, capture the exact failure and separate
framework/environment failures from assertion failures.

## Completion Contract

For each task:

1. Update its status and checklist.
2. Record test commands and results.
3. Preserve the source fix and unrelated user changes.
4. Do not claim UI coverage until both Spectre and fallback branches have
   executed assertions.
5. At the end, update `todo/INDEX.md` and `STATUS.md` with the final state.

## Final Evidence

- `./scripts/Invoke-Tests.ps1 -Type Unit -Fast`: 292 passed, 0 failed, 1
  skipped.
- `./scripts/Invoke-Tests.ps1 -Type All -Fast`: 339 passed, 0 failed, 1
  skipped.
- `./scripts/Invoke-Tests.ps1 -Type All -Coverage`: 339 passed, 0 failed, 1
  skipped; 40.36% command coverage and 75.1% line coverage for
  `modules/power-tools.ps1`.
- `./scripts/Invoke-Linter.ps1`: 0 errors; existing repository/style warnings
  remain, including pre-existing warnings in `power-tools.ps1`. The added code
  introduces no new analyzer warnings.
- The sole skipped test is the optional Spectre demo smoke test because
  `PwshSpectreConsole` is not installed on this host.
