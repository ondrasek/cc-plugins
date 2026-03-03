# Vault Quality Methodology

This document defines the quality methodology applied by the `obsidian-blueprint` plugin. It is organized into 7 quality dimensions, each defining a **role** (what needs to happen) rather than prescribing specific tools.

The setup skill reads this document to understand what to apply, then researches current best-in-class tools to fill each role.

---

## Principles

1. **Fail fast, fix fast** — Quality checks run as Claude Code hooks. Failures block the agent and feed back for automatic fixing (exit code 2).
2. **Ordered by speed** — Checks run fastest-first so common failures surface quickly.
3. **Opinionated defaults, flexible adaptation** — Defaults reflect production-grade vault standards. Every dimension can be relaxed for personal, early-stage, or legacy vaults.
4. **Roles, not tools** — The methodology defines *what* to check, not *which tool*. The setup skill researches current tools to fill each role, considering the vault's ecosystem and existing plugins.
5. **Incremental adoption** — Vaults can adopt dimensions one at a time. The audit skill tracks which dimensions are active.

---

## Dimension 1: Frontmatter Integrity

**Role**: Ensure every note has valid YAML frontmatter with required fields.

**What the tool must do**:
- Validate YAML syntax (no parse errors, no duplicate keys)
- Verify required fields are present (configurable per vault)
- Enforce ISO 8601 date formats (YYYY-MM-DD or YYYY-MM-DDTHH:MM:SS)
- Detect inconsistent field ordering across notes

**Default required fields**: `title`, `date` (as created date), `tags`

**Adaptation**:
- Vault-specific required fields detected from existing notes during analysis (e.g., `aliases`, `cssclasses`, `publish`)
- Daily notes may have a reduced schema (date derived from filename)
- Dataview-heavy vaults may require additional typed fields

**Per-edit hook**: Validate YAML syntax and required fields on each `.md` file edit. Report unfixable issues (exit 2).

**Quality gate**: Full scan of all notes — YAML validity, required fields, date format consistency.

---

## Dimension 2: Link Integrity

**Role**: Detect broken internal links and embeds.

**What the tool must do**:
- Resolve wikilinks (`[[target]]`) to existing files
- Resolve embedded files (`![[file]]`) to existing attachments
- Resolve aliased links (`[[target|alias]]`) to existing files
- Detect orphan notes (no incoming links from any other note)

**Adaptation**:
- Configure root folder if vault uses a subfolder structure
- Respect Obsidian's "shortest path" link resolution (configurable in `.obsidian/app.json`)
- Handle heading links (`[[note#heading]]`) and block references (`[[note^blockid]]`)

**Quality gate only** — too slow for per-edit (requires building a file index of the entire vault).

---

## Dimension 3: Naming Conventions

**Role**: Enforce consistent file and folder naming patterns.

