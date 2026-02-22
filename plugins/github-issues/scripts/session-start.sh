#!/bin/bash
# SessionStart hook: display issue context when on an issue-linked branch
# Non-blocking — always exits 0.
#
# Branch naming convention: <issue-number>-<description>
# Example: 42-fix-login-bug → fetches issue #42

BRANCH=$(git branch --show-current 2>/dev/null)
if [[ -z "$BRANCH" ]]; then
    exit 0
fi

# Extract issue number from branch name (leading digits before first hyphen)
if [[ ! "$BRANCH" =~ ^([0-9]+)- ]]; then
    exit 0
fi
ISSUE_NUMBER="${BASH_REMATCH[1]}"

# Fetch issue details
ISSUE_JSON=$(gh issue view "$ISSUE_NUMBER" --json number,title,state,labels,assignees 2>/dev/null)
if [[ $? -ne 0 ]] || [[ -z "$ISSUE_JSON" ]]; then
    exit 0
fi

TITLE=$(echo "$ISSUE_JSON" | jq -r '.title')
STATE=$(echo "$ISSUE_JSON" | jq -r '.state')
LABELS=$(echo "$ISSUE_JSON" | jq -r '[.labels[].name] | join(", ")')
ASSIGNEES=$(echo "$ISSUE_JSON" | jq -r '[.assignees[].login] | join(", ")')

echo "Branch '$BRANCH' is linked to issue #${ISSUE_NUMBER}." >&2
echo "  Title:     $TITLE" >&2
echo "  State:     $STATE" >&2
if [[ -n "$LABELS" ]]; then
    echo "  Labels:    $LABELS" >&2
fi
if [[ -n "$ASSIGNEES" ]]; then
    echo "  Assignees: $ASSIGNEES" >&2
fi

exit 0
