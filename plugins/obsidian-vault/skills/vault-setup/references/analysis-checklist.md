# Analysis Checklist

This checklist defines what the setup skill must analyze in a target Obsidian vault before applying the methodology. Each section feeds into tool selection, configuration, and threshold decisions.

---

## 1. Vault Structure

**Check for**:
- [ ] `.obsidian/` directory exists (confirms this is an Obsidian vault)
- [ ] Folder hierarchy — depth, top-level folders, organizational pattern (flat, PARA, Zettelkasten, Johnny Decimal, etc.)
- [ ] Total note count (`find . -name '*.md' -not -path './.obsidian/*' -not -path './.git/*' | wc -l`)
- [ ] Daily notes location (commonly `daily/`, `journal/`, `Daily Notes/`)
- [ ] Templates location (commonly `templates/`, `Templates/`, `_templates/`)
- [ ] Attachments location (commonly `attachments/`, `assets/`, `media/`, or configured in `.obsidian/app.json` → `attachmentFolderPath`)
- [ ] Canvas files (`.canvas`) — presence indicates visual knowledge mapping
- [ ] MOC (Map of Content) files — detect by naming convention or tag

**Impact**: Determines folder-specific configuration, naming convention detection, and which workflow categories to propose.

---

## 2. Frontmatter Conventions

**Check for** (sample 20+ notes across different folders):
- [ ] Which notes have frontmatter (percentage estimate)
- [ ] Common fields — collect field names and frequency (e.g., `title: 95%`, `tags: 80%`, `date: 60%`, `aliases: 30%`)
- [ ] Date formats in use — ISO 8601 (`2024-03-15`), full datetime (`2024-03-15T10:30:00`), other formats
- [ ] Tag format — YAML list (`tags: [a, b]`), YAML block list, comma-separated string
- [ ] Custom fields — Dataview-specific fields (e.g., `type`, `status`, `project`, `rating`)
- [ ] Field ordering patterns — is there a consistent order?

**Impact**: Determines required fields for Dimension 1 (Frontmatter Integrity), adaptation rules for date validation, and Dataview compatibility requirements.

---

## 3. Template Detection

**Check for**:
- [ ] Templater plugin installed (`.obsidian/plugins/templater-obsidian/`)
- [ ] Core Templates plugin enabled (check `.obsidian/core-plugins.json` for `templates`)
- [ ] Template folder location (check `.obsidian/templates.json` → `folder`, or Templater config)
- [ ] Template files — list template filenames and their frontmatter patterns
- [ ] Templater syntax usage (`<% %>` blocks in template files)

**Impact**: Determines Dimension 4 (Template Compliance) configuration. If no templates exist, Dimension 4 is skipped.

---

## 4. Community Plugins

**Check for**:
- [ ] `.obsidian/community-plugins.json` — list of installed plugin IDs
- [ ] `.obsidian/plugins/` directory — list of plugin folders
- [ ] Key plugins and their configurations:
  - `templater-obsidian` — Templater (template management)
  - `dataview` — Dataview (metadata queries, inline fields)
  - `calendar` — Calendar (daily notes integration)
  - `periodic-notes` — Periodic Notes (daily, weekly, monthly, yearly notes)
  - `obsidian-linter` — Linter (existing quality rules — respect these)
  - `obsidian-git` — Git integration (existing auto-commit — coordinate with hooks)
  - `obsidian-kanban` — Kanban (board files with special syntax)
  - `obsidian-excalidraw-plugin` — Excalidraw (drawing files)

**Impact**:
- Dataview: may introduce additional required frontmatter fields
- Linter plugin: coordinate with existing rules, avoid conflicts
- Git plugin: coordinate auto-commit with hook scripts
- Calendar/Periodic Notes: daily note format and folder detection
- Kanban/Excalidraw: special file types to exclude from certain checks

---

## 5. Tag Inventory

**Check for**:
- [ ] Frontmatter tags — extract from `tags:` field across sampled notes
- [ ] Inline tags — extract `#tag` patterns from note bodies
- [ ] Total unique tags count
- [ ] Tag frequency distribution (most common, orphan tags used only once)
- [ ] Nested tag patterns (e.g., `#project/active`, `#status/done`)
- [ ] Case inconsistencies (e.g., `#Project` vs `#project`)

