#!/bin/bash
# Quality gate hook for Claude Code Stop event
# Fail-fast: stops at the first failing check, outputs its full stderr/stdout.
# Exit 2 feeds stderr to Claude for automatic fixing.
#
# THIS IS AN ANNOTATED EXAMPLE. The specific tools below (yq, codespell,
# grep, etc.) are current best-in-class choices for Obsidian vault quality.
# The setup skill should research and substitute the best tools for each ROLE
# based on the vault's ecosystem. What matters is the PATTERN:
#   - run_check / run_check_nonempty functions
#   - fail() output format (check name, command, tool output, hint, action directive)
#   - Fail-fast: exit 2 on first failure, one error at a time
#   - TOOL_HINTS: per-tool diagnostic hints that tell Claude how to fix
#   - Check ordering: fastest/most-likely-to-fail first
#
# TEMPLATE VARIABLES (replaced by setup skill):
#   ${VAULT_ROOT}          — vault root directory (usually ".")
#   ${REQUIRED_FIELDS}     — comma-separated required frontmatter fields
#   ${DAILY_NOTES_FORMAT}  — daily note filename pattern (e.g., "YYYY-MM-DD")
#   ${TEMPLATES_FOLDER}    — templates directory (e.g., "templates/")
#
# ENABLED CHECKS (setup skill removes disabled ones and adds researched tools):
#   Each check is guarded by a comment marker for easy removal.

set -o pipefail

HOOK_LOG="${CLAUDE_PROJECT_DIR:-.}/.claude/hooks/hook-debug.log"
WORKTREE_ID="$(basename "${CLAUDE_PROJECT_DIR:-.}")"
debuglog() {
    echo "[quality-gate@${WORKTREE_ID}] $(date '+%Y-%m-%d %H:%M:%S') $1" >> "$HOOK_LOG"
}
debuglog "=== HOOK STARTED (pid=$$) ==="

cd "${CLAUDE_PROJECT_DIR:-.}"

# Per-tool diagnostic hints for Claude auto-fix.
# EXAMPLE HINTS: These are for the tools shown below. When substituting
# different tools, write hints that are SPECIFIC to that tool — tell Claude
# which file to read, how to re-check a single file, and what to fix.
declare -A TOOL_HINTS
TOOL_HINTS=(
    [frontmatter]="Read the failing .md file and check its YAML frontmatter block (between --- delimiters). Ensure all required fields (${REQUIRED_FIELDS}) are present, the YAML is valid, and date fields use ISO 8601 format (YYYY-MM-DD). Fix the frontmatter in-place."
    [naming]="Read the failing filename. Rename files to remove special characters (use hyphens or spaces). Daily notes must match the pattern '${DAILY_NOTES_FORMAT}.md'. Use the Bash tool to 'git mv' the file."
    [spelling]="Run 'codespell --interactive 0 path/to/file.md' to see spelling errors. Most are auto-fixable with 'codespell --write-changes path/to/file.md'. Read the file and fix remaining misspellings manually."
    [headings]="Read the file at the reported line. Markdown headings must not skip levels (e.g., jumping from # to ### without ##). Insert the missing intermediate heading level."
    [links]="Read the file containing the broken wikilink. Check if the target note exists — the link may have a typo, or the target note may have been renamed or deleted. Fix the wikilink to point to an existing note or create the missing note."
    [tags]="Read the file with the tag issue. Tags should be lowercase-kebab-case. If a tag is used inconsistently (e.g., #project vs #Project), standardize to the most common form across all files."
    [templates]="Read the note and its corresponding template in '${TEMPLATES_FOLDER}'. Ensure the note contains all required sections defined by the template. Add missing sections."
    [git-hygiene]="Check the .gitignore file at the vault root. Volatile Obsidian files (workspace.json, workspace-mobile.json, .obsidian/cache) must be gitignored. Shared config files (app.json, appearance.json, community-plugins.json) should remain tracked."
)

fail() {
    local name="$1"
    local cmd="$2"
    local output="$3"
    local hint="${TOOL_HINTS[$name]:-}"

    echo "" >&2
    echo "QUALITY GATE FAILED [$name]:" >&2
    echo "Command: $cmd" >&2
    echo "" >&2
    echo "$output" >&2
    echo "" >&2
    if [ -n "$hint" ]; then
        echo "Hint: $hint" >&2
        echo "" >&2
    fi
    echo "ACTION REQUIRED: You MUST fix the issue shown above. Do NOT stop or explain — read the failing file, edit the source code to resolve it, and the quality gate will re-run automatically." >&2
    debuglog "=== FAILED: $name ==="
    exit 2
}

