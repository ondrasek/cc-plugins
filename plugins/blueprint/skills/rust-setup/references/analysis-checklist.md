# Analysis Checklist

This checklist defines what the setup skill must analyze in a target codebase before applying the methodology. Each section feeds into tool selection, configuration, and threshold decisions.

---

## 1. Rust Edition & MSRV

**Check for**:
- [ ] `Cargo.toml` → `edition` field (2015, 2018, 2021, 2024)
- [ ] `Cargo.toml` → `rust-version` field (MSRV)
- [ ] `rust-toolchain.toml` → `channel` and `components`
- [ ] `clippy.toml` → `msrv` field

**Impact**: Sets edition in `rustfmt.toml`, determines available lint groups in `[lints]`, affects which clippy lints are applicable, determines if `[lints]` section is available (requires Rust 1.74+).

---

## 2. Project Structure

**Check for**:
- [ ] Single crate (`Cargo.toml` at root, `src/` directory)
- [ ] Workspace (`[workspace]` in root `Cargo.toml`, `members` list)
- [ ] Binary crate (`src/main.rs`)
- [ ] Library crate (`src/lib.rs`)
- [ ] Mixed binary + library
- [ ] `tests/` directory (integration tests)
- [ ] `benches/` directory (benchmarks)
- [ ] `examples/` directory

**Impact**: Determines `${WORKSPACE_FLAG}` (empty vs `--workspace`), per-crate vs workspace lint configuration, test discovery paths, coverage source directories.

---

## 3. Target Detection

**Check for**:
- [ ] `.cargo/config.toml` → `[build]` target
- [ ] `.cargo/config.toml` → `[target.*]` sections
- [ ] `Cargo.toml` → `[package.metadata.wasm-pack]`
- [ ] `wasm-pack` in dev dependencies or as installed tool
- [ ] `wasm-bindgen` in dependencies → WASM target
- [ ] `web-sys` or `js-sys` in dependencies → browser WASM
- [ ] `wasi` in dependencies → WASI target
- [ ] `#![no_std]` in `src/lib.rs` or `src/main.rs` → embedded/no_std
- [ ] Cross-compilation targets in CI

**Impact**:
- WASM: add `wasm-pack test`, WASM build check in CI, WASM-specific deny.toml entries
- `no_std`: cannot forbid unsafe, adjust complexity thresholds, skip some clippy lints
- Embedded: different test strategy, no coverage

---

## 4. Framework / Ecosystem Detection

**Check for** (in `Cargo.toml` dependencies):
- [ ] `actix-web` or `axum` or `rocket` → web framework
- [ ] `tokio` or `async-std` → async runtime
- [ ] `serde` → serialization
- [ ] `clap` → CLI application
- [ ] `sqlx` or `diesel` → database
- [ ] `tonic` or `prost` → gRPC
- [ ] `tracing` or `log` → logging framework
- [ ] `wasm-bindgen` → WASM interop
- [ ] No framework → pure library or utility

**Impact**:
- Web framework: enable security-focused clippy lints, framework-specific testing patterns
- Async: ensure clippy async lints are enabled
- CLI (clap): documentation on CLI args, integration test patterns
- Library: raise coverage threshold, raise documentation requirements
- WASM: adjust quality gate for dual-target testing

---

## 5. Existing Tool Configuration

**Check `Cargo.toml` for existing sections**:
- [ ] `[lints.rust]` — existing Rust lint config
- [ ] `[lints.clippy]` — existing clippy lint config
- [ ] `[workspace.lints]` — workspace-level lint config
- [ ] `[profile.dev]` / `[profile.release]` — build profiles
- [ ] `[features]` — feature flags affecting compilation

**Check for standalone config files**:
- [ ] `clippy.toml` or `.clippy.toml` — clippy configuration
- [ ] `rustfmt.toml` or `.rustfmt.toml` — rustfmt configuration
- [ ] `deny.toml` — cargo-deny configuration
- [ ] `rust-toolchain.toml` — toolchain pinning
- [ ] `.cargo/config.toml` — cargo configuration

