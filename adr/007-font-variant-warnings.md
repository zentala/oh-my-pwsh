# ADR-007: Nerd Font Variant Warnings (Regular vs Mono)

**Status:** Accepted
**Date:** 2025-11-06
**Deciders:** zentala, Claude Code

## Context

**User reported issue:**
> "I tested multiple Nerd Fonts: Agave, FiraCode, UbuntuMono. The Mono variants have icons that are too small and hard to see. What's the difference between Regular, Mono, and Propo variants?"

**Investigation findings:**
- ✅ **FiraCode Nerd Font** (Regular) - Icons display well
- ✅ **Agave Nerd Font Propo** - Icons display well (proportional)
- ❌ **UbuntuMono Nerd Font Mono** - Icons too small
- ❌ **Agave Nerd Font Mono** (assumed) - Icons too small

### Font Variant Differences

**1. Regular (Default)**
- Code: Fixed-width (monospace)
- Icons: Natural width, not compressed
- **Result: Icons display at readable size** ✅
- Use case: Terminal, code editors

**2. Mono (Strict Monospace)**
- Code: Fixed-width
- Icons: **Compressed to match character width**
- **Result: Icons too small, hard to read** ❌
- Use case: Rare - terminals that require strict monospace

**3. Propo (Proportional)**
- Code: Variable width
- Icons: Full size, not compressed
- **Result: Icons display well, code less aligned** ⚠️
- Use case: UI text, documentation (not terminals)

### Problem
Users could accidentally install Mono variants and experience poor icon rendering. Our installer didn't warn about this.

## Decision

**Add explicit warnings about font variants throughout the installation flow:**

### 1. Update `Get-RecommendedNerdFonts` Documentation

```powershell
function Get-RecommendedNerdFonts {
    <#
    .DESCRIPTION
        IMPORTANT: Always use REGULAR variants, NOT Mono variants!
        - Regular: Icons have natural width (✅ best for terminals)
        - Mono: Icons compressed to fixed width (❌ too small, hard to see)
        - Propo: Variable width (⚠️ good for UI, not for code)
    #>
}
```

### 2. Add Variant Property to Recommendations

```powershell
[PSCustomObject]@{
    Name = "CaskaydiaCove Nerd Font"
    ScoopName = "CascadiaCode-NF"
    Description = "Microsoft's Cascadia Code with Nerd Font icons"
    Why = "Clean, professional, excellent ligatures"
    Variant = "Regular (default)"  # NEW
}
```

### 3. Show Warning During Interactive Installation

```
📋 Recommended Nerd Fonts for PowerShell:

⚠️  IMPORTANT: Use REGULAR variants only!
   • Regular variant = Icons display at natural size ✅
   • Mono variant = Icons too small, hard to see ❌
   (All fonts below install the correct Regular variant)

  1. CaskaydiaCove Nerd Font (recommended)
     Microsoft's Cascadia Code with Nerd Font icons
     Why: Clean, professional, excellent ligatures

  2. FiraCode Nerd Font
     ...
```

### 4. Validate Recommendations (Tests)

Ensure our recommendations don't include Mono variants:

```powershell
It "All fonts use Regular variant (not Mono variant suffix)" {
    $result = Get-RecommendedNerdFonts

    foreach ($font in $result) {
        $font.Variant | Should -BeLike "*Regular*"
        # Font name should NOT end with " Nerd Font Mono"
        $font.Name | Should -Not -Match '\sNerd\sFont\sMono$'
    }
}
```

### 5. Special Handling for Font Families with "Mono"

Some fonts have "Mono" in the family name (not variant):
- ✅ **JetBrainsMono Nerd Font** (Regular) - OK, "Mono" is family name
- ❌ **JetBrains Nerd Font Mono** - Mono variant, avoid

Test distinguishes between family name and variant suffix.

## Consequences

### Positive
- ✅ **Prevents user frustration** - Warning before installation
- ✅ **Educational** - Users learn about variants
- ✅ **Better icon rendering** - Users choose correct variants
- ✅ **Validated recommendations** - Tests ensure we don't recommend Mono
- ✅ **Clear messaging** - Visual warnings with icons (✅ ❌ ⚠️)

