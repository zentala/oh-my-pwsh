# ============================================
# FUNKCJE POMOCNICZE
# ============================================

# Linux-style ls commands with flags support
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

# Funkcje emulujące komendy Linux
function chmod {
    Write-Host "chmod nie działa na Windows - użyj: icacls lub Properties > Security" -ForegroundColor Yellow
}

function chown {
    Write-Host "chown nie działa na Windows - użyj: icacls lub Properties > Security" -ForegroundColor Yellow
}

function sudo {
    param([Parameter(ValueFromRemainingArguments)]$cmd)
    Start-Process pwsh -ArgumentList "-Command", $cmd -Verb RunAs
}

function apt {
    Write-Host "apt nie działa na Windows - użyj: winget, choco lub scoop" -ForegroundColor Yellow
}

function ssh-keygen {
    ssh-keygen.exe @args
}

# Nawigacja
function .. { Set-Location .. }
function ... { Set-Location ..\.. }
function .... { Set-Location ..\..\.. }
function ~ { Set-Location $HOME }
function code. { code . }

# Funkcja touch jak w Linux
function touch {
    param($file)
    if (!(Test-Path $file)) {
        New-Item -ItemType File -Path $file | Out-Null
        Write-Host "✓ Created: $file" -ForegroundColor Green
    } else {
        (Get-Item $file).LastWriteTime = Get-Date
    }
}

# Funkcja mkdir jak w Linux - tworzy katalog
# Obsługuje -p (mkdir -p path/to/dir działa dzięki -Force)
function mkdir {
    param(
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$paths
    )
    # Remove -p flag if present (compatibility with Linux)
    $paths = $paths | Where-Object { $_ -ne '-p' }

    foreach ($path in $paths) {
        New-Item -ItemType Directory -Path $path -Force | Out-Null
        Write-Host "✓ Created directory: $path" -ForegroundColor Green
    }
}

# Funkcja dla szybkiego mkdir i cd
function mkcd {
    param($dir)
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    Set-Location $dir
}

function Test-ProfileDoctorPath {
    param([string]$Path)

    if (-not (Test-Path $Path)) {
        return [PSCustomObject]@{ Path = $Path; Exists = $false; Writable = $false; Error = "missing" }
    }

    try {
        $probe = Join-Path $Path ".profile-doctor-write-test"
        Set-Content -Path $probe -Value "ok" -ErrorAction Stop
        Remove-Item -Path $probe -Force -ErrorAction Stop
        return [PSCustomObject]@{ Path = $Path; Exists = $true; Writable = $true; Error = $null }
    } catch {
        return [PSCustomObject]@{ Path = $Path; Exists = $true; Writable = $false; Error = $_.Exception.Message }
    }
}

function Get-ProfileDoctorChecks {
    $paths = @(
        "C:\Users\zentala\AppData\Roaming\powershell\Community\Terminal-Icons",
        "C:\Users\zentala\AppData\Local\Packages\ohmyposh.cli_96v55e8n804z4\LocalCache\Local\oh-my-posh",
        "C:\Users\zentala\AppData\Local\fnm_multishells"
    )

    return [PSCustomObject]@{
        AgentSession = $env:CODEX_CI -eq '1' -or $env:TERM -eq 'dumb'
        WmiAvailable = [bool](Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue)
        Commands = [PSCustomObject]@{
            Fnm = [bool](Get-Command fnm -ErrorAction SilentlyContinue)
            OhMyPosh = [bool](Get-Command oh-my-posh -ErrorAction SilentlyContinue)
            Zoxide = [bool](Get-Command zoxide -ErrorAction SilentlyContinue)
        }
        Modules = [PSCustomObject]@{
            TerminalIcons = [bool](Get-Module -ListAvailable Terminal-Icons)
            PoshGit = [bool](Get-Module -ListAvailable posh-git)
        }
        Paths = $paths | ForEach-Object { Test-ProfileDoctorPath $_ }
    }
}

function profile-doctor {
    $report = Get-ProfileDoctorChecks

    Write-Host ""
    Write-Host "  profile doctor" -ForegroundColor Cyan
    Write-Host "  ──────────────" -ForegroundColor DarkGray
    Write-Host "  Agent session: $($report.AgentSession)" -ForegroundColor White
    Write-Host "  WMI available: $($report.WmiAvailable)" -ForegroundColor White
    Write-Host "  fnm: $($report.Commands.Fnm) | oh-my-posh: $($report.Commands.OhMyPosh) | zoxide: $($report.Commands.Zoxide)" -ForegroundColor White
    Write-Host "  Terminal-Icons: $($report.Modules.TerminalIcons) | posh-git: $($report.Modules.PoshGit)" -ForegroundColor White

    foreach ($pathCheck in $report.Paths) {
        if ($pathCheck.Writable) {
            Write-StatusMessage -Role success -Message "$($pathCheck.Path) writable"
        } elseif ($pathCheck.Exists) {
            Write-StatusMessage -Role warning -Message "$($pathCheck.Path) not writable: $($pathCheck.Error)"
        } else {
            Write-StatusMessage -Role warning -Message "$($pathCheck.Path) missing"
        }
    }

    return $report
}
