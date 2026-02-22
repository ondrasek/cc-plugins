#!/bin/bash
# Stop hook: remind to update the linked issue with a summary of work done
# Non-blocking — always exits 0.
#
# Only triggers if there are new local commits not yet on the remote.

BRANCH=$(git branch --show-current 2>/dev/null)
if [[ -z "$BRANCH" ]]; then
    exit 0
fi

# Extract issue number from branch name
if [[ ! "$BRANCH" =~ ^([0-9]+)- ]]; then
    exit 0
fi
ISSUE_NUMBER="${BASH_REMATCH[1]}"

# Check for new commits not on the remote
NEW_COMMITS=$(git log @{u}..HEAD --oneline 2>/dev/null)
if [[ -z "$NEW_COMMITS" ]]; then
    exit 0
fi

COMMIT_COUNT=$(echo "$NEW_COMMITS" | wc -l | tr -d ' ')

echo "You made ${COMMIT_COUNT} commit(s) on branch '${BRANCH}' linked to issue #${ISSUE_NUMBER}." >&2
echo "Consider updating the issue with a summary of work done:" >&2
echo "  gh issue comment ${ISSUE_NUMBER} --body 'Summary of changes...'" >&2

exit 0
