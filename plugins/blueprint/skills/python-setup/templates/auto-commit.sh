#!/bin/bash
# Auto-commit hook: commits and pushes changes when Claude stops
# Uses Claude CLI to generate commit messages
# Exit code 2 = blocking (Claude will respond to fix issues)
#
# TEMPLATE VARIABLES:
#   ${CO_AUTHOR}  — co-author line (e.g., "Claude Opus 4.6 <noreply@anthropic.com>")

HOOK_LOG="${CLAUDE_PROJECT_DIR:-.}/.claude/hooks/hook-debug.log"
WORKTREE_ID="$(basename "${CLAUDE_PROJECT_DIR:-.}")"
debuglog() {
    echo "[auto-commit@${WORKTREE_ID}] $(date '+%Y-%m-%d %H:%M:%S') $1" >> "$HOOK_LOG"
}
debuglog "=== HOOK STARTED (pid=$$) ==="

# Guard against infinite loop
if [ -n "$CLAUDE_HOOK_RUNNING" ]; then
    echo "[auto-commit] Skipping (already in hook)" >&2
    debuglog "Skipping (CLAUDE_HOOK_RUNNING already set)"
    exit 0
fi
export CLAUDE_HOOK_RUNNING=1

cd "$CLAUDE_PROJECT_DIR"

# Detect linked worktree for stderr labels
GIT_DIR=$(git rev-parse --git-dir 2>/dev/null)
GIT_COMMON_DIR=$(git rev-parse --git-common-dir 2>/dev/null)
if [ "$GIT_DIR" != "$GIT_COMMON_DIR" ]; then
    WT_LABEL=" (worktree: ${WORKTREE_ID})"
else
    WT_LABEL=""
fi

# Check for uncommitted changes
if [ -z "$(git status --porcelain)" ]; then
    echo "[auto-commit${WT_LABEL}] No changes to commit" >&2
    debuglog "No changes to commit (exit 0)"
    exit 0
fi

echo "[auto-commit${WT_LABEL}] Detected uncommitted changes" >&2

# Stage all changes
git add -A

# Get diff for commit message generation
diff_summary=$(git diff --cached --stat)
changed_files=$(git diff --cached --name-only | head -10 | tr '\n' ', ')

echo "[auto-commit${WT_LABEL}] Generating commit message..." >&2

# Try Claude for commit message, fallback to simple message
commit_msg=$(echo "$diff_summary" | claude -p "Generate a concise git commit message (max 72 chars first line) for these changes. Output ONLY the commit message, no quotes or explanation:" --model sonnet 2>/dev/null) || {
    commit_msg="WIP: ${changed_files%, }"
    echo "[auto-commit${WT_LABEL}] Using fallback commit message" >&2
}

echo "[auto-commit${WT_LABEL}] Committing: $commit_msg" >&2

# Commit (no GPG sign to avoid timeout in automated contexts)
commit_output=$(git commit --no-gpg-sign -m "$commit_msg

Co-Authored-By: ${CO_AUTHOR}" 2>&1) || {
    echo "" >&2
    echo "AUTO-COMMIT FAILED [pre-commit hook]${WT_LABEL}:" >&2
    echo "Command: git commit" >&2
    echo "" >&2
    echo "$commit_output" >&2
    echo "" >&2
    echo "Hint: The pre-commit hook rejected the commit. Read the error output above to identify which check failed and which files are affected. Fix the source code issues, then the auto-commit will re-run when you stop again." >&2
    echo "" >&2
    echo "ACTION REQUIRED: You MUST fix the issue shown above. Do NOT stop or explain — read the failing file, edit the source code to resolve it, and the auto-commit will re-run automatically when you stop." >&2
    exit 2
}

echo "[auto-commit${WT_LABEL}] Commit successful" >&2

echo "[auto-commit${WT_LABEL}] Pushing to origin..." >&2
push_output=$(git push -u origin HEAD 2>&1) || {
    echo "[auto-commit${WT_LABEL}] Push failed: $push_output" >&2
    echo "[auto-commit${WT_LABEL}] You may need to pull first" >&2
    exit 0
}

echo "[auto-commit${WT_LABEL}] Push successful" >&2
debuglog "=== HOOK FINISHED — push successful (exit 0) ==="
exit 0
