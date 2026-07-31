# 014 - NerdFont unit tests write to the real Windows Terminal settings.json

**Status:** `backlog`
**Priority:** P2 (test isolation — side effects on the dev machine)
**Complexity:** Small (1-2 hours)
**Type:** Test Quality

---

## Problem Statement

`tests/Unit/NerdFonts.Tests.ps1` (`Describe "Set-WindowsTerminalFont"`, line 213+)
calls the real production function `Set-WindowsTerminalFont -FontName "Test Font"`
from `modules/nerd-fonts.ps1`. That function resolves the real
`...\WindowsTerminal\...\settings.json`, backs it up, and rewrites the font.

The tests try to isolate (they create a temp settings file, ~line 245) but do not
mock `Set-WindowsTerminalFont` or redirect the settings path it actually uses, so
part of the work lands on the developer's real `settings.json`. Observed in the
pre-commit run: `Created backup: ...settings.json.backup-...`, `Font set to: Test Font`.

### Impact
- A "unit" test mutates real machine state (Windows Terminal config).
- Backup files pile up next to the real settings.
- Pre-commit is slow (~30s) and has side effects, which pushes contributors to
  `git commit --no-verify` (happened during the 2026-07-31 cc-cleanup session).

## Proposed Fix
- Mock `Set-WindowsTerminalFont` in the unit tests, OR
- Make the function accept an injectable settings path and pass the temp file in
  the test (no default-path fallback during tests).
- Move any test that must touch a real path into `tests/Integration/`, gated so it
  never runs in the fast pre-commit unit pass.

## Acceptance Criteria
- Running the unit suite does not create/modify any file under the real
  `WindowsTerminal\...\LocalState\`.
- No `settings.json.backup-*` produced by a unit run.
