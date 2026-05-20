#!/bin/bash
# Plugin-level per-edit hook: routes auto-fixers by file extension.
# Supports Python (.py), C# (.cs), Rust (.rs), Go (.go), and Lua (.lua) files.
# Uses ${CLAUDE_PLUGIN_ROOT} for plugin-relative path resolution.
#
# Triggered by PostToolUse on Edit|Write
# Exit 0 = success (fixes applied silently)
# Exit 2 = unfixable issues fed back to Claude (fail-fast: one error at a time)

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

        # Ruff lint with auto-fix (safe fixes only) — fail-fast on unfixable
        if command -v ruff &>/dev/null || $RUN ruff --version &>/dev/null 2>&1; then
            LINT_OUTPUT=$($RUN ruff check --fix --quiet "$FILE_PATH" 2>&1)
            if [ $? -ne 0 ]; then
                REMAINING=$($RUN ruff check --quiet "$FILE_PATH" 2>&1)
                if [ -n "$REMAINING" ]; then
                    fail "ruff-lint" "$RUN ruff check --quiet $FILE_PATH" "$REMAINING" \
                        "Run '$RUN ruff check $FILE_PATH --output-format=full' for detailed explanations. Read the file at the reported line and fix the lint issue in the source code."
                fi
            fi
            $RUN ruff format --quiet "$FILE_PATH" 2>&1
        fi

        # Codespell with auto-fix — fail-fast on unfixable
        if $RUN codespell --version &>/dev/null 2>&1; then
            SPELL_OUTPUT=$($RUN codespell --quiet-level=2 "$FILE_PATH" 2>&1)
            if [ -n "$SPELL_OUTPUT" ]; then
                $RUN codespell --write-changes --quiet-level=2 "$FILE_PATH" 2>/dev/null
                REMAINING=$($RUN codespell --quiet-level=2 "$FILE_PATH" 2>&1)
                if [ -n "$REMAINING" ]; then
                    fail "codespell" "$RUN codespell --quiet-level=2 $FILE_PATH" "$REMAINING" \
                        "Codespell found misspellings it could not auto-fix. Read the file at the reported line and correct the spelling manually."
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
            if [ $? -ne 0 ]; then
                fail "dotnet-format" "dotnet format $TARGET --include $FILE_PATH" "$FMT_OUTPUT" \
                    "dotnet format failed. Check for syntax errors that prevent formatting. Run 'dotnet build $TARGET' to see compilation errors."
            fi

            VERIFY_OUTPUT=$(dotnet format "$TARGET" --include "$FILE_PATH" --verify-no-changes --verbosity quiet 2>&1)
            if [ $? -ne 0 ]; then
                fail "dotnet-format-verify" "dotnet format $TARGET --include $FILE_PATH --verify-no-changes" "$VERIFY_OUTPUT" \
                    "dotnet format ran but formatting differences remain. Read the file and fix formatting manually, or check .editorconfig for conflicting settings."
            fi
        fi
        ;;

    *.rs)
        # --- Rust: cargo fmt ---
        if command -v cargo &>/dev/null; then
            FMT_OUTPUT=$(cargo fmt -- "$FILE_PATH" 2>&1)
            if [ $? -ne 0 ]; then
                fail "cargo-fmt" "cargo fmt -- $FILE_PATH" "$FMT_OUTPUT" \
                    "cargo fmt failed — this usually means a syntax error prevents formatting. Read the file at the reported line and fix the syntax error first."
            fi
        fi
        ;;

    *.go)
        # --- Go: gofumpt + goimports ---
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

        if command -v goimports &>/dev/null; then
            IMP_OUTPUT=$(goimports -w "$FILE_PATH" 2>&1)
            if [ $? -ne 0 ]; then
                fail "goimports" "goimports -w $FILE_PATH" "$IMP_OUTPUT" \
                    "goimports failed. Read the file and check for syntax errors or unresolvable import paths."
            fi
        fi
        ;;

    *.lua)
        # --- Lua: stylua ---
        if command -v stylua &>/dev/null; then
            FMT_OUTPUT=$(stylua "$FILE_PATH" 2>&1)
            if [ $? -ne 0 ]; then
                fail "stylua" "stylua $FILE_PATH" "$FMT_OUTPUT" \
                    "StyLua failed — this usually means a syntax error prevents formatting. Read the file at the reported line and fix the syntax error first."
            fi
        fi
        ;;

    *)
        # No matching language — exit silently
        exit 0
        ;;
esac

exit 0
