---
name: nvim-lua-update
description: Applies incremental methodology updates to a Neovim Lua plugin previously configured with blueprint. Use when user says "update quality tools", "upgrade methodology", "sync with latest blueprint", or after updating the plugin to get new tool recommendations and configs.
metadata:
  version: 1.0.0
  author: Ondrej (Ondra) Krajicek, me@ondrejkrajicek.com
---

# Neovim Lua Update

## Context Files

- `skills/shared/references/update-workflow.md` — the 6-step workflow structure
- `skills/nvim-lua-setup/references/methodology.md` — current methodology (latest version)
- `skills/nvim-lua-setup/templates/` — current templates

## Workflow

Follow `update-workflow.md`. Neovim Lua-specific: preserve selene.toml customizations, .stylua.toml settings, and test framework choice.
