#!/bin/bash
# Session start hook: dependency hygiene checks
# Runs once when a Claude Code session begins
# Non-blocking — reports issues but doesn't prevent session start
#
# THIS IS AN ANNOTATED EXAMPLE. The specific tool (deptry) is a current
# choice for the Architecture & Import Discipline role (dependency hygiene).
# The setup skill should substitute the best dependency checker for the
# project's ecosystem. What matters is the PATTERN:
#   - Run non-blocking checks (exit 0 always)
#   - Collect warnings and report to stderr
#   - Keep it fast (runs on every session start)
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
