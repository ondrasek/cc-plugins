#!/bin/bash
# Plugin-level session start hook: detect Obsidian vault and check git hygiene
# Non-blocking — always exits 0.
#
# Checks for volatile .obsidian/ files that should be gitignored

cd "${CLAUDE_PROJECT_DIR:-.}"

# Detect Obsidian vault
if [[ ! -d ".obsidian" ]]; then
    exit 0
fi

# Count notes (excluding .obsidian/ and .git/)
NOTE_COUNT=$(find . -name '*.md' -not -path './.obsidian/*' -not -path './.git/*' | wc -l | tr -d ' ')

# Check for volatile .obsidian/ files tracked by git
VOLATILE_FILES=()
for f in .obsidian/workspace.json .obsidian/workspace-mobile.json; do
    if git ls-files --error-unmatch "$f" 2>/dev/null >&2; then
        VOLATILE_FILES+=("$f")
    fi
done

# Check for .obsidian/cache/ directory tracked by git
CACHE_TRACKED=$(git ls-files .obsidian/cache/ 2>/dev/null)
if [[ -n "$CACHE_TRACKED" ]]; then
    VOLATILE_FILES+=(".obsidian/cache/")
fi

# Report findings
echo "Obsidian vault detected: ${NOTE_COUNT} notes" >&2

if [[ ${#VOLATILE_FILES[@]} -gt 0 ]]; then
    FILE_LIST=$(printf ", %s" "${VOLATILE_FILES[@]}")
    FILE_LIST="${FILE_LIST:2}"  # strip leading ", "
    echo "WARNING: Volatile .obsidian/ files are tracked by git. These cause merge conflicts and should be gitignored: ${FILE_LIST}" >&2
fi

exit 0
