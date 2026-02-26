---
name: update
description: Applies incremental methodology updates to a Neovim Lua plugin previously configured with nvim-lua-blueprint. Use when user says "update quality tools", "upgrade methodology", "sync with latest blueprint", or after updating the plugin to get new tool recommendations and configs.
metadata:
  version: 0.1.0
  author: Ondrej (Ondra) Krajicek, me@ondrejkrajicek.com
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
- **Updated configs** — default configurations that have changed (new selene rules, updated stylua settings, etc.)
- **New templates** — hook scripts or CI jobs that have been improved
- **Threshold changes** — recommended thresholds that have been adjusted

### 3. Present Update Plan

Show the user what would change:

```
## Available Updates

### New Tools
- lizard — added for code complexity measurement
  Would add: complexity check to quality gate and Makefile

### Configuration Updates
- selene.toml: updated vim.toml with new Neovim API globals
- .stylua.toml: lua_version updated to "luajit"
- ci.yml: updated selene-action to v2

### Template Updates
- quality-gate.sh: improved error hints for selene
- session-start.sh: added tool availability checks

### No Changes Needed
- .luacov is current
- Test configuration is current
- Coverage threshold matches recommendation
```

Wait for user approval before proceeding.

### 4. Apply Updates

For each approved update:

1. **Merge config changes** — Update selene.toml, .stylua.toml, .luarc.json, preserving project-specific customizations
2. **Update hook scripts** — Regenerate from templates with project-specific variables
3. **Update CI pipeline** — Add new jobs, update existing job commands and actions
4. **Suggest new tools** — Recommend installation commands for any new tools

### 5. Verify

Run the quality gate to ensure updates don't break anything.

### 6. Report

Summarize what was updated and any manual steps needed.

## Important Notes

- Always show the update plan before making changes
- Preserve project-specific customizations (custom thresholds, extra selene rules, stylua overrides)
- If a project has deliberately disabled a dimension, don't re-enable it
- Update one dimension at a time to make changes reviewable

## Troubleshooting

**Project was not configured with nvim-lua-blueprint**:
- Run `/nvim-lua-blueprint:audit` first to understand current state, then suggest `/nvim-lua-blueprint:setup` instead.

**Quality gate fails after update**:
- The update may have tightened thresholds or added new checks. Distinguish new failures from regressions. Roll back individual changes if needed.
