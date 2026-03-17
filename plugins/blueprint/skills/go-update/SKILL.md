---
name: go-update
description: Applies incremental methodology updates to a Go project previously configured with blueprint. Use when user says "update quality tools", "upgrade methodology", "sync with latest blueprint", or after updating the plugin to get new tool recommendations and configs.
metadata:
  version: 1.0.0
  author: Tomas (Tom) Grbalik, tomas.grbalik@gmail.com & Anthropic Opus
---

# Go Update

## Context Files

- `skills/shared/references/update-workflow.md` — the 6-step workflow structure
- `skills/go-setup/references/methodology.md` — current methodology (latest version)
- `skills/go-setup/templates/` — current templates

## Workflow

Follow `update-workflow.md`. Go-specific: preserve `.golangci.yml` customizations (custom linter settings, exclusion rules, severity overrides), `.testcoverage.yml` thresholds, and `go.mod` tool directive versions.
