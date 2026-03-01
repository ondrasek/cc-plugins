---
name: vault-audit
description: Read-only gap analysis comparing an Obsidian vault's current quality setup against the 7-dimension methodology. Use when user says "audit vault", "check vault quality", "what's missing", "vault gaps", or wants to see how their vault measures up before running setup.
metadata:
  version: 0.1.0
  author: Ondrej (Ondra) Krajicek, me@ondrejkrajicek.com
---

# Vault Audit

Read-only — does not modify any files.

## Context Files

Read these files before starting:

- `skills/shared/references/methodology-framework.md` — shared principles, hook architecture, exit codes, 7 quality dimensions
- `skills/vault-setup/references/methodology.md` — vault-specific 7 dimensions, thresholds, tool research guidance
- `skills/vault-setup/references/analysis-checklist.md` — what to check in the target vault

## Workflow

Follow the 5-step audit pattern below. Vault-specific details for each step:

### 1. Analyze Current State

Detect vault structure: folder hierarchy, `.obsidian/` contents, community plugins, daily notes configuration, frontmatter conventions, template files, tag inventory. Inventory existing tool configurations: linter configs, spelling dictionaries, `.gitignore` coverage, hook scripts, CI workflows.

### 2. Compare Against Methodology

Check each of the 7 dimensions — see methodology-framework.md for roles and the vault-specific `methodology.md` for tools and thresholds:

1. **Frontmatter Integrity** — Is YAML frontmatter validated? Required fields defined? Date format enforced?
2. **Link Integrity** — Are broken wikilinks detected? Orphaned notes identified? Missing attachments flagged?
3. **Naming Conventions** — Is a naming pattern enforced? Folder hierarchy consistent? Special characters detected?
4. **Template Compliance** — Are notes validated against declared templates? Required sections checked?
5. **Tag Hygiene** — Is tag taxonomy enforced? Orphan tags detected? Near-duplicates flagged?
6. **Documentation Quality** — Is spelling checked? Prose style consistent? Readability measured?
7. **Git Hygiene** — Is `.gitignore` covering volatile `.obsidian/` files? Large binaries detected? Merge-conflict-prone files excluded?

### 3. Check Hook Coverage

Expected hooks:
- SessionStart → vault detection, git hygiene warnings (non-blocking)
- PostToolUse (Edit|Write) → frontmatter validation, spelling (exit 2)
- Stop → quality gate (all enabled dimensions, exit 2)

### 4. Check CI Coverage

Expected workflows (from workflow-catalog.md categories):
- Frontmatter validation on push
- Link checking on PR
- Spelling on changed `.md` files

### 5. Report

Present dimension/hook/CI coverage tables with recommendations. Suggest running `/obsidian-blueprint:vault-setup` to configure missing dimensions.

```
## Audit Results

### Dimension Coverage
| Dimension | Status | Tools | Notes |
|-----------|--------|-------|-------|
| Frontmatter Integrity | Configured | ... | ... |
| ... | ... | ... | ... |

### Hook Coverage
- [x] SessionStart (vault detection)
- [x] PostToolUse (per-edit fix)
- [ ] Stop (quality gate) — not configured

### CI Coverage
- [x] frontmatter-check
- [ ] link-check — missing
- ...

### Recommendations
1. Run `/obsidian-blueprint:vault-setup` to configure missing dimensions
2. ...
```

## Important Notes

- Compare against methodology roles, not specific tools — any tool filling the role counts
- Note where vault-specific thresholds may be appropriate (personal vs. shared vaults)
- Flag outdated tools or community plugins that have been superseded
- Report both missing dimensions and misconfigured existing tools
