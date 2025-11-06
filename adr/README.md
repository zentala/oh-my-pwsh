# Architecture Decision Records (ADR)

## What is an ADR?

Architecture Decision Records (ADRs) document important architectural and design decisions made during the development of oh-my-pwsh. Each ADR captures the context, decision, and consequences of a specific choice.

## Format

We use the [MADR](https://adr.github.io/madr/) (Markdown Any Decision Records) format:

```markdown
# [Number]. [Title]

**Status:** [Proposed | Accepted | Deprecated | Superseded]
**Date:** YYYY-MM-DD
**Deciders:** [Who made the decision]

## Context

What is the issue we're facing?

## Decision

What did we decide?

## Consequences

What are the results of this decision?

### Positive
- Good thing 1
- Good thing 2

### Negative
- Trade-off 1
- Trade-off 2

### Neutral
- Other impact 1

## Alternatives Considered

What other options did we evaluate?

## Related
- [Link to related ADR]
- [Link to task]
- [Link to docs]
```

## Naming Convention

- **Format**: `NNN-short-title.md`
- **Example**: `001-pester-test-framework.md`
- **Number**: Zero-padded 3 digits
- **Title**: Lowercase with hyphens

## Index of ADRs

### Testing Infrastructure
- [ADR-001](./001-pester-test-framework.md) - Pester as Test Framework
- [ADR-002](./002-test-isolation-strategy.md) - Test Isolation Strategy
- [ADR-003](./003-coverage-targets.md) - Code Coverage Targets
- [ADR-004](./004-git-hooks-optional.md) - Git Hooks Optional

### Installation & Setup
- [ADR-005](./005-default-full-installation.md) - Default Full Installation with Opt-Out Flags
- [ADR-006](./006-windows-terminal-auto-config.md) - Windows Terminal Automatic Font Configuration
- [ADR-007](./007-font-variant-warnings.md) - Nerd Font Variant Warnings (Regular vs Mono)

### Linux Compatibility
- [ADR-008](./008-linux-flags-and-rr-alias.md) - Linux Flag Handling and `rr` Alias

## How to Create a New ADR

1. Determine the next number (NNN)
2. Create file: `adr/NNN-short-title.md`
3. Use the template above
4. Link it in this README
5. Link it in related task files (`todo/`)
6. Link it in related documentation (`docs/`)
7. Update `CLAUDE.md` if it affects development conventions

## When to Create an ADR

Create an ADR when:
- Making a significant architectural decision
- Choosing between multiple valid approaches
- Setting a technical standard or convention
- Making a trade-off that affects multiple components
- Establishing a pattern to be followed project-wide

**Do NOT create an ADR for:**
- Minor implementation details
- Obvious choices with no alternatives
- Temporary workarounds
- Personal preferences without technical impact

## Related Documentation

- [CLAUDE.md](../CLAUDE.md) - Development guidelines
- [todo/INDEX.md](../todo/INDEX.md) - Task tracking
- [docs/](../docs/) - Technical documentation
