# Phase 4: Port Agents + Commands

## Status: Planned

## Goal

Move the operational tooling (git workflow, issues, PRs) from `blueprint/.claude/` into the plugin structure so they're installed with the plugin.

## Deliverable

All existing agents and commands working as plugin components, available to any project using the plugin.

## Files to Port

### Agents (from `blueprint/.claude/agents/`)

| Source | Destination | Purpose |
|--------|-------------|---------|
| `git-workflow.md` | `agents/git-workflow.md` | Comprehensive git workflow agent |
| `github-issues-workflow.md` | `agents/github-issues-workflow.md` | GitHub issues management |
| `github-pr-workflow.md` | `agents/github-pr-workflow.md` | GitHub PR workflow |

### Commands (from `blueprint/.claude/commands/`)

| Source | Destination | Purpose |
|--------|-------------|---------|
| `git.md` | `commands/git.md` | Git operations command |
| `pr.md` | `commands/pr.md` | PR creation command |
| `pr-review-loop.md` | `commands/pr-review-loop.md` | Automated PR review loop |
| `issue/*.md` | `commands/issue/*.md` | Issue management commands |

## Adaptation Needed

- Update path references from `$CLAUDE_PROJECT_DIR/.claude/` to plugin-relative paths
- Ensure agents reference plugin resources correctly
- Verify commands work when invoked via plugin namespace (`/python-blueprint:git`, etc.)
- Consider which commands should keep the `issue:` prefix namespace

## Approach

1. Copy each file from `blueprint/.claude/` to the plugin directory
2. Review and update internal path references
3. Test each agent/command in the plugin context
4. Remove any blueprint-specific assumptions

## Verification

- All agents load correctly as plugin components
- All commands are accessible via the plugin namespace
- Path references resolve correctly
- No broken cross-references between agents and commands
