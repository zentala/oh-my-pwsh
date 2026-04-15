# cc — Claude Code CLI for Windows (blocks + plans)

> PowerShell port of [designorant/ccblocks](https://github.com/designorant/ccblocks) (originally Bash for macOS/Linux)

## What Problem Does This Solve?

Claude Code (the CLI tool `claude`) uses **5-hour rolling usage blocks** as a rate-limiting mechanism. When you first send a message to Claude, a 5-hour timer starts. During that window, you get a quota of messages (45 for Pro, 225 for Max 5x, 900 for Max 20x). When the block expires, you need to start a new one.

**The problem:** if you don't start a block before you need it, you waste time waiting for it to activate. Blocks start on first interaction, not automatically.

**The solution:** ccblocks installs a **Windows Task Scheduler** job that automatically sends a minimal input (`"."`) to `claude` CLI at predetermined times. This "triggers" a new 5-hour block before you sit down to work.

## How It Works

```
                           Task Scheduler
                           runs at preset hours
                                 │
                                 ▼
        ┌─────────────────────────────────────────────┐
        │  ccblocks-daemon.ps1                        │
        │                                             │
        │  1. Find claude binary (PATH or fallbacks)  │
        │  2. echo "." | claude (15s timeout)         │
        │  3. Verify via ccusage (optional)           │
        │  4. Write timestamp to .last-activity       │
        │  5. Log result to cc.log              │
        └─────────────────────────────────────────────┘
```

The Task Scheduler can **wake the PC from sleep (S3)** to run the trigger, then the PC goes back to sleep.

## Schedule Presets

| Preset    | Triggers                     | Coverage  | Best for                        |
|-----------|------------------------------|-----------|---------------------------------|
| `247`     | 0:00, 6:00, 12:00, 18:00    | 20h/day   | Maximum coverage                |
| `work`    | 9:00, 14:00 (Mon-Fri)       | 10h/day   | Standard work schedule          |
| `night`   | 18:00, 23:00                 | 10h/day   | Evening/night coders            |
| `zentala` | 5:00, 10:00, 15:00, 20:00   | 20h/day   | Wake at 9, work till late night |
| `custom`  | User-defined hours           | varies    | Flexible                        |

### zentala schedule explained

```
05:00 trigger → block  5:00-10:00   ← wake at 9:00, 1h of active block remaining
10:00 trigger → block 10:00-15:00   ← fresh block for morning work
15:00 trigger → block 15:00-20:00   ← fresh block for afternoon
20:00 trigger → block 20:00-01:00   ← evening block

gap: 01:00-05:00 (sleeping)
```

### Validation Rules

- Minimum 2 triggers, maximum 4 (24h ÷ 5h = 4.8)
- Minimum 5h spacing between triggers (no overlap waste)
- Wraparound spacing (last trigger → first trigger next day) ≥ 5h

## Files

| File                              | Role                                    |
|-----------------------------------|-----------------------------------------|
| `modules/cc/main.ps1`            | CLI module — core block scheduler        |
| `modules/cc/plan.ps1`       | CLI module — scheduled plan tasks        |
| `scripts/cc/blocks-daemon.ps1`     | Daemon — block trigger (Task Scheduler)  |
| `scripts/cc/plan-daemon.ps1`| Daemon — plan executor (Task Scheduler)  |

### Runtime Files (created by ccblocks)

| Path                                       | Content                         |
|--------------------------------------------|---------------------------------|
| `%APPDATA%\cc\config.json`           | Schedule configuration          |
| `%APPDATA%\cc\.last-activity`        | Timestamp of last trigger       |
| `%APPDATA%\cc\cc.log`          | Daemon log                      |
| `%APPDATA%\cc\plans\plan-*.json`     | Scheduled plan definitions      |
| `%APPDATA%\cc\plans\plan-*.output.md`| Claude output from plans        |
| `%APPDATA%\cc\plans\plan-*.log`      | Plan execution logs             |

### config.json Schema

```json
{
  "schedule": {
    "type": "preset",
    "preset": "zentala",
    "custom_hours": [5, 10, 15, 20],
    "coverage_hours": 20
  }
}
```

## CLI Usage

```powershell
cc blocks setup                      # Interactive first-time setup
cc blocks status                     # Show task + schedule + last trigger
cc blocks trigger                    # Fire the daemon manually right now
cc blocks schedule list              # List all presets
cc blocks schedule apply zentala     # Apply a preset
cc blocks schedule apply custom      # Interactive custom hours
cc blocks pause                      # Disable task (vacation)
cc blocks resume                     # Re-enable task
cc blocks logs                       # Tail log file (default: 50 lines)
cc blocks logs -Last 100             # Tail more
cc blocks uninstall                  # Remove task + config
cc blocks uninstall -Force           # No confirmation prompts
```

### Scheduled Plans (wake & run Claude)

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

**Auto-scheduling:** Without `--at`, ccblocks tries `ccusage` to find when the current block expires and schedules 5 minutes after. Falls back to next full hour.

**Plan JSON schema:**
```json
{
  "id": "20260414-0100",
  "prompt": "refactor the auth module",
  "workingDirectory": "C:\\code\\myproject",
  "scheduledAt": "2026-04-14T01:00:00",
  "status": "pending",
  "autoEdit": false,
  "timeoutMinutes": 60
}
```

## Dependencies

| Dependency | Required | Purpose                                |
|------------|----------|----------------------------------------|
| PowerShell 7+ | Yes  | Runtime                                |
| `claude` CLI   | Yes  | The thing being triggered              |
| `ccusage`      | No   | Optional verification after trigger    |

## Wake From Sleep

Task is registered with `WakeToRun = $true`:
- **Sleep (S3):** PC wakes, runs trigger, goes back to sleep. Works reliably.
- **Hibernation (S4):** Depends on BIOS/UEFI and drivers. May or may not work.

## Differences from Bash Original

| Aspect           | Bash (macOS/Linux)                 | PowerShell (Windows)              |
|------------------|------------------------------------|-----------------------------------|
| Scheduler        | LaunchAgent / systemd              | Windows Task Scheduler            |
| Config parsing   | Inline python3 for JSON            | Native `ConvertFrom-Json`         |
| Logging          | `logger` (syslog/journald)         | File-based log in `%APPDATA%`     |
| Timeout          | `timeout` / `gtimeout`             | `Start-Job` + `Wait-Job`         |
| Claude search    | `/opt/homebrew/bin/claude` etc.    | `Get-Command` + Windows paths    |
| Installation     | `brew install ccblocks`            | Part of oh-my-pwsh profile        |

## Source & Context

- Original project: [github.com/designorant/ccblocks](https://github.com/designorant/ccblocks)
- This port was created as part of [oh-my-pwsh](https://github.com/zentala/pwsh-profile)
- Claude Code usage model reference: [sessionwatcher.com/guides/claude-code-rate-limits-explained](https://www.sessionwatcher.com/guides/claude-code-rate-limits-explained)
