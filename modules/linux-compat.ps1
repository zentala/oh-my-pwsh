# ============================================
# Linux Compatibility Module
# ============================================
# Provides Linux-style aliases and functions for PowerShell
# Can be disabled by setting $OhMyPwsh_EnableLinuxCompat = $false

if (-not $global:OhMyPwsh_EnableLinuxCompat) {
    return
}

# ============================================
# BASIC COMMANDS
# ============================================

Set-Alias grep Select-String
Set-Alias which Get-Command
Set-Alias whereis Get-Command
Set-Alias clear Clear-Host
Set-Alias cls Clear-Host
Set-Alias less more
Set-Alias head 'Get-Content -TotalCount'
Set-Alias tail 'Get-Content -Tail'

# cp, mv, rm - File operations
Remove-Alias cp -ErrorAction SilentlyContinue
Set-Alias cp Copy-Item
Set-Alias mv Move-Item
Set-Alias rm Remove-Item
Set-Alias rmdir Remove-Item

# pwd, ps - System info
Set-Alias pwd Get-Location
Set-Alias ps Get-Process
Set-Alias kill Stop-Process

# echo, date - Output & time
Remove-Alias echo -ErrorAction SilentlyContinue
Set-Alias echo Write-Output
Set-Alias date Get-Date

# System info
Set-Alias whoami '$env:USERNAME'
Set-Alias hostname '$env:COMPUTERNAME'
Set-Alias df Get-PSDrive
Set-Alias du Get-ChildItem

# Archives & download
Set-Alias unzip Expand-Archive
Set-Alias zip Compress-Archive
Set-Alias wget Invoke-WebRequest
Set-Alias curl Invoke-WebRequest

# Help & history
Set-Alias man Get-Help
Set-Alias history Get-History

# ============================================
# EDITORS
# ============================================

Set-Alias vim 'C:\Program Files\Vim\vim90\vim.exe' -ErrorAction SilentlyContinue
Set-Alias vi vim -ErrorAction SilentlyContinue
Set-Alias nano 'notepad' -ErrorAction SilentlyContinue

# ============================================
# SHORTCUTS
# ============================================

Set-Alias g git
Set-Alias docker-compose 'docker compose'
Set-Alias k kubectl -ErrorAction SilentlyContinue
Set-Alias py python
Set-Alias python3 python

# ============================================
# LINUX-STYLE FUNCTIONS
# ============================================

# ls, ll, la - Directory listing
function ls {
    param([Parameter(ValueFromRemainingArguments)]$args)
    Get-ChildItem @args
}

function ll {
    param([Parameter(ValueFromRemainingArguments)]$args)
    Get-ChildItem @args
}

function la {
    param([Parameter(ValueFromRemainingArguments)]$args)
    Get-ChildItem -Force @args
}

# mkdir - Create directories (supports -p flag)
function mkdir {
    param(
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$paths
    )

    # Remove -p flag if present (Linux compatibility)
    $paths = $paths | Where-Object { $_ -ne '-p' }

    foreach ($path in $paths) {
        New-Item -ItemType Directory -Path $path -Force | Out-Null

        if ($global:OhMyPwsh_ShowFeedback) {
            Write-Host "✓ Created directory: $path" -ForegroundColor Green

            if ($global:OhMyPwsh_ShowAliasTargets) {
                Write-Host "  → New-Item -ItemType Directory -Force" -ForegroundColor DarkGray
            }
        }
    }
}

# touch - Create or update file timestamp
function touch {
    param($file)

    if (!(Test-Path $file)) {
        New-Item -ItemType File -Path $file | Out-Null

        if ($global:OhMyPwsh_ShowFeedback) {
            Write-Host "✓ Created file: $file" -ForegroundColor Green

            if ($global:OhMyPwsh_ShowAliasTargets) {
                Write-Host "  → New-Item -ItemType File" -ForegroundColor DarkGray
            }
        }
    } else {
        (Get-Item $file).LastWriteTime = Get-Date

        if ($global:OhMyPwsh_ShowFeedback) {
            Write-Host "✓ Updated timestamp: $file" -ForegroundColor Cyan
        }
    }
}

# Navigation shortcuts
function .. { Set-Location .. }
function ... { Set-Location ..\.. }
function .... { Set-Location ..\..\.. }
function ~ { Set-Location $HOME }
function code. { code . }

# mkcd - Create directory and cd into it
function mkcd {
    param($dir)
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    Set-Location $dir

    if ($global:OhMyPwsh_ShowFeedback) {
        Write-Host "✓ Created and entered: $dir" -ForegroundColor Green
    }
}

# ============================================
# COMPATIBILITY WARNINGS
# ============================================

function chmod {
    Write-Host "chmod doesn't work on Windows - use: icacls or Properties > Security" -ForegroundColor Yellow
    if ($global:OhMyPwsh_ShowAliasTargets) {
        Write-Host "  → Windows alternative: icacls <file> /grant <user>:<permission>" -ForegroundColor DarkGray
    }
}

function chown {
    Write-Host "chown doesn't work on Windows - use: icacls or Properties > Security" -ForegroundColor Yellow
    if ($global:OhMyPwsh_ShowAliasTargets) {
        Write-Host "  → Windows alternative: icacls <file> /setowner <user>" -ForegroundColor DarkGray
    }
}

function apt {
    Write-Host "apt doesn't work on Windows - use: winget, choco, or scoop" -ForegroundColor Yellow
    if ($global:OhMyPwsh_ShowAliasTargets) {
        Write-Host "  → Recommended: scoop install <package>" -ForegroundColor DarkGray
    }
}

function sudo {
    param([Parameter(ValueFromRemainingArguments)]$cmd)
    Start-Process pwsh -ArgumentList "-Command", $cmd -Verb RunAs
}

function ssh-keygen {
    ssh-keygen.exe @args
}

# Export module
Export-ModuleMember -Function * -Alias *
