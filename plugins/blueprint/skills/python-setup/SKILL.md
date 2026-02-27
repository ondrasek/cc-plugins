---
name: python-setup
description: Analyzes a Python project and configures 9-dimension quality methodology including hooks, CI, and tool configs. Use when user says "set up quality tools", "configure linting", "add CI pipeline", "python quality", or wants to apply coding standards to a Python project.
metadata:
  version: 1.0.0
  author: Ondrej (Ondra) Krajicek, me@ondrejkrajicek.com
---

# Python Setup

## Critical Rules

- **Always present analysis and plan to the user before making changes**
- **Merge, don't replace** — preserve existing pyproject.toml sections, CI jobs, hooks
- **Use the package manager detected in analysis** (don't assume uv)
- All hook scripts must be executable (`chmod +x`)

## Context Files

Read these files before starting:

- `skills/shared/references/methodology-framework.md` — shared principles, hook architecture, exit codes, settings.json format
- `skills/shared/references/setup-workflow.md` — the 6-phase workflow structure
- `skills/python-setup/references/methodology.md` — Python-specific 9 dimensions, thresholds, tool research guidance
- `skills/python-setup/references/analysis-checklist.md` — what to check in the target codebase
- `skills/python-setup/templates/` — **annotated examples** showing structural patterns. Use templates for patterns but substitute the tools chosen during research.

## Workflow

Follow the 6-phase workflow from `setup-workflow.md`.

### Phase 1: Analyze

Follow `analysis-checklist.md` systematically: package manager, Python version, project structure, frameworks, existing tools, CI, maturity.

### Phase 2: Plan

Research tools for each of the 9 dimensions. Python-specific files to plan:
- `pyproject.toml` — `[tool.*]` sections for each tool
- `.claude/hooks/` — quality-gate.sh, per-edit-fix.sh, session-start.sh, optionally auto-commit.sh
- `.claude/settings.json` — hook registrations (see methodology-framework.md for format)
- `.github/workflows/ci.yml` — CI pipeline
- `.pre-commit-config.yaml` — pre-commit hooks
- `Makefile` — development commands
- `CLAUDE.md` — project instructions
- `pyrightconfig.json` — type checker config (only if pyright chosen)
- `semver-check.sh` — only when Dimension 9 is activated at level 3

Present complete plan and wait for approval. Ask about optional items (auto-commit, style-guide check).

### Phase 3: Configure

Read each template in `templates/` for the structural pattern, substitute the researched tools. Install dev dependencies and pre-commit hooks.

### Phase 4: Review

Read `references/reviewer-prompt.md` for the full prompt template. Spawn reviewer subagent using Task tool with `subagent_type: "general-purpose"`.

### Phase 5: Verify

Run `.claude/hooks/quality-gate.sh`. Distinguish pre-existing issues from config problems.

### Phase 6: Report

Structured summary: configured dimensions, files created/modified, quality gate results, next steps.

## Troubleshooting

**Package manager not detected**: Check for pyproject.toml, lock files, or requirements.txt. Ask the user.

**Pre-commit install fails**: Verify pre-commit is in dev dependencies. Run package manager install first.
