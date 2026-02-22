---
name: update
description: Applies incremental methodology updates to a .NET project previously configured with dotnet-blueprint. Use when user says "update quality tools", "upgrade methodology", "sync with latest blueprint", or after updating the plugin to get new analyzer recommendations and configs.
metadata:
  version: 0.2.0
  author: Ondrej (Ondra) Krajicek, me@ondrejkrajicek.com
---

# Update

## Context Files

Read these files from the plugin before starting:

- `skills/setup/methodology.md` — current methodology (latest version)
- `skills/setup/templates/` — current templates

## Workflow

### 1. Detect Current State

Run the same analysis as the audit skill to understand what's currently configured.

### 2. Identify Differences

Compare the project's current configuration against the latest methodology:

- **New analyzers** — analyzer packages added to the methodology since the project was configured
- **Updated configs** — .editorconfig rules or MSBuild properties that have changed
- **New templates** — hook scripts or CI jobs that have been improved
- **Threshold changes** — recommended thresholds that have been adjusted
- **Framework updates** — new .NET version support

### 3. Present Update Plan

Show the user what would change:

```
## Available Updates

### New Analyzers
- Meziantou.Analyzer — added to linting dimension
  Would add: PackageReference to Directory.Build.props

### Configuration Updates
- .editorconfig: add csharp_style_prefer_primary_constructors rule
- Directory.Build.props: AnalysisLevel latest → latest-Recommended
- .editorconfig: promote IDE0051 (dead code) to error severity

### Template Updates
- quality-gate.sh: improved error hints for dotnet build
- ci.yml: added security audit job

### No Changes Needed
- xUnit test configuration is current
- Nullable reference types already enabled
- Coverage threshold matches recommendation
```

Wait for user approval before proceeding.

### 4. Apply Updates

For each approved update:

1. **Merge config changes** — Update Directory.Build.props, .editorconfig, preserving project-specific customizations
2. **Update hook scripts** — Regenerate from templates with project-specific variables
3. **Update CI pipeline** — Add new jobs, update existing job commands
4. **Add new analyzer packages** — Add PackageReferences and restore

### 5. Verify

Run the quality gate to ensure updates don't break anything.

### 6. Report

Summarize what was updated and any manual steps needed.

## Important Notes

- Always show the update plan before making changes
- Preserve project-specific customizations (custom thresholds, suppressed rules, extra analyzers)
- If a project has deliberately disabled a dimension, don't re-enable it
- Update one dimension at a time to make changes reviewable

## Troubleshooting

**Project was not configured with dotnet-blueprint**:
- Run `/dotnet-blueprint:audit` first to understand current state, then suggest `/dotnet-blueprint:setup` instead.

**Quality gate fails after update**:
- The update may have tightened analyzer severity or added new rules. Distinguish new failures from regressions. Roll back individual changes if needed.
