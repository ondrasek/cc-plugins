# python-quality-gate

Fail-fast Python quality gate that runs 14 checks on every Claude Stop. Blocks until all checks pass — Claude fixes each failure automatically before the next Stop re-runs the gate.

## Why Not a Plugin?

Claude Code has [known bugs](https://github.com/anthropics/claude-code/issues/11509) where plugin-defined hooks don't reliably fire — particularly for local/directory-based marketplace plugins ([#11509](https://github.com/anthropics/claude-code/issues/11509), [#14410](https://github.com/anthropics/claude-code/issues/14410)) and the VSCode extension ([#18547](https://github.com/anthropics/claude-code/issues/18547)). Since this quality gate is entirely a Stop hook with no skills, shipping it as a plugin provides no benefit — the hook simply won't run.

Instead, the script is distributed as a **self-updating gist**. You copy it into your project once and configure it as a project-level hook in `.claude/settings.json`. On each run, the script checks the [canonical gist](https://gist.github.com/ondrasek/f796e3c3321fe0033845994f5406eb0d) for updates via HTTP ETag and tells Claude to update itself when a newer version is available.

## Installation

1. Download the script and its ETag file into your project:

```bash
mkdir -p scripts
curl -sf -D /tmp/qg-headers \
  "https://gist.githubusercontent.com/ondrasek/f796e3c3321fe0033845994f5406eb0d/raw/quality-gate.sh" \
  -o scripts/quality-gate.sh
chmod +x scripts/quality-gate.sh
grep -i '^etag:' /tmp/qg-headers | tr -d '\r' | awk '{print $2}' > scripts/quality-gate.sh.etag
rm /tmp/qg-headers
```

2. Add the Stop hook to `.claude/settings.json`:

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "scripts/quality-gate.sh",
            "timeout": 300
          }
        ]
      }
    ]
  }
}
```

3. Commit both `scripts/quality-gate.sh` and `scripts/quality-gate.sh.etag`.

The `.etag` file acts as a version lock — any stale checkout triggers a self-update on first run.

## Self-Updating

The script checks the canonical gist every 60 minutes using HTTP conditional requests:

- **304 Not Modified** — script is current, proceeds to quality checks
- **200 OK** — newer version available, exits with code 2 instructing Claude to download the update
- **Network failure** — skipped silently, proceeds to quality checks

The `.etag` file serves double duty: its content is the HTTP ETag (version lock), its mtime is the last-check timestamp (rate limiting).

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
