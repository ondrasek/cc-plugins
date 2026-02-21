#!/bin/bash
# Style guide check for CLI output formatting.
# Only applies to projects using click for CLI output.
#
# Rules:
#   1. No ASCII art splitter lines (===, ---, ***) in click.echo/print calls
#   2. Section headings must use click.style() with bold=True and a color
#   3. Section headings should include an emoji
#
# TEMPLATE VARIABLES:
#   ${SOURCE_DIR}  — source directory (e.g., "src/")

set -euo pipefail

SRC_DIR="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel)}/${SOURCE_DIR}"

# Find all Python files that use click
CLI_FILES=()
while IFS= read -r -d '' f; do
    if grep -qE '(import click|from click)' "$f" 2>/dev/null; then
        CLI_FILES+=("$f")
    fi
done < <(find "$SRC_DIR" -name '*.py' -print0 2>/dev/null)

# Exit cleanly if no click-using files found
[ ${#CLI_FILES[@]} -eq 0 ] && exit 0

ERRORS=()

for f in "${CLI_FILES[@]}"; do
    [ -f "$f" ] || continue
    basename=$(basename "$f")

    # Rule 1: No ASCII splitter lines in echo/print calls
    while IFS= read -r match; do
        ERRORS+=("$basename: ASCII splitter line detected — use emoji + click.style(ALL CAPS, bold=True) instead: $match")
    done < <(grep -nE '(echo|print)\(.*"[=\-\*]{3,}' "$f" 2>/dev/null || true)

    # Rule 2: Section heading echo() calls should use click.style with bold
    while IFS= read -r match; do
        if echo "$match" | grep -q 'click\.style'; then
            continue
        fi
        ERRORS+=("$basename: Unstyled ALL-CAPS heading — wrap with click.style(..., bold=True, fg=COLOR): $match")
    done < <(grep -nE 'click\.echo\("[^"]*[A-Z]{3,}[^"]*"\)' "$f" 2>/dev/null || true)
done

if [ ${#ERRORS[@]} -gt 0 ]; then
    echo "STYLE GUIDE VIOLATIONS:" >&2
    echo "" >&2
    for err in "${ERRORS[@]}"; do
        echo "  - $err" >&2
    done
    echo "" >&2
    echo "Design rules: Section headings must use emoji + click.style(ALL CAPS text, fg=COLOR, bold=True). No ASCII splitter lines (===, ---, ***)." >&2
    exit 1
fi

exit 0
