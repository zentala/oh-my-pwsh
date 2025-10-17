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
