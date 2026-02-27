# Rust Quality Methodology

This document defines the quality methodology applied by the `rust-blueprint` plugin. It is organized into 9 quality dimensions, each defining a **role** (what needs to happen) rather than prescribing specific tools.

The setup skill reads this document to understand what to apply, then researches current best-in-class tools to fill each role.

---

## Principles

1. **Fail fast, fix fast** — Quality checks run as Claude Code hooks. Failures block the agent and feed back for automatic fixing (exit code 2).
2. **Ordered by speed** — Checks run fastest-first so common failures surface quickly.
3. **Opinionated defaults, flexible adaptation** — Defaults reflect production-grade standards. Every dimension can be relaxed for early-stage, prototype, or legacy projects.
4. **Roles, not tools** — The methodology defines *what* to check, not *which tool*. The setup skill researches current tools to fill each role, considering the project's ecosystem and Rust edition.
5. **Incremental adoption** — Projects can adopt dimensions one at a time. The audit skill tracks which dimensions are active.

---

## Dimension 1: Testing & Coverage

**Role**: Verify that code changes are backed by tests. Measure and enforce test coverage thresholds.

**What the tool must do**:
- Discover and run tests (unit, integration, doc tests)
- Stop on first failure (fail-fast mode)
- Measure line coverage against a threshold
- Report uncovered lines
- Support workspace-aware test execution

**Default thresholds**:
- Minimum coverage: 75%
- Test location: inline `#[cfg(test)]` modules + `tests/` directory

**Adaptation**:
- New project (< 500 LOC): 60%
- Legacy project adopting methodology: start at current coverage, increase incrementally
- Library crate: raise to 85% (consumers depend on tested behavior)
- WASM crate: include `wasm-pack test` / `wasm-bindgen-test` for browser/Node targets

**Quality gate**: Run tests (fail-fast), then run coverage check against threshold.

**CI job**: `test` — run tests with coverage, upload report on PRs. Add WASM test job if WASM targets detected.

---

## Dimension 2: Linting & Formatting

**Role**: Enforce consistent code style. Auto-detect and fix common bugs, anti-patterns, and idiomatic Rust violations.

**What the tools must do**:
- Lint: check for style errors, common mistakes, unidiomatic patterns, unnecessary code, performance anti-patterns
- Format: enforce consistent whitespace, import ordering, brace style

**Default configuration**:
- `clippy.toml` with project-specific settings
- `rustfmt.toml` with edition-appropriate defaults
- Auto-format on every file edit (per-edit hook)
- Clippy pedantic lints enabled for libraries, warn-level for applications

**Quality gate**: `cargo clippy` (deny warnings) + `cargo fmt --check`.

**Per-edit hook**: Auto-format on every `.rs` file edit. Report unfixable issues back to Claude (exit 2).

**CI job**: `lint` — clippy check + format check.

---

## Dimension 3: Type Safety

**Role**: Leverage Rust's type system to its fullest. The compiler provides inherent type safety; this dimension ensures unsafe code is minimized and clippy's type-related lints are active.

**What the tools must do**:
- Enforce `#![forbid(unsafe_code)]` where appropriate (pure-safe crates)
- Enable clippy unsafe lints for crates that need `unsafe`
- Configure `[lints]` in Cargo.toml for type-related warnings

**Default configuration**:
- `forbid(unsafe_code)` for application crates and safe library crates
- `unsafe_op_in_unsafe_fn` lint for crates that require `unsafe`
- Clippy `unsafe` lint group enabled

**Adaptation**:
- FFI/interop crate: cannot forbid unsafe; use clippy `undocumented_unsafe_blocks` instead
- WASM crate with JS interop: relax unsafe restrictions for `wasm-bindgen` generated code
- `no_std` crate: may need limited unsafe for low-level operations

**Quality gate**: Build with configured lint levels (Cargo.toml `[lints]` section).

**CI job**: `typecheck` — included in build/clippy job with strict lint levels.

---

## Dimension 4: Security Analysis

**Role**: Audit dependencies for known vulnerabilities. Enforce license compliance and detect duplicate/banned dependencies.