**Impact**: Determines Dimension 5 (Tag Hygiene) configuration, orphan tag threshold, and tag normalization rules.

---

## 6. Link Patterns

**Check for** (sample notes):
- [ ] Wikilink usage (`[[note name]]`) — percentage of notes using wikilinks
- [ ] Markdown link usage (`[text](path)`) — percentage using standard markdown links
- [ ] Aliases (`[[note|display text]]`)
- [ ] Embeds (`![[file]]`, `![[note#heading]]`)
- [ ] Heading links (`[[note#heading]]`)
- [ ] Block references (`[[note^blockid]]`)
- [ ] Link resolution setting in `.obsidian/app.json` → `useMarkdownLinks`, `newLinkFormat` (shortest, relative, absolute)

**Impact**: Determines Dimension 2 (Link Integrity) configuration and link resolution strategy.

---

## 7. Daily Notes Configuration

**Check for**:
- [ ] `.obsidian/daily-notes.json` — format, folder, template
- [ ] Periodic Notes plugin config (`.obsidian/plugins/periodic-notes/data.json`) — daily, weekly, monthly, quarterly, yearly
- [ ] Calendar plugin config (`.obsidian/plugins/calendar/data.json`)
- [ ] Existing daily notes — count, date range, naming pattern consistency

**Impact**: Determines daily note naming convention for Dimension 3, template for Dimension 4, and whether to propose daily/weekly automation workflows.

---

## 8. Git History

**Check for**:
- [ ] Repository age (`git log --reverse --format=%ci | head -1`)
- [ ] Commit frequency (`git log --oneline | wc -l`, commits per week/month)
- [ ] Contributors (`git shortlog -sn --no-merges | wc -l`)
- [ ] Existing `.gitignore` — what patterns are already covered
- [ ] Tracked volatile files (`git ls-files .obsidian/workspace.json .obsidian/workspace-mobile.json .obsidian/cache/`)
- [ ] Large files tracked (`git ls-files | xargs ls -la 2>/dev/null | sort -k5 -rn | head -20`)

**Impact**: Determines Dimension 7 (Git Hygiene) configuration, existing `.gitignore` merge strategy, and vault maturity assessment.

---

## 9. Existing Claude Code Configuration

**Check for**:
- [ ] `.claude/settings.json` — existing hooks, permissions
- [ ] `.claude/hooks/` — existing hook scripts
- [ ] `CLAUDE.md` — existing project instructions
- [ ] `.claude/rules/` — existing rule files

**Impact**: Merge hooks into existing settings.json. Don't overwrite existing CLAUDE.md — append methodology reference.

---

## 10. Existing GitHub Actions

**Check for**:
- [ ] `.github/workflows/*.yml` — existing workflow files
- [ ] Workflow triggers — which events are covered
- [ ] Existing quality checks — spelling, linting, link checking
- [ ] Claude Code Action usage (`anthropics/claude-code-action`)

**Impact**: If workflows exist, merge quality checks into existing pipeline rather than overwriting. If no workflows, create new ones based on workflow-catalog.md categories.

---

## Analysis Output Format

After analysis, the setup skill should produce a structured summary:

```
Vault type: Obsidian vault
Total notes: 347
Folder structure: PARA method (Projects/, Areas/, Resources/, Archive/)
Daily notes: daily/ folder, YYYY-MM-DD format, 180 notes
Templates: Templater plugin, templates/ folder, 12 templates
Community plugins: dataview, templater, calendar, periodic-notes, obsidian-git
Frontmatter coverage: ~70% of notes have frontmatter
Common fields: title (95%), tags (80%), date (65%), aliases (30%)
Tag count: 142 unique tags, 23 orphan tags, 3 case inconsistencies
Link style: wikilinks (95%), 12 broken links detected
Git history: 14 months, 892 commits, 1 contributor
Existing tools: codespell installed, .gitignore covers workspace.json
Missing dimensions: link integrity, template compliance, tag hygiene
CI: No existing GitHub Actions
```

This summary drives the plan phase, where the skill selects which dimensions to configure and how.
