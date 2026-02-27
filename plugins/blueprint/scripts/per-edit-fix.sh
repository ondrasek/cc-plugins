#!/bin/bash
# Plugin-level per-edit hook: routes auto-fixers by file extension.
# Supports Python (.py), C# (.cs), Rust (.rs), and Lua (.lua) files.
# Uses ${CLAUDE_PLUGIN_ROOT} for plugin-relative path resolution.
#
# Triggered by PostToolUse on Edit|Write
# Exit 0 = success (fixes applied silently)
# Exit 2 = unfixable issues fed back to Claude

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.filePath // empty')

# No file path — nothing to do
if [[ -z "$FILE_PATH" ]]; then
    exit 0
fi

# File doesn't exist — nothing to do
if [[ ! -f "$FILE_PATH" ]]; then
    exit 0
fi

ERRORS=""

case "$FILE_PATH" in
    *.py)
        # --- Python: ruff lint+format, codespell ---
        PROJ_DIR="${CLAUDE_PROJECT_DIR:-.}"

        # Detect package manager runner
        if command -v uv &>/dev/null && [[ -f "${PROJ_DIR}/uv.lock" || -f "${PROJ_DIR}/pyproject.toml" ]]; then
            RUN="uv run"
        elif command -v poetry &>/dev/null && [[ -f "${PROJ_DIR}/poetry.lock" ]]; then
            RUN="poetry run"
        elif command -v pdm &>/dev/null && [[ -f "${PROJ_DIR}/pdm.lock" ]]; then
            RUN="pdm run"
        else
            RUN="python -m"
        fi

        # Ruff lint with auto-fix (safe fixes only)
        if command -v ruff &>/dev/null || $RUN ruff --version &>/dev/null 2>&1; then
            LINT_OUTPUT=$($RUN ruff check --fix --quiet "$FILE_PATH" 2>&1)
            if [ $? -ne 0 ]; then
                REMAINING=$($RUN ruff check --quiet "$FILE_PATH" 2>&1)
                if [ -n "$REMAINING" ]; then
                    ERRORS="${ERRORS}LINT (ruff):\n${REMAINING}\n\n"
                fi
            fi
            $RUN ruff format --quiet "$FILE_PATH" 2>&1
        fi

        # Codespell with auto-fix
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
        ;;

    *.cs)
        # --- C#: dotnet format ---
        PROJ_DIR="${CLAUDE_PROJECT_DIR:-.}"
        SLN_FILE=$(find "$PROJ_DIR" -maxdepth 2 -name '*.sln' -print -quit 2>/dev/null)

        if [ -z "$SLN_FILE" ]; then
            CSPROJ_DIR=$(dirname "$FILE_PATH")
            while [ "$CSPROJ_DIR" != "/" ] && [ "$CSPROJ_DIR" != "." ]; do
                CSPROJ=$(find "$CSPROJ_DIR" -maxdepth 1 -name '*.csproj' -print -quit 2>/dev/null)
                [ -n "$CSPROJ" ] && break
                CSPROJ_DIR=$(dirname "$CSPROJ_DIR")
            done
            TARGET="${CSPROJ:-}"
        else
            TARGET="$SLN_FILE"
        fi

        if [ -n "$TARGET" ]; then
            FMT_OUTPUT=$(dotnet format "$TARGET" --include "$FILE_PATH" --verbosity quiet 2>&1)
            FMT_EXIT=$?

            if [ $FMT_EXIT -ne 0 ]; then
                ERRORS="${ERRORS}FORMAT (dotnet format):\n${FMT_OUTPUT}\n\n"
            else
                VERIFY_OUTPUT=$(dotnet format "$TARGET" --include "$FILE_PATH" --verify-no-changes --verbosity quiet 2>&1)
                if [ $? -ne 0 ]; then
                    ERRORS="${ERRORS}FORMAT (dotnet format):\n${VERIFY_OUTPUT}\n\n"
                fi
            fi
        fi
        ;;

    *.rs)
        # --- Rust: cargo fmt ---
        if command -v cargo &>/dev/null; then
            FMT_OUTPUT=$(cargo fmt -- "$FILE_PATH" 2>&1)
            FMT_EXIT=$?
            if [ $FMT_EXIT -ne 0 ]; then
                ERRORS="${ERRORS}FORMAT (cargo fmt):\n${FMT_OUTPUT}\n\n"
            fi
        fi
        ;;

    *.lua)
        # --- Lua: stylua ---
        if command -v stylua &>/dev/null; then
            FMT_OUTPUT=$(stylua "$FILE_PATH" 2>&1)
            FMT_EXIT=$?
            if [ $FMT_EXIT -ne 0 ]; then
                ERRORS="${ERRORS}FORMAT (stylua):\n${FMT_OUTPUT}\n\n"
            fi
        fi
        ;;

    *)
        # No matching language — exit silently
        exit 0
        ;;
esac

# Report unfixable issues back to Claude
if [ -n "$ERRORS" ]; then
    echo -e "Per-edit check found issues in ${FILE_PATH}:\n${ERRORS}" >&2
    exit 2
fi

exit 0
