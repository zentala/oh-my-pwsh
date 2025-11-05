# =====================================================
# Nerd Fonts Detection and Installation
# =====================================================

function Test-NerdFontInstalled {
    <#
    .SYNOPSIS
        Detects if any Nerd Font is installed on the system

    .DESCRIPTION
        Checks Windows registry for installed fonts with "Nerd" in the name.
        Nerd Fonts typically have names like:
        - CascadiaCode Nerd Font
        - FiraCode Nerd Font
        - JetBrainsMono Nerd Font

    .OUTPUTS
        [PSCustomObject] with properties:
        - Installed: Boolean - true if any Nerd Font found
        - Fonts: Array of detected Nerd Font names
        - Count: Number of Nerd Fonts found

    .EXAMPLE
        $nf = Test-NerdFontInstalled
        if ($nf.Installed) {
            Write-Host "Found $($nf.Count) Nerd Fonts: $($nf.Fonts -join ', ')"
        }
    #>

    try {
        # Check both system and user font registries
        $registryPaths = @(
            "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts",  # System fonts
            "HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"   # User fonts
        )

        $nerdFonts = @()

        foreach ($path in $registryPaths) {
            if (Test-Path $path) {
                $fonts = Get-ItemProperty -Path $path -ErrorAction SilentlyContinue
                if ($fonts) {
                    $fontNames = $fonts | Get-Member -MemberType NoteProperty |
                        Where-Object { $_.Name -like "*Nerd*Font*" -or $_.Name -like "*NF*Mono*" } |
                        Select-Object -ExpandProperty Name

                    if ($fontNames) {
                        $nerdFonts += $fontNames
                    }
                }
            }
        }

        # Remove duplicates and return results
        $uniqueFonts = $nerdFonts | Select-Object -Unique

        return [PSCustomObject]@{
            Installed = ($uniqueFonts.Count -gt 0)
            Fonts = $uniqueFonts
            Count = $uniqueFonts.Count
        }

    } catch {
        # If registry check fails, assume not installed
        return [PSCustomObject]@{
            Installed = $false
            Fonts = @()
            Count = 0
        }
    }
}

function Get-RecommendedNerdFonts {
    <#
    .SYNOPSIS
        Returns list of recommended Nerd Fonts for PowerShell profiles

    .DESCRIPTION
        Provides curated list of best Nerd Fonts for terminal use with install info

    .OUTPUTS
        Array of PSCustomObjects with font recommendations
    #>

    return @(
        [PSCustomObject]@{
            Name = "CaskaydiaCove Nerd Font"
            ScoopName = "CascadiaCode-NF"
            Description = "Microsoft's Cascadia Code with Nerd Font icons (recommended)"
            Why = "Clean, professional, designed for coding, excellent ligature support"
        },
        [PSCustomObject]@{
            Name = "FiraCode Nerd Font"
            ScoopName = "FiraCode-NF"
            Description = "Popular programming font with excellent ligatures"
            Why = "Best ligatures, very popular, great readability"
        },
        [PSCustomObject]@{
            Name = "JetBrainsMono Nerd Font"
            ScoopName = "JetBrainsMono-NF"
            Description = "JetBrains' monospace font optimized for developers"
            Why = "Designed specifically for IDEs, excellent character distinction"
        },
        [PSCustomObject]@{
            Name = "Meslo Nerd Font"
            ScoopName = "Meslo-NF"
            Description = "Customized version of Apple's Menlo font"
            Why = "Safe choice, works everywhere, very readable"
        }
    )
}

