#!/bin/bash
# Session start hook: plugin structure and tooling checks
# Runs once when a Claude Code session begins
# Non-blocking — reports issues but doesn't prevent session start
#
# THIS IS AN ANNOTATED EXAMPLE. The checks below verify Neovim plugin
# structure conventions and tool availability. The setup skill should
# adapt based on the project's actual structure. What matters is the PATTERN:
#   - Run non-blocking checks (exit 0 always)
#   - Collect warnings and report to stderr
#   - Keep it fast (runs on every session start)
#
# TEMPLATE VARIABLES:
#   ${SOURCE_DIR}   — main source directory (e.g., "lua/")
#   ${PLUGIN_NAME}  — plugin name

cd "${CLAUDE_PROJECT_DIR:-.}"

WARNINGS=""

# 1. Check plugin/ file sizes (entry points should be small)
for f in plugin/*.lua; do
    [ -f "$f" ] || continue
    LINES=$(wc -l < "$f" | tr -d ' ')
    if [ "$LINES" -gt 30 ]; then
        WARNINGS="${WARNINGS}STRUCTURE: $f has $LINES lines (recommend ≤30 for entry points)\n"
    fi
done

# 2. Check doc/ directory existence
if [ ! -d "doc" ]; then
    WARNINGS="${WARNINGS}DOCUMENTATION: No doc/ directory found. Consider adding vimdoc help files.\n"
fi

# 3. Check selene.toml existence
if [ ! -f "selene.toml" ]; then
    WARNINGS="${WARNINGS}LINTING: No selene.toml found. Run /nvim-lua-blueprint:setup to configure.\n"
fi

# 4. Check .stylua.toml existence
if [ ! -f ".stylua.toml" ] && [ ! -f "stylua.toml" ]; then
    WARNINGS="${WARNINGS}FORMATTING: No .stylua.toml found. Run /nvim-lua-blueprint:setup to configure.\n"
fi

# 5. Check tool availability
if ! command -v selene &>/dev/null; then
    WARNINGS="${WARNINGS}TOOLS: selene not found. Install with: cargo install selene\n"
fi
if ! command -v stylua &>/dev/null; then
    WARNINGS="${WARNINGS}TOOLS: stylua not found. Install with: cargo install stylua\n"
fi

if [ -n "$WARNINGS" ]; then
    echo -e "Session start checks found issues:\n${WARNINGS}" >&2
    echo "These are non-blocking warnings. Consider fixing them during this session." >&2
    exit 0
fi

exit 0
