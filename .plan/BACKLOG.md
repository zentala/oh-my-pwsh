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
