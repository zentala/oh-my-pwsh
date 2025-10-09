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

# Funkcja dla szybkiego mkdir i cd
function mkcd {
    param($dir)
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    Set-Location $dir
}
