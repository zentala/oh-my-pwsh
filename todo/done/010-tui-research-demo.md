# 010 - TUI Research & Demo Script

**Status:** ✅ done (research completed)
**Priority:** P1 - **BLOCKS Task 009** (Interactive Installer)
**Created:** 2025-10-19
**Completed:** 2025-10-19

---

## ✅ RESEARCH COMPLETE - DECISION: Use PwshSpectreConsole

**Demo:** `demos/tui-demo.ps1` - Working showcase of all features
**Module:** PwshSpectreConsole v2.3.0
**Result:** ⭐⭐⭐⭐⭐ Perfect for oh-my-pwsh interactive installer

---

## Goal

Research and evaluate Windows-native TUI (Text User Interface) libraries for PowerShell that can create beautiful interactive menus, prompts, forms, and progress indicators. Create a demo script showcasing capabilities.

## User Story

> "As oh-my-pwsh developer, I need to choose a TUI library that works natively on Windows with minimal dependencies, so I can build interactive installers and CLI tools with good UX without requiring Node.js or Python."

## Context

User's requirements:
> "zbadac jakiesa windowsowe narzedzia do robienia rzeczy w tui jakies takie ktore pozwoal mi printoac ladne popupy itd. i ze potrzbuejmy skrypu demo - poakzuajcego jakie sa mozlisoci np zadanie pytan i odpowiedzi, ywbiernaie z pol itd. ale nbez node czy pyhtona, domylnie ma dzialc na windowsie, max 1 rzcz do intalacji."

**Requirements:**
- ✅ Works on Windows natively
- ✅ PowerShell compatible
- ✅ Maximum 1 dependency to install
- ❌ No Node.js or Python required
- ✅ Can create: menus, prompts, forms, progress bars, popups
- ✅ Good UX (colors, formatting, interactivity)

**Blocks:**
- Task 009 (Interactive Installer) - needs TUI decision

## Research Candidates

### 1. **Spectre.Console** ⭐ TOP CANDIDATE

**Description:** A .NET library for creating beautiful console applications

**Pros:**
- ✅ Native .NET (works with PowerShell)
- ✅ Rich features: progress bars, tables, trees, prompts, panels
- ✅ Beautiful rendering (colors, formatting, Unicode)
- ✅ Active development (Microsoft-backed)
- ✅ One dependency: `Install-Module PwshSpectreConsole`

**Cons:**
- Requires PowerShell module installation

**Install:**
```powershell
Install-Module -Name PwshSpectreConsole -Scope CurrentUser
```

**Features:**
- Interactive prompts (text, select, multiselect, confirm)
- Progress bars (single, multiple, indeterminate)
- Tables with borders and colors
- Panels and layouts
- Tree views
- Markup styling

**Links:**
- PowerShell Wrapper: https://github.com/ShaunLawrie/PwshSpectreConsole
- Original .NET: https://spectreconsole.net/

---

### 2. **Terminal.Gui.Ps**

**Description:** PowerShell wrapper for Terminal.Gui (TUI framework)

**Pros:**
- ✅ Rich TUI framework (like ncurses for .NET)
- ✅ Full windowing system (dialogs, forms, buttons)
- ✅ Mouse support
- ✅ Cross-platform (.NET)

**Cons:**
- More complex than needed for simple menus
- Smaller PowerShell community
- Steeper learning curve

**Install:**
```powershell
Install-Module -Name Terminal.Gui.Ps
```

**Links:**
- https://github.com/gui-cs/Terminal.Gui

---

### 3. **PSChoiceMenu**

**Description:** Simple PowerShell module for interactive menus

**Pros:**
- ✅ Lightweight
- ✅ Easy to use
- ✅ No external dependencies beyond PowerShell module

**Cons:**
- Limited features (just menus)
- Less polished UI than Spectre.Console

**Install:**
```powershell
Install-Module -Name PSChoiceMenu
```

---

### 4. **Native PowerShell (Baseline)**

**Description:** Built-in PowerShell cmdlets: `Read-Host`, `Write-Host`, `Out-GridView`

**Pros:**
- ✅ Zero dependencies
- ✅ Works everywhere
- ✅ Simple

**Cons:**
- ❌ Limited UX
- ❌ No colors in prompts
- ❌ No progress bars (basic only)
- ❌ No interactive menus

**Features:**
```powershell
# Simple prompt
$answer = Read-Host "Enter name"

# Confirmation
$confirm = Read-Host "Continue? [Y/n]"

# Grid view (GUI popup - Windows only)
Get-Process | Out-GridView -OutputMode Single
```

