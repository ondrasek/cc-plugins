# dotnet-blueprint

A Claude Code plugin that intelligently applies a .NET quality methodology to any codebase. Rather than copying config files, it analyzes your project's ecosystem, researches current best tools, and configures hooks and CI to match.

## Skills

### `/dotnet-blueprint:setup`

The main skill. Analyzes your .NET project and configures quality tooling:

1. **Analyze** — detects .NET SDK, target framework, solution structure, frameworks, existing tools
2. **Plan** — researches current best analyzers for each role, determines thresholds, identifies conflicts
3. **Configure** — generates/merges Directory.Build.props, .editorconfig, creates hooks, sets up CI
4. **Review** — spawns a reviewer subagent to audit generated config against the methodology
5. **Verify** — runs quality checks to confirm everything works
6. **Report** — summarizes changes and any manual steps needed

### `/dotnet-blueprint:audit`

Gap analysis — compares your project's current setup against the full methodology and reports missing or outdated configuration.

### `/dotnet-blueprint:update`

Incremental updates — applies methodology improvements while preserving your project-specific customizations.

### `/dotnet-blueprint:explain`

Read-only Q&A — answers questions about why specific analyzers are included, how thresholds were chosen, and what each quality dimension covers.

## Quality Methodology

The plugin applies a 9-dimension quality methodology. Each dimension defines a **role** (what needs to happen), not a specific tool. The setup skill researches and selects the best current tools at runtime.

| Dimension | Role |
|-----------|------|
| Testing & Coverage | Run tests, enforce coverage threshold |
| Linting & Formatting | Consistent style, auto-fix on edit, Roslyn analyzers |
| Type Safety | Nullable reference types, strict analysis level |
| Security Analysis | Security analyzers, NuGet vulnerability audit |
| Code Complexity | Cyclomatic complexity limits |
| Dead Code & Modernization | Unused code detection, modern C# idioms |
| Documentation | XML documentation comment coverage |
| Architecture | Dependency boundaries, namespace discipline |

The methodology adapts to your project — adjusting analyzer selection, thresholds, and configuration based on project type, size, maturity, and existing tooling.

## Plugin-Level Hooks

The plugin registers a per-edit auto-fix hook that runs on any project using the plugin. It auto-detects the solution file and runs `dotnet format` on every C# file edit.

## Structure

```
.claude-plugin/plugin.json   — Plugin manifest
skills/                      — Skill definitions and methodology
hooks/                       — Plugin-level hook registrations
scripts/                     — Hook scripts
```
