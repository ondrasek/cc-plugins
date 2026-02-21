#!/bin/bash
# Session start hook: dependency hygiene checks
# Runs once when a Claude Code session begins
# Non-blocking — reports issues but doesn't prevent session start
#
# TEMPLATE VARIABLES:
#   ${PACKAGE_MANAGER_RUN}  — command prefix (e.g., "uv run", "poetry run")

cd "${CLAUDE_PROJECT_DIR:-.}"

WARNINGS=""

# 1. Dependency hygiene (deptry) — find unused/missing/transitive deps
DEPTRY_OUTPUT=$(${PACKAGE_MANAGER_RUN} deptry . 2>&1)
DEPTRY_EXIT=$?
if [ $DEPTRY_EXIT -ne 0 ]; then
    WARNINGS="${WARNINGS}DEPENDENCY ISSUES (deptry):\n${DEPTRY_OUTPUT}\n\n"
fi

if [ -n "$WARNINGS" ]; then
    echo -e "Session start checks found issues:\n${WARNINGS}" >&2
    echo "These are non-blocking warnings. Consider fixing them during this session." >&2
    exit 0
fi

exit 0
