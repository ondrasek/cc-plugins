---
name: update
description: Applies incremental methodology updates to a Python project previously configured with python-blueprint. Use when user says "update quality tools", "upgrade methodology", "sync with latest blueprint", or after updating the plugin to get new tool recommendations and configs.
metadata:
  version: 0.1.0
  author: ondrasek
---

# Update

## Context Files

Read these files from the plugin before starting:

- `skills/setup/methodology.md` — current methodology (latest version)
- `skills/setup/templates/` — current templates

## Workflow

### 1. Detect Current State

Run the same analysis as the audit skill to understand what's currently configured.

### 2. Identify Differences

Compare the project's current configuration against the latest methodology:

- **New tools** — tools added to the methodology since the project was configured
- **Updated configs** — default configurations that have changed (new ruff rules, updated versions, etc.)
- **New templates** — hook scripts or CI jobs that have been improved
- **Threshold changes** — recommended thresholds that have been adjusted

### 3. Present Update Plan

Show the user what would change:

```
## Available Updates

### New Tools
- ty (type checker) — added to type safety dimension
  Would add: [tool.ty] section to pyproject.toml, ty check to quality gate

### Configuration Updates
- ruff: target-version py312 → py313
- ruff.lint: add "UP" rule set (pyupgrade)
- mypy: add warn_unused_ignores = true

### Template Updates
- quality-gate.sh: improved error hints for pyright and mypy
- ci.yml: added deadcode job

### No Changes Needed
- pytest configuration is current
- bandit configuration is current
- coverage threshold matches recommendation
```

Wait for user approval before proceeding.

### 4. Apply Updates

For each approved update:

1. **Merge config changes** — Update `pyproject.toml` sections, preserving project-specific customizations
2. **Update hook scripts** — Regenerate from templates with project-specific variables
3. **Update CI pipeline** — Add new jobs, update existing job commands
4. **Install new dependencies** — Run package manager install

### 5. Verify

Run the quality gate to ensure updates don't break anything.

### 6. Report

Summarize what was updated and any manual steps needed.

## Important Notes

- Always show the update plan before making changes
- Preserve project-specific customizations (custom thresholds, extra rules, whitelists)
- If a project has deliberately disabled a dimension, don't re-enable it
- Update one dimension at a time to make changes reviewable

## Troubleshooting

**Project was not configured with python-blueprint**:
- Run `/python-blueprint:audit` first to understand current state, then suggest `/python-blueprint:setup` instead.

**Quality gate fails after update**:
- The update may have tightened thresholds or added new checks. Distinguish new failures from regressions. Roll back individual changes if needed.
