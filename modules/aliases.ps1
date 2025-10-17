# ============================================
# ALIASY LINUXOWE - Pełna kompatybilność
# ============================================

# Podstawowe komendy
# Note: ls, ll, la are defined as functions in functions.ps1 to support flags
Set-Alias grep Select-String
Set-Alias which Get-Command
Set-Alias whereis Get-Command
Set-Alias clear Clear-Host
Set-Alias cls Clear-Host
Set-Alias cat Get-Content
Set-Alias less more
Set-Alias head 'Get-Content -TotalCount'
Set-Alias tail 'Get-Content -Tail'
# touch is defined as a function in functions.ps1 to properly create files
Remove-Alias cp -ErrorAction SilentlyContinue
Set-Alias cp Copy-Item
Set-Alias mv Move-Item
Set-Alias rm Remove-Item
Set-Alias rmdir Remove-Item
# mkdir is defined as a function in functions.ps1 to support -ItemType Directory
Set-Alias pwd Get-Location
Set-Alias ps Get-Process
Set-Alias kill Stop-Process
Remove-Alias echo -ErrorAction SilentlyContinue
Set-Alias echo Write-Output
Set-Alias date Get-Date
Set-Alias whoami '$env:USERNAME'
Set-Alias hostname '$env:COMPUTERNAME'
Set-Alias df Get-PSDrive
Set-Alias du Get-ChildItem
Set-Alias man Get-Help
Set-Alias history Get-History
Set-Alias unzip Expand-Archive
Set-Alias zip Compress-Archive
Set-Alias wget Invoke-WebRequest
Set-Alias curl Invoke-WebRequest

# Edytory
Set-Alias vim 'C:\Program Files\Vim\vim90\vim.exe' -ErrorAction SilentlyContinue
Set-Alias vi vim -ErrorAction SilentlyContinue
Set-Alias nano 'notepad' -ErrorAction SilentlyContinue

# Skróty do programów
Set-Alias g git
Set-Alias docker-compose 'docker compose'
Set-Alias k kubectl -ErrorAction SilentlyContinue
Set-Alias py python
Set-Alias python3 python
