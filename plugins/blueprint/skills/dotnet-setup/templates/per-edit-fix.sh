#!/bin/bash
# Per-edit hook: runs fast auto-fixers on changed C# files
# Triggered by PostToolUse on Edit|Write
# Exit 0 = success (fixes applied silently)
# Exit 2 = unfixable issues fed back to Claude (fail-fast: one error at a time)
#
# THIS IS AN ANNOTATED EXAMPLE. The specific tool (dotnet format) is the
# built-in formatter for .NET. The setup skill should verify this is
# available and add any additional auto-fixers if needed. What matters is
# the PATTERN:
#   - Detect C# file from tool input JSON
#   - Run auto-fixers silently (exit 0 if all fixed)
#   - FAIL-FAST: stop at the first unfixable error, report only that one
#   - Structured output: check name, command, tool output, hint, action directive
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

fail() {
    local name="$1" cmd="$2" output="$3" hint="$4"
    echo "" >&2
    echo "PER-EDIT CHECK FAILED [$name] in ${FILE_PATH}:" >&2
    echo "Command: $cmd" >&2
    echo "" >&2
    echo "$output" >&2
    echo "" >&2
    if [ -n "$hint" ]; then
        echo "Hint: $hint" >&2
        echo "" >&2
    fi
    echo "ACTION REQUIRED: You MUST fix the issue shown above. Do NOT stop or explain — read the file at the reported line, edit the source code to resolve it, and the check will re-run on next edit." >&2
    exit 2
}

# 1. dotnet format (whitespace + style auto-fix for single file)
FORMAT_OUTPUT=$(dotnet format ${SOLUTION_FILE} --include "$FILE_PATH" --verbosity quiet 2>&1)
FORMAT_EXIT=$?
if [ $FORMAT_EXIT -ne 0 ]; then
    fail "dotnet-format" "dotnet format ${SOLUTION_FILE} --include $FILE_PATH" "$FORMAT_OUTPUT" \
        "dotnet format failed to apply formatting. Check for syntax errors in the file that prevent formatting. Run 'dotnet build ${SOLUTION_FILE}' to see compilation errors."
fi

# Verify formatting was fully applied
VERIFY_OUTPUT=$(dotnet format ${SOLUTION_FILE} --include "$FILE_PATH" --verify-no-changes --verbosity quiet 2>&1)
if [ $? -ne 0 ]; then
    fail "dotnet-format-verify" "dotnet format ${SOLUTION_FILE} --include $FILE_PATH --verify-no-changes" "$VERIFY_OUTPUT" \
        "dotnet format ran but formatting differences remain. This may indicate conflicting .editorconfig rules. Read the file and fix formatting manually, or check .editorconfig for conflicting settings."
fi

exit 0
