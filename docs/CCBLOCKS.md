# ccblocks — Claude Code Block Scheduler (Windows)

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
        │  5. Log result to ccblocks.log              │
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
| `modules/ccblocks.ps1`            | CLI module — `ccblocks` command          |
| `scripts/ccblocks-daemon.ps1`     | Daemon — what Task Scheduler runs       |

### Runtime Files (created by ccblocks)

| Path                                       | Content                         |
|--------------------------------------------|---------------------------------|
| `%APPDATA%\ccblocks\config.json`           | Schedule configuration          |
| `%APPDATA%\ccblocks\.last-activity`        | Timestamp of last trigger       |
| `%APPDATA%\ccblocks\ccblocks.log`          | Daemon log                      |

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
ccblocks setup                      # Interactive first-time setup
ccblocks status                     # Show task + schedule + last trigger
ccblocks trigger                    # Fire the daemon manually right now
ccblocks schedule list              # List all presets
ccblocks schedule apply zentala     # Apply a preset
ccblocks schedule apply custom      # Interactive custom hours
ccblocks pause                      # Disable task (vacation)
ccblocks resume                     # Re-enable task
ccblocks logs                       # Tail log file (default: 50 lines)
ccblocks logs -Last 100             # Tail more
ccblocks uninstall                  # Remove task + config
ccblocks uninstall -Force           # No confirmation prompts
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
