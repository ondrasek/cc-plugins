#!/bin/bash
# Session start hook: dependency hygiene checks
# Runs once when a Claude Code session begins
# Non-blocking — reports issues but doesn't prevent session start
#
# THIS IS AN ANNOTATED EXAMPLE. The specific tools (cargo-audit, cargo-machete)
# are current choices for the Security and Architecture roles (dependency hygiene).
# The setup skill should substitute the best dependency checkers for the project's
# ecosystem. What matters is the PATTERN:
#   - Run non-blocking checks (exit 0 always)
#   - Collect warnings and report to stderr
#   - Keep it fast (runs on every session start)
#
# TEMPLATE VARIABLES:
#   ${WORKSPACE_FLAG}  — workspace flag (e.g., "--workspace" or empty)

cd "${CLAUDE_PROJECT_DIR:-.}"

WARNINGS=""

# 1. Security advisory check (cargo-audit)
if command -v cargo-audit &>/dev/null; then
    AUDIT_OUTPUT=$(cargo audit 2>&1)
    AUDIT_EXIT=$?
    if [ $AUDIT_EXIT -ne 0 ]; then
        WARNINGS="${WARNINGS}SECURITY ADVISORIES (cargo audit):\n${AUDIT_OUTPUT}\n\n"
    fi
fi

# 2. Unused dependency check (cargo-machete)
if command -v cargo-machete &>/dev/null; then
    MACHETE_OUTPUT=$(cargo machete 2>&1)
    if [ -n "$MACHETE_OUTPUT" ]; then
        WARNINGS="${WARNINGS}UNUSED DEPENDENCIES (cargo-machete):\n${MACHETE_OUTPUT}\n\n"
    fi
fi

if [ -n "$WARNINGS" ]; then
    echo -e "Session start checks found issues:\n${WARNINGS}" >&2
    echo "These are non-blocking warnings. Consider fixing them during this session." >&2
    exit 0
fi

exit 0
