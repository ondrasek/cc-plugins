# obsidian-vault

A Claude Code plugin that applies quality methodology to git-managed Obsidian vaults. It analyzes vault structure, validates content quality, and configures hooks and CI to maintain consistency across notes.

## Skills (5)

| Skill | Description |
|-------|-------------|
| `/obsidian-vault:vault-setup` | Analyze vault structure and configure quality tooling for an Obsidian vault |
| `/obsidian-vault:vault-audit` | Read-only gap analysis for vault content quality |
| `/obsidian-vault:vault-update` | Incremental methodology updates for an existing vault setup |
| `/obsidian-vault:vault-explain` | Q&A about the vault quality methodology |
| `/obsidian-vault:vault-calendar` | Calendar-based note management and daily/weekly/periodic note workflows |

## Setup Workflow (6 Phases)

All setup skills follow the same workflow:

1. **Analyze** — detect vault structure, folder hierarchy, existing templates, community plugins, and .gitignore coverage
2. **Plan** — determine quality dimensions to apply, identify missing frontmatter schemas, evaluate naming conventions
3. **Configure** — generate/merge .gitignore rules, frontmatter templates, linter configs, and CI workflows
4. **Review** — spawn a reviewer subagent to audit the generated configuration
5. **Verify** — run quality checks to confirm everything works
6. **Report** — summarize changes and next steps

## Quality Methodology (7 Dimensions)

| Dimension | Role |
|-----------|------|
| Frontmatter Consistency | Validate YAML frontmatter schema, required fields, date formats |
| Link Integrity | Detect broken wikilinks, orphaned notes, missing attachments |
| Naming & Folder Conventions | Enforce kebab-case or configured naming, folder hierarchy rules |
| Spelling & Grammar | Codespell auto-fix, language-aware spell checking |
| Tag Hygiene | Detect unused tags, enforce tag taxonomy, normalize casing |
| Git Hygiene | Gitignore volatile .obsidian/ files, prevent merge-conflict-prone tracking |
| Template Compliance | Validate notes against vault-defined templates and schemas |

## GitHub Workflow Catalog

Setup can generate CI workflows for vault quality checks:

- **Frontmatter validation** — YAML schema enforcement on push
- **Link checking** — broken wikilink detection on PR
- **Spelling** — codespell checks on changed .md files

## Plugin-Level Hooks

The plugin registers two hooks:

- **SessionStart** (`scripts/session-start.sh`) — detects Obsidian vault, reports note count, warns about volatile .obsidian/ files tracked by git (non-blocking)
- **PostToolUse Edit|Write** (`scripts/per-edit-fix.sh`) — validates frontmatter YAML, checks date format, runs codespell on edited .md files (exit 2 on unfixable issues)

## Structure

```
.claude-plugin/plugin.json          — Plugin manifest
hooks/hooks.json                    — Plugin-level hook registrations
scripts/
  session-start.sh                  — Vault detection and git hygiene check
  per-edit-fix.sh                   — Frontmatter validation and spelling fix
skills/
  vault-setup/                      — Vault setup skill + references + templates
  vault-audit/                      — Vault audit skill
  vault-update/                     — Vault update skill
  vault-explain/                    — Vault explain skill
  vault-calendar/                   — Calendar and periodic note skill
```

## Companion Plugin

Users may also want to install [kepano/obsidian-skills](https://github.com/kepano/obsidian-skills) for additional Obsidian-specific capabilities, including note creation patterns, plugin management, and vault navigation skills.
