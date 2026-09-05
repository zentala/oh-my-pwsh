# cc — Claude Code CLI for Windows (plans)

> **Note:** `cc plan` does not auto-remove its one-shot tasks after they run —
> old `cc-plan-*` tasks may linger in Task Scheduler and are safe to
> `Unregister-ScheduledTask`.

## What Problem Does This Solve?

You want Claude Code to work on something while you sleep. `cc plan` registers a
one-shot Windows Task Scheduler job that **wakes the PC from sleep**, runs
`claude -p "<prompt>"` in the directory you were in, saves the output, and lets
the PC go back to sleep.

## How It Works

```
                           Task Scheduler
                           one-shot task, WakeToRun
                                 │
                                 ▼
        ┌─────────────────────────────────────────────┐
        │  plan-daemon.ps1                            │
        │                                             │
        │  1. Read the plan JSON                      │
        │  2. Run claude -p in the saved directory    │
        │  3. Save output to plan-<id>.output.md      │
        │  4. Log result to plan-<id>.log             │
        └─────────────────────────────────────────────┘
```

- **Sleep (S3):** PC wakes, runs the plan, goes back to sleep. Works reliably.
- **Hibernation (S4):** Depends on BIOS/UEFI and drivers. May or may not work.

## Files

| File                         | Role                                    |
|------------------------------|-----------------------------------------|
| `modules/cc/main.ps1`        | CLI module — entry point, shared helpers |
| `modules/cc/plan.ps1`        | CLI module — scheduled plan tasks        |
| `scripts/cc/plan-daemon.ps1` | Daemon — plan executor (Task Scheduler)  |

### Runtime Files

| Path                                  | Content                    |
|---------------------------------------|----------------------------|
| `%APPDATA%\cc\plans\plan-*.json`      | Scheduled plan definitions |
| `%APPDATA%\cc\plans\plan-*.output.md` | Claude output from plans   |
| `%APPDATA%\cc\plans\plan-*.log`       | Plan execution logs        |

## CLI Usage

Schedule Claude to run a specific prompt in a specific directory. PC wakes from sleep to execute.

```powershell
# Schedule a task (runs in current directory)
cc plan "refactor the auth module"                    # auto-schedule
cc plan "write tests for utils" --at 1:00             # run at 1:00 AM
cc plan "fix all TODOs" --at 3:00 --auto-edit         # allow file changes
cc plan "analyze codebase" --timeout 120              # 2h timeout (default: 60m)

# Manage plans
cc plan list                  # List all plans (pending/running/completed/failed)
cc plan show <id>             # Show details + Claude output
cc plan cancel <id>           # Cancel a pending plan
cc plan clean                 # Remove completed plans older than 7 days
```

**How it works:**
1. You run `cc plan "prompt"` from your project directory
2. A one-shot Task Scheduler task is created with `WakeToRun = true`
3. At the scheduled time, PC wakes from sleep
4. Daemon runs `claude -p "prompt"` in the saved directory
5. Output is saved to `%APPDATA%\cc\plans\plan-<id>.output.md`

**Modes:**
- **Default (read-only):** Claude analyzes but cannot modify files. Safe for overnight analysis.
- **`--auto-edit`:** Claude can edit files (`--dangerously-skip-permissions`). Use for actual coding tasks.

**Auto-scheduling:** Without `--at`, `cc plan` tries `ccusage` to find when the
current usage block expires and schedules 5 minutes after. Falls back to the next
full hour.

**Plan JSON schema:**
```json
{
  "id": "20260414-0100",
  "prompt": "refactor the auth module",
  "workingDirectory": "C:\code\myproject",
  "scheduledAt": "2026-04-14T01:00:00",
  "status": "pending",
  "autoEdit": false,
  "timeoutMinutes": 60
}
```

## Dependencies

| Dependency    | Required | Purpose                             |
|---------------|----------|-------------------------------------|
| PowerShell 7+ | Yes      | Runtime                             |
| `claude` CLI  | Yes      | The thing being run                 |
| `ccusage`     | No       | Optional auto-scheduling hint       |
