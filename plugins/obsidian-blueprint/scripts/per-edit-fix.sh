#!/bin/bash
# Plugin-level per-edit hook: validates frontmatter and spelling in Obsidian vault notes
# Triggered by PostToolUse on Edit|Write
# Exit 0 = success (fixes applied silently)
# Exit 2 = unfixable issues fed back to Claude

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.filePath // empty')

# Only process Markdown files outside .obsidian/
if [[ -z "$FILE_PATH" ]] || [[ "$FILE_PATH" != *.md ]]; then
    exit 0
fi
if [[ "$FILE_PATH" == */.obsidian/* ]]; then
    exit 0
fi
if [[ ! -f "$FILE_PATH" ]]; then
    exit 0
fi

ERRORS=""

# --- Frontmatter YAML validation ---
# Check if file starts with --- (frontmatter delimiter)
FIRST_LINE=$(head -1 "$FILE_PATH")
if [[ "$FIRST_LINE" == "---" ]]; then
    # Check for closing delimiter
    CLOSING=$(sed -n '2,$ { /^---$/= }' "$FILE_PATH" | head -1)
    if [[ -z "$CLOSING" ]]; then
        ERRORS="${ERRORS}FRONTMATTER: Missing closing '---' delimiter. The file starts with frontmatter but has no closing delimiter.\n\n"
    else
        # Extract frontmatter content (between first and second ---)
        FRONTMATTER=$(sed -n "2,$((CLOSING - 1))p" "$FILE_PATH")
        if [[ -n "$FRONTMATTER" ]]; then
            YAML_CHECK=$(echo "$FRONTMATTER" | python3 -c "import sys, yaml; yaml.safe_load(sys.stdin)" 2>&1)
            YAML_EXIT=$?
            if [[ $YAML_EXIT -ne 0 ]]; then
                ERRORS="${ERRORS}FRONTMATTER (YAML):\n${YAML_CHECK}\n\n"
            else
                # Validate date fields are ISO format (YYYY-MM-DD)
                DATE_ISSUES=""
                while IFS= read -r line; do
                    # Match common date field names
                    if [[ "$line" =~ ^(date|created|modified|updated|published|due|scheduled)[[:space:]]*: ]]; then
                        FIELD_NAME="${BASH_REMATCH[1]}"
                        # Extract the value after the colon
                        VALUE=$(echo "$line" | sed 's/^[^:]*:[[:space:]]*//' | tr -d '"' | tr -d "'" | xargs)
                        # Skip empty values
                        if [[ -z "$VALUE" ]]; then
                            continue
                        fi
                        # Check if it matches YYYY-MM-DD (possibly with time after)
                        if [[ ! "$VALUE" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}($|[T ]) ]]; then
                            DATE_ISSUES="${DATE_ISSUES}  ${FIELD_NAME}: '${VALUE}' is not ISO 8601 format (expected YYYY-MM-DD)\n"
                        fi
                    fi
                done <<< "$FRONTMATTER"
                if [[ -n "$DATE_ISSUES" ]]; then
                    ERRORS="${ERRORS}FRONTMATTER (dates):\n${DATE_ISSUES}\n"
                fi
            fi
        fi
    fi
fi

# --- Codespell: auto-fix spelling, report unfixable ---
if command -v codespell &>/dev/null; then
    SPELL_OUTPUT=$(codespell --quiet-level=2 "$FILE_PATH" 2>&1)
    if [[ -n "$SPELL_OUTPUT" ]]; then
        codespell --write-changes --quiet-level=2 "$FILE_PATH" 2>/dev/null
        REMAINING=$(codespell --quiet-level=2 "$FILE_PATH" 2>&1)
        if [[ -n "$REMAINING" ]]; then
            ERRORS="${ERRORS}SPELLING (codespell):\n${REMAINING}\n\n"
        fi
    fi
fi

# Report unfixable issues back to Claude
if [[ -n "$ERRORS" ]]; then
    echo -e "Per-edit check found issues in ${FILE_PATH}:\n${ERRORS}" >&2
    exit 2
fi

exit 0
