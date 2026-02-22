# git-auto-commit

Auto-commit and push all changes when Claude stops.

## What It Does

Registers a **Stop** hook that fires every time Claude finishes a turn. The hook:

1. Checks for uncommitted changes — exits silently if the working tree is clean
2. Stages everything (`git add -A`)
3. Enforces **version-bump checks** — if any plugin's files changed but its `plugin.json` version wasn't bumped, the commit is blocked and Claude is told to fix it
4. Generates a commit message using `claude -p --model haiku` (falls back to a file-list summary)
5. Commits with `--no-gpg-sign` and pushes to origin

## Prerequisites

- **git** — initialized repo with a remote named `origin`
- **Claude CLI** (`claude`) — used for commit message generation
- **jq** — used for version-bump checks on `plugin.json` files

## How It Works

| Hook | Event | Blocking? | Timeout | What it does |
|------|-------|-----------|---------|--------------|
| **auto-commit** | Stop | Yes (exit 2 on failure) | 120s | Stage, commit, and push changes |

### Re-entrancy Guard

The script sets `CLAUDE_HOOK_RUNNING=1` to prevent infinite loops — if Claude restarts in response to hook output, the hook exits immediately.

### Exit Codes

| Code | Meaning |
|------|---------|
| `0` | Success (committed and pushed, or nothing to do) |
| `0` | Push failed (non-blocking — warns but doesn't retry) |
| `2` | Commit failed or version bump required (blocks — feeds error back to Claude) |

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
