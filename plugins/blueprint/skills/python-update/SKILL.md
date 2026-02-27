---
name: python-update
description: Applies incremental methodology updates to a Python project previously configured with blueprint. Use when user says "update quality tools", "upgrade methodology", "sync with latest blueprint", or after updating the plugin to get new tool recommendations and configs.
metadata:
  version: 1.0.0
  author: Ondrej (Ondra) Krajicek, me@ondrejkrajicek.com
---

# Python Update

## Context Files

- `skills/shared/references/update-workflow.md` — the 6-step workflow structure
- `skills/python-setup/references/methodology.md` — current methodology (latest version)
- `skills/python-setup/templates/` — current templates

## Workflow

Follow `update-workflow.md`. Python-specific: preserve pyproject.toml customizations, pre-commit config, and package manager choice.
