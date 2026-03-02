#!/bin/bash
# Per-edit hook: runs cargo fmt on changed Rust files
# Triggered by PostToolUse on Edit|Write
# Exit 0 = success (fixes applied silently)
# Exit 2 = unfixable issues fed back to Claude (fail-fast: one error at a time)
#
# THIS IS AN ANNOTATED EXAMPLE. cargo fmt is the standard Rust formatter.
# The setup skill should verify it's available and configured. What matters
# is the PATTERN:
#   - Detect Rust file from tool input JSON
#   - Run auto-fixers silently (exit 0 if all fixed)
#   - FAIL-FAST: stop at the first unfixable error, report only that one
#   - Structured output: check name, command, tool output, hint, action directive

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.filePath // empty')

# Only process Rust files
if [[ -z "$FILE_PATH" ]] || [[ "$FILE_PATH" != *.rs ]]; then
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

# 1. cargo fmt on the specific file
FMT_OUTPUT=$(cargo fmt -- "$FILE_PATH" 2>&1)
if [ $? -ne 0 ]; then
    fail "cargo-fmt" "cargo fmt -- $FILE_PATH" "$FMT_OUTPUT" \
        "cargo fmt failed — this usually means a syntax error prevents formatting. Read the file at the reported line and fix the syntax error first."
fi

exit 0
