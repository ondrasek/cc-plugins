# Audit Workflow

Read-only — does not modify any files.

The audit skill compares a vault's current quality setup against the 7-dimension methodology and reports gaps. The vault-specific audit SKILL.md provides the detection details while following this shared structure.

---

## Workflow

### 1. Analyze Current State

Follow the same analysis steps as the setup skill (Phase 1):
- Detect vault structure: folders, daily notes path, templates path, attachments path
- Inventory existing tool configurations (spelling dictionaries, linter configs, frontmatter schemas)
- Check for existing hooks in `.claude/settings.json`
- Check for GitHub Actions workflows in `.github/workflows/`
- Check for installed CLI tools
- Check .gitignore coverage

### 2. Compare Against Methodology

For each of the 7 quality dimensions from the vault-specific `methodology.md`, check whether the role is filled by any tool:

1. **Frontmatter Integrity** — Is frontmatter validated? Are required fields defined? Are types enforced? Are dates parseable?
2. **Link Integrity** — Are broken wikilinks detected? Are orphaned notes flagged? Are missing embed targets caught? Are unreachable attachments identified?
3. **Naming Conventions** — Are file naming rules enforced? Folder naming? Date prefix patterns? Special character restrictions?
4. **Template Compliance** — Are notes validated against their declared template? Required sections checked? Heading hierarchy enforced? Placeholder tags detected?
5. **Tag Hygiene** — Is tag taxonomy enforced? Are orphan tags detected? Near-duplicate tags flagged? Nested tag structure validated?
6. **Documentation Quality** — Is spelling checked? Prose style validated? Heading consistency enforced? Readability scores measured?
7. **Git Hygiene** — Is .gitignore comprehensive? Are large binaries detected? Commit message format enforced? Merge conflict markers caught?

### 3. Check Hook Coverage

Verify Claude Code hooks are configured for each hook event:
- SessionStart → vault detection, git hygiene warnings (non-blocking)
- PostToolUse (Edit|Write) → per-edit frontmatter validation, spelling
- Stop → quality gate (all enabled dimensions)

### 4. Check GitHub Actions Coverage

Verify GitHub Actions workflows are configured where appropriate:
- Vault quality check workflows (link validation, frontmatter checks)
- Automated workflows (daily note generation, calendar sync)
- Review workflows (claude-code-action integration)

### 5. Report

Present findings in a structured format:

```
## Audit Results

### Dimension Coverage
| Dimension | Status | Tools | Notes |
|-----------|--------|-------|-------|
| Frontmatter Integrity | Configured | ... | ... |
| Link Integrity | Missing | — | No link checker found |
| ... | ... | ... | ... |

### Hook Coverage
- [x] SessionStart (vault detection)
- [x] PostToolUse (per-edit fix)
- [ ] Stop (quality gate) — not configured

### GitHub Actions Coverage
- [x] link-validation.yml
- [ ] daily-note.yml — not configured
- ...

### Recommendations
1. Run the setup skill to configure missing dimensions
2. ...
```

---

## Important Notes

- Compare against methodology roles, not specific tools — any tool filling the role counts
- Note where vault-specific thresholds may be appropriate (e.g., personal vs team vaults)
- Flag outdated tools that have been superseded by better alternatives
- Report both missing dimensions and misconfigured existing tools
- Check community plugin overlap — some quality roles may be partially filled by Obsidian plugins (e.g., Linter plugin for formatting)
