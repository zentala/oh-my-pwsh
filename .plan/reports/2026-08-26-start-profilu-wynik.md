# E001 — start profilu: wynik wdrożenia

## TLDR

Cztery zadania z `HANDOFF.md` są wdrożone. Koszt profilu spadł z ~4,2 s
(baseline z handoffu) do **~1,0 s w najlepszym pomiarze i ~1,3–1,6 s przy
bieżącym obciążeniu maszyny**. Kryterium akceptacji `< 800 ms` **nie jest
spełnione** i nie da się go spełnić bez wycięcia banera `oh-my-stats` albo
promptu `oh-my-posh` — te dwie rzeczy to razem ~750 ms i obie widzi
użytkownik. Testy: oh-my-stats 68/0, oh-my-pwsh 297 passed / 16 failed,
czyli dokładnie baseline sprzed zmian (te 16 to brakujący moduł
`PwshSpectreConsole`, nie regresja).

## Co zostało zrobione

| Zadanie | Stan | Efekt |
|---|---|---|
| T1 — `Get-ScheduledTask` poza ścieżkę krytyczną | zrobione (`1542ce9`) | `ccblocks` usunięty całkiem, `modules/cc/main.ps1` 234 → 64 linie, dot-source 538–1167 ms → 93 ms |
| T2 — `Show-SystemStats` | zrobione (oh-my-stats `4bd372a` + ten commit) | 1458–1763 ms → ~280 ms |
| T3 — jedna linia zamiast listy braków | zrobione | jedna linia `missing: …  ->  winget install …`, ID sprawdzone przez `winget show --exact` |
| T4 — cache odświeża się w tle | zrobione (`4ed72b9` + ten commit) | start nigdy nie czeka na skan; trzy stany zamiast dwóch |

Poza handoffem, bo to był największy pozostały koszt: **cache skryptu
inicjalizacyjnego `oh-my-posh`** (`Get-OhMyPoshInitScript`). Samo
`oh-my-posh init pwsh` to odpalenie procesu za ~350 ms przy każdym starcie
shella, a jego wynik zmienia się tylko przy zmianie motywu albo binarki.

## Pomiary

`pwsh -Command exit` minus `pwsh -NoProfile -Command exit`, mediana z 7–15
przebiegów. Maszyna była przez cały czas pomiaru na ~97% RAM i ~600
procesach, więc rozrzut jest duży — podaję też najlepszy przebieg, bo on
pokazuje koszt samego kodu, a nie kolejki do dysku.

| Etap | Koszt |
|---|---|
| baseline z handoffu | ~4200 ms |
| po T1 (ccblocks) + T2 (źródło oh-my-stats) | ~1420 ms |
| po cache init `oh-my-posh` | ~1010 ms |
| po cięciach w oh-my-stats (dysk, procesy, próbka CPU) | **~990 ms najlepszy przebieg, 1300–1600 ms przy obciążeniu** |

Co zostało w środku, zmierzone osobno:

| Blok | Koszt | Da się ściąć? |
|---|---|---|
| `Invoke-Expression` skryptu init `oh-my-posh` | ~470 ms | nie — to kod oh-my-posh i kompilacja jego skryptu; zostaje tylko wyłączenie promptu |
| baner `oh-my-stats` (import + render) | ~280 ms | tylko przez wyłączenie banera (`$global:OhMyPwsh_EnableStats = $false`) albo pokazywanie starych liczb |
| `Get-ToolAvailability` przy trafieniu w cache | ~120 ms | w większości JIT `ConvertFrom-Json` |
| dot-source pozostałych modułów | ~150 ms | drobne |

### Co dokładnie ścięte w oh-my-stats (ten commit)

| Zmiana | Było | Jest |
|---|---|---|
| dysk przez `[System.IO.DriveInfo]` zamiast `Get-PSDrive C` | 69 ms | ~0 ms |
| jeden `Get-Process`, liczony dwa razy | 2 × ~30 ms | ~30 ms |
| okno próbkowania licznika CPU 100 → 50 ms | 141 ms | ~90 ms |

## Kryterium `< 800 ms` — dlaczego nie

