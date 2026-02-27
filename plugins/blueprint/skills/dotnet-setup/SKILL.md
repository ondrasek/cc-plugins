---
name: dotnet-setup
description: Analyzes a .NET/C# project and configures 9-dimension quality methodology including hooks, CI, and tool configs. Use when user says "set up quality tools", "configure analyzers", "add CI pipeline", "dotnet quality", or wants to apply coding standards to a .NET project.
metadata:
  version: 1.0.0
  author: Ondrej (Ondra) Krajicek, me@ondrejkrajicek.com
---

# .NET Setup

## Critical Rules

- **Always present analysis and plan to the user before making changes**
- **Merge, don't replace** — preserve existing .csproj properties, CI jobs, hooks, .editorconfig rules
- **Use `dotnet` CLI** for all build, test, and format operations
- All hook scripts must be executable (`chmod +x`)

## Context Files

Read these files before starting:

- `skills/shared/references/methodology-framework.md` — shared principles, hook architecture, exit codes, settings.json format
- `skills/shared/references/setup-workflow.md` — the 6-phase workflow structure
- `skills/dotnet-setup/references/methodology.md` — .NET-specific 9 dimensions, thresholds, tool research guidance
- `skills/dotnet-setup/references/analysis-checklist.md` — what to check in the target codebase
- `skills/dotnet-setup/templates/` — **annotated examples** showing structural patterns. Use templates for patterns but substitute the tools chosen during research.

## Workflow

Follow the 6-phase workflow from `setup-workflow.md`.

### Phase 1: Analyze

Follow `analysis-checklist.md` systematically: .NET SDK version, target framework, solution structure, frameworks, existing tools, CI, maturity.

### Phase 2: Plan

Research tools for each of the 9 dimensions. .NET-specific files to plan:
- `Directory.Build.props` — centralized MSBuild properties and analyzer packages
- `.editorconfig` — formatting and analyzer severity rules
- `.claude/hooks/` — quality-gate.sh, per-edit-fix.sh, session-start.sh, optionally auto-commit.sh
- `.claude/settings.json` — hook registrations (see methodology-framework.md for format)
- `.github/workflows/ci.yml` — CI pipeline
- `CLAUDE.md` — project instructions
- `semver-check.sh` — only when Dimension 9 is activated at level 3

Present complete plan and wait for approval. Ask about optional items (auto-commit, architecture tests).

### Phase 3: Configure

Read each template in `templates/` for the structural pattern, substitute the researched tools. Restore NuGet packages and verify build.

### Phase 4: Review

Read `references/reviewer-prompt.md` for the full prompt template. Spawn reviewer subagent using Task tool with `subagent_type: "general-purpose"`.

### Phase 5: Verify

Run `.claude/hooks/quality-gate.sh`. Distinguish pre-existing issues from config problems.

### Phase 6: Report

Structured summary: configured dimensions, files created/modified, quality gate results, next steps.

## Troubleshooting

**Solution file not found**: Check for `.sln` files. If none, look for `.csproj` files directly. Ask the user.

**Build restore fails**: Check for custom NuGet feeds in `nuget.config`. Ensure authentication is configured for private feeds.
