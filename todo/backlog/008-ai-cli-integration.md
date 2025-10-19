# 008 - AI CLI Integration (Research)

**Status:** backlog (research)
**Priority:** P4 (low - research task)
**Created:** 2025-10-19

## Goal

Research and design architecture for integrating AI assistants (Claude, Gemini, OpenAI Codex) directly into PowerShell console, allowing users to ask questions and delegate tasks to AI from the terminal.

## User Story

> "As a developer working in the terminal, I want to quickly ask an AI assistant for help or delegate a task without leaving my console, so I can stay in my flow and get instant answers or code generation."

**Example interaction:**
```powershell
PS> ai "how do I list all files modified in the last 7 days?"

🤖 Claude suggests:
Get-ChildItem -Recurse | Where-Object { $_.LastWriteTime -gt (Get-Date).AddDays(-7) }

[Run] [Copy] [Explain] [Cancel]
```

## Context

User's vision:
> "wsparice dla gemini cli, codex from openai i claude, ze mozesz dostac sugestie aby je zaisntalwoac i praowac nad jakimis rzeczami tak ze ja podam Ci co mozemy zroic (pomysl) a ty go przekazesz do np claude z moim proptem. to bedzie bardziej zaawansowana opcja sugestii. albo w ogole interacja ai do konsoli."

**Advanced use case:**
- User has an idea/problem
- User types `ai "I want to add feature X"`
- System passes prompt to Claude/Gemini/Codex
- AI generates code/suggestions
- User can review, run, or save the result

## Research Questions

### 1. Available AI CLI Tools

**Claude:**
- Official Claude CLI? (check Anthropic docs)
- Community wrappers?
- API integration via PowerShell?

**Gemini:**
- Google AI Studio CLI?
- `gcloud ai` integration?
- Community tools?

**OpenAI:**
- Official `openai` CLI?
- Codex-specific tools?
- ChatGPT API via PowerShell?

**GitHub Copilot CLI:**
- `gh copilot` - GitHub's official CLI for Copilot
- Already available if user has Copilot license
- Integration possibilities?

### 2. Architecture Options

**Option A: Wrapper Function**
```powershell
function ai {
    param([string]$Prompt)

    # Detect which AI CLI is available
    if (Get-Command "claude" -ErrorAction SilentlyContinue) {
        claude-cli $Prompt
    } elseif (Get-Command "gemini" -ErrorAction SilentlyContinue) {
        gemini-cli $Prompt
    } elseif (Get-Command "gh" -ErrorAction SilentlyContinue) {
        gh copilot suggest $Prompt
    } else {
        Show-AISuggestion -Prompt $Prompt
    }
}
```

**Option B: Interactive Menu**
```powershell
PS> ai-setup

Which AI assistant would you like to use?
  1. Claude (Anthropic) - Best for code explanation and architecture
  2. Gemini (Google) - Fast, good for general queries
  3. GitHub Copilot - Best for code generation
  4. OpenAI GPT - Versatile, good for all tasks

Select [1/2/3/4]:
```

**Option C: Plugin Architecture**
```powershell
# modules/ai-providers/claude.ps1
# modules/ai-providers/gemini.ps1
# modules/ai-providers/openai.ps1
# modules/ai-providers/copilot.ps1

# Dynamic loading based on availability
```

### 3. User Experience Flow

**Discovery:**
```powershell
PS> ai "help"

[!] AI assistant not configured yet.

💡 Available AI tools for PowerShell:
  1. GitHub Copilot CLI (gh copilot)
     - Best for: Code suggestions, shell commands
     - Install: gh extension install github/gh-copilot
     - Auth: GitHub account with Copilot license

  2. Claude CLI (unofficial)
     - Best for: Code review, architecture questions
     - Install: npm install -g @anthropic/claude-cli
     - Auth: Anthropic API key

  3. Google Gemini CLI
     - Best for: Fast queries, general help
     - Install: pip install google-generativeai
     - Auth: Google Cloud API key

Would you like to install one? [1/2/3/n]:
```

**Configuration:**
```powershell
# Store API keys securely
$env:ANTHROPIC_API_KEY = Read-Host "Enter Anthropic API key" -AsSecureString
# or use Windows Credential Manager
```

**Usage:**
```powershell
# Simple query
PS> ai "how to compress folder"

# Code generation
PS> ai --code "function to get disk usage"

# Explain existing command
PS> ai --explain "Get-ChildItem -Recurse | Measure-Object -Property Length -Sum"

# Interactive mode
PS> ai --interactive
🤖 AI Interactive Mode (type 'exit' to quit)
You: how do I...
AI: ...
```

### 4. Security & Privacy

**Concerns:**
- API keys storage (use Windows Credential Manager)
- Prompt data leaving local machine
- Code execution from AI suggestions (require user confirmation)
- Rate limiting / API costs

**Mitigations:**
- Always show code before executing
- User confirmation required for destructive operations
- Local credential storage
- Transparent about what data is sent to AI

