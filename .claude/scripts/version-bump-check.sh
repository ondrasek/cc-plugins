#!/usr/bin/env bash
# PostToolUse/Bash hook: blocks commits when plugin files changed but version wasn't bumped.
# Compares against merge-base with main (or HEAD~1 if on main).
# Exit 0 = pass, Exit 2 = block with structured feedback.
# Compatible with bash 3 (macOS default).

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

# Skip merge and rebase commits
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

# Determine current branch
CURRENT_BRANCH="$(git symbolic-ref --short HEAD 2>/dev/null || echo "")"
if [ -z "$CURRENT_BRANCH" ]; then
  exit 0  # detached HEAD
fi

# Determine base ref for comparison
if [ "$CURRENT_BRANCH" = "main" ] || [ "$CURRENT_BRANCH" = "master" ]; then
  # On main: compare against previous commit
  BASE_REF="HEAD~1"
  if ! git rev-parse HEAD~1 >/dev/null 2>&1; then
    exit 0  # first commit in repo
  fi
else
  # On branch: compare against merge-base with main
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

# Extract unique plugin directories from changed files
AFFECTED_PLUGINS="$(echo "$CHANGED_FILES" | grep -oE '^plugins/[^/]+' | sort -u || echo "")"
if [ -z "$AFFECTED_PLUGINS" ]; then
  exit 0  # no plugin files changed
fi

# Temp file to collect unbumped plugin details (bash 3 compatible, no arrays)
DETAILS_FILE="$(mktemp "${TMPDIR:-/tmp}/version-bump-check.XXXXXX")"
trap 'rm -f "$DETAILS_FILE"' EXIT

# Check each affected plugin for version bump
for PLUGIN_PATH in $AFFECTED_PLUGINS; do
  PLUGIN_NAME="$(basename "$PLUGIN_PATH")"
  MANIFEST="$PLUGIN_PATH/.claude-plugin/plugin.json"

  # Get version at base ref (empty if plugin didn't exist)
  BASE_VERSION="$(git show "$BASE_REF:$MANIFEST" 2>/dev/null | jq -r '.version // empty' 2>/dev/null || echo "")"
  if [ -z "$BASE_VERSION" ]; then
    continue  # new plugin, no prior version to compare
  fi

  # Get version at HEAD
  HEAD_VERSION="$(git show "HEAD:$MANIFEST" 2>/dev/null | jq -r '.version // empty' 2>/dev/null || echo "")"
  if [ -z "$HEAD_VERSION" ]; then
    continue  # plugin.json removed or no version field
  fi

  # Compare versions
  if [ "$BASE_VERSION" = "$HEAD_VERSION" ]; then
    PLUGIN_FILES="$(echo "$CHANGED_FILES" | grep "^$PLUGIN_PATH/" | head -10 | sed 's/^/    - /')"
    printf '  Plugin: %s\n  Current version: %s\n  Manifest: %s\n  Changed files:\n%s\n\n' \
      "$PLUGIN_NAME" "$HEAD_VERSION" "$MANIFEST" "$PLUGIN_FILES" >> "$DETAILS_FILE"
  fi
done

# If no unbumped plugins, pass
if [ ! -s "$DETAILS_FILE" ]; then
  exit 0
fi

# Block with structured message
cat <<EOF
BLOCKED: Plugin version not bumped.

The following plugin(s) have changes but their version in plugin.json was not updated:

$(cat "$DETAILS_FILE")
Action required: Determine the appropriate semver increment for each plugin listed above:
- PATCH (x.y.Z): bug fixes, minor tweaks, documentation changes
- MINOR (x.Y.0): new features, new skills, backward-compatible enhancements
- MAJOR (X.0.0): breaking changes to skill interfaces or hook contracts

Update the "version" field in each plugin's .claude-plugin/plugin.json, then amend the commit:
  git add <manifest> && git commit --amend --no-edit
EOF

exit 2
