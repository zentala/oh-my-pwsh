# oh-my-ai v0.0.1 - Specification

> **Status**: Draft
> **Version**: 0.0.1 (MVP)
> **Date**: 2025-10-19
> **Author**: Business Analyst, Solution Architect, DevEx/UX Engineer
> **Related**: [oh-my-ai.md](./oh-my-ai.md), [oh-my-ai.questions-all.md](./oh-my-ai.questions-all.md)

---

## Executive Summary

**oh-my-ai** is a PowerShell AI assistant module that brings intelligent command suggestions, error fixing, and script generation directly into the terminal. Built as a companion to [oh-my-pwsh](../CLAUDE.md), it provides a seamless DevEx-first interface for interacting with AI providers (OpenAI, Anthropic, OpenRouter, Ollama) without leaving PowerShell.

### Value Proposition

**For Power Users & Developers:**
- **Zero context switching** - Ask AI directly in terminal (`/ how to sort files`)
- **Smart command history awareness** - AI understands your workflow (last 10 commands)
- **Own your data** - Use your own API keys, no vendor lock-in
- **Beautiful UX** - Clean syntax (`/`, `/next`, `/write`), tab completion, colored output

**vs Competitors (AIShell, PSAI, ShellGPT, Copilot CLI):**
- ✅ **Simpler setup** - `/install` wizard, auto-configuration
- ✅ **Better DevEx** - Intuitive slash commands, aliases, inline help
- ✅ **Integrated with oh-my-pwsh** - Consistent icons, logging, error handling
- ✅ **Standalone package** - Works independently or as part of oh-my-pwsh suite

### Tech Stack

- **Language**: PowerShell 7.x (Windows primary, Linux future)
- **AI Backend**: PSAI module (facade/wrapper pattern)
- **Providers**: OpenAI, Anthropic, OpenRouter, Ollama
- **Config**: JSON (`~/.oh-my-ai/config.json`)
- **Sessions**: JSON logs (`~/.oh-my-ai/sessions/`)

---

## User Personas

### 1. **Alex - Linux Migrant**
- **Background**: 5 years Linux/bash, new to Windows/PowerShell
- **Goal**: Translate bash muscle memory to PowerShell (`/ bash ls -lah equivalent`)
- **Pain**: Doesn't know PowerShell cmdlet names, wants quick answers
- **Usage**: Frequent `/` queries, occasional `//` for workflow suggestions

### 2. **Sam - Windows Power User**
- **Background**: Experienced with cmd/PowerShell, wants to level up
- **Goal**: Learn advanced PowerShell patterns, automate tasks
- **Pain**: Googling syntax, trial-and-error debugging
- **Usage**: `/next` for suggestions, `/write` for script generation, `/edit` for refactoring

### 3. **Jordan - Casual Developer**
- **Background**: Full-stack dev, uses terminal occasionally
- **Goal**: Get things done quickly without memorizing commands
- **Pain**: Forgot how to do X, needs quick reminder
- **Usage**: Simple `/` queries, rarely explores advanced features

### 4. **Casey - DevOps Engineer**
- **Background**: Multi-cloud, infrastructure as code, scripts daily
- **Goal**: Debug complex pipelines, generate automation scripts
- **Pain**: Long error messages, needs context-aware debugging
- **Usage**: `/?` for error fixing, `/write` for pipeline scripts, custom prompts

---

## Architecture Decision Records (ADRs)

### ADR-001: Session ID Strategy
**Status**: Accepted
**Date**: 2025-10-19
**Context**: Session files need unique identifiers to prevent collisions when multiple PowerShell windows are open simultaneously.

**Decision**: Use `YYYY-MM-DD_NNN_PIDXXXXX` format
- Date prefix for human readability
- Sequential number for same-day sessions
- Process ID suffix to prevent collisions

**Implementation**:
```powershell
$date = Get-Date -Format "yyyy-MM-dd"
$pid = $PID
$counter = 1
while (Test-Path "~/.oh-my-ai/sessions/${date}_$('{0:D3}' -f $counter)_PID${pid}.json") {
    $counter++
}
$sessionId = "${date}_$('{0:D3}' -f $counter)_PID${pid}"
```

**Example**: `2025-10-19_001_PID12345.json`

**Consequences**:
- ✅ No collision risk
- ✅ Human-readable
- ✅ Sortable by date
- ⚠️ Slightly longer filename

---

### ADR-002: Error Capture Mechanism
**Status**: Accepted
**Date**: 2025-10-19
**Context**: `/? ` command needs to capture PowerShell errors reliably. PowerShell has multiple error types: exceptions, non-terminating errors, exit codes.

**Decision**: Capture from `$Error` automatic variable + `$LASTEXITCODE`

**Implementation**:
```powershell
function Get-LastCommandError {
    $lastCommand = (Get-History -Count 1).CommandLine
    $errorInfo = @{
        Command = $lastCommand
        HasError = $Error.Count -gt 0
        ErrorMessage = if ($Error.Count -gt 0) { $Error[0].Exception.Message } else { $null }
        ExitCode = $LASTEXITCODE
        FullError = if ($Error.Count -gt 0) { $Error[0] | Out-String } else { $null }
    }
    return $errorInfo
}
```

