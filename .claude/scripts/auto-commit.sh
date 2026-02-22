#!/bin/bash
# Auto-commit hook: stages, commits, and pushes all changes when Claude stops.
# Includes version-bump enforcement — blocks if plugin files changed but
# plugin.json version wasn't bumped.
# Exit 0 = silent success; exit 2 = feed error back to Claude.
# Compatible with bash 3 (macOS default).

# Guard against infinite loop (e.g., if Claude restarts from hook output)
if [ -n "$CLAUDE_HOOK_RUNNING" ]; then
    exit 0
fi
export CLAUDE_HOOK_RUNNING=1

cd "$CLAUDE_PROJECT_DIR" || exit 0

# Nothing to do if working tree is clean
if [ -z "$(git status --porcelain)" ]; then
    exit 0
fi

# Stage everything
git add -A

# --- Version bump check (before committing) ---
# Compares staged + committed changes against merge-base with main.

check_version_bumps() {
    # Must be in a git repo
    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        return 0
    fi

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

    # Unstage so Claude can fix before we retry
    git reset HEAD --quiet

    # Block with structured message
    cat >&2 <<EOF
BLOCKED: Plugin version not bumped.

The following plugin(s) have changes but their version in plugin.json was not updated:

$(cat "$DETAILS_FILE")
Action required: Determine the appropriate semver increment for each plugin listed above:
- PATCH (x.y.Z): bug fixes, minor tweaks, documentation changes
- MINOR (x.Y.0): new features, new skills, backward-compatible enhancements
- MAJOR (X.0.0): breaking changes to skill interfaces or hook contracts

Update the "version" field in each plugin's .claude-plugin/plugin.json, then the auto-commit hook will re-run on next Stop.
EOF
    return 2
}

check_version_bumps || exit $?

# --- Commit ---

# Build commit message from diff summary
diff_summary=$(git diff --cached --stat)
changed_files=$(git diff --cached --name-only | head -20)

# Use Claude to generate a meaningful commit message, fall back to file list
commit_msg=$(echo -e "Generate a git commit message for these changes. First line max 72 chars, then blank line, then detailed bullet points of what changed. Output ONLY the message, no quotes or markdown fences.\n\nFiles changed:\n${changed_files}\n\nDiff stat:\n${diff_summary}" \
    | claude -p --model haiku 2>/dev/null) || {
    commit_msg="Auto-commit: $(echo "$changed_files" | tr '\n' ', ' | sed 's/,$//')"
}

# Commit without GPG to avoid signing timeouts in automated contexts
commit_output=$(git commit --no-gpg-sign -m "${commit_msg}

Co-Authored-By: Claude <noreply@anthropic.com>" 2>&1) || {
    echo "[auto-commit] Commit failed:" >&2
    echo "$commit_output" >&2
    echo "Fix the issues above and commit manually." >&2
    exit 2
}

# Push
push_output=$(git push -u origin HEAD 2>&1) || {
    echo "[auto-commit] Push failed: $push_output" >&2
    echo "You may need to pull first." >&2
    exit 0
}

echo "[auto-commit] Committed and pushed." >&2
exit 0
