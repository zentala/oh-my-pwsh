# JOURNAL — E001 start profilu

## Session 2026-08-26

- **Goal**: wdrożyć `HANDOFF.md` (start profilu 4,2 s → < 800 ms), przy czym `ccblocks`
  wyrzucić całkiem — nie tylko zdjąć ze ścieżki krytycznej.
- **Done**:
  - T1 — `ccblocks` usunięty z repo wraz ze wszystkimi wzmiankami, `cc/main.ps1`
    234 → 64 linie; `Get-ScheduledTask` (538–1167 ms) zniknął ze startu (`1542ce9`).
  - T2 — `Show-SystemStats` 1458–1763 ms → ~280 ms (`4bd372a`, `830b5e8` w oh-my-stats):
    projekcja właściwości CIM, `Win32_PerfRawData_PerfOS_Processor` zamiast
    `Win32_Processor.LoadPercentage` (~1050 ms), `[System.IO.DriveInfo]` zamiast
    `Get-PSDrive C` (~70 ms), jeden `Get-Process` zamiast dwóch, okno próbki 100 → 50 ms.
  - T3 — N linii `Write-InstallHint` → jedna linia `missing: …  ->  winget install …`;
    ID paczek sprawdzone `winget show --id <id> --exact`, nie zgadnięte (scoop nie jest
    na tej maszynie zainstalowany).
  - T4 — cache narzędzi odświeża się w tle (`Start-ProfileCacheRefresh`, lock, zapis
    atomowy, log błędu dla procesu, którego nikt nie ogląda); `$_ProfileCacheFresh` ma
    trzy stany: `cached`/`$false`, `refreshing`/`$null`, `uncached`/`$true`.
  - Poza planem — cache skryptu init `oh-my-posh` (~350 ms na każdy shell), z podmianą
    `POSH_SESSION_ID` i sprawdzeniem, czy `init.<hash>.ps1` nadal istnieje (`9d887ca`).
  - Wynik: 4,2 s → ~990 ms w najlepszym przebiegu.
- **Decisions**:
  - **Nie** cache'uję wyrenderowanego banera z krótkim TTL, choć handoff to dopuszczał:
    baner pokazuje RAM i obciążenie CPU *teraz*, odgrzewany kłamałby nieodróżnialnie od
    świeżego. To ta sama cicha nieprawda, przed którą chronią stany `refreshing`/`uncached`.
  - Kryterium `< 800 ms` **nie jest spełnione** i zostało to zaraportowane wprost zamiast
    domknięte wyłączeniem banera. Dźwignia, gdyby Paweł chciał: `$global:OhMyPwsh_EnableStats = $false` (~700 ms).
- **Findings this session**: 3 → `.plan/BACKLOG.md` (brakujący `themes/quick-term.omp.json`,
  `Get-ToolAvailability` ~120 ms na JIT `ConvertFrom-Json`, pomysł Pawła na policzenie
  banera w `Start-ThreadJob` równolegle z JIT-em init oh-my-posh).
- **Next**: zmierzyć wariant z `Start-ThreadJob` (Medium, 5 pkt) — z zastrzeżeniem, że nowy
  runspace nie dziedziczy modułów, więc import `oh-my-stats` płaci się drugi raz.
- **Raport**: `.plan/reports/2026-08-26-start-profilu-wynik.md`
