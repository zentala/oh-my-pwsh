#Requires -Modules PwshSpectreConsole

<#
.SYNOPSIS
    Demo of TUI capabilities for oh-my-pwsh using Spectre.Console

.DESCRIPTION
    Showcases key TUI features needed for interactive installer:
    - Text prompts
    - Selection menus
    - Confirmation dialogs
    - Progress bars
    - Tables and panels

.EXAMPLE
    .\demos\tui-demo.ps1
#>

param(
    [switch]$Quick  # Skip interactive prompts
)

# Suppress encoding warning
$env:IgnoreSpectreEncoding = $true

# Check if PwshSpectreConsole is installed
if (-not (Get-Module -ListAvailable -Name PwshSpectreConsole)) {
    Write-Host "⚠️  PwshSpectreConsole not found. Installing..." -ForegroundColor Yellow
    Install-Module -Name PwshSpectreConsole -Scope CurrentUser -Force
}

Import-Module PwshSpectreConsole

# Title
Write-Host ""
Write-SpectreFigletText -Text "oh-my-pwsh"
Write-SpectreRule "TUI Demo with Spectre.Console"
Write-Host ""

if (-not $Quick) {
    # Demo 1: Welcome Panel
    Format-SpectrePanel -Title "Welcome" -Data "This demo showcases TUI features for oh-my-pwsh interactive installer" | Out-SpectreHost
    Write-Host ""

    # Demo 2: Text Input
    Write-SpectreRule "Text Input"
    $name = Read-SpectreText -Prompt "What's your name?" -DefaultAnswer "Developer"
    Write-Host "Hello, $name!" -ForegroundColor Green
    Write-Host ""

    # Demo 3: Single Selection
    Write-SpectreRule "Selection Menu"
    $mode = Read-SpectreSelection -Title "Choose installation mode" -Choices @(
        "Quick Install (Recommended)"
        "Custom Install"
        "Minimal Install"
    )
    Write-Host "Selected: $mode" -ForegroundColor Green
    Write-Host ""

    # Demo 4: Multi-Selection
    Write-SpectreRule "Multi-Selection"
    $tools = Read-SpectreMultiSelection -Title "Select tools to install (Space to toggle, Enter to confirm)" -Choices @(
        "bat - Better cat with syntax highlighting"
        "eza - Modern ls with icons"
        "ripgrep - Fast grep for searching"
        "fd - Fast find for files"
    )
    Write-Host "Selected tools:" -ForegroundColor Green
    $tools | ForEach-Object { Write-Host "  ✓ $_" -ForegroundColor Cyan }
    Write-Host ""

    # Demo 5: Confirmation
    Write-SpectreRule "Confirmation"
    $confirm = Read-SpectreConfirm -Prompt "Proceed with installation?" -DefaultAnswer $true
    if (-not $confirm) {
        Write-Host "Installation cancelled." -ForegroundColor Yellow
        exit 0
    }
    Write-Host ""
}

# Demo 6: Progress Bar
Write-SpectreRule "Progress Indicator"
Invoke-SpectreCommandWithStatus -Spinner "Dots" -Title "Installing tools..." -ScriptBlock {
    Start-Sleep -Seconds 2
}
Write-Host "✓ Installation complete" -ForegroundColor Green
Write-Host ""

# Demo 7: Table
Write-SpectreRule "Status Table"
$data = @(
    [PSCustomObject]@{ Tool = "bat"; Status = "✓ Installed"; Version = "0.24.0" }
    [PSCustomObject]@{ Tool = "eza"; Status = "✓ Installed"; Version = "0.17.0" }
    [PSCustomObject]@{ Tool = "ripgrep"; Status = "✓ Installed"; Version = "14.0.3" }
    [PSCustomObject]@{ Tool = "fd"; Status = "✓ Installed"; Version = "9.0.0" }
)
$data | Format-SpectreTable | Out-SpectreHost
Write-Host ""

# Demo 8: Success Panel
Format-SpectrePanel -Title "✓ Installation Complete!" -Data @"
All tools installed successfully!

Next steps:
1. Restart PowerShell
2. Type 'help' to see available commands
3. Enjoy your new terminal experience!
"@ | Out-SpectreHost
Write-Host ""

Write-Host "Demo complete! 🎉" -ForegroundColor Magenta
Write-Host ""
Write-Host "Recommendation: Use PwshSpectreConsole for interactive installer" -ForegroundColor Cyan
