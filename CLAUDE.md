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
plans/                           — Development phase documentation
```

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
