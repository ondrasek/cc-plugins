# Go Quality Methodology

This document defines the quality methodology applied by the `go-blueprint` plugin. It is organized into 9 quality dimensions, each defining a **role** (what needs to happen) rather than prescribing specific tools.

The setup skill reads this document to understand what to apply, then researches current best-in-class tools to fill each role.

---

## Principles

1. **Fail fast, fix fast** — Quality checks run as Claude Code hooks. Failures block the agent and feed back for automatic fixing (exit code 2).
2. **Ordered by speed** — Checks run fastest-first so common failures surface quickly.
3. **Opinionated defaults, flexible adaptation** — Defaults reflect production-grade standards. Every dimension can be relaxed for early-stage, prototype, or legacy projects.
4. **Roles, not tools** — The methodology defines *what* to check, not *which tool*. The setup skill researches current tools to fill each role, considering the project's ecosystem and Go version.
5. **Incremental adoption** — Projects can adopt dimensions one at a time. The audit skill tracks which dimensions are active.

---

## Dimension 1: Testing & Coverage

**Role**: Verify that code changes are backed by tests. Measure and enforce test coverage thresholds.

**What the tools must do**:
- Discover and run tests (unit, integration, table-driven)
- Stop on first failure (fail-fast mode)
- Measure line coverage against a threshold
- Report uncovered lines
- Support module-wide test execution (`./...`)

**Default thresholds**:
- Minimum coverage: 80%
- Test location: `*_test.go` files alongside source

**Adaptation**:
- New project (< 500 LOC): 60%
- Legacy project adopting methodology: start at current coverage, increase incrementally
- Library module: raise to 85% (consumers depend on tested behavior)
- CLI application: 70% (hard to test interactive paths)

**Quality gate**: Run tests (fail-fast, race detector), then run coverage check against threshold.

**CI job**: `test` — run tests with coverage, upload report on PRs.

**Key commands**:
- `go test -race -coverprofile=coverage.out -covermode=atomic -count=1 -failfast -shuffle=on ./...`
- `gotestsum` wraps `go test` with better output and JUnit XML for CI
- `go-test-coverage --config=.testcoverage.yml` enforces thresholds (Go has no built-in threshold enforcement)
- `-coverpkg=./...` instruments all module packages, not just the package under test

---

## Dimension 2: Linting & Formatting

**Role**: Enforce consistent code style. Auto-detect and fix common bugs, anti-patterns, and idiomatic Go violations. Catch typos.

**What the tools must do**:
- Lint: check for style errors, unused code, unidiomatic patterns, performance anti-patterns, error handling mistakes
- Format: enforce consistent whitespace, import ordering (Go formatting is canonical and non-configurable)
- Spell check: catch typos in identifiers, strings, comments

**Default configuration**:
- golangci-lint v2 as unified lint orchestrator (`.golangci.yml`)
- `gofumpt` (stricter superset of gofmt) + `goimports` + `gci` (import ordering) as formatters
- Auto-format on every file edit (per-edit hook)
- Key linters: `revive`, `gocritic`, `errorlint`, `misspell`, `nolintlint`
- `default: standard` set: `govet`, `errcheck`, `staticcheck`, `unused`, `ineffassign`, `copyloopvar`

**Quality gate**: `golangci-lint run ./...` (covers lint) + `golangci-lint fmt --diff ./...` (covers format).

**Per-edit hook**: Auto-format with `gofumpt -w` + `goimports -w` on every `.go` file edit. Report unfixable issues back to Claude (exit 2).

**CI job**: `lint` — `golangci-lint run ./...` + `golangci-lint fmt --diff ./...`.

**Gotchas**:
- `gofmt`/`gofumpt` always exit 0 — CI must check output emptiness: `test -z "$(gofmt -l .)"`
- golangci-lint v2 requires `version: "2"` in config; `stylecheck` and `gosimple` merged into `staticcheck`
- Do not install golangci-lint with `go install` — use binary install or brew
- In v2, formatters are in a dedicated `formatters:` section, not `linters:`

---

## Dimension 3: Type Safety

**Role**: Leverage Go's type system beyond compiler checks. The compiler catches unused variables, unused imports, and type mismatches as hard errors. This dimension catches what the compiler misses.

**What the tools must do**:
- Extended static analysis beyond `go vet` (correctness, simplification, style)
- Nil pointer safety analysis
- Variable shadowing detection
- Type assertion safety (unchecked type assertions)
- Enum switch exhaustiveness

**Default configuration**:
- `staticcheck` with all checks enabled (`checks: ["all"]`) — 150+ checks
- `govet` with `enable-all: true` (disable `fieldalignment` — too noisy)
- `exhaustive` for enum switch coverage
- `forcetypeassert` for unchecked type assertions
- `errcheck` with `check-type-assertions: true`
- `errorlint` for Go 1.13+ error wrapping (`errors.Is`/`errors.As`)