function Install-NerdFonts {
    <#
    .SYNOPSIS
        Interactive helper to install Nerd Fonts on Windows

    .DESCRIPTION
        Guides user through Nerd Font installation using scoop or manual download.
        Checks if already installed, recommends best fonts, provides installation commands.

    .PARAMETER FontName
        Optional: Specific font to install (e.g., "CascadiaCode-NF")
        If not specified, shows interactive menu

    .PARAMETER Silent
        Install recommended font (CascadiaCode-NF) without prompts

    .EXAMPLE
        Install-NerdFonts
        # Shows interactive menu

    .EXAMPLE
        Install-NerdFonts -FontName "FiraCode-NF"
        # Installs specific font

    .EXAMPLE
        Install-NerdFonts -Silent
        # Installs CascadiaCode-NF without prompts
    #>

    param(
        [string]$FontName,
        [switch]$Silent
    )

    Write-Host "`n🔤 Nerd Fonts Installer`n" -ForegroundColor Cyan

    # Check if already installed
    $existing = Test-NerdFontInstalled
    if ($existing.Installed) {
        Write-Host "✓ Nerd Fonts already installed:" -ForegroundColor Green
        foreach ($font in $existing.Fonts) {
            Write-Host "  • $font" -ForegroundColor Gray
        }
        Write-Host ""

        if (-not $Silent) {
            $continue = Read-Host "Install another Nerd Font? (y/N)"
            if ($continue -ne 'y' -and $continue -ne 'Y') {
                return
            }
        }
    } else {
        Write-Host "⚠️  No Nerd Fonts detected" -ForegroundColor Yellow
        Write-Host ""
    }

    # Check if scoop is available
    $scoopAvailable = Get-Command scoop -ErrorAction SilentlyContinue

    if (-not $scoopAvailable) {
        Write-Host "❌ Scoop not found - required for easy font installation" -ForegroundColor Red
        Write-Host ""
        Write-Host "📌 Install scoop first:" -ForegroundColor Cyan
        Write-Host "   Set-ExecutionPolicy RemoteSigned -Scope CurrentUser" -ForegroundColor Gray
        Write-Host "   irm get.scoop.sh | iex" -ForegroundColor Gray
        Write-Host ""
        Write-Host "📌 Or install manually:" -ForegroundColor Cyan
        Write-Host "   1. Visit: https://www.nerdfonts.com/font-downloads" -ForegroundColor Gray
        Write-Host "   2. Download a font (CascadiaCode recommended)" -ForegroundColor Gray
        Write-Host "   3. Extract and install .ttf files" -ForegroundColor Gray
        Write-Host "   4. Restart terminal" -ForegroundColor Gray
        Write-Host ""
        return
    }

    # Get recommended fonts
    $recommended = Get-RecommendedNerdFonts

    if ($Silent) {
        # Silent mode - install CascadiaCode-NF
        $FontName = "CascadiaCode-NF"
        Write-Host "Installing recommended font: CaskaydiaCove Nerd Font..." -ForegroundColor Cyan
    } elseif (-not $FontName) {
        # Interactive mode - show menu
        Write-Host "📋 Recommended Nerd Fonts for PowerShell:" -ForegroundColor Yellow
        Write-Host ""

        for ($i = 0; $i -lt $recommended.Count; $i++) {
            $font = $recommended[$i]
            Write-Host "  $($i + 1). " -NoNewline -ForegroundColor Cyan
            Write-Host $font.Name -ForegroundColor White
            Write-Host "     $($font.Description)" -ForegroundColor Gray
            Write-Host "     Why: $($font.Why)" -ForegroundColor DarkGray
            Write-Host ""
        }

        Write-Host "  0. Cancel" -ForegroundColor Gray
        Write-Host ""

        $choice = Read-Host "Select font to install (1-$($recommended.Count), or 0 to cancel)"

        if ($choice -eq '0' -or $choice -eq '') {
            Write-Host "Cancelled" -ForegroundColor Gray
            return
        }

        $index = [int]$choice - 1
        if ($index -ge 0 -and $index -lt $recommended.Count) {
            $FontName = $recommended[$index].ScoopName
        } else {
            Write-Host "Invalid choice" -ForegroundColor Red
            return
        }
    }

    # Install via scoop
    Write-Host ""
    Write-Host "📦 Installing $FontName..." -ForegroundColor Cyan

    # Add nerd-fonts bucket if not added
    $buckets = scoop bucket list
    if ($buckets -notcontains 'nerd-fonts') {
        Write-Host "  Adding nerd-fonts bucket..." -ForegroundColor Gray
        scoop bucket add nerd-fonts
    }

    # Install font
    try {
        scoop install $FontName
        Write-Host ""
        Write-Host "✓ Font installed successfully!" -ForegroundColor Green
        Write-Host ""
        Write-Host "📌 Next steps:" -ForegroundColor Yellow
        Write-Host "  1. Restart your terminal" -ForegroundColor Gray
        Write-Host "  2. In Windows Terminal: Settings → Profiles → Defaults → Appearance → Font face" -ForegroundColor Gray
        Write-Host "  3. Select the Nerd Font you just installed" -ForegroundColor Gray
        Write-Host "  4. Enable in oh-my-pwsh: Edit config.ps1" -ForegroundColor Gray
        Write-Host "       Set: `$global:OhMyPwsh_UseNerdFonts = `$true" -ForegroundColor Gray
        Write-Host ""

    } catch {
        Write-Host ""
        Write-Host "✗ Installation failed: $_" -ForegroundColor Red
        Write-Host ""
        Write-Host "📌 Try manually:" -ForegroundColor Yellow
        Write-Host "   scoop install $FontName" -ForegroundColor Gray
        Write-Host ""
    }
}
