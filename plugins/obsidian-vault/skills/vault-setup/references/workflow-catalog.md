# Workflow Catalog

This catalog defines GitHub workflow categories the setup skill should consider proposing during Phase 2. Each category defines a **role** (what the workflow does), not a fixed template. The setup skill analyzes the vault structure and proposes specific workflows from relevant categories.

The `templates/issue-workflow.yml` in the templates directory provides an annotated structural example showing the GitHub Actions pattern. The setup skill generates specific workflows dynamically based on research.

---

## Categories

| Category | Role | Triggered by | When to propose |
|----------|------|-------------|-----------------|
| Quality Enforcement | Run quality gate on PRs, validate frontmatter in CI | Push / PR | Always (core workflow) |
| Content Generation | Create notes from issue context (summaries, reading notes, research) | Issue labels | Vault has templates, uses GitHub issues |
| Knowledge Graph Maintenance | Auto-link orphan notes, build MOCs, update canvas files | Schedule or issue | Vault has MOCs or canvas files |
| Daily/Weekly Automation | Generate daily notes with calendar events, weekly reviews | Schedule (cron) | Vault has daily notes configured |
| Publishing | Deploy vault content as static site, blog, or wiki | Push to main | Vault has publish-ready structure |
| Taxonomy Operations | Batch rename tags, migrate metadata, normalize frontmatter | Issue request | Vault has significant tag/metadata usage |
| Backup & Sync | Automated commit/push, cross-device sync validation | Schedule | Vault is actively edited |

---

## Quality Enforcement

**Role**: Run quality checks on every push and pull request to catch content issues before they land on the main branch.

**Detection signals**:
- Always relevant — this is the core workflow category
- Vault has quality-gate.sh configured

**What to include**:
- Frontmatter validation (YAML syntax, required fields)
- Link checking (broken wikilinks)
- Spelling (on changed `.md` files)
- Naming convention enforcement

**Key research topics**:
- GitHub Actions for markdown validation
- YAML validation in CI (yamllint, python-based validators)
- Obsidian-aware link checking tools that run headless
- Spell checking in CI (codespell, cspell, typos-cli)

**Reference**: This is the vault equivalent of a CI pipeline. Mirrors the quality gate checks from `.claude/hooks/quality-gate.sh` but runs in CI for PRs not made through Claude Code.

---

## Content Generation

**Role**: Use Claude to generate or transform notes based on GitHub issue context. Examples: create a reading summary note, generate a research note from a paper link, create meeting notes from an agenda.

**Detection signals**:
- Vault has templates (Templater or core Templates plugin)
- Repository uses GitHub Issues for task tracking
- Vault has a clear organizational structure for different note types

**What to include**:
- Workflow triggered by issue label (e.g., `generate-note`)
- Claude Code Action (`anthropics/claude-code-action`) to read issue body and generate note
- Note placed in correct folder based on template type
- Frontmatter populated from issue metadata
- Auto-commit the generated note

**Key research topics**:
- `anthropics/claude-code-action` setup and configuration
- Issue-triggered workflows with label filtering
- Template-based content generation patterns

---

## Knowledge Graph Maintenance

**Role**: Periodically analyze the vault's link graph and improve connectivity. Find orphan notes (no incoming links), suggest links, build or update Maps of Content (MOCs), refresh canvas files.

**Detection signals**:
- Vault has MOC files (detected by naming convention like `MOC - *.md` or `_index.md` or tag `#moc`)
- Vault has canvas files (`.canvas`)
- Vault has more than 100 notes (below this, manual linking is manageable)
- Significant number of orphan notes detected during analysis

**What to include**:
- Scheduled workflow (weekly) or issue-triggered
- Claude Code Action to analyze link graph
- Suggest new links for orphan notes
- Update MOC files with new notes
- Create PR with suggested changes for human review

**Key research topics**:
- Graph analysis of wikilink connections
- MOC generation patterns
- `anthropics/claude-code-action` for vault analysis

---

## Daily/Weekly Automation

