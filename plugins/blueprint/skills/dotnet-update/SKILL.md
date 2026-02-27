---
name: dotnet-update
description: Applies incremental methodology updates to a .NET project previously configured with blueprint. Use when user says "update quality tools", "upgrade methodology", "sync with latest blueprint", or after updating the plugin to get new tool recommendations and configs.
metadata:
  version: 1.0.0
  author: Ondrej (Ondra) Krajicek, me@ondrejkrajicek.com
---

# .NET Update

## Context Files

- `skills/shared/references/update-workflow.md` — the 6-step workflow structure
- `skills/dotnet-setup/references/methodology.md` — current methodology (latest version)
- `skills/dotnet-setup/templates/` — current templates

## Workflow

Follow `update-workflow.md`. .NET-specific: preserve Directory.Build.props customizations, .editorconfig overrides, and analyzer package choices.
