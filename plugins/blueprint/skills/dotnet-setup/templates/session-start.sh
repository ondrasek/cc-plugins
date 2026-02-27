#!/bin/bash
# Session start hook: dependency hygiene checks
# Runs once when a Claude Code session begins
# Non-blocking — reports issues but doesn't prevent session start
#
# THIS IS AN ANNOTATED EXAMPLE. The specific tools (dotnet list package)
# are built into the .NET SDK. The setup skill should add any additional
# dependency hygiene tools for the project's ecosystem. What matters is
# the PATTERN:
#   - Run non-blocking checks (exit 0 always)
#   - Collect warnings and report to stderr
#   - Keep it fast (runs on every session start)
#
# TEMPLATE VARIABLES:
#   ${SOLUTION_FILE}  — solution file (e.g., "MyApp.sln")

cd "${CLAUDE_PROJECT_DIR:-.}"

WARNINGS=""

# 1. NuGet vulnerability audit — find packages with known CVEs
VULN_OUTPUT=$(dotnet list ${SOLUTION_FILE} package --vulnerable --include-transitive 2>&1)
VULN_EXIT=$?
if echo "$VULN_OUTPUT" | grep -qi "has the following vulnerable packages"; then
    WARNINGS="${WARNINGS}VULNERABLE PACKAGES:\n${VULN_OUTPUT}\n\n"
fi

# 2. Outdated packages — check for outdated NuGet dependencies
OUTDATED_OUTPUT=$(dotnet list ${SOLUTION_FILE} package --outdated 2>&1)
if echo "$OUTDATED_OUTPUT" | grep -qi "has the following updates available"; then
    WARNINGS="${WARNINGS}OUTDATED PACKAGES (non-blocking):\n${OUTDATED_OUTPUT}\n\n"
fi

if [ -n "$WARNINGS" ]; then
    echo -e "Session start checks found issues:\n${WARNINGS}" >&2
    echo "These are non-blocking warnings. Consider fixing them during this session." >&2
    exit 0
fi

exit 0
