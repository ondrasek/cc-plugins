# python-blueprint

A Claude Code plugin that intelligently applies a Python quality methodology to any codebase. Rather than copying config files, it analyzes your project's ecosystem, researches current best tools, and configures hooks and CI to match.

## Installation

Inside Claude Code, run:

```
/plugin marketplace add ondrasek/python-blueprint
/plugin install python-blueprint@python-blueprint
```

Then in any Python project:

```
/python-blueprint:setup
```

### Local development

```bash
cd /path/to/target-project
claude --plugin-dir /path/to/python-blueprint
```

## Skills

### `/python-blueprint:setup`

The main skill. Analyzes your Python project and configures quality tooling:

1. **Analyze** — detects package manager, project structure, Python version, frameworks, existing tools
2. **Plan** — researches current best tools for each role, determines thresholds, identifies conflicts
3. **Configure** — generates/merges pyproject.toml sections, creates hooks, sets up CI
4. **Review** — spawns a reviewer subagent to audit generated config against the methodology
5. **Verify** — runs quality checks to confirm everything works
6. **Report** — summarizes changes and any manual steps needed

### `/python-blueprint:audit`

Gap analysis — compares your project's current setup against the full methodology and reports missing or outdated configuration.

### `/python-blueprint:update`

Incremental updates — applies methodology improvements while preserving your project-specific customizations.

### `/python-blueprint:explain`

Read-only Q&A — answers questions about why specific tools are included, how thresholds were chosen, and what each quality dimension covers.

## Quality Methodology

The plugin applies an 8-dimension quality methodology. Each dimension defines a **role** (what needs to happen), not a specific tool. The setup skill researches and selects the best current tools at runtime.

| Dimension | Role |
|-----------|------|
| Testing & Coverage | Run tests, enforce coverage threshold |
| Linting & Formatting | Consistent style, auto-fix on edit |
| Type Safety | Static type analysis |
| Security Analysis | Vulnerability pattern detection |
| Code Complexity | Cyclomatic complexity limits |
| Dead Code & Modernization | Unused code, modern idioms |
| Documentation | Docstring coverage |
| Architecture | Import boundaries, dependency hygiene |

The methodology adapts to your project — adjusting tool selection, thresholds, and configuration based on project type, size, maturity, and existing tooling.

## Plugin-Level Hooks

The plugin registers a per-edit auto-fix hook that runs on any project using the plugin. It auto-detects the package manager and runs lint/format and spell checking on every Python file edit.

## Project Structure

```
.claude-plugin/plugin.json   — Plugin manifest
skills/                      — Skill definitions and methodology
hooks/                       — Plugin-level hook registrations
scripts/                     — Hook scripts
plans/                       — Development phase documentation
```

## Development

```bash
# Test the plugin locally against a target project
cd /path/to/target-project
claude --plugin-dir /path/to/python-blueprint

# Run the setup skill
/python-blueprint:setup
```
