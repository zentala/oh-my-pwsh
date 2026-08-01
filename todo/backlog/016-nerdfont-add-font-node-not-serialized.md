# 016 - Set-WindowsTerminalFont: font.face lost when the font node is missing

**Status:** `backlog`
**Priority:** P3 (edge case — only when settings.json has no `profiles.defaults.font`)
**Complexity:** Small (<1 hour)
**Type:** Bug

---

## Problem Statement

In `Set-WindowsTerminalFont` (`modules/nerd-fonts.ps1`), when the target
`settings.json` does **not** already have `profiles.defaults.font`, the code adds it:

```powershell
$settings.profiles.defaults | Add-Member -NotePropertyName "font" -NotePropertyValue @{} -Force
...
$settings.profiles.defaults.font | Add-Member -NotePropertyName "face" -NotePropertyValue $FontName -Force
```

`font` is added as a **hashtable**, then `face` is added onto it via `Add-Member`.
A NoteProperty attached to a hashtable is not serialized by `ConvertTo-Json` (it
emits the dictionary keys, not adapted members), so the written file ends up with
`"font": {}` and `font.face` comes out `null`. The font is silently not applied.

Found while fixing task #014 (test isolation). A real WT `settings.json` usually
already has a font node, so the common path works — this only bites a fresh/minimal
settings file.

## Proposed Fix

- Build the `font` node as a `[PSCustomObject]` (or set the hashtable key directly:
  `$settings.profiles.defaults.font = @{ face = $FontName }`) instead of
  `Add-Member` onto a hashtable, so `ConvertTo-Json` serializes `face`.

## Acceptance Criteria

- Given a settings file with `profiles.defaults` but no `font`, calling
  `Set-WindowsTerminalFont -FontName X -SettingsPath <temp>` writes
  `profiles.defaults.font.face == X`.
- Add a unit test in `tests/Unit/NerdFonts.Tests.ps1` seeding a settings file with
  no `font` node and asserting the written `face` (temp path, no real settings).
