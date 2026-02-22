# CLAUDE.md — cc-plugins

## What This Is

A multi-plugin marketplace repo for Claude Code. Each plugin lives in its own self-contained directory under `plugins/`.

## Directory Structure

```
.claude-plugin/marketplace.json  — Marketplace manifest (lists all plugins)
plugins/
  python-blueprint/              — Python quality methodology plugin
    .claude-plugin/plugin.json   — Plugin manifest
    skills/                      — setup, audit, update, explain
    hooks/hooks.json             — Plugin-level hook registrations
    scripts/per-edit-fix.sh      — Plugin-level per-edit auto-fix
  dotnet-blueprint/              — .NET quality methodology plugin
    .claude-plugin/plugin.json   — Plugin manifest
    skills/                      — setup, audit, update, explain
    hooks/hooks.json             — Plugin-level hook registrations
    scripts/per-edit-fix.sh      — Plugin-level per-edit auto-fix
  rust-blueprint/                — Rust quality methodology plugin
    .claude-plugin/plugin.json   — Plugin manifest
    skills/                      — setup, audit, update, explain
    hooks/hooks.json             — Plugin-level hook registrations
    scripts/per-edit-fix.sh      — Plugin-level per-edit auto-fix
  github-issues/                 — GitHub issue management utility plugin
    .claude-plugin/plugin.json   — Plugin manifest
    skills/                      — triage, manage, refine, develop, organize
    hooks/hooks.json             — Plugin-level hook registrations
    scripts/                     — session-start, commit-reference-check, stop-reminder
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
claude --plugin-dir /path/to/cc-plugins/plugins/python-blueprint
```

### Adding a new plugin

1. Create `plugins/<plugin-name>/` with `.claude-plugin/plugin.json`, `skills/`, etc.
2. Add an entry to `.claude-plugin/marketplace.json` with `source` pointing to the plugin subdirectory
3. Create a `plugins/<plugin-name>/README.md`
4. Add the plugin to the root README table

## python-blueprint Plugin

### Key files to understand

- `plugins/python-blueprint/skills/setup/methodology.md` — the intellectual core: 8 quality dimensions defined as roles, hook output format, fail-fast design
- `plugins/python-blueprint/skills/setup/SKILL.md` — the setup workflow including reviewer subagent
- `plugins/python-blueprint/skills/setup/templates/` — structural references for generated configs

### Conventions

- Methodology defines **roles** (what to check), not tools. The setup skill researches tools dynamically.
- Templates use shell variables (`${PACKAGE_MANAGER_RUN}`, `${SOURCE_DIR}`, etc.) for customization
- Plugin-level hooks use `${CLAUDE_PLUGIN_ROOT}` for path resolution
- Hook output is structured as a prompt: what failed, tool output, diagnostic hint, action directive
- Quality gate is fail-fast: one error at a time, exit code 2

### Quality Methodology (8 Dimensions)

1. **Testing & Coverage** — run tests, enforce coverage threshold
2. **Linting & Formatting** — consistent style, auto-fix on edit
3. **Type Safety** — static type analysis
4. **Security Analysis** — vulnerability pattern detection
5. **Code Complexity** — cyclomatic complexity limits
6. **Dead Code & Modernization** — unused code, modern idioms
7. **Documentation** — docstring coverage
8. **Architecture & Import Discipline** — import boundaries, dependency hygiene

Each dimension defines a role. The setup skill researches and selects the best current tools to fill each role.

## dotnet-blueprint Plugin

### Key files to understand

- `plugins/dotnet-blueprint/skills/setup/methodology.md` — the intellectual core: 8 quality dimensions defined as roles, hook output format, fail-fast design (adapted for .NET)
- `plugins/dotnet-blueprint/skills/setup/SKILL.md` — the setup workflow including reviewer subagent
- `plugins/dotnet-blueprint/skills/setup/templates/` — structural references for generated configs

### .NET-Specific Conventions

- Same role-based methodology as python-blueprint, adapted for .NET ecosystem
- Templates use shell variables (`${SOLUTION_FILE}`, `${SOURCE_DIR}`, etc.) for customization
- Config centralization via `Directory.Build.props` and `.editorconfig`
- Roslyn analyzers preferred over external CLI tools (run during `dotnet build`)
- Same hook architecture: fail-fast quality gate, per-edit auto-fix, session-start hygiene

## rust-blueprint Plugin

### Key files to understand

- `plugins/rust-blueprint/skills/setup/methodology.md` — the intellectual core: 8 quality dimensions defined as roles, hook output format, fail-fast design (adapted for Rust)
- `plugins/rust-blueprint/skills/setup/SKILL.md` — the setup workflow including reviewer subagent
- `plugins/rust-blueprint/skills/setup/templates/` — structural references for generated configs

### Rust-Specific Conventions

- Same role-based methodology as python-blueprint, adapted for Rust ecosystem
- Templates use shell variables (`${WORKSPACE_FLAG}`, `${MSRV}`, `${COVERAGE_THRESHOLD}`, etc.) for customization
- Config via `Cargo.toml` `[lints]` section, `clippy.toml`, `rustfmt.toml`, `deny.toml`
- clippy preferred as the single linter (covers style, correctness, performance, complexity)
- WASM target detection and adaptation (wasm-pack, wasm-bindgen, wasm32-* targets)
- Same hook architecture: fail-fast quality gate, per-edit auto-fix, session-start hygiene

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

### Skills (5)

1. **triage** — read-only querying, viewing, and status dashboard
2. **manage** — CRUD lifecycle, batch operations, label management
3. **refine** — progressive refinement: rough ideas → epics → user stories (INVEST, SPIDR)
4. **develop** — issue → branch → PR workflow bridge
5. **organize** — lock, unlock, pin, unpin, transfer
