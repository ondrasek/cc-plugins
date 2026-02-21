#!/bin/bash
# Auto-commit hook: stages, commits, and pushes all changes when Claude stops
# Exit 0 = silent success; exit 2 = feed error back to Claude

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
