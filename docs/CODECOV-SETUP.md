# Codecov Setup Guide (Optional - Future Reference)

**Status:** Not currently used
**Reason:** Project has 1 developer, local coverage sufficient

This guide is preserved for future reference if the project grows and external coverage reporting becomes valuable.

---

## Why Not Using Codecov Now?

For a single-developer project:
- ✅ Local HTML coverage reports are sufficient
- ✅ No need for PR coverage comments (you see it locally)
- ✅ GitHub Actions can display coverage in logs
- ✅ Saves setup time and external dependencies

**When to reconsider:**
- Multiple active contributors
- Need for coverage trends over time
- Want PR-based coverage diff comments
- Public repo with community contributions

---

## Setup Instructions (If Needed Later)

### 1. Create Codecov Account

1. Go to https://codecov.io
2. Sign up with GitHub account
3. Grant access to `pwsh-profile` repository

### 2. Get Upload Token

1. Navigate to repository settings in Codecov
2. Copy the `CODECOV_TOKEN`
3. Add to GitHub repository secrets:
   - Go to: https://github.com/zentala/pwsh-profile/settings/secrets/actions
   - Click "New repository secret"
   - Name: `CODECOV_TOKEN`
   - Value: [paste token]

### 3. Update GitHub Actions Workflow

Add to `.github/workflows/tests.yml`:

```yaml
- name: Upload coverage to Codecov
  if: matrix.os == 'windows-latest' && matrix.powershell == '7.4'
  uses: codecov/codecov-action@v3
  with:
    token: ${{ secrets.CODECOV_TOKEN }}
    files: ./tests/Coverage/coverage.xml
    flags: unittests
    name: codecov-umbrella
    fail_ci_if_error: false
```

### 4. Add Badge to README

```markdown
[![codecov](https://codecov.io/gh/zentala/pwsh-profile/branch/main/graph/badge.svg)](https://codecov.io/gh/zentala/pwsh-profile)
```

### 5. Configure Codecov Behavior

Create `codecov.yml` in repository root:

```yaml
coverage:
  status:
    project:
      default:
        target: 75%
        threshold: 2%
    patch:
      default:
        target: 80%

comment:
  layout: "reach,diff,flags,tree"
  behavior: default
  require_changes: false

ignore:
  - "tests/**"
  - "**/*.Tests.ps1"
```

---

## Alternative: GitHub Actions Only

**Recommended approach for now:**

Display coverage directly in GitHub Actions logs:

```yaml
- name: Display Coverage Summary
  run: |
    $coverage = [xml](Get-Content tests/Coverage/coverage.xml)
    $lineRate = $coverage.coverage.LineRate
    $percent = [math]::Round($lineRate * 100, 2)
    Write-Host "📊 Code Coverage: $percent%" -ForegroundColor Cyan
```

Store coverage as artifact:

```yaml
- name: Upload Coverage Report
  uses: actions/upload-artifact@v3
  with:
    name: coverage-report
    path: tests/Coverage/
```

---

## Cost Comparison

| Solution | Cost | Setup Time | Features |
|----------|------|------------|----------|
| **Local only** | Free | 0 min | Basic coverage, HTML reports |
| **GH Actions** | Free | 15 min | Coverage in logs, artifacts |
| **Codecov** | Free (public repos) | 30 min | Trends, badges, PR comments |

---

## Conclusion

**For oh-my-pwsh:**
- Use local coverage reports (`./scripts/Show-Coverage.ps1`)
- Display coverage in GitHub Actions logs
- Store coverage as artifacts in CI
- Revisit Codecov if project scales

---

## Related

- [TESTING-STRATEGY.md](./TESTING-STRATEGY.md) - Overall testing strategy
- [ADR-003](../adr/003-coverage-targets.md) - Coverage targets decision
- [Task 005](../todo/005-testing-infrastructure.md) - Testing infrastructure implementation
