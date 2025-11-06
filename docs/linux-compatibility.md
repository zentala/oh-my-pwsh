# Linux Compatibility w PowerShell

Ten profil zapewnia kompatybilność z komendami Linuxowymi. Oto co masz zainstalowane i co możesz jeszcze dodać:

## ✅ Już masz zainstalowane

### Moduły PowerShell
- **PSReadLine** - Edycja linii komend jak w bash (Ctrl+R, Ctrl+A, Ctrl+E)
- **posh-git** - Integracja Git w promptcie
- **Terminal-Icons** - Ikony dla plików (jak exa/lsd)
- **PSFzf** - Fuzzy finder (Ctrl+R historia, Ctrl+T pliki)
- **zoxide** - Smart `cd` (komenda `z`)

### Aliasy i funkcje
- `ls`, `ll`, `la` - Listowanie plików
- `grep` - Wyszukiwanie (Select-String)
- `cat`, `head`, `tail` - Czytanie plików
- `touch` - Tworzenie/aktualizacja plików
- `mkdir` - Tworzenie katalogów (wspiera `-p`)
- `rm` - Usuwanie plików (`-Recurse`, `-Force`)
- `rr` - **NOWE!** Szybkie usuwanie rekursywne (jak `rm -rf` w Linux)
- `rmdir` - Usuwanie katalogów rekursywnie
- `cp` - Kopiowanie (`-Recurse`, `-Force`)
- `mv` - Przenoszenie/zmiana nazwy (`-Force`)
- `which`, `whereis` - Znajdowanie komend
- `pwd`, `cd` - Nawigacja
- `..`, `...`, `....` - Szybka nawigacja w górę
- `z` - Smart jump do katalogów (zoxide)

## 🚀 Możesz jeszcze dodać

### 1. Scoop - Package Manager (jak apt/brew)
```powershell
# Instalacja Scoop
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
irm get.scoop.sh | iex

# Podstawowe narzędzia
scoop install git
scoop bucket add extras
scoop bucket add nerd-fonts
```

### 2. GNU Coreutils dla Windows
```powershell
scoop install coreutils
# Daje ci prawdziwe komendy Linux: ls, cat, grep, sed, awk, etc.
# Uwaga: będą dostępne jako gls, gcat, etc. żeby nie konfliktować
```

### 3. Inne przydatne narzędzia
```powershell
scoop install fd          # Lepszy find
scoop install ripgrep     # Lepszy grep (rg)
scoop install bat         # Lepszy cat z syntax highlighting
scoop install eza         # Nowoczesny ls (następca exa)
scoop install delta       # Lepszy git diff
scoop install fzf         # Już używasz przez PSFzf
scoop install zoxide      # Już używasz
```

### 4. WSL (Windows Subsystem for Linux)
Jeśli naprawdę potrzebujesz prawdziwego Linuxa:
```powershell
wsl --install
# Pełny Ubuntu w Windows!
```

## 📝 Uwagi

### ⚠️ Dlaczego nie `rm -rf`?

PowerShell ma konflikt parametrów (`-f` = `-Force` lub `-Filter`), więc użyj:

**Opcja 1: Szybki alias `rr`** (rekomendowane)
```powershell
rr directory/       # Jak rm -rf w Linux
rr file1 file2      # Usuwa wiele plików/katalogów
```

**Opcja 2: Pełne nazwy parametrów**
```powershell
rm -Recurse -Force directory/
cp -Recurse source/ dest/
mv -Force oldname newname
```

### mkdir -p
Działa! PowerShell automatycznie tworzy rekurencyjnie:
```powershell
mkdir -p path/to/deep/dir  # Zadziała!
```

### touch
Tworzy nowe pliki i aktualizuje timestamp istniejących:
```powershell
touch file.txt           # Tworzy plik
touch existing.txt       # Aktualizuje czas modyfikacji
```

### Różnice PowerShell vs Bash
- `$env:PATH` zamiast `$PATH`
- `Get-ChildItem` zamiast `ls` (ale masz alias)
- `Select-String` zamiast `grep` (ale masz alias)
- Pipe przekazuje obiekty, nie tekst (potężniejsze!)
- Parametry pełne zamiast krótkich flag (`-Recurse` zamiast `-r`)

## 🎯 Rekomendacja

Dla ciebie najlepsze będzie:
1. **Zostań przy swoim profilu** - masz już 90% tego co potrzeba
2. **Zainstaluj Scoop** - będziesz mógł łatwo instalować narzędzia
3. **Dodaj `bat` i `eza`** - nowoczesne zamienniki cat i ls
4. **Użyj WSL tylko jeśli musisz** - dla większości zadań ten profil wystarczy

Twój profil jest już bardzo "zlinuxowany"! 🐧
