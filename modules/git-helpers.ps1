# ============================================
# GIT SHORTCUTS
# ============================================

function gs { git status }
function ga { git add . }
function gc { param($m) git commit -m $m }
function gp { git push }
function gl { git log --oneline --graph --decorate -10 }
function gco { param($branch) git checkout $branch }
