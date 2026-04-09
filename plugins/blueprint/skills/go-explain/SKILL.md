---
name: go-explain
description: Answers questions about the Go quality methodology — why tools are chosen, how thresholds work, what each dimension covers, and how hooks interact. Use when user asks "why this tool", "what does the quality gate do", "how are thresholds set", or any Go methodology question.
metadata:
  version: 1.0.0
  author: Tomas (Tom) Grbalik, tomas.grbalik@gmail.com & Anthropic Opus
---

# Go Explain

Read-only — does not modify any files.

## Context Files

- `skills/shared/references/explain-pattern.md` — shared answer format and behavior
- `skills/shared/references/methodology-framework.md` — shared principles, hook architecture
- `skills/go-setup/references/methodology.md` — Go-specific dimensions, rationale, adaptation rules
- `skills/go-setup/references/analysis-checklist.md` — how projects are analyzed

## Example Questions

**"Why golangci-lint instead of running tools separately?"** → Dimension 2. golangci-lint v2 orchestrates 100+ linters in a single config file and command, covering 6 of 9 dimensions. Running tools separately means managing separate configs, inconsistent execution, and slower quality gates.

**"What's the coverage threshold?"** → Dimension 1. 80% default; 60% new; 85% library; 70% CLI.

**"Why govulncheck over gosec for security?"** → Dimension 4. Both are used. govulncheck uses call-graph analysis to report only actually-reachable vulnerabilities (fewer false positives). gosec detects source-level patterns (SQL injection, hardcoded creds). They're complementary.

**"Why gofumpt instead of gofmt?"** → Dimension 2. gofumpt is a strict superset of gofmt — it adds extra rules (no empty lines at block boundaries, consistent composite literals) while remaining fully gofmt-compatible.

**"How does Go handle circular imports?"** → Dimension 8. Go prevents circular imports at compile time (hard error). No linter needed — the compiler enforces this.

**"How do I disable a check?"** → Each check has a `[check:*]` comment marker in quality-gate.sh. Delete the `run_check` block. For golangci-lint linters, remove from the `enable:` list in `.golangci.yml`.
