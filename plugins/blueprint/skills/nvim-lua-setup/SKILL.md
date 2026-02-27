---
name: nvim-lua-setup
description: Analyzes a Neovim Lua plugin and configures 9-dimension quality methodology including hooks, CI, and tool configs. Use when user says "set up quality tools", "configure linting", "add CI pipeline", "neovim lua quality", or wants to apply coding standards to a Neovim Lua plugin.
metadata:
  version: 1.0.0
  author: Ondrej (Ondra) Krajicek, me@ondrejkrajicek.com
---

# Neovim Lua Setup

## Critical Rules

- **Always present analysis and plan to the user before making changes**
- **Merge, don't replace** — preserve existing selene.toml, .stylua.toml, CI jobs, hooks
- **Always configure for LuaJIT/Lua 5.1** (Neovim's embedded Lua)
- All hook scripts must be executable (`chmod +x`)

## Context Files

Read these files before starting:

- `skills/shared/references/methodology-framework.md` — shared principles, hook architecture, exit codes, settings.json format
- `skills/shared/references/setup-workflow.md` — the 6-phase workflow structure
- `skills/nvim-lua-setup/references/methodology.md` — Neovim Lua-specific 9 dimensions, thresholds, tool research guidance
- `skills/nvim-lua-setup/references/analysis-checklist.md` — what to check in the target codebase
- `skills/nvim-lua-setup/templates/` — **annotated examples** showing structural patterns. Use templates for patterns but substitute the tools chosen during research.

## Workflow

Follow the 6-phase workflow from `setup-workflow.md`.

### Phase 1: Analyze

Follow `analysis-checklist.md` systematically: project structure (lua/, plugin/, tests/, doc/), plugin type, test framework (plenary/mini.test/busted), existing tools, CI, maturity.

### Phase 2: Plan

Research tools for each of the 9 dimensions. Neovim Lua-specific files to plan:
- `selene.toml` + `vim.toml` — Selene linter configuration with Neovim globals
- `.stylua.toml` — StyLua formatter configuration
- `.luacov` — coverage configuration
- `.luarc.json` — lua-language-server configuration
- `.claude/hooks/` — quality-gate.sh, per-edit-fix.sh, session-start.sh, optionally auto-commit.sh
- `.claude/settings.json` — hook registrations (see methodology-framework.md for format)
- `.github/workflows/ci.yml` — CI pipeline with Neovim version matrix
- `Makefile` — development commands
- `CLAUDE.md` — project instructions
- `semver-check.sh` — only when Dimension 9 is activated at level 3

Present complete plan and wait for approval.

### Phase 3: Configure

Read each template in `templates/` for the structural pattern, substitute the researched tools. Note: per-edit hook runs StyLua only (selene has no `--fix` flag).

### Phase 4: Review

Read `references/reviewer-prompt.md` for the full prompt template. Spawn reviewer subagent using Task tool with `subagent_type: "general-purpose"`.

### Phase 5: Verify

Run `.claude/hooks/quality-gate.sh`. Distinguish pre-existing issues from config problems.

### Phase 6: Report

Structured summary: configured dimensions, files created/modified, quality gate results, next steps.

## Troubleshooting

**No lua/ directory found**: The project may not be a Neovim plugin. Suggest using the appropriate blueprint skill instead.

**Test framework not detected**: Check for plenary.nvim, mini.test, or busted. Ask the user which framework to use.
