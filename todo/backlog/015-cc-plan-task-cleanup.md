# 015 - cc plan leaves dead one-shot tasks in Task Scheduler

**Status:** `backlog`
**Priority:** P3 (housekeeping — no functional break)
**Complexity:** Small (1-2 hours)
**Type:** Bug / Housekeeping

---

## Problem Statement

`cc plan` registers a one-shot Task Scheduler job that wakes the PC and runs
`claude` once at a set time. After the job runs, nothing removes it. Old
`cc-plan-*` tasks stay `Ready` in Task Scheduler forever with an empty `NextRun`.

Found 2026-07-31: `cc-plan-20260417-0500` (executed 2026-04-17, `status: completed`)
was still registered months later and had to be removed by hand
(`Unregister-ScheduledTask`).

## Proposed Fix
- In `scripts/cc/plan-daemon.ps1`, after the plan reaches `status: completed`
  (or on any terminal exit), `Unregister-ScheduledTask` its own task.
- Add `cc plan prune` to sweep any `cc-plan-*` task whose plan file is
  `completed`/past and whose `NextRun` is empty.

## Acceptance Criteria
- A completed `cc plan` run leaves no lingering task in Task Scheduler.
- `cc plan prune` removes already-orphaned `cc-plan-*` entries.