---

### 5. **BurntToast** (Notifications only)

**Description:** Windows notification toasts from PowerShell

**Pros:**
- ✅ Native Windows notifications
- ✅ Good for alerts

**Cons:**
- ❌ Not for interactive TUI
- Only notifications, not forms/menus

**Install:**
```powershell
Install-Module -Name BurntToast
```

---

## Evaluation Criteria

| Library | Windows Native | Dependencies | Menus | Forms | Progress | Colors | Mouse | Complexity | Score |
|---------|----------------|--------------|-------|-------|----------|--------|-------|------------|-------|
| **Spectre.Console** | ✅ .NET | 1 module | ✅ | ✅ | ✅✅ | ✅✅ | ❌ | Low | ⭐⭐⭐⭐⭐ |
| **Terminal.Gui.Ps** | ✅ .NET | 1 module | ✅ | ✅✅ | ✅ | ✅ | ✅ | High | ⭐⭐⭐⭐ |
| **PSChoiceMenu** | ✅ | 1 module | ✅ | ❌ | ❌ | ✅ | ❌ | Low | ⭐⭐⭐ |
| **Native PowerShell** | ✅ | None | ❌ | ❌ | Basic | ❌ | ❌ | Low | ⭐⭐ |
| **BurntToast** | ✅ | 1 module | ❌ | ❌ | ❌ | ✅ | ❌ | Low | ⭐ |

**Winner:** **Spectre.Console (PwshSpectreConsole)** - Best balance of features, UX, and simplicity

---

## Demo Script Requirements

Create `demos/tui-demo.ps1` showcasing:

### 1. Text Prompts
```powershell
# Simple text input
$name = Read-SpectreText -Prompt "What's your name?"

# Secret input (password)
$password = Read-SpectreText -Prompt "Password" -Secret

# Text with validation
$email = Read-SpectreText -Prompt "Email" -Validator { $_ -match "^.+@.+\..+$" }
```

### 2. Selection Menus
```powershell
# Single selection
$choice = Read-SpectreSelection -Title "Choose installation mode" -Choices @(
    "Quick Install (Recommended)"
    "Custom Install"
    "Minimal Install"
)

# Multi-selection
$tools = Read-SpectreMultiSelection -Title "Select tools to install" -Choices @(
    "bat - Better cat"
    "eza - Modern ls"
    "ripgrep - Fast grep"
    "fd - Fast find"
) -AllowEmpty
```

### 3. Confirmation
```powershell
$confirm = Read-SpectreConfirm -Prompt "Install these tools?" -DefaultAnswer $true
```

### 4. Progress Bars
```powershell
# Single progress bar
Invoke-SpectreCommandWithProgress -Title "Installing tools..." -ScriptBlock {
    param($Context)
    Start-Sleep -Seconds 3
    $Context.Refresh()
}

# Multiple tasks
$tasks = @(
    @{ Name = "Installing PowerShell"; Duration = 2 }
    @{ Name = "Installing Oh My Posh"; Duration = 1 }
    @{ Name = "Installing fzf"; Duration = 1 }
)

foreach ($task in $tasks) {
    Write-SpectreProgress -Task $task.Name -ScriptBlock {
        Start-Sleep -Seconds $task.Duration
    }
}
```

### 5. Tables
```powershell
$data = @(
    [PSCustomObject]@{ Tool = "bat"; Status = "Installed ✓"; Version = "0.24.0" }
    [PSCustomObject]@{ Tool = "eza"; Status = "Not Found"; Version = "-" }
    [PSCustomObject]@{ Tool = "ripgrep"; Status = "Installed ✓"; Version = "14.0.3" }
)

Format-SpectreTable -Data $data -Color Green
```

### 6. Panels & Layouts
```powershell
# Info panel
Write-SpectrePanel -Title "Installation Summary" -Content @"
Installed: 5 tools
Failed: 0
Time: 45 seconds
"@ -Color Green

# Figlet text (ASCII art title)
Write-SpectreFigletText -Text "oh-my-pwsh" -Color Cyan
```

### 7. Status/Spinner
```powershell
Invoke-SpectreSpinner -Title "Checking system requirements..." -ScriptBlock {
    Start-Sleep -Seconds 2
}
```

---

## Demo Script Structure

