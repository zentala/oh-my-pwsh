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

# cp, mv, rm - File operations (defined as functions below for flag support)

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
# FILE OPERATIONS WITH LINUX FLAGS
# ============================================

# rm - Remove files/directories (supports -Recurse, -Force)
# Note: Use full parameter names due to PowerShell conflicts
# For quick recursive+force removal, use 'rr' alias
function rm {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [switch]$Recurse,

        [Parameter(Mandatory=$false)]
        [switch]$Force,

        [Parameter(ValueFromRemainingArguments=$true)]
        [string[]]$Paths
    )

    # If no paths specified, show usage
    if (-not $Paths -or $Paths.Count -eq 0) {
        Write-Host "Usage: rm [-Recurse] [-Force] <path>..." -ForegroundColor Yellow
        Write-Host "  Quick alias: rr <path>  (recursive + force)" -ForegroundColor DarkGray
        if ($global:OhMyPwsh_ShowAliasTargets) {
            Write-Host "  → Remove-Item [-Recurse] [-Force] <path>" -ForegroundColor DarkGray
        }
        return
    }

    # Execute removal
    foreach ($path in $Paths) {
        try {
            Remove-Item -Path $path -Recurse:$Recurse -Force:$Force -ErrorAction Stop

            if ($global:OhMyPwsh_ShowFeedback) {
                $action = if ($Recurse) { "Removed recursively" } else { "Removed" }
                Write-Host "✓ $action`: $path" -ForegroundColor Green

                if ($global:OhMyPwsh_ShowAliasTargets) {
                    $cmd = "Remove-Item"
                    if ($Recurse) { $cmd += " -Recurse" }
                    if ($Force) { $cmd += " -Force" }
                    Write-Host "  → $cmd" -ForegroundColor DarkGray
                }
            }
        }
        catch {
            Write-Host "✗ Failed to remove: $path" -ForegroundColor Red
            Write-Host "  $($_.Exception.Message)" -ForegroundColor DarkRed
        }
    }
}

# rr - Quick alias for recursive+force removal (like rm -rf in Linux)
function rr {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments=$true)]
        [string[]]$Paths
    )

    if (-not $Paths -or $Paths.Count -eq 0) {
        Write-Host "Usage: rr <path>...  (recursive + force removal)" -ForegroundColor Yellow
        Write-Host "  Equivalent to: rm -Recurse -Force <path>" -ForegroundColor DarkGray
        return
    }

    foreach ($path in $Paths) {
        try {
            Remove-Item -Path $path -Recurse -Force -ErrorAction Stop

            if ($global:OhMyPwsh_ShowFeedback) {
                Write-Host "✓ Removed recursively (forced): $path" -ForegroundColor Green

                if ($global:OhMyPwsh_ShowAliasTargets) {
                    Write-Host "  → Remove-Item -Recurse -Force" -ForegroundColor DarkGray
                }
            }
        }
        catch {
            Write-Host "✗ Failed to remove: $path" -ForegroundColor Red
            Write-Host "  $($_.Exception.Message)" -ForegroundColor DarkRed
        }
    }
}

# rmdir - Remove directory recursively (like rr)
# Remove default PowerShell alias first
Remove-Item Alias:rmdir -ErrorAction SilentlyContinue

function rmdir {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments=$true)]
        [string[]]$Paths
    )

    # In Linux, rmdir removes only empty dirs, but PowerShell's Remove-Item is recursive
    # We follow PowerShell behavior for consistency
    if (-not $Paths -or $Paths.Count -eq 0) {
        Write-Host "Usage: rmdir <path>...  (recursive + force removal)" -ForegroundColor Yellow
        Write-Host "  Equivalent to: rr <path>" -ForegroundColor DarkGray
        return
    }

    foreach ($path in $Paths) {
        try {
            Remove-Item -Path $path -Recurse -Force -ErrorAction Stop

            if ($global:OhMyPwsh_ShowFeedback) {
                Write-Host "✓ Removed directory recursively: $path" -ForegroundColor Green

                if ($global:OhMyPwsh_ShowAliasTargets) {
                    Write-Host "  → Remove-Item -Recurse -Force" -ForegroundColor DarkGray
                }
            }
        }
        catch {
            Write-Host "✗ Failed to remove: $path" -ForegroundColor Red
            Write-Host "  $($_.Exception.Message)" -ForegroundColor DarkRed
        }
    }
}

# cp - Copy files/directories (supports -Recurse, -Force)
function cp {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [switch]$Recurse,

        [Parameter(Mandatory=$false)]
        [switch]$Force,

        [Parameter(ValueFromRemainingArguments=$true)]
        [string[]]$Paths
    )

    # Need at least source and destination
    if (-not $Paths -or $Paths.Count -lt 2) {
        Write-Host "Usage: cp [-Recurse] [-Force] <source> <destination>" -ForegroundColor Yellow
        if ($global:OhMyPwsh_ShowAliasTargets) {
            Write-Host "  → Copy-Item [-Recurse] [-Force] <source> <destination>" -ForegroundColor DarkGray
        }
        return
    }

    try {
        Copy-Item -Path $Paths[0] -Destination $Paths[1] -Recurse:$Recurse -Force:$Force -ErrorAction Stop

        if ($global:OhMyPwsh_ShowFeedback) {
            $action = if ($Recurse) { "Copied recursively" } else { "Copied" }
            Write-Host "✓ $action`: $($Paths[0]) → $($Paths[1])" -ForegroundColor Green

            if ($global:OhMyPwsh_ShowAliasTargets) {
                $cmd = "Copy-Item"
                if ($Recurse) { $cmd += " -Recurse" }
                if ($Force) { $cmd += " -Force" }
                Write-Host "  → $cmd" -ForegroundColor DarkGray
            }
        }
    }
    catch {
        Write-Host "✗ Failed to copy: $($Paths[0])" -ForegroundColor Red
        Write-Host "  $($_.Exception.Message)" -ForegroundColor DarkRed
    }
}

# mv - Move/rename files (supports -Force)
function mv {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [switch]$Force,

        [Parameter(ValueFromRemainingArguments=$true)]
        [string[]]$Paths
    )

    # Need at least source and destination
    if (-not $Paths -or $Paths.Count -lt 2) {
        Write-Host "Usage: mv [-Force] <source> <destination>" -ForegroundColor Yellow
        if ($global:OhMyPwsh_ShowAliasTargets) {
            Write-Host "  → Move-Item [-Force] <source> <destination>" -ForegroundColor DarkGray
        }
        return
    }

    try {
        Move-Item -Path $Paths[0] -Destination $Paths[1] -Force:$Force -ErrorAction Stop

        if ($global:OhMyPwsh_ShowFeedback) {
            Write-Host "✓ Moved: $($Paths[0]) → $($Paths[1])" -ForegroundColor Green

            if ($global:OhMyPwsh_ShowAliasTargets) {
                $cmd = "Move-Item"
                if ($Force) { $cmd += " -Force" }
                Write-Host "  → $cmd" -ForegroundColor DarkGray
            }
        }
    }
    catch {
        Write-Host "✗ Failed to move: $($Paths[0])" -ForegroundColor Red
        Write-Host "  $($_.Exception.Message)" -ForegroundColor DarkRed
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
