# =====================================================
# Nerd Fonts Detection and Installation
# =====================================================

function Get-TerminalType {
    <#
    .SYNOPSIS
        Detects which terminal emulator is currently being used

    .DESCRIPTION
        Checks environment variables to determine the terminal type.
        Helps provide terminal-specific instructions and automation.

    .OUTPUTS
        [string] Terminal type: "WindowsTerminal", "VSCode", "ConEmu", "LegacyConsole"

    .EXAMPLE
        $termType = Get-TerminalType
        if ($termType -eq "WindowsTerminal") {
            # Can automate font configuration
        }
    #>

    # Windows Terminal - has WT_SESSION environment variable
    if (-not [string]::IsNullOrEmpty($env:WT_SESSION)) {
        return "WindowsTerminal"
    }

    # VS Code integrated terminal
    if (-not [string]::IsNullOrEmpty($env:VSCODE_PID) -or $env:TERM_PROGRAM -eq "vscode") {
        return "VSCode"
    }

    # ConEmu
    if (-not [string]::IsNullOrEmpty($env:ConEmuPID)) {
        return "ConEmu"
    }

    # Default: Legacy Windows Console (conhost.exe)
    return "LegacyConsole"
}

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

function Set-WindowsTerminalFont {
    <#
    .SYNOPSIS
        Automatically configures font in Windows Terminal settings

    .DESCRIPTION
        Modifies Windows Terminal's settings.json to set the specified Nerd Font
        as the default font. Creates backup before modifying.

    .PARAMETER FontName
        Font face name to set (e.g., "CaskaydiaCove Nerd Font")

    .PARAMETER Silent
        Don't prompt for confirmation

    .OUTPUTS
        [bool] True if successfully configured, False otherwise

    .EXAMPLE
        Set-WindowsTerminalFont -FontName "CaskaydiaCove Nerd Font"
    #>

    param(
        [Parameter(Mandatory=$true)]
        [string]$FontName,

        [switch]$Silent
    )

    # Check if running in Windows Terminal
    $termType = Get-TerminalType
    if ($termType -ne "WindowsTerminal") {
        Write-Host "⚠️  Not running in Windows Terminal - cannot auto-configure" -ForegroundColor Yellow
        return $false
    }

    # Find Windows Terminal settings file
    $settingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"

    if (-not (Test-Path $settingsPath)) {
        Write-Host "✗ Windows Terminal settings not found at: $settingsPath" -ForegroundColor Red
        return $false
    }

    try {
        # Create backup
        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $backupPath = "$settingsPath.backup-$timestamp"
        Copy-Item $settingsPath $backupPath -Force
        Write-Host "✓ Created backup: $backupPath" -ForegroundColor Green

        # Read and parse JSON
        $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json

        # Set font in profiles.defaults
        if (-not $settings.profiles) {
            $settings | Add-Member -NotePropertyName "profiles" -NotePropertyValue @{} -Force
        }
        if (-not $settings.profiles.defaults) {
            $settings.profiles | Add-Member -NotePropertyName "defaults" -NotePropertyValue @{} -Force
        }
        if (-not $settings.profiles.defaults.font) {
            $settings.profiles.defaults | Add-Member -NotePropertyName "font" -NotePropertyValue @{} -Force
        }

        # Set the font face
        if ($settings.profiles.defaults.font.PSObject.Properties['face']) {
            $settings.profiles.defaults.font.face = $FontName
        } else {
            $settings.profiles.defaults.font | Add-Member -NotePropertyName "face" -NotePropertyValue $FontName -Force
        }

        # Write back to file
        $settings | ConvertTo-Json -Depth 32 | Set-Content $settingsPath -Encoding UTF8

        Write-Host "✓ Font set to: $FontName" -ForegroundColor Green
        Write-Host "  Restart Windows Terminal for changes to take effect" -ForegroundColor Gray
        return $true

    } catch {
        Write-Host "✗ Failed to configure font: $_" -ForegroundColor Red
        Write-Host "  Restoring backup..." -ForegroundColor Yellow

        if (Test-Path $backupPath) {
            Copy-Item $backupPath $settingsPath -Force
            Write-Host "✓ Backup restored" -ForegroundColor Green
        }

        return $false
    }
}