**What the tools must do**:
- Audit: check dependencies against the RustSec advisory database
- Deny: enforce license allowlist, detect duplicate crate versions, ban specific crates
- Supply chain: detect yanked crates, unmaintained dependencies

**Default configuration**:
- `deny.toml` with advisories, licenses, bans, and sources sections
- License allowlist: MIT, Apache-2.0, BSD-2-Clause, BSD-3-Clause, ISC, Zlib, Unicode-3.0
- Ban duplicate crate versions (warn, not deny — duplicates are common in Rust)

**Adaptation**:
- Corporate: strict license allowlist, no copyleft
- Open source: permissive license checking
- WASM: include `wasm-bindgen`, `js-sys`, `web-sys` in trusted sources

**Quality gate**: `cargo audit` + `cargo deny check`.

**CI job**: `security` — advisory audit + deny check.

---

## Dimension 5: Code Complexity

**Role**: Enforce measurable cognitive complexity limits to keep functions testable and maintainable.

**What the tool must do**:
- Measure cognitive complexity per function
- Fail when functions exceed threshold
- Report which functions are too complex

**Default thresholds**:
- No function above cognitive complexity 25 (clippy default)

**Adaptation**:
- Early-stage project: accept complexity ≤ 35 temporarily
- Legacy codebase: start at current max, tighten over time
- Macro-heavy code: may need higher threshold for generated code

**Quality gate**: clippy `cognitive_complexity` lint configured in `clippy.toml`.

---

## Dimension 6: Dead Code & Modernization

**Role**: Detect unused code and unused dependencies.

**What the tools must do**:
- Dead code: Rust compiler's built-in `dead_code`, `unused_imports`, `unused_variables` lints (deny level)
- Unused dependencies: detect crate dependencies declared in Cargo.toml but not used in source

**Default configuration**:
- `dead_code` = "deny" in Cargo.toml `[lints.rust]`
- `unused_imports` = "deny"
- `unused_variables` = "deny"
- `cargo-machete` for unused dependency detection

**Adaptation**:
- Library with public API: `dead_code` may flag public items not used within the crate; adjust with `#[allow]` on public API or use `unreachable_pub` lint instead
- Workspace: run `cargo-machete` per workspace member

**Quality gate**: Build with deny-level dead code lints + `cargo-machete` check.

**CI job**: `deadcode` — build with strict lints + machete check.

---

## Dimension 7: Documentation

**Role**: Enforce documentation on public items.

**What the tool must do**:
- Enforce `missing_docs` lint on public functions, types, modules
- Verify doc examples compile and pass (`cargo test --doc`)
- Build documentation without warnings (`cargo doc --no-deps`)

**Default thresholds**:
- Libraries: `#![warn(missing_docs)]` (all public items)
- Applications: `missing_docs` on public modules only

**Adaptation**:
- Library: `#![deny(missing_docs)]` — consumers depend on documentation
- Internal application: warn only
- Early-stage / prototype: disable, enable later
- WASM library: ensure `wasm-bindgen` exported functions are documented

**Quality gate**: Build with `missing_docs` lint + `cargo doc` (deny warnings).

---

## Dimension 8: Architecture & Import Discipline

**Role**: Enforce module visibility boundaries. Detect dependency hygiene issues.

**What the tools must do**:
- Module visibility: leverage Rust's `pub(crate)`, `pub(super)` visibility modifiers
- Dependency hygiene: detect unused dependencies (`cargo-machete`), duplicate crate versions (`cargo deny`)
- Workspace structure: verify workspace member dependencies are consistent

**Progressive activation**:

Architecture enforcement in Rust is largely handled by the module system and visibility modifiers. The quality gate drives refinement:

1. **No explicit boundaries defined**: the gate runs `cargo-machete` for unused deps and `cargo deny` for duplicates. Most projects start here.
2. **Dependency issue detected** → gate fails with a hint telling Claude to clean up Cargo.toml and use appropriate visibility modifiers.
3. **Workspace with multiple crates**: enforce consistent dependency versions across workspace members.

