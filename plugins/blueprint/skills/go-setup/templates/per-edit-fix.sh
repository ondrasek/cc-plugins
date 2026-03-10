#!/bin/bash
# Per-edit hook: runs gofumpt + goimports on changed Go files
# Triggered by PostToolUse on Edit|Write
# Exit 0 = success (fixes applied silently)
# Exit 2 = unfixable issues fed back to Claude (fail-fast: one error at a time)
#
# THIS IS AN ANNOTATED EXAMPLE. gofumpt and goimports are the standard Go
# formatters. The setup skill should verify they're available. What matters
# is the PATTERN:
#   - Detect Go file from tool input JSON
#   - Run auto-fixers silently (exit 0 if all fixed)
#   - FAIL-FAST: stop at the first unfixable error, report only that one
#   - Structured output: check name, command, tool output, hint, action directive

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.filePath // empty')

# Only process Go files
if [[ -z "$FILE_PATH" ]] || [[ "$FILE_PATH" != *.go ]]; then
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

# 1. gofumpt (strict superset of gofmt) — format the file
if command -v gofumpt &>/dev/null; then
    FMT_OUTPUT=$(gofumpt -w "$FILE_PATH" 2>&1)
    if [ $? -ne 0 ]; then
        fail "gofumpt" "gofumpt -w $FILE_PATH" "$FMT_OUTPUT" \
            "gofumpt failed — this usually means a syntax error prevents formatting. Read the file at the reported line and fix the syntax error first."
    fi
elif command -v gofmt &>/dev/null; then
    FMT_OUTPUT=$(gofmt -w "$FILE_PATH" 2>&1)
    if [ $? -ne 0 ]; then
        fail "gofmt" "gofmt -w $FILE_PATH" "$FMT_OUTPUT" \
            "gofmt failed — this usually means a syntax error prevents formatting. Read the file at the reported line and fix the syntax error first."
    fi
fi

# 2. goimports — fix imports
if command -v goimports &>/dev/null; then
    IMP_OUTPUT=$(goimports -w "$FILE_PATH" 2>&1)
    if [ $? -ne 0 ]; then
        fail "goimports" "goimports -w $FILE_PATH" "$IMP_OUTPUT" \
            "goimports failed. Read the file and check for syntax errors or unresolvable import paths."
    fi
fi

exit 0
