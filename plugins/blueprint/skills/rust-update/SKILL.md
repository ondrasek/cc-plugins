---
name: rust-update
description: Applies incremental methodology updates to a Rust project previously configured with blueprint. Use when user says "update quality tools", "upgrade methodology", "sync with latest blueprint", or after updating the plugin to get new tool recommendations and configs.
metadata:
  version: 1.0.0
  author: Ondrej (Ondra) Krajicek, me@ondrejkrajicek.com
---

# Rust Update

## Context Files

- `skills/shared/references/update-workflow.md` — the 6-step workflow structure
- `skills/rust-setup/references/methodology.md` — current methodology (latest version)
- `skills/rust-setup/templates/` — current templates

## Workflow

Follow `update-workflow.md`. Rust-specific: preserve Cargo.toml [lints] customizations, deny.toml exceptions, and clippy.toml settings.