Prompt `oh-my-posh` (~470 ms) i baner (~280 ms) to razem ~750 ms z ~990 ms.
Żeby zejść poniżej 800 ms, trzeba wyłączyć jedno z nich. Oba są tym, co
użytkownik widzi po starcie shella, więc **nie wyłączam ich sam** — flaga
`$global:OhMyPwsh_EnableStats = $false` w `config.ps1` już istnieje i zbija
koszt do ~700 ms, jeśli baner ma pójść.

Nie zdecydowałem się na cache wyrenderowanego banera z krótkim TTL, choć
handoff to dopuszczał: baner pokazuje RAM, liczbę procesów i obciążenie CPU
*teraz*. Odgrzewany przez 20–30 s wygląda identycznie jak świeży i kłamie o
stanie maszyny — to dokładnie ten rodzaj cichej nieprawdy, której reszta tej
roboty (stany `refreshing`/`uncached`) ma unikać.

## Stany cache'u narzędzi (T4)

| Stan | `Fresh` | Co widzi użytkownik |
|---|---|---|
| `cached` | `$false` | nic — cache ważny |
| `refreshing` | `$null` | `tools: checking in background - result applies from the next shell` |
| `uncached` | `$true` | `tools: cache could not be written - every shell start pays for a full scan` |

Skrypt tła zapisuje `~/.oh-my-pwsh-cache.error`, gdy się wywróci. To nie
ozdoba — wyłapał własny błąd tego skryptu (złamana ścieżka do
`nerd-fonts.ps1`), którego inaczej nie byłoby widać wcale, bo proces jest
odłączony i nikt nie czyta jego wyjścia.

## Zweryfikowane na żywo, nie z kodu

- zimny start (brak cache): shell pokazuje `checking in background`, **nie**
  listę braków; w tle powstaje `~/.oh-my-pwsh-cache.json` z kluczem
  `NerdFonts`; `.error` nie powstaje;
- ciepły start: liczby z cache, jedna linia braków;
- `prompt` renderuje się kolorami `oh-my-posh` po podmianie na wersję z
  cache'u;
- `POSH_SESSION_ID` jest inny przy każdym wywołaniu mimo cache'u
  (sprawdzone dwoma kolejnymi wywołaniami) — inaczej wszystkie terminale
  dzieliłyby jeden identyfikator sesji oh-my-posh.

## Braki narzędzi to prawda, nie fałszywy alarm

Linia `missing: fzf, zoxide, fnm, bat, eza, rg, fd, delta` na mATX jest
prawdziwa — sprawdzone `Get-Command` w shellu bez profilu: żadnego z tych
ośmiu nie ma w PATH. Zainstalowany jest tylko `oh-my-posh`. Nerd Fonts też
naprawdę nie ma w rejestrze fontów (`Count = 0`).

## GAPS — czego nie sprawdziłem

- **Pomiary robione na mocno obciążonej maszynie** (97% RAM, ~600 procesów,
  22 terminale). Mediana z 15 przebiegów potrafiła skoczyć o 500 ms między
  seriami. Liczba „~990 ms" to najlepszy przebieg, nie średnia z czystej
  maszyny — na spokojnym systemie może być niżej, ale tego nie zmierzyłem.
- **Nie sprawdziłem, co robi cache init `oh-my-posh` po realnym upgrade
  binarki.** Klucz cache'u zawiera ścieżkę i czas modyfikacji exe, a
  dodatkowo sprawdzam, czy plik, do którego skrypt się odwołuje, nadal
  istnieje. To dwa rozsądne zabezpieczenia, ale prawdziwego upgrade'u
  oh-my-posh w tej sesji nie było.
- **`themes/quick-term.omp.json` nie istnieje** w repo, więc profil od
  zawsze używa domyślnego motywu oh-my-posh. Nie ruszałem tego — osobna
  sprawa, wpisana do backlogu.
- Nie mierzyłem kosztu pierwszego renderu promptu (`prompt` po starcie) —
  jednorazowo widziałem ~1,1 s, ale to było w procesie bez rozgrzanego JIT
  i nie wchodzi w mierzony koszt profilu.
