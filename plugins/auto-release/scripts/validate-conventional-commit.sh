#!/bin/bash
# PostToolUse(Bash) hook: validate commit messages follow Conventional Commits.
# Blocking — exits 2 if the last commit doesn't follow the convention.
#
# Only triggers on `git commit` commands (skips merge/rebase/amend).

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Only check git commit commands
if [[ -z "$COMMAND" ]] || [[ "$COMMAND" != *"git commit"* ]]; then
    exit 0
fi

# Skip merge, rebase, and amend commits
if [[ "$COMMAND" == *"merge"* ]] || [[ "$COMMAND" == *"rebase"* ]] || [[ "$COMMAND" == *"--amend"* ]]; then
    exit 0
fi

# Get the last commit subject line
COMMIT_SUBJECT=$(git log -1 --format=%s 2>/dev/null)
if [[ -z "$COMMIT_SUBJECT" ]]; then
    exit 0
fi

# Validate against conventional commit pattern
# Format: <type>[(scope)][!]: <description>
PATTERN='^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\([a-zA-Z0-9._-]+\))?!?: .+'

if echo "$COMMIT_SUBJECT" | grep -qE "$PATTERN"; then
    exit 0
fi

# Non-conventional commit — block and instruct Claude to amend
cat >&2 <<EOF
CONVENTIONAL COMMIT VALIDATION FAILED

What failed: Commit message does not follow Conventional Commits format.

Commit message:
  ${COMMIT_SUBJECT}

Expected format: <type>[(scope)][!]: <description>

Valid types: feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert

Examples:
  feat(auth): add OAuth2 login flow
  fix: correct null pointer in user lookup
  chore(deps): update dependency versions
  refactor(api)!: restructure endpoint naming

Action required: Amend the commit with a conventional commit message.
  command: git commit --amend -m "<type>(scope): description"
EOF

exit 2
