# ADR-008: Linux Flag Handling and `rr` Alias

**Status:** Accepted
**Date:** 2025-11-06
**Deciders:** Claude Code (with user approval)

## Context

PowerShell has inherent parameter name conflicts that prevent direct implementation of Linux-style short flags for file operations:

1. **Parameter Ambiguity**: `-f` flag is ambiguous in `Remove-Item`, `Copy-Item`, and `Move-Item` cmdlets because PowerShell accepts partial parameter names, and both `-Force` and `-Filter` start with 'f'.

2. **Combined Flags**: Linux-style combined flags like `-rf` cannot be parsed as a single parameter in PowerShell's parameter binding system.

3. **User Expectations**: Users migrating from Linux expect `rm -rf directory/` to work as it does in bash/zsh, creating friction during Windows/PowerShell adoption.

4. **Project Philosophy**: oh-my-pwsh aims to provide "painless migration from Linux... **learning about PowerShell commands on the way**" (from CLAUDE.md).

## Decision

Implement a dual approach combining education with convenience:

### 1. Full PowerShell Parameter Names (Primary)

Use complete parameter names to avoid conflicts:
```powershell
rm -Recurse -Force path/
cp -Recurse -Force src/ dest/
mv -Force oldname newname
```

### 2. Quick Alias `rr` (Secondary)

Provide `rr` function as a memorable shortcut for recursive+force removal:
```powershell
rr directory/       # Equivalent to: rm -Recurse -Force
rr file1 file2      # Multiple paths supported
```

### 3. Educational Hints

When users call functions without required arguments, show helpful usage:
```
Usage: rm [-Recurse] [-Force] <path>...
  Quick alias: rr <path>  (recursive + force)
  → Remove-Item [-Recurse] [-Force] <path>
```

## Consequences

### Positive

✅ **Educational** - Users learn PowerShell conventions (full parameter names)
✅ **Convenient** - `rr` alias provides quick workflow for power users
✅ **Consistent** - Aligns with project philosophy and existing aliases (`ll`, `la`)
✅ **Maintainable** - No parameter binding hacks or workarounds
✅ **Discoverable** - Usage hints guide users to correct syntax
✅ **Memorable** - `rr` = "remove recursive" (easy mnemonic)

### Negative

❌ **Not Exact Linux Behavior** - `rm -rf` won't work (users must adapt)
❌ **Requires Learning** - Users must learn either full names or new alias
❌ **Breaking Change** - If users had scripts using `rm` alias, they need updates

### Neutral

- Sets precedent for future Linux compatibility functions
- Establishes pattern: full names + memorable shortcuts when conflicts exist

## Alternatives Considered

### Option 1: Full Names Only (Rejected)

```powershell
rm -Recurse -Force directory/
```

**Pros:** Pure PowerShell way, no confusion
**Cons:** Too verbose for daily use, poor DX for Linux users

**Why Rejected:** Goes against project goal of "painless migration"

### Option 2: Function Bypass with Parsing (Rejected)

```powershell
function rm {
    # Parse $args manually to handle -rf
    if ($args[0] -match '^-[rf]+$') { ... }
}
```

**Pros:** Closer to Linux syntax
**Cons:** Fragile, bypasses PowerShell parameter system, hard to maintain

**Why Rejected:** Violates PowerShell best practices, loses tab completion

### Option 3: Alternative Short Flags (Rejected)

```powershell
rm -rec -force path/    # -rec instead of -r
```

**Pros:** Shorter than full names
**Cons:** Not standard Linux OR PowerShell, confusing middle ground

**Why Rejected:** Worst of both worlds, no clear advantage

## Implementation Details

### Functions Affected

- `rm` - Uses `-Recurse` and `-Force` parameters
- `rr` - New function, always recursive+force
- `rmdir` - Wrapper around `rr` (always recursive in PowerShell anyway)
- `cp` - Uses `-Recurse` and `-Force` parameters
- `mv` - Uses `-Force` parameter

### Naming Rationale: Why `rr`?

- **Memorable**: "remove recursive" or "remove really"
- **Short**: 2 characters (same length as `rm`)
- **No Conflicts**: Not used by PowerShell or common tools
- **Consistent**: Follows pattern of `ll`, `la` (short aliases)

### rmdir Behavior

PowerShell's native `rmdir` alias already exists but only removes empty directories. Our implementation:
- Removes default `rmdir` alias
- Replaces with function that calls `rr` (always recursive)
- Matches PowerShell's `Remove-Item` behavior (recursive by default)

## Testing Strategy

All functions have comprehensive unit tests covering:
- Basic file/directory operations
- Parameter combinations (`-Recurse`, `-Force`, combined)
- Multiple path arguments
- Usage message display
- Error handling

**Test Coverage:** 24 new tests, all 191 project tests passing

## Documentation

Updated files:
- `docs/linux-compatibility.md` - User-facing documentation with examples
- `modules/linux-compat.ps1` - Inline comments explaining design
- This ADR - Architectural rationale

## Related

- **Task:** [todo/done/...] (Linux flag implementation)
- **Code:** `modules/linux-compat.ps1:158-274`
- **Tests:** `tests/Unit/LinuxCompat.Tests.ps1:291-494`
- **Docs:** `docs/linux-compatibility.md:71-106`
- **ADRs:**
  - [ADR-001](./001-pester-test-framework.md) - Testing framework
  - [ADR-002](./002-test-isolation-strategy.md) - Test isolation

## Future Considerations

- Monitor user feedback on `rr` alias adoption
- Consider adding more memorable aliases if similar conflicts arise
- May need to document common "gotchas" for Linux users
- Could add shell hints/warnings when users try `rm -rf` (detect and suggest `rr`)

## Review History

- 2025-11-06: Initial decision made during user request for `rm -rf` support
- User requested: "mamy tu aliasy, rm nie usuwa z subfolderami a rm -rf nie dziala"
- Solution designed collaboratively with user approval
