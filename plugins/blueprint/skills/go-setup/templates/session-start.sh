#!/bin/bash
# Session start hook: dependency hygiene checks
# Runs once when a Claude Code session begins
# Non-blocking — reports issues but doesn't prevent session start
#
# THIS IS AN ANNOTATED EXAMPLE. The specific tools (govulncheck, go mod verify)
# are current choices for the Security and Architecture roles (dependency hygiene).
# The setup skill should substitute the best dependency checkers for the project's
# ecosystem. What matters is the PATTERN:
#   - Run non-blocking checks (exit 0 always)
#   - Collect warnings and report to stderr
#   - Keep it fast (runs on every session start)

cd "${CLAUDE_PROJECT_DIR:-.}"

WARNINGS=""

# 1. Vulnerability check (govulncheck)
if command -v govulncheck &>/dev/null; then
    VULN_OUTPUT=$(govulncheck ./... 2>&1)
    VULN_EXIT=$?
    if [ $VULN_EXIT -ne 0 ]; then
        WARNINGS="${WARNINGS}VULNERABILITIES (govulncheck):\n${VULN_OUTPUT}\n\n"
    fi
fi

# 2. Module integrity check (go mod verify)
VERIFY_OUTPUT=$(go mod verify 2>&1)
VERIFY_EXIT=$?
if [ $VERIFY_EXIT -ne 0 ]; then
    WARNINGS="${WARNINGS}MODULE INTEGRITY (go mod verify):\n${VERIFY_OUTPUT}\n\n"
fi

# 3. Dependency tidiness check
TIDY_OUTPUT=$(go mod tidy -diff 2>&1)
if [ -n "$TIDY_OUTPUT" ]; then
    WARNINGS="${WARNINGS}UNTIDY DEPENDENCIES (go mod tidy -diff):\n${TIDY_OUTPUT}\n\n"
fi

if [ -n "$WARNINGS" ]; then
    echo -e "Session start checks found issues:\n${WARNINGS}" >&2
    echo "These are non-blocking warnings. Consider fixing them during this session." >&2
    echo "Re-run this check with: bash \"\${CLAUDE_PROJECT_DIR:-.}\"/.claude/hooks/session-start.sh" >&2
    exit 0
fi

exit 0