**Adaptation**:
- CGo project: some vet checks may false-positive on C interop
- Untyped codebase (pre-generics): skip `exhaustive` if no type constraints used
- Framework-heavy project: add framework-specific linters (e.g., `sqlclosecheck` for database code)

**Quality gate**: Covered by `golangci-lint run ./...` with appropriate linters enabled.

**CI job**: `typecheck` — included in lint job (staticcheck + govet run inside golangci-lint).

---

## Dimension 4: Security Analysis

**Role**: Audit dependencies for known vulnerabilities. Detect security anti-patterns in source code.

**What the tools must do**:
- Vulnerability scanning: check dependencies against Go Vulnerability Database (`vuln.go.dev`)
- Pattern detection: hardcoded secrets, SQL injection, command injection, weak crypto, insecure file permissions
- Supply chain: verify module checksums against `sum.golang.org`
- License compliance: check dependency licenses

**Default configuration**:
- `govulncheck ./...` — official Go security scanner with call-graph analysis (reports only actually-reachable vulnerabilities)
- `gosec` — 40+ vulnerability pattern detectors (available as golangci-lint linter)
- `go mod verify` — checksum integrity
- `go-licenses check ./...` — license compliance (optional)

**Adaptation**:
- Web framework (gin, echo, fiber, chi): enable `bodyclose`, `noctx`, `sqlclosecheck` linters
- Library (no I/O): lighter security checking
- Corporate: strict license allowlist
- CGo project: govulncheck may fail with C headers — use `CGO_ENABLED=0` if pure-Go

**Quality gate**: `govulncheck ./...` + gosec (via golangci-lint) + `go mod verify`.

**CI job**: `security` — govulncheck + go mod verify.

**Gotchas**:
- gosec G101 (hardcoded credentials) is notorious for false positives — exclude with `gosec.excludes: [G101]`
- govulncheck JSON/SARIF modes always exit 0; text mode exits non-zero on findings
- govulncheck only analyzes one GOOS/GOARCH at a time

---

## Dimension 5: Code Complexity

**Role**: Enforce measurable cyclomatic and cognitive complexity limits to keep functions testable and maintainable.

**What the tools must do**:
- Measure cyclomatic complexity per function
- Measure cognitive complexity per function
- Fail when functions exceed threshold
- Report which functions are too complex

**Default thresholds**:
- Cyclomatic complexity: 15 per function (`gocyclo`)
- Cognitive complexity: 20 per function (`gocognit`)
- Function length: 80 lines / 50 statements (`funlen`)
- Nesting depth: 5 (`nestif`)

**Adaptation**:
- Early-stage project: accept cyclomatic ≤ 20, cognitive ≤ 30
- Legacy codebase: start at current max, tighten over time
- Table-driven test files: exclude from complexity checks (long but not complex)

**Quality gate**: Covered by `golangci-lint run ./...` with `gocyclo`, `gocognit`, `funlen`, `nestif` enabled.

**Gotchas**:
- `cyclop` and `gocyclo` use the same metric — enable one or the other, not both
- Pair cyclomatic (gocyclo) with cognitive (gocognit) for complementary measurement
- Test files need relaxed thresholds — use golangci-lint exclusions for `_test.go`

---

## Dimension 6: Dead Code & Modernization

**Role**: Detect unused code and suggest modern Go idioms.

**What the tools must do**:
- Dead code: find unused functions, types, variables (exported and unexported)
- Unused dependencies: detect modules declared in `go.mod` but not used
- Modernization: suggest idiomatic replacements for outdated patterns

**Default configuration**:
- `unused` linter (enabled by default in golangci-lint) — catches unused unexported symbols
- `deadcode -test ./...` — whole-program analysis for unused exported functions (standalone)
- `unparam` — unused function parameters
- `wastedassign` — assigned but never used values
- `modernize` linter — Go 1.26+ idiom suggestions (`any` over `interface{}`, `min`/`max` builtins, `strings.Cut`, etc.)
- `go fix -diff ./...` — Go 1.26 built-in modernizer (preview mode)
- `go mod tidy -v` — remove unused dependencies

**Adaptation**:
- Library with public API: `deadcode` can't analyze non-main packages; rely on `unused` linter
- Multi-platform: `deadcode` only analyzes one GOOS/GOARCH at a time
- Pre-Go 1.26: skip `go fix` modernizer, rely on `modernize` linter in golangci-lint

**Quality gate**: `golangci-lint run ./...` (unused, unparam, wastedassign, modernize) + `go mod tidy -diff` (Go 1.21+).

