# ============================================
# Custom Help System
# ============================================
# Beautiful, informative help for oh-my-pwsh

if (-not $global:OhMyPwsh_EnableCustomHelp) {
    return
}

function Show-OhMyPwshHelp {
    param(
        [string]$Topic = "all"
    )

    # No Clear-Host - print to terminal like everything else
    # Header
    Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║              " -NoNewline -ForegroundColor Cyan
    Write-Host "🚀 oh-my-pwsh - PowerShell Enhanced" -NoNewline -ForegroundColor White
    Write-Host "              ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""

    # Quick Commands
    if ($Topic -eq "all" -or $Topic -eq "quick") {
        Write-Host "━━━ QUICK COMMANDS ━━━" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  Navigation:" -ForegroundColor White
        Write-Host "    .., ..., ....              " -NoNewline -ForegroundColor Cyan
        Write-Host "Go up 1/2/3 directories" -ForegroundColor Gray
        Write-Host "    z <dir>                    " -NoNewline -ForegroundColor Cyan
        Write-Host "Smart jump to directory (zoxide)" -ForegroundColor Gray
        Write-Host "    mkcd <dir>                 " -NoNewline -ForegroundColor Cyan
        Write-Host "Create directory and cd into it" -ForegroundColor Gray
        Write-Host ""

        Write-Host "  File Operations:" -ForegroundColor White
        Write-Host "    ls, ll, la                 " -NoNewline -ForegroundColor Cyan
        if (Get-Command eza -ErrorAction SilentlyContinue) {
            Write-Host "List files (powered by eza)" -ForegroundColor Green
            Write-Host "    lt                         " -NoNewline -ForegroundColor Cyan
            Write-Host "Tree view (eza --tree)" -ForegroundColor Green
        } else {
            Write-Host "List files (Get-ChildItem)" -ForegroundColor Gray
        }
        Write-Host "    cat <file>                 " -NoNewline -ForegroundColor Cyan
        if (Get-Command bat -ErrorAction SilentlyContinue) {
            Write-Host "View file (powered by bat)" -ForegroundColor Green
        } else {
            Write-Host "View file (Get-Content)" -ForegroundColor Gray
        }
        Write-Host "    touch <file>               " -NoNewline -ForegroundColor Cyan
        Write-Host "Create/update file" -ForegroundColor Gray
        Write-Host "    mkdir <dir>                " -NoNewline -ForegroundColor Cyan
        Write-Host "Create directory (supports -p)" -ForegroundColor Gray
        Write-Host ""

        Write-Host "  Search:" -ForegroundColor White
        Write-Host "    grep <pattern>             " -NoNewline -ForegroundColor Cyan
        if (Get-Command rg -ErrorAction SilentlyContinue) {
            Write-Host "Search text (powered by ripgrep)" -ForegroundColor Green
        } else {
            Write-Host "Search text (Select-String)" -ForegroundColor Gray
        }
        Write-Host "    find <pattern>             " -NoNewline -ForegroundColor Cyan
        if (Get-Command fd -ErrorAction SilentlyContinue) {
            Write-Host "Find files (powered by fd)" -ForegroundColor Green
        } else {
            Write-Host "Find files (Get-ChildItem -Recurse)" -ForegroundColor Gray
        }
        Write-Host "    Ctrl+R                     " -NoNewline -ForegroundColor Cyan
        Write-Host "Search command history (fzf)" -ForegroundColor Gray
        Write-Host "    Ctrl+T                     " -NoNewline -ForegroundColor Cyan
        Write-Host "Fuzzy file finder (fzf)" -ForegroundColor Gray
        Write-Host ""

        Write-Host "  Git:" -ForegroundColor White
        Write-Host "    g <command>                " -NoNewline -ForegroundColor Cyan
        Write-Host "Git shortcut" -ForegroundColor Gray
        if (Get-Command delta -ErrorAction SilentlyContinue) {
            Write-Host "    git diff                   " -NoNewline -ForegroundColor Cyan
            Write-Host "Enhanced with delta" -ForegroundColor Green
        }
        Write-Host ""
    }

    # Enhanced Tools Status
    if ($Topic -eq "all" -or $Topic -eq "tools") {
        Write-Host "━━━ ENHANCED TOOLS STATUS ━━━" -ForegroundColor Yellow
        Write-Host ""

        $tools = @(
            @{ Name = "bat"; Command = "bat"; Description = "Better cat with syntax highlighting" }
            @{ Name = "eza"; Command = "eza"; Description = "Modern ls with icons and colors" }
            @{ Name = "ripgrep"; Command = "rg"; Description = "Faster grep for searching" }
            @{ Name = "fd"; Command = "fd"; Description = "Faster find for locating files" }
            @{ Name = "delta"; Command = "delta"; Description = "Better git diff viewer" }
            @{ Name = "fzf"; Command = "fzf"; Description = "Fuzzy finder (Ctrl+R, Ctrl+T)" }
            @{ Name = "zoxide"; Command = "zoxide"; Description = "Smart directory jumping (z)" }
        )

        foreach ($tool in $tools) {
            $installed = Get-Command $tool.Command -ErrorAction SilentlyContinue
            if ($installed) {
                Write-Host "  ✓ " -NoNewline -ForegroundColor Green
                Write-Host "$($tool.Name.PadRight(12))" -NoNewline -ForegroundColor White
                Write-Host $tool.Description -ForegroundColor Gray
            } else {
                Write-Host "  ✗ " -NoNewline -ForegroundColor Red
                Write-Host "install " -NoNewline -ForegroundColor White
                Write-Host "``$($tool.Name)``" -NoNewline -ForegroundColor White
                Write-Host " for " -NoNewline -ForegroundColor White
                Write-Host "$($tool.Description.ToLower())" -NoNewline -ForegroundColor White
                Write-Host ": " -NoNewline -ForegroundColor White
                Write-Host "scoop install $($tool.Name)" -ForegroundColor DarkGray
            }
        }
        Write-Host ""

        # Quick install
        $missing = $tools | Where-Object { -not (Get-Command $_.Command -ErrorAction SilentlyContinue) }
        if ($missing.Count -gt 0) {
            Write-Host "  💡 Install all missing tools:" -ForegroundColor Cyan
            Write-Host "     Install-EnhancedTools" -ForegroundColor Yellow
            Write-Host ""
        }
    }

    # Learning Mode - Show PowerShell equivalents
    if ($global:OhMyPwsh_ShowAliasTargets -and ($Topic -eq "all" -or $Topic -eq "learn")) {
        Write-Host "━━━ LEARNING MODE - PowerShell Equivalents ━━━" -ForegroundColor Yellow
        Write-Host ""

        $aliases = @(
            @{ Linux = "ls"; PowerShell = "Get-ChildItem" }
            @{ Linux = "cat"; PowerShell = "Get-Content" }
            @{ Linux = "grep"; PowerShell = "Select-String" }
            @{ Linux = "pwd"; PowerShell = "Get-Location" }
            @{ Linux = "cd"; PowerShell = "Set-Location" }
            @{ Linux = "rm"; PowerShell = "Remove-Item" }
            @{ Linux = "cp"; PowerShell = "Copy-Item" }
            @{ Linux = "mv"; PowerShell = "Move-Item" }
            @{ Linux = "ps"; PowerShell = "Get-Process" }
            @{ Linux = "kill"; PowerShell = "Stop-Process" }
            @{ Linux = "which"; PowerShell = "Get-Command" }
            @{ Linux = "man"; PowerShell = "Get-Help" }
        )

        foreach ($alias in $aliases) {
            Write-Host "  $($alias.Linux.PadRight(10))" -NoNewline -ForegroundColor Cyan
            Write-Host " → " -NoNewline -ForegroundColor DarkGray
            Write-Host $alias.PowerShell -ForegroundColor White
        }
        Write-Host ""
        Write-Host "  💡 Disable this: " -NoNewline -ForegroundColor Cyan
        Write-Host "`$OhMyPwsh_ShowAliasTargets = `$false" -ForegroundColor Yellow
        Write-Host ""
    }

    # Configuration
    if ($Topic -eq "all" -or $Topic -eq "config") {
        Write-Host "━━━ CONFIGURATION ━━━" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  Edit config:   " -NoNewline -ForegroundColor Cyan
        Write-Host "code config.ps1" -ForegroundColor White
        Write-Host "  Profile:       " -NoNewline -ForegroundColor Cyan
        Write-Host "code profile.ps1" -ForegroundColor White
        Write-Host "  Reload:        " -NoNewline -ForegroundColor Cyan
        Write-Host ". `$PROFILE" -ForegroundColor White
        Write-Host ""

        Write-Host "  Current Settings:" -ForegroundColor White
        Write-Host "    Linux Compat:      " -NoNewline -ForegroundColor Gray
        Write-Host $(if ($global:OhMyPwsh_EnableLinuxCompat) { "✓ Enabled" } else { "✗ Disabled" }) -ForegroundColor $(if ($global:OhMyPwsh_EnableLinuxCompat) { "Green" } else { "Red" })
        Write-Host "    Enhanced Tools:    " -NoNewline -ForegroundColor Gray
        Write-Host $(if ($global:OhMyPwsh_UseEnhancedTools) { "✓ Enabled" } else { "✗ Disabled" }) -ForegroundColor $(if ($global:OhMyPwsh_UseEnhancedTools) { "Green" } else { "Red" })
        Write-Host "    Show Feedback:     " -NoNewline -ForegroundColor Gray
        Write-Host $(if ($global:OhMyPwsh_ShowFeedback) { "✓ Enabled" } else { "✗ Disabled" }) -ForegroundColor $(if ($global:OhMyPwsh_ShowFeedback) { "Green" } else { "Red" })
        Write-Host "    Learning Mode:     " -NoNewline -ForegroundColor Gray
        Write-Host $(if ($global:OhMyPwsh_ShowAliasTargets) { "✓ Enabled" } else { "✗ Disabled" }) -ForegroundColor $(if ($global:OhMyPwsh_ShowAliasTargets) { "Green" } else { "Red" })
        Write-Host ""
    }

    # More Help
    Write-Host "━━━ MORE HELP ━━━" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  help quick          " -NoNewline -ForegroundColor Cyan
    Write-Host "Quick commands reference" -ForegroundColor Gray
    Write-Host "  help tools          " -NoNewline -ForegroundColor Cyan
    Write-Host "Enhanced tools status" -ForegroundColor Gray
    Write-Host "  help learn          " -NoNewline -ForegroundColor Cyan
    Write-Host "PowerShell equivalents" -ForegroundColor Gray
    Write-Host "  help config         " -NoNewline -ForegroundColor Cyan
    Write-Host "Configuration settings" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  📖 Full docs: " -NoNewline -ForegroundColor Cyan
    Write-Host "https://github.com/zentala/pwsh-profile" -ForegroundColor Blue
    Write-Host ""
}

# Override native help command
function help {
    param([Parameter(ValueFromRemainingArguments)]$args)

    if ($args.Count -eq 0) {
        Show-OhMyPwshHelp
    } else {
        Show-OhMyPwshHelp -Topic $args[0]
    }
}

# Aliases
# Note: '?' is read-only in PowerShell, can't override
Set-Alias omph Show-OhMyPwshHelp
