---
name: go-audit
description: Read-only gap analysis comparing a Go project's current quality setup against the 9-dimension methodology. Use when user says "audit quality", "check coverage gaps", "what's missing", or wants to see how their Go project measures up before running setup.
metadata:
  version: 1.0.0
  author: Ondrej (Ondra) Krajicek, me@ondrejkrajicek.com
---

# Go Audit

Read-only — does not modify any files.

## Context Files

Read these files before starting:

- `skills/shared/references/audit-workflow.md` — the 5-step workflow structure
- `skills/go-setup/references/methodology.md` — the 9 quality dimensions (roles) to audit against
- `skills/go-setup/references/analysis-checklist.md` — what to check in the target codebase

## Workflow

Follow `audit-workflow.md`. Go-specific details:

### 1. Analyze Current State

Detect Go version, project structure (single module vs workspace), build constraints (CGo, build tags). Inventory existing configurations in `.golangci.yml`, `.testcoverage.yml`, `go.mod` tool directives. Check hooks, CI, installed tools (verify golangci-lint v1 vs v2).

### 2. Compare Against Methodology

Check each of the 9 dimensions — see `methodology.md` for Go-specific tools and thresholds.

### 3. Check Hook Coverage

Expected hooks: SessionStart (govulncheck + go mod verify), PostToolUse/Edit|Write (gofumpt + goimports), Stop (quality gate), PostToolUse/Bash (semver check).

### 4. Check CI Coverage

Expected jobs: test, lint (covers 6 dimensions via golangci-lint), security, version.

### 5. Report

Present dimension/hook/CI coverage tables with recommendations. Suggest running `/blueprint:go-setup` to configure missing dimensions.
