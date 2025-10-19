# Command Suggestions Data
# Format: PowerShell Data File (.psd1)
#
# Structure:
# - Tools: Full tool definitions (single source of truth)
# - Suggestions: Map missing commands to tools (references)

@{
    # ═══════════════════════════════════════════════════════════
    # TOOLS - Full tool definitions
    # ═══════════════════════════════════════════════════════════
    Tools = @{
        # ───────────────────────────────────────────────────────
        # EDITORS
        # ───────────────────────────────────────────────────────

        micro = @{
            Name = 'micro'
            Category = 'editor'
            Description = 'Easy terminal editor (most similar to ee)'
            LongDescription = 'Modern terminal-based text editor with mouse support and familiar keybindings. Perfect for users coming from ee or nano.'
            InstallCmd = 'winget install zyedidia.micro'
            PackageManager = 'winget'
            RequiresAdmin = $false
            LinuxEquiv = @('ee', 'nano')
            Features = @(
                'Mouse support'
                'Familiar keybindings (Ctrl+S, Ctrl+Q)'
                'Syntax highlighting'
                'No learning curve (unlike vim)'
                'Multiple cursors'
                'Plugin system'
            )
            Homepage = 'https://micro-editor.github.io'
        }

        nano = @{
            Name = 'nano'
            Category = 'editor'
            Description = 'Simple Unix-style editor'
            LongDescription = 'GNU nano text editor ported to Windows. Lightweight and familiar for Linux users.'
            InstallCmd = 'winget install GNU.Nano'
            PackageManager = 'winget'
            RequiresAdmin = $false
            LinuxEquiv = @('nano', 'pico')
            Features = @(
                'Lightweight'
                'Familiar for Linux users'
                'Simple keybindings'
                'Built-in help (Ctrl+G)'
            )
            Homepage = 'https://www.nano-editor.org'
        }

        nvim = @{
            Name = 'nvim'
            Category = 'editor'
            Description = 'Modern Vim (advanced)'
            LongDescription = 'Neovim - hyperextensible Vim-based text editor with better defaults and Lua scripting.'
            InstallCmd = 'winget install Neovim.Neovim'
            PackageManager = 'winget'
            RequiresAdmin = $false
            LinuxEquiv = @('vim', 'vi', 'nvim')
            Features = @(
                'Powerful and extensible'
                'Lua scripting support'
                'Active plugin ecosystem'
                'Better defaults than Vim'
                'Async operations'
                'Steep learning curve'
            )
            Homepage = 'https://neovim.io'
        }

        vim = @{
            Name = 'vim'
            Category = 'editor'
            Description = 'Classic Vim'
            LongDescription = 'Vi IMproved - the classic programmers text editor. Available everywhere, powerful but requires learning.'
            InstallCmd = 'winget install Vim.Vim'
            PackageManager = 'winget'
            RequiresAdmin = $false
            LinuxEquiv = @('vim', 'vi')
            Features = @(
                'Modal editing'
                'Powerful text manipulation'
                'Ubiquitous (available everywhere)'
                'Vimscript for customization'
                'Steep learning curve'
            )
            Homepage = 'https://www.vim.org'
        }

        # ───────────────────────────────────────────────────────
        # SYSTEM TOOLS
        # ───────────────────────────────────────────────────────

        gsudo = @{
            Name = 'gsudo'
            Category = 'system'
            Description = 'Linux-style sudo for Windows'
            LongDescription = 'A sudo for Windows - run elevated commands from current console without losing context.'
            InstallCmd = 'winget install gerardog.gsudo'
            PackageManager = 'winget'
            RequiresAdmin = $false
            LinuxEquiv = @('sudo')
            Features = @(
                'Elevate commands without UAC popup'
                'Preserve current directory and environment'
                'Cache credentials (optional)'
                'Works with PowerShell, CMD, Git Bash'
                'Colored output support'
            )
            Homepage = 'https://gerardog.github.io/gsudo'
        }

        # ───────────────────────────────────────────────────────
        # FUTURE: More tools can be added here
        # ───────────────────────────────────────────────────────
        # - Package managers (winget, scoop, chocolatey)
        # - Network tools (curl alternatives, etc.)
        # - System monitoring (htop alternatives like btm, ntop)
    }

    # ═══════════════════════════════════════════════════════════
    # SUGGESTIONS - Map missing commands to tools
    # ═══════════════════════════════════════════════════════════
    Suggestions = @{
        # ───────────────────────────────────────────────────────
        # EDITORS
        # ───────────────────────────────────────────────────────

        # When user types 'ee' (Easy Editor from FreeBSD)
        ee = @{
            Primary = 'micro'              # Reference to Tools.micro
            Alternatives = @('nano', 'nvim')  # References to Tools.nano, Tools.nvim
            Context = 'Easy Editor from FreeBSD - simple text editor similar to nano'
        }

        # When user types 'vim'
        vim = @{
            Primary = 'nvim'               # Suggest modern Neovim
            Alternatives = @('vim', 'micro')
            Context = 'Vi IMproved text editor - suggest modern Neovim or easier micro'
        }

        # When user types 'vi'
        vi = @{
            Primary = 'nvim'
            Alternatives = @('vim')
            Context = 'Vi editor - use modern Neovim instead of classic vi'
        }

        # When user types 'nano'
        nano = @{
            Primary = 'nano'               # Direct match - install nano
            Alternatives = @('micro')      # micro is easier for Windows users
            Context = 'GNU nano text editor - available on Windows too'
        }

        # ───────────────────────────────────────────────────────
        # SYSTEM TOOLS
        # ───────────────────────────────────────────────────────

        # When user types 'sudo'
        sudo = @{
            Primary = 'gsudo'
            Alternatives = @()
            Context = 'Superuser do - use gsudo for Windows privilege elevation'
        }

        # ───────────────────────────────────────────────────────
        # FUTURE: More suggestions
        # ───────────────────────────────────────────────────────
        # apt = @{ Primary = 'winget'; Alternatives = @('scoop', 'chocolatey') }
        # htop = @{ Primary = 'btm'; Alternatives = @('ntop') }
        # tree = @{ Primary = 'tree'; Alternatives = @() }  # tree exists as PowerShell alias
    }
}
