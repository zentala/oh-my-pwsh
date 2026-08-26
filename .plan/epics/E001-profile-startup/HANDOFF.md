# E001 — Profile startup: 4,2 s → cel poniżej 800 ms

## TLDR

Zmierzono, co realnie zjada 4,2 s startu PowerShell 7. Dwa bloki odpowiadają
za ~55-60% całości: `Show-SystemStats` z `oh-my-stats` (1,4-1,7 s — redundantne
`Get-CimInstance`) i sprawdzanie starego zadania Task Schedulera w `cc/main.ps1`
(0,55-0,7 s, uruchamiane bezwarunkowo na KAŻDYM starcie mimo że migracja z
`ccblocks` już dawno się odbyła). Reszta to rozproszony koszt modułów (PSReadLine,
Terminal-Icons, posh-git, oh-my-posh init, itd.), każdy < 130 ms z osobna.
Komunikat o brakujących narzędziach (bat/eza/rg/fd/delta/fzf/zoxide/fnm) już DZIŚ
jest ukryty za cache'em z TTL 24h (`_ProfileCacheFresh`) — pokazuje się tylko
w dniu odświeżenia cache'u, ale wtedy leci jako 5-9 osobnych linii, część z nich
rekomenduje `scoop install X` na maszynie, gdzie **scoop nie jest zainstalowany**
(tylko winget). Ta sesja nie wdrożyła żadnej zmiany zachowania startu — tylko
zmierzyła i zaplanowała. Cel: < 800 ms.

## Model mentalny — jak się to w ogóle ładuje

1. `~/Documents/PowerShell/Microsoft.PowerShell_profile.ps1` (profil PS7,
   **nie w tym repo**) robi `Set-Location ~/code`, potem
   `. C:\code\oh-my-pwsh\profile.ps1`, potem import Chocolatey (Chocolatey
   nie jest zainstalowany na tej maszynie → `Test-Path` fails fast, koszt ~0).
2. `profile.ps1` (ten plik) ustawia UTF-8, ładuje `config.ps1`, potem w
   ŚCIŚLE tej kolejności: `settings/icons.ps1` → `modules/status-output.ps1`
   → `modules/logger.ps1` → `modules/profile-cache.ps1` (kolejność jest
   wymuszona komentarzami w pliku — logger potrzebuje icons+status-output,
   inne moduły potrzebują `Write-InstallHint`/`Write-ModuleStatus` z loggera).
3. `Get-ToolAvailability` (z `profile-cache.ps1`) czyta
   `~/.oh-my-pwsh-cache.json` — jeśli świeży (< `OhMyPwsh_StatusCacheHours`,
   domyślnie 24h), zwraca go i ustawia `$global:_ProfileCacheFresh = $false`;
   jeśli stary/brak, **synchronicznie** odpala `Update-ProfileCache` (9×
   `Get-Command`, 4× `Get-Module -ListAvailable` — tanie, ~50-100ms łącznie)
   i ustawia `Fresh = $true`.
4. `$_ProfileCacheFresh` steruje, czy w ogóle drukują się linie
   `Write-ModuleStatus`/`Write-ToolStatus`/`Write-InstallHint` — **to już
   działa poprawnie jako wyciszenie na co dzień**, zobacz "Co już jest OK"
   niżej. Nie myl tego z problemem samego czasu ładowania.
5. Potem `oh-my-stats` (Import-Module + `Show-SystemStats`), moduły
   PowerShell (Terminal-Icons, posh-git, PSFzf, zoxide init, fnm env), potem
   `modules/*.ps1` w kolejności z pliku (proxy-guard → environment →
   psreadline → functions → git-helpers → linux-compat → enhanced-tools →
   help-system → nerd-fonts → power-tools → **cc/main.ps1** →
   ssh-sleep-blocker), na końcu `oh-my-posh init`.
