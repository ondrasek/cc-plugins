#!/bin/bash
# Per-edit hook: runs StyLua on changed Lua files
# Triggered by PostToolUse on Edit|Write
# Exit 0 = success (fixes applied silently)
# Exit 2 = unfixable issues fed back to Claude
#
# THIS IS AN ANNOTATED EXAMPLE. StyLua is the standard Lua formatter for
# Neovim projects. The setup skill should verify it's available and configured.
# What matters is the PATTERN:
#   - Detect Lua file from tool input JSON
#   - Run auto-fixers silently (exit 0 if all fixed)
#   - Report unfixable issues to stderr (exit 2)
#
# Note: Selene (linter) has NO --fix flag, so only StyLua runs on per-edit.
# Selene issues are caught by the quality gate on Stop.

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.filePath // empty')

# Only process Lua files
if [[ -z "$FILE_PATH" ]] || [[ "$FILE_PATH" != *.lua ]]; then
    exit 0
fi

# Verify file exists
if [[ ! -f "$FILE_PATH" ]]; then
    exit 0
fi

ERRORS=""

# 1. StyLua on the specific file
FMT_OUTPUT=$(stylua "$FILE_PATH" 2>&1)
FMT_EXIT=$?
if [ $FMT_EXIT -ne 0 ]; then
    ERRORS="${ERRORS}FORMAT (stylua):\n${FMT_OUTPUT}\n\n"
fi

# Report unfixable issues back to Claude
if [ -n "$ERRORS" ]; then
    echo -e "Per-edit check found issues in ${FILE_PATH}:\n${ERRORS}" >&2
    exit 2
fi

exit 0
