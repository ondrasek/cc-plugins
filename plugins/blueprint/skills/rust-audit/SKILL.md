---
name: rust-audit
description: Read-only gap analysis comparing a Rust project's current quality setup against the 9-dimension methodology. Use when user says "audit quality", "check coverage gaps", "what's missing", or wants to see how their Rust project measures up before running setup.
metadata:
  version: 1.0.0
  author: Ondrej (Ondra) Krajicek, me@ondrejkrajicek.com
---

# Rust Audit

Read-only — does not modify any files.

## Context Files

Read these files before starting:

- `skills/shared/references/audit-workflow.md` — the 5-step workflow structure
- `skills/rust-setup/references/methodology.md` — the 9 quality dimensions (roles) to audit against
- `skills/rust-setup/references/analysis-checklist.md` — what to check in the target codebase

## Workflow

Follow `audit-workflow.md`. Rust-specific details:

### 1. Analyze Current State

Detect Rust edition, MSRV, project structure (single crate vs workspace), targets (WASM, no_std). Inventory existing configurations in Cargo.toml `[lints]`, clippy.toml, rustfmt.toml, deny.toml. Check hooks, CI, installed cargo subcommands.

### 2. Compare Against Methodology

Check each of the 9 dimensions — see `methodology.md` for Rust-specific tools and thresholds.

### 3. Check Hook Coverage

Expected hooks: SessionStart (cargo audit + machete), PostToolUse/Edit|Write (cargo fmt), Stop (quality gate), PostToolUse/Bash (semver check).

### 4. Check CI Coverage

Expected jobs: test, lint, security, deadcode, version, wasm (optional).

### 5. Report

Present dimension/hook/CI coverage tables with recommendations. Suggest running `/blueprint:rust-setup` to configure missing dimensions.
