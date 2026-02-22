#!/bin/bash
# SessionStart hook: display release context for the current repo.
# Non-blocking — always exits 0.

# Must be in a git repo
if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    exit 0
fi

# Check if gh CLI is available
if ! command -v gh &>/dev/null; then
    exit 0
fi

# Get latest release tag
LATEST=$(gh release list --limit 1 --json tagName,publishedAt --jq '.[0]' 2>/dev/null)
if [[ -z "$LATEST" ]] || [[ "$LATEST" == "null" ]]; then
    exit 0
fi

TAG=$(echo "$LATEST" | jq -r '.tagName')
DATE=$(echo "$LATEST" | jq -r '.publishedAt')

if [[ -z "$TAG" ]] || [[ "$TAG" == "null" ]]; then
    exit 0
fi

# Format the date (strip time portion)
SHORT_DATE="${DATE%%T*}"

# Count commits since last tag
COMMIT_COUNT=$(git rev-list "${TAG}..HEAD" --count 2>/dev/null)
if [[ -z "$COMMIT_COUNT" ]]; then
    COMMIT_COUNT=0
fi

# Count draft releases
DRAFT_COUNT=$(gh release list --limit 20 --json isDraft --jq '[.[] | select(.isDraft)] | length' 2>/dev/null)

echo "Latest release: $TAG ($SHORT_DATE)" >&2
if [[ "$COMMIT_COUNT" -gt 0 ]]; then
    echo "  Unreleased commits: $COMMIT_COUNT since $TAG" >&2
fi
if [[ -n "$DRAFT_COUNT" ]] && [[ "$DRAFT_COUNT" -gt 0 ]]; then
    echo "  Draft releases: $DRAFT_COUNT" >&2
fi

exit 0
