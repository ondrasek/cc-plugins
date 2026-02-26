#!/usr/bin/env bash
# PostToolUse/Bash hook: blocks commits when source changed but version wasn't bumped.
# Compares against merge-base with main (or HEAD~1 if on main).
# Exit 0 = pass, Exit 2 = block with structured feedback.
# Compatible with bash 3 (macOS default).
#
# THIS IS AN ANNOTATED EXAMPLE. The setup skill should substitute the
# version extraction commands and source directories based on the project's
# ecosystem. What matters is the PATTERN:
#   - Fire only on git commit
#   - Skip merge/rebase/amend
#   - Determine base ref (merge-base or HEAD~1)
#   - Check if source dirs changed
#   - Compare base version vs HEAD version
#   - Block (exit 2) with semver guidance if unchanged
#
# TEMPLATE VARIABLES (replaced by setup skill):
#   ${VERSION_FILE}            — path to version file (e.g., "myplugin-scm-1.rockspec")
#   ${VERSION_EXTRACT_CMD}     — command to extract version from file on disk
#   ${VERSION_EXTRACT_CMD_GIT} — command to extract version from git show output (reads stdin)
#   ${SOURCE_DIRS}             — space-separated directories whose changes require a bump

set -euo pipefail

# Read tool input from stdin
INPUT="$(cat)"

# Extract the command that was run
COMMAND="$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)"
if [ -z "$COMMAND" ]; then
  exit 0
fi

# Only fire on git commit commands
if ! echo "$COMMAND" | grep -qE '^\s*git\s+commit\b'; then
  exit 0
fi

# Skip merge, rebase, and amend commits
if echo "$COMMAND" | grep -qE '(--amend|--no-edit.*merge|rebase|cherry-pick)'; then
  exit 0
fi

# Check if the commit actually succeeded
EXIT_CODE="$(echo "$INPUT" | jq -r '.tool_result.exit_code // 0' 2>/dev/null)"
if [ "$EXIT_CODE" != "0" ] 2>/dev/null; then
  exit 0
fi

# Must be in a git repo
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  exit 0
fi

# Version file must exist
if [ ! -f "${VERSION_FILE}" ]; then
  exit 0
fi

# Determine current branch
CURRENT_BRANCH="$(git symbolic-ref --short HEAD 2>/dev/null || echo "")"
if [ -z "$CURRENT_BRANCH" ]; then
  exit 0  # detached HEAD
fi

# Determine base ref for comparison
if [ "$CURRENT_BRANCH" = "main" ] || [ "$CURRENT_BRANCH" = "master" ]; then
  BASE_REF="HEAD~1"
  if ! git rev-parse HEAD~1 >/dev/null 2>&1; then
    exit 0  # first commit in repo
  fi
else
  BASE_REF="$(git merge-base HEAD main 2>/dev/null || git merge-base HEAD master 2>/dev/null || echo "")"
  if [ -z "$BASE_REF" ]; then
    exit 0
  fi
fi

# Get files changed since base ref
CHANGED_FILES="$(git diff --name-only "$BASE_REF"..HEAD 2>/dev/null || echo "")"
if [ -z "$CHANGED_FILES" ]; then
  exit 0
fi

# Check if any source directories have changes
SOURCE_CHANGED=false
for DIR in ${SOURCE_DIRS}; do
  if echo "$CHANGED_FILES" | grep -q "^${DIR}"; then
    SOURCE_CHANGED=true
    break
  fi
done

if [ "$SOURCE_CHANGED" = false ]; then
  exit 0  # no source changes, version bump not required
fi

# Get version at base ref
BASE_VERSION="$(git show "$BASE_REF:${VERSION_FILE}" 2>/dev/null | ${VERSION_EXTRACT_CMD_GIT} 2>/dev/null || echo "")"
if [ -z "$BASE_VERSION" ]; then
  exit 0  # no prior version to compare (new file or new field)
fi

# Get version at HEAD
HEAD_VERSION="$(${VERSION_EXTRACT_CMD} 2>/dev/null || echo "")"
if [ -z "$HEAD_VERSION" ]; then
  exit 0  # version field removed or unreadable
fi

# Compare versions
if [ "$BASE_VERSION" = "$HEAD_VERSION" ]; then
  AFFECTED_FILES="$(echo "$CHANGED_FILES" | head -10 | sed 's/^/    - /')"
  cat >&2 <<EOF
BLOCKED: Version not bumped.

Source files changed since ${BASE_REF} but the version in ${VERSION_FILE} is still ${HEAD_VERSION}.

Changed files (up to 10):
${AFFECTED_FILES}

Action required: Determine the appropriate semver increment:
- PATCH (x.y.Z): bug fixes, minor tweaks, documentation changes
- MINOR (x.Y.0): new features, backward-compatible enhancements
- MAJOR (X.0.0): breaking changes to public API

Update the version in ${VERSION_FILE}, then amend the commit:
  git add ${VERSION_FILE} && git commit --amend --no-edit
EOF
  exit 2
fi

exit 0
