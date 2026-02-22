#!/bin/bash
# PostToolUse(Bash) hook: verify commit messages reference the linked issue
# Blocking — exits 2 if the commit message is missing the issue reference.
#
# Only triggers on `git commit` commands (skips merge/rebase).
# Branch naming convention: <issue-number>-<description>

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Only check git commit commands
if [[ -z "$COMMAND" ]] || [[ "$COMMAND" != *"git commit"* ]]; then
    exit 0
fi

# Skip merge and rebase commits
if [[ "$COMMAND" == *"merge"* ]] || [[ "$COMMAND" == *"rebase"* ]]; then
    exit 0
fi

BRANCH=$(git branch --show-current 2>/dev/null)
if [[ -z "$BRANCH" ]]; then
    exit 0
fi

# Extract issue number from branch name
if [[ ! "$BRANCH" =~ ^([0-9]+)- ]]; then
    exit 0
fi
ISSUE_NUMBER="${BASH_REMATCH[1]}"

# Get the last commit message
COMMIT_MSG=$(git log -1 --format=%B 2>/dev/null)
if [[ -z "$COMMIT_MSG" ]]; then
    exit 0
fi

# Check if the commit message references the issue
if echo "$COMMIT_MSG" | grep -qF "#${ISSUE_NUMBER}"; then
    exit 0
fi

# Missing reference — block and instruct Claude to amend
cat >&2 <<EOF
COMMIT REFERENCE CHECK FAILED

What failed: Commit message does not reference issue #${ISSUE_NUMBER}.

Commit message:
${COMMIT_MSG}

Branch: ${BRANCH}

Hint: The branch name indicates this work is for issue #${ISSUE_NUMBER}, but the commit message does not contain '#${ISSUE_NUMBER}'.

Action: You MUST amend the commit to include '#${ISSUE_NUMBER}' in the message. Run:
  git commit --amend -m "<message that includes #${ISSUE_NUMBER}>"
EOF

exit 2
