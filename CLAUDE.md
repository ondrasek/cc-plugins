# CLAUDE.md — python-blueprint plugin

## What This Is

A Claude Code plugin that applies a Python quality methodology to any codebase. Instead of copying config files, it analyzes the target project's ecosystem, selects appropriate tools, and configures hooks/CI intelligently.

## Directory Structure

```
.claude-plugin/plugin.json   — Plugin manifest
skills/
  setup/                     — Main setup skill (Phase 3)
    methodology.md           — Quality dimensions and adaptation rules (Phase 2)
    tool-catalog.md          — Tool descriptions and alternatives (Phase 2)
    analysis-checklist.md    — Target codebase analysis guide (Phase 2)
    templates/               — Adaptable config templates (Phase 2)
    SKILL.md                 — Setup skill definition (Phase 3)
  audit/SKILL.md             — Gap analysis skill (Phase 5)
  update/SKILL.md            — Incremental update skill (Phase 5)
  explain/SKILL.md           — Methodology Q&A skill (Phase 5)
hooks/                       — Plugin-level hook registrations (Phase 3)
scripts/                     — Hook scripts (Phase 3)
plans/                       — Phase plan documents
blueprint/                   — Original blueprint files (reference material)
```

## Development Status

See `plans/` for detailed phase documentation:
- Phase 1: Plugin scaffold + CLAUDE.md (complete)
- Phase 2: Methodology document + templates (complete)
- Phase 3: Setup skill (`/python-blueprint:setup`) (complete)
- Phase 5: Supporting skills (audit, update, explain)
- Phase 6: End-to-end testing + polish

## Working on This Repo

### Testing the plugin locally

```bash
# From a target project directory:
claude --plugin-dir /path/to/python-blueprint
```

### Key files to understand

- `blueprint/` contains the original quality gate, hooks, and configs — the source material for the methodology
- `blueprint/.claude/hooks/quality-gate.sh` has the 15-point quality gate
- `blueprint/pyproject-tools.toml` has all tool configurations
- `blueprint/.github/workflows/ci.yml` has the CI pipeline

### Conventions

- Templates in `skills/setup/templates/` use shell variables (`${PROJECT_NAME}`, etc.) for customization points
- Methodology documents are Markdown, designed to be read by Claude as context for the setup skill
- Plugin-level hooks use `${CLAUDE_PLUGIN_ROOT}` for path resolution
- Phase docs in `plans/` are the source of truth for what each phase delivers

## Quality Methodology (8 Dimensions)

The methodology being extracted from `blueprint/` covers:

1. **Testing & Coverage** — pytest, minimum coverage thresholds
2. **Linting & Formatting** — ruff (check + format)
3. **Type Safety** — pyright, mypy
4. **Security Analysis** — bandit, semgrep
5. **Code Complexity** — xenon (cyclomatic complexity)
6. **Dead Code & Modernization** — vulture, refurb
7. **Documentation** — interrogate (docstring coverage)
8. **Architecture & Import Discipline** — import-linter, deptry

Each dimension has adaptation rules for different project types, sizes, and maturity levels.