6. `cc/main.ps1` przy DOT-SOURCE (nie przy wywołaniu `cc`!) uruchamia
   `_cc_migrate_from_ccblocks` na końcu pliku (linia 165), a potem dot-sourcuje
   `blocks.ps1` i `plan.ps1` (same definicje funkcji, tanie — 15,8 ms razem).

**Czego NIE ruszać bez powodu:** kolejność icons→status-output→logger→
profile-cache jest zamierzona (komentarze to mówią wprost). `$_ProfileAvailability`
/ `$_ProfileCacheFresh` to już istniejący, działający mechanizm cache'u —
zadanie nie polega na budowaniu go od zera, tylko na (a) przeniesieniu
odświeżania poza ścieżkę krytyczną i (b) skróceniu komunikatu do jednej linii,
gdy `Fresh = $true`.

## Pomiary (zmierzone, nie zgadywane)

Środowisko: `pwsh -File` z instrumentacją (`Measure-Command` per blok, ten sam
proces), plus pomiary izolowane (osobny `pwsh -NoProfile -File` per pytanie) dla
weryfikacji krzyżowej. Maszyna: mATX, PowerShell 7.6.5, cache `.oh-my-pwsh-cache.json`
ciepły (wiek ~10h, TTL 24h → `Fresh=$false` w tym przebiegu, więc install-hinty
NIE drukowały się w tym pomiarze — realny koszt w dniu odświeżenia cache'u jest
WYŻSZY o czas `Update-ProfileCache`, patrz GAPS).

| Blok | ms (measured) | % z ~3,7 s | Źródło pomiaru |
|---|---:|---:|---|
| **`Show-SystemStats` (oh-my-stats)** | **1458-1763** | **~40-48%** | izolowany `Measure-Command`, 2 przebiegi |
| **`cc/main.ps1` (dot-source, w tym `blocks.ps1`+`plan.ps1`)** | **538-1167** | **~15-32%** (szeroki rozrzut, patrz niżej) | izolowany, 2 przebiegi w tym samym procesie |
| … z czego `Get-ScheduledTask -TaskName ccblocks`| 564-685 | ~15-18% | izolowany, 2 przebiegi — **to jest cały koszt cc/main.ps1** |
| … z czego `blocks.ps1`+`plan.ps1` dot-source (same funkcje) | 15,8 | <1% | izolowany — zaniedbywalne |
| `modules/enhanced-tools.ps1` | 129 | ~3,5% | pierwszy przebieg (parse 163 linii) |
| `modules/psreadline.ps1` | 89 | ~2,4% | pierwszy przebieg |
| `modules/profile-cache.ps1` (dot-source, definicje) | 59 | ~1,6% | pierwszy przebieg |
| `Get-ToolAvailability` (odczyt cache) | 54 | ~1,5% | pierwszy przebieg |
| `modules/nerd-fonts.ps1` | 54 | ~1,5% | pierwszy przebieg |
| `modules/ssh-sleep-blocker/main.ps1` | 32 | <1% | pierwszy przebieg |
| `modules/linux-compat.ps1` | 31 | <1% | pierwszy przebieg |
| `modules/power-tools.ps1` | 30 | <1% | pierwszy przebieg |
| `modules/functions.ps1` | 25 | <1% | pierwszy przebieg |
| `modules/proxy-guard.ps1` | 24 | <1% | pierwszy przebieg |
| `config.ps1` | 23 | <1% | pierwszy przebieg |
| `modules/help-system.ps1` | 22 | <1% | pierwszy przebieg |
| `settings/icons.ps1` | 22 | <1% | pierwszy przebieg |
| `modules/status-output.ps1` | 20 | <1% | pierwszy przebieg |
| `modules/logger.ps1` | 19 | <1% | pierwszy przebieg |
| `modules/environment.ps1` | 17 | <1% | pierwszy przebieg |
| `modules/git-helpers.ps1` | 16 | <1% | pierwszy przebieg |
| `Import-Module oh-my-stats` (samo ładowanie modułu, bez `Show-SystemStats`) | 44 | ~1,2% | izolowany |
| `Import-Module Terminal-Icons` | 11 | <1% | pierwszy przebieg |
| `Import-Module posh-git` | 9 | <1% | pierwszy przebieg |
| `zoxide init` (tool niedostępny na tej maszynie → no-op) | 10 | <1% | pierwszy przebieg |
| `oh-my-posh init` | 10 | <1% | pierwszy przebieg |
| `fnm env` (tool niedostępny → no-op) | 8 | <1% | pierwszy przebieg |
| Chocolatey profile import (nieobecny → `Test-Path` fail-fast) | 8 | <1% | pierwszy przebieg |
| encoding setup (UTF-8) | 12 | <1% | pierwszy przebieg |
| **Referencja: `pwsh -NoProfile` sam host, zero profilu** | **220** | — | osobny proces, koszt STAŁY niezależny od profilu |
| **Referencja: pełny realny `$PROFILE` (`pwsh -Command exit`, cache ciepły)** | **3098** | — | osobny proces — najbliższy prawdziwemu UX |

