---
name: nvim-lua-audit
description: Read-only gap analysis comparing a Neovim Lua plugin's current quality setup against the 9-dimension methodology. Use when user says "audit quality", "check coverage gaps", "what's missing", or wants to see how their Neovim plugin measures up before running setup.
metadata:
  version: 1.0.0
  author: Ondrej (Ondra) Krajicek, me@ondrejkrajicek.com
---

# Neovim Lua Audit

Read-only — does not modify any files.

## Context Files

Read these files before starting:

- `skills/shared/references/audit-workflow.md` — the 5-step workflow structure
- `skills/nvim-lua-setup/references/methodology.md` — the 9 quality dimensions (roles) to audit against
- `skills/nvim-lua-setup/references/analysis-checklist.md` — what to check in the target codebase

## Workflow

Follow `audit-workflow.md`. Neovim Lua-specific details:

### 1. Analyze Current State

Detect project structure (lua/, plugin/, tests/, doc/), plugin type, test framework (plenary/mini.test/busted). Inventory existing configurations in selene.toml, .stylua.toml, .luacov, .luarc.json. Check hooks, CI, installed tools.

### 2. Compare Against Methodology

Check each of the 9 dimensions — see `methodology.md` for Neovim Lua-specific tools and thresholds.

### 3. Check Hook Coverage

Expected hooks: SessionStart (plugin structure check), PostToolUse/Edit|Write (StyLua), Stop (quality gate), PostToolUse/Bash (semver check).

### 4. Check CI Coverage

Expected jobs: test (Neovim matrix), lint (selene + stylua), typecheck (optional), version.

### 5. Report

Present dimension/hook/CI coverage tables with recommendations. Suggest running `/blueprint:nvim-lua-setup` to configure missing dimensions.

## Troubleshooting

**No lua/ directory found**: The project may not be a Neovim plugin. Suggest using the appropriate blueprint skill instead.
