# CLAUDE.md — python-blueprint plugin

## What This Is

A Claude Code plugin that applies a Python quality methodology to any codebase. Instead of copying config files, it analyzes the target project's ecosystem, researches current best tools, and configures hooks/CI intelligently.

## Directory Structure

```
.claude-plugin/plugin.json   — Plugin manifest
skills/
  setup/                     — Main setup skill
    SKILL.md                 — 6-phase workflow (analyze, plan, configure, review, verify, report)
    methodology.md           — 8 quality dimensions (roles, not tools) + hook output format
    analysis-checklist.md    — Target codebase analysis guide
    templates/               — Adaptable config templates
  audit/SKILL.md             — Read-only gap analysis
  update/SKILL.md            — Incremental methodology updates
  explain/SKILL.md           — Methodology Q&A
hooks/hooks.json             — Plugin-level hook registrations
scripts/per-edit-fix.sh      — Plugin-level per-edit auto-fix
plans/                       — Development phase documentation
```

## Working on This Repo

### Testing the plugin locally

```bash
# From a target project directory:
claude --plugin-dir /path/to/python-blueprint
```

### Key files to understand

- `skills/setup/methodology.md` — the intellectual core: 8 quality dimensions defined as roles, hook output format, fail-fast design
- `skills/setup/SKILL.md` — the setup workflow including reviewer subagent
- `skills/setup/templates/` — structural references for generated configs

### Conventions

- Methodology defines **roles** (what to check), not tools. The setup skill researches tools dynamically.
- Templates use shell variables (`${PACKAGE_MANAGER_RUN}`, `${SOURCE_DIR}`, etc.) for customization
- Plugin-level hooks use `${CLAUDE_PLUGIN_ROOT}` for path resolution
- Hook output is structured as a prompt: what failed, tool output, diagnostic hint, action directive
- Quality gate is fail-fast: one error at a time, exit code 2

## Quality Methodology (8 Dimensions)

1. **Testing & Coverage** — run tests, enforce coverage threshold
2. **Linting & Formatting** — consistent style, auto-fix on edit
3. **Type Safety** — static type analysis
4. **Security Analysis** — vulnerability pattern detection
5. **Code Complexity** — cyclomatic complexity limits
6. **Dead Code & Modernization** — unused code, modern idioms
7. **Documentation** — docstring coverage
8. **Architecture & Import Discipline** — import boundaries, dependency hygiene

Each dimension defines a role. The setup skill researches and selects the best current tools to fill each role.