**Winowajca — jednym zdaniem:** `Show-SystemStats` z osobnego repo
`oh-my-stats` (4-5× `Get-CimInstance`/`Get-Counter`, w tym DWA razy
`Win32_OperatingSystem` i DWA razy `Win32_Processor` — czysta duplikacja)
odpowiada za blisko połowę czasu startu; drugi w kolejności jest
bezwarunkowe `Get-ScheduledTask -TaskName ccblocks` w `cc/main.ps1`,
uruchamiane na każdym starcie mimo że służy jednorazowej migracji, która
już dawno się odbyła na tej maszynie.

## Co już jest OK — nie przerabiać od zera

- **Cache narzędzi już istnieje**: `modules/profile-cache.ps1`,
  `~/.oh-my-pwsh-cache.json`, TTL 24h (`$global:OhMyPwsh_StatusCacheHours`,
  domyślnie 24, konfigurowalne w `config.ps1` — dziś zakomentowane).
  `$_ProfileCacheFresh` już wycisza `Write-InstallHint`/`Write-ToolStatus`/
  `Write-ModuleStatus` na wszystkich zwykłych startach — hinty drukują się
  TYLKO w dniu, gdy cache wygasł. To znaczy, że problem "lista narzędzi na
  każdym starcie" zgłoszony przez Pawła prawdopodobnie dotyczy (a) dnia
  odświeżenia cache'u, gdzie i tak leci ściana tekstu, ORAZ/LUB (b) polecenia
  `profile-status`, które ZAWSZE pokazuje pełną listę (to zamierzone — to
  jest komenda on-demand, nie start shella). Task 3 niżej dotyczy TYLKO
  ścieżki startu shella, nie `profile-status`.
- Kolejność ładowania modułów jest przemyślana (komentarze w `profile.ps1`
  o zależnościach icons→status-output→logger).

## Zadania — plik po pliku

### T1 — Przenieś `Get-ScheduledTask` z `cc/main.ps1` poza ścieżkę krytyczną
**Plik:** `modules/cc/main.ps1`, funkcja `_cc_migrate_from_ccblocks` (linie
147-160), wywołanie na linii 165.
**Zmiana:** Migracja z `ccblocks` → `cc` jest jednorazowa. Zapisz marker po
udanej migracji (np. plik `$script:CcConfigDir\.migrated-from-ccblocks`) i
pomijaj CAŁĄ funkcję (łącznie z `Get-ScheduledTask`), jeśli marker istnieje
LUB jeśli `$oldDir` (`%APPDATA%\ccblocks`) w ogóle nie istnieje — dziś
`Get-ScheduledTask` odpala się BEZ WZGLĘDU na to, czy `$oldDir` istnieje.
Docelowy koszt tej ścieżki na starcie: ~1 `Test-Path` (< 1ms) zamiast
550-700ms.
**Test:** usuń `%APPDATA%\ccblocks` (jeśli istnieje, zbackupuj), sprawdź że
`cc blocks`/`cc plan` nadal działają; zmierz `Measure-Command { . modules\cc\main.ps1 }`
przed/po — cel < 20 ms.
**Punkty:** 2 (Small — jeden plik, jasna logika).

