# 🚀 Modular PowerShell Profile

Modular PowerShell profile for Windows 11 with Oh My Posh, PSReadLine, and Linux-style aliases.

## 📂 Structure

```
pwsh-profile/
├── profile.ps1              # Main loader file
├── modules/
│   ├── aliases.ps1          # Linux-style aliases (ls, grep, cat, ...)
│   ├── functions.ps1        # Helper functions (touch, mkcd, .., ...)
│   ├── git-helpers.ps1      # Git shortcuts (gs, ga, gc, gp, ...)
│   ├── psreadline.ps1       # PSReadLine configuration
│   └── environment.ps1      # PATH & environment variables
├── scripts/                 # Private scripts
└── themes/                  # Oh My Posh themes (optional)
```

## 🔧 Installation

1. Clone the repo to `C:\code\`:
   ```powershell
   cd C:\code
   git clone git@github.com:zentala/pwsh-profile.git
   ```

2. Replace your main PowerShell profile:
   ```powershell
   # Backup old profile
   Copy-Item $PROFILE "$PROFILE.backup"

   # Create symlink or load from repo
   . C:\code\pwsh-profile\profile.ps1
   ```

3. Restart PowerShell

## ✨ Features

- ✅ **Linux-style aliases** - `ls`, `grep`, `cat`, `touch`, `which`, ...
- ✅ **Git shortcuts** - `gs`, `ga`, `gc "msg"`, `gp`, `gl`
- ✅ **PSReadLine** - Fish/Zsh-like autocompletion
- ✅ **Oh My Posh** - Beautiful prompt
- ✅ **Oh My Stats** - System stats on startup
- ✅ **Quick navigation** - `..`, `...`, `....`, `mkcd`

## 🛠️ Requirements

- PowerShell 7.x
- Oh My Posh
- PSReadLine
- Terminal Icons (optional)
- Oh My Stats (optional)

## 📝 License

MIT - Paweł Żentała © 2025
