---
name: vault-explain
description: Answers questions about the Obsidian vault quality methodology — why dimensions exist, how hooks work, what each check covers, and how workflows are configured. Use when user asks "why frontmatter", "what does the quality gate check", "how do vault hooks work", or any vault methodology question.
metadata:
  version: 0.1.0
  author: Ondrej (Ondra) Krajicek, me@ondrejkrajicek.com
---

# Vault Explain

Read-only — does not modify any files.

## Context Files

- `skills/shared/references/methodology-framework.md` — shared principles, hook architecture, exit codes, 7 quality dimensions
- `skills/vault-setup/references/methodology.md` — vault-specific dimensions, rationale, adaptation rules
- `skills/vault-setup/references/analysis-checklist.md` — how vaults are analyzed
- `skills/vault-setup/references/workflow-catalog.md` — GitHub workflow categories and options

## Example Questions

**"Why validate frontmatter?"** -- Dimension 1 (Frontmatter Integrity). YAML frontmatter is the structured backbone of an Obsidian vault. Broken frontmatter causes Dataview queries to fail silently, search to miss notes, and plugins that depend on metadata to malfunction. Validation catches missing required fields, type mismatches, and unparseable dates before they propagate.

**"What's gitignored and why?"** -- Dimension 7 (Git Hygiene). Obsidian writes volatile state files (workspace.json, workspace-mobile.json) that change on every session, creating constant merge conflicts in shared vaults. Plugin caches and hotkey configs are machine-specific. The methodology excludes these while preserving community plugin configs, snippets, and templates that should be version-controlled.

**"How does the quality gate work?"** -- Hook Architecture in methodology-framework.md. The quality gate runs as a Stop hook (exit code 2). It checks enabled dimensions sequentially, failing fast at the first error. Claude reads the structured error output and fixes the issue. The gate re-runs automatically until all checks pass. This prevents "lost in the middle" — long error lists cause Claude to skip or half-fix items.

**"What GitHub workflows can I set up?"** -- See workflow-catalog.md. Categories include: frontmatter validation on push, link checking on PR, spelling on changed .md files, daily note generation, calendar sync, attachment optimization. The setup skill proposes workflows based on vault characteristics and can research `anthropics/claude-code-action` for AI-powered review workflows.

**"Should I use all 7 dimensions?"** -- Principles: incremental adoption. Start with frontmatter integrity and git hygiene (the foundation), then add link integrity and spelling. Template compliance and tag hygiene are most valuable for larger vaults with established conventions. Adopt dimensions as the vault matures.

**"What about kepano/obsidian-skills?"** -- Companion plugin recommendation. The obsidian-blueprint plugin focuses on quality methodology (dimensions, hooks, gates). kepano/obsidian-skills provides Obsidian-specific capabilities: note creation patterns, plugin management, vault navigation. They complement each other — quality methodology plus vault operations.

## Behavior

1. Read the vault-specific methodology references to answer questions
2. Cite which document and section the answer comes from
3. If a question is outside the methodology's scope, say so
4. Suggest running `/obsidian-blueprint:vault-audit` if the user wants to see their vault's status
5. Suggest running `/obsidian-blueprint:vault-setup` if the user wants to apply changes

## Answer Format

- Be specific — reference exact sections from the methodology
- Explain the rationale, not just the rule
- Mention adaptation rules when relevant (personal vs. shared vaults, vault maturity)
- Keep answers concise but complete
