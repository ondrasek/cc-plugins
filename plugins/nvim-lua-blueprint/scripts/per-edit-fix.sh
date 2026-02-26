#!/bin/bash
# Plugin-level per-edit hook: runs StyLua on changed Lua files
# Installed with the nvim-lua-blueprint plugin — runs on any project using the plugin.
# Uses ${CLAUDE_PLUGIN_ROOT} for plugin-relative path resolution.
#
# Triggered by PostToolUse on Edit|Write
# Exit 0 = success (fixes applied silently)
# Exit 2 = unfixable issues fed back to Claude

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
if command -v stylua &>/dev/null; then
    FMT_OUTPUT=$(stylua "$FILE_PATH" 2>&1)
    FMT_EXIT=$?
    if [ $FMT_EXIT -ne 0 ]; then
        ERRORS="${ERRORS}FORMAT (stylua):\n${FMT_OUTPUT}\n\n"
    fi
fi

# Report unfixable issues back to Claude
if [ -n "$ERRORS" ]; then
    echo -e "Per-edit check found issues in ${FILE_PATH}:\n${ERRORS}" >&2
    exit 2
fi

exit 0
