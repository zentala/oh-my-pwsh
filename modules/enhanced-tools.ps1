# ============================================
# Enhanced Tools Module
# ============================================
# Modern alternatives to classic Unix tools
# Requires: scoop install bat eza ripgrep fd delta

if (-not $global:OhMyPwsh_UseEnhancedTools) {
    return
}

# ============================================
# BAT - Better cat with syntax highlighting
# ============================================
# Install: scoop install bat
# Docs: https://github.com/sharkdp/bat

if (Get-Command bat -ErrorAction SilentlyContinue) {
    function cat {
        param([Parameter(ValueFromRemainingArguments)]$args)
        bat @args
    }

    if ($global:OhMyPwsh_ShowTips) {
        Write-Host "✓ bat loaded (enhanced cat)" -ForegroundColor DarkGreen
    }
} else {
    if ($global:OhMyPwsh_ShowTips) {
        Write-Host "💡 Install bat for better cat: scoop install bat" -ForegroundColor DarkYellow
    }
    # Fallback to native
    Set-Alias cat Get-Content
}

# ============================================
# EZA - Modern ls alternative
# ============================================
# Install: scoop install eza
# Docs: https://github.com/eza-community/eza

if (Get-Command eza -ErrorAction SilentlyContinue) {
    function ls {
        param([Parameter(ValueFromRemainingArguments)]$args)
        eza --icons @args
    }

    function ll {
        param([Parameter(ValueFromRemainingArguments)]$args)
        eza --icons -l @args
    }

    function la {
        param([Parameter(ValueFromRemainingArguments)]$args)
        eza --icons -la @args
    }

    function lt {
        param([Parameter(ValueFromRemainingArguments)]$args)
        eza --icons --tree @args
    }

    if ($global:OhMyPwsh_ShowTips) {
        Write-Host "✓ eza loaded (enhanced ls)" -ForegroundColor DarkGreen
    }
} else {
    if ($global:OhMyPwsh_ShowTips) {
        Write-Host "💡 Install eza for better ls: scoop install eza" -ForegroundColor DarkYellow
    }
    # Fallback handled by linux-compat.ps1
}

# ============================================
# RIPGREP (rg) - Faster grep
# ============================================
# Install: scoop install ripgrep
# Docs: https://github.com/BurntSushi/ripgrep

if (Get-Command rg -ErrorAction SilentlyContinue) {
    function grep {
        param([Parameter(ValueFromRemainingArguments)]$args)
        rg @args
    }

    if ($global:OhMyPwsh_ShowTips) {
        Write-Host "✓ ripgrep loaded (enhanced grep)" -ForegroundColor DarkGreen
    }
} else {
    if ($global:OhMyPwsh_ShowTips) {
        Write-Host "💡 Install ripgrep for better grep: scoop install ripgrep" -ForegroundColor DarkYellow
    }
    # Fallback to Select-String handled by linux-compat.ps1
}

# ============================================
# FD - Faster, better find
# ============================================
# Install: scoop install fd
# Docs: https://github.com/sharkdp/fd

if (Get-Command fd -ErrorAction SilentlyContinue) {
    function find {
        param([Parameter(ValueFromRemainingArguments)]$args)
        fd @args
    }

    if ($global:OhMyPwsh_ShowTips) {
        Write-Host "✓ fd loaded (enhanced find)" -ForegroundColor DarkGreen
    }
} else {
    if ($global:OhMyPwsh_ShowTips) {
        Write-Host "💡 Install fd for better find: scoop install fd" -ForegroundColor DarkYellow
    }
    # No fallback - PowerShell has Get-ChildItem -Recurse
}

# ============================================
# DELTA - Better git diff
# ============================================
# Install: scoop install delta
# Docs: https://github.com/dandavison/delta

if (Get-Command delta -ErrorAction SilentlyContinue) {
    # Configure git to use delta
    git config --global core.pager "delta"
    git config --global interactive.diffFilter "delta --color-only"
    git config --global delta.navigate true
    git config --global delta.light false
    git config --global merge.conflictstyle diff3
    git config --global diff.colorMoved default

    if ($global:OhMyPwsh_ShowTips) {
        Write-Host "✓ delta configured for git diff" -ForegroundColor DarkGreen
    }
} else {
    if ($global:OhMyPwsh_ShowTips) {
        Write-Host "💡 Install delta for better git diff: scoop install delta" -ForegroundColor DarkYellow
    }
}

# ============================================
# INSTALLATION HELPER
# ============================================

function Install-EnhancedTools {
    Write-Host "`n🚀 Installing Enhanced Tools..." -ForegroundColor Cyan
    Write-Host "This will install: bat, eza, ripgrep, fd, delta`n" -ForegroundColor White

    # Check if scoop is installed
    if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
        Write-Host "❌ Scoop not found! Installing Scoop first..." -ForegroundColor Red
        Write-Host "Run: irm get.scoop.sh | iex`n" -ForegroundColor Yellow
        return
    }

    $tools = @('bat', 'eza', 'ripgrep', 'fd', 'delta')

    foreach ($tool in $tools) {
        if (Get-Command $tool -ErrorAction SilentlyContinue) {
            Write-Host "✓ $tool already installed" -ForegroundColor Green
        } else {
            Write-Host "Installing $tool..." -ForegroundColor Yellow
            scoop install $tool
        }
    }

    Write-Host "`n✨ Done! Restart your terminal to use enhanced tools." -ForegroundColor Green
    Write-Host "💡 Tip: Type 'help' to see what's available`n" -ForegroundColor Cyan
}

# Export
Export-ModuleMember -Function * -Alias *