run_check() {
    local name="$1"; shift
    local cmd="$*"
    debuglog "Running $name..."
    OUTPUT=$("$@" 2>&1) || fail "$name" "$cmd" "$OUTPUT"
}

run_check_nonempty() {
    local name="$1"; shift
    local cmd="$*"
    debuglog "Running $name..."
    OUTPUT=$("$@" 2>&1)
    [ -n "$OUTPUT" ] && fail "$name" "$cmd" "$OUTPUT"
}

# Checks ordered by speed and likelihood of failure.
# EXAMPLE CHECKS: Replace tool commands with researched alternatives.
# Keep the run_check/run_check_nonempty pattern and [check:*] markers.

# [check:frontmatter]
# Validates YAML frontmatter in all .md files: syntax, required fields, date format
# Uses yq for YAML parsing (install: brew install yq / https://github.com/mikefarah/yq)
run_check "frontmatter" bash -c '
IFS="," read -ra REQUIRED <<< "'"${REQUIRED_FIELDS}"'"
ERRORS=""
while IFS= read -r -d "" file; do
    FIRST_LINE=$(head -1 "$file")
    if [[ "$FIRST_LINE" != "---" ]]; then
        ERRORS="${ERRORS}${file}: missing frontmatter\n"
        continue
    fi
    CLOSING=$(sed -n "2,\$ { /^---\$/= }" "$file" | head -1)
    if [[ -z "$CLOSING" ]]; then
        ERRORS="${ERRORS}${file}: unclosed frontmatter\n"
        continue
    fi
    FM=$(sed -n "2,$((CLOSING - 1))p" "$file")
    # Validate YAML syntax with yq
    if ! echo "$FM" | yq "." > /dev/null 2>&1; then
        ERRORS="${ERRORS}${file}: invalid YAML in frontmatter\n"
        continue
    fi
    # Check required fields
    for req in "${REQUIRED[@]}"; do
        req=$(echo "$req" | xargs)
        [[ -z "$req" ]] && continue
        HAS=$(echo "$FM" | yq "has(\"$req\")" 2>/dev/null)
        if [[ "$HAS" != "true" ]]; then
            ERRORS="${ERRORS}${file}: missing required field \"${req}\"\n"
        fi
    done
    # Validate date fields
    for df in date created updated; do
        VAL=$(echo "$FM" | yq ".$df // \"\"" 2>/dev/null | tr -d "\"")
        if [[ -n "$VAL" ]] && [[ "$VAL" != "null" ]]; then
            if [[ ! "$VAL" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
                ERRORS="${ERRORS}${file}: field \"${df}\" value \"${VAL}\" is not ISO 8601\n"
            fi
        fi
    done
done < <(find "'"${VAULT_ROOT}"'" -name "*.md" -not -path "*/.obsidian/*" -not -path "*/.git/*" -print0)
if [[ -n "$ERRORS" ]]; then
    echo -e "$ERRORS"
    exit 1
fi
'

# [check:naming]
# Checks filenames for problematic special characters and daily note format
run_check_nonempty "naming" bash -c "
ISSUES=''
# Check for special characters in filenames (allow spaces, hyphens, underscores, dots)
while IFS= read -r -d '' file; do
    basename=\$(basename \"\$file\" .md)
    if echo \"\$basename\" | grep -qP '[<>:\"/\\\\|?*#^\\[\\]{}]'; then
        ISSUES=\"\${ISSUES}\${file}: filename contains special characters\n\"
    fi
done < <(find '${VAULT_ROOT}' -name '*.md' -not -path '*/.obsidian/*' -not -path '*/.git/*' -print0)
# Check daily notes match expected format
if [ -d '${VAULT_ROOT}/${DAILY_NOTES_FOLDER:-daily}' ]; then
    while IFS= read -r -d '' file; do
        basename=\$(basename \"\$file\" .md)
        if ! echo \"\$basename\" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'; then
            ISSUES=\"\${ISSUES}\${file}: daily note filename does not match ${DAILY_NOTES_FORMAT} pattern\n\"
        fi
    done < <(find '${VAULT_ROOT}/${DAILY_NOTES_FOLDER:-daily}' -name '*.md' -print0)
fi
if [ -n \"\$ISSUES\" ]; then
    echo -e \"\$ISSUES\"
fi
"

# [check:spelling]
# Run spell checker on all markdown files
run_check_nonempty "spelling" codespell --quiet-level=2 --skip=".obsidian,.git,*.json" ${VAULT_ROOT}

# [check:headings]
# Check heading hierarchy — no skipped levels (e.g., # then ### without ##)
run_check_nonempty "headings" bash -c '
ERRORS=""
while IFS= read -r -d "" file; do
    PREV_LEVEL=0
    IN_CODE=false
    LINE_NUM=0
    while IFS= read -r line; do
        LINE_NUM=$((LINE_NUM + 1))
        # Track code blocks
        if [[ "$line" == "\`\`\`"* ]]; then
            if $IN_CODE; then IN_CODE=false; else IN_CODE=true; fi
            continue
        fi
        $IN_CODE && continue
        # Match headings
        if [[ "$line" =~ ^(#{1,6})[[:space:]] ]]; then
            LEVEL=${#BASH_REMATCH[1]}
            if [[ $PREV_LEVEL -gt 0 ]] && [[ $LEVEL -gt $((PREV_LEVEL + 1)) ]]; then
                ERRORS="${ERRORS}${file}:${LINE_NUM}: heading jumps from h${PREV_LEVEL} to h${LEVEL}\n"
            fi
            PREV_LEVEL=$LEVEL
        fi
    done < "$file"
done < <(find "'"${VAULT_ROOT}"'" -name "*.md" -not -path "*/.obsidian/*" -not -path "*/.git/*" -print0)
if [[ -n "$ERRORS" ]]; then
    echo -e "$ERRORS"
fi
'

# [check:links]
# Validate wikilinks resolve to existing files in the vault
run_check_nonempty "links" bash -c '
# Build index of all note names (without extension)
declare -A NOTES
while IFS= read -r -d "" file; do
    NAME=$(basename "$file" .md)
    NOTES["$NAME"]=1
done < <(find "'"${VAULT_ROOT}"'" -name "*.md" -not -path "*/.obsidian/*" -not -path "*/.git/*" -print0)

# Check wikilinks
ERRORS=""
while IFS= read -r -d "" file; do
    IN_CODE=false
    LINE_NUM=0
    while IFS= read -r line; do
        LINE_NUM=$((LINE_NUM + 1))
        if [[ "$line" == "\`\`\`"* ]]; then
            if $IN_CODE; then IN_CODE=false; else IN_CODE=true; fi
            continue
        fi
        $IN_CODE && continue
        # Extract wikilinks: [[target]] or [[target|alias]] or [[target#heading]]
        while [[ "$line" =~ \[\[([^\]|#]+) ]]; do
            TARGET="${BASH_REMATCH[1]}"
            # Remove the matched portion to find next link
            line="${line#*]]}"
            # Skip external links and file embeds with extensions
            [[ "$TARGET" == http* ]] && continue
            [[ "${TARGET##*/}" == *.* ]] && continue
            # Handle folder-prefixed links
            LINK_NAME="${TARGET##*/}"
            LINK_NAME=$(echo "$LINK_NAME" | xargs)
            if [[ -z "${NOTES[$LINK_NAME]+x}" ]]; then
                ERRORS="${ERRORS}${file}:${LINE_NUM}: broken wikilink [[${TARGET}]]\n"
            fi
        done
    done < "$file"
done < <(find "'"${VAULT_ROOT}"'" -name "*.md" -not -path "*/.obsidian/*" -not -path "*/.git/*" -print0)
if [[ -n "$ERRORS" ]]; then
    echo -e "$ERRORS" | head -50
fi
'

# [check:tags]
# Check for orphan tags and case inconsistencies
run_check_nonempty "tags" bash -c '
declare -A TAG_COUNTS    # lowercase tag -> count
declare -A TAG_VARIANTS  # lowercase tag -> space-separated variants
declare -A TAG_FILES     # lowercase tag -> first file seen

while IFS= read -r -d "" file; do
    IN_CODE=false
    while IFS= read -r line; do
        if [[ "$line" == "\`\`\`"* ]]; then
            if $IN_CODE; then IN_CODE=false; else IN_CODE=true; fi
            continue
        fi
        $IN_CODE && continue
        # Match inline tags: #word (not inside links)
        while [[ "$line" =~ (^|[[:space:]])#([a-zA-Z][a-zA-Z0-9_/-]*) ]]; do
            TAG="${BASH_REMATCH[2]}"
            LOWER=$(echo "$TAG" | tr "[:upper:]" "[:lower:]")
            TAG_COUNTS["$LOWER"]=$(( ${TAG_COUNTS["$LOWER"]:-0} + 1 ))
            if [[ "${TAG_VARIANTS[$LOWER]}" != *"$TAG"* ]]; then
                TAG_VARIANTS["$LOWER"]="${TAG_VARIANTS[$LOWER]:+${TAG_VARIANTS[$LOWER]} }$TAG"
            fi
            TAG_FILES["$LOWER"]="${TAG_FILES[$LOWER]:-$file}"
            line="${line#*"#${TAG}"}"
        done
    done < "$file"
done < <(find "'"${VAULT_ROOT}"'" -name "*.md" -not -path "*/.obsidian/*" -not -path "*/.git/*" -print0)

ERRORS=""
for LOWER in "${!TAG_VARIANTS[@]}"; do
    VARIANTS="${TAG_VARIANTS[$LOWER]}"
    # Check case inconsistencies (multiple variants)
    WORD_COUNT=$(echo "$VARIANTS" | wc -w | tr -d " ")
    if [[ "$WORD_COUNT" -gt 1 ]]; then
        ERRORS="${ERRORS}tag case inconsistency: ${VARIANTS}\n"
    fi
    # Check orphan tags (used only once)
    if [[ "${TAG_COUNTS[$LOWER]}" -eq 1 ]]; then
        ERRORS="${ERRORS}${TAG_FILES[$LOWER]}: orphan tag #${VARIANTS} (used only once)\n"
    fi
done
if [[ -n "$ERRORS" ]]; then
    echo -e "$ERRORS" | head -50
fi
'

# [check:templates]
# Verify notes created from templates contain required template sections
# Uses yq for frontmatter parsing, grep for heading comparison
run_check "templates" bash -c '
TEMPLATE_DIR="'"${TEMPLATES_FOLDER}"'"
if [[ ! -d "$TEMPLATE_DIR" ]]; then
    exit 0  # No templates directory — skip check
fi

# Parse template headings
declare -A TEMPLATE_HEADINGS
for tmpl in "$TEMPLATE_DIR"/*.md; do
    [[ -f "$tmpl" ]] || continue
    NAME=$(basename "$tmpl" .md)
    HEADINGS=$(grep -E "^#{1,6} " "$tmpl" | tr "\n" "|")
    [[ -n "$HEADINGS" ]] && TEMPLATE_HEADINGS["$NAME"]="$HEADINGS"
done

[[ ${#TEMPLATE_HEADINGS[@]} -eq 0 ]] && exit 0

ERRORS=""
while IFS= read -r -d "" file; do
    FIRST_LINE=$(head -1 "$file")
    [[ "$FIRST_LINE" != "---" ]] && continue
    CLOSING=$(sed -n "2,\$ { /^---\$/= }" "$file" | head -1)
    [[ -z "$CLOSING" ]] && continue
    FM=$(sed -n "2,$((CLOSING - 1))p" "$file")
    # Get template name from frontmatter using yq
    TMPL_NAME=$(echo "$FM" | yq ".template // \"\"" 2>/dev/null | tr -d "\"")
    [[ -z "$TMPL_NAME" ]] || [[ "$TMPL_NAME" == "null" ]] && continue
    [[ -z "${TEMPLATE_HEADINGS[$TMPL_NAME]+x}" ]] && continue
    # Compare headings
    IFS="|" read -ra REQ_HEADINGS <<< "${TEMPLATE_HEADINGS[$TMPL_NAME]}"
    BODY=$(tail -n +"$((CLOSING + 1))" "$file")
    for heading in "${REQ_HEADINGS[@]}"; do
        [[ -z "$heading" ]] && continue
        if ! echo "$BODY" | grep -qF "$heading"; then
            ERRORS="${ERRORS}${file}: missing template section \"${heading}\" (template: ${TMPL_NAME})\n"
        fi
    done
done < <(find "'"${VAULT_ROOT}"'" -name "*.md" -not -path "*/.obsidian/*" -not -path "*/.git/*" -not -path "'"${TEMPLATES_FOLDER}"'/*" -print0)
if [[ -n "$ERRORS" ]]; then
    echo -e "$ERRORS"
    exit 1
fi
'

# [check:git-hygiene]
# Verify volatile .obsidian/ files are gitignored
run_check "git-hygiene" bash -c "
GITIGNORE='${VAULT_ROOT}/.gitignore'
ERRORS=''
VOLATILE_FILES=('workspace.json' 'workspace-mobile.json' 'cache')
if [ -f \"\$GITIGNORE\" ]; then
    for vf in \"\${VOLATILE_FILES[@]}\"; do
        if ! grep -q \"\.obsidian/\${vf}\" \"\$GITIGNORE\" 2>/dev/null; then
            # Check if it's tracked by git
            if git ls-files --error-unmatch \".obsidian/\${vf}\" >/dev/null 2>&1; then
                ERRORS=\"\${ERRORS}.obsidian/\${vf} is tracked by git but should be gitignored (volatile file)\n\"
            fi
        fi
    done
else
    ERRORS='No .gitignore found — vault should have a .gitignore to exclude volatile .obsidian/ files'
fi
if [ -n \"\$ERRORS\" ]; then
    echo -e \"\$ERRORS\"
    exit 1
fi
"

debuglog "=== ALL CHECKS PASSED ==="
exit 0
