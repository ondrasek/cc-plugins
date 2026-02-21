---
name: update
description: Applies incremental methodology updates to a Rust project previously configured with rust-blueprint. Use when user says "update quality tools", "upgrade methodology", "sync with latest blueprint", or after updating the plugin to get new tool recommendations and configs.
metadata:
  version: 0.1.0
  author: ondrasek
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
- **Updated configs** — default configurations that have changed (new clippy lints, updated deny.toml, etc.)
- **New templates** — hook scripts or CI jobs that have been improved
- **Threshold changes** — recommended thresholds that have been adjusted

### 3. Present Update Plan

Show the user what would change:

```
## Available Updates

### New Tools
- cargo-machete — added for unused dependency detection
  Would add: machete check to quality gate and CI

### Configuration Updates
- clippy.toml: msrv 1.80.0 → 1.85.0
- deny.toml: added Unicode-3.0 to license allowlist
- Cargo.toml [lints.clippy]: add pedantic group at warn level

### Template Updates
- quality-gate.sh: improved error hints for cargo-deny
- ci.yml: added deadcode job

### No Changes Needed
- rustfmt.toml is current
- cargo-audit configuration is current
- Coverage threshold matches recommendation
```

Wait for user approval before proceeding.

### 4. Apply Updates

For each approved update:

1. **Merge config changes** — Update `Cargo.toml`, `clippy.toml`, `deny.toml`, preserving project-specific customizations
2. **Update hook scripts** — Regenerate from templates with project-specific variables
3. **Update CI pipeline** — Add new jobs, update existing job commands
4. **Install new tools** — Run `cargo install` for any new cargo subcommands

### 5. Verify

Run the quality gate to ensure updates don't break anything.

### 6. Report

Summarize what was updated and any manual steps needed.

## Important Notes

- Always show the update plan before making changes
- Preserve project-specific customizations (custom thresholds, extra lints, deny.toml exceptions)
- If a project has deliberately disabled a dimension, don't re-enable it
- Update one dimension at a time to make changes reviewable

## Troubleshooting

**Project was not configured with rust-blueprint**:
- Run `/rust-blueprint:audit` first to understand current state, then suggest `/rust-blueprint:setup` instead.

**Quality gate fails after update**:
- The update may have tightened thresholds or added new checks. Distinguish new failures from regressions. Roll back individual changes if needed.
