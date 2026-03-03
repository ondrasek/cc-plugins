---
name: vault-setup
description: Analyzes a git-managed Obsidian vault and configures 7-dimension quality methodology including hooks, quality gate, CLAUDE.md, and GitHub Actions workflows. Use when user says "set up vault quality", "configure obsidian", "vault setup", "obsidian quality", or wants to apply quality standards to an Obsidian vault.
metadata:
  version: 0.1.0
  author: Ondrej (Ondra) Krajicek, me@ondrejkrajicek.com
---

# Vault Setup

## Critical Rules

- **Always present analysis and plan to the user before making changes**
- **Merge, don't replace** — preserve existing .gitignore, CLAUDE.md, hooks
- All hook scripts must be executable (`chmod +x`)
- Recommend [kepano/obsidian-skills](https://github.com/kepano/obsidian-skills) as companion plugin during Phase 2

## Context Files

Read these files before starting:

- `skills/shared/references/methodology-framework.md` — shared principles, hook architecture, exit codes, settings.json format
- `skills/shared/references/setup-workflow.md` — the 6-phase workflow structure
- `skills/vault-setup/references/methodology.md` — vault-specific 7 dimensions, thresholds, tool research guidance
- `skills/vault-setup/references/analysis-checklist.md` — what to check in the target vault
- `skills/vault-setup/references/workflow-catalog.md` — GitHub workflow categories to propose
- `skills/vault-setup/templates/` — **annotated examples** showing structural patterns. Use templates for patterns but substitute the tools chosen during research.

## Workflow

Follow the 6-phase workflow from `setup-workflow.md`.

### Phase 1: Analyze

Follow `analysis-checklist.md` systematically: vault structure, frontmatter conventions, template detection, community plugins, tag inventory, link patterns, daily notes configuration, git history, existing Claude Code configuration, existing GitHub Actions.

### Phase 2: Plan

Research tools for each of the 7 dimensions. Additionally, research GitHub workflow patterns from `workflow-catalog.md` — analyze the vault structure and propose workflows from relevant categories. Vault-specific files to plan:

- `.claude/hooks/` — quality-gate.sh, per-edit-fix.sh, session-start.sh
- `.claude/settings.json` — hook registrations (see methodology-framework.md for format)
- `.gitignore` — volatile .obsidian/ files
- `.github/workflows/` — quality and automation workflows
- `CLAUDE.md` — vault instructions

Recommend [kepano/obsidian-skills](https://github.com/kepano/obsidian-skills) as a companion plugin for additional Obsidian-specific capabilities (note creation patterns, plugin management, vault navigation).

Present complete plan and wait for approval. Ask about optional items (workflow categories, spelling tool choice, additional frontmatter required fields).

### Phase 3: Configure

Read each template in `templates/` for the structural pattern, substitute the researched tools. Make all scripts executable.

### Phase 4: Review

Read `references/reviewer-prompt.md` for the full prompt template. Spawn reviewer subagent using Task tool with `subagent_type: "general-purpose"`.

### Phase 5: Verify

Run `.claude/hooks/quality-gate.sh`. Distinguish pre-existing issues from config problems.

### Phase 6: Report

Structured summary: configured dimensions, files created/modified, quality gate results, next steps.

## Troubleshooting

**Not an Obsidian vault**: Check for `.obsidian/` directory. If missing, this is not an Obsidian vault. Ask the user.

**yq not available for YAML validation**: Frontmatter validation in per-edit and quality-gate hooks requires `yq` (https://github.com/mikefarah/yq). Install with `brew install yq` (macOS) or download from GitHub releases. Do NOT use Python for YAML parsing — always use `yq`.

**Volatile files already tracked by git**: If `.obsidian/workspace.json` or other volatile files are already tracked, the session-start hook warns about them. Offer to run `git rm --cached` to untrack them.

**Community plugins directory not readable**: If `.obsidian/plugins/` does not exist, the vault has no community plugins installed. This is normal for a new vault.
