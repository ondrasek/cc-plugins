#!/bin/bash
# Per-edit hook: runs fast auto-fixers on changed markdown files
# Triggered by PostToolUse on Edit|Write
# Exit 0 = success (fixes applied silently)
# Exit 2 = unfixable issues fed back to Claude (fail-fast: one error at a time)
#
# THIS IS AN ANNOTATED EXAMPLE. The specific tools (yq, codespell) are
# current choices for the Frontmatter & Spelling roles. The setup skill should
# substitute the best auto-fixable tools for the vault's ecosystem. What
# matters is the PATTERN:
#   - Detect markdown file from tool input JSON
#   - Run auto-fixers silently (exit 0 if all fixed)
#   - FAIL-FAST: stop at the first unfixable error, report only that one
#   - Structured output: check name, command, tool output, hint, action directive
#
# TEMPLATE VARIABLES:
#   ${REQUIRED_FIELDS}  — comma-separated required frontmatter fields

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.filePath // empty')

# Only process markdown files
if [[ -z "$FILE_PATH" ]] || [[ "$FILE_PATH" != *.md ]]; then
    exit 0
fi

# Verify file exists
if [[ ! -f "$FILE_PATH" ]]; then
    exit 0
fi

# Skip .obsidian directory
if [[ "$FILE_PATH" == */.obsidian/* ]]; then
    exit 0
fi
# Skip folders whose name starts with ! (e.g., "!templates", "!archive")
if [[ "$FILE_PATH" == */!* ]]; then
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

# 1. YAML frontmatter validity and required fields (using yq)
FIRST_LINE=$(head -1 "$FILE_PATH")
if [[ "$FIRST_LINE" == "---" ]]; then
    CLOSING_REL=$(tail -n +2 "$FILE_PATH" | grep -n '^---$' | head -1 | cut -d: -f1)
    if [[ -z "$CLOSING_REL" ]]; then
        fail "frontmatter" "frontmatter delimiter check" \
            "${FILE_PATH}: unclosed frontmatter (missing closing ---)" \
            "Add a closing '---' line after the frontmatter YAML block."
    fi
    CLOSING=$((CLOSING_REL + 1))  # adjust for tail -n +2 offset

    FRONTMATTER=$(sed -n "2,$((CLOSING - 1))p" "$FILE_PATH")
    if [[ -n "$FRONTMATTER" ]]; then
        # Validate YAML syntax
        YAML_CHECK=$(echo "$FRONTMATTER" | yq '.' 2>&1 >/dev/null)
        if [[ $? -ne 0 ]]; then
            fail "frontmatter" "yq '.' (YAML validation)" "$YAML_CHECK" \
                "The YAML frontmatter has syntax errors. Read the file and fix the YAML between the --- delimiters."
        fi

        # Check required fields
        IFS=',' read -ra FIELDS <<< "${REQUIRED_FIELDS}"
        for field in "${FIELDS[@]}"; do
            field=$(echo "$field" | xargs)
            [[ -z "$field" ]] && continue
            HAS_FIELD=$(echo "$FRONTMATTER" | yq "has(\"$field\")" 2>/dev/null)
            if [[ "$HAS_FIELD" != "true" ]]; then
                fail "frontmatter" "yq 'has(\"$field\")'" \
                    "${FILE_PATH}: missing required field \"$field\"" \
                    "Read the file and add the '$field' field to the YAML frontmatter block."
            fi
        done

        # Validate ISO 8601 date format in date fields
        for DATE_FIELD in date created updated; do
            VALUE=$(echo "$FRONTMATTER" | yq ".${DATE_FIELD} // \"\"" 2>/dev/null | tr -d '"')
            if [[ -n "$VALUE" ]] && [[ "$VALUE" != "null" ]]; then
                if [[ ! "$VALUE" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
                    fail "frontmatter" "date format check" \
                        "${FILE_PATH}: field \"$DATE_FIELD\" value \"$VALUE\" is not ISO 8601 (expected YYYY-MM-DD)" \
                        "Read the file and change the $DATE_FIELD field to ISO 8601 format (YYYY-MM-DD)."
                fi
            fi
        done
    fi
else
    fail "frontmatter" "frontmatter presence check" \
        "${FILE_PATH}: missing YAML frontmatter (file must start with ---)" \
        "Add YAML frontmatter to the top of the file: start with '---', add required fields (${REQUIRED_FIELDS}), end with '---'."
fi

# 2. Codespell with auto-fix (if available) — fail-fast on unfixable
if command -v codespell &>/dev/null; then
    SPELL_OUTPUT=$(codespell --quiet-level=2 "$FILE_PATH" 2>&1)
    if [ -n "$SPELL_OUTPUT" ]; then
        codespell --write-changes --quiet-level=2 "$FILE_PATH" 2>/dev/null
        REMAINING=$(codespell --quiet-level=2 "$FILE_PATH" 2>&1)
        if [ -n "$REMAINING" ]; then
            fail "codespell" "codespell --quiet-level=2 $FILE_PATH" "$REMAINING" \
                "Codespell found misspellings it could not auto-fix. Read the file at the reported line and correct the spelling manually."
        fi
    fi
fi

exit 0
