# 🚀 Modular PowerShell Profile

A modern, powerful PowerShell profile for Windows 11 with all the tools you need for a productive terminal experience.

<img src="https://cdn.zentala.io/terminal/pwsh.png" alt="PowerShell Terminal Screenshot" style="max-width: 700px; height: auto;">

## ✨ What You Get

### 🎨 Beautiful Terminal
- **[Oh My Posh](https://ohmyposh.dev/)** - Stunning prompt with git status, execution time, and more
- **[posh-git](https://github.com/dahlbyk/posh-git)** - Git branch/status integration in prompt
- **[Terminal Icons](https://github.com/devblackops/Terminal-Icons)** - Colorful file/folder icons
- **[Oh My Stats](https://github.com/zentala/oh-my-stats)** - System stats (CPU, RAM, disk) on startup

### ⚡ Productivity Tools
- **[PSReadLine](https://github.com/PowerShell/PSReadLine)** - Fish/Zsh-like autocompletion with history
- **[PSFzf](https://github.com/kelleyma49/PSFzf)** - Fuzzy search for files, history, git (`Ctrl+R`, `Ctrl+T`)
- **[zoxide](https://github.com/ajeetdsouza/zoxide)** - Smart directory jumping - `z` remembers your most used folders
- **[gsudo](https://github.com/gerardog/gsudo)** - Linux-style `sudo` for Windows

### 🐧 Linux-Style Experience
- **Aliases** - `ls -la`, `grep`, `cat`, `touch`, `which`, `curl`, `wget`, and more
- **Git shortcuts** - `gs` (status), `ga` (add), `gc "msg"` (commit), `gp` (push), `gl` (log)
- **Quick navigation** - `..`, `...`, `....`, `~`, `mkcd newdir`
- **Helper functions** - `touch`, `mkcd`, `sudo`, and more

## 📂 Structure

```
pwsh-profile/
├── profile.ps1                    # Main loader file
├── modules/
│   ├── aliases.ps1                # Linux-style aliases (ls, grep, cat, ...)
│   ├── functions.ps1              # Helper functions (touch, mkcd, .., ...)
│   ├── git-helpers.ps1            # Git shortcuts (gs, ga, gc, gp, ...)
│   ├── psreadline.ps1             # PSReadLine configuration
│   └── environment.ps1            # PATH & environment variables
├── scripts/
│   └── install-dependencies.ps1   # Automatic dependency installer
└── themes/                        # Oh My Posh themes (optional)
```

## 🔧 Installation

### Quick Install (Automated)

1. **Clone the repo:**
   ```powershell
   cd C:\code
   git clone git@github.com:zentala/pwsh-profile.git
   cd pwsh-profile
   ```

2. **Run installation script:**
   ```powershell
   pwsh -ExecutionPolicy Bypass -File scripts\install-dependencies.ps1
   ```

   This will automatically check and install all dependencies!

3. **Restart PowerShell** and enjoy your modern terminal!

---

### Manual Install (Step by Step)

### 1. Clone the repo

```powershell
cd C:\code
git clone git@github.com:zentala/pwsh-profile.git
```

### 2. Install PowerShell 7.x

```powershell
winget install Microsoft.PowerShell
```

### 3. Install Required Tools

```powershell
# Oh My Posh - Beautiful prompt
winget install JanDeDobbeleer.OhMyPosh

# fzf - Fuzzy finder binary (required for PSFzf)
winget install fzf

# zoxide - Smart directory jumping (Rust-based, super fast)
winget install ajeetdsouza.zoxide

# gsudo - Linux-style sudo for Windows
winget install gerardog.gsudo
```

### 4. Install PowerShell Modules

```powershell
# PSReadLine - Advanced command line editing
Install-Module -Name PSReadLine -Force

# posh-git - Git integration
Install-Module -Name posh-git -Scope CurrentUser

# Terminal-Icons - File icons
Install-Module -Name Terminal-Icons -Scope CurrentUser

# PSFzf - Fuzzy finder for PowerShell
Install-Module -Name PSFzf -Scope CurrentUser

# Oh My Stats - System stats (optional but recommended)
# See: https://github.com/zentala/oh-my-stats
```

### 5. Load Profile

Replace your main PowerShell profile:

```powershell
# Backup old profile
Copy-Item $PROFILE "$PROFILE.backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"

# Create new profile that loads from repo
@"
# Load profile from repo
`$ProfileRepo = "C:\code\pwsh-profile\profile.ps1"
if (Test-Path `$ProfileRepo) {
    . `$ProfileRepo
}
"@ | Out-File $PROFILE -Encoding UTF8
```

### 6. Restart PowerShell

Open a new PowerShell window and enjoy your modern terminal!

## 🎯 Key Features Explained

### Fuzzy Search & Smart Navigation

**PSFzf** - Fuzzy finder:
- **`Ctrl+R`** - Search command history with fuzzy matching
- **`Ctrl+T`** - Search files in current directory
- **`gst`** - Fuzzy git status selector

**zoxide** - Smart directory jumping:
- **`z folder`** - Jump to frequently used folder (e.g., `z code`)
- **`z -`** - Go back to previous directory
- **`zi`** - Interactive folder selection with fzf

### Git Shortcuts

```powershell
gs          # git status
ga          # git add .
gc "msg"    # git commit -m "msg"
gp          # git push
gl          # git log --oneline --graph (last 10)
gco branch  # git checkout branch
```

### Linux-Style Commands

```powershell
ls -la      # List all files with details
touch file  # Create file or update timestamp
mkcd dir    # Create directory and cd into it
which cmd   # Find command location
..          # cd ..
...         # cd ../..
....        # cd ../../..
~           # cd $HOME
```

### Admin Access

```powershell
sudo command  # Run command with admin privileges
```

## 🎨 Customization

### Change Oh My Posh Theme

Edit `profile.ps1` line 32:

```powershell
$omp_config = "$env:POSH_THEMES_PATH\your-theme.omp.json"
```

Browse themes: https://ohmyposh.dev/docs/themes

### Add Your Own Scripts

Place your scripts in `scripts/` folder and source them in `profile.ps1`.

## 📊 Performance

Profile loads in ~1-2 seconds with all features enabled. Timer is included - check `$global:PSProfileLoadStart` to measure.

## 📝 License

MIT - Paweł Żentała © 2025

---

**Made with ❤️ for modern Windows terminal experience**