```powershell
# demos/tui-demo.ps1

#Requires -Modules PwshSpectreConsole

<#
.SYNOPSIS
    Demo of TUI capabilities for oh-my-pwsh using Spectre.Console

.DESCRIPTION
    This script showcases various TUI features:
    - Text prompts (simple, secret, validated)
    - Selection menus (single, multi)
    - Confirmation dialogs
    - Progress bars
    - Tables
    - Panels and layouts
    - Status spinners

.EXAMPLE
    .\demos\tui-demo.ps1
#>

param(
    [switch]$FullDemo  # Run all demos, otherwise interactive menu
)

# Check if PwshSpectreConsole is installed
if (-not (Get-Module -ListAvailable -Name PwshSpectreConsole)) {
    Write-Host "⚠️  PwshSpectreConsole not found. Installing..." -ForegroundColor Yellow
    Install-Module -Name PwshSpectreConsole -Scope CurrentUser -Force
}

Import-Module PwshSpectreConsole

# Title
Write-SpectreFigletText -Text "TUI Demo" -Color Cyan
Write-Host ""

# Demo menu
if (-not $FullDemo) {
    $demo = Read-SpectreSelection -Title "Choose demo to run" -Choices @(
        "1. Text Prompts"
        "2. Selection Menus"
        "3. Confirmations"
        "4. Progress Bars"
        "5. Tables"
        "6. Panels & Layouts"
        "7. Status Spinners"
        "8. Full Installer Simulation"
        "9. Run All Demos"
    )
}

# Run selected demo
switch ($demo) {
    "1. Text Prompts" { Demo-TextPrompts }
    "2. Selection Menus" { Demo-SelectionMenus }
    # ... etc
}

function Demo-TextPrompts {
    Write-SpectrePanel -Title "Text Prompts Demo" -Content "Various input types" -Color Blue

    # Simple text
    $name = Read-SpectreText -Prompt "What's your name?"
    Write-Host "Hello, $name!" -ForegroundColor Green

    # Secret input
    $password = Read-SpectreText -Prompt "Enter a password" -Secret
    Write-Host "Password length: $($password.Length)" -ForegroundColor Green

    # Validated input
    $email = Read-SpectreText -Prompt "Enter email" -Validator {
        param($input)
        if ($input -match "^.+@.+\..+$") {
            return $true
        } else {
            Write-Host "Invalid email format" -ForegroundColor Red
            return $false
        }
    }
    Write-Host "Email: $email" -ForegroundColor Green
}

function Demo-SelectionMenus {
    Write-SpectrePanel -Title "Selection Menus Demo" -Content "Choose from options" -Color Blue

    # Single selection
    $mode = Read-SpectreSelection -Title "Choose installation mode" -Choices @(
        "Quick Install (Recommended)"
        "Custom Install"
        "Minimal Install"
    )
    Write-Host "Selected: $mode" -ForegroundColor Green

    # Multi-selection
    $tools = Read-SpectreMultiSelection -Title "Select tools to install" -Choices @(
        "bat - Better cat with syntax highlighting"
        "eza - Modern ls with icons"
        "ripgrep - Fast grep for searching"
        "fd - Fast find for files"
        "delta - Beautiful git diff"
    ) -AllowEmpty
    Write-Host "Selected tools:" -ForegroundColor Green
    $tools | ForEach-Object { Write-Host "  - $_" -ForegroundColor Cyan }
}

function Demo-FullInstallerSimulation {
    # Simulate full installer UX
    Write-SpectreFigletText -Text "oh-my-pwsh" -Color Magenta
    Write-Host ""

    Write-SpectrePanel -Title "Welcome" -Content @"
Welcome to oh-my-pwsh installer!

This wizard will help you set up your PowerShell environment
with modern tools and beautiful prompts.
"@ -Color Cyan

    # Mode selection
    $mode = Read-SpectreSelection -Title "Choose installation mode" -Choices @(
        "Quick Install (Recommended) - All recommended tools"
        "Custom Install - Choose what to install"
        "Minimal Install - Core only"
    )

    if ($mode -like "Custom*") {
        # Custom tool selection
        $tools = Read-SpectreMultiSelection -Title "Select tools to install" -Choices @(
            "Oh My Posh - Beautiful prompt"
            "posh-git - Git integration"
            "Terminal-Icons - File icons"
            "PSReadLine - Smart completion"
            "fzf - Fuzzy finder"
            "zoxide - Smart directory jumps"
            "bat - Better cat"
            "eza - Modern ls"
        )
    }

    # Confirmation
    $confirm = Read-SpectreConfirm -Prompt "Proceed with installation?" -DefaultAnswer $true

    if ($confirm) {
        # Simulate installation with progress
        Write-SpectrePanel -Title "Installing..." -Content "Please wait while we set up your environment" -Color Yellow

        $installTasks = @(
            @{ Name = "PowerShell 7.x"; Duration = 2 }
            @{ Name = "Oh My Posh"; Duration = 1 }
            @{ Name = "posh-git"; Duration = 1 }
            @{ Name = "fzf"; Duration = 1 }
            @{ Name = "zoxide"; Duration = 1 }
        )

        foreach ($task in $installTasks) {
            Invoke-SpectreCommandWithProgress -Title "Installing $($task.Name)..." -ScriptBlock {
                Start-Sleep -Seconds $task.Duration
            }
        }

        # Success summary
        $summary = @(
            [PSCustomObject]@{ Tool = "PowerShell 7.x"; Status = "✓ Installed"; Version = "7.4.0" }
            [PSCustomObject]@{ Tool = "Oh My Posh"; Status = "✓ Installed"; Version = "19.0.0" }
            [PSCustomObject]@{ Tool = "posh-git"; Status = "✓ Installed"; Version = "1.1.0" }
            [PSCustomObject]@{ Tool = "fzf"; Status = "✓ Installed"; Version = "0.44.0" }
            [PSCustomObject]@{ Tool = "zoxide"; Status = "✓ Installed"; Version = "0.9.0" }
        )

        Write-Host ""
        Format-SpectreTable -Data $summary -Color Green

        Write-SpectrePanel -Title "✓ Installation Complete!" -Content @"
All tools installed successfully!

Next steps:
1. Restart PowerShell
2. Type 'help' to see available commands
3. Enjoy your new terminal experience!
"@ -Color Green
    }
}
```

