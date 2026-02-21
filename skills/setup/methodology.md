# Python Quality Methodology

This document defines the quality methodology applied by the `python-blueprint` plugin. It is organized into 8 quality dimensions, each with tools, rationale, default configuration, and adaptation rules.

The setup skill reads this document to understand what to apply and how to adapt it.

---

## Principles

1. **Fail fast, fix fast** — Quality checks run as Claude Code hooks. Failures block the agent and feed back for automatic fixing (exit code 2).
2. **Ordered by speed** — Checks run fastest-first so common failures surface quickly.
3. **Opinionated defaults, flexible adaptation** — Defaults reflect production-grade standards. Every dimension can be relaxed for early-stage, prototype, or legacy projects.
4. **Tools are replaceable** — The methodology defines *what* to check, not *which tool*. See `tool-catalog.md` for alternatives.
5. **Incremental adoption** — Projects can adopt dimensions one at a time. The audit skill tracks which dimensions are active.

---

## Dimension 1: Testing & Coverage

**What**: Every code change must be backed by tests. Coverage ensures untested code paths are visible.

**Default tools**: pytest, pytest-cov

**Default configuration**:
- `pytest -x --tb=short` (fail fast, concise output)
- `--cov=src/ --cov-fail-under=80` (80% minimum coverage)
- Test paths: `tests/`

**Adaptation rules**:
- **New project (< 500 LOC)**: Lower threshold to 60%, focus on happy-path tests
- **Legacy project**: Start with 40% threshold, increase 5% per sprint
- **Library**: Require 90%+ coverage for public API
- **CLI app**: Exclude integration tests from coverage minimum; test commands separately
- **Django/Flask**: Include framework-specific test utilities (e.g., `pytest-django`)

**Quality gate check**: `uv run pytest -x --tb=short` then `uv run pytest --cov=src/ --cov-report=term --cov-fail-under=80 -q`

**CI job**: `test` — runs pytest with coverage, uploads to Codecov on PRs

---

## Dimension 2: Linting & Formatting

**What**: Consistent code style and automated detection of common bugs, anti-patterns, and import issues.

**Default tools**: ruff (lint + format), codespell

**Default configuration**:
- Target: Python 3.13
- Line length: 100
- Lint rules: E, W, F, I, UP, B, SIM (pycodestyle, pyflakes, isort, pyupgrade, bugbear, simplify)
- Format: double quotes
- Codespell: skip `.venv,*.pyc,__pycache__,.git`

**Adaptation rules**:
- **Python version < 3.13**: Set `target-version` to match project's minimum Python
- **Existing formatter (black)**: Migrate to ruff format (drop-in compatible) or keep black if team prefers
- **Large codebase**: Start with `E,F,I` rules, add `UP,B,SIM` incrementally
- **Monorepo**: Configure per-package `ruff.toml` or `pyproject.toml` sections

**Quality gate checks**: `uv run ruff check src/ tests/` then `uv run ruff format --check src/ tests/`

**Per-edit hook**: Auto-fix with `ruff check --fix --quiet` and `ruff format --quiet` on every Python file edit. Also runs `codespell --write-changes` for typo correction.

**CI job**: `lint` — ruff check + format check

---

## Dimension 3: Type Safety

**What**: Static type analysis catches type errors before runtime. Two complementary checkers provide broader coverage.

**Default tools**: pyright, mypy, ty

**Default configuration**:
- Pyright: `standard` mode, include `src/`, Python 3.13
- Mypy: `strict = true`, `warn_return_any = true`, `warn_unused_ignores = true`, relaxed for `tests.*`
- ty: Python 3.13, exclude tests and `__pycache__`

**Adaptation rules**:
- **Untyped codebase**: Start with pyright in `basic` mode only; skip mypy until annotations exist
- **Gradual typing**: Use mypy `--follow-imports=silent` to type-check only annotated modules
- **Django**: Add `django-stubs` and configure mypy `plugins = ["mypy_django_plugin.main"]`
- **FastAPI/Pydantic**: Pyright handles Pydantic well; add `pydantic` mypy plugin if using mypy
- **Python < 3.10**: Drop ty (requires modern Python); pyright + mypy sufficient

**Quality gate checks**: `uv run pyright src/` then `uv run mypy src/` then `uv run ty check src/`

**CI job**: `typecheck` — runs pyright

---

## Dimension 4: Security Analysis

**What**: Static analysis for known vulnerability patterns, unsafe API usage, and security anti-patterns.

**Default tools**: bandit, semgrep

**Default configuration**:
- Bandit: exclude `tests`, `.venv`; skip `B101` (assert); severity `-ll` (low and above)
- Semgrep: `p/python` ruleset, error mode, quiet output

**Adaptation rules**:
- **Library (no I/O)**: Relax bandit severity to `-lll` (medium+ only)
- **Web app (Django/Flask/FastAPI)**: Add semgrep rulesets: `p/django`, `p/flask`, `p/owasp-top-ten`
- **Data science**: Skip semgrep (too noisy on notebooks); bandit only
- **CI-only semgrep**: Semgrep is slow; consider running only in CI, not in quality gate

**Quality gate checks**: `uv run bandit -r src/ -q -ll` then `uv run semgrep scan --config p/python --error --quiet src/`

