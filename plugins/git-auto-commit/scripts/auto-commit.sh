#!/bin/bash
# Stop hook: fail-fast cascade checker for git hygiene.
# Checks one condition per Stop, exits 2 with actionable instructions for Claude.
# Claude resolves the issue, next Stop re-runs and progresses to the next check.
#
# Cascade order:
#   0. Already clean? → exit 0 (fast path)
#   1. Remote changes? → "Pull/merge from remote"
#   2. Untracked/modified files? → "Stage with git add -A"
#   3. Staged uncommitted? → "Commit with conventional message"
#   4. Unpushed commits? → "Push to remote"
#   All clean → exit 0
#
# Exit 0 = clean; exit 2 = action needed (message fed back to Claude).
# Compatible with bash 3 (macOS default).

cd "$CLAUDE_PROJECT_DIR" || exit 0

# Must be in a git repo
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    exit 0
fi

# ─── Check 0: Fast path — nothing to do ──────────────────────────────────────

check_clean() {
    # Quick check: any dirty files at all?
    if [ -n "$(git status --porcelain)" ]; then
        return 1  # dirty, continue to other checks
    fi

    # Working tree is clean — but are there unpushed commits?
    local UPSTREAM
    UPSTREAM="$(git rev-parse --abbrev-ref '@{u}' 2>/dev/null || echo "")"
    if [ -z "$UPSTREAM" ]; then
        # No upstream — if there are commits, we need to push
        local BRANCH
        BRANCH="$(git symbolic-ref --short HEAD 2>/dev/null || echo "")"
        if [ -n "$BRANCH" ] && [ "$(git rev-list --count HEAD 2>/dev/null || echo "0")" != "0" ]; then
            return 1  # has commits but no upstream
        fi
        return 0  # nothing to do
    fi

    # Check if local matches remote (without fetching — that's Check 1's job)
    local LOCAL REMOTE
    LOCAL="$(git rev-parse HEAD 2>/dev/null || echo "")"
    REMOTE="$(git rev-parse '@{u}' 2>/dev/null || echo "")"
    if [ "$LOCAL" = "$REMOTE" ]; then
        return 0  # clean and pushed
    fi

    return 1  # unpushed commits
}

check_clean && exit 0

# ─── Check 1: Remote changes (behind or diverged) ────────────────────────────

check_remote_changes() {
    # Need a branch with an upstream to check
    local BRANCH
    BRANCH="$(git symbolic-ref --short HEAD 2>/dev/null || echo "")"
    if [ -z "$BRANCH" ]; then
        return 0  # detached HEAD, skip
    fi

    # Check if upstream exists
    local UPSTREAM
    UPSTREAM="$(git rev-parse --abbrev-ref '@{u}' 2>/dev/null || echo "")"
    if [ -z "$UPSTREAM" ]; then
        return 0  # no upstream tracking, check later at push time
    fi

    # Fetch quietly to see if remote has new commits
    git fetch origin --quiet 2>/dev/null || return 0

    local LOCAL REMOTE BASE
    LOCAL="$(git rev-parse HEAD)"
    REMOTE="$(git rev-parse '@{u}' 2>/dev/null || echo "")"
    BASE="$(git merge-base HEAD '@{u}' 2>/dev/null || echo "")"

    if [ -z "$REMOTE" ] || [ "$LOCAL" = "$REMOTE" ]; then
        return 0  # up to date
    fi

    if [ "$LOCAL" = "$BASE" ]; then
        # Behind remote
        local BEHIND_COUNT
        BEHIND_COUNT="$(git rev-list --count HEAD..'@{u}' 2>/dev/null || echo "some")"
        cat >&2 <<EOF
REMOTE CHANGES DETECTED

What failed: Local branch is behind ${UPSTREAM} by ${BEHIND_COUNT} commit(s).

Context:
  - Branch: ${BRANCH}
  - Upstream: ${UPSTREAM}
  - Local HEAD: $(git rev-parse --short HEAD)
  - Remote HEAD: $(git rev-parse --short '@{u}')

Action required: Pull remote changes before committing.
  command: git pull origin ${BRANCH}
EOF
        return 2
    fi

    if [ "$REMOTE" = "$BASE" ]; then
        return 0  # ahead only, will push later
    fi

    # Diverged
    cat >&2 <<EOF
REMOTE CHANGES DETECTED — BRANCHES DIVERGED

What failed: Local and remote branches have diverged.

Context:
  - Branch: ${BRANCH}
  - Upstream: ${UPSTREAM}
  - Commits ahead: $(git rev-list --count '@{u}'..HEAD 2>/dev/null || echo "unknown")
  - Commits behind: $(git rev-list --count HEAD..'@{u}' 2>/dev/null || echo "unknown")

Action required: Pull and rebase remote changes, then resolve any conflicts.
  command: git pull --rebase origin ${BRANCH}
EOF
    return 2
}

check_remote_changes || exit $?

# ─── Check 2: Untracked or modified files ────────────────────────────────────

