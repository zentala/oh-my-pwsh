# Backlog — oh-my-pwsh

Znalezione błędy i zadania, do triażu.

- [ ] **`themes/quick-term.omp.json` nie istnieje** — `profile.ps1` odwołuje się do
  motywu, którego nie ma w repo, więc `oh-my-posh` od zawsze startuje z motywem
  domyślnym i nikt tego nie widzi, bo jest `try`/`Test-Path` bez komunikatu.
  Znalezione przy cache'owaniu skryptu init (E001, 2026-08-26). Albo dodać motyw,
  albo usunąć odwołanie. (Importance: Medium, Points: 2)
- [ ] **`Get-ToolAvailability` kosztuje ~120 ms przy trafieniu w cache** — to głównie
  JIT `ConvertFrom-Json` przy pierwszym użyciu w procesie. Zmierzone przy E001.
  Do sprawdzenia, czy własny mikroparser albo `[System.Text.Json]` jest tańszy.
  (Importance: Low, Points: 3)
- [ ] **Policzyć baner `oh-my-stats` równolegle z inicjalizacją `oh-my-posh`** — dziś
  profil robi wszystko po kolei w jednym wątku: ~470 ms na `Invoke-Expression` skryptu
  init oh-my-posh (JIT dużego wygenerowanego skryptu, czysty CPU) i ~280 ms na baner.
  Init oh-my-posh MUSI zostać w głównym runspace (definiuje `prompt`, ustawia
  `$env:POSH_*`, wpina PSReadLine) — ale **zbieranie danych** do banera to czysty odczyt
  (CIM, `Get-Process`, `DriveInfo`) i może pójść na drugi wątek: `Start-ThreadJob` na
  początku `profile.ps1`, `Receive-Job -Wait` tuż przed rysowaniem. Kolejność wydruku się
  nie psuje, bo punkt oczekiwania jest na końcu profilu.
  Haczyk, który trzeba zmierzyć przed obietnicą: nowy runspace **nie dziedziczy**
  załadowanych modułów, więc thread-job musi sam zrobić `Import-Module oh-my-stats`, a
  ten import jest sporą częścią tych 280 ms; sam `Start-ThreadJob` przy pierwszym użyciu
  kosztuje kilkadziesiąt ms. Realny zysk: pewnie 150–250 ms, ale dopiero po pomiarze —
  nie zakładać go z góry. Pomysł Pawła, 2026-08-26. (Importance: Medium, Points: 5)
