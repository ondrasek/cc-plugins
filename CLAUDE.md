# CLAUDE.md — cc-plugins

## What This Is

A multi-plugin marketplace repo for Claude Code. Each plugin lives in its own self-contained directory under `plugins/`.

## Directory Structure

```
.claude-plugin/marketplace.json  — Marketplace manifest (lists all plugins)
plugins/
  blueprint/                     — Multi-language quality methodology plugin
    .claude-plugin/plugin.json   — Plugin manifest
    skills/shared/references/    — Shared methodology framework and workflows
    skills/{lang}-{skill}/       — 16 skills (python/dotnet/rust/nvim-lua × setup/audit/update/explain)
    hooks/hooks.json             — Plugin-level hook registrations
    scripts/per-edit-fix.sh      — Multi-language per-edit auto-fix (routes by extension)
  github-issues/                 — GitHub issue management utility plugin
    .claude-plugin/plugin.json   — Plugin manifest
    skills/                      — triage, manage, refine, create, develop, recommend, organize
    hooks/hooks.json             — Plugin-level hook registrations
    scripts/                     — session-start, commit-reference-check, stop-reminder
  obsidian-blueprint/                  — Obsidian vault quality methodology plugin
    .claude-plugin/plugin.json   — Plugin manifest
    skills/shared/references/    — Shared methodology framework and workflows
    skills/vault-{skill}/        — 5 skills (setup/audit/update/explain/calendar)
    hooks/hooks.json             — Plugin-level hook registrations
    scripts/                     — per-edit-fix (frontmatter), session-start (vault detection)
  calendar-access/                     — Read-only calendar access plugin
    .claude-plugin/plugin.json   — Plugin manifest
    skills/shared/references/    — Provider detection, CLI commands, field mapping
    skills/{skill}/              — 10 skills (setup/view/search/list-calendars + 6 shortcuts)
    hooks/hooks.json             — Plugin-level hook registrations (SessionStart only)
    scripts/session-start.sh     — Show today's upcoming events
plans/                           — Development phase documentation
```

## Skill Writing Guidelines

When creating or modifying skills in this repo, **always research the latest Anthropic skill-writing guidelines** before making changes. The guidelines evolve — do not rely on cached knowledge.

### Required research before writing/editing skills

