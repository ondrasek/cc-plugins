# Phase 2: Methodology Document + Templates

## Status: Complete

## Goal

Extract the quality methodology from the current blueprint files into structured documents and adaptable templates. This is the intellectual core of the plugin.

## Deliverable

The complete methodology — 8 quality dimensions, tool catalog, analysis checklist, and all templates needed by the setup skill.

## Files to Create

### Methodology Documents

- **`skills/setup/methodology.md`** — 8 quality dimensions with adaptation rules:
  1. Testing & Coverage
  2. Linting & Formatting
  3. Type Safety
  4. Security Analysis
  5. Code Complexity
  6. Dead Code & Modernization
  7. Documentation
  8. Architecture & Import Discipline

- **`skills/setup/tool-catalog.md`** — tool descriptions, default configs, alternatives:
  - Primary tools: pytest, ruff, pyright, mypy, bandit, vulture, xenon, refurb
  - Supporting tools: import-linter, semgrep, ty, interrogate, codespell, deptry
  - Alternatives and when to prefer them

- **`skills/setup/analysis-checklist.md`** — what to check in target codebases:
  - Existing tool configs (pyproject.toml, setup.cfg, tox.ini)
  - Package manager (uv, pip, poetry, pdm)
  - Project structure (src layout vs flat)
  - Existing CI/CD
  - Python version constraints
  - Framework detection (Django, Flask, FastAPI, etc.)

### Templates (in `skills/setup/templates/`)

Each template is an adaptable reference, not a raw copy target:

| Template | Source | Purpose |
|----------|--------|---------|
| `quality-gate.sh` | `blueprint/.claude/hooks/quality-gate.sh` | Stop hook: run all quality checks |
| `per-edit-fix.sh` | `blueprint/.claude/hooks/per-edit-fix.sh` | PostToolUse hook: auto-fix on edit |
| `auto-commit.sh` | `blueprint/.claude/hooks/auto-commit.sh` | Stop hook: auto-commit changes |
| `session-start.sh` | `blueprint/.claude/hooks/session-start.sh` | SessionStart hook: env setup |
| `ci.yml` | `blueprint/.github/workflows/ci.yml` | GitHub Actions pipeline |
| `devcontainer.json` | `blueprint/.devcontainer/devcontainer.json` | DevContainer config |
| `Dockerfile` | `blueprint/.devcontainer/Dockerfile` | DevContainer image |
| `pyproject-tools.toml` | `blueprint/pyproject-tools.toml` | Tool config sections |
| `statusline.sh` | `blueprint/.claude/statusline.sh` | Claude Code status line |

## Source Material

All source files are in `blueprint/`:
- `blueprint/.claude/hooks/quality-gate.sh` — 15-point quality gate
- `blueprint/.claude/hooks/per-edit-fix.sh` — per-edit auto-fix
- `blueprint/.claude/hooks/auto-commit.sh` — auto-commit logic
- `blueprint/.claude/hooks/session-start.sh` — session initialization
- `blueprint/.claude/hooks/style-guide-check.sh` — style guide rules
- `blueprint/pyproject-tools.toml` — all tool configurations
- `blueprint/.github/workflows/ci.yml` — CI pipeline
- `blueprint/.devcontainer/` — full devcontainer setup
- `blueprint/.claude/settings.json` — hook registrations
- `blueprint/pyrightconfig.json`, `blueprint/.pre-commit-config.yaml`

## Approach

1. Read each source file and extract the methodology principles
2. Document adaptation rules (when to skip checks, adjust thresholds, etc.)
3. Create templates with clear markers for customization points
4. Cross-reference between methodology, tool catalog, and templates

## Verification

- Every quality dimension in methodology.md maps to at least one tool and one template
- Tool catalog covers all 15 tools from the quality gate
- Templates are parameterized (not hardcoded to a specific project)
- Analysis checklist covers the key ecosystem variations