### T2 — Napraw/wynieś `Show-SystemStats` (oh-my-stats)
**Plik zewnętrzny:** `C:\code\oh-my-stats\pwsh\oh-my-stats.psm1` (osobne repo,
osobny właściciel bug-a — zgłoszone tam jako `.plan/BACKLOG.md`, patrz niżej).
**W TYM repo (`oh-my-pwsh`):** `profile.ps1` linie 100-120 (blok
"OH-MY-STATS — Display FIRST"). Dwie niezależne opcje, wybierz jedną:
  - **(a) Cache wynik `Show-SystemStats` z krótkim TTL** (np. 5 min — CPU/RAM
    się zmieniają, ale nie trzeba ich liczyć na każdym z wielu terminali
    otwieranych w ciągu minuty) w tym samym `~/.oh-my-pwsh-cache.json` albo
    osobnym pliku, i renderować z cache gdy świeży.
  - **(b) Async**: odpal `Show-SystemStats` jako `Start-ThreadJob` (moduł
    `Microsoft.PowerShell.ThreadJob`, potwierdzone dostępny w PS 7.6.5 bez
    dodatkowej instalacji) i wypisz wynik, gdy job się skończy — albo
    zrezygnuj z synchronicznego wypisania na starcie i zostaw tylko komendę
    on-demand (`profile-status`-owy odpowiednik dla staty systemowe).
  Rekomendacja: (a) jest prostsze i bezpieczniejsze (brak race condition
  na terminalu), ale NIE naprawia źródła (oh-my-stats nadal liczy 4-5 CIM
  calli za każdym odświeżeniem cache'u) — dlatego T2 idzie w parze z bugiem
  zgłoszonym w oh-my-stats (usunięcie duplikatów `Win32_OperatingSystem`/
  `Win32_Processor`, patrz `C:\code\oh-my-stats\.plan\BACKLOG.md`).
**Test:** `Measure-Command { Show-SystemStats }` przed/po; z cache (a) cel
< 20ms na trafienie cache'u, > 0 na miss ale nie blokuje renderowania promptu.
**Punkty:** 5 (Medium — dotyka dwóch repo, decyzja projektowa cache-vs-async).

### T3 — Jedna linia zamiast listy brakujących narzędzi + gotowy one-liner
**Pliki:** `modules/logger.ps1` (`Write-InstallHint`, linie 34-59+),
`modules/profile-cache.ps1` (`Get-ToolAvailability`/`Update-ProfileCache`),
wszystkie miejsca wołające `Write-InstallHint`/`Write-ToolStatus` na ścieżce
STARTU shella (nie `profile-status` — ta zostaje pełna, to on-demand):
`profile.ps1` linie 151, 171, 179, 229, 239; `modules/enhanced-tools.ps1`
linie 33, 66, 83, 104, 132; `modules/nerd-fonts.ps1` (hint Nerd Fonts).
**Zmiana:**
  1. Zamiast N wywołań `Write-InstallHint` (jedno per brakujące narzędzie),
     zbierz brakujące narzędzia do jednej listy w trakcie ładowania modułów
     (np. `$global:_MissingTools = [System.Collections.Generic.List[string]]::new()`,
     dopisuj `"$Tool ($Description)"` zamiast drukować od razu).
  2. Po zakończeniu ładowania wszystkich modułów (koniec `profile.ps1`,
     obok bloku "WELCOME MESSAGE"), jeśli `$_MissingTools.Count -gt 0` I
     `$_ProfileCacheFresh` (czyli dokładnie tak jak dziś — tylko w dniu
     odświeżenia), wypisz JEDNĄ linię:
     `narzędzia niezainstalowane: bat, eza, rg — rekomendowana instalacja:`
     a pod nią (albo w tej samej linii po dwukropku) gotowy do wklejenia
     one-liner **winget**, nie scoop — na tej maszynie (`mATX.lan`) `scoop`
     NIE jest zainstalowany (`Get-Command scoop` = false w cache'u), tylko
     `winget` (`C:\Users\zentala\AppData\Local\Microsoft\WindowsApps\winget.exe`).
     Zbuduj mapowanie narzędzie→winget-id (część już istnieje dla
     fzf/zoxide/fnm/oh-my-posh w `profile.ps1`/`profile-cache.ps1` jako
     `InstallCommand`; DOPISZ brakujące dla bat/eza/rg/fd/delta — dziś mają
     tylko `ScoopPackage`, potrzebują odpowiednik winget: `winget install
     sharkdp.bat eza-community.eza BurntSushi.ripgrep.MSVC sharkdp.fd
     dandavison.delta` — id zweryfikuj w `winget search`, nie zgaduj).
     Przykładowy format całej linii (jedna, kopiowalna):
     `narzędzia niezainstalowane: bat, eza, rg, fd, delta — winget install sharkdp.bat eza-community.eza BurntSushi.ripgrep.MSVC sharkdp.fd dandavison.delta`
  3. `profile-status` (`Show-ProfileStatus` w `profile-cache.ps1`) NIE
     zmienia się — zostaje pełna, wielolinijkowa, bo to komenda on-demand,
     nie coś co Paweł widzi bez pytania.
**Test:** tymczasowo ustaw fałszywy stary cache (`Timestamp` sprzed 25h),
odpal nowy shell, sprawdź że leci JEDNA linia z poprawnym, wklejalnym
poleceniem `winget`; sprawdź że `profile-status` nadal pokazuje pełną listę.
**Punkty:** 3 (Small feature — kilka plików, ale logika prosta:
zbieranie zamiast druku + jedno renderowanie na końcu).

### T4 — Cache się odświeża w tle, nigdy nie blokuje startu; brak wyniku = `unknown`, nie cisza
**Plik:** `modules/profile-cache.ps1`, `Get-ToolAvailability` (linie 145-160),
`profile.ps1` linia 91-92.
**Zmiana — reguła Pawła "cisza nigdy nie znaczy sukces" ma konkretne
zastosowanie tutaj:** dziś `Get-ToolAvailability` w scenariuszu zimnego/
wygasłego cache'u ROBI `Update-ProfileCache` SYNCHRONICZNIE (blokuje start
o ~50-100ms dla samych narzędzi — tanie, ale jeśli T2 doda tu też staty
systemowe, koszt rośnie). Docelowo:
  1. Jeśli cache jest świeży (< TTL) → użyj go, brak zmian.
  2. Jeśli cache jest przestarzały/brak → **użyj STAREJ wartości cache'u
     (jeśli plik istnieje, nawet wygasły) do renderowania TEGO startu**,
     jednocześnie odpal `Update-ProfileCache` w tle (`Start-ThreadJob` albo
     `Start-Job`, bez czekania) tak, żeby NASTĘPNY start miał świeże dane.
     Nigdy nie blokuj promptu na wynik.
  3. Jeśli plik cache'u W OGÓLE nie istnieje (pierwsze uruchomienie na tej
     maszynie) — nie ma żadnej "starej" wartości do pokazania. W tym
     wypadku **nie wolno milcząco założyć "wszystko zainstalowane"**: nie
     drukuj żadnego stwierdzającego komunikatu o narzędziach w ogóle tym
     razem (nie fałszywe "0 brakujących", nie pusta linia sugerująca
     sukces) — ewentualnie jedna neutralna linia typu
     `sprawdzanie narzędzi w tle — wynik przy następnym starcie`, i
     odpal `Update-ProfileCache` w tle jak w p.2. `$_ProfileCacheFresh`/
     `Fresh` powinno mieć trzeci stan (`$true`/`$false`/`$null`="unknown"),
     nie tylko bool — każde miejsce, które dziś czyta `$_ProfileCacheFresh`
     jako bool, trzeba przejrzeć (`profile.ps1` linie 151,171,179,229,239,
     `enhanced-tools.ps1` linia 13).
