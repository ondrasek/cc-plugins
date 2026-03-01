# cc-plugins

A collection of Claude Code plugins by [ondrasek](https://github.com/ondrasek).

## Installation

Add this marketplace to Claude Code:

```
/plugin marketplace add ondrasek/cc-plugins
```

Then install individual plugins:

```
/plugin install blueprint@cc-plugins
```

## Available Plugins

| Plugin | Description |
|--------|-------------|
| [blueprint](plugins/blueprint/) | Quality methodology for Python, .NET, Rust, and Neovim Lua — analyzes your project and configures 9 dimensions of quality tooling (16 skills: 4 languages x setup/audit/update/explain) |
| [github-issues](plugins/github-issues/) | Intelligent GitHub issue management — natural language queries, codebase-aware creation, progressive refinement (epics → user stories) |
| [github-releases](plugins/github-releases/) | Intelligent GitHub release management — version detection, conventional commit analysis, release notes generation |
| [git-auto-commit](plugins/git-auto-commit/) | Fail-fast cascade checker — enforces staging, version bumps, conventional commits, and push via Stop hook |
| [auto-release](plugins/auto-release/) | Automated semantic versioning and GitHub releases from conventional commits |
| [obsidian-blueprint](plugins/obsidian-blueprint/) | Quality methodology for git-managed Obsidian vaults — analyzes vault structure and configures 7 dimensions of content quality (5 skills: setup/audit/update/explain/calendar) |
| [calendar-access](plugins/calendar-access/) | Read-only calendar access — Google Calendar (gcalcli) and Microsoft 365 (Azure CLI + Graph API), with SessionStart hook for today's events (10 skills: setup/view/search/list-calendars + 6 shortcuts) |

## Standalone Scripts

| Script | Description |
|--------|-------------|
| [python-quality-gate](plugins/python-quality-gate/) | Fail-fast Python quality gate — 14 checks via Stop hook. Not a plugin due to [Claude Code plugin hook bugs](https://github.com/anthropics/claude-code/issues/11509). Install as a project-level hook pointing to the [canonical gist](https://gist.github.com/ondrasek/f796e3c3321fe0033845994f5406eb0d); the script self-updates via ETag. |

## Local Development

```bash
# Test a specific plugin against a target project
cd /path/to/target-project
claude --plugin-dir /path/to/cc-plugins/plugins/blueprint
```
