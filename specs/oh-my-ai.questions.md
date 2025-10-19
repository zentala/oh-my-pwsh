# oh-my-ai v0.0.1 - Questions for Specification

> **Status**: Draft - Awaiting answers
> **Date**: 2025-10-19
> **Team**: Business Analyst, Solution Architect, DevEx/UX Engineer

This document contains critical questions that need answers before writing the formal specification for oh-my-ai v0.0.1.

---

## 🎯 Business Analyst - Model Biznesowy i Wartość

### 1. Kim jest użytkownik docelowy?

Z opisu wynika "power users, often ex-Linux users" - czy to jedyna grupa?

**Pytania**:
- Jakie mają poziomy doświadczenia z PowerShell? (początkujący migrujący z Linuxa vs zaawansowani)
- Czy to narzędzie osobiste (solo dev) czy może być używane w zespołach?
- Czy targetujemy konkretne role? (DevOps, SysAdmin, Full-Stack Dev)

**Odpowiedź**:
```
[TODO]
```

---

### 2. Jaka jest główna wartość biznesowa?

Z rozmowy wynika kilka use case'ów:
- Pomoc w migracji z Linux → Windows PowerShell
- Odkrywanie ekosystemu PowerShell apps
- Asystent przy pisaniu komend/skryptów

**Pytanie**: Która z tych wartości jest NAJWAŻNIEJSZA? Co stanowi "killer feature"?

**Odpowiedź**:
```
[TODO]
```

---

### 3. Konkurencja i różnicowanie

W rozmowie wymieniono: AIShell (Microsoft), PSAI, ShellGPT, Copilot CLI.

**Pytanie**: Dlaczego użytkownik miałby wybrać `oh-my-ai` zamiast tych rozwiązań? Co nas wyróżnia?

**Odpowiedź**:
```
[TODO]
```

---

## 🏗️ Solution Architect - Architektura i Integracja

### 4. Strategia integracji z PSAI

Zdecydowałeś się na PSAI jako backend.

**Pytania**:
- Czy oh-my-ai to wrapper/fasada na PSAI czy rozszerzenie?
- Co się dzieje gdy PSAI się zmieni/przestanie być utrzymywany?
- Czy chcesz abstrakcję pozwalającą podmienić PSAI na inny backend w przyszłości?

**Odpowiedź**:
```
[TODO]
```

---

### 5. Zarządzanie stanem i konfiguracją

Struktura plików:
```
~/.ai-config.json - konfiguracja
~/.ai-session.json - sesja?
./ai-scripts/ - generowane skrypty
```

**Pytania**:
- Gdzie zapisywać historię konwersacji z AI?
- Jak długo cachować context (envContext)?
- Czy user może mieć różne profile (work/personal)?
- Czy synchronizować konfigurację między maszynami (git)?

**Odpowiedź**:
```
[TODO]
```

---

### 6. Model promptów

```json
"promptTemplates": {
  "default": "...",
  "history": "...",
  "error": "...",
  "interactive": "..."
}
```

**Pytania**:
- Czy user może edytować te prompty? (/prompt edit default)
- Czy mamy wersjonowanie promptów?
- Czy budujemy bibliotekę community promptów?

**Odpowiedź**:
```
[TODO]
```

---

### 7. Multi-provider strategy

Wspierasz OpenAI i Ollama.

**Pytania**:
- Czy planujemy Anthropic (Claude)?
- Czy user może mieć jednocześnie kilku providerów i przełączać w locie?
- Jak obsłużyć różnice w API (streaming, function calling)?
- Budget control - jak monitorować koszty API?

**Odpowiedź**:
```
[TODO]
```

---

## 💎 DevEx/UX Engineer - Doświadczenie Użytkownika

### 8. Onboarding nowego użytkownika

```
user wpisuje `/` → auto-setup wizard
```

