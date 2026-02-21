# /python-blueprint:audit

Analyze a Python project's current quality configuration and report gaps against the methodology.

**This skill is read-only — it does not modify any files.**

## Context Files

Read these files from the plugin before starting:

- `skills/setup/methodology.md` — the 8 quality dimensions (roles) to audit against
- `skills/setup/analysis-checklist.md` — what to check in the target codebase

## Workflow

### 1. Analyze Current State

Follow the same analysis steps as the setup skill (Phase 1 of `skills/setup/SKILL.md`):
- Detect package manager, Python version, project structure, framework
- Inventory existing tool configurations in `pyproject.toml`
- Check for existing hooks in `.claude/settings.json`
- Check for CI pipeline
- Check for pre-commit configuration

### 2. Compare Against Methodology

For each of the 8 quality dimensions from `methodology.md`:

1. **Testing & Coverage** — Is pytest configured? Is coverage measured? What's the threshold?
2. **Linting & Formatting** — Is ruff configured? Which rule sets? Is formatting enforced?
3. **Type Safety** — Is pyright/mypy/ty configured? What mode?
4. **Security Analysis** — Is bandit/semgrep configured?
5. **Code Complexity** — Is xenon configured? What thresholds?
6. **Dead Code & Modernization** — Is vulture/refurb configured?
7. **Documentation** — Is interrogate configured? What threshold?
8. **Architecture** — Is import-linter/deptry configured?

### 3. Check Hook Coverage

Verify Claude Code hooks are configured:
- SessionStart → dependency hygiene (deptry)
- PostToolUse (Edit|Write) → per-edit auto-fix (ruff, codespell)
- Stop → quality gate (all checks)
- Stop → auto-commit (optional)

### 4. Check CI Coverage

Verify CI pipeline covers at minimum:
- test job (pytest + coverage)
- lint job (ruff)
- typecheck job (pyright)
- security job (bandit)
- deadcode job (vulture)

### 5. Report

Present findings in a structured format:

```
## Audit Results

### Dimension Coverage
| Dimension | Status | Tools | Notes |
|-----------|--------|-------|-------|
| Testing & Coverage | Configured | pytest, pytest-cov | Coverage at 65%, below 80% recommendation |
| Linting & Formatting | Configured | ruff | Missing SIM, UP rule sets |
| Type Safety | Partial | pyright only | mypy and ty not configured |
| Security Analysis | Missing | — | No security tooling configured |
| Code Complexity | Missing | — | No complexity limits enforced |
| Dead Code | Missing | — | No dead code detection |
| Documentation | Missing | — | No docstring coverage enforcement |
| Architecture | Missing | — | No import boundaries or dependency hygiene |

### Hook Coverage
- [x] PostToolUse (per-edit fix)
- [x] Stop (quality gate)
- [ ] Stop (auto-commit) — not configured
- [ ] SessionStart (deptry) — not configured

### CI Coverage
- [x] test
- [x] lint
- [ ] typecheck — missing
- [ ] security — missing
- [ ] deadcode — missing

### Recommendations
1. Run `/python-blueprint:setup` to configure missing dimensions
2. Add mypy and ty for comprehensive type safety
3. Raise ruff rule coverage (add UP, SIM)
4. Consider raising coverage threshold from 65% to 80%
```

## Important Notes

- This skill only reads and reports — it never modifies files
- Compare against methodology defaults but note where project-specific thresholds may be appropriate
- Flag deprecated tools (e.g., black instead of ruff format, flake8 instead of ruff)
- Report both missing dimensions and misconfigured existing tools