**Test:** usuń `~/.oh-my-pwsh-cache.json`, odpal nowy shell — MUSI pokazać
neutralny komunikat "sprawdzanie w tle", NIE "wszystko OK"; drugi start (po
tym jak background job dopisał cache) MUSI pokazać prawdziwy wynik.
**Punkty:** 5 (Medium — zmiana stanu z bool na trójstanowy, dotyka kilku
plików, wymaga przemyślenia race condition przy równoległym otwieraniu wielu
terminali naraz — dopisanie do tego samego pliku cache z kilku procesów
jednocześnie może się gubić; rozważ `Set-Content` z retry albo lock file
zgodnie z ogólną zasadą atomic-write z CLAUDE.md).

## Kryteria akceptacji

- Realny czas ładowania profilu (mierzony jak w tabeli, `pwsh -Command exit`
  minus baseline `pwsh -NoProfile`) spada z ~2,9 s do **< 800 ms** przy
  ciepłym cache'u.
- Żaden pojedynczy start shella nie czeka na `Get-ScheduledTask` ani na
  pełne odświeżenie stat systemowych — oba mogą się dziać w tle.
- Komunikat o brakujących narzędziach to jedna linia z gotowym poleceniem
  `winget install ...`, widoczna tylko wtedy, gdy naprawdę czegoś brakuje
  i cache jest świeży (bez zmiany istniejącego `profile-status`).
