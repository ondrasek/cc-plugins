# blueprint

A Claude Code plugin that intelligently applies quality methodology to Python, .NET, Rust, and Neovim Lua projects. Rather than copying config files, it analyzes your project's ecosystem, researches current best tools, and configures hooks and CI to match.

## Skills (16)

Four skills per supported language:

| Skill | Description |
|-------|-------------|
| `/blueprint:python-setup` | Analyze and configure quality tooling for a Python project |
| `/blueprint:python-audit` | Read-only gap analysis for Python projects |
| `/blueprint:python-update` | Incremental methodology updates for Python projects |
| `/blueprint:python-explain` | Q&A about the Python quality methodology |
| `/blueprint:dotnet-setup` | Analyze and configure quality tooling for a .NET project |
| `/blueprint:dotnet-audit` | Read-only gap analysis for .NET projects |
| `/blueprint:dotnet-update` | Incremental methodology updates for .NET projects |
| `/blueprint:dotnet-explain` | Q&A about the .NET quality methodology |
| `/blueprint:rust-setup` | Analyze and configure quality tooling for a Rust project |
| `/blueprint:rust-audit` | Read-only gap analysis for Rust projects |
| `/blueprint:rust-update` | Incremental methodology updates for Rust projects |
| `/blueprint:rust-explain` | Q&A about the Rust quality methodology |
| `/blueprint:nvim-lua-setup` | Analyze and configure quality tooling for a Neovim Lua plugin |
| `/blueprint:nvim-lua-audit` | Read-only gap analysis for Neovim Lua plugins |
| `/blueprint:nvim-lua-update` | Incremental methodology updates for Neovim Lua plugins |
| `/blueprint:nvim-lua-explain` | Q&A about the Neovim Lua quality methodology |

## Setup Workflow (6 Phases)

All setup skills follow the same workflow:

1. **Analyze** — detect project structure, language version, existing tools, maturity
2. **Plan** — research tools for each quality dimension, determine thresholds, identify conflicts
3. **Configure** — generate/merge config files, create hooks, set up CI
4. **Review** — spawn a reviewer subagent to audit the generated config
5. **Verify** — run quality checks to confirm everything works
6. **Report** — summarize changes and next steps

## Quality Methodology (9 Dimensions)

Each language applies the same 9-dimension framework with technology-specific tools and thresholds:

| Dimension | Role |
|-----------|------|
| Testing & Coverage | Run tests, enforce coverage threshold |
| Linting & Formatting | Consistent style, auto-fix on edit |
| Type Safety | Static type analysis or compiler strictness |
| Security Analysis | Vulnerability pattern detection |
| Code Complexity | Cyclomatic/cognitive complexity limits |
| Dead Code & Modernization | Unused code, modern idioms |
| Documentation | Documentation coverage on public API |
| Architecture & Import Discipline | Module boundaries, dependency hygiene |
| Version Discipline | Semver 2.0 validation, bump enforcement |

## Plugin-Level Hook

The plugin registers a per-edit auto-format hook that routes by file extension:

- `.py` — ruff lint+format, codespell
- `.cs` — dotnet format
- `.rs` — cargo fmt
- `.lua` — stylua

Other file types are silently ignored.

## Structure

```
.claude-plugin/plugin.json          — Plugin manifest
hooks/hooks.json                    — Plugin-level hook registrations
scripts/per-edit-fix.sh             — Multi-language per-edit formatter
skills/
  shared/references/                — Shared methodology framework and workflows
  python-setup/                     — Python setup skill + references + templates
  python-audit/                     — Python audit skill
  python-update/                    — Python update skill
  python-explain/                   — Python explain skill
  dotnet-setup/                     — .NET setup skill + references + templates
  dotnet-audit/, dotnet-update/, dotnet-explain/
  rust-setup/                       — Rust setup skill + references + templates
  rust-audit/, rust-update/, rust-explain/
  nvim-lua-setup/                   — Neovim Lua setup skill + references + templates
  nvim-lua-audit/, nvim-lua-update/, nvim-lua-explain/
```
