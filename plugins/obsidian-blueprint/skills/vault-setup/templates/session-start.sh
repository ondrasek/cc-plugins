#!/bin/bash
# Session start hook: vault health report
# Runs once when a Claude Code session begins
# Non-blocking — reports vault status but doesn't prevent session start
#
# THIS IS AN ANNOTATED EXAMPLE. The specific checks below are current best
# practices for Obsidian vault health monitoring. The setup skill should
# customize based on the vault's structure. What matters is the PATTERN:
#   - Run non-blocking checks (exit 0 always)
#   - Collect warnings and report to stderr
#   - Keep it fast (runs on every session start)
#
# TEMPLATE VARIABLES:
#   ${VAULT_ROOT}  — vault root directory (usually ".")

cd "${CLAUDE_PROJECT_DIR:-.}"

REPORT=""

# 1. Note count by folder
NOTE_COUNTS=$(find ${VAULT_ROOT} -name '*.md' -not -path '*/.obsidian/*' -not -path '*/.git/*' -not -path '*/.trash/*' | \
    awk -F/ '{
        if (NF <= 2) dir = "(root)";
        else { dir = ""; for(i=1; i<NF; i++) { if(i>1) dir = dir "/"; dir = dir $i } }
        count[dir]++
    }
    END { for (d in count) printf "%4d  %s\n", count[d], d }' | sort -rn)
TOTAL_NOTES=$(echo "$NOTE_COUNTS" | awk '{s+=$1} END {print s+0}')
REPORT="${REPORT}VAULT OVERVIEW (${TOTAL_NOTES} notes):\n${NOTE_COUNTS}\n\n"

# 2. Frontmatter coverage
if [ "$TOTAL_NOTES" -gt 0 ]; then
    WITH_FM=$(find ${VAULT_ROOT} -name '*.md' -not -path '*/.obsidian/*' -not -path '*/.git/*' -not -path '*/.trash/*' -exec grep -l '^---$' {} \; | wc -l | tr -d ' ')
    PCT=$(( WITH_FM * 100 / TOTAL_NOTES ))
    REPORT="${REPORT}FRONTMATTER COVERAGE: ${WITH_FM}/${TOTAL_NOTES} notes (${PCT}%)\n"
    if [ "$PCT" -lt 80 ]; then
        REPORT="${REPORT}  Warning: ${PCT}% frontmatter coverage is below the 80% threshold\n"
    fi
    REPORT="${REPORT}\n"
fi

# 3. Orphan note count (notes with no incoming wikilinks)
if [ "$TOTAL_NOTES" -gt 0 ]; then
    # Build a list of all link targets, then count notes with no incoming links
    ALL_NOTES=$(find "${VAULT_ROOT}" -name '*.md' -not -path '*/.obsidian/*' -not -path '*/.git/*' -not -path '*/.trash/*' -exec basename {} .md \; | sort -u)
    LINK_TARGETS=$(grep -roh '\[\[[^]|#]*' "${VAULT_ROOT}" --include='*.md' 2>/dev/null | sed 's/\[\[//' | sed 's|.*/||' | sort -u)
    ORPHAN_COUNT=0
    while IFS= read -r note; do
        if ! echo "$LINK_TARGETS" | grep -qxF "$note"; then
            ORPHAN_COUNT=$((ORPHAN_COUNT + 1))
        fi
    done <<< "$ALL_NOTES"
    if [ "$ORPHAN_COUNT" -gt 0 ]; then
        REPORT="${REPORT}ORPHAN NOTES: ${ORPHAN_COUNT} notes have no incoming links\n\n"
    fi
fi

# 4. Git status summary
if git rev-parse --is-inside-work-tree &>/dev/null; then
    MODIFIED=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
    BRANCH=$(git branch --show-current 2>/dev/null)
    UNPUSHED=$(git log --oneline @{u}..HEAD 2>/dev/null | wc -l | tr -d ' ')
    GIT_STATUS="GIT: branch=${BRANCH:-detached}"
    if [ "$MODIFIED" -gt 0 ]; then
        GIT_STATUS="${GIT_STATUS}, ${MODIFIED} uncommitted changes"
    fi
    if [ "$UNPUSHED" -gt 0 ]; then
        GIT_STATUS="${GIT_STATUS}, ${UNPUSHED} unpushed commits"
    fi
    REPORT="${REPORT}${GIT_STATUS}\n"
fi

# 5. Check yq availability (required for frontmatter validation hooks)
if ! command -v yq &>/dev/null; then
    REPORT="${REPORT}\nWARNING: yq is not installed. Frontmatter validation hooks require yq.\n"
    REPORT="${REPORT}Install: brew install yq (macOS) or https://github.com/mikefarah/yq/releases\n"
fi

if [ -n "$REPORT" ]; then
    echo -e "Obsidian Vault Health Report:\n${REPORT}" >&2
    echo "Re-run this check with: bash \"\${CLAUDE_PROJECT_DIR:-.}\"/.claude/hooks/session-start.sh" >&2
fi

# Always non-blocking
exit 0
