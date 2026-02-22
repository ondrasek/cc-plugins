# cc-plugins

A collection of Claude Code plugins by [ondrasek](https://github.com/ondrasek).

## Installation

Add this marketplace to Claude Code:

```
/plugin marketplace add ondrasek/cc-plugins
```

Then install individual plugins:

```
/plugin install python-blueprint@cc-plugins
```

## Available Plugins

| Plugin | Description |
|--------|-------------|
| [python-blueprint](plugins/python-blueprint/) | Intelligent Python quality methodology — analyzes your project and configures 8 dimensions of quality tooling |
| [dotnet-blueprint](plugins/dotnet-blueprint/) | Intelligent .NET quality methodology — analyzes your project and configures 8 dimensions of quality tooling |
| [rust-blueprint](plugins/rust-blueprint/) | Intelligent Rust quality methodology — analyzes your project and configures 8 dimensions of quality tooling (with WASM support) |
| [github-issues](plugins/github-issues/) | Intelligent GitHub issue management — natural language queries, codebase-aware creation, progressive refinement (epics → user stories) |
| [github-releases](plugins/github-releases/) | Intelligent GitHub release management — version detection, conventional commit analysis, release notes generation |
| [git-auto-commit](plugins/git-auto-commit/) | Fail-fast cascade checker — enforces staging, version bumps, conventional commits, and push via Stop hook |
| [auto-release](plugins/auto-release/) | Automated semantic versioning and GitHub releases from conventional commits |

## Local Development

```bash
# Test a specific plugin against a target project
cd /path/to/target-project
claude --plugin-dir /path/to/cc-plugins/plugins/python-blueprint
```