1. **WebSearch** for the latest Anthropic skill documentation: search for `"Anthropic Claude skills best practices"` and `"Claude Code skills documentation"` on `docs.anthropic.com` and `anthropic.com`
2. **Read the official guide**: [The Complete Guide to Building Skills for Claude](https://resources.anthropic.com/hubfs/The-Complete-Guide-to-Building-Skill-for-Claude.pdf)
3. **Check the docs**: [Agent Skills Quickstart](https://docs.anthropic.com/en/docs/agents-and-tools/agent-skills/quickstart)

### Key rules from the official guide

- **SKILL.md naming**: Must be exactly `SKILL.md` (case-sensitive). No variations.
- **Skill folder naming**: kebab-case only, no spaces, no underscores, no capitals.
- **No README.md inside skill folders** — all documentation goes in SKILL.md or `references/`.
- **YAML frontmatter**: `name` (kebab-case, required) + `description` (required, under 1024 chars, must include what it does AND when to use it with trigger phrases). No XML angle brackets. No "claude" or "anthropic" in name.
- **Progressive disclosure** (3 levels): frontmatter (always loaded) -> SKILL.md body (loaded on invocation) -> `references/` and `templates/` (loaded on demand)
- **Description formula**: `[What it does] + [When to use it] + [Key capabilities]`
- **Keep SKILL.md under 5,000 words** — move detailed docs to `references/`
- **Be specific and actionable** in instructions, not vague. Use bullet points and numbered lists.
- **Put critical instructions at the top** using `## Critical Rules` or `## Important`
- **Include error handling** and troubleshooting sections
- **Include examples** of common scenarios and expected outcomes

### Reference documents

- [The Complete Guide to Building Skills for Claude (PDF)](https://resources.anthropic.com/hubfs/The-Complete-Guide-to-Building-Skill-for-Claude.pdf)
- [Claude Code Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices)
- [Equipping Agents for the Real World with Agent Skills](https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills)
- [Introducing Agent Skills](https://www.anthropic.com/news/skills)
- [Agent Skills Quickstart (docs)](https://docs.anthropic.com/en/docs/agents-and-tools/agent-skills/quickstart)
- [Public skills repository (GitHub)](https://github.com/anthropics/skills)

## Working on This Repo

### Testing a plugin locally

```bash
# From a target project directory:
claude --plugin-dir /path/to/cc-plugins/plugins/blueprint
```

### Adding a new plugin

1. Create `plugins/<plugin-name>/` with `.claude-plugin/plugin.json`, `skills/`, etc.
2. Add an entry to `.claude-plugin/marketplace.json` with `source` pointing to the plugin subdirectory
3. Create a `plugins/<plugin-name>/README.md`
4. Add the plugin to the root README table

## blueprint Plugin

### Key files to understand

- `plugins/blueprint/skills/shared/references/methodology-framework.md` — shared principles, hook architecture, exit codes, CC hygiene
- `plugins/blueprint/skills/shared/references/setup-workflow.md` — shared 6-phase setup workflow
- `plugins/blueprint/skills/{lang}-setup/references/methodology.md` — tech-specific 9 dimensions, thresholds, adaptation rules
- `plugins/blueprint/skills/{lang}-setup/references/analysis-checklist.md` — tech-specific project analysis checklist
- `plugins/blueprint/skills/{lang}-setup/templates/` — annotated config templates per language

### Conventions

- Methodology defines **roles** (what to check), not tools. The setup skill researches tools dynamically.
- Shared workflows in `skills/shared/references/` — tech-specific SKILL.md files reference them
- Templates use shell variables for customization (language-specific: `${PACKAGE_MANAGER_RUN}`, `${SOLUTION_FILE}`, `${WORKSPACE_FLAG}`, etc.)
- Plugin-level hook (`scripts/per-edit-fix.sh`) routes by file extension: `.py` → ruff, `.cs` → dotnet format, `.rs` → cargo fmt, `.lua` → stylua
- Hook output is structured as a prompt: what failed, tool output, diagnostic hint, action directive
- Quality gate is fail-fast: one error at a time, exit code 2

### Quality Methodology (9 Dimensions)

1. **Testing & Coverage** — run tests, enforce coverage threshold
2. **Linting & Formatting** — consistent style, auto-fix on edit
3. **Type Safety** — static type analysis or compiler strictness
4. **Security Analysis** — vulnerability pattern detection
5. **Code Complexity** — cyclomatic/cognitive complexity limits
6. **Dead Code & Modernization** — unused code, modern idioms
7. **Documentation** — documentation coverage on public API
8. **Architecture & Import Discipline** — module boundaries, dependency hygiene
9. **Version Discipline** — semver 2.0 validation, bump enforcement

### Language-Specific Notes

- **Python**: pyproject.toml config, ruff/pyright/bandit ecosystem, pre-commit hooks, deptry for deps
- **.NET**: Directory.Build.props + .editorconfig centralization, Roslyn analyzers preferred, dotnet format
- **Rust**: Cargo.toml `[lints]` + clippy.toml/rustfmt.toml/deny.toml, WASM target detection
- **Neovim Lua**: selene (std="vim") + stylua, LuaJIT/Lua 5.1 only, plenary/mini.test/busted detection

## github-issues Plugin

### Key files to understand

- `plugins/github-issues/skills/shared/references/cross-cutting.md` — the intellectual core: 3 cross-cutting behaviors (issue relationships, comments, labels) that all skills must follow
- `plugins/github-issues/skills/shared/references/label-taxonomy.md` — label naming conventions and category definitions
- `plugins/github-issues/skills/refine/references/` — epic, user story, and splitting technique guides

### Conventions

- **`gh` CLI everywhere** — all operations use `gh` commands with `--json` for structured output
- **Cross-cutting behaviors** are documented once in `skills/shared/references/` and referenced from every SKILL.md
- **NEVER create priority labels** — explicit user requirement, enforced across all skills
- **Sub-issues for epic decomposition** — uses GitHub's native sub-issue support (`--add-parent`)
- **Comments explain "why"** — every significant change gets a comment providing context

### Hooks (3)

- **SessionStart** (`session-start.sh`) — displays issue context when on an issue-linked branch (non-blocking)
- **PostToolUse/Bash** (`commit-reference-check.sh`) — blocks commits missing `#N` issue reference, instructs to amend (exit 2)
- **Stop** (`stop-reminder.sh`) — reminds to update the issue with work summary when unpushed commits exist (non-blocking)

Branch convention: `<issue-number>-<description>` (e.g., `42-fix-bug` → issue #42). Non-matching branches are silently ignored.

### Skills (7)

1. **triage** — read-only querying, viewing, and status dashboard
2. **manage** — CRUD lifecycle, batch operations, label management
3. **refine** — progressive refinement: rough ideas → epics → user stories (INVEST, SPIDR)
4. **create** — research-driven issue creation with immediate refinement
5. **develop** — issue → branch → PR workflow bridge
6. **recommend** — analyze open issues against codebase activity, severity, and trends to suggest what to work on next
7. **organize** — lock, unlock, pin, unpin, transfer

## calendar-access Plugin

### Key files

- `plugins/calendar-access/skills/shared/references/cross-cutting.md` — provider detection, output format, read-only guarantee
- `plugins/calendar-access/skills/shared/references/providers.md` — CLI commands, parsing, field mapping
- `plugins/calendar-access/skills/setup/references/auth-guide.md` — auth steps for Google + Microsoft

### Conventions

- **Read-only** — never creates, modifies, or deletes events
- **Pure CLI** — gcalcli (Google) + Azure CLI + curl against Graph API (Microsoft)
- **Custom Entra ID app required** — Azure CLI's built-in app lacks `Calendars.Read`; setup guides through app registration
- **`calendarView` endpoint** for Microsoft — expands recurring events (not `/events`)
- **Multi-provider merge** — both configured → results merge chronologically
- **Config**: Microsoft client ID in `~/.config/calendar-access/config.json`, Google in `~/.gcalcli_oauth`

### Hook (1)

- **SessionStart** — shows up to 4 upcoming events for rest of today (non-blocking, silent if unconfigured)

### Skills (10)

Core: **setup**, **view**, **search**, **list-calendars**
Shortcuts: **today**, **tomorrow**, **next-week**, **next-month**, **last-week**, **last-month**

## obsidian-blueprint Plugin

### Key files to understand

- `plugins/obsidian-blueprint/skills/shared/references/methodology-framework.md` — shared principles, hook architecture, exit codes, CC hygiene
- `plugins/obsidian-blueprint/skills/shared/references/setup-workflow.md` — shared 6-phase setup workflow
- `plugins/obsidian-blueprint/skills/vault-setup/references/methodology.md` — 7 vault dimensions, thresholds, adaptation rules
- `plugins/obsidian-blueprint/skills/vault-setup/references/analysis-checklist.md` — vault analysis checklist
- `plugins/obsidian-blueprint/skills/vault-setup/references/workflow-catalog.md` — GitHub workflow categories (roles, not templates)
- `plugins/obsidian-blueprint/skills/vault-setup/templates/` — annotated config templates

### Conventions

- Methodology defines **roles** (what to check), not tools. The setup skill researches tools dynamically.
- Shared workflows in `skills/shared/references/` — vault-specific SKILL.md files reference them
- Templates use shell variables for customization (`${VAULT_ROOT}`, `${REQUIRED_FIELDS}`, `${DAILY_NOTES_FORMAT}`, etc.)
- Plugin-level hook (`scripts/per-edit-fix.sh`) validates YAML frontmatter, ISO dates, runs codespell on .md files
- `.obsidian/` is tracked in git — only volatile files (workspace.json, cache/) are gitignored
- Python3 used for YAML parsing (universally available, avoids yq version fragmentation)
- Recommends [kepano/obsidian-skills](https://github.com/kepano/obsidian-skills) as companion plugin

### Quality Methodology (7 Dimensions)

1. **Frontmatter Integrity** — valid YAML, required fields, ISO dates
2. **Link Integrity** — broken wikilinks, missing embeds, orphan aliases
3. **Naming Conventions** — filename patterns, no special chars, daily note format
4. **Template Compliance** — notes match template structure/fields
5. **Tag Hygiene** — orphan tags, case consistency, synonyms
6. **Documentation Quality** — spelling, heading hierarchy, empty notes
7. **Git Hygiene** — volatile .obsidian/ gitignored, no tracked binaries

### Skills (5)

1. **vault-setup** — 6-phase setup: analyze vault → research tools & workflows → configure
2. **vault-audit** — read-only gap analysis against 7 dimensions
3. **vault-update** — incremental methodology updates
4. **vault-explain** — Q&A about vault methodology
5. **vault-calendar** — pull Google/M365 calendar events into daily notes
