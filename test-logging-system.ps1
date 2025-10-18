# ============================================
# Test Logging System with Message Segments
# ============================================
# Test Write-StatusMessage with styled message composition

# Load dependencies
$ProfileRoot = Split-Path -Parent $PSCommandPath
. "$ProfileRoot\settings\icons.ps1"
. "$ProfileRoot\modules\status-output.ps1"
. "$ProfileRoot\modules\logger.ps1"

Write-Host "`n=== TEST 1: Simple String Messages ===" -ForegroundColor Cyan
$global:OhMyPwsh_UseNerdFonts = $false

Write-StatusMessage -Role "success" -Message "Simple success message"
Write-StatusMessage -Role "warning" -Message "Simple warning message"
Write-StatusMessage -Role "error" -Message "Simple error message"
Write-StatusMessage -Role "info" -Message "Simple info message"

Write-Host "`n=== TEST 2: Styled Message Segments ===" -ForegroundColor Cyan

# Example 1: Highlight tool name
$segments1 = @(
    @{Text = "install "; Color = "White"}
    @{Text = "bat"; Color = "Yellow"}
    @{Text = " for improved cat: "; Color = "White"}
    @{Text = "scoop install bat"; Color = "DarkGray"}
)
Write-StatusMessage -Role "warning" -Message $segments1

# Example 2: Multiple colors
$segments2 = @(
    @{Text = "Module "; Color = "White"}
    @{Text = "PSFzf"; Color = "Cyan"}
    @{Text = " loaded with "; Color = "White"}
    @{Text = "Ctrl+R"; Color = "Yellow"}
    @{Text = " and "; Color = "White"}
    @{Text = "Ctrl+T"; Color = "Yellow"}
)
Write-StatusMessage -Role "success" -Message $segments2

# Example 3: Error with highlighted part
$segments3 = @(
    @{Text = "Failed to load "; Color = "White"}
    @{Text = "config.ps1"; Color = "Yellow"}
    @{Text = " - file not found"; Color = "White"}
)
Write-StatusMessage -Role "error" -Message $segments3

Write-Host "`n=== TEST 3: Helper Functions ===" -ForegroundColor Cyan

# Test Write-InstallHint with styled segments
Write-InstallHint -Tool "ripgrep" -Description "faster grep" -InstallCommand "scoop install ripgrep"
Write-InstallHint -Tool "delta" -InstallCommand "scoop install delta"

# Test Write-ModuleStatus
Write-ModuleStatus -Name "Terminal-Icons" -Loaded $true
Write-ModuleStatus -Name "posh-git" -Loaded $true -Description "Git integration"

# Test Write-ToolStatus
Write-ToolStatus -Name "bat" -Installed $true -Description "enhanced cat"
Write-ToolStatus -Name "eza" -Installed $false -Description "modern ls" -ScoopPackage "eza"

Write-Host "`n=== TEST 4: NoIndent Parameter ===" -ForegroundColor Cyan
Write-StatusMessage -Role "info" -Message "With indent (default)"
Write-StatusMessage -Role "info" -Message "Without indent" -NoIndent

Write-Host "`n=== TEST 5: Edge Cases ===" -ForegroundColor Cyan

# Empty description
Write-InstallHint -Tool "fzf" -Description "" -InstallCommand "winget install fzf"

# Single segment
$singleSegment = @(
    @{Text = "Just one segment"; Color = "Magenta"}
)
Write-StatusMessage -Role "tip" -Message $singleSegment

# Segment without explicit color (should default to White)
$noColorSegment = @(
    @{Text = "No color specified"}
)
Write-StatusMessage -Role "question" -Message $noColorSegment

Write-Host "`n=== DONE ===" -ForegroundColor Green
Write-Host ""