---

## Tasks

- [ ] Install and test Spectre.Console (PwshSpectreConsole)
- [ ] Install and test Terminal.Gui.Ps (comparison)
- [ ] Install and test PSChoiceMenu (comparison)
- [ ] Create demo script (`demos/tui-demo.ps1`)
- [ ] Implement all demo functions (prompts, menus, progress, tables, panels)
- [ ] Create full installer simulation demo
- [ ] Document findings in this task
- [ ] Make recommendation for Task 009 (Interactive Installer)
- [ ] Create reusable TUI helper module (`modules/tui-helpers.ps1`)

## Success Criteria

- [ ] Demo script works on fresh Windows install
- [ ] All TUI features demonstrated (prompts, menus, progress, tables)
- [ ] Maximum 1 dependency to install
- [ ] Clear recommendation for Task 009
- [ ] Reusable helpers created for future features
- [ ] Documentation of chosen library

## Decision Criteria

**Must Have:**
- Works on Windows natively
- Maximum 1 PowerShell module dependency
- Interactive menus and prompts
- Progress indicators
- Good visual design (colors, formatting)

**Nice to Have:**
- Tables
- Panels/layouts
- Mouse support
- Cross-platform (Linux/macOS)

**Not Needed:**
- Full windowing system
- Complex forms
- Graphics/charts

## Recommendation (After Research)

**RECOMMENDED: Spectre.Console (PwshSpectreConsole)**

**Rationale:**
- ✅ Best balance of features and simplicity
- ✅ Beautiful rendering out of the box
- ✅ Active development and community
- ✅ Comprehensive documentation
- ✅ One module install
- ✅ Perfect for installer and CLI tools

**Runner-up:** Terminal.Gui.Ps (if we need forms/dialogs later)

**Fallback:** Native PowerShell (if zero-dependency requirement)

## Next Steps After Decision

1. Unblock Task 009 (Interactive Installer)
2. Create `modules/tui-helpers.ps1` wrapper around Spectre.Console
3. Use in installer
4. Use in future interactive features (AI CLI, setup wizards)

## Related

- [009-interactive-installer.md](./009-interactive-installer.md) - **BLOCKED** - Waiting for this decision
- [008-ai-cli-integration.md](./008-ai-cli-integration.md) - Will also benefit from TUI
- [CLAUDE.md](../../CLAUDE.md) - DevEx mindset

## Notes

- **Priority: P1** - Blocks Task 009 (Interactive Installer)
- Research task - need to test libraries hands-on
- Create demo script to show capabilities to user
- Decision needed before implementing installer
- Consider future use cases (AI CLI, setup wizards, interactive help)

## Research Links

- Spectre.Console: https://spectreconsole.net/
- PwshSpectreConsole: https://github.com/ShaunLawrie/PwshSpectreConsole
- Terminal.Gui: https://github.com/gui-cs/Terminal.Gui
- PSChoiceMenu: https://www.powershellgallery.com/packages/PSChoiceMenu
