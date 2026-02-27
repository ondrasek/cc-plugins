---
name: dotnet-audit
description: Read-only gap analysis comparing a .NET project's current quality setup against the 9-dimension methodology. Use when user says "audit quality", "check coverage gaps", "what's missing", or wants to see how their .NET project measures up before running setup.
metadata:
  version: 1.0.0
  author: Ondrej (Ondra) Krajicek, me@ondrejkrajicek.com
---

# .NET Audit

Read-only — does not modify any files.

## Context Files

Read these files before starting:

- `skills/shared/references/audit-workflow.md` — the 5-step workflow structure
- `skills/dotnet-setup/references/methodology.md` — the 9 quality dimensions (roles) to audit against
- `skills/dotnet-setup/references/analysis-checklist.md` — what to check in the target codebase

## Workflow

Follow `audit-workflow.md`. .NET-specific details:

### 1. Analyze Current State

Detect .NET SDK version, target framework, solution structure, frameworks. Inventory existing configurations in Directory.Build.props, .editorconfig, .csproj files. Check hooks, CI.

### 2. Compare Against Methodology

Check each of the 9 dimensions — see `methodology.md` for .NET-specific tools and thresholds.

### 3. Check Hook Coverage

Expected hooks: SessionStart (NuGet audit), PostToolUse/Edit|Write (dotnet format), Stop (quality gate), PostToolUse/Bash (semver check).

### 4. Check CI Coverage

Expected jobs: test, lint, security, version.

### 5. Report

Present dimension/hook/CI coverage tables with recommendations. Suggest running `/blueprint:dotnet-setup` to configure missing dimensions.
