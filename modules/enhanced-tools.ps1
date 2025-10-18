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
    Write-ToolStatus -Name "bat" -Installed $true -Description "enhanced cat"
} else {
    Write-ToolStatus -Name "bat" -Installed $false -Description "improved cat" -ScoopPackage "bat"
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

    Write-ToolStatus -Name "eza" -Installed $true -Description "enhanced ls"
} else {
    Write-ToolStatus -Name "eza" -Installed $false -Description "modern ls" -ScoopPackage "eza"
    # Fallback to native PowerShell Get-ChildItem
    # ls/ll/la aliases will use default behavior
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

    Write-ToolStatus -Name "ripgrep" -Installed $true -Description "enhanced grep"
} else {
    Write-ToolStatus -Name "ripgrep" -Installed $false -Description "faster grep" -ScoopPackage "ripgrep"
    # Fallback to Select-String (defined in linux-compat.ps1)
    function grep {
        param([Parameter(ValueFromRemainingArguments)]$args)
        Select-String @args
    }
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

    Write-ToolStatus -Name "fd" -Installed $true -Description "enhanced find"
} else {
    Write-ToolStatus -Name "fd" -Installed $false -Description "faster find" -ScoopPackage "fd"
    # Fallback to Get-ChildItem -Recurse
    function find {
        param([Parameter(ValueFromRemainingArguments)]$args)
        if ($args.Count -gt 0) {
            Get-ChildItem -Recurse -Filter $args[0] -ErrorAction SilentlyContinue
        } else {
            Get-ChildItem -Recurse -ErrorAction SilentlyContinue
        }
    }
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

    Write-ToolStatus -Name "delta" -Installed $true -Description "enhanced git diff"
} else {
    Write-ToolStatus -Name "delta" -Installed $false -Description "better git diff" -ScoopPackage "delta"
    # Fallback: git will use default pager (less or built-in)
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
