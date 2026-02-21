#!/bin/bash
# Plugin-level per-edit hook: runs fast auto-fixers on changed Python files
# Installed with the python-blueprint plugin — runs on any project using the plugin.
# Uses ${CLAUDE_PLUGIN_ROOT} for plugin-relative path resolution.
#
# Triggered by PostToolUse on Edit|Write
# Exit 0 = success (fixes applied silently)
# Exit 2 = unfixable issues fed back to Claude

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

# Detect package manager runner
if command -v uv &>/dev/null && [[ -f "${CLAUDE_PROJECT_DIR}/uv.lock" || -f "${CLAUDE_PROJECT_DIR}/pyproject.toml" ]]; then
    RUN="uv run"
elif command -v poetry &>/dev/null && [[ -f "${CLAUDE_PROJECT_DIR}/poetry.lock" ]]; then
    RUN="poetry run"
elif command -v pdm &>/dev/null && [[ -f "${CLAUDE_PROJECT_DIR}/pdm.lock" ]]; then
    RUN="pdm run"
else
    RUN="python -m"
fi

ERRORS=""

# 1. Ruff lint with auto-fix (safe fixes only)
if command -v ruff &>/dev/null || $RUN ruff --version &>/dev/null 2>&1; then
    LINT_OUTPUT=$($RUN ruff check --fix --quiet "$FILE_PATH" 2>&1)
    if [ $? -ne 0 ]; then
        REMAINING=$($RUN ruff check --quiet "$FILE_PATH" 2>&1)
        if [ -n "$REMAINING" ]; then
            ERRORS="${ERRORS}LINT (ruff):\n${REMAINING}\n\n"
        fi
    fi

    # 2. Ruff format (always auto-fixes)
    $RUN ruff format --quiet "$FILE_PATH" 2>&1
fi

# 3. Codespell with auto-fix
if $RUN codespell --version &>/dev/null 2>&1; then
    SPELL_OUTPUT=$($RUN codespell --quiet-level=2 "$FILE_PATH" 2>&1)
    if [ -n "$SPELL_OUTPUT" ]; then
        $RUN codespell --write-changes --quiet-level=2 "$FILE_PATH" 2>/dev/null
        REMAINING=$($RUN codespell --quiet-level=2 "$FILE_PATH" 2>&1)
        if [ -n "$REMAINING" ]; then
            ERRORS="${ERRORS}SPELLING (codespell):\n${REMAINING}\n\n"
        fi
    fi
fi

# Report unfixable issues back to Claude
if [ -n "$ERRORS" ]; then
    echo -e "Per-edit check found issues in ${FILE_PATH}:\n${ERRORS}" >&2
    exit 2
fi

exit 0