**Impact**: Merge methodology config into existing config; don't overwrite user customizations. Respect existing lint levels and tool choices.

---

## 6. Existing CI/CD

**Check for**:
- [ ] `.github/workflows/*.yml` — GitHub Actions
- [ ] `.gitlab-ci.yml` — GitLab CI
- [ ] `.circleci/config.yml` — CircleCI
- [ ] `Jenkinsfile` — Jenkins
- [ ] `.travis.yml` — Travis CI

**Impact**: If CI exists, merge quality checks into existing pipeline rather than overwriting. If no CI, create `.github/workflows/ci.yml`.

---

## 7. Existing Claude Code Configuration

**Check for**:
- [ ] `.claude/settings.json` — existing hooks, permissions, statusline
- [ ] `.claude/hooks/` — existing hook scripts
- [ ] `CLAUDE.md` — existing project instructions

**Impact**: Merge hooks into existing settings.json. Don't overwrite existing CLAUDE.md — append methodology reference.

---

## 8. Project Maturity Signals

**Assess**:
- [ ] Git history length (commits, age)
- [ ] Lines of code (approximate via `find src/ -name '*.rs' | xargs wc -l`)
- [ ] Number of test functions (`#[test]` count)
- [ ] Existing coverage percentage (if coverage tooling is configured)
- [ ] Number of crates in workspace
- [ ] README quality

**Impact**: Determines initial thresholds:
| Signal | Coverage | Documentation | Complexity |
|--------|----------|---------------|------------|
| New (< 500 LOC) | 60% | warn | 35 |
| Small (500–5k LOC) | 70% | warn | 30 |
| Medium (5k–50k LOC) | 75% | warn | 25 |
| Large (50k+ LOC) | 75% | warn | 25 |
| Library | 85% | deny | 25 |

---

## 9. Installed Tooling

**Check for installed cargo subcommands**:
- [ ] `cargo clippy` — usually bundled with rustup
- [ ] `cargo fmt` — usually bundled with rustup
- [ ] `cargo nextest` — modern test runner (faster, better output)
- [ ] `cargo-llvm-cov` — source-based code coverage
- [ ] `cargo-audit` — RustSec advisory database
- [ ] `cargo-deny` — license, advisory, ban, duplicate checks
- [ ] `cargo-machete` — unused dependency detection

**Impact**: Determine which tools need to be installed. Prefer `cargo nextest` over `cargo test` if available. Use `cargo-llvm-cov` for coverage.

---

## 10. Version & Packaging

**Check for**:
- [ ] `Cargo.toml` → `package.version` field
- [ ] Workspace root `Cargo.toml` → `workspace.package.version`
- [ ] Member `Cargo.toml` → `version.workspace = true` (inherits from workspace)
- [ ] `Cargo.toml` → `publish = false` or `publish = []` (not published to crates.io)
- [ ] `Cargo.toml` → `[package.metadata]` with publishing-related keys
- [ ] Multiple crates with independent versions (workspace without `version.workspace`)

**Impact**: Determines Dimension 9 activation level:
| Signal | Activation |
|--------|-----------|
| No version field | Dimension skipped |
| Version field + `publish = false` | Format validation only (quality gate) |
| Version field + published (no `publish = false`) | Format validation + bump enforcement |
| `version.workspace = true` | Check workspace root version |

**Record**: Version source, version value, publish status, workspace inheritance.

---

## Analysis Output Format

After analysis, the setup skill should produce a structured summary:

```
Rust edition: 2024
MSRV: 1.85.0
Project structure: workspace (3 crates)
Targets: native + wasm32-unknown-unknown
Framework: axum (async web), tokio runtime
Project size: ~5,000 LOC, 85 test functions
Existing tools: clippy (default config), rustfmt (default)
Missing dimensions: security, dead code (deps), documentation, coverage
CI: GitHub Actions (test + lint jobs exist)
WASM: wasm-bindgen detected, needs wasm-pack test job
```

This summary drives the plan phase, where the skill selects which dimensions to configure and how.