**Adaptation**:
- Single-crate project: dependency hygiene only; visibility is handled by the module system
- Workspace: inter-crate dependency analysis, shared dependency versions via workspace inheritance
- Monorepo: per-crate analysis

**Quality gate**: `cargo-machete` (unused deps) + `cargo deny check` (duplicates, advisories).

**Session start hook**: Run `cargo audit` + `cargo-machete` (non-blocking warnings).

---

## Dimension 9: Version Discipline

**Role**: Enforce semver 2.0 on the project's version string. Detect missing version bumps when source code changes are committed.

**What the tools must do**:
- Validate the project's version string follows semver 2.0 format (MAJOR.MINOR.PATCH with optional pre-release and build metadata)
- On commit, compare the version at the branch base vs HEAD — block if source files changed but the version did not

**Progressive activation**:

Version discipline is never configured speculatively. The quality gate drives its introduction:

1. **No version field detected**: the dimension is skipped entirely. Internal tools and examples start here.
2. **Version field exists, not published**: format validation only (quality gate). Catches typos and non-semver strings.
3. **Version field + published crate**: both format validation (quality gate) AND bump enforcement (PostToolUse/Bash hook on `git commit`).

Detection signals for Rust:
- **Version field**: `package.version` in `Cargo.toml`; `workspace.package.version` in workspace root
- **Published crate**: absence of `publish = false` in `[package]` section
- **Workspace inheritance**: `version.workspace = true` in member crate → check workspace root `Cargo.toml` instead
- **Not published**: `publish = false` or `publish = []` → skip bump enforcement

**Default configuration**:
- Semver 2.0 regex validation in the quality gate
- PostToolUse/Bash hook (`semver-check.sh`) that fires only on `git commit`

**Adaptation**:
- Workspace with `version.workspace = true`: single check against workspace root version
- Workspace with per-crate versions: one check per published crate
- `publish = false` crates: skip bump enforcement, keep format validation
- Pre-1.0 crate: no special treatment — semver pre-release tags handle instability

**Quality gate**: Validate version string matches semver 2.0 regex.

**PostToolUse/Bash hook**: On `git commit`, compare version at merge-base vs HEAD. Block if source dirs changed but version is unchanged.

**CI job**: `version` — extract and validate version string format.

---

## Hook Architecture

The methodology uses four hook types:

| Hook Event | Script | Behavior | Blocking |
|-----------|--------|----------|----------|
| **SessionStart** | `session-start.sh` | `cargo audit` + `cargo-machete` | No (warnings only) |
| **PostToolUse** (Edit\|Write) | `per-edit-fix.sh` | Auto-format on each `.rs` file edit | Yes (exit 2 for unfixable) |
| **Stop** | `quality-gate.sh` | Full quality gate (all enabled dimensions) | Yes (exit 2 → Claude fixes) |
| **Stop** | `auto-commit.sh` | Auto-commit and push if quality gate passes | No (push failure is non-blocking) |
| **PostToolUse** (Bash) | `semver-check.sh` | Block commits where source changed but version was not bumped | Yes (exit 2 for unbumped) |

### Fail-Fast Design

The quality gate runs checks **sequentially and stops at the first failure**. It does NOT collect all errors and report them at once. This is intentional:

- Claude fixes one issue at a time, then the gate re-runs
- Prevents "lost in the middle" — a long list of errors causes Claude to skip or half-fix items
- Each re-run confirms the previous fix didn't introduce new issues
- Faster feedback: common failures (tests, lint) are checked first

### Hook Output as Prompt

Hook stderr is fed directly to Claude as a prompt. The output must be structured to work well as an instruction, not just as a log message. Every failure output has three parts:

1. **What failed** — the check name and command that was run
2. **Tool output** — the raw error from the tool (file paths, line numbers, error codes)
3. **Diagnostic hint** — a specific instruction telling Claude how to investigate and fix this type of failure

The output ends with an **action directive** that tells Claude to fix the issue immediately rather than explain or stop.

### Output Examples

