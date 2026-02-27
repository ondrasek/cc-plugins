---
name: rust-setup
description: Analyzes a Rust project and configures 9-dimension quality methodology including hooks, CI, and tool configs. Use when user says "set up quality tools", "configure linting", "add CI pipeline", "rust quality", or wants to apply coding standards to a Rust project.
metadata:
  version: 1.0.0
  author: Ondrej (Ondra) Krajicek, me@ondrejkrajicek.com
---

# Rust Setup

## Critical Rules

- **Always present analysis and plan to the user before making changes**
- **Merge, don't replace** — preserve existing Cargo.toml sections, CI jobs, hooks
- **Respect the project's Rust edition and MSRV** (don't assume latest)
- All hook scripts must be executable (`chmod +x`)

## Context Files

Read these files before starting:

- `skills/shared/references/methodology-framework.md` — shared principles, hook architecture, exit codes, settings.json format
- `skills/shared/references/setup-workflow.md` — the 6-phase workflow structure
- `skills/rust-setup/references/methodology.md` — Rust-specific 9 dimensions, thresholds, tool research guidance
- `skills/rust-setup/references/analysis-checklist.md` — what to check in the target codebase
- `skills/rust-setup/templates/` — **annotated examples** showing structural patterns. Use templates for patterns but substitute the tools chosen during research.

## Workflow

Follow the 6-phase workflow from `setup-workflow.md`.

### Phase 1: Analyze

Follow `analysis-checklist.md` systematically: Rust edition, MSRV, project structure, targets (WASM, no_std), existing tools, CI, maturity.

### Phase 2: Plan

Research tools for each of the 9 dimensions. Rust-specific files to plan:
- `Cargo.toml` — `[lints]` sections
- `clippy.toml`, `rustfmt.toml`, `deny.toml`
- `.claude/hooks/` — quality-gate.sh, per-edit-fix.sh, session-start.sh, optionally auto-commit.sh
- `.claude/settings.json` — hook registrations (see methodology-framework.md for format)
- `.github/workflows/ci.yml` — CI pipeline
- `CLAUDE.md` — project instructions
- `semver-check.sh` — only when Dimension 9 is activated at level 3

Present complete plan and wait for approval.

### Phase 3: Configure

Read each template in `templates/` for the structural pattern, substitute the researched tools. Install required cargo subcommands.

### Phase 4: Review

Read `references/reviewer-prompt.md` for the full prompt template. Spawn reviewer subagent using Task tool with `subagent_type: "general-purpose"`.

### Phase 5: Verify

Run `.claude/hooks/quality-gate.sh`. Distinguish pre-existing issues from config problems.

### Phase 6: Report

Structured summary: configured dimensions, files created/modified, quality gate results, next steps.

## Troubleshooting

**Cargo subcommand not found**: Install missing tools with `cargo install <tool>`. Check `references/methodology.md` for required tools.

**WASM build fails**: Check for platform-specific code. Use `#[cfg(not(target_arch = "wasm32"))]` to gate platform-specific sections.