**CI job**: `deadcode` — unused dependency check + dead code analysis.

---

## Dimension 7: Documentation

**Role**: Enforce documentation on exported symbols (functions, types, methods, packages).

**What the tools must do**:
- Check for missing doc comments on exported symbols
- Enforce doc comment format (starts with declared name, ends with period)
- Check package-level documentation
- Enforce deprecation annotation format (`Deprecated:` not `DEPRECATED:`)

**Default configuration**:
- `godoclint` with `require-doc` and `require-pkg-doc` rules
- `revive` `exported` rule as backup
- `godot` — enforces periods at end of doc comments
- `staticcheck` ST1000/ST1020/ST1021/ST1022 checks

**Default thresholds**:
- Libraries: all exported symbols must have doc comments
- Applications: exported symbols in public packages only

**Adaptation**:
- Library: strict — all exported symbols must be documented
- Internal application: warn only on missing docs
- Early-stage / prototype: disable, enable later

**Quality gate**: Covered by `golangci-lint run ./...` with `godoclint`, `godot`, `revive` enabled.

**Gotchas**:
- golangci-lint v2's `comments` exclusion preset silently suppresses doc warnings — **remove it from `exclusions.presets`** if documentation enforcement is desired
- `revive` `comments-density` rule can check minimum comment-to-code ratio

---

## Dimension 8: Architecture & Import Discipline

**Role**: Enforce import boundaries between packages. Detect dependency hygiene issues.

**What the tools must do**:
- Import boundaries: allow/deny lists for package imports (`depguard`)
- Module governance: version constraints and replacement recommendations (`gomodguard`)
- Import ordering: enforce group ordering — stdlib, third-party, local module (`gci`)
- Dependency hygiene: detect unused/missing modules in `go.mod`

**Progressive activation**:

Import boundary enforcement is never configured speculatively. The quality gate drives its introduction:

1. **No import contracts defined**: the gate runs `go mod tidy -diff` for dependency hygiene and `gci` for import ordering only. Most projects start here.
2. **Deprecated import detected** → gate fails with a hint telling Claude to configure `depguard` deny rules for deprecated packages (`io/ioutil`, `math/rand`, `github.com/pkg/errors`).
3. **Contracts exist**: the gate enforces them on every run. Violations fail the gate like any other check.

**Adaptation**:
- Single-package project: import ordering only; boundaries not applicable
- Multi-package project: configure `depguard` with layer-appropriate deny rules
- Workspace (`go.work`): golangci-lint doesn't natively support workspaces — run per-module

**Quality gate**: `golangci-lint run ./...` (depguard, gomodguard, gci, importas) + `go mod verify`.

**Session start hook**: Run `go mod verify` + `govulncheck` (non-blocking warnings).

**Go-specific**: Go prevents circular imports at compile time (hard error). No linter needed for circular detection.

---

## Dimension 9: Version Discipline

**Role**: Enforce semver 2.0 on the project's version string. Detect missing version bumps when source code changes are committed.

**What the tools must do**:
- Validate the project's version string follows semver 2.0 format (MAJOR.MINOR.PATCH with optional pre-release and build metadata)
- On commit, compare the version at the branch base vs HEAD — block if source files changed but the version did not

**Progressive activation**:

Version discipline is never configured speculatively. The quality gate drives its introduction:

1. **No version constant detected**: the dimension is skipped entirely. Internal tools and scripts start here.
2. **Version constant exists, not published**: format validation only (quality gate). Catches typos and non-semver strings.
3. **Version constant + published module**: both format validation (quality gate) AND bump enforcement (PostToolUse/Bash hook on `git commit`).

Detection signals for Go:
- **Version constant**: `var Version = "..."` or `const Version = "..."` in source code
- **go.mod version path**: module paths with `/v2`, `/v3` etc. indicate published, versioned modules
- **Git tags**: presence of `v*` tags indicates release practice
- **GoReleaser config**: `.goreleaser.yml` or `.goreleaser.yaml` indicates publishing intent
- **ldflags pattern**: `-ldflags "-X main.Version=..."` in Makefile/CI indicates version injection

**Default configuration**:
- Semver 2.0 regex validation in the quality gate
- PostToolUse/Bash hook (`semver-check.sh`) that fires only on `git commit`

**Adaptation**:
- Module with major version suffix (`/v2`): validate module path matches tag prefix
- `go install`-distributed tool: version via `debug.ReadBuildInfo()` — may not have a constant
- GoReleaser-managed: version comes from git tags, not source constant — adjust extraction
- Pre-1.0 module: no special treatment — semver pre-release tags handle instability

**Quality gate**: Validate version string matches semver 2.0 regex.