**Consequences**:
- ✅ Captures both terminating and non-terminating errors
- ✅ Includes exit codes for native commands
- ⚠️ User must not clear `$Error` manually (rare edge case)

---

### ADR-003: Context Truncation Strategy
**Status**: Accepted
**Date**: 2025-10-19
**Context**: AI context must balance completeness vs token limits. Spec said "10 commands OR 150 lines" but logic was ambiguous.

**Decision**: Two-phase truncation
1. Take last 10 commands from history
2. If combined text > 150 lines, truncate to last 150 lines

**Implementation**:
```powershell
function Get-CommandContext {
    # Phase 1: Get last 10 commands
    $history = Get-History -Count 10 | Select-Object -ExpandProperty CommandLine
    $contextText = $history -join "`n"

    # Phase 2: Truncate if exceeds line limit
    $lines = $contextText -split "`n"
    if ($lines.Count -gt 150) {
        $lines = $lines[-150..-1]  # Keep newest 150 lines
        $contextText = $lines -join "`n"
    }

    return $contextText
}
```

**Consequences**:
- ✅ Predictable: always last 10 commands (or fewer if history empty)
- ✅ Token-safe: never exceeds 150 lines
- ⚠️ May lose early parts of long commands

---

### ADR-004: Command Interception Strategy
**Status**: Accepted
**Date**: 2025-10-19
**Context**: Slash commands (`/`, `/next`, `/write`) are not valid PowerShell. Need to intercept before PowerShell parser.

**Decision**: PSReadLine `Enter` key handler

**Implementation**:
```powershell
Set-PSReadLineKeyHandler -Chord Enter -ScriptBlock {
    $line = $null
    $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

    if ($line -match '^/') {
        # Clear input line
        [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
        [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()

        # Route to oh-my-ai
        Invoke-AiCommandRouter $line
    } else {
        # Normal PowerShell command
        [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
    }
}
```

**Alternatives Considered**:
- Function aliasing (`function / {}`) - doesn't work (invalid function name)
- Custom parser - too complex

**Consequences**:
- ✅ Clean user experience
- ✅ No namespace pollution
- ⚠️ Overrides default Enter behavior (potential conflict with other modules)

---

### ADR-005: Provider Fallback Configuration
**Status**: Accepted
**Date**: 2025-10-19
**Context**: If primary provider fails, should try alternatives. Config schema was missing this field.

**Decision**: Add `providerFallback` array to config

**Schema Addition**:
```json
{
  "version": "0.0.1",
  "provider": "openai",
  "providerFallback": ["openai", "anthropic", "ollama"],
  "model": "gpt-4o-mini",
  ...
}
```

**Fallback Logic**:
1. Try `provider` field first
2. If fails → iterate `providerFallback` array
3. Skip if provider not configured (missing API key)
4. Show warning: `[!] OpenAI failed, trying Anthropic...`

**Consequences**:
- ✅ Resilient to API outages
- ✅ User-configurable priority
- ⚠️ May incur costs on multiple providers

---

### ADR-006: Tab Completion Implementation
**Status**: Accepted
**Date**: 2025-10-19
**Context**: Users expect Tab to autocomplete commands and arguments.

**Decision**: Custom argument completers

**Implementation**:
```powershell
# Complete slash commands
Register-ArgumentCompleter -Native -CommandName '/' -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)

    $commands = @('/write', '/edit', '/next', '/config', '/agent', '/history', '/help', '/install')
    $commands | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}

# Complete model names for /agent
Register-ArgumentCompleter -CommandName 'Invoke-AiAgent' -ParameterName 'Model' -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete)

    $config = Get-AiConfig
    $models = @()
    foreach ($provider in $config.providers.PSObject.Properties) {
        $models += $provider.Value.models
    }

    $models | Where-Object { $_ -like "$wordToComplete*" }
}
```

**Consequences**:
- ✅ Standard PowerShell UX
- ✅ Dynamic (reads config for models)
- ⚠️ Requires PSReadLine 2.0+

---

### ADR-007: API Key Masking Pattern
**Status**: Accepted
**Date**: 2025-10-19
**Context**: API keys must be shown in `/config` output but should be partially hidden for security.

**Decision**: Show first 3 and last 3 characters

**Implementation**:
```powershell
function Hide-ApiKey {
    param([string]$apiKey)

    if ($apiKey.Length -le 10) {
        return "***"  # Too short to mask safely
    }

    $prefix = $apiKey.Substring(0, 3)
    $suffix = $apiKey.Substring($apiKey.Length - 3, 3)
    $masked = "*" * 15

    return "${prefix}${masked}${suffix}"
}
```

**Example**: `sk-...` → `sk-***************xyz`

**Consequences**:
- ✅ User can verify which key is configured
- ✅ Safe for screenshots/logs
- ⚠️ Still reversible if key space is small (use responsibly)

---

### ADR-008: Update Check Strategy
**Status**: Accepted
**Date**: 2025-10-19
**Context**: Users should be notified of updates, but checks must be fast and offline-safe.

**Decision**: GitHub API with 24-hour cache + 2-second timeout

**Implementation**:
```powershell
function Test-UpdateAvailable {
    $cacheFile = "~/.oh-my-ai/.update-check"
    $cacheValid = (Test-Path $cacheFile) -and
                  ((Get-Item $cacheFile).LastWriteTime -gt (Get-Date).AddDays(-1))

    if (-not $cacheValid) {
        try {
            $release = Invoke-RestMethod `
                -Uri "https://api.github.com/repos/zentala/oh-my-ai/releases/latest" `
                -TimeoutSec 2 `
                -ErrorAction Stop

            @{
                LatestVersion = $release.tag_name
                CurrentVersion = "0.0.1"
            } | ConvertTo-Json | Out-File $cacheFile
        } catch {
            # Silent fail - don't annoy offline users
            return $null
        }
    }

    $cached = Get-Content $cacheFile | ConvertFrom-Json
    return $cached
}
```

**Consequences**:
- ✅ Fast (cached for 24h)
- ✅ Offline-safe (2s timeout, silent fail)
- ⚠️ May miss updates if always offline

---

### ADR-009: Environment Context Collection
**Status**: Accepted
**Date**: 2025-10-19
**Context**: `Get-CimInstance` is slow (~100ms). Need faster alternative.

**Decision**: Use .NET Framework APIs instead of CIM

**Implementation**:
```powershell
$envContext = @{
    os = [System.Environment]::OSVersion.VersionString
    pwshVersion = $PSVersionTable.PSVersion.ToString()
    terminal = $env:TERM_PROGRAM ?? "Unknown"
    language = [System.Globalization.CultureInfo]::CurrentCulture.Name
    user = $env:USERNAME
}
```

**Benchmark**:
- `Get-CimInstance`: ~100ms
- `.NET APIs`: ~5ms
- **20x faster**

**Consequences**:
- ✅ Instant context collection
- ✅ No CIM dependency
- ⚠️ Less detailed OS info (acceptable trade-off)

---

## User Stories

### Epic 1: Basic AI Interaction

#### US-001: First-time Setup
**As** a new user
**I want** to be guided through AI provider setup
**So that** I can start using oh-my-ai without reading docs

**Acceptance Criteria:**
- [ ] Running any `/` command without config triggers `/install` wizard
- [ ] Wizard prompts for: provider (OpenAI/Anthropic/OpenRouter/Ollama), API key, model
- [ ] Wizard tests connection with ping prompt
- [ ] Wizard saves config to `~/.oh-my-ai/config.json`
- [ ] Wizard shows tutorial with example commands
- [ ] Yellow warning if setup fails, suggests troubleshooting

**Priority**: P0 (MVP)

---

#### US-002: Simple Query (No Context)
**As** a user
**I want** to ask AI a PowerShell question
**So that** I can get quick answers without context

**Acceptance Criteria:**
- [ ] `/ <question>` sends question to AI with default system prompt
- [ ] Response displayed with colored output (icon, formatted text)
- [ ] Command history (last 10 commands) included in context but marked as "use ONLY if relevant"
- [ ] No automatic execution - just shows answer
- [ ] Works with all configured providers (fallback if primary fails)

**Example:**
```powershell
PS> / how to list files sorted by size

🤖 AI:
Get-ChildItem | Sort-Object Length -Descending
```

**Priority**: P0 (MVP)

---

#### US-003: Context-Aware Query
**As** a user working through a task
**I want** AI to understand my recent commands
**So that** I get relevant suggestions based on my workflow

**Acceptance Criteria:**
- [ ] Same syntax as US-002: `/ <question>`
- [ ] Context includes last 10 commands OR 150 lines (whichever smaller)
- [ ] AI system prompt instructs: "Use command history ONLY if relevant"
- [ ] User sees indicator: `🤖 AI (analyzing last 5 commands)...`
- [ ] Context can be globally disabled: `/config history off`

**Example:**
```powershell
PS> Get-Process chrome
PS> / how to kill it

🤖 AI (analyzing last 2 commands):
Stop-Process -Name chrome
```

**Priority**: P0 (MVP)

---

#### US-004: Fix Last Command
**As** a user who just got an error
**I want** AI to analyze and fix it
**So that** I don't have to debug manually

**Acceptance Criteria:**
- [ ] `/? <optional question>` analyzes last command from history
- [ ] Captures command using `Get-LastCommandError` (see ADR-002)
- [ ] Captures: command text, `$Error[0]` message, `$LASTEXITCODE`, full error object
- [ ] AI prompt: "Last command failed: {{lastCmd}}. Error: {{error}}. Exit code: {{exitCode}}. Provide fix."
- [ ] Shows original command, error, and suggested fix
- [ ] Optionally executes fix with Y/n confirmation

**Example:**
```powershell
PS> Get-ChildItem -InvalidParam
Get-ChildItem: A parameter cannot be found that matches parameter name 'InvalidParam'.

PS> /? fix this

🤖 AI:
❌ Error: Invalid parameter '-InvalidParam'
✅ Fix: Get-ChildItem
   (lists files in current directory)

Execute fix? [Y/n]:
```

**Priority**: P1 (Should Have)

---

### Epic 2: Code Generation

#### US-005: Suggest Next Step
**As** a user in the middle of a task
**I want** AI to suggest what to do next
**So that** I can continue my workflow efficiently

**Acceptance Criteria:**
- [ ] `/next` (alias `/n`) analyzes last command + its output
- [ ] AI prompt: "Based on command history and last output, suggest next logical step"
- [ ] Shows suggestion with explanation
- [ ] Y/n confirmation before execution
- [ ] Fails gracefully if no history available

**Example:**
```powershell
PS> Get-Process | Where-Object CPU -gt 100
# (shows list of high-CPU processes)

PS> /next

🤖 AI suggests:
Stop-Process -Name "chrome" -Force
(Terminates high-CPU Chrome processes)

Execute? [Y/n]:
```

**Priority**: P1 (Should Have)

---

#### US-006: Generate Script File
**As** a user
**I want** AI to generate a script and save it to file
**So that** I can reuse it later

**Acceptance Criteria:**
- [ ] `/write [filename] <description>` generates script
- [ ] Without filename: shows suggestion + tip to add filename
- [ ] With filename: creates file in current directory
- [ ] With `""` as filename: AI suggests name, requires Y/n confirmation
- [ ] Generated script includes comments
- [ ] Alias: `/w`

**Example:**
```powershell
PS> /write backup.ps1 copy logs folder to D:\backup

🤖 Generating backup.ps1...

✅ Created: backup.ps1
# Backup script: Copy logs to D:\backup
Copy-Item -Path .\logs -Destination D:\backup -Recurse
```

**Priority**: P1 (Should Have)

---

#### US-007: Edit Existing File
**As** a user
**I want** AI to modify an existing file
**So that** I can refactor or improve code

**Acceptance Criteria:**
- [ ] `/edit <filename> <instruction>` modifies file
- [ ] `/edit` without args shows subhelp
- [ ] `/edit config` opens `~/.oh-my-ai/config.json` in default editor
- [ ] AI reads file, applies changes, saves (creates .bak backup)
- [ ] Shows diff before/after
- [ ] Alias: `/e`

**Example:**
```powershell
PS> /edit script.ps1 add error handling

🤖 Editing script.ps1...

Changes:
+ try {
      # existing code
+ } catch {
+     Write-Error $_.Exception.Message
+ }

Apply changes? [Y/n]:
```

**Priority**: P2 (Nice to Have)

---

### Epic 3: Configuration & Help

#### US-008: View Help
**As** a user
**I want** to see available commands
**So that** I know what oh-my-ai can do

**Acceptance Criteria:**
- [ ] `/` or `/help` shows command list
- [ ] Grouped by category (Basic, Generate, Config)
- [ ] Shows aliases (e.g., `/write` = `/w`)
- [ ] Shows examples for common commands
- [ ] Colored output with icons

**Priority**: P0 (MVP)

---

#### US-009: View Configuration
**As** a user
**I want** to see my current AI setup
**So that** I know which provider/model is active

**Acceptance Criteria:**
- [ ] `/config` (alias `/c`) shows current settings
- [ ] Displays: provider, model, API key (masked), history setting
- [ ] Shows environment context (OS, PowerShell version, terminal)
- [ ] Shows config file path
- [ ] Colored, formatted output

**Example:**
```powershell
PS> /config

🤖 oh-my-ai Configuration

Provider:  OpenAI
Model:     gpt-4o-mini
API Key:   sk-***************xyz (valid ✓)
History:   Enabled (last 10 commands, max 150 lines)

Environment:
  OS:        Windows 11 Pro
  PowerShell: 7.5.0
  Terminal:  Windows Terminal

Config: C:\Users\Pawel\.oh-my-ai\config.json
```

**Priority**: P2 (Nice to Have)

---

#### US-010: Switch AI Model
**As** a user
**I want** to change AI provider or model
**So that** I can use different models for different tasks

**Acceptance Criteria:**
- [ ] `/agent` (alias `/a`) shows available models
- [ ] `/agent <model>` switches to that model
- [ ] Tab completion for model names
- [ ] Saves selection to config
- [ ] Validates model exists before switching

**Example:**
```powershell
PS> /agent

Available models:
  OpenAI:       gpt-4o-mini, gpt-4-turbo
  Anthropic:    claude-3-5-sonnet-20241022
  Ollama:       llama3

Current: gpt-4o-mini

PS> /agent claude-3-5-sonnet-20241022
✓ Switched to claude-3-5-sonnet-20241022
```

**Priority**: P2 (Nice to Have)

---

#### US-011: View Command History
**As** a user
**I want** to see my recent commands and AI interactions
**So that** I can review what I've done

**Acceptance Criteria:**
- [ ] `/history` (alias `/h`) shows last 10 PowerShell commands
- [ ] Shows link to current session file
- [ ] Session file contains full AI conversation log
- [ ] Colored output with timestamps

**Example:**
```powershell
PS> /history

🕓 Recent Commands (Session: 2025-10-19_001_PID12345)

[1] Get-Process
[2] / how to kill chrome
[3] Stop-Process -Name chrome
[4] /next

Full session log: C:\Users\Pawel\.oh-my-ai\sessions\2025-10-19_001_PID12345.json
```

**Priority**: P2 (Nice to Have)

---

#### US-012: Check for Updates
**As** a user
**I want** to know when new versions are available
**So that** I can stay up to date

**Acceptance Criteria:**
- [ ] On first command in session, check GitHub for latest release (silent)
- [ ] If newer version found, show yellow notification
- [ ] `/update` shows changelog and update instructions
- [ ] Notification shown max once per session
- [ ] Fails gracefully if offline

**Example:**
```powershell
PS> / how to list files

[!] oh-my-ai v0.0.2 available (current: v0.0.1)
    Run /update to see what's new

🤖 AI: Get-ChildItem
```

**Priority**: P2 (Nice to Have)

---

## Architecture

> **Key Decisions**: See ADRs above for:
> - ADR-004: Command Interception (PSReadLine hook)
> - ADR-006: Tab Completion
> - ADR-009: Fast envContext collection

### Module Structure

```
oh-my-ai/
├── oh-my-ai.psm1                # Main module entry point
├── oh-my-ai.psd1                # Module manifest
├── modules/
│   ├── core/
│   │   ├── config.ps1           # Configuration management
│   │   ├── session.ps1          # Session logging
│   │   ├── context.ps1          # Command history context
│   │   └── output.ps1           # Colored output (copy from oh-my-pwsh)
│   ├── providers/
│   │   ├── provider-base.ps1    # Abstract provider interface
│   │   ├── openai.ps1           # OpenAI API wrapper
│   │   ├── anthropic.ps1        # Anthropic API wrapper
│   │   ├── openrouter.ps1       # OpenRouter API wrapper
│   │   └── ollama.ps1           # Ollama local wrapper
│   └── commands/
│       ├── query.ps1            # / command
│       ├── fix.ps1              # /? command
│       ├── next.ps1             # /next command
│       ├── write.ps1            # /write command
│       ├── edit.ps1             # /edit command
│       ├── agent.ps1            # /agent command
│       ├── config.ps1           # /config command
│       ├── history.ps1          # /history command
│       └── help.ps1             # /help command
├── prompts/
│   ├── system/
│   │   ├── default.md           # Default query prompt
│   │   ├── fix.md               # Error fixing prompt
│   │   ├── next.md              # Next step suggestion prompt
│   │   ├── write.md             # Script generation prompt
│   │   └── edit.md              # File editing prompt
│   └── user/                    # User custom prompts (empty)
├── config/
│   └── default-config.json      # Default configuration template
├── tests/
│   └── (Pester tests)
└── README.md
```

### Runtime User Directory

```
~/.oh-my-ai/                     # C:\Users\{user}\.oh-my-ai\
├── config.json                  # User configuration
├── sessions/
│   ├── 2025-10-19_001.json
│   └── 2025-10-19_002.json
└── prompts/                     # User custom prompts
    └── (user files)
```

---

### Component Diagram

```
┌─────────────────────────────────────────────────────┐
│                  PowerShell User                    │
└──────────────────────┬──────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────┐
│              oh-my-ai.psm1 (Main)                   │
│  - PSReadLine hook (slash command detection)       │
│  - Argument completers (Tab autocomplete)          │
└──────────────────────┬──────────────────────────────┘
                       │
          ┌────────────┼────────────┐
          ▼            ▼            ▼
    ┌─────────┐  ┌─────────┐  ┌──────────┐
    │ Config  │  │ Context │  │ Commands │
    │ Manager │  │ Builder │  │  Router  │
    └─────────┘  └─────────┘  └──────────┘
          │            │            │
          └────────────┼────────────┘
                       ▼
              ┌─────────────────┐
              │ Provider Manager│
              └─────────────────┘
                       │
          ┌────────────┼────────────┬────────────┐
          ▼            ▼            ▼            ▼
    ┌─────────┐  ┌──────────┐  ┌─────────┐  ┌────────┐
    │ OpenAI  │  │Anthropic │  │OpenRouter│  │ Ollama │
    └─────────┘  └──────────┘  └─────────┘  └────────┘
          │            │            │            │
          └────────────┴────────────┴────────────┘
                       │
                       ▼
              ┌─────────────────┐
              │   AI Response   │
              └─────────────────┘
                       │
                       ▼
              ┌─────────────────┐
              │ Output Formatter│
              │ Session Logger  │
              └─────────────────┘
```

---

## Context & Prompt Strategy

### Context Collection

**When**: Every AI command (`/`, `/next`, `/?`, `/write`, `/edit`)

**What**:
1. **Command History**: Last 10 commands from `Get-History`
2. **Truncation**: Max 150 lines total (two-phase, see ADR-003)
3. **Strategy**: Keep newest commands/lines if exceeds limit
4. **Environment**: OS, PowerShell version, current directory (cached per session)

**Implementation** (see ADR-003 for full details):
```powershell
function Get-CommandContext {
    # Phase 1: Get last 10 commands
    $history = Get-History -Count 10 | Select-Object -ExpandProperty CommandLine
    $contextText = $history -join "`n"

    # Phase 2: Truncate if exceeds line limit
    $lines = $contextText -split "`n"
    if ($lines.Count -gt 150) {
        $lines = $lines[-150..-1]  # Keep last 150 lines
        $contextText = $lines -join "`n"
    }

    return $contextText
}
```

### Prompt Templates

**Location**: `prompts/system/*.md`

**Format**: Markdown with placeholders

**Example** (`prompts/system/default.md`):
```markdown
You are a PowerShell assistant integrated into the terminal.

User's environment:
- OS: {{os}}
- PowerShell: {{pwshVersion}}
- Current directory: {{pwd}}

Recent command history (last 10 commands):
```
{{context}}
```

Instructions:
- Answer user's question concisely
- Provide working PowerShell code when relevant
- Use command history ONLY if it helps answer the question
- If history is irrelevant, ignore it
- Format code in code blocks
- Explain briefly what the code does

User question: {{userPrompt}}
```

**Placeholders**:
- `{{os}}` - Operating system (from `$env:OS`)
- `{{pwshVersion}}` - PowerShell version (from `$PSVersionTable`)
- `{{pwd}}` - Current directory (from `Get-Location`)
- `{{context}}` - Command history (from `Get-CommandContext`)
- `{{userPrompt}}` - User's question
- `{{lastCmd}}` - Last command (for `/?`)
- `{{error}}` - Error message (for `/?`)

---

## Command Reference

### Basic Commands

| Command | Alias | Description | Priority |
|---------|-------|-------------|----------|
| `/` | - | Show help | P0 |
| `/help` | - | Show help | P0 |
| `/ <question>` | - | Ask AI (with smart context) | P0 |
| `/? <question>` | - | Fix last command | P1 |
| `/next` | `/n` | Suggest next step | P1 |

### Generation Commands

| Command | Alias | Description | Priority |
|---------|-------|-------------|----------|
| `/write [file] <desc>` | `/w` | Generate script | P1 |
| `/edit <file> <instr>` | `/e` | Edit file with AI | P2 |

### Configuration Commands

| Command | Alias | Description | Priority |
|---------|-------|-------------|----------|
| `/install` | `/i` | Setup wizard | P0 |
| `/config` | `/c` | Show configuration | P2 |
| `/edit config` | - | Open config in editor | P2 |
| `/agent [model]` | `/a` | Switch AI model | P2 |
| `/history` | `/h` | Show command history | P2 |
| `/update` | - | Check for updates | P2 |

### Command Behavior

**Tab Completion**:
- `/` + Tab → shows all commands
- `/w` + Tab → completes to `/write`
- `/agent` + Tab → shows available models

**Confirmation**:
- `/next` - requires Y/n before execution
- `/write` - creates file immediately (no confirmation)
- `/edit` - shows diff, requires Y/n
- `/?` - shows fix, requires Y/n for execution

---

## Safety & Security

### Command Execution Safety

**Three lists in config**:

```json
"safety": {
  "autoExecuteWhitelist": [
    "Get-ChildItem", "Get-Content", "Get-Process", "Get-Service",
    "Select-Object", "Where-Object", "Sort-Object",
    "cat", "ls", "pwd", "echo"
  ],
  "requireConfirmation": [
    "Remove-Item", "rm", "del",
    "Stop-Process", "Stop-Service",
    "Set-ExecutionPolicy",
    "Invoke-Expression", "iex"
  ],
  "blocked": [
    "rm -rf /",
    "del /s /q C:\\*",
    "format c:",
    "Clear-Disk"
  ]
}
```

**Logic**:
1. If generated command in **blocked** → refuse, show error
2. If in **requireConfirmation** → show Y/n prompt
3. If in **autoExecuteWhitelist** → execute immediately (only for `/next`, not default)
4. Else → show Y/n prompt (default safe behavior)

### API Key Security

- Stored in `~/.oh-my-ai/config.json` (user-only permissions)
- Masked in output: `sk-***************xyz` (see ADR-007)
- Masking pattern: first 3 + last 3 characters visible
- Never logged to session files (redacted)
- User responsible for key security (this is a local tool)

### Audit Logging

**All AI interactions logged to session files**:
```json
{
  "sessionId": "2025-10-19_001",
  "startTime": "2025-10-19T14:30:22Z",
  "provider": "openai",
  "model": "gpt-4o-mini",
  "interactions": [
    {
      "timestamp": "2025-10-19T14:31:10Z",
      "command": "/",
      "userPrompt": "how to list files",
      "aiResponse": "Get-ChildItem",
      "executed": false
    }
  ]
}
```

**Purpose**: Debugging, cost tracking, incident recovery

---

## Session Management

### Session Lifecycle

1. **Session Start**: First AI command in PowerShell session
   - Generate session ID: `YYYY-MM-DD_NNN_PIDXXXXX` (see ADR-001)
   - Example: `2025-10-19_001_PID12345`
   - Create file: `~/.oh-my-ai/sessions/{sessionId}.json`
   - Log start time, provider, model

2. **During Session**: Each AI interaction
   - Append to `interactions` array
   - Log: timestamp, command, prompt, response, execution status

3. **Session End**: PowerShell closes
   - Update `endTime`
   - Close JSON file

### Session File Format

```json
{
  "sessionId": "2025-10-19_001_PID12345",
  "startTime": "2025-10-19T14:30:22Z",
  "endTime": "2025-10-19T15:45:10Z",
  "provider": "openai",
  "model": "gpt-4o-mini",
  "interactions": [
    {
      "timestamp": "2025-10-19T14:31:10Z",
      "command": "/",
      "shellHistory": ["Get-Process", "Get-Service"],
      "userPrompt": "how to save this to file",
      "aiResponse": "... | Out-File output.txt",
      "executed": true,
      "exitCode": 0
    }
  ]
}
```

**Notes**:
- `shellHistory` only captured at moment of AI query (snapshot)
- Not all PowerShell commands logged (too verbose)
- API keys redacted from logs

---

## Configuration Schema

### File Location
- **Windows**: `C:\Users\{user}\.oh-my-ai\config.json`
- **Linux** (future): `/home/{user}/.oh-my-ai/config.json`

### Schema

```json
{
  "version": "0.0.1",
  "provider": "openai",
  "providerFallback": ["openai", "anthropic", "ollama"],
  "model": "gpt-4o-mini",
  "providers": {
    "openai": {
      "apiKey": "sk-...",
      "models": ["gpt-4o-mini", "gpt-4-turbo"]
    },
    "anthropic": {
      "apiKey": "sk-ant-...",
      "models": ["claude-3-5-sonnet-20241022"]
    },
    "openrouter": {
      "apiKey": "sk-or-...",
      "baseUrl": "https://openrouter.ai/api/v1"
    },
    "ollama": {
      "baseUrl": "http://localhost:11434",
      "models": ["llama3", "mistral"]
    }
  },
  "context": {
    "enabled": true,
    "maxCommands": 10,
    "maxLines": 150,
    "truncationStrategy": "newest-first"
  },
  "safety": {
    "autoExecuteWhitelist": ["Get-ChildItem", "ls", "cat"],
    "requireConfirmation": ["Remove-Item", "rm", "Stop-Process"],
    "blocked": ["rm -rf /", "format c:"]
  },
  "envContext": {
    "os": "Windows 11 Pro",
    "pwshVersion": "7.5.0",
    "terminal": "Windows Terminal",
    "language": "en-US",
    "user": "Pawel"
  },
  "preferences": {
    "showUpdateNotifications": true,
    "coloredOutput": true,
    "defaultEditor": "code"
  }
}
```

### envContext Collection

**When**: First AI command in session (cached)

**How** (see ADR-009 for .NET optimization):
```powershell
$envContext = @{
    os = [System.Environment]::OSVersion.VersionString
    pwshVersion = $PSVersionTable.PSVersion.ToString()
    terminal = $env:TERM_PROGRAM ?? "Unknown"
    language = [System.Globalization.CultureInfo]::CurrentCulture.Name
    user = $env:USERNAME
}
```

**Performance**: 20x faster than `Get-CimInstance` (~5ms vs ~100ms)

---

## Provider Interface

### Abstract Provider Contract

All providers implement:
```powershell
interface IProvider {
    [string] Invoke-Query($prompt, $systemPrompt, $model)
    [bool] Test-Connection()
    [array] Get-AvailableModels()
}
```

### Provider Fallback Strategy

**Config**:
```json
"providerFallback": ["openai", "anthropic", "ollama"]
```

**Logic**:
1. Try primary provider (from `provider` field)
2. If fails (timeout, auth error) → try next in fallback list
3. Show yellow warning: `[!] OpenAI failed, trying Anthropic...`
4. If all fail → red error + troubleshooting tips

---

## Testing Strategy

### Unit Tests (Pester)

**Coverage Target**: 75% overall

**Test Files**:
```
tests/
├── core/
│   ├── config.Tests.ps1
│   ├── context.Tests.ps1
│   └── session.Tests.ps1
├── providers/
│   ├── openai.Tests.ps1
│   └── provider-base.Tests.ps1
└── commands/
    ├── query.Tests.ps1
    ├── fix.Tests.ps1
    └── write.Tests.ps1
```

**Key Test Scenarios**:
1. **Context Truncation**: Verify 150-line limit enforced
2. **Provider Fallback**: Mock API failures, verify fallback chain
3. **Safety**: Blocked commands rejected, whitelist auto-executes
4. **Session Logging**: Interactions appended correctly
5. **Config Loading**: Default config used if user config missing

### Integration Tests

**Manual Test Cases** (until automated):
1. Fresh install → `/install` wizard → verify config created
2. `/ question` → verify OpenAI called, response formatted
3. `/next` after command → verify context included, suggestion shown
4. `/?` after error → verify last command parsed, fix suggested
5. `/write script.ps1` → verify file created with correct content
6. `/agent llama3` → verify model switched, config updated
7. Provider failure → verify fallback, yellow warning shown

---

## Roadmap

### P0 - MVP (v0.0.1)
**Goal**: Basic AI queries + setup

- [ ] `/install` - Setup wizard
- [ ] `/` or `/help` - Help display
- [ ] `/ <question>` - AI query with smart context
- [ ] Config management (load, save, default)
- [ ] OpenAI provider (primary)
- [ ] Context collection (10 commands, 150 lines)
- [ ] Colored output (icons, formatting)
- [ ] Session logging (basic)

**Deliverable**: User can install, configure, and ask AI questions

---

### P1 - Core Features (v0.0.2)
**Goal**: Error fixing + code generation

- [ ] `/? <question>` - Fix last command
- [ ] `/next` - Suggest next step
- [ ] `/write [file] <desc>` - Generate script
- [ ] Anthropic provider (Claude)
- [ ] Provider fallback logic
- [ ] Safety system (whitelist, confirmation, blocked)
- [ ] Y/n confirmation prompts
- [ ] Session logging (full audit trail)

**Deliverable**: Complete AI assistant for daily workflow

---

### P2 - Polish (v0.0.3)
**Goal**: Configuration + convenience

- [ ] `/edit <file> <instr>` - Edit files
- [ ] `/config` - Show configuration
- [ ] `/edit config` - Open in editor
- [ ] `/agent [model]` - Switch models
- [ ] `/history` - Show command history
- [ ] `/update` - Check for updates
- [ ] Tab completion (all commands + models)
- [ ] OpenRouter + Ollama providers
- [ ] Custom prompts (`/prompt`)

**Deliverable**: Production-ready tool with polish

---

### P3 - Future Vision (v1.0+)
**Goal**: Advanced features

- [ ] Cost tracking (`/$`)
- [ ] Interactive mode (multi-turn conversations)
- [ ] Custom prompt library (`//p <file>`)
- [ ] Learning from user corrections
- [ ] Git context awareness
- [ ] Installed tools detection (bat, eza, fzf)
- [ ] Linux/bash support
- [ ] Multi-profile support (work/personal)

**Deliverable**: Full-featured AI shell companion

---

## Development Guidelines

### Code Style
- Follow PowerShell best practices (Verb-Noun naming)
- Comment complex logic
- Use approved verbs: `Get-`, `Set-`, `Invoke-`, `Test-`
- Error handling: try/catch with meaningful messages

### Dependency Management
- **PSAI**: Facade pattern (abstract provider interface)
  - If PSAI breaks → swap implementation without changing commands
- **oh-my-pwsh**: Optional dependency
  - If available → use `Write-StatusMessage`, `Get-FallbackIcon`
  - Else → copy minimal output functions to oh-my-ai

### File Naming
- PowerShell modules: `lowercase-with-hyphens.ps1`
- Tests: `ModuleName.Tests.ps1`
- Prompts: `lowercase.md`

### Documentation
- User docs: `README.md` (installation, quick start)
- Dev docs: `CONTRIBUTING.md` (setup, architecture)
- Specs: `specs/oh-my-ai-v0.0.1.md` (this file)

---

## Success Metrics

### v0.0.1 (MVP)
- [ ] 10 alpha testers successfully install and run first query
- [ ] Zero errors during `/install` wizard
- [ ] Positive feedback: "easier than AIShell/PSAI"

### v0.0.2 (Core Features)
- [ ] 50+ active users
- [ ] `/next` used in 30% of sessions (shows value)
- [ ] <5% error rate in provider calls

### v0.0.3 (Polish)
- [ ] 100+ active users
- [ ] 4+ star rating on PowerShell Gallery
- [ ] Mentioned in community articles/videos

---

## Open Questions

1. **Custom Prompts**: Should `//p <file>` be P2 or P3? (Depends on user demand)
2. **Cost Tracking**: Feasible for all providers? (OpenAI yes, Ollama no)
3. **oh-my-pwsh Dependency**: Standalone (copy code) or require oh-my-pwsh? → **Decision: Standalone (Opcja 1)**
4. **Linux Support**: Separate codebase or shared? → **Decision: Future, cross-platform PowerShell**

---

## ADR Summary

This specification includes 9 Architecture Decision Records:

| ADR | Title | Impact | Status |
|-----|-------|--------|--------|
| ADR-001 | Session ID Strategy | Prevents file collisions | ✅ Accepted |
| ADR-002 | Error Capture Mechanism | Enables `/? ` command | ✅ Accepted |
| ADR-003 | Context Truncation Strategy | Token budget control | ✅ Accepted |
| ADR-004 | Command Interception (PSReadLine) | Core architecture | ✅ Accepted |
| ADR-005 | Provider Fallback Config | Reliability | ✅ Accepted |
| ADR-006 | Tab Completion | UX enhancement | ✅ Accepted |
| ADR-007 | API Key Masking | Security | ✅ Accepted |
| ADR-008 | Update Check Strategy | User awareness | ✅ Accepted |
| ADR-009 | Fast envContext Collection | Performance (20x) | ✅ Accepted |

**Critical for MVP (P0)**:
- ADR-001, ADR-004 (core functionality)
- ADR-003, ADR-009 (performance)

**Important for P1**:
- ADR-002 (error fixing)
- ADR-005 (reliability)

**Polish for P2**:
- ADR-006, ADR-007, ADR-008 (UX/security)

---

## Links & References

- **Related Specs**: [oh-my-ai.md](./oh-my-ai.md), [oh-my-ai.questions-all.md](./oh-my-ai.questions-all.md)
- **Parent Project**: [oh-my-pwsh CLAUDE.md](../CLAUDE.md)
- **Dependencies**: PSAI (GitHub: dfinke/PSAI)
- **Competitors**: AIShell, ShellGPT, Copilot CLI

---

**End of Specification**
