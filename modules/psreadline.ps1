# ============================================
# PSREADLINE - Konfiguracja autouzupełniania
# ============================================

Import-Module PSReadLine -ErrorAction SilentlyContinue

if (Get-Module -Name PSReadLine) {
    # Tylko w Windows Terminal lub VS Code z Virtual Terminal support
    if ($env:WT_SESSION -or $env:TERM_PROGRAM -eq "vscode" -or $host.UI.SupportsVirtualTerminal) {
        try {
            Set-PSReadLineOption -PredictionSource History -ErrorAction Stop
            Set-PSReadLineOption -PredictionViewStyle ListView -ErrorAction Stop
        } catch {
            # Terminal nie wspiera prediction - ignoruj
        }
    }
    Set-PSReadLineOption -EditMode Windows -ErrorAction SilentlyContinue
    Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete -ErrorAction SilentlyContinue
    Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward -ErrorAction SilentlyContinue
    Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward -ErrorAction SilentlyContinue
}
