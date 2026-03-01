# Update Workflow

The update skill applies incremental methodology updates to a vault previously configured with the obsidian-vault plugin. The vault-specific update SKILL.md provides the details while following this shared structure.

---

## Workflow

### 1. Detect Current State

Same analysis as the audit skill — inventory existing tools, hooks, GitHub Actions workflows, and configuration.

### 2. Identify Differences

Compare current state against the latest methodology:
- New tools recommended for unfilled roles
- Updated configurations (new spelling rules, updated frontmatter schemas)
- New templates (workflow improvements, hook architecture changes)
- Changed thresholds or adaptation rules
- New workflow catalog entries available
- Updated `anthropics/claude-code-action` capabilities

### 3. Present Update Plan

Show the user what would change before making any modifications. Include:
- Dimension configuration changes (new tools, updated thresholds)
- Hook script updates (new checks, improved hints)
- GitHub Actions workflow additions or updates
- .gitignore updates
- CLAUDE.md updates

Wait for approval.

### 4. Apply Updates

Apply approved changes one dimension at a time:
- Merge config changes (preserve existing customizations, custom dictionaries, ignore patterns)
- Update hook scripts
- Update or add GitHub Actions workflows
- Install new tools if needed

### 5. Verify

Run the quality gate to confirm no breakage. Distinguish methodology improvements from regressions.

### 6. Report

Summarize updates applied and any manual steps remaining.

---

## Important Notes

- Always show the update plan before making changes
- Preserve vault-specific customizations (custom dictionaries, extra ignore patterns, template overrides)
- If a vault has deliberately disabled a dimension, don't re-enable it
- Update one dimension at a time to make changes reviewable
- Preserve any custom GitHub Actions workflows the user has added
- Check for new workflow catalog entries that may benefit the vault
