# ============================================
# Enhanced Tools Module
# ============================================
# Modern alternatives to classic Unix tools
# Requires: scoop install bat eza ripgrep fd delta

if (-not $global:OhMyPwsh_UseEnhancedTools) {
    return
}

# Use cached tool availability (populated by profile-cache.ps1)
$_tools = if ($global:_ProfileAvailability) { $global:_ProfileAvailability.Tools } else { $null }
$_showStatus = $global:_ProfileCacheFresh

function _HasTool($name) {
    if ($_tools) { return [bool]$_tools.$name }
    return [bool](Get-Command $name -ErrorAction SilentlyContinue)
}

# ============================================
# BAT - Better cat with syntax highlighting
# ============================================
# Install: scoop install bat
# Docs: https://github.com/sharkdp/bat

if (_HasTool bat) {
    function cat {
        param([Parameter(ValueFromRemainingArguments)]$args)
        bat @args
    }
    if ($_showStatus) { Write-ToolStatus -Name "bat" -Installed $true -Description "enhanced cat" }
} else {
    if ($_showStatus) { Write-ToolStatus -Name "bat" -Installed $false -Description "improved cat" -ScoopPackage "bat" }
    Set-Alias cat Get-Content
}

# ============================================
# EZA - Modern ls alternative
# ============================================
# Install: scoop install eza
# Docs: https://github.com/eza-community/eza

if (_HasTool eza) {
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

    if ($_showStatus) { Write-ToolStatus -Name "eza" -Installed $true -Description "enhanced ls" }
} else {
    if ($_showStatus) { Write-ToolStatus -Name "eza" -Installed $false -Description "modern ls" -ScoopPackage "eza" }
}

# ============================================
# RIPGREP (rg) - Faster grep
# ============================================
# Install: scoop install ripgrep
# Docs: https://github.com/BurntSushi/ripgrep

if (_HasTool rg) {
    function grep {
        param([Parameter(ValueFromRemainingArguments)]$args)
        rg @args
    }

    if ($_showStatus) { Write-ToolStatus -Name "ripgrep" -Installed $true -Description "enhanced grep" }
} else {
    if ($_showStatus) { Write-ToolStatus -Name "ripgrep" -Installed $false -Description "faster grep" -ScoopPackage "ripgrep" }
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

if (_HasTool fd) {
    function find {
        param([Parameter(ValueFromRemainingArguments)]$args)
        fd @args
    }

    if ($_showStatus) { Write-ToolStatus -Name "fd" -Installed $true -Description "enhanced find" }
} else {
    if ($_showStatus) { Write-ToolStatus -Name "fd" -Installed $false -Description "faster find" -ScoopPackage "fd" }
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

if (_HasTool delta) {
    # Configure git to use delta
    git config --global core.pager "delta"
    git config --global interactive.diffFilter "delta --color-only"
    git config --global delta.navigate true
    git config --global delta.light false
    git config --global merge.conflictstyle diff3
    git config --global diff.colorMoved default

    if ($_showStatus) { Write-ToolStatus -Name "delta" -Installed $true -Description "enhanced git diff" }
} else {
    if ($_showStatus) { Write-ToolStatus -Name "delta" -Installed $false -Description "better git diff" -ScoopPackage "delta" }
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
