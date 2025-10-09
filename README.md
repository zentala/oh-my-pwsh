# 🚀 PowerShell Profile - Paweł Żentała

Modularny PowerShell profile dla Windows 11 z Oh My Posh, PSReadLine i aliasami linuxowymi.

## 📂 Struktura

```
pwsh-profile/
├── profile.ps1              # Główny plik (loader)
├── modules/
│   ├── aliases.ps1          # Aliasy linuxowe (ls, grep, cat, ...)
│   ├── functions.ps1        # Funkcje pomocnicze (touch, mkcd, .., ...)
│   ├── git-helpers.ps1      # Git shortcuts (gs, ga, gc, gp, ...)
│   ├── psreadline.ps1       # Konfiguracja PSReadLine
│   └── environment.ps1      # PATH & zmienne środowiskowe
├── scripts/                 # Prywatne skrypty
└── themes/                  # Oh My Posh themes (opcjonalnie)
```

## 🔧 Instalacja

1. Sklonuj repo do `C:\code\`:
   ```powershell
   cd C:\code
   git clone git@github.com:zentala/pwsh-profile.git
   ```

2. Podmień główny profil PowerShell:
   ```powershell
   # Backup starego profilu
   Copy-Item $PROFILE "$PROFILE.backup"

   # Utwórz symlink lub załaduj z repo
   . C:\code\pwsh-profile\profile.ps1
   ```

3. Restart PowerShell

## ✨ Features

- ✅ **Aliasy linuxowe** - `ls`, `grep`, `cat`, `touch`, `which`, ...
- ✅ **Git shortcuts** - `gs`, `ga`, `gc "msg"`, `gp`, `gl`
- ✅ **PSReadLine** - autouzupełnianie jak w fish/zsh
- ✅ **Oh My Posh** - piękny prompt
- ✅ **Oh My Stats** - system stats przy starcie
- ✅ **Szybkie nawigowanie** - `..`, `...`, `....`, `mkcd`

## 🛠️ Wymagania

- PowerShell 7.x
- Oh My Posh
- PSReadLine
- Terminal Icons (opcjonalnie)
- Oh My Stats (opcjonalnie)

## 📝 Licencja

MIT - Paweł Żentała © 2025
