---
name: python-explain
description: Answers questions about the Python quality methodology — why tools are chosen, how thresholds work, what each dimension covers, and how hooks interact. Use when user asks "why this tool", "what does the quality gate do", "how are thresholds set", or any Python methodology question.
metadata:
  version: 1.0.0
  author: Ondrej (Ondra) Krajicek, me@ondrejkrajicek.com
---

# Python Explain

Read-only — does not modify any files.

## Context Files

- `skills/shared/references/explain-pattern.md` — shared answer format and behavior
- `skills/shared/references/methodology-framework.md` — shared principles, hook architecture
- `skills/python-setup/references/methodology.md` — Python-specific dimensions, rationale, adaptation rules
- `skills/python-setup/references/analysis-checklist.md` — how projects are analyzed

## Example Questions

**"Why ruff instead of flake8?"** → Dimension 2. Ruff is orders of magnitude faster, replaces flake8+isort+pyupgrade in a single tool, supports pyproject.toml natively.

**"What's the coverage threshold?"** → Dimension 1. 95% default; 80% for new projects (<500 LOC); legacy: start at current.

**"Should I use all 9 dimensions?"** → Principles: incremental adoption. Start with testing + linting, add incrementally.

**"How does the quality gate work?"** → Hook Architecture in methodology-framework.md. Fail-fast, exit code 2, automatic fix cycle.

**"Why is there a style-guide check?"** → Optional for CLI projects using click/typer. No ASCII splitter lines, styled headings.

**"How do I disable a check?"** → Each check has a `[check:*]` comment marker. Delete the `run_check` block.
