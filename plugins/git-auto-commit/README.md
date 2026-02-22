# git-auto-commit

Fail-fast cascade checker that enforces git hygiene when Claude stops. Instead of auto-committing, it detects issues one at a time and instructs Claude to resolve them.

## How It Works

Each time Claude stops, the hook runs a cascade of checks. It blocks on the **first** issue found (exit 2), giving Claude actionable instructions. When Claude resolves it and stops again, the hook progresses to the next check:

```
Stop → Check 1: Remote changes?      → "Pull/merge from remote"
Stop → Check 2: Untracked/modified?   → "Stage your files"
Stop → Check 3: Plugin version bumps? → "Bump versions"
Stop → Check 4: Staged uncommitted?   → "Commit with conventional message"
Stop → Check 5: Unpushed commits?     → "Push to remote"
Stop → All clean                      → exit 0
```

## Cascade Checks

| # | Check | What it detects | Action for Claude |
|---|-------|-----------------|-------------------|
| 1 | Remote changes | Branch behind or diverged from upstream | Pull or rebase |
| 2 | Unstaged changes | Untracked or modified files | Review and stage deliberately |
| 3 | Version bumps | Plugin files changed without version bump | Bump semver in plugin.json |
| 4 | Uncommitted staged | Staged files not yet committed | Commit using conventional format |
| 5 | Unpushed commits | Local commits not pushed to remote | Push to origin |

## Key Design Decisions

- **Claude stages files** — no more `git add -A`. Claude reviews each file and decides what to stage or gitignore.
- **Claude writes commit messages** — no more haiku subprocess. The hook provides conventional commit format reference inline.
- **Claude pushes** — no more auto-push. Claude gets explicit push instructions.
- **Fail-fast** — one issue at a time, resolved before progressing.

## Prerequisites

- **git** — initialized repo with a remote named `origin`
- **jq** — used for version-bump checks on `plugin.json` files

## Exit Codes

| Code | Meaning |
|------|---------|
| `0` | All checks passed (working tree clean, everything pushed) |
| `2` | Action needed — structured error message fed back to Claude |

## Installation

```bash
# From the cc-plugins marketplace
/plugin install git-auto-commit@cc-plugins
```

## Local Development

```bash
cd /path/to/your-project
claude --plugin-dir /path/to/cc-plugins/plugins/git-auto-commit
```
