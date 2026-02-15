# python-blueprint

A reusable project blueprint for Python projects using Claude Code. Provides a complete development environment with quality gates, CI/CD, devcontainer, and Claude Code hooks.

## What's Included

- **Claude Code configuration** — hooks (quality gate with 15 checks, auto-commit, per-edit fix, session start), statusline, agents, and slash commands
- **DevContainer** — full Python 3.13 development environment with pyenv, uv, Claude CLI, zsh
- **CI/CD** — GitHub Actions workflow for test, lint, typecheck, security, and dead code checks
- **Tool configuration** — ruff, pyright, mypy, bandit, vulture, xenon, refurb, interrogate, semgrep, ty, import-linter, codespell, deptry, pytest
- **Pre-commit hooks** — ruff lint and format checks
- **Makefile** — common development commands (setup, test, lint, format, clean)

## Quick Start

### 1. Add as a git submodule

```bash
cd your-project
git submodule add <blueprint-repo-url> .blueprint
git commit -m "Add python-blueprint submodule"
```

### 2. Apply the blueprint

```bash
.blueprint/apply.sh
```

This invokes Claude Code to intelligently merge the blueprint into your project:
- **Overwrites:** `.claude/`, `.devcontainer/`, `.github/workflows/ci.yml`, `Makefile`, `pyrightconfig.json`, `.pre-commit-config.yaml`
- **Smart merges:** tool config into `pyproject.toml`, entries into `.gitignore`
- **Creates if missing:** `CLAUDE.md` (starter template)
- **Never touches:** `src/`, `tests/`, `README.md`, or any project source code

### 3. Review and commit

```bash
git diff                    # Review changes
git add -A && git commit -m "Apply python-blueprint"
```

## Updating

When the blueprint is updated upstream:

```bash
cd .blueprint
git pull origin main
cd ..
.blueprint/apply.sh         # Re-apply with latest changes
git add -A && git commit -m "Update python-blueprint"
```

## Quality Gate (15 checks)

The quality gate runs automatically as a Claude Code Stop hook:

1. **pytest** — tests must pass
2. **coverage** — minimum 80% coverage
3. **ruff check** — linting
4. **ruff format** — formatting
5. **pyright** — type checking
6. **mypy** — strict type checking
7. **bandit** — security analysis
8. **vulture** — dead code detection
9. **xenon** — cyclomatic complexity (B/A/A thresholds)
10. **refurb** — Python modernization
11. **import-linter** — import architecture enforcement
12. **semgrep** — security and correctness patterns
13. **ty** — additional type checking
14. **interrogate** — docstring coverage (70% minimum)
15. **style-guide** — CLI output formatting rules

## File Reference

| File | Purpose |
|------|---------|
| `apply.sh` | Entry point — invokes Claude Code to merge blueprint |
| `APPLY_PROMPT.md` | Merge instructions for Claude Code |
| `pyproject-tools.toml` | Tool configuration sections for pyproject.toml |
| `gitignore.blueprint` | Generic Python .gitignore entries |
| `CLAUDE.md.blueprint` | Starter CLAUDE.md template |
| `.claude/` | Claude Code hooks, agents, commands, statusline |
| `.devcontainer/` | Full devcontainer setup |
| `.github/workflows/ci.yml` | GitHub Actions CI pipeline |
| `Makefile` | Common development commands |
| `pyrightconfig.json` | Pyright type checker configuration |
| `.pre-commit-config.yaml` | Pre-commit hook configuration |
