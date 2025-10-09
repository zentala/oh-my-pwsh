# ============================================
# ZMIENNE ŚRODOWISKOWE & PATH
# ============================================

# GitHub CLI - dodaj do PATH
$ghPath = "$env:LOCALAPPDATA\Temp\gh\bin"
if (Test-Path $ghPath) {
    $env:PATH = "$ghPath;$env:PATH"
}