**Good** — a quality gate failure for clippy:
```
QUALITY GATE FAILED [clippy]:
Command: cargo clippy ${WORKSPACE_FLAG} -- -D warnings

error: redundant clone
  --> src/lib.rs:42:18
   |
42 |     let name = s.clone();
   |                  ^^^^^^^^ help: remove this
   |

Hint: Read the file at the reported line number. Clippy errors usually have
a suggested fix in the help message. Apply the suggestion or restructure the
code. Run 'cargo clippy -p <crate-name>' to re-check a single crate.

ACTION REQUIRED: You MUST fix the issue shown above. Do NOT stop or
explain — read the failing file, edit the source code to resolve it,
and the quality gate will re-run automatically.
```

**Good** — a per-edit hook reporting a format issue:
```
Per-edit check found issues in src/lib.rs:
FORMAT (cargo fmt):
Diff in src/lib.rs at line 15
```

**Bad** — a wall of text with multiple failures (do NOT do this):
```
ERROR: 47 issues found
warning: unused import `std::io::Read`
warning: unused variable `x`
warning: function `process` is too complex
... (43 more lines)
```

### Exit Code Convention

| Exit Code | Meaning | Claude Behavior |
|-----------|---------|-----------------|
| 0 | All checks passed | Claude proceeds normally |
| 1 | Error (script bug, tool not found) | Claude sees error but is not forced to fix |
| 2 | Check failed — stderr is a fix instruction | Claude reads stderr and must fix the issue, then the hook re-runs |

Exit code 2 is the key mechanism. It turns the hook into a feedback loop: fail → Claude fixes → hook re-runs → repeat until clean.

### Hint Writing Guidelines

Each tool check should have a diagnostic hint. Good hints:

- Tell Claude **which file to read** (use the paths from the tool output)
- Tell Claude **how to re-check** a single crate after fixing (avoids re-running the full gate)
- Tell Claude **what to fix** (edit source code, not the test, unless the test is wrong)
- Are **specific to the tool** (not generic "fix the error" advice)

Example hints:
```
[cargo test]    "Read the failing test and the source it tests. Run
                 'cargo test -p <crate> <test_name> -- --nocapture' to see
                 the full output. Fix the source code, not the test, unless
                 the test itself is wrong."

[clippy]        "Read the file at the reported line. Clippy usually suggests
                 a fix in the help message. Apply the suggestion. Run
                 'cargo clippy -p <crate>' to re-check a single crate."

[cargo fmt]     "Run 'cargo fmt' to auto-fix all formatting issues."
```

---

## Pre-commit Hooks

Separate from Claude Code hooks, git hooks can run on `git commit`:
- Format check (`cargo fmt --check`)
- Clippy check (`cargo clippy -- -D warnings`)

These catch issues in manual commits that bypass the Claude Code workflow.

---

## CI Pipeline Structure

The CI pipeline runs a subset of the quality gate as parallel jobs:

| Job | Dimension | Purpose |
|-----|-----------|---------|
| `test` | Testing & Coverage | Verify behavior, upload coverage |
| `lint` | Linting & Formatting | Clippy + format check |
| `security` | Security Analysis | Advisory audit + deny check |
| `deadcode` | Dead Code | Unused dependency check |
| `version` | Version Discipline | Verify semver format |
| `wasm` | WASM (optional) | Build + test WASM targets |

Jobs run on `push` to main and on pull requests to main.

---

## Tool Research

When the setup skill fills each role, it should:

1. **Check what the project already uses** — respect existing tool choices
2. **Research current best tools** (via WebSearch) for any unfilled roles, considering:
   - Compatibility with the project's Rust edition and MSRV
   - Target-specific support needed (WASM, embedded, no_std)
   - Community adoption and maintenance status
   - Speed (quality gate runs on every stop, so tools must be fast)
   - Configuration via `Cargo.toml` `[lints]` section (preferred over crate-level attributes)
3. **Present tool choices to the user** with rationale before configuring

---

## WASM-Specific Considerations

When a project targets WASM (`wasm32-unknown-unknown`, `wasm32-wasip1`, `wasm32-wasip2`):