- Brak cache'u / cache w trakcie odświeżania w tle renderuje się jako
  wyraźny stan "sprawdzanie w tle", nigdy jako cichy sukces.

## Punkty razem

T1: 2 + T2: 5 + T3: 3 + T4: 5 = **15 pkt** (jedna fala, poniżej progu 40 pkt
z `rules/workflows.md` — nie trzeba dzielić na równoległych subagentów).

## GAPS — czego nie sprawdziłem

- **Pomiar robiony jednym przebiegiem instrumentowanego skryptu +
  kilkoma izolowanymi `Measure-Command`, nie 10+ powtórzeniami** — nie
  liczyłem odchylenia standardowego. Liczby dla drobnych bloków (< 100ms)
  mogą się różnić ±30-50% między uruchomieniami (JIT, dysk, obciążenie
  maszyny — RAM był na 91% w chwili pomiaru wg `oh-my-stats`, co samo w
  sobie mogło spowalniać wszystko).
- **Nie zmierzyłem kosztu `Update-ProfileCache` w dniu realnego wygaśnięcia
  cache'u w tym samym procesie co reszta profilu** — mój `measure-profile.ps1`
  miał błąd zakresu zmiennych (funkcje z dot-source w scriptblocku nie
  trafiły do global scope), przez co `Get-ToolAvailability`/
  `Test-NerdFontInstalled` rzuciły błąd w tym jednym przebiegu. Nie wpływa
  to na zmierzone liczby DLA INNYCH bloków (każdy mierzony niezależnie), ale
  oznacza, że nie mam bezpośredniego pomiaru "cold cache + Show-SystemStats +
  Get-ScheduledTask w jednym starcie" — sumowałem komponenty osobno.
  Szacunek: cold-cache dzień = warm-cache dzień (~2,9s) + ~50-100ms
  (Update-ProfileCache dla samych narzędzi, tanie) + ewentualnie koszt
  wielolinijkowych `Write-InstallHint` (pomijalny, to tylko `Write-Host`).
