#!/bin/bash
# Plugin-level per-edit hook: runs fast auto-fixers on changed C# files
# Installed with the dotnet-blueprint plugin — runs on any project using the plugin.
# Uses ${CLAUDE_PLUGIN_ROOT} for plugin-relative path resolution.
#
# Triggered by PostToolUse on Edit|Write
# Exit 0 = success (fixes applied silently)
# Exit 2 = unfixable issues fed back to Claude

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.filePath // empty')

# Only process C# files
if [[ -z "$FILE_PATH" ]] || [[ "$FILE_PATH" != *.cs ]]; then
    exit 0
fi

# Verify file exists
if [[ ! -f "$FILE_PATH" ]]; then
    exit 0
fi

# Find the solution or project file
PROJ_DIR="${CLAUDE_PROJECT_DIR:-.}"
SLN_FILE=$(find "$PROJ_DIR" -maxdepth 2 -name '*.sln' -print -quit 2>/dev/null)
if [[ -z "$SLN_FILE" ]]; then
    # No solution file, try to find the nearest .csproj
    CSPROJ_FILE=$(find "$(dirname "$FILE_PATH")" -maxdepth 3 -name '*.csproj' -print -quit 2>/dev/null)
    if [[ -z "$CSPROJ_FILE" ]]; then
        exit 0
    fi
    TARGET="$CSPROJ_FILE"
else
    TARGET="$SLN_FILE"
fi

ERRORS=""

# 1. dotnet format (whitespace + style fixes)
if command -v dotnet &>/dev/null; then
    FORMAT_OUTPUT=$(dotnet format "$TARGET" --include "$FILE_PATH" --verbosity quiet 2>&1)
    FORMAT_EXIT=$?
    if [ $FORMAT_EXIT -ne 0 ]; then
        ERRORS="${ERRORS}FORMAT (dotnet format):\n${FORMAT_OUTPUT}\n\n"
    fi
fi

# Report unfixable issues back to Claude
if [ -n "$ERRORS" ]; then
    echo -e "Per-edit check found issues in ${FILE_PATH}:\n${ERRORS}" >&2
    exit 2
fi

exit 0
