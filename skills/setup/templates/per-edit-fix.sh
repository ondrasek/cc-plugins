#!/bin/bash
# Per-edit hook: runs fast auto-fixers on changed Python files
# Triggered by PostToolUse on Edit|Write
# Exit 0 = success (fixes applied silently)
# Exit 2 = unfixable issues fed back to Claude
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

ERRORS=""

# 1. Ruff lint with auto-fix (safe fixes only)
LINT_OUTPUT=$(${PACKAGE_MANAGER_RUN} ruff check --fix --quiet "$FILE_PATH" 2>&1)
LINT_EXIT=$?
if [ $LINT_EXIT -ne 0 ]; then
    REMAINING=$(${PACKAGE_MANAGER_RUN} ruff check --quiet "$FILE_PATH" 2>&1)
    if [ -n "$REMAINING" ]; then
        ERRORS="${ERRORS}LINT (ruff):\n${REMAINING}\n\n"
    fi
fi

# 2. Ruff format (always auto-fixes)
${PACKAGE_MANAGER_RUN} ruff format --quiet "$FILE_PATH" 2>&1

# 3. Codespell with auto-fix
SPELL_OUTPUT=$(${PACKAGE_MANAGER_RUN} codespell --quiet-level=2 "$FILE_PATH" 2>&1)
if [ -n "$SPELL_OUTPUT" ]; then
    ${PACKAGE_MANAGER_RUN} codespell --write-changes --quiet-level=2 "$FILE_PATH" 2>/dev/null
    REMAINING=$(${PACKAGE_MANAGER_RUN} codespell --quiet-level=2 "$FILE_PATH" 2>&1)
    if [ -n "$REMAINING" ]; then
        ERRORS="${ERRORS}SPELLING (codespell):\n${REMAINING}\n\n"
    fi
fi

# Report unfixable issues back to Claude
if [ -n "$ERRORS" ]; then
    echo -e "Per-edit check found issues in ${FILE_PATH}:\n${ERRORS}" >&2
    exit 2
fi

exit 0
