# python-quality-gate

Fail-fast Python quality gate that runs 14 checks on every Claude Stop. Blocks until all checks pass — Claude fixes each failure automatically before the next Stop re-runs the gate.

## How It Works

The Stop hook runs checks in order, stopping at the **first** failure (exit 2). Claude reads the error, fixes the code, and stops again — the gate re-runs and progresses to the next check.

Repo-agnostic: scans all Python code in the repository. Each tool uses its own config (pyproject.toml, pyrightconfig.json, etc.) for includes/excludes.

## Checks (14)

| # | Check | Tool | What it catches |
|---|-------|------|-----------------|
| 1 | Tests | pytest | Failing tests (fast, `-m "not slow"`) |
| 2 | Coverage | pytest-cov | Coverage below 80% threshold |
| 3 | Lint | ruff check | Lint violations, import sorting |
| 4 | Format | ruff format | Formatting inconsistencies |
| 5 | Types (pyright) | pyright | Static type errors |
| 6 | Types (mypy) | mypy | Static type errors (complementary) |
| 7 | Security | bandit | Security vulnerabilities (high confidence) |
| 8 | Dead code | vulture | Unused functions, variables, imports |
| 9 | Complexity | xenon | Functions with cyclomatic complexity > 10 |
| 10 | Modernization | refurb | Non-idiomatic patterns, outdated constructs |
| 11 | Imports | import-linter | Import boundary violations |
| 12 | Types (ty) | ty | Additional type checking |
| 13 | Docstrings | interrogate | Missing docstrings (70% threshold) |
| 14 | Style guide | inline | CLI output formatting (click/typer projects only) |

Checks are ordered by speed and failure likelihood — fast/common first.

## Per-Tool Hints

Each check includes a diagnostic hint that tells Claude exactly how to investigate and fix the failure: which command to run for more detail, what to look for in the code, and how to verify the fix.

## Prerequisites

- **uv** — all tools run via `uv run`
- **Python project with pyproject.toml** — tools use it for configuration
- Tools must be declared as dev dependencies in pyproject.toml

## Configuration

Each tool reads its own config from standard locations:

| Tool | Config location |
|------|----------------|
| ruff | `[tool.ruff]` in pyproject.toml |
| pyright | pyrightconfig.json or `[tool.pyright]` in pyproject.toml |
| mypy | `[tool.mypy]` in pyproject.toml or mypy.ini |
| coverage | `[tool.coverage.run]` in pyproject.toml |
| bandit | `[tool.bandit]` in pyproject.toml or .bandit |
| import-linter | `[tool.importlinter]` in pyproject.toml |
| interrogate | `[tool.interrogate]` in pyproject.toml |

## Exit Codes

| Code | Meaning |
|------|---------|
| `0` | All 14 checks passed |
| `2` | Check failed — structured error with hint fed back to Claude |

## Installation

```bash
# From the cc-plugins marketplace
/plugin install python-quality-gate@cc-plugins
```

## Local Development

```bash
cd /path/to/your-python-project
claude --plugin-dir /path/to/cc-plugins/plugins/python-quality-gate
```
