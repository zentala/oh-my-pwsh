# ============================================
# Test Write-StatusMessage Function
# ============================================
# Test colored status output with proper color control

# Load dependencies
$ProfileRoot = Split-Path -Parent $PSCommandPath
. "$ProfileRoot\settings\icons.ps1"
. "$ProfileRoot\modules\status-output.ps1"

Write-Host "`n=== TEST 1: Unicode Mode (Default) ===" -ForegroundColor Cyan
$global:OhMyPwsh_UseNerdFonts = $false

Write-Host "`nAll 6 roles:" -ForegroundColor Yellow
Write-StatusMessage -Role "success" -Message "Module loaded successfully"
Write-StatusMessage -Role "warning" -Message "Optional tool missing"
Write-StatusMessage -Role "error" -Message "Critical failure occurred"
Write-StatusMessage -Role "info" -Message "Configuration loaded"
Write-StatusMessage -Role "tip" -Message "Try using the help command"
Write-StatusMessage -Role "question" -Message "Do you want to continue?"

Write-Host "`nNo indent:" -ForegroundColor Yellow
Write-StatusMessage -Role "success" -Message "No indentation" -NoIndent

Write-Host "`n=== TEST 2: Nerd Font Mode ===" -ForegroundColor Cyan
$global:OhMyPwsh_UseNerdFonts = $true

Write-Host "`nAll 6 roles (NF mode):" -ForegroundColor Yellow
Write-StatusMessage -Role "success" -Message "Module loaded successfully"
Write-StatusMessage -Role "warning" -Message "Optional tool missing"
Write-StatusMessage -Role "error" -Message "Critical failure occurred"
Write-StatusMessage -Role "info" -Message "Configuration loaded"
Write-StatusMessage -Role "tip" -Message "Try using the help command"
Write-StatusMessage -Role "question" -Message "Do you want to continue?"

Write-Host "`n=== TEST 3: Color Verification ===" -ForegroundColor Cyan
$global:OhMyPwsh_UseNerdFonts = $false

Write-Host "`nExpected colors:" -ForegroundColor Yellow
Write-Host "  Brackets: DarkGray" -ForegroundColor DarkGray
Write-Host "  Icons: Role colors (see below)" -ForegroundColor White
Write-Host "  Text: White" -ForegroundColor White

Write-Host "`nActual output:" -ForegroundColor Yellow
Write-StatusMessage -Role "success" -Message "Icon should be Green"
Write-StatusMessage -Role "warning" -Message "Icon should be Yellow"
Write-StatusMessage -Role "error" -Message "Icon should be Red"
Write-StatusMessage -Role "info" -Message "Icon should be Cyan"
Write-StatusMessage -Role "tip" -Message "Icon should be Blue"
Write-StatusMessage -Role "question" -Message "Icon should be Magenta"

Write-Host "`n=== DONE ===" -ForegroundColor Green
Write-Host ""
