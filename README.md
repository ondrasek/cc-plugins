# python-blueprint

A Claude Code plugin that intelligently applies a Python quality methodology to any codebase. Rather than copying config files, it analyzes your project's ecosystem, selects appropriate tools, and configures hooks and CI to match.

## Installation

```bash
# Install the plugin
claude plugin add /path/to/python-blueprint

# Or use it directly
claude --plugin-dir /path/to/python-blueprint
```

## Skills

### `/python-blueprint:setup`

The main skill. Analyzes your Python project and configures quality tooling:

1. **Analyze** — detects package manager, project structure, Python version, frameworks, existing tools
2. **Plan** — selects tools, determines thresholds, identifies conflicts
3. **Configure** — generates/merges pyproject.toml sections, creates hooks, sets up CI
4. **Verify** — runs quality checks to confirm everything works
5. **Report** — summarizes changes and any manual steps needed

### `/python-blueprint:audit`

Gap analysis — compares your project's current setup against the full methodology and reports missing or outdated configuration.

### `/python-blueprint:update`

Incremental updates — applies methodology improvements while preserving your project-specific customizations.

### `/python-blueprint:explain`

Read-only Q&A — answers questions about why specific tools are included, how thresholds were chosen, and what each quality dimension covers.

## Quality Methodology

The plugin applies an 8-dimension quality methodology:

| Dimension | Tools | What it checks |
|-----------|-------|----------------|
| Testing & Coverage | pytest, coverage | Tests pass, minimum coverage met |
| Linting & Formatting | ruff | Code style, import sorting, formatting |
| Type Safety | pyright, mypy | Static type analysis |
| Security Analysis | bandit, semgrep | Security vulnerabilities, patterns |
| Code Complexity | xenon | Cyclomatic complexity thresholds |
| Dead Code & Modernization | vulture, refurb | Unused code, Python idiom updates |
| Documentation | interrogate | Docstring coverage |
| Architecture | import-linter, deptry | Import discipline, dependency hygiene |

The methodology adapts to your project — adjusting tool selection, thresholds, and configuration based on project type, size, maturity, and existing tooling.

## Plugin-Level Hooks

The plugin registers a per-edit auto-fix hook that runs on any project using the plugin. It auto-detects the package manager and runs ruff lint/format and codespell on every Python file edit.

## Project Structure

```
.claude-plugin/plugin.json   — Plugin manifest
skills/                      — Skill definitions and methodology
hooks/                       — Plugin-level hook registrations
scripts/                     — Hook scripts
plans/                       — Development phase documentation
blueprint/                   — Original blueprint files (reference material)
```

## Development

This plugin is being built in phases. See `plans/` for detailed documentation:

1. Plugin scaffold + CLAUDE.md
2. Methodology document + templates
3. Setup skill
4. Supporting skills (audit, update, explain)
5. End-to-end testing + polish

### Contributing

```bash
# Test the plugin locally against a target project
cd /path/to/target-project
claude --plugin-dir /path/to/python-blueprint

# Run the setup skill
/python-blueprint:setup
```

## Prior Art

This plugin evolved from a git-submodule-based blueprint. The original blueprint files are preserved in `blueprint/` as reference material for the methodology extraction. See `blueprint/README.md` (the previous README) for the original approach.
