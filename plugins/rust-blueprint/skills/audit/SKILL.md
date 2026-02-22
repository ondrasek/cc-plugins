---
name: audit
description: Read-only gap analysis comparing a Rust project's current quality setup against the 9-dimension methodology. Use when user says "audit quality", "check coverage gaps", "what's missing", or wants to see how their project measures up before running setup.
metadata:
  version: 0.2.0
  author: Ondrej (Ondra) Krajicek, me@ondrejkrajicek.com
---

# Audit

Read-only — does not modify any files.

## Context Files

Read these files from the plugin before starting:

- `skills/setup/methodology.md` — the 9 quality dimensions (roles) to audit against
- `skills/setup/analysis-checklist.md` — what to check in the target codebase

## Workflow

### 1. Analyze Current State

Follow the same analysis steps as the setup skill (Phase 1 of `skills/setup/SKILL.md`):
- Detect Rust edition, MSRV, project structure, targets (WASM, no_std)
- Inventory existing tool configurations in `Cargo.toml`, `clippy.toml`, `rustfmt.toml`, `deny.toml`
- Check for existing hooks in `.claude/settings.json`
- Check for CI pipeline
- Check for installed cargo subcommands

### 2. Compare Against Methodology

For each of the 9 quality dimensions from `methodology.md`, check whether the role is filled by any tool:

1. **Testing & Coverage** — Is there a test suite? Is coverage measured? What's the threshold?
2. **Linting & Formatting** — Is clippy configured? Is rustfmt configured? Are lint levels set?
3. **Type Safety** — Is `unsafe_code` forbidden or audited? Are type-related clippy lints enabled?
4. **Security Analysis** — Is `cargo-audit` used? Is `cargo-deny` configured? Is there a `deny.toml`?
5. **Code Complexity** — Is `cognitive_complexity` configured in clippy? What threshold?
6. **Dead Code & Modernization** — Are dead code lints at deny level? Is `cargo-machete` used?
7. **Documentation** — Is `missing_docs` lint enabled? Does `cargo doc` build cleanly?
8. **Architecture** — Is dependency hygiene checked? Are duplicate crate versions monitored?
9. **Version Discipline** — Is there a `package.version`? Is the version semver 2.0? Is bump enforcement configured for published crates?

### 3. Check Hook Coverage

Verify Claude Code hooks are configured for each hook event from `methodology.md`:
- SessionStart → `cargo audit` + `cargo-machete` (non-blocking)
- PostToolUse (Edit|Write) → per-edit auto-format (`cargo fmt`)
- Stop → quality gate (all enabled dimensions)
- Stop → auto-commit (optional)
- PostToolUse (Bash) → semver bump enforcement (blocking, only if Dimension 9 active)

### 4. Check CI Coverage

Verify CI pipeline has a job for each enabled dimension:
- test (runner + coverage)
- lint (clippy + format)
- security (audit + deny)
- deadcode (machete)
- wasm (if WASM targets detected)
- version (semver format check)

### 5. Report

Present findings in a structured format:

```
## Audit Results

### Dimension Coverage
| Dimension | Status | Tools | Notes |
|-----------|--------|-------|-------|
| Testing & Coverage | Configured | cargo test | No coverage measurement |
| Linting & Formatting | Partial | clippy (default), rustfmt | No pedantic lints, no clippy.toml |
| Type Safety | Default | compiler | unsafe_code not explicitly forbidden |
| Security Analysis | Missing | — | No cargo-audit or cargo-deny |
| Code Complexity | Default | clippy | Using default threshold (25) |
| Dead Code | Partial | compiler | No cargo-machete for deps |
| Documentation | Missing | — | missing_docs not enabled |
| Architecture | Missing | — | No dependency hygiene checking |
| Version Discipline | Missing | — | No version validation configured |

### Hook Coverage
- [x] PostToolUse (per-edit fix)
- [ ] Stop (quality gate) — not configured
- [ ] Stop (auto-commit) — not configured
- [ ] SessionStart (dependency hygiene) — not configured

### CI Coverage
- [x] test
- [ ] lint — missing
- [ ] security — missing
- [ ] deadcode — missing

### Recommendations
1. Run `/rust-blueprint:setup` to configure missing dimensions
2. Add cargo-deny with deny.toml for license and advisory checking
3. Enable pedantic clippy lints for library crates
4. Add coverage measurement with cargo-llvm-cov
```

## Important Notes

- Compare against methodology roles, not specific tools — any tool filling the role counts
- Note where project-specific thresholds may be appropriate
- Flag outdated tools that have been superseded by better alternatives
- Report both missing dimensions and misconfigured existing tools

## Troubleshooting

**No Cargo.toml found**:
- The project may not be a Rust project. Suggest using the appropriate blueprint plugin instead.

**Hooks configured but methodology.md not found**:
- The project may have been configured manually without the plugin. Audit the hooks against the methodology principles anyway.
