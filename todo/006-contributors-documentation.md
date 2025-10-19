# 006 - Contributors Documentation

**Status:** active
**Priority:** P2
**Created:** 2025-10-19

## Goal

Create comprehensive `CONTRIBUTORS.md` that helps new developers understand:
- How to start development on oh-my-pwsh
- Tech stack and tools used
- Testing requirements
- Role of Claude Code as development assistant
- Documentation structure (CLAUDE.md, ADRs, runbooks, tasks)

## Context

User request:
> "trzeba zrobic plik CONTRIBUTORS.md gdzie opiszemy jak zaczac devlopment, u nas chyba regula jest taka ze pliku CALUDE.md i inne pliki dla claude opisuja rzeczy dla devlopera, ale trzeba by to opisac, oraz stack w jakim tomamy zrbione, ze sa testy, ze dev with claude code or at least read him - czy jako dock inzynier mozesz taki opisa i zonbaczyc jak u nas jest domnactacja rziona? moze tam tez opiac postawio walsnie jak ten claude soba zarzadza. na pewno trzbea nsapic ze claude to pdoatowy inzynier."

Key requirements:
- Explain CLAUDE.md and Claude-specific files are for AI assistant
- Describe tech stack (PowerShell, Pester, GitHub Actions, etc.)
- Mention testing infrastructure
- Recommend developing with Claude Code or at least reading CLAUDE.md
- Explain task management system (todo/, runbooks, ADRs)
- Position Claude as "junior engineer" / development assistant
- Add badges similar to shields.io style (user showed example with Hugo, Bootstrap, GitHub Pages, etc.)

## Tech Stack to Document

**Languages & Frameworks:**
- PowerShell 7.x
- Pester 5.x (testing framework)

**Development Tools:**
- Claude Code (AI development assistant)
- Git & GitHub
- Scoop/Winget (package managers)

**CI/CD:**
- GitHub Actions
- Optional git hooks (pre-commit)

**Enhanced Tools (optional):**
- bat, eza, ripgrep, fd, delta, fzf, zoxide

**Documentation:**
- Markdown
- MADR (ADRs)

## Structure Outline

```markdown
# Contributing to oh-my-pwsh

## Technologies Used
[Shields.io badges for: PowerShell, Pester, GitHub Actions, Claude Code, etc.]

## Prerequisites
- PowerShell 7.x
- Git
- (Optional) Claude Code

## Getting Started

### 1. Clone & Setup
### 2. Understanding the Documentation Structure
- CLAUDE.md - instructions for AI assistant
- ADRs - architectural decisions
- Runbooks - daily work logs
- Tasks - development tracking

### 3. Development with Claude Code
- Claude as junior engineer
- CLAUDE.md contains development conventions
- Even if not using Claude, READ CLAUDE.md for project conventions

### 4. Testing Requirements
- All enhanced tools must have fallback tests
- Run tests locally: ./scripts/Invoke-Tests.ps1
- CI/CD runs on GitHub Actions
- Coverage target: 75%

### 5. Task Management
- How to create tasks
- Using runbooks
- When to create ADRs

## Development Workflow
[Standard git workflow + task management]

## Code Style & Conventions
[Link to CLAUDE.md sections]
```

## Tasks

- [ ] Research shields.io badges for PowerShell, Pester, GitHub Actions, Claude Code
- [ ] Create CONTRIBUTORS.md structure
- [ ] Write "Technologies Used" section with badges
- [ ] Write "Getting Started" section
- [ ] Explain documentation structure (CLAUDE.md, ADRs, runbooks, tasks)
- [ ] Explain Claude Code role as development assistant
- [ ] Document testing requirements
- [ ] Add development workflow
- [ ] Link to existing docs (TESTING-STRATEGY.md, ARCHITECTURE.md)
- [ ] Update CLAUDE.md to reference CONTRIBUTORS.md
- [ ] Create runbook entry

## Success Criteria

- [ ] New developer can understand how to start
- [ ] Tech stack clearly documented with badges
- [ ] Claude Code role explained (assistant, not replacement for human decisions)
- [ ] Documentation structure explained (CLAUDE.md vs user docs)
- [ ] Testing requirements clear
- [ ] Task management system explained

## Notes

- User wants Claude positioned as "pomocnik" (helper/assistant), not autonomous agent
- CLAUDE.md and AI-specific files should be explained as developer documentation that AI reads
- Include shields.io style badges similar to user's example (Hugo, Bootstrap, etc.)
- Less badges than example, but relevant ones for our stack

## Related

- [CLAUDE.md](../CLAUDE.md) - Contains development conventions
- [TESTING-STRATEGY.md](../docs/TESTING-STRATEGY.md) - Testing requirements
- [ARCHITECTURE.md](../docs/ARCHITECTURE.md) - Project architecture
- [adr/README.md](../adr/README.md) - ADR conventions
