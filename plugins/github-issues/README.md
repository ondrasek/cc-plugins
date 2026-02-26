# github-issues

Intelligent GitHub issue management for Claude Code via the `gh` CLI.

## What It Does

Gives Claude Code natural language access to GitHub issues — querying, creating, refining, and managing issues with codebase awareness, relationship tracking, and best-practice issue structures.

## Prerequisites

- [GitHub CLI](https://cli.github.com) (`gh`) installed and authenticated (`gh auth login`)

## Skills

| Skill | Trigger examples | What it does |
|-------|-----------------|--------------|
| **triage** | "show my issues", "what's assigned to me", "summarize issue #42" | Query and inspect issues with natural language |
| **manage** | "create an issue", "file a bug", "close issue #42", "add labels" | Full CRUD lifecycle with codebase context |
| **refine** | "refine issue #42", "make this an epic", "split into stories" | Progressive refinement: rough ideas → epics → user stories (INVEST) |
| **develop** | "start working on issue #42", "create a branch" | Bridge issues to development workflow |
| **recommend** | "what should I work on", "recommend an issue", "pick my next task" | Analyze issues against codebase activity, severity, and trends to suggest what to tackle next |
| **organize** | "lock issue", "pin this", "transfer to another repo" | Administrative operations |

## Hooks

The plugin includes three hooks that enforce issue reference discipline in git workflows:

| Hook | Event | Blocking? | What it does |
|------|-------|-----------|--------------|
| **session-start** | SessionStart | No | Displays issue context (title, state, labels, assignees) when on an issue-linked branch |
| **commit-reference-check** | PostToolUse(Bash) | Yes (exit 2) | Blocks commits missing `#N` reference on issue-linked branches; instructs Claude to amend |
| **stop-reminder** | Stop | No | Reminds to update the issue with a work summary when there are unpushed commits |

**Branch convention**: Hooks detect issue-linked branches by the pattern `<number>-<description>` (e.g., `42-fix-login-bug` → issue #42). Non-matching branches are silently ignored.

## Cross-Cutting Behaviors

All skills automatically:

- **Search for related issues** before creating or editing
- **Add comments** explaining changes with context
- **Respect label conventions** — check existing labels first, use plain lowercase kebab-case names, no prefixes, never create priority labels

## Installation

```bash
# From the cc-plugins marketplace
/plugin install github-issues@cc-plugins
```

## Local Development

```bash
cd /path/to/your-project
claude --plugin-dir /path/to/cc-plugins/plugins/github-issues
```
