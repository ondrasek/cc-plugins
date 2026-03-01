#!/bin/bash
# Per-edit hook: runs fast auto-fixers on changed markdown files
# Triggered by PostToolUse on Edit|Write
# Exit 0 = success (fixes applied silently)
# Exit 2 = unfixable issues fed back to Claude
#
# THIS IS AN ANNOTATED EXAMPLE. The specific tools (python3, codespell) are
# current choices for the Frontmatter & Spelling roles. The setup skill should
# substitute the best auto-fixable tools for the vault's ecosystem. What
# matters is the PATTERN:
#   - Detect markdown file from tool input JSON
#   - Run auto-fixers silently (exit 0 if all fixed)
#   - Report unfixable issues to stderr (exit 2)
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

ERRORS=""

# 1. YAML frontmatter validity and required fields
FM_OUTPUT=$(python3 -c "
import re, sys

path = sys.argv[1]
required = [f.strip() for f in '${REQUIRED_FIELDS}'.split(',')]
date_re = re.compile(r'^\d{4}-\d{2}-\d{2}$')

with open(path, 'r', encoding='utf-8', errors='replace') as fh:
    content = fh.read()

if not content.startswith('---'):
    print(f'{path}: missing YAML frontmatter (file must start with ---)')
    sys.exit(1)

end = content.find('---', 3)
if end == -1:
    print(f'{path}: unclosed frontmatter (missing closing ---)')
    sys.exit(1)

fm = content[3:end].strip()
errors = []
fields = {}
for line in fm.split('\n'):
    if ':' in line:
        key = line.split(':', 1)[0].strip()
        val = line.split(':', 1)[1].strip()
        fields[key] = val

for req in required:
    if req and req not in fields:
        errors.append(f'{path}: missing required field \"{req}\"')

# Validate ISO 8601 date format in date fields
for date_field in ['date', 'created', 'updated']:
    if date_field in fields and fields[date_field]:
        val = fields[date_field].strip('\"').strip(\"'\")
        if val and not date_re.match(val):
            errors.append(f'{path}: field \"{date_field}\" value \"{val}\" is not ISO 8601 (expected YYYY-MM-DD)')

if errors:
    print('\n'.join(errors))
    sys.exit(1)
" "$FILE_PATH" 2>&1)
FM_EXIT=$?
if [ $FM_EXIT -ne 0 ]; then
    ERRORS="${ERRORS}FRONTMATTER:\n${FM_OUTPUT}\n\n"
fi

# 2. Codespell with auto-fix (if available)
if command -v codespell &>/dev/null; then
    SPELL_OUTPUT=$(codespell --quiet-level=2 "$FILE_PATH" 2>&1)
    if [ -n "$SPELL_OUTPUT" ]; then
        codespell --write-changes --quiet-level=2 "$FILE_PATH" 2>/dev/null
        REMAINING=$(codespell --quiet-level=2 "$FILE_PATH" 2>&1)
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