**CI job**: `security` — runs bandit

---

## Dimension 5: Code Complexity

**What**: Functions exceeding cyclomatic complexity thresholds are hard to test, review, and maintain. Enforce measurable complexity limits.

**Default tool**: xenon

**Default configuration**:
- Max absolute: B (no function above CC 10)
- Max modules: A (module averages in 1–5 range)
- Max average: A (project-wide average in 1–5 range)
- Thresholds follow McCabe/NIST production standards

**Adaptation rules**:
- **Early-stage project**: Accept C absolute (CC ≤ 15) temporarily
- **Legacy codebase**: Start at D absolute, tighten one grade per quarter
- **Data processing / ETL**: May legitimately have complex functions; consider per-module exceptions
- **Generated code**: Exclude from complexity checks

**Quality gate check**: `uv run xenon --max-absolute B --max-modules A --max-average A src/`

---

## Dimension 6: Dead Code & Modernization

**What**: Remove unused code and adopt modern Python idioms. Keeps the codebase lean and current.

**Default tools**: vulture, refurb

**Default configuration**:
- Vulture: `--min-confidence 80` on `src/`
- Refurb: `--python-version 3.13` on `src/`

**Adaptation rules**:
- **Library with public API**: Lower vulture confidence to 90% or maintain a whitelist for public symbols
- **Plugin architecture**: Vulture may flag dynamically-loaded code; use whitelist
- **Python < 3.13**: Set refurb `--python-version` to match minimum supported version
- **Large legacy codebase**: Start vulture at confidence 95, lower gradually

**Quality gate checks**: `uv run vulture src/ --min-confidence 80` (nonempty output = fail) then `uv run refurb src/ --python-version 3.13` (nonempty output = fail)

**CI job**: `deadcode` — runs vulture

---

## Dimension 7: Documentation

**What**: Public functions, classes, and modules should have docstrings. Enforced by coverage measurement, not style.

**Default tool**: interrogate

**Default configuration**:
- Fail-under: 70%
- Exclude: tests, docs
- Ignore: `__init__` methods/modules, magic methods, semiprivate, private

**Adaptation rules**:
- **Early-stage / prototype**: Lower to 50%
- **Library**: Raise to 90% — consumers depend on docstrings
- **Internal tool**: 60% is acceptable
- **Data science**: Exclude generated or notebook-converted code

**Quality gate check**: `uv run interrogate src/ -v --fail-under 70 -e tests/`

---

## Dimension 8: Architecture & Import Discipline

**What**: Enforce import boundaries between modules and detect dependency hygiene issues (unused, missing, or transitive dependencies).

**Default tools**: import-linter, deptry

**Default configuration**:
- Import-linter: `root_packages = ["your_package"]` with custom contracts
- Deptry: `ignore = ["DEP003"]` (self-imports)

**Adaptation rules**:
- **Single-module project**: Skip import-linter (nothing to enforce)
- **Monorepo**: Configure import contracts per package
- **Django**: Configure layer contracts: views → services → models (no reverse)
- **New project**: Start with deptry only; add import-linter when architecture emerges
- **Session-only**: Deptry runs in session-start hook (non-blocking warnings), not in quality gate

**Quality gate check**: `uv run lint-imports`

**Session start hook**: `uv run deptry .` (non-blocking)

---

## Hook Architecture

The methodology uses four hook types:

| Hook Event | Script | Behavior | Blocking |
|-----------|--------|----------|----------|
| **SessionStart** | `session-start.sh` | Dependency hygiene (deptry) | No (warnings only) |
| **PostToolUse** (Edit\|Write) | `per-edit-fix.sh` | Auto-fix lint, format, spelling on each Python file edit | Yes (exit 2 for unfixable) |
| **Stop** | `quality-gate.sh` | Full 15-check quality gate | Yes (exit 2 → Claude fixes) |
| **Stop** | `auto-commit.sh` | Auto-commit and push if quality gate passes | No (push failure is non-blocking) |

**Key design**: The quality gate exits with code 2 on failure, which feeds stderr back to Claude for automatic fixing. The agent loops until all checks pass or it gives up.

---

## Pre-commit Hooks

Separate from Claude Code hooks, `pre-commit` runs on `git commit`:
- `ruff` — lint check
- `ruff-format` — format check

These catch issues in manual commits that bypass the Claude Code workflow.

---

## CI Pipeline Structure

The CI pipeline runs a subset of the quality gate as parallel jobs:

| Job | Checks | Purpose |
|-----|--------|---------|
| `test` | pytest + coverage + Codecov | Verify behavior |
| `lint` | ruff check + ruff format | Verify style |
| `typecheck` | pyright | Verify types |
| `security` | bandit | Verify safety |
| `deadcode` | vulture | Verify no dead code |

Jobs run on `push` to main and on pull requests to main.

---

## Style Guide (CLI Projects)

For projects using `click` for CLI output:
1. **No ASCII splitter lines** — no `===`, `---`, `***` in echo/print calls
2. **Section headings** — use `click.style(ALL CAPS text, fg=COLOR, bold=True)`
3. **Emoji prefixes** — section headings should include an emoji

This is enforced by a separate `style-guide-check.sh` in the quality gate. Only applies to projects with click-based CLIs.
