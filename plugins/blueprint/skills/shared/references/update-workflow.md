# Update Workflow

The update skill applies incremental methodology updates to a project previously configured with the blueprint plugin. Each technology-specific update SKILL.md provides the tech-specific details while following this shared structure.

---

## Workflow

### 1. Detect Current State

Same analysis as the audit skill — inventory existing tools, hooks, CI, and configuration.

### 2. Identify Differences

Compare current state against the latest methodology:
- New tools recommended for unfilled roles
- Updated configurations (new lint rules, updated thresholds)
- New templates (CI job improvements, hook architecture changes)
- Changed thresholds or adaptation rules

### 3. Present Update Plan

Show the user what would change before making any modifications. Wait for approval.

### 4. Apply Updates

Apply approved changes one dimension at a time:
- Merge config changes (preserve existing customizations)
- Update hook scripts
- Update CI pipeline
- Install new tools if needed

### 5. Verify

Run the quality gate to confirm no breakage. Distinguish methodology improvements from regressions.

### 6. Report

Summarize updates applied and any manual steps remaining.

---

## Important Notes

- Always show the update plan before making changes
- Preserve project-specific customizations (custom thresholds, extra rules, exceptions)
- If a project has deliberately disabled a dimension, don't re-enable it
- Update one dimension at a time to make changes reviewable