1. **Detection**: Check for `wasm-pack` config, `wasm-bindgen` in dependencies, `wasm32-*` in `.cargo/config.toml` targets or `Cargo.toml` metadata
2. **Testing**: Add `wasm-pack test` or `wasm-bindgen-test` for browser/Node targets
3. **CI**: Add WASM build/test job with appropriate target triple
4. **Coverage**: `cargo-llvm-cov` supports WASM targets with `--target` flag
5. **Quality gate**: Add WASM build check (`cargo build --target wasm32-unknown-unknown`)
6. **Security**: Include WASM-specific crates (`wasm-bindgen`, `js-sys`, `web-sys`) in trusted sources

---

## Rust-Specific Patterns

### Cargo.toml `[lints]` Section

Modern Rust (1.74+, edition 2021+) supports lint configuration in Cargo.toml:
```toml
[lints.rust]
unsafe_code = "forbid"
dead_code = "deny"
unused_imports = "deny"

[lints.clippy]
pedantic = { level = "warn", priority = -1 }
cognitive_complexity = "warn"
```
This is preferred over crate-level `#![allow/warn/deny/forbid]` attributes.

### Workspace Inheritance

Workspace projects should use workspace-level lint configuration:
```toml
# In workspace root Cargo.toml
[workspace.lints.rust]
unsafe_code = "forbid"

# In member Cargo.toml
[lints]
workspace = true
```

### Cargo.toml as Central Config

Cargo.toml is the central configuration point:
- `[lints]` for compiler and clippy lint levels
- `[profile.dev]` / `[profile.release]` for build settings
- `[workspace]` for multi-crate projects
- Dependencies, features, targets all in one place

---

## Claude Code Hygiene

These checks target the Claude Code development environment itself — project instructions, hooks, and agent configuration. Unlike the 9 code quality dimensions, these ensure the AI-assisted workflow is correctly set up and efficient.

**Sources**: Boris Cherny (creator of Claude Code) internal workflow recommendations; official Anthropic Claude Code best practices.

---

### CC1: Project Instructions (CLAUDE.md)

**Role**: Keep CLAUDE.md concise, actionable, and focused so Claude follows every instruction reliably.

**Why this matters**: Boris Cherny's team found that keeping CLAUDE.md to ~100 lines (≈2500 tokens) produces dramatically better results than longer files. Bloated instructions cause Claude to ignore important rules — they get lost in noise. For each line, ask: "Would removing this cause Claude to make mistakes?" If not, cut it.

**What to check**:
- Total size ≤ 2500 tokens (including content pulled in via `@path` imports and all rule files under `.claude/rules/`)
- No self-evident instructions ("write clean code", "follow best practices")
- No information Claude can infer by reading the code
- No file-by-file codebase descriptions or tutorials (link to docs instead)
- Includes required operational content: build/test commands, non-obvious conventions, environment quirks

**Default threshold**: 2500 tokens

---

### CC2: Hook & Script Hygiene

**Role**: Ensure Claude Code hooks are correctly configured so the feedback loop works reliably.

**What to check**:
- All registered hook scripts exist and are executable (`chmod +x`)
- Exit codes follow convention: 0 (pass), 2 (fail with feedback). Never exit 1 for check failures — exit 1 logs the error but doesn't force Claude to fix it
- Matchers are case-sensitive correct (`Edit|Write` not `edit|write`, `Bash` not `bash`)
- Scripts use `${CLAUDE_PROJECT_DIR}` or `${CLAUDE_PLUGIN_ROOT}` for paths, not hardcoded absolute paths
- Timeouts are appropriate: quality gate ≥ 120s for large projects, per-edit ≤ 30s
- No hooks sourced from untrusted origins

---

### CC3: Context Efficiency

**Role**: Keep skills, prompts, and configuration right-sized to preserve Claude's context window.

**What to check**:
- Skill SKILL.md files ≤ 500 lines (move detailed reference to separate files)
- Subagent prompts are scoped to a single responsibility
- Heavy reference material uses progressive disclosure: metadata → SKILL.md body → `references/` subdirectory
- Agent definitions in `agents/` include focused `description` and `tools` restrictions