**PostToolUse/Bash hook**: On `git commit`, compare version at merge-base vs HEAD. Block if source dirs changed but version is unchanged.

**CI job**: `version` — extract and validate version string format.

---

## Hook Architecture

The methodology uses four hook types:

| Hook Event | Script | Behavior | Blocking |
|-----------|--------|----------|----------|
| **SessionStart** | `session-start.sh` | `govulncheck` + `go mod verify` | No (warnings only) |
| **PostToolUse** (Edit\|Write) | `per-edit-fix.sh` | Auto-format on each `.go` file edit | Yes (exit 2 for unfixable) |
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
- Tell Claude **how to re-check** a single package after fixing (avoids re-running the full gate)
- Tell Claude **what to fix** (edit source code, not the test, unless the test is wrong)
- Are **specific to the tool** (not generic "fix the error" advice)

Example hints:
```
[go-test]   "Read the failing test and the source it tests. Run
             'go test -v -run TestName ./pkg/...' to see the full output.
             Fix the source code, not the test, unless the test itself
             is wrong."

[golangci]  "Read the file at the reported line. golangci-lint usually
             reports the linter name in brackets. Run
             'golangci-lint run ./pkg/...' to re-check a single package."

[gofumpt]   "Run 'gofumpt -w .' to auto-fix all formatting issues."
```

---

## Pre-commit Hooks

Separate from Claude Code hooks, git hooks can run on `git commit`:
- Format check (`gofumpt -l .` — non-empty output = unformatted files)
- Lint check (`golangci-lint run ./...`)

These catch issues in manual commits that bypass the Claude Code workflow.

---

## CI Pipeline Structure

The CI pipeline runs a subset of the quality gate as parallel jobs:

| Job | Dimension | Purpose |
|-----|-----------|---------|
| `test` | Testing & Coverage | Verify behavior, upload coverage |
| `lint` | Linting & Formatting + Type Safety + Complexity + Dead Code + Docs + Architecture | golangci-lint covers 6 dimensions |
| `security` | Security Analysis | govulncheck + go mod verify |
| `version` | Version Discipline | Verify semver format |

Jobs run on `push` to main and on pull requests to main.

**Note**: Unlike Rust/Python where each dimension maps to a separate CI job, Go consolidates dimensions 2, 3, 5, 6, 7, and 8 into a single `lint` job because golangci-lint orchestrates all of them through one config file and command.

---

## Tool Research

When the setup skill fills each role, it should:

1. **Check what the project already uses** — respect existing tool choices
2. **Research current best tools** (via WebSearch) for any unfilled roles, considering:
   - Compatibility with the project's Go version (`go` directive in go.mod)
   - Framework-specific support needed (web, CLI, gRPC)
   - Community adoption and maintenance status
   - Speed (quality gate runs on every stop, so tools must be fast)
   - Configuration via `.golangci.yml` (preferred single config file for 6+ dimensions)
3. **Present tool choices to the user** with rationale before configuring

---

## Go-Specific Patterns

### golangci-lint v2 as Central Config

`.golangci.yml` is the central configuration point covering dimensions 2, 3, 5, 6, 7, and 8:
- `linters:` section with `default: standard` + additional linters
- `linters.settings:` for per-linter configuration
- `formatters:` section for gofumpt, goimports, gci
- `exclusions:` for test files, generated code, vendor
- `severity:` for error vs warning classification

External config files remain necessary only for:
- `.testcoverage.yml` — coverage thresholds (go-test-coverage)
- `.goreleaser.yml` — release management (optional)
- `go.mod` — tool directives (Go 1.24+)

### Build Tags

Build tags (`//go:build integration`) control which files are compiled. Set `run.build-tags: [integration]` in `.golangci.yml` to include tagged files during linting. Without this, integration test files are invisible to analysis.

### CGo Considerations

CGo complicates tooling: golangci-lint requires compilable C headers when `CGO_ENABLED=1`, and govulncheck can fail with C import errors. Setting `CGO_ENABLED=0` in CI is standard for pure-Go projects.

### Workspaces (go.work)

golangci-lint does not natively support `go.work` — run per-module:
```bash
for dir in $(go work edit -json | jq -r '.Use[].DiskPath'); do
  (cd "$dir" && golangci-lint run ./...)
done
```

### Tool Version Management (Go 1.24+)

Go 1.24 introduced `tool` directives in `go.mod`:
```bash
go get -tool github.com/golangci/golangci-lint/v2/cmd/golangci-lint@v2.11.3
go tool golangci-lint run ./...
```

### Canonical Formatting

Unlike other languages, Go's formatter (`gofmt`) is canonical and non-configurable. `gofumpt` is a strict superset adding extra rules. All Go code must be gofmt-compatible — this is a language convention, not a preference.

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