### 5. Integration with oh-my-pwsh

**Smart Suggestions Integration:**
- If command not found → suggest AI help
- Example: `unknowncommand` → "Command not found. Ask AI for help? [Y/n]"

**Learning Mode Integration:**
- AI can explain PowerShell equivalents
- `ai --learn "grep"` → explains `Select-String` with examples

**Help System Integration:**
- `help ai` → shows AI capabilities
- `ai --status` → shows which AI tools are configured

## Technical Considerations

### API Integration

**PowerShell HTTP Requests:**
```powershell
# Call Claude API
$headers = @{
    "x-api-key" = $env:ANTHROPIC_API_KEY
    "anthropic-version" = "2023-06-01"
    "content-type" = "application/json"
}

$body = @{
    model = "claude-3-sonnet-20240229"
    messages = @(
        @{
            role = "user"
            content = $Prompt
        }
    )
    max_tokens = 1024
} | ConvertTo-Json

$response = Invoke-RestMethod -Uri "https://api.anthropic.com/v1/messages" `
    -Method Post `
    -Headers $headers `
    -Body $body
```

### Rate Limiting

- Implement caching for repeated queries
- Respect API rate limits
- Show cost warnings for expensive operations

### Offline Mode

- Cache common responses locally
- Fallback to help system if no internet
- Don't break if AI unavailable

## Proposed Architecture

### Module Structure

```
modules/
├── ai-assistant.ps1           # Main AI wrapper
├── ai-providers/
│   ├── provider-base.ps1     # Abstract base class
│   ├── claude.ps1            # Claude provider
│   ├── gemini.ps1            # Gemini provider
│   ├── openai.ps1            # OpenAI provider
│   └── copilot.ps1           # GitHub Copilot provider
├── ai-security.ps1           # API key management
└── ai-ui.ps1                 # Interactive prompts
```

### Base Provider Interface

```powershell
class AIProvider {
    [string] $Name
    [string] $InstallCommand
    [bool] $IsAvailable
    [hashtable] $Config

    [bool] CheckAvailability() { }
    [string] SendPrompt([string]$prompt) { }
    [void] Configure() { }
    [string] GetInstallInstructions() { }
}
```

### Configuration

```powershell
# config.ps1
$global:OhMyPwsh_EnableAI = $true
$global:OhMyPwsh_PreferredAI = "claude"  # claude | gemini | openai | copilot
$global:OhMyPwsh_AIAutoSuggest = $false  # Auto-suggest on command-not-found
```

## Tasks (When Moving to Active)

- [ ] Research available AI CLI tools (Claude, Gemini, OpenAI, Copilot)
- [ ] Test GitHub Copilot CLI (`gh copilot`)
- [ ] Design provider plugin architecture
- [ ] Implement base `AIProvider` class
- [ ] Implement at least one provider (GitHub Copilot - easiest to start)
- [ ] Design secure API key storage (Windows Credential Manager)
- [ ] Create `ai` wrapper function
- [ ] Add interactive setup (`ai-setup`)
- [ ] Integrate with command-not-found suggestions
- [ ] Write tests for provider detection
- [ ] Write tests for API key security
- [ ] Document security considerations
- [ ] Create user documentation
- [ ] Add to README under "Coming Soon"

## Success Criteria

- [ ] User can type `ai "question"` and get response
- [ ] System detects which AI tools are available
- [ ] Easy setup/configuration flow
- [ ] API keys stored securely
- [ ] User confirmation required before executing AI-generated code
- [ ] Works offline (graceful degradation)
- [ ] Respects rate limits
- [ ] Tests verify provider detection and fallbacks

## Future Extensions

- Context-aware suggestions (knows current directory, git repo, recent commands)
- Multi-turn conversations (chat mode)
- Code review workflow (`ai review myfile.ps1`)
- Automated commit message generation (`ai commit`)
- Shell command correction (`ai fix "last command"`)
- Integration with oh-my-stats (ask AI about system performance)

## Related

- [007-smart-editor-suggestions.md](./007-smart-editor-suggestions.md) - Similar suggestion pattern
- [modules/linux-compat.ps1](../../modules/linux-compat.ps1) - Existing command wrappers
- [CLAUDE.md](../../CLAUDE.md) - DevEx mindset

## Notes

- **Priority: P4 (research)** - This is exploratory, not urgent
- Start with GitHub Copilot CLI (easiest, many users already have access)
- Keep architecture pluggable (easy to add new providers)
- Security first (never auto-execute AI code)
- Transparent about data sent to APIs
- Respect user's choice of AI provider

## Research Links

- GitHub Copilot CLI: https://docs.github.com/en/copilot/github-copilot-in-the-cli
- Anthropic API: https://docs.anthropic.com/claude/reference/
- Google AI Studio: https://ai.google.dev/
- OpenAI API: https://platform.openai.com/docs/api-reference
