# Phase 1: Plugin Scaffold + CLAUDE.md

## Status: In Progress

## Goal

Create the plugin manifest, reorganize the directory structure, and establish CLAUDE.md.

## Deliverable

A valid (but mostly empty) Claude Code plugin structure with all current files preserved in `blueprint/` as reference material.

## Tasks

1. **Create `.claude-plugin/plugin.json`** — plugin manifest with name, version, description, author
2. **Create `plans/` directory** — phase markdown files for each phase
3. **Move current files into `blueprint/`** — preserve as reference material for methodology extraction:
   - `.claude/` (hooks, agents, commands, settings, statusline)
   - `.devcontainer/` (Dockerfile, devcontainer.json, scripts)
   - `.github/` (CI workflow)
   - Config files: `pyproject-tools.toml`, `pyrightconfig.json`, `.pre-commit-config.yaml`
   - Build files: `Makefile`, `apply.sh`, `APPLY_PROMPT.md`
   - Templates: `gitignore.blueprint`, `CLAUDE.md.blueprint`
4. **Create empty directory structure**:
   - `skills/setup/templates/`
   - `skills/audit/`, `skills/update/`, `skills/explain/`
   - `agents/`, `commands/`, `hooks/`, `scripts/`
5. **Create `CLAUDE.md`** — development guide for maintaining the plugin repo
6. **Update `README.md`** — describe the new plugin architecture

## Key Decisions

- Clean break from submodule approach; old files preserved in `blueprint/` for reference only
- Move, don't copy: hooks/agents/commands won't run on this repo until Phase 3-4 restores them via the plugin structure
- `.gitkeep` files in empty directories to ensure git tracks them

## Verification

- `claude --plugin-dir .` recognizes the plugin
- Directory structure matches planned layout
- CLAUDE.md accurately describes architecture
- README.md reflects plugin approach
- All phase docs in `plans/` contain enough detail for independent execution
