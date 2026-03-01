#!/bin/bash
# Quality gate hook for Claude Code Stop event
# Fail-fast: stops at the first failing check, outputs its full stderr/stdout.
# Exit 2 feeds stderr to Claude for automatic fixing.
#
# THIS IS AN ANNOTATED EXAMPLE. The specific tools below (python3, codespell,
# cspell, etc.) are current best-in-class choices for Obsidian vault quality.
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
run_check "frontmatter" python3 -c "
import os, sys, re

required = [f.strip() for f in '${REQUIRED_FIELDS}'.split(',')]
errors = []
date_re = re.compile(r'^\d{4}-\d{2}-\d{2}$')

for root, dirs, files in os.walk('${VAULT_ROOT}'):
    # Skip hidden dirs and templates
    dirs[:] = [d for d in dirs if not d.startswith('.')]
    for f in files:
        if not f.endswith('.md'):
            continue
        path = os.path.join(root, f)
        with open(path, 'r', encoding='utf-8', errors='replace') as fh:
            content = fh.read()
        if not content.startswith('---'):
            errors.append(f'{path}: missing frontmatter')
            continue
        end = content.find('---', 3)
        if end == -1:
            errors.append(f'{path}: unclosed frontmatter')
            continue
        fm = content[3:end].strip()
        fields = {}
        for line in fm.split('\n'):
            if ':' in line:
                key = line.split(':', 1)[0].strip()
                val = line.split(':', 1)[1].strip()
                fields[key] = val
        for req in required:
            if req and req not in fields:
                errors.append(f'{path}: missing required field \"{req}\"')
        for date_field in ['date', 'created', 'updated']:
            if date_field in fields and fields[date_field]:
                val = fields[date_field].strip('\"').strip(\"'\")
                if val and not date_re.match(val):
                    errors.append(f'{path}: field \"{date_field}\" value \"{val}\" is not ISO 8601')

if errors:
    print('\n'.join(errors))
    sys.exit(1)
"

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
run_check_nonempty "headings" python3 -c "
import os, re, sys

errors = []
heading_re = re.compile(r'^(#{1,6})\s')

for root, dirs, files in os.walk('${VAULT_ROOT}'):
    dirs[:] = [d for d in dirs if not d.startswith('.')]
    for f in files:
        if not f.endswith('.md'):
            continue
        path = os.path.join(root, f)
        with open(path, 'r', encoding='utf-8', errors='replace') as fh:
            lines = fh.readlines()
        prev_level = 0
        in_code_block = False
        for i, line in enumerate(lines, 1):
            stripped = line.strip()
            if stripped.startswith('\`\`\`'):
                in_code_block = not in_code_block
                continue
            if in_code_block:
                continue
            m = heading_re.match(stripped)
            if m:
                level = len(m.group(1))
                if prev_level > 0 and level > prev_level + 1:
                    errors.append(f'{path}:{i}: heading jumps from h{prev_level} to h{level}')
                prev_level = level

if errors:
    print('\n'.join(errors))
"

# [check:links]
# Validate wikilinks resolve to existing files in the vault
run_check_nonempty "links" python3 -c "
import os, re, sys

# Build index of all note names (without extension)
notes = set()
for root, dirs, files in os.walk('${VAULT_ROOT}'):
    dirs[:] = [d for d in dirs if not d.startswith('.')]
    for f in files:
        if f.endswith('.md'):
            notes.add(os.path.splitext(f)[0])

# Check wikilinks
wikilink_re = re.compile(r'\[\[([^\]|#]+?)(?:#[^\]]*)?(?:\|[^\]]+)?\]\]')
errors = []
for root, dirs, files in os.walk('${VAULT_ROOT}'):
    dirs[:] = [d for d in dirs if not d.startswith('.')]
    for f in files:
        if not f.endswith('.md'):
            continue
        path = os.path.join(root, f)
        with open(path, 'r', encoding='utf-8', errors='replace') as fh:
            content = fh.read()
        in_code_block = False
        for i, line in enumerate(content.split('\n'), 1):
            stripped = line.strip()
            if stripped.startswith('\`\`\`'):
                in_code_block = not in_code_block
                continue
            if in_code_block:
                continue
            for m in wikilink_re.finditer(line):
                target = m.group(1).strip()
                # Skip external links and embedded images
                if target.startswith('http') or '.' in target.split('/')[-1]:
                    continue
                # Handle folder-prefixed links (folder/note)
                link_name = target.split('/')[-1] if '/' in target else target
                if link_name not in notes:
                    errors.append(f'{path}:{i}: broken wikilink [[{target}]]')

if errors:
    print('\n'.join(errors[:50]))  # Cap at 50 to avoid overwhelming output
"

# [check:tags]
# Check for orphan tags and case inconsistencies
run_check_nonempty "tags" python3 -c "
import os, re, sys
from collections import defaultdict

tag_re = re.compile(r'(?:^|\s)#([a-zA-Z][a-zA-Z0-9_/-]*)\b')
tag_usage = defaultdict(list)  # lowercase -> [(original, file)]

for root, dirs, files in os.walk('${VAULT_ROOT}'):
    dirs[:] = [d for d in dirs if not d.startswith('.')]
    for f in files:
        if not f.endswith('.md'):
            continue
        path = os.path.join(root, f)
        with open(path, 'r', encoding='utf-8', errors='replace') as fh:
            content = fh.read()
        in_code_block = False
        for line in content.split('\n'):
            stripped = line.strip()
            if stripped.startswith('\`\`\`'):
                in_code_block = not in_code_block
                continue
            if in_code_block:
                continue
            for m in tag_re.finditer(line):
                tag = m.group(1)
                tag_usage[tag.lower()].append((tag, path))

errors = []
# Find case inconsistencies
seen_lower = defaultdict(set)
for lower_tag, usages in tag_usage.items():
    variants = set(t for t, _ in usages)
    if len(variants) > 1:
        files = set(f for _, f in usages)
        errors.append(f'tag case inconsistency: {variants} used in {len(files)} files')
    seen_lower[lower_tag] = variants

# Find tags used only once (potential orphans)
for lower_tag, usages in tag_usage.items():
    if len(usages) == 1:
        tag, path = usages[0]
        errors.append(f'{path}: orphan tag #{tag} (used only once)')

if errors:
    print('\n'.join(errors[:50]))
"

# [check:templates]
# Verify notes created from templates contain required template sections
run_check "templates" python3 -c "
import os, re, sys

template_dir = '${TEMPLATES_FOLDER}'
if not os.path.isdir(template_dir):
    sys.exit(0)  # No templates directory — skip check

# Parse template headings
templates = {}
for f in os.listdir(template_dir):
    if not f.endswith('.md'):
        continue
    path = os.path.join(template_dir, f)
    with open(path, 'r', encoding='utf-8', errors='replace') as fh:
        content = fh.read()
    headings = re.findall(r'^(#{1,6}\s+.+)$', content, re.MULTILINE)
    if headings:
        templates[os.path.splitext(f)[0]] = headings

if not templates:
    sys.exit(0)

# Check notes that declare a template in frontmatter
errors = []
for root, dirs, files in os.walk('${VAULT_ROOT}'):
    dirs[:] = [d for d in dirs if not d.startswith('.') and d != template_dir]
    for f in files:
        if not f.endswith('.md'):
            continue
        path = os.path.join(root, f)
        with open(path, 'r', encoding='utf-8', errors='replace') as fh:
            content = fh.read()
        if not content.startswith('---'):
            continue
        end = content.find('---', 3)
        if end == -1:
            continue
        fm = content[3:end]
        # Look for template field
        for line in fm.split('\n'):
            if line.strip().startswith('template:'):
                tmpl_name = line.split(':', 1)[1].strip().strip('\"').strip(\"'\")
                if tmpl_name in templates:
                    note_headings = re.findall(r'^(#{1,6}\s+.+)$', content[end+3:], re.MULTILINE)
                    for req_heading in templates[tmpl_name]:
                        if req_heading not in note_headings:
                            errors.append(f'{path}: missing template section \"{req_heading}\" (template: {tmpl_name})')
                break

if errors:
    print('\n'.join(errors))
    sys.exit(1)
"

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