**Pytania**:
- Czy pokazujemy "interactive tutorial" po pierwszym setupie?
- Jak user dowiaduje się o nowych features? (changelog, /news?)
- Czy mamy przykładowe use cases do wypróbowania?

**Odpowiedź**:
```
[TODO]
```

---

### 9. Feedback loop przy wykonywaniu komend

```
/next → sugestia → [Y/n] → execute
```

**Pytania**:
- Co się dzieje po wykonaniu? Czy AI widzi output?
- Czy user może poprawić sugestię przed wykonaniem? (/edit)
- Jak pokazywać długie outputy? (paginacja, less)
- Czy logujemy success/fail do uczenia się z błędów?

**Odpowiedź**:
```
[TODO]
```

---

### 10. Discovery i autouzupełnianie

Planujesz `Register-ArgumentCompleter` dla:
```
/a<Tab> → /agent
/agent <Tab> → lista modeli
```

**Pytania**:
- Czy pokazujemy inline hints (jak w Fish shell)?
- Czy autouzupełnianie działa dla argumentów promptów? (/ how to<Tab>)
- Jak wizualnie odróżnić AI suggestions od zwykłych komend?

**Odpowiedź**:
```
[TODO]
```

---

### 11. Error handling i graceful degradation

Zgodnie z filozofią oh-my-pwsh: "zero-error philosophy, graceful degradation"

**Pytania**:
- Co się dzieje gdy API nie odpowiada? (fallback? cache?)
- Gdy Ollama nie działa a user nie ma klucza OpenAI?
- Jak informować o błędach bez przerywania flow? (yellow warning vs red error)

**Odpowiedź**:
```
[TODO]
```

---

### 12. Safety i Security

AI może generować potencjalnie niebezpieczne komendy.

**Pytania**:
- Czy mamy blacklist komend (rm -rf, format)?
- Czy pokazujemy "dry-run" preview przed wykonaniem?
- Jak obsłużyć komendy wymagające sudo/admin?
- Czy zapisujemy wszystkie AI-generated commands do audytu?

**Odpowiedź**:
```
[TODO]
```

---

### 13. Personalizacja i context awareness

```json
"envContext": {
  "os": "Windows 11",
  "terminal": "Windows Terminal",
  "language": "pl-PL"
}
```

**Pytania**:
- Czy AI powinno uczyć się z historii usera? (fine-tuning/RAG)
- Czy tracked git repo → AI ma więcej contextu o projekcie?
- Czy AI wie o zainstalowanych narzędziach (bat, eza, fzf)?
- Jak często odświeżać envContext?

**Odpowiedź**:
```
[TODO]
```

---

## 📊 Priorytety i Scope v0.0.1

### 14. MVP vs Full Vision

Z rozmowy wynika bardzo dużo features.

**Pytanie**: Co MUSI być w v0.0.1 (MVP) a co może poczekać?

Proponowana kategoryzacja:
- **P0 (Must Have)**: /, /setup, basic AI queries z PSAI
- **P1 (Should Have)**: //, /agent, /config, error analysis
- **P2 (Nice to Have)**: /next, /edit, /script
- **P3 (Future)**: autonomous agent, learning from history

**Czy się zgadzasz z tym podziałem?**

**Odpowiedź**:
```
[TODO]
```

---

## 🎬 Następne kroki

Po uzyskaniu odpowiedzi na te pytania, przygotujemy:

1. **Formalną specyfikację v0.0.1** z:
   - User personas
   - User stories z acceptance criteria
   - Architecture Decision Records
   - UX flows (text-based mockups)
   - Technical specifications

2. **Task breakdown** do ./todo/

3. **Test scenarios** dla każdego user story

---

## 📝 Notatki

**Related files**:
- [./oh-my-ai.md](./oh-my-ai.md) - Original conversation with ChatGPT
- (future) ./oh-my-ai-v0.0.1.md - Formal specification

**Status tracking**:
- Questions created: 2025-10-19
- Answers provided: [TODO]
- Specification written: [TODO]
