# ssh-sleep-blocker — Keep Windows awake during SSH sessions

Prevents Windows from entering sleep while there are active inbound SSH
connections on port 22. Runs as a scheduled task that starts at system boot
and polls every 30 seconds.

## What problem does this solve?

Running remote agents or long-lived SSH sessions to a Windows workstation
breaks when the machine falls asleep mid-session. Power plans that keep
the machine awake indiscriminately waste energy. This daemon blocks sleep
**only while SSH is actually in use** by calling the Windows
`SetThreadExecutionState` API with `ES_SYSTEM_REQUIRED`.

## How it works

```
  Task Scheduler (AtStartup, SYSTEM, highest)
            │
            ▼
  scripts/ssh-sleep-blocker/daemon.ps1
            │
   every 30 s:
   Get-NetTCPConnection -LocalPort 22 -State Established
            │
            ├── > 0 ─→ SetThreadExecutionState(ES_CONTINUOUS | ES_SYSTEM_REQUIRED)
            └── = 0 ─→ SetThreadExecutionState(ES_CONTINUOUS)
```

The daemon keeps running indefinitely (`ExecutionTimeLimit = 0`). Log entries
are written only on state transitions to avoid log spam.

## Files

| Path | Purpose |
|---|---|
| `modules/ssh-sleep-blocker/main.ps1` | CLI (`ssh-sleep-blocker <cmd>`) |
| `scripts/ssh-sleep-blocker/daemon.ps1` | Long-running polling daemon |
| `scripts/ssh-sleep-blocker/daemon.cmd` | CMD wrapper (Task Scheduler entry) |
| `%APPDATA%\ssh-sleep-blocker\daemon.log` | Runtime log |

## Commands

```powershell
ssh-sleep-blocker setup        # Register scheduled task (admin)
ssh-sleep-blocker status       # Task state + current SSH count
ssh-sleep-blocker logs 100     # Tail last 100 lines of daemon.log
ssh-sleep-blocker start        # Kick the task now (admin)
ssh-sleep-blocker stop         # Stop running task (admin)
ssh-sleep-blocker disable      # Disable autostart (admin)
ssh-sleep-blocker enable       # Re-enable autostart (admin)
ssh-sleep-blocker uninstall    # Remove task (admin)
```

Admin commands run easiest via `gsudo pwsh -c "ssh-sleep-blocker setup"`.

## Installation

First time setup — from an elevated shell:

```powershell
gsudo pwsh -c "ssh-sleep-blocker setup"
gsudo pwsh -c "ssh-sleep-blocker start"
```

The task runs as `SYSTEM`, so it survives user logoff.

## Troubleshooting

- **Task runs but sleep still triggers** — Windows may be using S4 (Hibernate)
  rather than S3 (Sleep). `SetThreadExecutionState` does not block hibernation.
  Switch to Sleep or Hybrid Sleep in Power Options.
- **"Task not installed"** — run `ssh-sleep-blocker setup` (admin).
- **Daemon silent after boot** — check `%APPDATA%\ssh-sleep-blocker\daemon.log`
  and Task Scheduler History for the `SSHSleepBlocker` task.
