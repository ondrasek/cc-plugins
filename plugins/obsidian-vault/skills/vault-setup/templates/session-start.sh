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
    ORPHANS=$(python3 -c "
import os, re
from collections import defaultdict

# Build link targets
incoming = defaultdict(int)
wikilink_re = re.compile(r'\[\[([^\]|#]+?)(?:#[^\]]*)?(?:\|[^\]]+)?\]\]')
all_notes = set()

for root, dirs, files in os.walk('${VAULT_ROOT}'):
    dirs[:] = [d for d in dirs if not d.startswith('.')]
    for f in files:
        if not f.endswith('.md'):
            continue
        name = os.path.splitext(f)[0]
        all_notes.add(name)
        path = os.path.join(root, f)
        with open(path, 'r', encoding='utf-8', errors='replace') as fh:
            content = fh.read()
        for m in wikilink_re.finditer(content):
            target = m.group(1).strip().split('/')[-1]
            incoming[target] += 1

orphans = [n for n in all_notes if incoming.get(n, 0) == 0]
print(len(orphans))
" 2>/dev/null)
    if [ -n "$ORPHANS" ] && [ "$ORPHANS" -gt 0 ]; then
        REPORT="${REPORT}ORPHAN NOTES: ${ORPHANS} notes have no incoming links\n\n"
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

if [ -n "$REPORT" ]; then
    echo -e "Obsidian Vault Health Report:\n${REPORT}" >&2
fi

# Always non-blocking
exit 0
