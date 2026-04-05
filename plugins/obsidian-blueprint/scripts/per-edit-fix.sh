#!/bin/bash
# Plugin-level per-edit hook: validates frontmatter and spelling in Obsidian vault notes
# Triggered by PostToolUse on Edit|Write
# Exit 0 = success (fixes applied silently)
# Exit 2 = unfixable issues fed back to Claude (fail-fast: one error at a time)

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.filePath // empty')

# Only process Markdown files outside .obsidian/
if [[ -z "$FILE_PATH" ]] || [[ "$FILE_PATH" != *.md ]]; then
    exit 0
fi
if [[ "$FILE_PATH" == */.obsidian/* ]]; then
    exit 0
fi
# Skip folders whose name starts with ! (e.g., "!templates", "!archive")
if [[ "$FILE_PATH" == */!* ]]; then
    exit 0
fi
# Skip template files (may contain placeholders that fail YAML validation)
if [[ "$(basename "$FILE_PATH")" == "TEMPLATE.md" ]]; then
    exit 0
fi
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

# --- Frontmatter YAML validation ---
# Check if file starts with --- (frontmatter delimiter)
FIRST_LINE=$(head -1 "$FILE_PATH")
if [[ "$FIRST_LINE" == "---" ]]; then
    # Check for closing delimiter
    CLOSING_REL=$(tail -n +2 "$FILE_PATH" | grep -n '^---$' | head -1 | cut -d: -f1)
    if [[ -z "$CLOSING_REL" ]]; then
        fail "frontmatter" "frontmatter delimiter check" \
            "${FILE_PATH}: missing closing '---' delimiter. The file starts with frontmatter but has no closing delimiter." \
            "Add a closing '---' line after the frontmatter YAML block."
    fi
    CLOSING=$((CLOSING_REL + 1))  # adjust for tail -n +2 offset

    # Extract frontmatter content (between first and second ---)
    FRONTMATTER=$(sed -n "2,$((CLOSING - 1))p" "$FILE_PATH")
    if [[ -n "$FRONTMATTER" ]]; then
        # Validate YAML syntax with yq
        if ! command -v yq &>/dev/null; then
            fail "frontmatter" "yq (YAML validation)" \
                "yq is not installed. Cannot validate YAML frontmatter." \
                "Install yq (https://github.com/mikefarah/yq): brew install yq (macOS) or download from GitHub releases."
        fi

        YAML_CHECK=$(echo "$FRONTMATTER" | yq '.' 2>&1 >/dev/null)
        YAML_EXIT=$?
        if [[ $YAML_EXIT -ne 0 ]]; then
            fail "frontmatter" "yq '.' (YAML validation)" "$YAML_CHECK" \
                "The YAML frontmatter has syntax errors. Read the file and fix the YAML between the --- delimiters."
        fi

        # Validate date fields are ISO format (YYYY-MM-DD)
        for DATE_FIELD in date created modified updated published due scheduled; do
            VALUE=$(echo "$FRONTMATTER" | yq ".${DATE_FIELD} // \"\"" 2>/dev/null | tr -d '"')
            if [[ -n "$VALUE" ]] && [[ "$VALUE" != "null" ]]; then
                if [[ ! "$VALUE" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}($|[T ]) ]]; then
                    fail "frontmatter" "date format check" \
                        "${FILE_PATH}: field \"${DATE_FIELD}\" value \"${VALUE}\" is not ISO 8601 format (expected YYYY-MM-DD)" \
                        "Read the file and change the ${DATE_FIELD} field to ISO 8601 format (YYYY-MM-DD)."
                fi
            fi
        done
    fi
fi

# --- Codespell: auto-fix spelling, report unfixable ---
if command -v codespell &>/dev/null; then
    SPELL_OUTPUT=$(codespell --quiet-level=2 "$FILE_PATH" 2>&1)
    if [[ -n "$SPELL_OUTPUT" ]]; then
        codespell --write-changes --quiet-level=2 "$FILE_PATH" 2>/dev/null
        REMAINING=$(codespell --quiet-level=2 "$FILE_PATH" 2>&1)
        if [[ -n "$REMAINING" ]]; then
            fail "codespell" "codespell --quiet-level=2 $FILE_PATH" "$REMAINING" \
                "Codespell found misspellings it could not auto-fix. Read the file at the reported line and correct the spelling manually."
        fi
    fi
fi

exit 0