- **Nie sprawdziłem obecności `$PROFILE.AllUsersAllHosts` ani innych
  profili systemowych** (`$PROFILE.AllUsersCurrentHost` itd.) — sprawdziłem
  tylko `$PROFILE.CurrentUserCurrentHost`
  (`~/Documents/PowerShell/Microsoft.PowerShell_profile.ps1`), który jest
  jedynym miejscem dot-sourcującym `oh-my-pwsh`. Jeśli PowerShell 7 na tej
  maszynie ma dodatkowo ustawiony profil all-users (rzadkie, ale możliwe np.
  przez politykę grupową albo instalator), on ładowałby się PRZED tym i nie
  jest uwzględniony w pomiarach. Warto sprawdzić `$PROFILE | Format-List *`
  na starcie realnej sesji Pawła.
- **Nie zweryfikowałem dokładnych ID pakietów winget** dla bat/eza/rg/fd/delta
  podanych w T3 (`sharkdp.bat`, `eza-community.eza`,
  `BurntSushi.ripgrep.MSVC`, `sharkdp.fd`, `dandavison.delta`) — to moja
  najlepsza wiedza z pamięci, sesja implementująca T3 MUSI odpalić
  `winget search <narzędzie>` i potwierdzić realne ID przed wpisaniem ich
  do `Write-InstallHint`, żeby nie dać Pawłowi kopiowalnej komendy, która
  się wywali.
- **Nie zmierzyłem osobno kosztu `PSReadLine`/`Terminal-Icons`/`posh-git`
  jako "import modułu" per se** — moduły te są ładowane w ramach
  `modules/psreadline.ps1` (89ms zmierzone łącznie z resztą tego pliku) i
  bloku "LOAD POWERSHELL MODULES" w `profile.ps1` (Terminal-Icons 11ms,
  posh-git 9ms zmierzone osobno) — te dwie ostatnie liczby są wiarygodne,
  ale PSReadLine mógł już być załadowany przez sam hosta PS7 przed moim
  pomiarem (biblioteka wbudowana), więc 89ms mogło być zawyżone/zaniżone
  względem prawdziwego kosztu na czystym starcie.
- **Nie sprawdziłem, czy Paweł faktycznie widzi listę brakujących narzędzi
  NA KAŻDYM starcie, czy tylko okazjonalnie** — z analizy kodu wynika, że
  `$_ProfileCacheFresh` powinno to ograniczać do raz na `OhMyPwsh_StatusCacheHours`
  (24h domyślnie). Możliwe wytłumaczenia rozjazdu z jego obserwacją: (a)
  otwiera pierwszy terminal danego dnia i to jest dokładnie ten jeden start,
  który mu się rzuca w oczy i pamięta jako "zawsze"; (b) używa
  `profile-status` częściej niż mu się wydaje; (c) cache bywa kasowany/
  invalidowany przez coś, czego nie znalazłem (np. antywirus czyszczący
  `%USERPROFILE%`, albo różne wartości `$env:USERPROFILE` w różnych
  kontekstach uruchomienia). T3/T4 rozwiązują oba scenariusze niezależnie
  od przyczyny, więc nie blokowałem się na ustaleniu, który to jest.
- **Repo `C:\Users\zentala\code\oh-my-pwsh` (martwa kopia)** — potwierdzone
  martwe: starszy commit (2026-08-01 vs 2026-08-21 w `C:\code\oh-my-pwsh`),
  inny remote (`pwsh-profile.git` vs `oh-my-pwsh.git` — prawdopodobnie repo
  przemianowane na GitHub, ta kopia to stary klon sprzed zmiany nazwy), i
  żaden profil go nie dot-sourcuje. Nie usunąłem jej — to nie było w
  zakresie zadania, tylko decyzja "którą edytować".
