---
name: go-setup
description: Analyzes a Go project and configures 9-dimension quality methodology including hooks, CI, and tool configs. Use when user says "set up quality tools", "configure linting", "add CI pipeline", "go quality", or wants to apply coding standards to a Go project.
metadata:
  version: 1.0.0
  author: Ondrej (Ondra) Krajicek, me@ondrejkrajicek.com
---

# Go Setup

## Critical Rules

- **Always present analysis and plan to the user before making changes**
- **Merge, don't replace** — preserve existing .golangci.yml settings, go.mod tool directives, CI jobs, hooks
- **Respect the project's Go version** (`go` directive in go.mod — don't assume latest)
- All hook scripts must be executable (`chmod +x`)
- golangci-lint v2 requires `version: "2"` in config — do NOT generate v1 syntax

## Context Files

Read these files before starting:

- `skills/shared/references/methodology-framework.md` — shared principles, hook architecture, exit codes, settings.json format
- `skills/shared/references/setup-workflow.md` — the 6-phase workflow structure
- `skills/go-setup/references/methodology.md` — Go-specific 9 dimensions, thresholds, tool research guidance
- `skills/go-setup/references/analysis-checklist.md` — what to check in the target codebase
- `skills/go-setup/templates/` — **annotated examples** showing structural patterns. Use templates for patterns but substitute the tools chosen during research.

## Workflow

Follow the 6-phase workflow from `setup-workflow.md`.

### Phase 1: Analyze

Follow `analysis-checklist.md` systematically: Go version, project structure, build constraints (CGo, tags), frameworks, existing tools (check for golangci-lint v1 vs v2), CI, maturity. **Also check host environment**: is `gcc` available? (needed for `-race` flag even in pure-Go projects).

### Phase 2: Plan

Research tools for each of the 9 dimensions. Go-specific files to plan:
- `.golangci.yml` — unified config for dimensions 2, 3, 5, 6, 7, 8
- `.testcoverage.yml` — coverage thresholds
- `.claude/hooks/` — quality-gate.sh, per-edit-fix.sh, session-start.sh, optionally auto-commit.sh
- `.claude/settings.json` — hook registrations (see methodology-framework.md for format)
- `.github/workflows/ci.yml` — CI pipeline
- `CLAUDE.md` — project instructions
- `semver-check.sh` — only when Dimension 9 is activated at level 3

Present complete plan and wait for approval.

### Phase 3: Configure

Read each template in `templates/` for the structural pattern, substitute the researched tools. Install required tools:
- Binary install for golangci-lint (NOT `go install`)
- `go install` for gotestsum, go-test-coverage, govulncheck, gofumpt, goimports, deadcode
- Or use `go.mod` tool directives for Go 1.24+ — if adding tool directives via `go get -tool`, **run `go mod tidy` immediately after** to clean up transitive dependencies

After writing `.golangci.yml`, run a **dry-run lint check** (`golangci-lint run --fix=false ./...`) to catch config errors (invalid linter flags, unknown settings) before proceeding. Fix any config issues before Phase 4.

Add `.gitignore` entries for generated artifacts — see `templates/gitignore-entries.txt`.

### Phase 4: Review

Read `references/reviewer-prompt.md` for the full prompt template. Spawn reviewer subagent using Task tool with `subagent_type: "general-purpose"`.

### Phase 5: Verify

Run `.claude/hooks/quality-gate.sh`. Distinguish pre-existing issues from config problems.

### Phase 6: Report

Structured summary: configured dimensions, files created/modified, quality gate results, next steps.

## Troubleshooting

**golangci-lint v1 config detected**: Run `golangci-lint migrate` to auto-convert to v2 format before merging methodology config.

**CGo build failures in CI**: Set `CGO_ENABLED=0` for pure-Go projects. If CGo is required, ensure CI has C compiler toolchain.

**Workspace (go.work) projects**: golangci-lint must run per-module. Generate a loop in quality-gate.sh and CI.

**Race detector fails (gcc not found)**: The `-race` flag requires CGo and a C compiler. On WSL2, Alpine, or minimal containers without gcc, either install `gcc` (`apt install build-essential`) or remove `-race` from quality-gate.sh and CI. The setup skill should detect this in Phase 1 and warn.

**Coverage includes test files**: Use `-coverpkg=./...` to control which packages are instrumented.
