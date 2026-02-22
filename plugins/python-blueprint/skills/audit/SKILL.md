---
name: audit
description: Read-only gap analysis comparing a Python project's current quality setup against the 9-dimension methodology. Use when user says "audit quality", "check coverage gaps", "what's missing", or wants to see how their project measures up before running setup.
metadata:
  version: 0.3.0
  author: Ondrej (Ondra) Krajicek, me@ondrejkrajicek.com
---

# Audit

Read-only — does not modify any files.

## Context Files

Read these files from the plugin before starting:

- `skills/setup/methodology.md` — the 9 quality dimensions (roles) to audit against
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

For each of the 9 quality dimensions from `methodology.md`, check whether the role is filled by any tool:

1. **Testing & Coverage** — Is there a test runner? Is coverage measured? What's the threshold?
2. **Linting & Formatting** — Is there a linter? A formatter? Is auto-fix configured?
3. **Type Safety** — Is there a static type checker? What strictness mode?
4. **Security Analysis** — Is there a security scanner? Framework-specific rules?
5. **Code Complexity** — Is there a complexity checker? What thresholds?
6. **Dead Code & Modernization** — Is there dead code detection? Modernization checking?
7. **Documentation** — Is there docstring coverage enforcement? What threshold?
8. **Architecture** — Is there circular import detection? Import contract enforcement? Dependency hygiene?
9. **Version Discipline** — Is there a version file? Is the version semver 2.0? Is bump enforcement configured?

### 3. Check Hook Coverage

Verify Claude Code hooks are configured for each hook event from `methodology.md`:
- SessionStart → dependency hygiene check (non-blocking)
- PostToolUse (Edit|Write) → per-edit auto-fix (lint, format, spelling)
- Stop → quality gate (all enabled dimensions)
- PostToolUse (Bash) → semver bump enforcement (blocking, only if Dimension 9 active)
- Stop → auto-commit (optional)

### 4. Check CI Coverage

Verify CI pipeline has a job for each enabled dimension:
- test (runner + coverage)
- lint (linter + formatter)
- typecheck (type checker)
- security (security scanner)
- deadcode (dead code detector)
- version (semver format check)

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
| Version Discipline | Missing | — | No version validation configured |

### Hook Coverage
- [x] PostToolUse (per-edit fix)
- [x] Stop (quality gate)
- [ ] Stop (auto-commit) — not configured
- [ ] SessionStart (dependency hygiene) — not configured

### CI Coverage
- [x] test
- [x] lint
- [ ] typecheck — missing
- [ ] security — missing
- [ ] deadcode — missing

### Recommendations
1. Run `/python-blueprint:setup` to configure missing dimensions
2. Consider adding a second type checker for broader coverage
3. Expand linter rule sets for more comprehensive checking
4. Consider raising coverage threshold from 65% to 80%
```

## Important Notes

- Compare against methodology roles, not specific tools — any tool filling the role counts
- Note where project-specific thresholds may be appropriate
- Flag outdated tools that have been superseded by better alternatives
- Report both missing dimensions and misconfigured existing tools

## Troubleshooting

**No pyproject.toml found**:
- The project may use setup.cfg or setup.py. Check those for tool configs. Recommend migrating to pyproject.toml.

**Hooks configured but methodology.md not found**:
- The project may have been configured manually without the plugin. Audit the hooks against the methodology principles anyway.
