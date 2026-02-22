#!/bin/bash
# Stop hook: fail-fast cascade checker for git hygiene.
# Checks one condition per Stop, exits 2 with actionable instructions for Claude.
# Claude resolves the issue, next Stop re-runs and progresses to the next check.
#
# Cascade order:
#   1. Remote changes? → "Pull/merge from remote"
#   2. Untracked/modified files? → "Stage your files"
#   3. Plugin version bumps? → "Bump versions"
#   4. Staged uncommitted? → "Commit with conventional message"
#   5. Unpushed commits? → "Push to remote"
#   All clean → exit 0
#
# Exit 0 = clean; exit 2 = action needed (message fed back to Claude).
# Compatible with bash 3 (macOS default).

# Guard against infinite loop (e.g., if Claude restarts from hook output)
if [ -n "$CLAUDE_HOOK_RUNNING" ]; then
    exit 0
fi
export CLAUDE_HOOK_RUNNING=1

cd "$CLAUDE_PROJECT_DIR" || exit 0

# Must be in a git repo
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    exit 0
fi

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
Action required: Review each file and decide whether to stage or gitignore it.
  - Use \`git add <specific files>\` to stage files you want committed
  - Do NOT use \`git add -A\` — be deliberate about what gets staged
  - Add paths to .gitignore if they should not be tracked (build artifacts, secrets, etc.)
EOF
    return 2
}

check_unstaged_changes || exit $?

# ─── Check 3: Plugin version bumps ───────────────────────────────────────────

check_version_bumps() {
    # Determine current branch
    local CURRENT_BRANCH
    CURRENT_BRANCH="$(git symbolic-ref --short HEAD 2>/dev/null || echo "")"
    if [ -z "$CURRENT_BRANCH" ]; then
        return 0  # detached HEAD
    fi

    # Determine base ref for comparison
    local BASE_REF
    if [ "$CURRENT_BRANCH" = "main" ] || [ "$CURRENT_BRANCH" = "master" ]; then
        BASE_REF="HEAD~1"
        if ! git rev-parse HEAD~1 >/dev/null 2>&1; then
            return 0  # first commit in repo
        fi
    else
        BASE_REF="$(git merge-base HEAD main 2>/dev/null || git merge-base HEAD master 2>/dev/null || echo "")"
        if [ -z "$BASE_REF" ]; then
            return 0
        fi
    fi

    # Get files changed: committed since base ref + currently staged
    local COMMITTED_FILES STAGED_FILES CHANGED_FILES
    COMMITTED_FILES="$(git diff --name-only "$BASE_REF"..HEAD 2>/dev/null || echo "")"
    STAGED_FILES="$(git diff --cached --name-only 2>/dev/null || echo "")"
    CHANGED_FILES="$(printf '%s\n%s' "$COMMITTED_FILES" "$STAGED_FILES" | sort -u | grep -v '^$' || echo "")"

    if [ -z "$CHANGED_FILES" ]; then
        return 0
    fi

    # Extract unique plugin directories from changed files
    local AFFECTED_PLUGINS
    AFFECTED_PLUGINS="$(echo "$CHANGED_FILES" | grep -oE '^plugins/[^/]+' | sort -u || echo "")"
    if [ -z "$AFFECTED_PLUGINS" ]; then
        return 0  # no plugin files changed
    fi

    # Temp file to collect unbumped plugin details (bash 3 compatible)
    local DETAILS_FILE
    DETAILS_FILE="$(mktemp "${TMPDIR:-/tmp}/version-bump-check.XXXXXX")"
    trap 'rm -f "$DETAILS_FILE"' RETURN

    # Check each affected plugin for version bump
    local PLUGIN_PATH PLUGIN_NAME MANIFEST BASE_VERSION HEAD_VERSION PLUGIN_FILES
    for PLUGIN_PATH in $AFFECTED_PLUGINS; do
        PLUGIN_NAME="$(basename "$PLUGIN_PATH")"
        MANIFEST="$PLUGIN_PATH/.claude-plugin/plugin.json"

        # Get version at base ref (empty if plugin didn't exist)
        BASE_VERSION="$(git show "$BASE_REF:$MANIFEST" 2>/dev/null | jq -r '.version // empty' 2>/dev/null || echo "")"
        if [ -z "$BASE_VERSION" ]; then
            continue  # new plugin, no prior version to compare
        fi

        # Get version from the staged/working tree file
        if [ -f "$MANIFEST" ]; then
            HEAD_VERSION="$(jq -r '.version // empty' "$MANIFEST" 2>/dev/null || echo "")"
        else
            continue  # plugin.json removed
        fi

        if [ -z "$HEAD_VERSION" ]; then
            continue  # no version field
        fi

        # Compare versions
        if [ "$BASE_VERSION" = "$HEAD_VERSION" ]; then
            PLUGIN_FILES="$(echo "$CHANGED_FILES" | grep "^$PLUGIN_PATH/" | head -10 | sed 's/^/    - /')"
            printf '  Plugin: %s\n  Current version: %s\n  Manifest: %s\n  Changed files:\n%s\n\n' \
                "$PLUGIN_NAME" "$HEAD_VERSION" "$MANIFEST" "$PLUGIN_FILES" >> "$DETAILS_FILE"
        fi
    done

    # If no unbumped plugins, pass
    if [ ! -s "$DETAILS_FILE" ]; then
        return 0
    fi

    # Block with structured message
    cat >&2 <<EOF
PLUGIN VERSION NOT BUMPED

What failed: Plugin(s) have changes but their version in plugin.json was not updated.

$(cat "$DETAILS_FILE")
Action required: Determine the appropriate semver increment for each plugin listed above:
  - PATCH (x.y.Z): bug fixes, minor tweaks, documentation changes
  - MINOR (x.Y.0): new features, new skills, backward-compatible enhancements
  - MAJOR (X.0.0): breaking changes to skill interfaces or hook contracts

Update the "version" field in each plugin's .claude-plugin/plugin.json.
EOF
    return 2
}

check_version_bumps || exit $?

# ─── Check 4: Staged uncommitted changes ─────────────────────────────────────

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

# ─── Check 5: Unpushed commits ───────────────────────────────────────────────

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