**Role**: Automatically generate periodic notes (daily, weekly, monthly) with pre-populated content like calendar events, task rollover, or review prompts.

**Detection signals**:
- Vault has daily notes configured (`.obsidian/daily-notes.json` or Periodic Notes plugin)
- Daily notes folder exists with existing notes
- Templates exist for daily/weekly notes
- Calendar plugin installed

**What to include**:
- Cron-triggered workflow (e.g., 6am daily, Monday morning for weekly)
- Generate note from template
- Populate with: date, day of week, linked tasks from previous day, upcoming calendar items
- Auto-commit to vault repository

**Key research topics**:
- Cron scheduling in GitHub Actions
- Template rendering with dynamic content
- Task rollover patterns (detecting unchecked `- [ ]` items in previous daily note)

---

## Publishing

**Role**: Deploy vault content as a static site, blog, or wiki. Build and publish on push to main.

**Detection signals**:
- Vault has a publish-ready structure (consistent frontmatter with `publish: true` field, or a dedicated `publish/` folder)
- `obsidian-publish` plugin or alternative publishing setup detected
- Static site generator config files present (`mkdocs.yml`, `_config.yml`, `quartz.config.ts`)
- GitHub Pages enabled or Cloudflare Pages/Netlify config present

**What to include**:
- Build step using detected static site generator (Quartz, MkDocs, Jekyll, Hugo)
- Deploy to GitHub Pages or configured hosting
- Only process notes marked for publication
- Transform wikilinks to standard markdown links for publishing

**Key research topics**:
- Quartz (Obsidian-native static site generator)
- MkDocs with obsidian plugins
- Wikilink-to-markdown-link transformation
- GitHub Pages deployment actions

---

## Taxonomy Operations

**Role**: Batch operations on vault metadata — rename tags across all notes, migrate frontmatter schemas, normalize field values. Triggered by issue request to keep operations auditable.

**Detection signals**:
- Vault has significant tag usage (50+ unique tags)
- Tag hygiene issues detected (case inconsistencies, orphan tags, synonyms)
- Frontmatter schema has evolved over time (older notes have different fields than newer ones)
- Dataview plugin in use (metadata consistency is critical for queries)

**What to include**:
- Issue-triggered workflow (label: `taxonomy-operation`)
- Issue body describes the operation (e.g., "Rename tag #project to #projects across all notes")
- Claude Code Action to execute the operation
- Create PR with changes for review before merging

**Key research topics**:
- Bulk find-and-replace in YAML frontmatter
- Tag renaming that handles both frontmatter tags and inline #tags
- `anthropics/claude-code-action` for batch vault operations

---

## Backup & Sync

**Role**: Automated commit and push to keep the vault backed up. Validate cross-device sync consistency.

**Detection signals**:
- Vault is actively edited (frequent commits in git history)
- `obsidian-git` plugin installed (coordinate with existing auto-commit)
- Multiple contributors or devices (evidence of merge conflicts in history)

**What to include**:
- Scheduled workflow (daily backup validation)
- Check for uncommitted changes and auto-commit
- Validate vault integrity after sync (no corrupt frontmatter, no broken links from renamed files)
- Alert on potential sync conflicts

**Key research topics**:
- Obsidian sync conflict detection patterns
- Git auto-commit workflows
- Vault integrity validation scripts

---

## Workflow Template Pattern

All workflows should follow this structural pattern (see `templates/issue-workflow.yml` for a complete annotated example):

```yaml
name: <Descriptive name>

on:
  # Trigger configuration varies by category
  push:
    branches: [main]
    paths: ['**.md']  # Only trigger on markdown changes
  pull_request:
    branches: [main]
  schedule:
    - cron: '0 6 * * *'  # For scheduled workflows
  issues:
    types: [labeled]      # For issue-triggered workflows

jobs:
  <job-name>:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: <Step description>
        run: |
          # Tool commands here
```

For workflows using Claude Code Action:

```yaml
      - uses: anthropics/claude-code-action@beta
        with:
          anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}
          prompt: |
            <Context-specific prompt for Claude>
```