### Negative
- ⚠️ **More text to read** - Longer installation prompts
- ⚠️ **May confuse some users** - "What's a variant?"
- ⚠️ **Doesn't prevent** - Users can still install Mono via scoop directly

### Neutral
- 🔄 **Documentation heavy** - Multiple places with warnings
- 🔄 **Edge cases** - Fonts like JetBrainsMono (family name contains "Mono")

## Alternatives Considered

### Alternative 1: Block Mono Variants
```powershell
if ($FontName -match 'Mono-NF$') {
    throw "Mono variants not supported. Use Regular variant."
}
```
**Rejected** - Too restrictive, breaks for JetBrainsMono

### Alternative 2: Automatic Detection & Correction
```powershell
# If user tries to install Mono, auto-switch to Regular
if ($FontName -eq "FiraCode-Mono-NF") {
    $FontName = "FiraCode-NF"
    Write-Host "Switched to Regular variant for better icons"
}
```
**Rejected** - Too "magical", confusing behavior

### Alternative 3: Post-Install Validation
After installation, detect if Mono variant was installed and warn

**Rejected** - Too late, font already installed

### Alternative 4: Scoop Bucket Curation
Only include Regular variants in nerd-fonts bucket

**Rejected** - We don't control the bucket, Mono variants have legitimate uses

## Implementation Details

### Warning Display Format
```powershell
Write-Host "⚠️  IMPORTANT: Use REGULAR variants only!" -ForegroundColor Yellow
Write-Host "   • Regular variant = Icons display at natural size ✅" -ForegroundColor Gray
Write-Host "   • Mono variant = Icons too small, hard to see ❌" -ForegroundColor Gray
Write-Host "   (All fonts below install the correct Regular variant)" -ForegroundColor DarkGray
```

### Font Name Pattern Matching
```powershell
# BAD: Ends with " Nerd Font Mono" (variant suffix)
"FiraCode Nerd Font Mono"         # ❌ Avoid
"Ubuntu Nerd Font Mono"           # ❌ Avoid

# GOOD: "Mono" is part of family name, not variant
"JetBrainsMono Nerd Font"         # ✅ OK
"UbuntuMono Nerd Font"            # ✅ OK (if not Mono variant)

# Pattern to detect Mono variant:
if ($fontName -match '\sNerd\sFont\sMono$') {
    # This is a Mono variant
}
```

### Scoop Package Naming
```powershell
# Regular variants (recommended)
"CascadiaCode-NF"      # → CaskaydiaCove Nerd Font
"FiraCode-NF"          # → FiraCode Nerd Font
"JetBrainsMono-NF"     # → JetBrainsMono Nerd Font (family has Mono, but not Mono variant)

# Mono variants (avoid)
"CascadiaCode-Mono-NF" # → Would be Mono variant
"FiraCode-Mono-NF"     # → Would be Mono variant
```

## Testing Strategy

1. **Recommendation validation** (`NerdFonts.Tests.ps1`)
   - All recommendations have Variant property
   - No Mono variant suffixes in recommendations
   - JetBrainsMono passes (family name ≠ variant)

2. **Documentation tests**
   - Function help text mentions variants
   - Warning text displays correctly

3. **User experience tests** (manual)
   - Install flow shows warning
   - Warning is visible and clear
   - User understands difference

## Related

- **ADR**: [ADR-006: Windows Terminal Auto-Configuration](./006-windows-terminal-auto-config.md)
- **Module**: `modules/nerd-fonts.ps1`
- **Tests**: `tests/Unit/NerdFonts.Tests.ps1`
- **User Report**: Session 2025-11-06 - Font variant discovery

## References

- [Nerd Fonts Documentation](https://www.nerdfonts.com/)
- [Font Variants Explanation](https://github.com/ryanoasis/nerd-fonts/wiki/FAQ-and-Troubleshooting)

## Future Considerations

- Add visual preview of icon sizes for different variants?
- Detect installed Mono fonts and suggest switching to Regular?
- Add configuration option to prefer Propo variants?
- Create comparison screenshots for documentation?