**What the tool must do**:
- Validate filenames against a configurable pattern (default: no special characters that break wikilinks)
- Detect special characters that cause cross-platform issues (`\`, `:`, `*`, `?`, `"`, `<`, `>`, `|`)
- Enforce daily note naming consistency (YYYY-MM-DD or configured pattern)
- Check folder naming consistency

**Default configuration**:
- No characters that break wikilinks: `[`, `]`, `#`, `^`, `|`
- No characters that break cross-platform: `\`, `:`, `*`, `?`, `"`, `<`, `>`, `|`
- Daily notes match configured date format pattern

**Adaptation**:
- Detect existing naming convention from vault (kebab-case, Title Case, sentence case, etc.)
- Respect vault-specific conventions for different note types (daily, zettelkasten IDs, MOC prefixes)
- Allow configured exceptions (e.g., templates folder may use different naming)

**Per-edit + quality gate**: Per-edit checks the name of the edited file. Quality gate scans all files.

---

## Dimension 4: Template Compliance

**Role**: Verify that notes match their template structure.

**What the tool must do**:
- Identify which template a note was created from (via frontmatter field or folder location)
- Verify the note contains expected sections/headings from its template
- Detect notes with a template type that are missing required template sections

**Adaptation**:
- Detect templates from Templater plugin (`templates/` folder, `.obsidian/plugins/templater-obsidian/`)
- Detect templates from core Templates plugin (`.obsidian/templates.json`)
- Map template types to expected structure using existing template files
- Skip if vault has no templates configured

**Quality gate only** — requires reading template definitions and comparing against all notes.

---

## Dimension 5: Tag Hygiene

**Role**: Maintain clean, consistent tagging.

**What the tool must do**:
- Detect orphan tags (used only once across the entire vault)
- Detect case inconsistencies (e.g., `#Project` vs `#project`)
- Detect likely synonyms (e.g., `#todo` and `#todos`)
- Check consistency between frontmatter `tags:` field and inline `#tags`

**Adaptation**:
- Detect existing tag conventions (nested tags like `#project/active`, flat tags)
- Respect Dataview-style inline fields that use tags
- Configure minimum usage threshold for orphan tag detection (default: 1)

**Quality gate only** — requires scanning all notes to build a tag inventory.

---

## Dimension 6: Documentation Quality

**Role**: Content quality checks for vault notes.

**What the tool must do**:
- Spelling: catch typos in note content (auto-fixable where possible)
- Heading hierarchy: no skipped heading levels (e.g., `#` followed by `###`)
- Empty notes: detect notes with less than 10 characters of body content (excluding frontmatter)
- Long lines: detect very long lines that hurt readability (configurable threshold)

**Default configuration**:
- Spelling tool: researched during setup (codespell, cspell, typos-cli are candidates)
- Heading hierarchy: warn on skipped levels
- Empty note threshold: < 10 characters body
- Long line threshold: disabled by default (Obsidian handles wrapping)

**Adaptation**:
- Configure custom dictionary for domain-specific terms
- Respect code blocks and math blocks (skip spell checking inside them)
- Configure language for non-English vaults

**Per-edit (spelling) + quality gate (full scan)**: Spelling auto-fix runs on each edit. Full documentation quality scan runs in the quality gate.

---

## Dimension 7: Git Hygiene

**Role**: Keep git history clean and merge-conflict-free.

**What the tool must do**:
- Verify volatile `.obsidian/` files are gitignored:
  - `workspace.json` — changes on every Obsidian focus change
  - `workspace-mobile.json` — mobile workspace state
  - `.obsidian/cache/` — plugin cache directory
- Detect large binary files tracked by git (attachments should use git-lfs or be appropriately sized)
- Verify `.gitignore` covers community plugin data that should not be shared

**Files that SHOULD be tracked** (do not gitignore these):
- `.obsidian/app.json` — core Obsidian settings
- `.obsidian/appearance.json` — theme settings
- `.obsidian/community-plugins.json` — list of installed plugins
- `.obsidian/core-plugins.json` — enabled core plugins
- `.obsidian/hotkeys.json` — custom hotkeys
- Plugin settings: `.obsidian/plugins/*/data.json` (most plugin configs are shareable)

**Files that SHOULD NOT be tracked** (gitignore these):
- `.obsidian/workspace.json` — volatile, changes constantly
- `.obsidian/workspace-mobile.json` — mobile-specific state
- `.obsidian/cache/` — cache directory
- `.obsidian/plugins/*/main.js` — plugin binaries (reinstallable)
- `.obsidian/plugins/*/styles.css` — plugin styles (reinstallable)
- `.obsidian/plugins/*/manifest.json` — plugin manifests (reinstallable)
- `.trash/` — Obsidian trash

**Adaptation**:
- Detect tracked volatile files and offer to `git rm --cached` them
- Detect large binary attachments and suggest git-lfs
- Respect existing `.gitignore` patterns

**Session start + quality gate**: Session start checks for tracked volatile files (non-blocking warning). Quality gate runs full gitignore coverage check.

---

## Hook Architecture

The methodology uses three hook types:

| Hook Event | Script | Behavior | Blocking |
|-----------|--------|----------|----------|
| **SessionStart** | `session-start.sh` | Git hygiene check, vault summary | No (warnings only) |
| **PostToolUse** (Edit\|Write) | `per-edit-fix.sh` | Frontmatter validation, naming check, spelling auto-fix on each `.md` file edit | Yes (exit 2 for unfixable) |
| **Stop** | `quality-gate.sh` | Full quality gate (all enabled dimensions) | Yes (exit 2 -> Claude fixes) |

### Fail-Fast Design

The quality gate runs checks **sequentially and stops at the first failure**. It does NOT collect all errors and report them at once. This is intentional:

- Claude fixes one issue at a time, then the gate re-runs
- Prevents "lost in the middle" — a long list of errors causes Claude to skip or half-fix items
- Each re-run confirms the previous fix didn't introduce new issues
- Faster feedback: common failures (frontmatter, spelling) are checked first

### Hook Output as Prompt

Hook stderr is fed directly to Claude as a prompt. The output must be structured to work well as an instruction, not just as a log message. Every failure output has three parts:

1. **What failed** — the check name and command that was run
2. **Tool output** — the raw error from the tool (file paths, line numbers, error codes)
3. **Diagnostic hint** — a specific instruction telling Claude how to investigate and fix this type of failure

The output ends with an **action directive** that tells Claude to fix the issue immediately rather than explain or stop.

### Output Examples

**Good** — a quality gate failure for frontmatter validation:
```
QUALITY GATE FAILED [frontmatter]:
Command: frontmatter validation (yq + bash)

notes/meeting-notes/2024-03-15.md: missing required field 'tags'
notes/projects/website-redesign.md: date '15 March 2024' is not ISO 8601

Hint: Read each failing note file. Add the missing frontmatter field or
fix the date format to YYYY-MM-DD. Check other notes in the same folder
for the expected frontmatter pattern.

ACTION REQUIRED: You MUST fix the issue shown above. Do NOT stop or
explain — read the failing file, edit the frontmatter to resolve it,
and the quality gate will re-run automatically.
```

**Good** — a per-edit hook reporting an unfixable spelling issue:
```
Per-edit check found issues in notes/research/quantum-computing.md:
SPELLING (codespell):
notes/research/quantum-computing.md:42: qubit ==> qubit (false positive? add to dictionary)
```

### Exit Code Convention

| Exit Code | Meaning | Claude Behavior |
|-----------|---------|-----------------|
| 0 | All checks passed | Claude proceeds normally |
| 1 | Error (script bug, tool not found) | Claude sees error but is not forced to fix |
| 2 | Check failed — stderr is a fix instruction | Claude reads stderr and must fix the issue, then the hook re-runs |

Exit code 2 is the key mechanism. It turns the hook into a feedback loop: fail -> Claude fixes -> hook re-runs -> repeat until clean.

### Hint Writing Guidelines

Each tool check should have a diagnostic hint. Good hints:

- Tell Claude **which file to read** (use the paths from the tool output)
- Tell Claude **how to re-check** a single file after fixing (avoids re-running the full gate)
- Tell Claude **what to fix** (edit the frontmatter, fix the link target, etc.)
- Are **specific to the tool** (not generic "fix the error" advice)

Example hints:
```
[frontmatter]   "Read the failing note and check its YAML frontmatter.
                 Add missing required fields. Fix date formats to
                 YYYY-MM-DD. Verify YAML syntax with a dry run."

[links]         "The reported wikilink target does not exist. Read the
                 note, check the link spelling, and either create the
                 target note or fix the link to point to an existing note."

[spelling]      "Run the spelling tool on the specific file to see
                 context. Fix the typo or add the word to the custom
                 dictionary file if it's a domain-specific term."

[naming]        "The filename contains characters that break wikilinks
                 or cross-platform compatibility. Rename the file using
                 only alphanumeric characters, hyphens, and spaces."

[tags]          "The reported tag has a case inconsistency. Search the
                 vault for all variants and normalize to one casing."
```

---

## GitHub Workflow Integration

Reference `workflow-catalog.md` for workflow categories the setup skill should propose during Phase 2. The setup skill analyzes the vault structure and proposes specific workflows based on detection signals. The `templates/issue-workflow.yml` provides an annotated structural example of the GitHub Actions pattern.

---

## Tool Research

When the setup skill fills each role, it should:

1. **Check what the vault already uses** — respect existing tool choices and community plugins
2. **Research current best tools** (via WebSearch) for any unfilled roles, considering:
   - Markdown/YAML processing capabilities
   - Obsidian-specific awareness (wikilinks, frontmatter, embeds)
   - Speed (quality gate runs on every stop, so tools must be fast)
   - Availability as CLI tools (must run in shell scripts, not just as Obsidian plugins)
   - Cross-platform compatibility (macOS, Linux for CI)
3. **Present tool choices to the user** with rationale before configuring

### Research areas by dimension

| Dimension | Research topics |
|-----------|----------------|
| Frontmatter Integrity | YAML validators (yq, yamllint), frontmatter-specific tools. Use `yq` for YAML parsing — do NOT use python3+PyYAML. |
| Link Integrity | Obsidian link checkers, markdown link validators, custom wikilink resolvers |
| Naming Conventions | Filename linters, custom shell scripts, existing naming convention tools |
| Template Compliance | Template diffing tools, structure validators, custom scripts |
| Tag Hygiene | Tag extraction tools, custom scripts, grep-based approaches |
| Documentation Quality | Spelling (codespell, cspell, typos-cli), markdown linters (markdownlint-cli2), heading validators |
| Git Hygiene | git commands, gitignore validators, git-lfs detection |

---

## Claude Code Hygiene

These checks target the Claude Code development environment itself — project instructions, hooks, and agent configuration. Unlike the 7 content quality dimensions, these ensure the AI-assisted workflow is correctly set up and efficient.

---

### CC1: Project Instructions (CLAUDE.md)

**Role**: Keep CLAUDE.md concise, actionable, and focused so Claude follows every instruction reliably.

**Why this matters**: Keeping CLAUDE.md to ~100 lines produces dramatically better results than longer files. Bloated instructions cause Claude to ignore important rules.

**What to check**:
- Total size <= 2500 tokens (including `@path` imports and `.claude/rules/`)
- No self-evident instructions
- Includes: vault structure summary, quality gate commands, non-obvious conventions

**Default threshold**: 2500 tokens

---

### CC2: Hook & Script Hygiene

**Role**: Ensure Claude Code hooks are correctly configured so the feedback loop works reliably.

**What to check**:
- All registered hook scripts exist and are executable (`chmod +x`)
- Exit codes follow convention: 0 (pass), 2 (fail with feedback)
- Matchers are case-sensitive correct (`Edit|Write` not `edit|write`)
- Scripts use `${CLAUDE_PROJECT_DIR}` for paths, not hardcoded absolute paths
- Timeouts are appropriate: quality gate >= 120s, per-edit <= 30s

---

### CC3: Context Efficiency

**Role**: Keep skills, prompts, and configuration right-sized to preserve Claude's context window.

**What to check**:
- Skill SKILL.md files <= 500 lines
- Subagent prompts are scoped to a single responsibility
- Heavy reference material uses progressive disclosure