function Get-RecommendedNerdFonts {
    <#
    .SYNOPSIS
        Returns list of recommended Nerd Fonts for PowerShell profiles

    .DESCRIPTION
        Provides curated list of best Nerd Fonts for terminal use with install info.

        IMPORTANT: Always use REGULAR variants, NOT Mono variants!
        - Regular: Icons have natural width (✅ best for terminals)
        - Mono: Icons compressed to fixed width (❌ too small, hard to see)
        - Propo: Variable width (⚠️ good for UI, not for code)

    .OUTPUTS
        Array of PSCustomObjects with font recommendations
    #>

    return @(
        [PSCustomObject]@{
            Name = "CaskaydiaCove Nerd Font"
            ScoopName = "CascadiaCode-NF"
            Description = "Microsoft's Cascadia Code with Nerd Font icons (recommended)"
            Why = "Clean, professional, designed for coding, excellent ligature support"
            Variant = "Regular (default)"
        },
        [PSCustomObject]@{
            Name = "FiraCode Nerd Font"
            ScoopName = "FiraCode-NF"
            Description = "Popular programming font with excellent ligatures"
            Why = "Best ligatures, very popular, great readability"
            Variant = "Regular (default)"
        },
        [PSCustomObject]@{
            Name = "JetBrainsMono Nerd Font"
            ScoopName = "JetBrainsMono-NF"
            Description = "JetBrains' monospace font optimized for developers"
            Why = "Designed specifically for IDEs, excellent character distinction"
            Variant = "Regular (default)"
        },
        [PSCustomObject]@{
            Name = "Meslo Nerd Font"
            ScoopName = "Meslo-NF"
            Description = "Customized version of Apple's Menlo font"
            Why = "Safe choice, works everywhere, very readable"
            Variant = "Regular (default)"
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

        # Important note about variants
        Write-Host "⚠️  IMPORTANT: Use REGULAR variants only!" -ForegroundColor Yellow
        Write-Host "   • Regular variant = Icons display at natural size ✅" -ForegroundColor Gray
        Write-Host "   • Mono variant = Icons too small, hard to see ❌" -ForegroundColor Gray
        Write-Host "   (All fonts below install the correct Regular variant)" -ForegroundColor DarkGray
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

        # Get actual font display name (not scoop package name)
        $fontDisplayName = ($recommended | Where-Object { $_.ScoopName -eq $FontName }).Name
        if (-not $fontDisplayName) {
            $fontDisplayName = $FontName -replace '-NF$', ' Nerd Font'
        }

        # Detect terminal type and offer auto-configuration
        $termType = Get-TerminalType

        if ($termType -eq "WindowsTerminal" -and -not $Silent) {
            Write-Host "🎯 Detected Windows Terminal!" -ForegroundColor Cyan
            Write-Host ""
            $autoConfig = Read-Host "Would you like to automatically configure this font in Windows Terminal? (Y/n)"

            if ($autoConfig -ne 'n' -and $autoConfig -ne 'N') {
                Write-Host ""
                $success = Set-WindowsTerminalFont -FontName $fontDisplayName
                if ($success) {
                    Write-Host ""
                    Write-Host "📌 Final steps:" -ForegroundColor Yellow
                    Write-Host "  1. ⚠️  RESTART Windows Terminal (close all tabs)" -ForegroundColor Yellow
                    Write-Host "  2. Enable in oh-my-pwsh config: code `$ProfileRoot\config.ps1" -ForegroundColor Gray
                    Write-Host "     Set: `$global:OhMyPwsh_UseNerdFonts = `$true" -ForegroundColor Gray
                    Write-Host ""
                    return
                }
            }
        }

        # Manual instructions (if not Windows Terminal or user declined auto-config)
        Write-Host "📌 Next steps:" -ForegroundColor Yellow
        Write-Host "  1. Restart your terminal" -ForegroundColor Gray

        if ($termType -eq "WindowsTerminal") {
            Write-Host "  2. In Windows Terminal: Settings → Profiles → Defaults → Appearance → Font face" -ForegroundColor Gray
            Write-Host "     Select: $fontDisplayName" -ForegroundColor Gray
        } elseif ($termType -eq "VSCode") {
            Write-Host "  2. In VS Code: Settings → Terminal › Integrated: Font Family" -ForegroundColor Gray
            Write-Host "     Set to: $fontDisplayName" -ForegroundColor Gray
        } else {
            Write-Host "  2. Configure your terminal to use: $fontDisplayName" -ForegroundColor Gray
        }

        Write-Host "  3. Enable in oh-my-pwsh: Edit config.ps1" -ForegroundColor Gray
        Write-Host "     Set: `$global:OhMyPwsh_UseNerdFonts = `$true" -ForegroundColor Gray
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
