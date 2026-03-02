#!/bin/bash
# Per-edit hook: runs fast auto-fixers on changed Python files
# Triggered by PostToolUse on Edit|Write
# Exit 0 = success (fixes applied silently)
# Exit 2 = unfixable issues fed back to Claude (fail-fast: one error at a time)
#
# THIS IS AN ANNOTATED EXAMPLE. The specific tools (ruff, codespell) are
# current choices for the Linting & Formatting role. The setup skill should
# substitute the best auto-fixable linter, formatter, and spell checker for
# the project's ecosystem. What matters is the PATTERN:
#   - Detect Python file from tool input JSON
#   - Run auto-fixers silently (exit 0 if all fixed)
#   - FAIL-FAST: stop at the first unfixable error, report only that one
#   - Structured output: check name, command, tool output, hint, action directive
#
# TEMPLATE VARIABLES:
#   ${PACKAGE_MANAGER_RUN}  — command prefix (e.g., "uv run", "poetry run")

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.filePath // empty')

# Only process Python files
if [[ -z "$FILE_PATH" ]] || [[ "$FILE_PATH" != *.py ]]; then
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

# 1. Ruff lint with auto-fix (safe fixes only) — fail-fast on unfixable
LINT_OUTPUT=$(${PACKAGE_MANAGER_RUN} ruff check --fix --quiet "$FILE_PATH" 2>&1)
if [ $? -ne 0 ]; then
    REMAINING=$(${PACKAGE_MANAGER_RUN} ruff check --quiet "$FILE_PATH" 2>&1)
    if [ -n "$REMAINING" ]; then
        fail "ruff-lint" "${PACKAGE_MANAGER_RUN} ruff check --quiet $FILE_PATH" "$REMAINING" \
            "Run '${PACKAGE_MANAGER_RUN} ruff check $FILE_PATH --output-format=full' for detailed explanations. Read the file at the reported line and fix the lint issue in the source code."
    fi
fi

# 2. Ruff format (always auto-fixes)
${PACKAGE_MANAGER_RUN} ruff format --quiet "$FILE_PATH" 2>&1

# 3. Codespell with auto-fix — fail-fast on unfixable
SPELL_OUTPUT=$(${PACKAGE_MANAGER_RUN} codespell --quiet-level=2 "$FILE_PATH" 2>&1)
if [ -n "$SPELL_OUTPUT" ]; then
    ${PACKAGE_MANAGER_RUN} codespell --write-changes --quiet-level=2 "$FILE_PATH" 2>/dev/null
    REMAINING=$(${PACKAGE_MANAGER_RUN} codespell --quiet-level=2 "$FILE_PATH" 2>&1)
    if [ -n "$REMAINING" ]; then
        fail "codespell" "${PACKAGE_MANAGER_RUN} codespell --quiet-level=2 $FILE_PATH" "$REMAINING" \
            "Codespell found misspellings it could not auto-fix. Read the file at the reported line and correct the spelling manually."
    fi
fi

exit 0
