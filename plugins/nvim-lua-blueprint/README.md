# nvim-lua-blueprint

A Claude Code plugin that intelligently applies a Neovim Lua plugin quality methodology to any codebase. Rather than copying config files, it analyzes your project's ecosystem, researches current best tools, and configures hooks and CI to match.

## Skills

### `/nvim-lua-blueprint:setup`

The main skill. Analyzes your Neovim Lua plugin and configures quality tooling:

1. **Analyze** — detects project structure, plugin type, test framework (plenary/mini.test/busted), existing tools
2. **Plan** — researches current best tools for each role, determines thresholds, identifies conflicts
3. **Configure** — generates/merges selene.toml, .stylua.toml, .luarc.json, creates hooks, sets up CI with Neovim matrix
4. **Review** — spawns a reviewer subagent to audit generated config against the methodology
5. **Verify** — runs quality checks to confirm everything works
6. **Report** — summarizes changes and any manual steps needed

### `/nvim-lua-blueprint:audit`

Gap analysis — compares your plugin's current setup against the full methodology and reports missing or outdated configuration.

### `/nvim-lua-blueprint:update`

Incremental updates — applies methodology improvements while preserving your project-specific customizations.

### `/nvim-lua-blueprint:explain`

Read-only Q&A — answers questions about why specific tools are included, how thresholds were chosen, and what each quality dimension covers.

## Quality Methodology

The plugin applies a 9-dimension quality methodology. Each dimension defines a **role** (what needs to happen), not a specific tool. The setup skill researches and selects the best current tools at runtime.

| Dimension | Role | Default Tools |
|-----------|------|---------------|
| Testing & Coverage | Run tests, enforce coverage threshold | plenary/mini.test/busted + luacov |
| Linting & Formatting | Consistent style, detect bugs, auto-format on edit | Selene + StyLua |
| Type Safety | LuaCATS type checking in batch mode | lua-language-server |
| Security Analysis | Detect dangerous patterns (limited ecosystem) | Selene rules + grep patterns |
| Code Complexity | Cyclomatic complexity limits | Lizard |
| Dead Code & Modernization | Unused vars/imports, deprecated API usage | Selene |
| Documentation | Vimdoc help files, doc generator staleness | lemmy-help / mini.doc |
| Architecture | Plugin structure conventions, plugin/ size limits | Custom checks |
| Version Discipline | Semver validation, bump enforcement | semver-check.sh |

The methodology adapts to your plugin — adjusting tool selection, thresholds, and configuration based on plugin type (colorscheme, UI, library, etc.), size, maturity, and existing tooling.

## Plugin-Level Hooks

The plugin registers a per-edit auto-format hook that runs on any project using the plugin. It runs StyLua on every Lua file edit.

## Structure

```
.claude-plugin/plugin.json   — Plugin manifest
skills/                      — Skill definitions and methodology
hooks/                       — Plugin-level hook registrations
scripts/                     — Hook scripts
```
