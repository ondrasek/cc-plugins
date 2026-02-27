#!/bin/bash
# Per-edit hook: runs fast auto-fixers on changed C# files
# Triggered by PostToolUse on Edit|Write
# Exit 0 = success (fixes applied silently)
# Exit 2 = unfixable issues fed back to Claude
#
# THIS IS AN ANNOTATED EXAMPLE. The specific tool (dotnet format) is the
# built-in formatter for .NET. The setup skill should verify this is
# available and add any additional auto-fixers if needed. What matters is
# the PATTERN:
#   - Detect C# file from tool input JSON
#   - Run auto-fixers silently (exit 0 if all fixed)
#   - Report unfixable issues to stderr (exit 2)
#
# TEMPLATE VARIABLES:
#   ${SOLUTION_FILE}  — solution file (e.g., "MyApp.sln")

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

ERRORS=""

# 1. dotnet format (whitespace + style auto-fix for single file)
FORMAT_OUTPUT=$(dotnet format ${SOLUTION_FILE} --include "$FILE_PATH" --verbosity quiet 2>&1)
FORMAT_EXIT=$?
if [ $FORMAT_EXIT -ne 0 ]; then
    # Check if there are remaining issues
    VERIFY_OUTPUT=$(dotnet format ${SOLUTION_FILE} --include "$FILE_PATH" --verify-no-changes --verbosity quiet 2>&1)
    if [ $? -ne 0 ]; then
        ERRORS="${ERRORS}FORMAT (dotnet format):\n${VERIFY_OUTPUT}\n\n"
    fi
fi

# Report unfixable issues back to Claude
if [ -n "$ERRORS" ]; then
    echo -e "Per-edit check found issues in ${FILE_PATH}:\n${ERRORS}" >&2
    exit 2
fi

exit 0