check_unstaged_changes() {
    # Untracked files (not gitignored)
    local UNTRACKED
    UNTRACKED="$(git ls-files --others --exclude-standard)"
    # Modified tracked files (not staged)
    local MODIFIED
    MODIFIED="$(git diff --name-only)"

    if [ -z "$UNTRACKED" ] && [ -z "$MODIFIED" ]; then
        return 0
    fi

    local FILES_LIST=""
    if [ -n "$UNTRACKED" ]; then
        FILES_LIST="${FILES_LIST}  Untracked files:\n$(echo "$UNTRACKED" | sed 's/^/    - /')\n"
    fi
    if [ -n "$MODIFIED" ]; then
        FILES_LIST="${FILES_LIST}  Modified files:\n$(echo "$MODIFIED" | sed 's/^/    - /')\n"
    fi

    cat >&2 <<EOF
UNSTAGED CHANGES DETECTED

What failed: There are untracked or modified files that need to be staged.

Context:
$(printf '%b' "$FILES_LIST")
Action required: Stage all changes. The .gitignore file handles exclusions.
  command: git add -A
EOF
    return 2
}

check_unstaged_changes || exit $?

# ─── Check 3: Staged uncommitted changes ─────────────────────────────────────

check_staged_uncommitted() {
    local STAGED
    STAGED="$(git diff --cached --name-only)"
    if [ -z "$STAGED" ]; then
        return 0
    fi

    local DIFF_STAT
    DIFF_STAT="$(git diff --cached --stat)"

    cat >&2 <<EOF
STAGED CHANGES NOT COMMITTED

What failed: There are staged changes that need to be committed.

Context:
  Staged files:
$(echo "$STAGED" | sed 's/^/    - /')

  Diff stat:
$(echo "$DIFF_STAT" | sed 's/^/    /')

Action required: Commit these staged changes using Conventional Commits format.

Format: <type>[(scope)][!]: <description>

Types: feat (new feature), fix (bug fix), docs (documentation),
       refactor (restructuring), chore (maintenance), perf (performance),
       test (tests), build (build system), ci (CI config), style (formatting)

Add ! after type for breaking changes: feat!: remove deprecated API

Write a detailed commit message:
  - First line: type(scope): concise summary (max 72 chars)
  - Blank line
  - Body: bullet points explaining what changed and why
  - Blank line
  - Footer: Co-Authored-By: Claude <noreply@anthropic.com>

Examples:
  feat(auto-commit): add cascade checker for git hygiene
  fix(hooks): correct exit code on version bump failure
  chore: update marketplace manifest with new plugin
  refactor(auto-commit)!: replace auto-staging with manual staging cascade
EOF
    return 2
}

check_staged_uncommitted || exit $?

# ─── Check 4: Unpushed commits ───────────────────────────────────────────────

check_unpushed() {
    local BRANCH
    BRANCH="$(git symbolic-ref --short HEAD 2>/dev/null || echo "")"
    if [ -z "$BRANCH" ]; then
        return 0  # detached HEAD
    fi

    # Check if upstream exists
    local UPSTREAM
    UPSTREAM="$(git rev-parse --abbrev-ref '@{u}' 2>/dev/null || echo "")"

    if [ -z "$UPSTREAM" ]; then
        # No upstream tracking — check if there are any commits to push
        local COMMIT_COUNT
        COMMIT_COUNT="$(git rev-list --count HEAD 2>/dev/null || echo "0")"
        if [ "$COMMIT_COUNT" = "0" ]; then
            return 0
        fi

        cat >&2 <<EOF
NO UPSTREAM TRACKING

What failed: Branch '${BRANCH}' has no upstream tracking branch.

Context:
  - Branch: ${BRANCH}
  - Commits: ${COMMIT_COUNT}

Action required: Push and set upstream tracking.
  command: git push -u origin ${BRANCH}
EOF
        return 2
    fi

    # Fetch to get latest remote state (may already be fetched in check 1)
    git fetch origin --quiet 2>/dev/null || true

    local LOCAL REMOTE
    LOCAL="$(git rev-parse HEAD)"
    REMOTE="$(git rev-parse '@{u}' 2>/dev/null || echo "")"

    if [ -z "$REMOTE" ] || [ "$LOCAL" = "$REMOTE" ]; then
        return 0  # up to date
    fi

    local BASE
    BASE="$(git merge-base HEAD '@{u}' 2>/dev/null || echo "")"

    if [ "$REMOTE" = "$BASE" ]; then
        # Ahead of remote — need to push
        local AHEAD_COUNT
        AHEAD_COUNT="$(git rev-list --count '@{u}'..HEAD 2>/dev/null || echo "some")"
        cat >&2 <<EOF
UNPUSHED COMMITS

What failed: Local branch is ahead of ${UPSTREAM} by ${AHEAD_COUNT} commit(s).

Context:
  - Branch: ${BRANCH}
  - Unpushed commits:
$(git log --oneline '@{u}'..HEAD 2>/dev/null | head -10 | sed 's/^/    /')

Action required: Push commits to remote.
  command: git push origin ${BRANCH}
EOF
        return 2
    fi

    if [ "$LOCAL" = "$BASE" ]; then
        # Behind — shouldn't happen if check 1 passed, but handle it
        cat >&2 <<EOF
REMOTE CHANGES DETECTED

What failed: Local branch fell behind ${UPSTREAM} since last check.

Action required: Pull remote changes.
  command: git pull origin ${BRANCH}
EOF
        return 2
    fi

    # Diverged — shouldn't happen if check 1 passed, but handle it
    cat >&2 <<EOF
BRANCHES DIVERGED

What failed: Local and remote branches have diverged since last check.

Action required: Pull and rebase, then push.
  command: git pull --rebase origin ${BRANCH}
EOF
    return 2
}

check_unpushed || exit $?

# ─── All clean ────────────────────────────────────────────────────────────────

exit 0
