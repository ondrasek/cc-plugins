# git-auto-commit

Fail-fast cascade checker that enforces git hygiene when Claude stops. The hook detects issues one at a time and instructs Claude to resolve them — together they keep origin up to date so no work is lost.

## How It Works

Each time Claude stops, the hook runs a cascade of checks. It blocks on the **first** issue found (exit 2), giving Claude actionable instructions. When Claude resolves it and stops again, the hook progresses to the next check:

```
Stop → Check 0: Already clean?        → exit 0 (fast path)
Stop → Check 1: Remote changes?       → "Pull/merge from remote"
Stop → Check 2: Untracked/modified?    → "Stage with git add -A"
Stop → Check 3: Staged uncommitted?    → "Commit with conventional message"
Stop → Check 4: Unpushed commits?      → "Push to remote"
Stop → All clean                       → exit 0
```

## Cascade Checks

| # | Check | What it detects | Action for Claude |
|---|-------|-----------------|-------------------|
| 0 | Fast path | Working tree clean and pushed | Exit immediately |
| 1 | Remote changes | Branch behind or diverged from upstream | Pull or rebase |
| 2 | Unstaged changes | Untracked or modified files | `git add -A` (`.gitignore` handles exclusions) |
| 3 | Uncommitted staged | Staged files not yet committed | Commit using conventional format |
| 4 | Unpushed commits | Local commits not pushed to remote | Push to origin |

## Key Design Decisions

- **Claude commits early and often** — the hook enforces it, Claude does the git operations
- **`.gitignore` handles exclusions** — staging uses `git add -A`, no file-by-file review
- **Conventional Commits** — the hook provides the format spec inline so Claude writes the right message
- **Fail-fast** — one issue at a time, resolved before progressing

## Prerequisites

- **git** — initialized repo with a remote named `origin`

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
