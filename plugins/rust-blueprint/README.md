# rust-blueprint

A Claude Code plugin that intelligently applies a Rust quality methodology to any codebase. Rather than copying config files, it analyzes your project's ecosystem, researches current best tools, and configures hooks and CI to match.

## Skills

### `/rust-blueprint:setup`

The main skill. Analyzes your Rust project and configures quality tooling:

1. **Analyze** — detects Rust edition, MSRV, project structure, targets (WASM, no_std), frameworks, existing tools
2. **Plan** — researches current best tools for each role, determines thresholds, identifies conflicts
3. **Configure** — generates/merges Cargo.toml lint sections, clippy.toml, rustfmt.toml, deny.toml, creates hooks, sets up CI
4. **Review** — spawns a reviewer subagent to audit generated config against the methodology
5. **Verify** — runs quality checks to confirm everything works
6. **Report** — summarizes changes and any manual steps needed

### `/rust-blueprint:audit`

Gap analysis — compares your project's current setup against the full methodology and reports missing or outdated configuration.

### `/rust-blueprint:update`

Incremental updates — applies methodology improvements while preserving your project-specific customizations.

### `/rust-blueprint:explain`

Read-only Q&A — answers questions about why specific tools are included, how thresholds were chosen, and what each quality dimension covers.

## Quality Methodology

The plugin applies a 9-dimension quality methodology. Each dimension defines a **role** (what needs to happen), not a specific tool. The setup skill researches and selects the best current tools at runtime.

| Dimension | Role |
|-----------|------|
| Testing & Coverage | Run tests, enforce coverage threshold |
| Linting & Formatting | Consistent style, clippy lints, auto-format on edit |
| Type Safety | Unsafe code auditing, type-related clippy lints |
| Security Analysis | Advisory audit, license compliance, dependency bans |
| Code Complexity | Cognitive complexity limits |
| Dead Code & Modernization | Unused code and dependency detection |
| Documentation | Doc comment coverage, `cargo doc` builds cleanly |
| Architecture | Module visibility, dependency hygiene, duplicate detection |

The methodology adapts to your project — adjusting tool selection, thresholds, and configuration based on project type, size, maturity, targets (WASM, no_std), and existing tooling.

## WASM Support

The plugin detects WASM targets (`wasm-bindgen`, `wasm-pack`, `wasm32-*` targets) and adapts:
- Adds `wasm-pack test` / `wasm-bindgen-test` for WASM testing
- Adds WASM build/test CI job
- Adjusts `deny.toml` for WASM-specific crates
- Adds WASM build check to quality gate

## Plugin-Level Hooks

The plugin registers a per-edit auto-format hook that runs on any project using the plugin. It runs `cargo fmt` on every Rust file edit.

## Structure

```
.claude-plugin/plugin.json   — Plugin manifest
skills/                      — Skill definitions and methodology
hooks/                       — Plugin-level hook registrations
scripts/                     — Hook scripts
```
