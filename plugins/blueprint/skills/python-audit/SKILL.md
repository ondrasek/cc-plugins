---
name: python-audit
description: Read-only gap analysis comparing a Python project's current quality setup against the 9-dimension methodology. Use when user says "audit quality", "check coverage gaps", "what's missing", or wants to see how their project measures up before running setup.
metadata:
  version: 1.0.0
  author: Ondrej (Ondra) Krajicek, me@ondrejkrajicek.com
---

# Python Audit

Read-only — does not modify any files.

## Context Files

Read these files before starting:

- `skills/shared/references/audit-workflow.md` — the 5-step workflow structure
- `skills/python-setup/references/methodology.md` — the 9 quality dimensions (roles) to audit against
- `skills/python-setup/references/analysis-checklist.md` — what to check in the target codebase

## Workflow

Follow `audit-workflow.md`. Python-specific details:

### 1. Analyze Current State

Detect package manager, Python version, project structure, frameworks. Inventory existing tool configurations in `pyproject.toml`, standalone config files. Check hooks, CI.

### 2. Compare Against Methodology

Check each of the 9 dimensions — see `methodology.md` for Python-specific tools and thresholds.

### 3. Check Hook Coverage

Expected hooks: SessionStart (deptry), PostToolUse/Edit|Write (ruff + format), Stop (quality gate), PostToolUse/Bash (semver check).

### 4. Check CI Coverage

Expected jobs: test, lint, typecheck, security, deadcode, version.

### 5. Report

Present dimension/hook/CI coverage tables with recommendations. Suggest running `/blueprint:python-setup` to configure missing dimensions.
