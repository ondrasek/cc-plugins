---
name: vault-update
description: Applies incremental methodology updates to an Obsidian vault previously configured with obsidian-vault plugin. Use when user says "update vault tools", "upgrade methodology", "sync with latest obsidian-vault", or after updating the plugin to get new recommendations.
metadata:
  version: 0.1.0
  author: Ondrej (Ondra) Krajicek, me@ondrejkrajicek.com
---

# Vault Update

## Context Files

- `skills/shared/references/methodology-framework.md` — shared principles, hook architecture, exit codes
- `skills/vault-setup/references/methodology.md` — current methodology (latest version)
- `skills/vault-setup/templates/` — current templates
- `skills/vault-setup/references/workflow-catalog.md` — current GitHub workflow categories

## Workflow

Follow the 6-step update workflow below. Vault-specific: preserve existing `.gitignore` customizations, hook customizations, workflow customizations, and spelling dictionary entries.

### 1. Detect Current State

Same analysis as the audit skill — inventory existing tools, hooks, CI, and configuration. Identify which methodology version was previously applied by reading existing hook scripts and config.

### 2. Identify Differences

Compare current state against the latest methodology:
- New tools recommended for unfilled roles
- Updated configurations (new frontmatter fields, updated spelling dictionaries)
- New templates (hook script improvements, workflow additions from workflow-catalog.md)
- Changed thresholds or adaptation rules
- New workflow catalog entries not yet adopted

### 3. Present Update Plan

Show the user what would change before making any modifications. Wait for approval.

### 4. Apply Updates

Apply approved changes one dimension at a time:
- Merge config changes (preserve existing `.gitignore` entries, custom spelling words, frontmatter field customizations)
- Update hook scripts (preserve custom check additions or threshold overrides)
- Update CI workflows (preserve custom job additions or workflow triggers)
- Update GitHub Actions workflows from workflow catalog if new categories apply
- Install new tools if needed

### 5. Verify

Run the quality gate to confirm no breakage. Distinguish methodology improvements from regressions.

### 6. Report

Summarize updates applied and any manual steps remaining.

## Important Notes

- Always show the update plan before making changes
- Preserve vault-specific customizations (custom frontmatter schemas, extra `.gitignore` entries, spelling dictionary additions, workflow customizations)
- If a vault has deliberately disabled a dimension, do not re-enable it
- Update one dimension at a time to make changes reviewable
